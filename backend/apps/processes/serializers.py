"""
FactoryOS AI — Universal Process Engine Serializers
Phase 3: Serializers for Graph Designer, Work Orders, Execution & Simulation
"""
from rest_framework import serializers
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
    SimulationScenario,
)

class ProcessEdgeSerializer(serializers.ModelSerializer):
    source_node_key = serializers.CharField(source="source_node.node_key", read_only=True)
    target_node_key = serializers.CharField(source="target_node.node_key", read_only=True)

    class Meta:
        model = ProcessEdge
        fields = [
            "id",
            "edge_key",
            "source_node",
            "target_node",
            "source_node_key",
            "target_node_key",
            "edge_type",
            "condition_expression",
            "label",
            "priority",
            "created_at",
        ]

class ProcessNodeSerializer(serializers.ModelSerializer):
    assigned_line_name = serializers.CharField(source="assigned_line.name", read_only=True)
    assigned_machine_name = serializers.CharField(source="assigned_machine.name", read_only=True)

    class Meta:
        model = ProcessNode
        fields = [
            "id",
            "node_key",
            "name",
            "node_type",
            "position_x",
            "position_y",
            "cycle_time_seconds",
            "setup_time_seconds",
            "standard_capacity_per_hour",
            "assigned_line",
            "assigned_line_name",
            "assigned_machine",
            "assigned_machine_name",
            "required_operators",
            "operator_role",
            "required_skills",
            "resource_spec",
            "input_materials",
            "output_materials",
            "yield_rate_percent",
            "configuration",
            "created_at",
            "updated_at",
        ]

class ProcessVersionSerializer(serializers.ModelSerializer):
    node_count = serializers.IntegerField(source="nodes.count", read_only=True)
    edge_count = serializers.IntegerField(source="edges.count", read_only=True)

    class Meta:
        model = ProcessVersion
        fields = [
            "id",
            "process_definition",
            "version_number",
            "version_tag",
            "status",
            "change_summary",
            "is_published",
            "validation_errors",
            "graph_metadata",
            "published_at",
            "node_count",
            "edge_count",
            "created_at",
            "updated_at",
        ]

class ProcessVersionDetailSerializer(serializers.ModelSerializer):
    nodes = ProcessNodeSerializer(many=True, read_only=True)
    edges = ProcessEdgeSerializer(many=True, read_only=True)

    class Meta:
        model = ProcessVersion
        fields = [
            "id",
            "process_definition",
            "version_number",
            "version_tag",
            "status",
            "change_summary",
            "is_published",
            "validation_errors",
            "graph_metadata",
            "published_at",
            "nodes",
            "edges",
            "created_at",
            "updated_at",
        ]

class ProcessDefinitionSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    published_version_tag = serializers.SerializerMethodField()
    latest_version_number = serializers.SerializerMethodField()
    published_version_id = serializers.SerializerMethodField()
    latest_version_id = serializers.SerializerMethodField()
    version_count = serializers.IntegerField(source="versions.count", read_only=True)
    versions = ProcessVersionSerializer(many=True, read_only=True)

    class Meta:
        model = ProcessDefinition
        fields = [
            "id",
            "factory",
            "factory_name",
            "name",
            "code",
            "description",
            "category",
            "industry_type",
            "target_cycle_time_seconds",
            "is_active",
            "published_version_tag",
            "latest_version_number",
            "published_version_id",
            "latest_version_id",
            "version_count",
            "versions",
            "created_at",
            "updated_at",
        ]

    def get_published_version_tag(self, obj):
        pv = obj.published_version
        return pv.version_tag if pv else None

    def get_latest_version_number(self, obj):
        lv = obj.latest_version
        return lv.version_number if lv else None

    def get_published_version_id(self, obj):
        pv = obj.published_version
        return str(pv.id) if pv else None

    def get_latest_version_id(self, obj):
        lv = obj.latest_version
        return str(lv.id) if lv else None

class ProcessDefinitionDetailSerializer(ProcessDefinitionSerializer):
    class Meta(ProcessDefinitionSerializer.Meta):
        fields = ProcessDefinitionSerializer.Meta.fields

class WorkOrderSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    product_name = serializers.CharField(source="product.name", read_only=True)
    product_sku = serializers.CharField(source="product.sku", read_only=True)
    process_name = serializers.CharField(source="process_definition.name", read_only=True)
    process_version_tag = serializers.CharField(source="process_version.version_tag", read_only=True)
    assigned_line_name = serializers.CharField(source="assigned_line.name", read_only=True)
    progress_percent = serializers.FloatField(read_only=True)

    class Meta:
        model = WorkOrder
        fields = [
            "id",
            "factory",
            "factory_name",
            "order_number",
            "product",
            "product_name",
            "product_sku",
            "process_definition",
            "process_name",
            "process_version",
            "process_version_tag",
            "assigned_line",
            "assigned_line_name",
            "quantity_target",
            "quantity_completed",
            "quantity_scrapped",
            "status",
            "priority",
            "progress_percent",
            "planned_start_date",
            "planned_due_date",
            "actual_start_date",
            "actual_end_date",
            "notes",
            "created_at",
            "updated_at",
        ]

class StageExecutionSerializer(serializers.ModelSerializer):
    node_key = serializers.CharField(source="node.node_key", read_only=True)
    node_name = serializers.CharField(source="node.name", read_only=True)
    node_type = serializers.CharField(source="node.node_type", read_only=True)
    cycle_time_seconds = serializers.FloatField(source="node.cycle_time_seconds", read_only=True)
    setup_time_seconds = serializers.FloatField(source="node.setup_time_seconds", read_only=True)
    standard_capacity_per_hour = serializers.IntegerField(source="node.standard_capacity_per_hour", read_only=True)
    required_operators = serializers.IntegerField(source="node.required_operators", read_only=True)
    operator_role = serializers.CharField(source="node.operator_role", read_only=True)
    required_skills = serializers.ListField(source="node.required_skills", read_only=True)
    yield_rate_percent = serializers.FloatField(source="node.yield_rate_percent", read_only=True)
    assigned_machine_name = serializers.CharField(source="assigned_machine.name", read_only=True)

    class Meta:
        model = StageExecution
        fields = [
            "id",
            "node",
            "node_key",
            "node_name",
            "node_type",
            "cycle_time_seconds",
            "setup_time_seconds",
            "standard_capacity_per_hour",
            "required_operators",
            "operator_role",
            "required_skills",
            "yield_rate_percent",
            "status",
            "assigned_machine",
            "assigned_machine_name",
            "units_queued",
            "units_in_progress",
            "units_completed",
            "units_scrapped",
            "started_at",
            "completed_at",
            "duration_seconds",
            "retry_count",
            "error_message",
            "created_at",
            "updated_at",
        ]

class ProcessExecutionSerializer(serializers.ModelSerializer):
    order_number = serializers.CharField(source="work_order.order_number", read_only=True)
    product_name = serializers.CharField(source="work_order.product.name", read_only=True)
    quantity_target = serializers.IntegerField(source="work_order.quantity_target", read_only=True)
    bottleneck_node_name = serializers.CharField(source="bottleneck_node.name", read_only=True)
    stage_executions = StageExecutionSerializer(many=True, read_only=True)

    class Meta:
        model = ProcessExecution
        fields = [
            "id",
            "work_order",
            "order_number",
            "product_name",
            "quantity_target",
            "process_version",
            "execution_number",
            "mode",
            "status",
            "started_at",
            "completed_at",
            "current_progress_percent",
            "total_units_input",
            "total_units_output",
            "total_units_scrap",
            "bottleneck_node",
            "bottleneck_node_name",
            "stage_executions",
            "created_at",
            "updated_at",
        ]

class MaterialFlowSerializer(serializers.ModelSerializer):
    raw_material_name = serializers.CharField(source="raw_material.name", read_only=True)
    stage_name = serializers.CharField(source="stage_execution.node.name", read_only=True)

    class Meta:
        model = MaterialFlow
        fields = [
            "id",
            "process_execution",
            "stage_execution",
            "stage_name",
            "raw_material",
            "raw_material_name",
            "flow_type",
            "quantity",
            "unit_of_measure",
            "previous_stock_level",
            "new_stock_level",
            "timestamp",
            "notes",
        ]

class ProductionEventSerializer(serializers.ModelSerializer):
    work_order_number = serializers.CharField(source="work_order.order_number", read_only=True)
    stage_name = serializers.CharField(source="stage_execution.node.name", read_only=True)

    class Meta:
        model = ProductionEvent
        fields = [
            "id",
            "factory",
            "work_order",
            "work_order_number",
            "process_execution",
            "stage_execution",
            "stage_name",
            "event_type",
            "severity",
            "source",
            "payload",
            "message",
            "timestamp",
        ]

class SimulationScenarioSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)

    class Meta:
        model = SimulationScenario
        fields = [
            "id",
            "factory",
            "factory_name",
            "name",
            "scenario_type",
            "parameters",
            "random_seed",
            "is_active",
            "created_at",
        ]
