"""
FactoryOS AI — Real OpenAI-Compatible LLM Provider for Goal-Driven Agent Planning
Phase 4, Step 2: Goal Parsing, Tool Selection, and Structured Plan Generation

Supports standard OpenAI REST API endpoints (OpenAI, Groq, Ollama, vLLM, DeepSeek, etc.)
via httpx with connection pooling, timeouts, and retry logic.
Validates structured JSON output strictly against permitted typed tools.
"""
import os
import json
import logging
from typing import Dict, Any, List, Optional, Tuple
import httpx

from apps.agent_automation.services.industry_profiles import IndustryProfile, IndustryProfileRegistry
from apps.agent_automation.services.tool_registry import ManufacturingToolRegistry

logger = logging.getLogger(__name__)


class LLMProviderError(Exception):
    """Raised when an LLM provider request fails, times out, or returns invalid schemas."""
    pass


class OpenAICompatibleAgentProvider:
    """
    Production-grade LLM provider communicating with OpenAI-compatible REST endpoints.
    Enforces structured JSON output and schema validation.
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        model: Optional[str] = None,
        timeout_seconds: Optional[int] = None,
        max_retries: Optional[int] = None,
    ):
        self.api_key = (api_key or os.getenv("FACTORYOS_AI_API_KEY", "")).strip()
        self.base_url = (base_url or os.getenv("FACTORYOS_AI_BASE_URL", "https://api.openai.com/v1")).rstrip("/")
        self.model = model or os.getenv("FACTORYOS_AI_MODEL", "gpt-4o-mini")
        
        try:
            self.timeout_seconds = int(timeout_seconds or os.getenv("FACTORYOS_AI_TIMEOUT_SECONDS", "30"))
        except (ValueError, TypeError):
            self.timeout_seconds = 30
            
        try:
            self.max_retries = int(max_retries or os.getenv("FACTORYOS_AI_MAX_RETRIES", "2"))
        except (ValueError, TypeError):
            self.max_retries = 2

    @property
    def is_configured(self) -> bool:
        """Returns True if a non-empty API key is configured."""
        return bool(self.api_key and len(self.api_key) > 5)

    def generate_plan(
        self,
        goal: str,
        industry_profile: IndustryProfile,
        factory_name: str,
        operational_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Interprets natural-language goal and returns a structured, validated execution plan.
        """
        if not self.is_configured:
            raise LLMProviderError(
                "FACTORYOS_AI_API_KEY is not configured or is empty. Cannot invoke live LLM."
            )

        # 1. Gather permitted tools metadata for this profile
        available_tools = []
        for tool_name in industry_profile.permitted_tools:
            tool = ManufacturingToolRegistry.get_tool(tool_name)
            if tool:
                available_tools.append(tool.to_metadata())

        # 2. Build system instructions
        system_prompt = (
            "You are FactoryOS AI's autonomous manufacturing goal planner. "
            f"You are orchestrating operations for factory '{factory_name}' under the '{industry_profile.display_name}' profile (v{industry_profile.version}).\n\n"
            f"Regulatory Framework: {industry_profile.regulatory_framework}\n"
            f"Profile Constraints: {json.dumps(industry_profile.process_constraints)}\n"
            f"Terminology: {json.dumps(industry_profile.terminology)}\n\n"
            "You MUST decompose the user's manufacturing goal into an ordered, minimal set of permitted tool calls.\n"
            "AVAILABLE TOOLS:\n"
            f"{json.dumps(available_tools, indent=2)}\n\n"
            "STRICT RULES:\n"
            "1. ONLY use tool names from the permitted available tools list.\n"
            "2. Tool 'create_work_order' is CONSEQUENTIAL and will pause for human approval. Mark is_consequential=true.\n"
            "3. If critical information is missing to proceed safely, invoke 'request_human_clarification'.\n"
            "4. Return ONLY valid JSON matching this schema:\n"
            "{\n"
            '  "goal_summary": "Concise summary of manufacturing objective",\n'
            '  "completion_criteria": ["Criteria 1", "Criteria 2"],\n'
            '  "steps": [\n'
            '    {\n'
            '      "step_number": 1,\n'
            '      "title": "Short title",\n'
            '      "description": "Explanation",\n'
            '      "tool_name": "exact_tool_name",\n'
            '      "tool_arguments": { ... },\n'
            '      "is_consequential": true/false\n'
            '    }\n'
            '  ]\n'
            "}"
        )

        user_prompt = f"Manufacturing Goal:\n\"{goal}\"\n\nContext:\n{json.dumps(operational_context or {})}"

        # 3. Issue HTTP Request to OpenAI-compatible Chat Completions endpoint
        endpoint = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.2,
        }

        last_error = None
        for attempt in range(1 + self.max_retries):
            try:
                with httpx.Client(timeout=self.timeout_seconds) as client:
                    response = client.post(endpoint, json=payload, headers=headers)
                    if response.status_code != 200:
                        raise LLMProviderError(
                            f"LLM API returned HTTP {response.status_code}: {response.text[:200]}"
                        )
                    res_json = response.json()
                    content = res_json["choices"][0]["message"]["content"]
                    parsed = json.loads(content)

                    # 4. Schema validation
                    return self._validate_and_sanitize_plan(parsed, industry_profile)

            except (httpx.TimeoutException, httpx.NetworkError) as e:
                last_error = f"Network or timeout error calling LLM provider: {str(e)}"
                logger.warning(f"LLM request attempt {attempt + 1} failed: {last_error}")
            except (json.JSONDecodeError, KeyError) as e:
                last_error = f"Malformed JSON from LLM: {str(e)}"
                logger.warning(f"LLM response parsing attempt {attempt + 1} failed: {last_error}")
            except Exception as e:
                last_error = str(e)
                logger.warning(f"LLM invocation attempt {attempt + 1} failed: {last_error}")

        raise LLMProviderError(f"LLM plan generation failed after {self.max_retries + 1} attempts. Last error: {last_error}")

    def _validate_and_sanitize_plan(
        self,
        plan_dict: Dict[str, Any],
        industry_profile: IndustryProfile,
    ) -> Dict[str, Any]:
        """
        Validates that all steps in the plan strictly adhere to permitted tools and required fields.
        """
        if not isinstance(plan_dict, dict):
            raise LLMProviderError("Plan root must be a JSON object.")

        goal_summary = str(plan_dict.get("goal_summary", "Autonomous Manufacturing Plan")).strip()
        completion_criteria = plan_dict.get("completion_criteria", [])
        if not isinstance(completion_criteria, list):
            completion_criteria = [str(completion_criteria)]

        raw_steps = plan_dict.get("steps", [])
        if not isinstance(raw_steps, list) or not raw_steps:
            raise LLMProviderError("Plan must contain at least one step in 'steps' list.")

        sanitized_steps = []
        for idx, step in enumerate(raw_steps, start=1):
            if not isinstance(step, dict):
                continue

            tool_name = str(step.get("tool_name", "")).strip()
            # Validate tool against active industry profile
            if not IndustryProfileRegistry.is_tool_permitted(industry_profile.key, tool_name):
                raise LLMProviderError(
                    f"Tool '{tool_name}' in step {idx} is not permitted for industry '{industry_profile.display_name}'."
                )

            tool = ManufacturingToolRegistry.get_tool(tool_name)
            if not tool:
                raise LLMProviderError(f"Tool '{tool_name}' in step {idx} does not exist in registry.")

            title = str(step.get("title", f"Step {idx}: {tool_name}")).strip()
            desc = str(step.get("description", "")).strip()
            args = step.get("tool_arguments", {})
            if not isinstance(args, dict):
                args = {}

            is_consequential = (tool.side_effect == "CONSEQUENTIAL") or bool(step.get("is_consequential", False))

            sanitized_steps.append({
                "step_number": idx,
                "title": title,
                "description": desc,
                "tool_name": tool_name,
                "tool_arguments": args,
                "is_consequential": is_consequential,
            })

        return {
            "goal_summary": goal_summary,
            "completion_criteria": completion_criteria,
            "steps": sanitized_steps,
        }
