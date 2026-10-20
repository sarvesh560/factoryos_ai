"""
FactoryOS AI — AI Provider Abstraction for Agent Decision-Making
Phase 4: Multi-Agent Manufacturing Orchestration

Provides a decoupled provider interface for evaluating manufacturing events:
- BaseAgentAIProvider (Abstract Interface)
- DeterministicRuleAgentProvider (Deterministic Industrial Rules Engine)

Allows future LLM/Foundation Model integration without restructuring orchestration or security.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Dict, Any, Optional
from apps.agent_automation.models import (
    ManufacturingEvent,
    AgentConfiguration,
    DecisionStatus,
    ActionType,
    EventSeverity,
)


@dataclass
class AgentEvaluationResult:
    """
    Structured outcome returned by an AI provider for an event evaluation.
    """
    status: str
    findings: str
    evidence: Dict[str, Any] = field(default_factory=dict)
    proposed_action: str = ""
    action_parameters: Dict[str, Any] = field(default_factory=dict)
    rationale: str = ""
    confidence_score: float = 1.0
    provider_info: Dict[str, Any] = field(default_factory=dict)


class BaseAgentAIProvider(ABC):
    """
    Abstract interface for manufacturing AI agent reasoning providers.
    """
    @abstractmethod
    def evaluate(
        self,
        event: ManufacturingEvent,
        agent: AgentConfiguration,
        context: Optional[Dict[str, Any]] = None,
    ) -> AgentEvaluationResult:
        """
        Evaluates a manufacturing event against agent parameters and operational context.
        """
        pass


class DeterministicRuleAgentProvider(BaseAgentAIProvider):
    """
    Deterministic industrial heuristic and rules-based agent decision engine.
    Applies verifiable thresholds, physics-based bounds, and operational procedures.
    Zero paid API keys or external dependencies required.
    """
    PROVIDER_KEY = "DETERMINISTIC_INDUSTRIAL_RULES_V1"
    PROVIDER_NAME = "FactoryOS Deterministic Manufacturing Rules Engine"

    def evaluate(
        self,
        event: ManufacturingEvent,
        agent: AgentConfiguration,
        context: Optional[Dict[str, Any]] = None,
    ) -> AgentEvaluationResult:
        payload = event.payload or {}
        event_type = event.event_type
        agent_type = agent.agent_type
        provider_meta = {
            "provider_key": self.PROVIDER_KEY,
            "provider_name": self.PROVIDER_NAME,
            "rule_version": "1.0.0",
        }

        # -------------------------------------------------------------
        # 1. MAINTENANCE AGENT
        # -------------------------------------------------------------
        if agent_type == "MAINTENANCE":
            if event_type == "MACHINE_ANOMALY":
                machine_name = payload.get("machine_name") or payload.get("machine") or "Asset"
                machine_id = payload.get("machine_id") or event.source_id or ""
                temperature = payload.get("temperature_c") or payload.get("temperature", 0)
                vibration = payload.get("vibration_rms") or payload.get("vibration", 0)
                anomaly_type = payload.get("anomaly_type") or payload.get("anomaly") or "Mechanical Variance"
                error_code = payload.get("error_code", "ERR-MNT-901")

                is_critical = (
                    event.severity in [EventSeverity.CRITICAL, EventSeverity.ERROR]
                    or temperature > 85.0
                    or vibration > 6.5
                )

                if is_critical:
                    findings = (
                        f"Critical anomaly detected on {machine_name}: '{anomaly_type}'. "
                        f"Operational limits breached (Temp: {temperature}°C, Vibration: {vibration} mm/s)."
                    )
                    evidence = {
                        "machine_name": machine_name,
                        "machine_id": machine_id,
                        "temperature_c": temperature,
                        "vibration_rms": vibration,
                        "threshold_temp_max": 85.0,
                        "threshold_vibration_max": 6.5,
                        "severity": event.severity,
                        "error_code": error_code,
                    }
                    action_params = {
                        "machine_id": machine_id,
                        "machine_name": machine_name,
                        "priority": "HIGH" if event.severity == EventSeverity.CRITICAL else "NORMAL",
                        "issue_description": findings,
                        "suggested_technician": "Mechanical Reliability Specialist",
                        "estimated_downtime_minutes": 45,
                    }
                    rationale = (
                        f"Machine telemetry exceeds baseline ISO 10816 vibration thresholds and thermal tolerances. "
                        f"Immediate maintenance inspection order is required to prevent catastrophic spindle/bearing failure."
                    )
                    return AgentEvaluationResult(
                        status=DecisionStatus.AWAITING_APPROVAL if agent.requires_approval else DecisionStatus.ACTION_REQUESTED,
                        findings=findings,
                        evidence=evidence,
                        proposed_action=ActionType.CREATE_MAINTENANCE_TICKET,
                        action_parameters=action_params,
                        rationale=rationale,
                        confidence_score=0.98,
                        provider_info=provider_meta,
                    )
                else:
                    return AgentEvaluationResult(
                        status=DecisionStatus.RECOMMENDATION,
                        findings=f"Minor telemetry variance on {machine_name} within non-critical tolerances.",
                        evidence={"temperature_c": temperature, "vibration_rms": vibration},
                        proposed_action="",
                        action_parameters={},
                        rationale="Telemetry variance is within safe operating margins; routine monitoring advised.",
                        confidence_score=0.85,
                        provider_info=provider_meta,
                    )

            elif event_type == "MAINTENANCE_DUE":
                machine_name = payload.get("machine_name", "Equipment Unit")
                machine_id = payload.get("machine_id", event.source_id or "")
                hours_run = payload.get("operating_hours", 250)
                findings = f"Preventive maintenance threshold reached for {machine_name} ({hours_run} operating hours)."
                return AgentEvaluationResult(
                    status=DecisionStatus.AWAITING_APPROVAL if agent.requires_approval else DecisionStatus.ACTION_REQUESTED,
                    findings=findings,
                    evidence={"operating_hours": hours_run, "scheduled_interval": 250},
                    proposed_action=ActionType.CREATE_MAINTENANCE_TICKET,
                    action_parameters={
                        "machine_id": machine_id,
                        "machine_name": machine_name,
                        "priority": "NORMAL",
                        "issue_description": findings,
                    },
                    rationale="Standard 250-hour preventative lubrication and filter inspection protocol due.",
                    confidence_score=1.0,
                    provider_info=provider_meta,
                )

        # -------------------------------------------------------------
        # 2. PRODUCTION AGENT
        # -------------------------------------------------------------
        elif agent_type == "PRODUCTION":
            if event_type == "PRODUCTION_DELAY":
                line_name = payload.get("line_name", "Production Line")
                line_id = payload.get("line_id", event.source_id or "")
                work_order_id = payload.get("work_order_id", "")
                cycle_variance_pct = payload.get("cycle_variance_pct") or payload.get("delay_percentage", 25.0)
                bottleneck_stage = payload.get("stage_name") or payload.get("bottleneck_node", "Assembly Station")

                findings = (
                    f"Line throughput degradation on {line_name} (Bottleneck: {bottleneck_stage}). "
                    f"Cycle time inflated by {cycle_variance_pct:.1f}% over nominal specification."
                )
                evidence = {
                    "line_id": line_id,
                    "line_name": line_name,
                    "work_order_id": work_order_id,
                    "bottleneck_stage": bottleneck_stage,
                    "cycle_variance_pct": cycle_variance_pct,
                    "tolerance_limit_pct": 15.0,
                }
                action_params = {
                    "line_id": line_id,
                    "line_name": line_name,
                    "work_order_id": work_order_id,
                    "bottleneck_stage": bottleneck_stage,
                    "investigation_scope": "Cycle Time & Operator Pacing Audit",
                    "priority": "HIGH" if cycle_variance_pct > 30 else "NORMAL",
                }
                rationale = (
                    f"Throughput velocity variance exceeds allowable 15% line standard deviation. "
                    f"Formal line investigation recommended to resolve queue buildup and rebalance routing pacing."
                )
                return AgentEvaluationResult(
                    status=DecisionStatus.AWAITING_APPROVAL if agent.requires_approval else DecisionStatus.ACTION_REQUESTED,
                    findings=findings,
                    evidence=evidence,
                    proposed_action=ActionType.CREATE_PRODUCTION_INVESTIGATION,
                    action_parameters=action_params,
                    rationale=rationale,
                    confidence_score=0.94,
                    provider_info=provider_meta,
                )

            elif event_type == "WORK_ORDER_STATUS_CHANGED":
                new_status = payload.get("new_status", "UNKNOWN")
                order_num = payload.get("order_number", "WO-Order")
                findings = f"Work order {order_num} transitioned to status '{new_status}'."
                return AgentEvaluationResult(
                    status=DecisionStatus.RECOMMENDATION,
                    findings=findings,
                    evidence={"status": new_status, "order_number": order_num},
                    proposed_action="",
                    action_parameters={},
                    rationale="State transition logged for production scheduling schedule tracking.",
                    confidence_score=1.0,
                    provider_info=provider_meta,
                )

        # -------------------------------------------------------------
        # 3. QUALITY AGENT
        # -------------------------------------------------------------
        elif agent_type == "QUALITY":
            if event_type == "QUALITY_FAILURE":
                product_name = payload.get("product_name", "Component")
                work_order_id = payload.get("work_order_id", "")
                stage_name = payload.get("stage_name", "Quality Inspection Gate")
                scrap_rate_pct = payload.get("scrap_rate_pct") or payload.get("scrap_rate", 8.5)
                defect_type = payload.get("defect_type", "Dimensional Out-of-Tolerance")
                defect_units = payload.get("defect_units", 12)

                findings = (
                    f"Quality threshold breach in stage '{stage_name}' for {product_name}. "
                    f"Scrap rate of {scrap_rate_pct:.1f}% exceeds 2.0% quality gate limit ({defect_units} defect units: {defect_type})."
                )
                evidence = {
                    "stage_name": stage_name,
                    "product_name": product_name,
                    "work_order_id": work_order_id,
                    "scrap_rate_pct": scrap_rate_pct,
                    "scrap_threshold_pct": 2.0,
                    "defect_type": defect_type,
                    "defect_units": defect_units,
                }
                action_params = {
                    "work_order_id": work_order_id,
                    "stage_name": stage_name,
                    "defect_type": defect_type,
                    "defect_count": defect_units,
                    "inspection_protocol": "First Article & Lot Sampling Verification",
                    "priority": "HIGH",
                }
                rationale = (
                    f"Scrap yield exceeds acceptable statistical process control (SPC) threshold by {scrap_rate_pct - 2.0:.1f}%. "
                    f"Immediate containment quality inspection required to prevent downstream defective batch processing."
                )
                return AgentEvaluationResult(
                    status=DecisionStatus.AWAITING_APPROVAL if agent.requires_approval else DecisionStatus.ACTION_REQUESTED,
                    findings=findings,
                    evidence=evidence,
                    proposed_action=ActionType.CREATE_QUALITY_INSPECTION,
                    action_parameters=action_params,
                    rationale=rationale,
                    confidence_score=0.96,
                    provider_info=provider_meta,
                )

        # -------------------------------------------------------------
        # 4. INVENTORY AGENT
        # -------------------------------------------------------------
        elif agent_type == "INVENTORY":
            if event_type == "INVENTORY_SHORTAGE":
                material_name = payload.get("material_name", "Raw Inventory Item")
                material_id = payload.get("material_id", "")
                current_stock = payload.get("current_stock", 0)
                safety_stock = payload.get("safety_stock", 100)
                unit_of_measure = payload.get("unit_of_measure", "kg")
                recommended_qty = payload.get("reorder_quantity") or max(200, (safety_stock * 2) - current_stock)

                findings = (
                    f"Raw material inventory critical starvation: '{material_name}'. "
                    f"Available stock ({current_stock} {unit_of_measure}) below safety threshold ({safety_stock} {unit_of_measure})."
                )
                evidence = {
                    "material_id": material_id,
                    "material_name": material_name,
                    "current_stock": current_stock,
                    "safety_stock": safety_stock,
                    "unit_of_measure": unit_of_measure,
                    "shortage_deficit": safety_stock - current_stock,
                }
                action_params = {
                    "material_id": material_id,
                    "material_name": material_name,
                    "reorder_quantity": recommended_qty,
                    "unit_of_measure": unit_of_measure,
                    "priority": "URGENT" if current_stock <= 0 else "HIGH",
                }
                rationale = (
                    f"Stock levels below buffer minimum threaten scheduled work order continuity. "
                    f"Immediate inventory purchase replenishment request proposed to restore safe buffer stock."
                )
                return AgentEvaluationResult(
                    status=DecisionStatus.AWAITING_APPROVAL if agent.requires_approval else DecisionStatus.ACTION_REQUESTED,
                    findings=findings,
                    evidence=evidence,
                    proposed_action=ActionType.CREATE_INVENTORY_REPLENISHMENT_REQUEST,
                    action_parameters=action_params,
                    rationale=rationale,
                    confidence_score=0.99,
                    provider_info=provider_meta,
                )

        # -------------------------------------------------------------
        # 5. ENERGY AGENT
        # -------------------------------------------------------------
        elif agent_type == "ENERGY":
            power_kw = payload.get("power_kw") or payload.get("energy_consumption_kwh", 0)
            baseline_kw = payload.get("baseline_power_kw", 40.0)
            if power_kw > (baseline_kw * 1.35):
                findings = (
                    f"Excessive electrical energy demand detected ({power_kw:.1f} kW vs {baseline_kw:.1f} kW nominal baseline)."
                )
                return AgentEvaluationResult(
                    status=DecisionStatus.RECOMMENDATION,
                    findings=findings,
                    evidence={"power_kw": power_kw, "baseline_kw": baseline_kw, "surge_pct": ((power_kw / baseline_kw) - 1.0) * 100},
                    proposed_action="",
                    action_parameters={},
                    rationale="Peak load power spike detected; recommend shifting auxiliary non-critical pump loads to off-peak.",
                    confidence_score=0.88,
                    provider_info=provider_meta,
                )

        # Fallback: No specific action proposed for this combination
        return AgentEvaluationResult(
            status=DecisionStatus.NO_ACTION,
            findings=f"Event {event_type} evaluated by {agent.name}; standard operational parameters satisfied.",
            evidence={"event_type": event_type, "severity": event.severity},
            proposed_action="",
            action_parameters={},
            rationale="No threshold breach or intervention triggers met according to established SOP rules.",
            confidence_score=1.0,
            provider_info=provider_meta,
        )
