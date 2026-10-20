"""
FactoryOS AI — Universal Production Execution Engine
Phase 3: Work Order Lifecycle, Graph Traversal, Material Tracking & Deterministic Transitions
"""
from typing import Optional, Dict, Any, List
from django.db import transaction
from django.utils import timezone
from apps.factories.models import Factory, RawMaterial, Machine, ProductionLine, Product
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    ProcessNode,
    ProcessEdge,
    WorkOrder,
    ProcessExecution,
    StageExecution,
    MaterialFlow,
    ProductionEvent,
)

class ProductionExecutionService:
    """
    Core Manufacturing Execution Engine.
    Handles graph-based production runs, dependency resolution,
    material inventory deduction, WIP tracking, and idempotent event progression.
    """

    @classmethod
    @transaction.atomic
    def create_work_order(
        cls,
        factory: Factory,
        order_number: str,
        product: Product,
        process_definition: ProcessDefinition,
        quantity_target: int,
        process_version: Optional[ProcessVersion] = None,
        assigned_line: Optional[ProductionLine] = None,
        status: str = "RELEASED",
        priority: str = "NORMAL",
        planned_start_date=None,
        planned_due_date=None,
        notes: str = "",
    ) -> WorkOrder:
        """
        Creates and releases a new manufacturing work order with strict validation.
        Enforces factory boundaries, positive quantities, and published workflow requirement.
        """
        if not order_number or not str(order_number).strip():
            raise ValueError("Work order number cannot be blank.")
        order_number = str(order_number).strip()

        if WorkOrder.objects.filter(factory=factory, order_number=order_number).exists():
            raise ValueError(f"Work order with number '{order_number}' already exists in this factory.")

        if product.factory_id != factory.id:
            raise ValueError("Product does not belong to the selected factory.")

        if process_definition.factory_id != factory.id:
            raise ValueError("Process definition does not belong to the selected factory.")

        if not process_definition.is_active:
            raise ValueError(f"Cannot create work order against inactive or archived process definition '{process_definition.name}'.")

        if assigned_line and assigned_line.factory_id != factory.id:
            raise ValueError("Assigned production line does not belong to the selected factory.")

        try:
            qty_int = int(quantity_target)
            if qty_int <= 0:
                raise ValueError
        except (ValueError, TypeError):
            raise ValueError("Target quantity must be a positive integer greater than zero.")

        # Published version enforcement: work orders can ONLY reference published versions
        if process_version:
            if process_version.process_definition_id != process_definition.id:
                raise ValueError("Process version does not belong to the selected process definition.")
            if not process_version.is_published or process_version.status != "PUBLISHED":
                raise ValueError(
                    f"Cannot create work order with version '{process_version.version_tag}' because it is in '{process_version.status}' status. "
                    "Only PUBLISHED versions can be used for manufacturing execution."
                )
            version = process_version
        else:
            version = process_definition.published_version
            if not version:
                raise ValueError(
                    f"No published process version found for '{process_definition.name}'. "
                    "Workflow must be validated and published before creating work orders."
                )

        initial_status = status.upper() if status else "RELEASED"
        if initial_status not in ("DRAFT", "PLANNED", "RELEASED"):
            initial_status = "RELEASED"

        wo = WorkOrder.objects.create(
            factory=factory,
            order_number=order_number,
            product=product,
            process_definition=process_definition,
            process_version=version,
            assigned_line=assigned_line,
            quantity_target=qty_int,
            status=initial_status,
            priority=priority,
            planned_start_date=planned_start_date or timezone.now(),
            planned_due_date=planned_due_date or (timezone.now() + timezone.timedelta(days=2)),
            notes=notes,
        )

        ProductionEvent.objects.create(
            factory=factory,
            work_order=wo,
            event_type="WORK_ORDER_CREATED",
            severity="INFO",
            source="OPERATOR",
            message=f"Work order '{wo.order_number}' created for {qty_int} units of {product.name} (Status: {initial_status}).",
            payload={"target_quantity": qty_int, "version": version.version_tag, "status": initial_status}
        )

        return wo

    @classmethod
    @transaction.atomic
    def start_execution(
        cls,
        work_order: WorkOrder,
        mode: str = "SIMULATION",
    ) -> ProcessExecution:
        """
        Initializes and starts a process execution run for a work order.
        Instantiates stage executions for all graph nodes and starts initial eligible operations.
        """
        version = work_order.process_version
        factory = work_order.factory

        # Look for existing active execution
        existing = work_order.executions.filter(status__in=["INITIALIZED", "RUNNING", "BLOCKED"]).first()
        if existing:
            return existing

        execution_num = f"EXEC-{work_order.order_number}-{work_order.executions.count() + 1}"
        execution = ProcessExecution.objects.create(
            work_order=work_order,
            process_version=version,
            execution_number=execution_num,
            mode=mode,
            status="RUNNING",
            started_at=timezone.now(),
            total_units_input=work_order.quantity_target,
        )

        work_order.status = "IN_PROGRESS"
        work_order.actual_start_date = timezone.now()
        work_order.save(update_fields=["status", "actual_start_date", "updated_at"])

        # Create StageExecution for all nodes in this version
        nodes = list(version.nodes.all())
        stage_map: Dict[str, StageExecution] = {}

        for node in nodes:
            se = StageExecution.objects.create(
                process_execution=execution,
                node=node,
                status="PENDING",
                assigned_machine=node.assigned_machine,
                units_queued=work_order.quantity_target if node.node_type == "START" else 0,
            )
            stage_map[node.node_key] = se

        # Mark START nodes as COMPLETED and unlock outgoing operations
        start_nodes = [n for n in nodes if n.node_type == "START"]
        for sn in start_nodes:
            se = stage_map[sn.node_key]
            se.status = "COMPLETED"
            se.units_completed = work_order.quantity_target
            se.completed_at = timezone.now()
            se.save(update_fields=["status", "units_completed", "completed_at", "updated_at"])

            # Activate downstream targets
            for edge in sn.outgoing_edges.all():
                target_key = edge.target_node.node_key
                target_se = stage_map[target_key]
                cls._activate_stage_if_ready(execution, target_se, work_order.quantity_target)

        ProductionEvent.objects.create(
            factory=factory,
            work_order=work_order,
            process_execution=execution,
            event_type="EXECUTION_STARTED",
            severity="INFO",
            source="SYSTEM_ENGINE" if mode == "PRODUCTION" else "SIMULATION",
            message=f"Process execution '{execution.execution_number}' started in {mode} mode.",
            payload={"execution_id": str(execution.id), "mode": mode}
        )

        return execution

    @classmethod
    def _activate_stage_if_ready(
        cls,
        execution: ProcessExecution,
        stage_exec: StageExecution,
        incoming_units: int,
    ) -> bool:
        """
        Evaluates whether a stage's incoming dependencies are satisfied.
        If ready, checks and consumes raw material, and sets status to RUNNING.
        """
        node = stage_exec.node
        version = execution.process_version

        # 1. Check incoming edges
        incoming_edges = list(node.incoming_edges.all())
        if incoming_edges:
            if node.node_type == "PARALLEL_JOIN":
                # For a PARALLEL_JOIN, ALL incoming branches must be completed
                for edge in incoming_edges:
                    src_exec = StageExecution.objects.filter(
                        process_execution=execution,
                        node=edge.source_node
                    ).first()
                    if not src_exec or src_exec.status != "COMPLETED":
                        return False # Still waiting for other branches
            else:
                # For standard or condition, check if at least one predecessor completed
                # (and for conditional branch, whether it was chosen)
                completed_predecessors = StageExecution.objects.filter(
                    process_execution=execution,
                    node__in=[e.source_node for e in incoming_edges],
                    status="COMPLETED"
                ).count()
                if completed_predecessors == 0:
                    return False

        # Node is ready
        stage_exec.units_queued = incoming_units
        stage_exec.units_in_progress = incoming_units

        # 2. Check and deduct raw material requirements if specified
        material_shortage = False
        shortage_details = []

        if node.input_materials:
            factory = execution.work_order.factory
            for mat_spec in node.input_materials:
                mat_id = mat_spec.get("raw_material_id") or mat_spec.get("material_id")
                qty_per_unit = float(mat_spec.get("quantity", mat_spec.get("quantity_per_unit", 1.0)))
                required_qty = round(qty_per_unit * incoming_units, 2)

                raw_mat = None
                if mat_id:
                    raw_mat = RawMaterial.objects.filter(factory=factory, id=mat_id).first()
                if not raw_mat and mat_spec.get("name"):
                    raw_mat = RawMaterial.objects.filter(factory=factory, name__icontains=mat_spec["name"]).first()

                if raw_mat:
                    if raw_mat.current_stock < required_qty:
                        material_shortage = True
                        shortage_details.append(f"{raw_mat.name} (need {required_qty}, have {raw_mat.current_stock})")
                    else:
                        # Deduct atomically
                        prev_stock = raw_mat.current_stock
                        raw_mat.current_stock = max(0.0, prev_stock - required_qty)
                        raw_mat.save(update_fields=["current_stock"])

                        MaterialFlow.objects.create(
                            process_execution=execution,
                            stage_execution=stage_exec,
                            raw_material=raw_mat,
                            flow_type="INPUT_CONSUMPTION",
                            quantity=required_qty,
                            unit_of_measure=raw_mat.unit_of_measure,
                            previous_stock_level=prev_stock,
                            new_stock_level=raw_mat.current_stock,
                            notes=f"Consumed for {incoming_units} units at '{node.name}'."
                        )

        if material_shortage:
            stage_exec.status = "BLOCKED"
            stage_exec.error_message = f"Material shortage: {', '.join(shortage_details)}"
            stage_exec.save(update_fields=["status", "units_queued", "units_in_progress", "error_message", "updated_at"])

            execution.status = "BLOCKED"
            execution.bottleneck_node = node
            execution.save(update_fields=["status", "bottleneck_node", "updated_at"])

            ProductionEvent.objects.create(
                factory=execution.work_order.factory,
                work_order=execution.work_order,
                process_execution=execution,
                stage_execution=stage_exec,
                event_type="STAGE_BLOCKED",
                severity="WARNING",
                source=execution.mode,
                message=f"Stage '{node.name}' blocked due to material shortage: {', '.join(shortage_details)}",
                payload={"shortages": shortage_details}
            )
            return False

        # Structural Parallel Split auto-completes and activates all outgoing branches
        if node.node_type == "PARALLEL_SPLIT":
            stage_exec.status = "COMPLETED"
            stage_exec.units_completed = incoming_units
            stage_exec.completed_at = timezone.now()
            stage_exec.save(update_fields=["status", "units_completed", "completed_at", "updated_at"])

            for edge in node.outgoing_edges.all():
                target_se = StageExecution.objects.filter(
                    process_execution=execution,
                    node=edge.target_node
                ).first()
                if target_se:
                    cls._activate_stage_if_ready(execution, target_se, incoming_units)
            return True

        # All good, start stage
        stage_exec.status = "RUNNING"
        stage_exec.started_at = timezone.now()
        stage_exec.save(update_fields=["status", "units_queued", "units_in_progress", "started_at", "updated_at"])

        ProductionEvent.objects.create(
            factory=execution.work_order.factory,
            work_order=execution.work_order,
            process_execution=execution,
            stage_execution=stage_exec,
            event_type="STAGE_STARTED",
            severity="INFO",
            source=execution.mode,
            message=f"Operation '{node.name}' started processing {incoming_units} units.",
            payload={"units": incoming_units, "machine": stage_exec.assigned_machine.code if stage_exec.assigned_machine else None}
        )
        return True

    @classmethod
    @transaction.atomic
    def advance_stage(
        cls,
        stage_execution: StageExecution,
        units_completed: Optional[int] = None,
        units_scrapped: int = 0,
        duration_seconds: Optional[float] = None,
    ) -> StageExecution:
        """
        Advances an active stage to COMPLETED.
        Handles WIP movements, triggers downstream dependent operations,
        and marks execution / work order as COMPLETED when all branches reach END.
        Protects idempotency if already completed.
        Strictly enforces stage sequence and rejects bypassing preceding operations.
        """
        if stage_execution.status == "COMPLETED":
            return stage_execution # Idempotent safe return

        execution = stage_execution.process_execution
        work_order = execution.work_order
        node = stage_execution.node

        # Guard: Execution status checks
        if execution.status == "PAUSED":
            raise ValueError("Cannot advance stage while execution is PAUSED. Resume execution before advancing operations.")
        if execution.status in ("COMPLETED", "FAILED"):
            raise ValueError(f"Cannot advance stage because process execution is already {execution.status}.")

        # Guard: Stage status checks - strictly prevent bypassing predecessor stages
        if stage_execution.status == "PENDING":
            raise ValueError(
                f"Cannot advance stage '{node.name}' ({node.node_key}) because it is in PENDING status. "
                "Required preceding operations must complete first."
            )
        if stage_execution.status == "BLOCKED":
            raise ValueError(
                f"Cannot advance stage '{node.name}' ({node.node_key}) because it is BLOCKED "
                f"({stage_execution.error_message or 'unresolved bottleneck'}). Clear bottleneck before proceeding."
            )
        if stage_execution.status == "FAILED":
            raise ValueError(
                f"Cannot advance stage '{node.name}' ({node.node_key}) because it has FAILED ({stage_execution.error_message})."
            )

        # Quantity validation
        if units_scrapped < 0:
            raise ValueError("Scrapped units cannot be negative.")

        total_in = stage_execution.units_in_progress or stage_execution.units_queued or work_order.quantity_target

        if units_completed is not None:
            if units_completed < 0:
                raise ValueError("Completed units cannot be negative.")
            if units_completed > total_in:
                raise ValueError(
                    f"Completed quantity ({units_completed}) exceeds available stage units ({total_in})."
                )
            if (units_completed + units_scrapped) > total_in:
                raise ValueError(
                    f"Total processed units ({units_completed + units_scrapped}) exceeds available stage units ({total_in})."
                )
            actual_good = units_completed
        else:
            actual_good = max(0, total_in - units_scrapped)

        stage_execution.status = "COMPLETED"
        stage_execution.units_completed = actual_good
        stage_execution.units_scrapped = units_scrapped
        stage_execution.units_in_progress = 0
        stage_execution.completed_at = timezone.now()
        stage_execution.duration_seconds = duration_seconds if duration_seconds is not None else node.cycle_time_seconds
        stage_execution.save()

        # Record WIP / Finished Goods material flow
        is_terminal = (node.node_type == "END")
        flow_type = "FINISHED_GOODS" if is_terminal else "WIP_TRANSFER"
        MaterialFlow.objects.create(
            process_execution=execution,
            stage_execution=stage_execution,
            flow_type=flow_type,
            quantity=float(actual_good),
            unit_of_measure="pcs",
            notes=f"Completed {actual_good} units at '{node.name}' (Scrap: {units_scrapped})."
        )

        if units_scrapped > 0:
            MaterialFlow.objects.create(
                process_execution=execution,
                stage_execution=stage_execution,
                flow_type="SCRAP_REJECT",
                quantity=float(units_scrapped),
                unit_of_measure="pcs",
                notes=f"Scrapped {units_scrapped} units at '{node.name}'."
            )

        ProductionEvent.objects.create(
            factory=work_order.factory,
            work_order=work_order,
            process_execution=execution,
            stage_execution=stage_execution,
            event_type="STAGE_COMPLETED",
            severity="INFO",
            source=execution.mode,
            message=f"Stage '{node.name}' completed: {actual_good} good units, {units_scrapped} scrap.",
            payload={"good_units": actual_good, "scrap": units_scrapped}
        )

        # Unlock outgoing nodes
        for edge in node.outgoing_edges.all():
            target_node = edge.target_node
            target_se = StageExecution.objects.filter(
                process_execution=execution,
                node=target_node
            ).first()

            if target_se and target_se.status in ("PENDING", "BLOCKED"):
                if target_node.node_type == "END":
                    target_se.status = "COMPLETED"
                    target_se.units_completed = actual_good
                    target_se.completed_at = timezone.now()
                    target_se.save(update_fields=["status", "units_completed", "completed_at", "updated_at"])
                else:
                    cls._activate_stage_if_ready(execution, target_se, actual_good)

        # Update overall execution progress
        all_stages = execution.stage_executions.all()
        total_count = all_stages.count()
        completed_count = all_stages.filter(status="COMPLETED").count()
        progress = round((completed_count / total_count) * 100.0, 1) if total_count > 0 else 100.0
        execution.current_progress_percent = progress
        execution.total_units_scrap += units_scrapped

        # Check if all END nodes have completed
        end_nodes = execution.process_version.nodes.filter(node_type="END")
        all_ends_done = True
        for en in end_nodes:
            se = StageExecution.objects.filter(process_execution=execution, node=en).first()
            if not se or se.status != "COMPLETED":
                all_ends_done = False
                break

        if all_ends_done:
            end_completed_sum = sum(
                se.units_completed for se in StageExecution.objects.filter(process_execution=execution, node__in=end_nodes, status="COMPLETED")
            )
            final_output = end_completed_sum if end_completed_sum > 0 else actual_good

            execution.status = "COMPLETED"
            execution.completed_at = timezone.now()
            execution.total_units_output = final_output
            execution.current_progress_percent = 100.0
            execution.bottleneck_node = None
            execution.save()

            work_order.status = "COMPLETED"
            work_order.quantity_completed = final_output
            work_order.quantity_scrapped += execution.total_units_scrap
            work_order.actual_end_date = timezone.now()
            work_order.save()

            ProductionEvent.objects.create(
                factory=work_order.factory,
                work_order=work_order,
                process_execution=execution,
                event_type="WORK_ORDER_COMPLETED",
                severity="INFO",
                source=execution.mode,
                message=f"Work order '{work_order.order_number}' completed successfully ({final_output} units finished).",
                payload={"completed_units": final_output, "scrap_units": execution.total_units_scrap}
            )
        else:
            execution.save(update_fields=["current_progress_percent", "total_units_scrap", "updated_at"])

        return stage_execution

    @classmethod
    @transaction.atomic
    def pause_execution(cls, execution: ProcessExecution, reason: str = "Operator hold") -> ProcessExecution:
        """
        Pauses an active process execution.
        """
        if execution.status == "PAUSED":
            return execution
        if execution.status != "RUNNING":
            raise ValueError(f"Cannot pause execution in '{execution.status}' status (must be RUNNING).")

        execution.status = "PAUSED"
        execution.save(update_fields=["status", "updated_at"])
        execution.work_order.status = "PAUSED"
        execution.work_order.save(update_fields=["status", "updated_at"])

        ProductionEvent.objects.create(
            factory=execution.work_order.factory,
            work_order=execution.work_order,
            process_execution=execution,
            event_type="EXECUTION_PAUSED",
            severity="WARNING",
            source="OPERATOR",
            message=f"Execution paused: {reason}",
            payload={"reason": reason}
        )
        return execution

    @classmethod
    @transaction.atomic
    def resume_execution(cls, execution: ProcessExecution) -> ProcessExecution:
        """
        Resumes a paused execution.
        """
        if execution.status == "RUNNING":
            return execution
        if execution.status != "PAUSED":
            raise ValueError(f"Cannot resume execution in '{execution.status}' status (must be PAUSED).")

        execution.status = "RUNNING"
        execution.save(update_fields=["status", "updated_at"])
        execution.work_order.status = "IN_PROGRESS"
        execution.work_order.save(update_fields=["status", "updated_at"])

        ProductionEvent.objects.create(
            factory=execution.work_order.factory,
            work_order=execution.work_order,
            process_execution=execution,
            event_type="EXECUTION_RESUMED",
            severity="INFO",
            source="OPERATOR",
            message="Execution resumed by operator.",
            payload={}
        )
        return execution

    @classmethod
    @transaction.atomic
    def fail_stage(cls, stage_execution: StageExecution, error_message: str) -> StageExecution:
        """
        Marks an active stage as FAILED and halts execution.
        """
        if stage_execution.status == "COMPLETED":
            raise ValueError("Cannot fail an already completed stage.")

        execution = stage_execution.process_execution
        if execution.status == "COMPLETED":
            raise ValueError("Cannot fail a stage in an already completed execution.")
        if execution.status == "PAUSED":
            raise ValueError("Cannot fail a stage while execution is PAUSED. Resume execution first.")

        stage_execution.status = "FAILED"
        stage_execution.error_message = error_message
        stage_execution.save(update_fields=["status", "error_message", "updated_at"])

        execution.status = "FAILED"
        execution.bottleneck_node = stage_execution.node
        execution.save(update_fields=["status", "bottleneck_node", "updated_at"])

        ProductionEvent.objects.create(
            factory=execution.work_order.factory,
            work_order=execution.work_order,
            process_execution=execution,
            stage_execution=stage_execution,
            event_type="STAGE_FAILED",
            severity="CRITICAL",
            source=execution.mode,
            message=f"Critical failure on '{stage_execution.node.name}': {error_message}",
            payload={"error": error_message}
        )
        return stage_execution

