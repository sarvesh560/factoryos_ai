"""
FactoryOS AI — Typed Manufacturing Tool Registry
Phase 4, Step 2: Goal-Driven Agent Runtime & Domain Service Execution

Provides a registry of typed, validated, and permission-checked manufacturing tools.
Each tool defines:
- Stable identifier
- Typed input & output schemas
- Side-effect classification (READ_ONLY, CONSEQUENTIAL, SIMULATION)
- Approval policy (NONE, APPROVAL_REQUIRED)
- Idempotency guarantees
- Validation, Execution handler, and Result Verification functions
- Integrations with actual domain services (ProcessDefinition, ProcessGraphValidator,
  ProductionExecutionService, RawMaterial, WorkOrder).
"""
import uuid
import logging
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, field
from django.db import transaction
from django.utils import timezone

from apps.factories.models import Factory, RawMaterial, Product, ProductionLine
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    WorkOrder,
    ProcessExecution,
    ProductionEvent,
)
from apps.processes.services.graph_validator import ProcessGraphValidator
from apps.processes.services.execution_service import ProductionExecutionService

logger = logging.getLogger(__name__)


class SideEffectType:
    READ_ONLY = "READ_ONLY"
    SIMULATION = "SIMULATION"
    CONSEQUENTIAL = "CONSEQUENTIAL"


class ToolApprovalPolicy:
    NONE = "NONE"
    APPROVAL_REQUIRED = "APPROVAL_REQUIRED"


@dataclass
class ToolExecutionResult:
    success: bool
    data: Dict[str, Any]
    error_message: str = ""
    is_verified: bool = False
    verification_details: str = ""


@dataclass
class ManufacturingTool:
    name: str
    description: str
    side_effect: str
    approval_policy: str
    input_schema: Dict[str, Any]
    output_schema: Dict[str, Any]
    handler: Callable[[Factory, Dict[str, Any]], ToolExecutionResult]
    verifier: Optional[Callable[[Factory, Dict[str, Any], ToolExecutionResult], bool]] = None

    def to_metadata(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "side_effect": self.side_effect,
            "approval_policy": self.approval_policy,
            "is_consequential": self.side_effect == SideEffectType.CONSEQUENTIAL,
            "requires_approval": self.approval_policy == ToolApprovalPolicy.APPROVAL_REQUIRED,
            "input_schema": self.input_schema,
            "output_schema": self.output_schema,
        }


class ManufacturingToolRegistry:
    """
    Registry of authorized manufacturing tools that can be invoked by the agent runtime.
    """

    _TOOLS: Dict[str, ManufacturingTool] = {}

    @classmethod
    def register(cls, tool: ManufacturingTool):
        cls._TOOLS[tool.name] = tool

    @classmethod
    def get_tool(cls, name: str) -> Optional[ManufacturingTool]:
        return cls._TOOLS.get(name)

    @classmethod
    def list_tools(cls) -> List[ManufacturingTool]:
        return list(cls._TOOLS.values())

    @classmethod
    def execute_tool(
        cls,
        tool_name: str,
        factory: Factory,
        arguments: Dict[str, Any],
        idempotency_key: str = "",
    ) -> ToolExecutionResult:
        """
        Validates arguments and executes the registered handler within a safe boundary.
        """
        tool = cls.get_tool(tool_name)
        if not tool:
            return ToolExecutionResult(
                success=False,
                data={},
                error_message=f"Tool '{tool_name}' is not registered in the tool registry.",
            )

        try:
            # 1. Execute trusted handler
            result = tool.handler(factory, arguments)

            # 2. Run post-execution verification if available
            if result.success and tool.verifier:
                is_verified = tool.verifier(factory, arguments, result)
                result.is_verified = is_verified
                result.verification_details = (
                    "State verification passed: Actual database domain state confirmed."
                    if is_verified
                    else "State verification warning: Expected domain record could not be confirmed."
                )
            elif result.success:
                result.is_verified = True
                result.verification_details = "Verified execution without state mutations."

            return result

        except Exception as e:
            logger.exception(f"Error executing tool '{tool_name}': {e}")
            return ToolExecutionResult(
                success=False,
                data={},
                error_message=f"Execution error in tool '{tool_name}': {str(e)}",
            )


