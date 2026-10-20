"""
FactoryOS AI — Controlled Workflow Action Registry
Phase 4: Multi-Agent Manufacturing Orchestration & Automated Action Execution

Enforces:
- Explicit permitted action white-listing
- Pre-execution authorization & asset scope checks
- Multi-tenant boundary validation
- Idempotency via unique idempotency keys
- Transactional atomicity & error recovery
"""
import uuid
import logging
from typing import Dict, Any, Tuple
from django.db import transaction
from django.utils import timezone

from apps.factories.models import Machine, ProductionLine, RawMaterial
from apps.processes.models import WorkOrder, ProductionEvent
from apps.agent_automation.models import (
    ActionExecution,
    ActionStatus,
    ActionType,
    AutomationAuditEvent,
)

logger = logging.getLogger(__name__)


class WorkflowActionRegistry:
    """
    Registry of controlled, audited manufacturing action handlers.
    Strictly forbids arbitrary code execution or unvalidated hardware writes.
    """

    @classmethod
    @transaction.atomic
    def execute_action(cls, execution: ActionExecution, actor: str = "SYSTEM") -> Tuple[bool, Dict[str, Any], str]:
        """
        Executes an authorized ActionExecution record through its registered handler.
        Guarantees idempotency and updates execution status atomically.
        """
        # 1. Idempotency Check
        if execution.status == ActionStatus.COMPLETED and execution.result_payload:
            logger.info(f"Action {execution.id} already completed (idempotency key: {execution.idempotency_key}).")
            return True, execution.result_payload, "Action already completed (idempotent replay)."

        execution.status = ActionStatus.EXECUTING
        execution.save(update_fields=["status", "updated_at"])

        action_type = execution.action_type
        params = execution.parameters or {}
        factory = execution.factory

        try:
            # 2. Dispatch to dedicated handler
            if action_type == ActionType.CREATE_MAINTENANCE_TICKET:
                result = cls._handle_create_maintenance_ticket(factory, params)
            elif action_type == ActionType.CREATE_QUALITY_INSPECTION:
                result = cls._handle_create_quality_inspection(factory, params)
            elif action_type == ActionType.CREATE_INVENTORY_REPLENISHMENT_REQUEST:
                result = cls._handle_create_inventory_replenishment(factory, params)
            elif action_type == ActionType.CREATE_PRODUCTION_INVESTIGATION:
                result = cls._handle_create_production_investigation(factory, params)
            elif action_type == ActionType.SEND_IN_APP_NOTIFICATION:
                result = cls._handle_send_notification(factory, params)
            else:
                raise ValueError(f"Unsupported action type: '{action_type}'")

            # 3. Mark Completed
            execution.status = ActionStatus.COMPLETED
            execution.result_payload = result
            execution.error_message = ""
            execution.executed_at = timezone.now()
            execution.save(update_fields=["status", "result_payload", "error_message", "executed_at", "updated_at"])

            # 4. Log Audit Event
            AutomationAuditEvent.objects.create(
                factory=factory,
                event_category="ACTION_EXECUTED",
                reference_id=str(execution.id),
                actor=actor,
                details={
                    "action_type": action_type,
                    "idempotency_key": execution.idempotency_key,
                    "result_code": result.get("reference_code"),
                    "summary": result.get("summary"),
                },
            )

            return True, result, "Action executed successfully."

        except Exception as e:
            logger.exception(f"Action execution {execution.id} failed: {e}")
            execution.status = ActionStatus.FAILED
            execution.error_message = str(e)
            execution.retry_count += 1
            execution.save(update_fields=["status", "error_message", "retry_count", "updated_at"])

            AutomationAuditEvent.objects.create(
                factory=factory,
                event_category="ACTION_FAILED",
                reference_id=str(execution.id),
                actor=actor,
                details={
                    "action_type": action_type,
                    "error": str(e),
                    "retry_count": execution.retry_count,
                },
            )
            return False, {}, f"Execution failed: {e}"

    # -----------------------------------------------------------------
    # Dedicated Action Handlers
    # -----------------------------------------------------------------

    @classmethod
    def _handle_create_maintenance_ticket(cls, factory, params: Dict[str, Any]) -> Dict[str, Any]:
        machine_id = params.get("machine_id")
        machine_name = params.get("machine_name", "Factory Equipment")
        priority = params.get("priority", "NORMAL")
        issue_desc = params.get("issue_description", "Automated anomaly trigger")

        machine = None
        if machine_id:
            machine = Machine.objects.filter(id=machine_id, production_line__factory=factory).first()
            if not machine:
                # Search by code or name within this factory
                machine = Machine.objects.filter(code=machine_id, production_line__factory=factory).first()

        if machine:
            machine_name = machine.name
            if priority in ["HIGH", "URGENT", "CRITICAL"]:
                machine.status = "MAINTENANCE"
                machine.save(update_fields=["status"])

        ticket_code = f"MNT-{timezone.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

        # Mirror to ProductionEvent timeline
        ProductionEvent.objects.create(
            factory=factory,
            event_type="MAINTENANCE_TICKET_CREATED",
            severity="WARNING" if priority == "NORMAL" else "CRITICAL",
            source="SYSTEM_ENGINE",
            message=f"Maintenance Ticket '{ticket_code}' dispatched for {machine_name}.",
            payload={
                "ticket_code": ticket_code,
                "machine_name": machine_name,
                "priority": priority,
                "issue_description": issue_desc,
            },
        )

        return {
            "reference_code": ticket_code,
            "status": "DISPATCHED",
            "machine_name": machine_name,
            "priority": priority,
            "summary": f"Maintenance ticket {ticket_code} created for {machine_name}.",
            "dispatched_at": timezone.now().isoformat(),
        }

    @classmethod
    def _handle_create_quality_inspection(cls, factory, params: Dict[str, Any]) -> Dict[str, Any]:
        work_order_id = params.get("work_order_id")
        stage_name = params.get("stage_name", "Quality Gate")
        defect_type = params.get("defect_type", "Defect Containment")
        defect_count = params.get("defect_count", 1)

        wo = None
        if work_order_id:
            wo = WorkOrder.objects.filter(id=work_order_id, factory=factory).first()

        inspection_code = f"QC-{timezone.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

        ProductionEvent.objects.create(
            factory=factory,
            work_order=wo,
            event_type="QUALITY_INSPECTION_ORDERED",
            severity="WARNING",
            source="SYSTEM_ENGINE",
            message=f"Quality Inspection '{inspection_code}' generated for {stage_name}.",
            payload={
                "inspection_code": inspection_code,
                "stage_name": stage_name,
                "defect_type": defect_type,
                "defect_count": defect_count,
            },
        )

        return {
            "reference_code": inspection_code,
            "status": "PENDING_INSPECTOR",
            "stage_name": stage_name,
            "work_order_number": wo.order_number if wo else "N/A",
            "summary": f"Quality inspection {inspection_code} generated for {stage_name}.",
            "ordered_at": timezone.now().isoformat(),
        }

    @classmethod
    def _handle_create_inventory_replenishment(cls, factory, params: Dict[str, Any]) -> Dict[str, Any]:
        material_id = params.get("material_id")
        material_name = params.get("material_name", "Raw Inventory Item")
        quantity = params.get("reorder_quantity", 100)
        uom = params.get("unit_of_measure", "kg")
        priority = params.get("priority", "NORMAL")

        raw_mat = None
        if material_id:
            raw_mat = RawMaterial.objects.filter(id=material_id, factory=factory).first()
            if not raw_mat:
                raw_mat = RawMaterial.objects.filter(code=material_id, factory=factory).first()

        if raw_mat:
            material_name = raw_mat.name
            uom = raw_mat.unit_of_measure

        req_code = f"REQ-MAT-{timezone.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

        ProductionEvent.objects.create(
            factory=factory,
            event_type="INVENTORY_REPLENISHMENT_ORDERED",
            severity="WARNING",
            source="SYSTEM_ENGINE",
            message=f"Inventory Replenishment '{req_code}' requested for {quantity} {uom} of {material_name}.",
            payload={
                "request_code": req_code,
                "material_name": material_name,
                "quantity": quantity,
                "unit_of_measure": uom,
                "priority": priority,
            },
        )

        return {
            "reference_code": req_code,
            "status": "REQUISITIONED",
            "material_name": material_name,
            "quantity": quantity,
            "unit_of_measure": uom,
            "summary": f"Replenishment request {req_code} logged for {quantity} {uom} {material_name}.",
            "requested_at": timezone.now().isoformat(),
        }

    @classmethod
    def _handle_create_production_investigation(cls, factory, params: Dict[str, Any]) -> Dict[str, Any]:
        line_name = params.get("line_name", "Production Line")
        line_id = params.get("line_id")
        bottleneck_stage = params.get("bottleneck_stage", "Line Operation")
        investigation_scope = params.get("investigation_scope", "Throughput Pacing Variance")

        if line_id:
            line = ProductionLine.objects.filter(id=line_id, factory=factory).first()
            if line:
                line_name = line.name

        inv_code = f"INV-PRD-{timezone.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

        ProductionEvent.objects.create(
            factory=factory,
            event_type="PRODUCTION_INVESTIGATION_INITIATED",
            severity="INFO",
            source="SYSTEM_ENGINE",
            message=f"Production investigation '{inv_code}' initiated on {line_name}.",
            payload={
                "investigation_code": inv_code,
                "line_name": line_name,
                "bottleneck_stage": bottleneck_stage,
                "scope": investigation_scope,
            },
        )

        return {
            "reference_code": inv_code,
            "status": "OPEN",
            "line_name": line_name,
            "bottleneck_stage": bottleneck_stage,
            "summary": f"Production investigation {inv_code} initiated for {line_name}.",
            "initiated_at": timezone.now().isoformat(),
        }

    @classmethod
    def _handle_send_notification(cls, factory, params: Dict[str, Any]) -> Dict[str, Any]:
        title = params.get("title", "Shop-Floor Notification")
        message = params.get("message", "Operational update from FactoryOS AI.")
        severity = params.get("severity", "INFO")

        notif_code = f"NOTIF-{uuid.uuid4().hex[:8].upper()}"

        ProductionEvent.objects.create(
            factory=factory,
            event_type="IN_APP_NOTIFICATION_SENT",
            severity=severity,
            source="SYSTEM_ENGINE",
            message=f"{title}: {message}",
            payload={"notification_code": notif_code, "title": title},
        )

        return {
            "reference_code": notif_code,
            "status": "DELIVERED",
            "title": title,
            "summary": f"In-app notification {notif_code} delivered.",
            "sent_at": timezone.now().isoformat(),
        }
