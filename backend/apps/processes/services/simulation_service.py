"""
FactoryOS AI — Manufacturing Simulation Engine
Phase 3: Configurable Simulation Scenarios, Anomaly Injection & Reproducible Deterministic Runs
"""
import random
from typing import Dict, Any, Optional
from django.db import transaction
from django.utils import timezone
from apps.processes.models import (
    ProcessExecution,
    StageExecution,
    ProductionEvent,
    SimulationScenario,
)
from apps.processes.services.execution_service import ProductionExecutionService

class ManufacturingSimulationEngine:
    """
    Simulation Engine generating realistic factory events,
    machine failures, quality fluctuations, and line bottlenecks
    without issuing real machine commands.
    """

    @classmethod
    @transaction.atomic
    def inject_anomaly(
        cls,
        execution: ProcessExecution,
        scenario_type: str,
        parameters: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Injects a simulated operational anomaly into an active process execution.
        """
        params = parameters or {}
        factory = execution.work_order.factory
        active_stage = execution.stage_executions.filter(status="RUNNING").first()

        if not active_stage:
            # Pick any ready or pending stage
            active_stage = execution.stage_executions.filter(status__in=["READY", "PENDING"]).exclude(node__node_type__in=["START", "END"]).first()

        result = {
            "execution_id": str(execution.id),
            "scenario_type": scenario_type,
            "success": True,
            "message": "",
        }

        event = None
        if scenario_type == "MACHINE_BREAKDOWN":
            machine_name = "Primary Spindle Cell"
            if active_stage and active_stage.assigned_machine:
                machine_name = active_stage.assigned_machine.name
                active_stage.assigned_machine.status = "MAINTENANCE"
                active_stage.assigned_machine.save(update_fields=["status", "updated_at"])

            if active_stage:
                active_stage.status = "BLOCKED"
                active_stage.error_message = f"Simulated unscheduled breakdown on {machine_name}."
                active_stage.save(update_fields=["status", "error_message", "updated_at"])

            execution.status = "BLOCKED"
            if active_stage:
                execution.bottleneck_node = active_stage.node
            execution.save(update_fields=["status", "bottleneck_node", "updated_at"])

            msg = f"Simulated anomaly: Machine breakdown on '{machine_name}'."
            result["message"] = msg
            event = ProductionEvent.objects.create(
                factory=factory,
                work_order=execution.work_order,
                process_execution=execution,
                stage_execution=active_stage,
                event_type="SIMULATION_ANOMALY_INJECTED",
                severity="CRITICAL",
                source="SIMULATION",
                message=msg,
                payload={"anomaly": "MACHINE_BREAKDOWN", "machine": machine_name}
            )

        elif scenario_type == "MATERIAL_SHORTAGE":
            mat_name = params.get("material_name", "Raw Inventory Component")
            if active_stage:
                active_stage.status = "BLOCKED"
                active_stage.error_message = f"Simulated material starvation: {mat_name} out of stock."
                active_stage.save(update_fields=["status", "error_message", "updated_at"])

            execution.status = "BLOCKED"
            if active_stage:
                execution.bottleneck_node = active_stage.node
            execution.save(update_fields=["status", "bottleneck_node", "updated_at"])

            msg = f"Simulated anomaly: Raw material starvation for '{mat_name}'."
            result["message"] = msg
            event = ProductionEvent.objects.create(
                factory=factory,
                work_order=execution.work_order,
                process_execution=execution,
                stage_execution=active_stage,
                event_type="SIMULATION_ANOMALY_INJECTED",
                severity="WARNING",
                source="SIMULATION",
                message=msg,
                payload={"anomaly": "MATERIAL_SHORTAGE", "material": mat_name}
            )

        elif scenario_type == "PRODUCTION_DELAY":
            delay_factor = float(params.get("delay_multiplier", 2.5))
            node_name = active_stage.node.name if active_stage else "Current Operation"
            msg = f"Simulated anomaly: Micro-stoppage cycle delay ({delay_factor}x slowdown) on '{node_name}'."
            result["message"] = msg

            if active_stage:
                execution.bottleneck_node = active_stage.node
                execution.save(update_fields=["bottleneck_node", "updated_at"])

            event = ProductionEvent.objects.create(
                factory=factory,
                work_order=execution.work_order,
                process_execution=execution,
                stage_execution=active_stage,
                event_type="SIMULATION_ANOMALY_INJECTED",
                severity="WARNING",
                source="SIMULATION",
                message=msg,
                payload={"anomaly": "PRODUCTION_DELAY", "factor": delay_factor}
            )

        elif scenario_type == "QUALITY_REJECTION":
            scrap_units = int(params.get("scrap_units", 15))
            node_name = active_stage.node.name if active_stage else "Quality Gate"
            msg = f"Simulated anomaly: Out-of-tolerance defect spike ({scrap_units} rejected parts) on '{node_name}'."
            result["message"] = msg

            event = ProductionEvent.objects.create(
                factory=factory,
                work_order=execution.work_order,
                process_execution=execution,
                stage_execution=active_stage,
                event_type="SIMULATION_ANOMALY_INJECTED",
                severity="WARNING",
                source="SIMULATION",
                message=msg,
                payload={"anomaly": "QUALITY_REJECTION", "scrap_spike": scrap_units}
            )

            # If stage is running, complete it with scrap
            if active_stage and active_stage.status == "RUNNING":
                ProductionExecutionService.advance_stage(
                    stage_execution=active_stage,
                    units_scrapped=scrap_units
                )

        elif scenario_type == "BOTTLENECK_FORMATION":
            node_name = active_stage.node.name if active_stage else "Intermediate Operation"
            if active_stage:
                execution.bottleneck_node = active_stage.node
                execution.save(update_fields=["bottleneck_node", "updated_at"])

            msg = f"Simulated anomaly: Queue backlog exceeded threshold (Bottleneck on '{node_name}')."
            result["message"] = msg
            event = ProductionEvent.objects.create(
                factory=factory,
                work_order=execution.work_order,
                process_execution=execution,
                stage_execution=active_stage,
                event_type="BOTTLENECK_DETECTED",
                severity="WARNING",
                source="SIMULATION",
                message=msg,
                payload={"bottleneck_node": node_name}
            )

        else:
            msg = f"Simulated event trigger: {scenario_type} executed."
            result["message"] = msg
            event = ProductionEvent.objects.create(
                factory=factory,
                work_order=execution.work_order,
                process_execution=execution,
                event_type="SIMULATION_ANOMALY_INJECTED",
                severity="INFO",
                source="SIMULATION",
                message=msg,
                payload={"scenario": scenario_type}
            )

        if event:
            from apps.processes.serializers import ProductionEventSerializer
            result["event"] = ProductionEventSerializer(event).data

        return result

    @classmethod
    @transaction.atomic
    def step_simulation(cls, execution: ProcessExecution, random_seed: int = 42) -> Optional[StageExecution]:
        """
        Advances the next active or ready operation in the graph deterministically.
        """
        rnd = random.Random(random_seed + execution.stage_executions.filter(status="COMPLETED").count())

        # If execution is BLOCKED, clear blockage first for simulation flow
        if execution.status == "BLOCKED":
            blocked_stage = execution.stage_executions.filter(status="BLOCKED").first()
            if blocked_stage:
                blocked_stage.status = "RUNNING"
                blocked_stage.error_message = ""
                blocked_stage.save(update_fields=["status", "error_message", "updated_at"])
            execution.status = "RUNNING"
            execution.bottleneck_node = None
            execution.save(update_fields=["status", "bottleneck_node", "updated_at"])

        # Find running stage
        running = execution.stage_executions.filter(status="RUNNING").exclude(node__node_type__in=["START", "END"]).first()
        if not running:
            # Check ready stage
            ready = execution.stage_executions.filter(status="READY").exclude(node__node_type__in=["START", "END"]).first()
            if ready:
                ready.status = "RUNNING"
                ready.save(update_fields=["status", "updated_at"])
                running = ready

        if not running:
            # Check if any pending stage can be activated
            pending = execution.stage_executions.filter(status="PENDING").exclude(node__node_type__in=["START", "END"]).first()
            if pending:
                ProductionExecutionService._activate_stage_if_ready(
                    execution, pending, execution.work_order.quantity_target
                )
                running = pending if pending.status == "RUNNING" else None

        if running:
            # Calculate deterministic yield and scrap
            base_yield = running.node.yield_rate_percent or 98.0
            variance = rnd.uniform(-1.5, 1.5)
            actual_yield = max(80.0, min(100.0, base_yield + variance))
            total_in = running.units_in_progress or execution.work_order.quantity_target
            good_units = int(round(total_in * (actual_yield / 100.0)))
            scrap = max(0, total_in - good_units)

            return ProductionExecutionService.advance_stage(
                stage_execution=running,
                units_completed=good_units,
                units_scrapped=scrap,
                duration_seconds=running.node.cycle_time_seconds
            )

        return None

    @classmethod
    @transaction.atomic
    def run_full_simulation(
        cls,
        execution: ProcessExecution,
        random_seed: int = 42,
        max_steps: int = 50,
    ) -> Dict[str, Any]:
        """
        Executes all remaining operations in the process graph deterministically until completion.
        """
        step_count = 0
        while execution.status in ("RUNNING", "INITIALIZED", "BLOCKED") and step_count < max_steps:
            advanced = cls.step_simulation(execution, random_seed=random_seed + step_count)
            step_count += 1
            execution.refresh_from_db()
            if not advanced and execution.status != "RUNNING":
                break

        return {
            "execution_id": str(execution.id),
            "status": execution.status,
            "progress_percent": execution.current_progress_percent,
            "steps_executed": step_count,
            "total_output": execution.total_units_output,
            "total_scrap": execution.total_units_scrap,
        }
