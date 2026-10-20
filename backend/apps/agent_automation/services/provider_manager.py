"""
FactoryOS AI — Goal Provider Manager & Deterministic Planner
Phase 4, Step 2: Provider Selection, Explicit Fallback, and Provider Status Reporting

Manages LLM vs Deterministic vs Hybrid execution modes.
Guarantees:
- Never silently passes deterministic output as LLM-generated.
- Transparently records provider type, model, fallback status, and failure reasons.
- Safe deterministic alternative requires ZERO API keys or external network connectivity.
"""
import os
import re
import logging
from typing import Dict, Any, List, Optional, Tuple

from apps.agent_automation.services.industry_profiles import IndustryProfile
from apps.agent_automation.services.llm_provider import OpenAICompatibleAgentProvider, LLMProviderError

logger = logging.getLogger(__name__)


class DeterministicGoalPlanner:
    """
    Deterministic domain-heuristic planner for manufacturing goals.
    Translates standard operational intents (orders, inventory checks, simulation, release)
    into structured, validated tool sequences without requiring paid API keys or network access.
    """

    @classmethod
    def generate_plan(
        cls,
        goal: str,
        industry_profile: IndustryProfile,
        factory_name: str,
    ) -> Dict[str, Any]:
        """
        Synthesizes a structured plan from natural-language goal text.
        """
        goal_lower = goal.lower()

        # 1. Extract target quantity (e.g., '100-unit', '500 units', 'produce 250')
        quantity_match = re.search(r'(\d+)\s*(?:-?\s*units?|-?\s*pieces?|-?\s*parts?|qty)?', goal_lower)
        target_quantity = 100
        if quantity_match:
            try:
                parsed_qty = int(quantity_match.group(1))
                if 0 < parsed_qty < 1000000:
                    target_quantity = parsed_qty
            except ValueError:
                pass

        # 2. Extract potential material or product hints
        material_hint = ""
        if "material" in goal_lower or "inventory" in goal_lower or "stock" in goal_lower:
            words = [w for w in goal.split() if len(w) > 3 and w.lower() not in ["check", "material", "availability", "inventory", "stock", "units", "order", "production"]]
            if words:
                material_hint = words[0]

        steps = []
        step_counter = 1

        # Step 1: Inventory Availability Check
        if any(k in goal_lower for k in ["inventory", "material", "stock", "availability", "prepare", "release"]):
            steps.append({
                "step_number": step_counter,
                "title": f"Check {industry_profile.terminology.get('workpiece', 'Material')} Inventory Availability",
                "description": "Query live RawMaterial stock balances to ensure sufficient buffer exists.",
                "tool_name": "inspect_inventory_stock",
                "tool_arguments": {"material_name_or_code": material_hint},
                "is_consequential": False,
            })
            step_counter += 1

        # Step 2: Process Workflow Discovery & Validation
        steps.append({
            "step_number": step_counter,
            "title": f"Identify & Validate {industry_profile.display_name} Process Workflow",
            "description": "Locate published manufacturing process graph and verify topological validity via ProcessGraphValidator.",
            "tool_name": "discover_and_validate_process",
            "tool_arguments": {"category": industry_profile.supported_templates[0] if industry_profile.supported_templates else ""},
            "is_consequential": False,
        })
        step_counter += 1

        # Step 3: Simulation Dry-Run Estimation
        if any(k in goal_lower for k in ["simulate", "estimation", "estimate", "dry-run", "bottleneck", "prepare", "release"]):
            steps.append({
                "step_number": step_counter,
                "title": f"Simulate {target_quantity}-Unit Production Run",
                "description": f"Perform a dry-run execution simulation for {target_quantity} units to project cycle times and yield.",
                "tool_name": "simulate_process_execution",
                "tool_arguments": {"units_to_produce": target_quantity},
                "is_consequential": False,
            })
            step_counter += 1

        # Step 4: Consequential Action — Work Order Creation & Release
        if any(k in goal_lower for k in ["order", "work order", "release", "commit", "produce", "manufacture", "prepare"]):
            steps.append({
                "step_number": step_counter,
                "title": f"Create & Release Work Order ({target_quantity} Units)",
                "description": f"Generate official production work order for {target_quantity} units. Consequential: Requires human authorization.",
                "tool_name": "create_work_order",
                "tool_arguments": {
                    "quantity_target": target_quantity,
                    "priority": "HIGH" if "urgent" in goal_lower or "rush" in goal_lower else "NORMAL",
                },
                "is_consequential": True,  # PAUSES FOR HUMAN APPROVAL
            })
            step_counter += 1

        # Step 5: Post-Release Status Verification
        steps.append({
            "step_number": step_counter,
            "title": "Verify Released Work Order State",
            "description": "Confirm work order registration and verify scheduling status on the shop floor.",
            "tool_name": "inspect_work_order_status",
            "tool_arguments": {"work_order_id_or_number": ""},
            "is_consequential": False,
        })

        summary = (
            f"Autonomous {industry_profile.display_name} preparation plan for {target_quantity} units: "
            f"check material stock, validate process graph, simulate execution, request approval to release work order, and verify state."
        )

        return {
            "goal_summary": summary,
            "completion_criteria": [
                f"Sufficient material stock confirmed for {target_quantity} units",
                "Process definition graph validated without topological errors",
                "Simulation completed with projected cycle time and scrap yield",
                "Human approval granted for work order release",
                "Work order status verified in database",
            ],
            "steps": steps,
        }