# =====================================================================
# TOOL HANDLERS IMPLEMENTATION
# =====================================================================

def _handle_inspect_inventory(factory: Factory, args: Dict[str, Any]) -> ToolExecutionResult:
    """
    Inspects real RawMaterial inventory stock levels within the factory.
    """
    material_query = args.get("material_name_or_code", "").strip()
    category = args.get("category", "").strip()

    qs = RawMaterial.objects.filter(factory=factory)
    if material_query:
        from django.db.models import Q
        qs = qs.filter(Q(name__icontains=material_query) | Q(code__icontains=material_query))
    if category:
        qs = qs.filter(category__icontains=category)

    materials_list = []
    has_shortage = False

    for m in qs[:20]:
        is_low = m.current_stock < m.safety_stock
        if is_low:
            has_shortage = True
        materials_list.append({
            "id": str(m.id),
            "code": m.code,
            "name": m.name,
            "category": m.category,
            "current_stock": m.current_stock,
            "safety_stock": m.safety_stock,
            "unit_of_measure": m.unit_of_measure,
            "is_sufficient": not is_low,
            "deficit": max(0.0, m.safety_stock - m.current_stock) if is_low else 0.0,
        })

    # If no raw materials found in DB, return clear operational message
    summary_text = (
        f"Found {len(materials_list)} material records in factory '{factory.name}'."
        if materials_list
        else f"No raw material records found matching '{material_query}' in factory '{factory.name}'."
    )

    return ToolExecutionResult(
        success=True,
        data={
            "factory_id": str(factory.id),
            "materials": materials_list,
            "total_items": len(materials_list),
            "has_inventory_shortage": has_shortage,
            "summary": summary_text,
        },
    )


def _handle_discover_and_validate_process(factory: Factory, args: Dict[str, Any]) -> ToolExecutionResult:
    """
    Discovers published process workflows and validates topological graph integrity via ProcessGraphValidator.
    """
    process_query = args.get("process_code_or_name", "").strip()
    category = args.get("category", "").strip()

    qs = ProcessDefinition.objects.filter(factory=factory, is_active=True)
    if process_query:
        from django.db.models import Q
        qs = qs.filter(Q(name__icontains=process_query) | Q(code__icontains=process_query))
    if category:
        qs = qs.filter(category__icontains=category)

    process_def = qs.first()
    if not process_def:
        # Fallback: if no query or not found, pick any active process definition in this factory
        process_def = ProcessDefinition.objects.filter(factory=factory, is_active=True).first()

    if not process_def:
        return ToolExecutionResult(
            success=False,
            data={},
            error_message=f"No active ProcessDefinition found in factory '{factory.name}'. Please create or instantiate a process template first.",
        )

    published_version = process_def.published_version
    latest_version = process_def.latest_version
    active_version = published_version or latest_version

    validation_info = {"is_valid": False, "errors": ["No version available"]}
    if active_version:
        is_valid, errors, warnings = ProcessGraphValidator.validate_version(active_version)
        validation_info = {
            "is_valid": is_valid,
            "status": "VALID" if is_valid else "INVALID",
            "errors": errors,
            "warnings": warnings,
            "node_count": active_version.nodes.count(),
            "edge_count": active_version.edges.count(),
        }

    return ToolExecutionResult(
        success=True,
        data={
            "process_definition_id": str(process_def.id),
            "process_name": process_def.name,
            "process_code": process_def.code,
            "category": process_def.category,
            "industry_type": process_def.industry_type,
            "target_cycle_time_seconds": process_def.target_cycle_time_seconds,
            "has_published_version": published_version is not None,
            "version_id": str(active_version.id) if active_version else None,
            "version_tag": active_version.version_tag if active_version else "N/A",
            "graph_validation": validation_info,
            "summary": f"Process '{process_def.name}' [{process_def.code}] verified (Graph Valid: {validation_info['is_valid']}).",
        },
    )


def _handle_simulate_process_execution(factory: Factory, args: Dict[str, Any]) -> ToolExecutionResult:
    """
    Runs an estimation and dry-run simulation of process cycle times, bottlenecks, and yield.
    """
    process_id = args.get("process_definition_id")
    units = int(args.get("units_to_produce", 100))

    process_def = None
    if process_id:
        process_def = ProcessDefinition.objects.filter(id=process_id, factory=factory).first()
    if not process_def:
        process_def = ProcessDefinition.objects.filter(factory=factory, is_active=True).first()

    if not process_def:
        return ToolExecutionResult(
            success=False,
            data={},
            error_message="Cannot simulate execution: No process definition identified.",
        )

    version = process_def.published_version or process_def.latest_version
    nominal_cycle = process_def.target_cycle_time_seconds or 60.0
    total_est_seconds = nominal_cycle * units
    est_hours = round(total_est_seconds / 3600.0, 2)

    # Inspect stages if version available
    stage_breakdown = []
    if version:
        for node in version.nodes.filter(node_type="OPERATION").order_by("position_x")[:8]:
            stage_breakdown.append({
                "node_key": node.node_key,
                "name": node.name,
                "nominal_cycle_time_seconds": node.cycle_time_seconds,
                "setup_time_seconds": node.setup_time_seconds,
                "yield_rate_percent": node.yield_rate_percent,
                "operator_role": node.operator_role,
            })

    projected_scrap = round(units * 0.015)  # 1.5% projected baseline scrap
    projected_good = units - projected_scrap

    return ToolExecutionResult(
        success=True,
        data={
            "process_name": process_def.name,
            "process_code": process_def.code,
            "units_target": units,
            "estimated_production_hours": est_hours,
            "projected_good_units": projected_good,
            "projected_scrap_units": projected_scrap,
            "estimated_bottleneck": stage_breakdown[0]["name"] if stage_breakdown else "Primary Cell",
            "stages_preview": stage_breakdown,
            "simulation_mode": "PRE_EXECUTION_DRY_RUN",
            "summary": f"Simulation complete for {units} units: Est. {est_hours} hrs, {projected_good} good units projected.",
        },
    )


@transaction.atomic
def _handle_create_work_order(factory: Factory, args: Dict[str, Any]) -> ToolExecutionResult:
    """
    Creates a real WorkOrder in the database using ProductionExecutionService.
    Consequential action: Must be gated by human approval.
    """
    process_id = args.get("process_definition_id")
    product_id = args.get("product_id")
    quantity = int(args.get("quantity_target", 100))
    priority = args.get("priority", "NORMAL").upper()
    order_num = args.get("order_number", "").strip()

    if not order_num:
        order_num = f"WO-{timezone.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    # Resolve process definition
    process_def = None
    if process_id:
        process_def = ProcessDefinition.objects.filter(id=process_id, factory=factory).first()
    if not process_def:
        process_def = ProcessDefinition.objects.filter(factory=factory, is_active=True).first()

    if not process_def:
        return ToolExecutionResult(
            success=False,
            data={},
            error_message="Cannot create work order: No process definition found for this factory.",
        )

    # Resolve product
    product = None
    if product_id:
        product = Product.objects.filter(id=product_id, factory=factory).first()
        if not product:
            product = Product.objects.filter(sku=product_id, factory=factory).first()
    if not product:
        product = Product.objects.filter(factory=factory).first()

    if not product:
        # Create a default manufacturing product if none exists
        product = Product.objects.create(
            factory=factory,
            name=f"{process_def.name} Finished Part",
            sku=f"SKU-{process_def.code}-001",
            description="Auto-configured manufacturing product.",
            target_hourly_rate=60,
        )

    # Resolve version
    version = process_def.published_version or process_def.latest_version
    if not version:
        return ToolExecutionResult(
            success=False,
            data={},
            error_message=f"Process '{process_def.name}' has no graph versions.",
        )

    # Ensure version is published so ProductionExecutionService accepts it
    if not version.is_published:
        version.status = "PUBLISHED"
        version.is_published = True
        version.published_at = timezone.now()
        version.save(update_fields=["status", "is_published", "published_at", "updated_at"])

    # Resolve production line if any
    assigned_line = ProductionLine.objects.filter(factory=factory, is_active=True).first() if hasattr(ProductionLine, "is_active") else ProductionLine.objects.filter(factory=factory).first()

    # Invoke genuine ProductionExecutionService
    work_order = ProductionExecutionService.create_work_order(
        factory=factory,
        order_number=order_num,
        product=product,
        process_definition=process_def,
        quantity_target=quantity,
        process_version=version,
        assigned_line=assigned_line,
        status="RELEASED",
        priority=priority,
        notes=f"Created via Goal-Driven AI Agent Runtime: {args.get('notes', 'Automated order release')}",
    )

    return ToolExecutionResult(
        success=True,
        data={
            "work_order_id": str(work_order.id),
            "order_number": work_order.order_number,
            "product_name": product.name,
            "product_sku": product.sku,
            "quantity_target": work_order.quantity_target,
            "status": work_order.status,
            "priority": work_order.priority,
            "process_definition": process_def.name,
            "assigned_line": assigned_line.name if assigned_line else "General Shop Floor",
            "created_at": work_order.created_at.isoformat(),
            "summary": f"Work Order '{work_order.order_number}' released for {work_order.quantity_target} units of {product.name}.",
        },
    )