class ProviderManager:
    """
    Coordinates AI provider resolution, plan generation, and provider status introspection.
    """

    @classmethod
    def get_provider_status(cls) -> Dict[str, Any]:
        """
        Returns sanitized runtime provider configuration without exposing secrets.
        """
        configured_provider = os.getenv("FACTORYOS_AI_PROVIDER", "hybrid").lower().strip()
        api_key = os.getenv("FACTORYOS_AI_API_KEY", "").strip()
        base_url = os.getenv("FACTORYOS_AI_BASE_URL", "https://api.openai.com/v1").strip()
        model_name = os.getenv("FACTORYOS_AI_MODEL", "gpt-4o-mini").strip()

        is_key_present = bool(api_key and len(api_key) > 5)
        masked_key = f"{api_key[:3]}...{api_key[-4:]}" if is_key_present else "NOT_CONFIGURED"

        # Determine effective mode
        if configured_provider == "llm":
            active_mode = "LLM (Direct)" if is_key_present else "LLM (Missing Credentials)"
        elif configured_provider == "deterministic":
            active_mode = "Deterministic Rules Engine"
        else:
            active_mode = "Hybrid (LLM with Deterministic Fallback)" if is_key_present else "Hybrid (Deterministic Active - No API Key)"

        return {
            "configured_provider": configured_provider,
            "active_mode": active_mode,
            "is_llm_available": is_key_present,
            "model_name": model_name,
            "base_url": base_url,
            "masked_api_key": masked_key,
            "timeout_seconds": int(os.getenv("FACTORYOS_AI_TIMEOUT_SECONDS", "30")),
            "max_retries": int(os.getenv("FACTORYOS_AI_MAX_RETRIES", "2")),
            "provider_version": "2.0.0",
        }

    @classmethod
    def plan_goal(
        cls,
        goal: str,
        industry_profile: IndustryProfile,
        factory_name: str,
        provider_mode_override: Optional[str] = None,
        operational_context: Optional[Dict[str, Any]] = None,
    ) -> Tuple[Dict[str, Any], str, str, bool, str]:
        """
        Generates a validated plan for the goal.
        Returns:
            (plan_data, provider_type, model_name, fallback_occurred, fallback_reason)
        """
        mode = (provider_mode_override or os.getenv("FACTORYOS_AI_PROVIDER", "hybrid")).lower().strip()
        llm_provider = OpenAICompatibleAgentProvider()

        # -------------------------------------------------------------
        # Mode 1: Pure Deterministic Mode
        # -------------------------------------------------------------
        if mode == "deterministic":
            logger.info("Executing plan generation in explicit DETERMINISTIC mode.")
            plan = DeterministicGoalPlanner.generate_plan(goal, industry_profile, factory_name)
            return plan, "deterministic", "deterministic-rules-v1", False, ""

        # -------------------------------------------------------------
        # Mode 2: Pure LLM Mode
        # -------------------------------------------------------------
        if mode == "llm":
            if not llm_provider.is_configured:
                raise LLMProviderError(
                    "FACTORYOS_AI_PROVIDER is set to 'llm', but FACTORYOS_AI_API_KEY is missing or invalid. "
                    "Cannot execute without valid credentials in strict LLM mode."
                )
            logger.info(f"Executing plan generation with live LLM model '{llm_provider.model}'.")
            plan = llm_provider.generate_plan(goal, industry_profile, factory_name, operational_context)
            return plan, "llm", llm_provider.model, False, ""

        # -------------------------------------------------------------
        # Mode 3: Hybrid Mode (Default: LLM with Explicit Fallback)
        # -------------------------------------------------------------
        if llm_provider.is_configured:
            try:
                logger.info(f"Hybrid Mode: Attempting live LLM generation with '{llm_provider.model}'...")
                plan = llm_provider.generate_plan(goal, industry_profile, factory_name, operational_context)
                return plan, "llm", llm_provider.model, False, ""
            except Exception as e:
                fallback_reason = f"LLM invocation encountered error: {str(e)[:180]}. Falling back to deterministic rules."
                logger.warning(fallback_reason)
                plan = DeterministicGoalPlanner.generate_plan(goal, industry_profile, factory_name)
                return plan, "hybrid", "deterministic-rules-v1", True, fallback_reason

        # Fallback when no LLM key is configured
        fallback_msg = (
            "No FACTORYOS_AI_API_KEY configured. Executing safe, deterministic industrial heuristic planner."
        )
        logger.info(fallback_msg)
        plan = DeterministicGoalPlanner.generate_plan(goal, industry_profile, factory_name)
        return plan, "hybrid", "deterministic-rules-v1", True, fallback_msg