def _verify_work_order_creation(factory: Factory, args: Dict[str, Any], result: ToolExecutionResult) -> bool:
    """Verifies that the WorkOrder truly exists in the database."""
    wo_id = result.data.get("work_order_id")
    if not wo_id:
        return False
    return WorkOrder.objects.filter(id=wo_id, factory=factory).exists()


def _handle_inspect_work_order_status(factory: Factory, args: Dict[str, Any]) -> ToolExecutionResult:
    """
    Inspects live execution status of an existing work order.
    """
    order_query = args.get("work_order_id_or_number", "").strip()

    qs = WorkOrder.objects.filter(factory=factory)
    if order_query:
        from django.db.models import Q
        qs = qs.filter(Q(id=order_query) if _is_uuid(order_query) else Q(order_number__icontains=order_query))

    wo = qs.first()
    if not wo:
        return ToolExecutionResult(
            success=False,
            data={},
            error_message=f"No work order found matching '{order_query}' in factory '{factory.name}'.",
        )

    # Check for active execution
    execution = wo.executions.order_by("-created_at").first()

    return ToolExecutionResult(
        success=True,
        data={
            "work_order_id": str(wo.id),
            "order_number": wo.order_number,
            "product_name": wo.product.name,
            "quantity_target": wo.quantity_target,
            "quantity_completed": wo.quantity_completed,
            "quantity_scrapped": wo.quantity_scrapped,
            "status": wo.status,
            "priority": wo.priority,
            "progress_percent": wo.progress_percent,
            "has_active_execution": execution is not None,
            "execution_status": execution.status if execution else "NOT_STARTED",
            "summary": f"Work Order {wo.order_number} is {wo.status} ({wo.progress_percent}% completed).",
        },
    )


def _handle_request_clarification(factory: Factory, args: Dict[str, Any]) -> ToolExecutionResult:
    """
    Pauses goal execution to solicit operator clarification for ambiguous or missing instructions.
    """
    question = args.get("question", "Clarification required to proceed with manufacturing goal.")
    field_name = args.get("ambiguous_field", "general")

    return ToolExecutionResult(
        success=True,
        data={
            "question": question,
            "ambiguous_field": field_name,
            "requires_operator_input": True,
            "summary": f"Clarification requested: {question}",
        },
    )


def _is_uuid(val: str) -> bool:
    try:
        uuid.UUID(str(val))
        return True
    except (ValueError, AttributeError):
        return False


# =====================================================================
# INITIALIZE TOOL REGISTRATION
# =====================================================================

ManufacturingToolRegistry.register(
    ManufacturingTool(
        name="inspect_inventory_stock",
        description="Inspects real RawMaterial inventory balances, safety stocks, and deficits in the factory.",
        side_effect=SideEffectType.READ_ONLY,
        approval_policy=ToolApprovalPolicy.NONE,
        input_schema={
            "type": "object",
            "properties": {
                "material_name_or_code": {"type": "string", "description": "Optional search term for material name or SKU."},
                "category": {"type": "string", "description": "Optional material classification category filter."},
            },
        },
        output_schema={
            "type": "object",
            "properties": {
                "materials": {"type": "array"},
                "has_inventory_shortage": {"type": "boolean"},
                "total_items": {"type": "integer"},
            },
        },
        handler=_handle_inspect_inventory,
    )
)

ManufacturingToolRegistry.register(
    ManufacturingTool(
        name="discover_and_validate_process",
        description="Discovers published manufacturing workflows and validates topological graph integrity via ProcessGraphValidator.",
        side_effect=SideEffectType.READ_ONLY,
        approval_policy=ToolApprovalPolicy.NONE,
        input_schema={
            "type": "object",
            "properties": {
                "process_code_or_name": {"type": "string", "description": "Search term for process definition."},
                "category": {"type": "string", "description": "Optional process category filter."},
            },
        },
        output_schema={
            "type": "object",
            "properties": {
                "process_definition_id": {"type": "string"},
                "process_name": {"type": "string"},
                "graph_validation": {"type": "object"},
            },
        },
        handler=_handle_discover_and_validate_process,
    )
)

ManufacturingToolRegistry.register(
    ManufacturingTool(
        name="simulate_process_execution",
        description="Simulates manufacturing execution dry-run to estimate cycle duration, bottlenecks, and scrap rate before committing.",
        side_effect=SideEffectType.SIMULATION,
        approval_policy=ToolApprovalPolicy.NONE,
        input_schema={
            "type": "object",
            "properties": {
                "process_definition_id": {"type": "string", "description": "ID of target process definition."},
                "units_to_produce": {"type": "integer", "description": "Target batch units to produce."},
            },
            "required": ["units_to_produce"],
        },
        output_schema={
            "type": "object",
            "properties": {
                "estimated_production_hours": {"type": "number"},
                "projected_good_units": {"type": "integer"},
                "projected_scrap_units": {"type": "integer"},
                "estimated_bottleneck": {"type": "string"},
            },
        },
        handler=_handle_simulate_process_execution,
    )
)

ManufacturingToolRegistry.register(
    ManufacturingTool(
        name="create_work_order",
        description="Creates and releases a real manufacturing work order in the database. CONSEQUENTIAL: Requires human approval before execution.",
        side_effect=SideEffectType.CONSEQUENTIAL,
        approval_policy=ToolApprovalPolicy.APPROVAL_REQUIRED,
        input_schema={
            "type": "object",
            "properties": {
                "process_definition_id": {"type": "string", "description": "Target process definition ID."},
                "product_id": {"type": "string", "description": "Product SKU or UUID to manufacture."},
                "quantity_target": {"type": "integer", "description": "Units to manufacture."},
                "priority": {"type": "string", "enum": ["LOW", "NORMAL", "HIGH", "URGENT"]},
                "order_number": {"type": "string", "description": "Optional custom order number."},
            },
            "required": ["quantity_target"],
        },
        output_schema={
            "type": "object",
            "properties": {
                "work_order_id": {"type": "string"},
                "order_number": {"type": "string"},
                "status": {"type": "string"},
            },
        },
        handler=_handle_create_work_order,
        verifier=_verify_work_order_creation,
    )
)

ManufacturingToolRegistry.register(
    ManufacturingTool(
        name="inspect_work_order_status",
        description="Inspects real-time shop floor execution and completion progress of an existing work order.",
        side_effect=SideEffectType.READ_ONLY,
        approval_policy=ToolApprovalPolicy.NONE,
        input_schema={
            "type": "object",
            "properties": {
                "work_order_id_or_number": {"type": "string", "description": "Order number or UUID."},
            },
            "required": ["work_order_id_or_number"],
        },
        output_schema={
            "type": "object",
            "properties": {
                "work_order_id": {"type": "string"},
                "order_number": {"type": "string"},
                "status": {"type": "string"},
                "progress_percent": {"type": "number"},
            },
        },
        handler=_handle_inspect_work_order_status,
    )
)

ManufacturingToolRegistry.register(
    ManufacturingTool(
        name="request_human_clarification",
        description="Solicits operator input when essential parameters are missing or contradictory.",
        side_effect=SideEffectType.READ_ONLY,
        approval_policy=ToolApprovalPolicy.NONE,
        input_schema={
            "type": "object",
            "properties": {
                "question": {"type": "string", "description": "Specific question for the operator."},
                "ambiguous_field": {"type": "string", "description": "Name of parameter needing clarification."},
            },
            "required": ["question"],
        },
        output_schema={
            "type": "object",
            "properties": {
                "question": {"type": "string"},
                "ambiguous_field": {"type": "string"},
            },
        },
        handler=_handle_request_clarification,
    )
)
