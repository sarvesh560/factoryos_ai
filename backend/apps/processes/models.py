"""
FactoryOS AI — Universal Manufacturing Process Engine (UMPE) Models
Phase 3: Process Graphs, Work Orders, Execution Engine, Material Tracking & Simulation
"""
import uuid
from django.db import models
from apps.factories.models import Factory, ProductionLine, Machine, Product, RawMaterial, IndustryType

class ProcessDefinition(models.Model):
    """
    Factory-scoped manufacturing process definition.
    Represents an overarching workflow (e.g., 'EV Stator Machining & Assembly')
    that contains one or more versioned directed process graphs.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="process_definitions",
        help_text="Factory owning this process definition."
    )
    name = models.CharField(max_length=255, help_text="Human-readable process name.")
    code = models.CharField(max_length=50, help_text="Unique process identifier per factory.")
    description = models.TextField(blank=True, default="")
    category = models.CharField(
        max_length=100,
        default="General Manufacturing",
        help_text="Manufacturing classification (e.g., Machining, Assembly, Food, Textile, Electronics)."
    )
    industry_type = models.CharField(
        max_length=50,
        choices=IndustryType.choices,
        default=IndustryType.CUSTOM,
        help_text="Target manufacturing industry for this process definition."
    )
    target_cycle_time_seconds = models.FloatField(
        default=60.0,
        help_text="Overall nominal target cycle time across the entire process."
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "process_definitions"
        unique_together = [("factory", "code")]
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} [{self.code}] ({self.factory.name})"

    @property
    def published_version(self):
        """Returns the latest active published version, if any."""
        return self.versions.filter(status="PUBLISHED").order_by("-version_number").first()

    @property
    def latest_version(self):
        """Returns the most recently created version."""
        return self.versions.order_by("-version_number").first()


class ProcessVersion(models.Model):
    """
    Immutable versioned graph specification for a process definition.
    Once PUBLISHED, the graph nodes and edges cannot be modified directly;
    users must clone a new DRAFT version to edit.
    """
    STATUS_CHOICES = [
        ("DRAFT", "Draft"),
        ("VALIDATED", "Validated"),
        ("PUBLISHED", "Published"),
        ("ARCHIVED", "Archived"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    process_definition = models.ForeignKey(
        ProcessDefinition,
        on_delete=models.CASCADE,
        related_name="versions"
    )
    version_number = models.PositiveIntegerField(default=1)
    version_tag = models.CharField(max_length=50, default="v1.0.0")
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default="DRAFT")
    change_summary = models.TextField(blank=True, default="")
    is_published = models.BooleanField(default=False)
    validation_errors = models.JSONField(default=list, blank=True)
    graph_metadata = models.JSONField(default=dict, blank=True) # zoom, pan, layout
    published_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "process_versions"
        unique_together = [("process_definition", "version_number")]
        ordering = ["-version_number"]

    def __str__(self):
        return f"{self.process_definition.code} {self.version_tag} ({self.status})"


class ProcessNode(models.Model):
    """
    Node in the directed manufacturing process graph.
    Represents operations, parallel splits/joins, condition branches, and quality gates.
    """
    NODE_TYPE_CHOICES = [
        ("START", "Process Start"),
        ("OPERATION", "Standard Operation"),
        ("PARALLEL_SPLIT", "Parallel Split (AND Fork)"),
        ("PARALLEL_JOIN", "Parallel Join (AND Sync)"),
        ("CONDITION_BRANCH", "Conditional Branch (OR/XOR Split)"),
        ("QUALITY_GATE", "Quality Gate / Inspection"),
        ("END", "Process End"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    process_version = models.ForeignKey(
        ProcessVersion,
        on_delete=models.CASCADE,
        related_name="nodes"
    )
    node_key = models.CharField(max_length=50, help_text="Unique key within this graph version.")
    name = models.CharField(max_length=255)
    node_type = models.CharField(max_length=50, choices=NODE_TYPE_CHOICES, default="OPERATION")
    position_x = models.FloatField(default=100.0, help_text="Canvas X position for visual rendering.")
    position_y = models.FloatField(default=100.0, help_text="Canvas Y position for visual rendering.")
    cycle_time_seconds = models.FloatField(default=30.0, help_text="Nominal operation duration per unit.")
    setup_time_seconds = models.FloatField(default=0.0, help_text="Standard setup or changeover time in seconds.")
    standard_capacity_per_hour = models.IntegerField(default=60)
    assigned_line = models.ForeignKey(
        ProductionLine,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="assigned_process_nodes"
    )
    assigned_machine = models.ForeignKey(
        Machine,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="assigned_process_nodes"
    )
    required_operators = models.IntegerField(default=1)
    operator_role = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Required operator role or specialization."
    )
    required_skills = models.JSONField(
        default=list,
        blank=True,
        help_text="List of required operator skills or qualifications."
    )
    resource_spec = models.JSONField(default=dict, blank=True)
    input_materials = models.JSONField(
        default=list,
        blank=True,
        help_text="List of required raw materials per unit [{raw_material_id, quantity, unit}]."
    )
    output_materials = models.JSONField(
        default=list,
        blank=True,
        help_text="List of produced output materials per unit."
    )
    yield_rate_percent = models.FloatField(default=100.0, help_text="Expected quality yield rate (0-100%).")
    configuration = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "process_nodes"
        unique_together = [("process_version", "node_key")]
        ordering = ["node_key"]

    def __str__(self):
        return f"{self.name} [{self.node_key}] ({self.node_type})"


class ProcessEdge(models.Model):
    """
    Directed connection between two process nodes in the graph.
    Supports standard, conditional, and exception/rework transitions.
    """
    EDGE_TYPE_CHOICES = [
        ("STANDARD", "Standard Directed Flow"),
        ("CONDITIONAL", "Conditional Flow"),
        ("DEFAULT", "Default Flow (Fallback)"),
        ("EXCEPTION", "Exception / Rework Path"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    process_version = models.ForeignKey(
        ProcessVersion,
        on_delete=models.CASCADE,
        related_name="edges"
    )
    edge_key = models.CharField(max_length=50)
    source_node = models.ForeignKey(
        ProcessNode,
        on_delete=models.CASCADE,
        related_name="outgoing_edges"
    )
    target_node = models.ForeignKey(
        ProcessNode,
        on_delete=models.CASCADE,
        related_name="incoming_edges"
    )
    edge_type = models.CharField(max_length=50, choices=EDGE_TYPE_CHOICES, default="STANDARD")
    condition_expression = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Logic expression for conditional routing (e.g., 'yield >= 95.0')."
    )
    label = models.CharField(max_length=100, blank=True, default="")
    priority = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "process_edges"
        unique_together = [("process_version", "edge_key")]

    def __str__(self):
        return f"{self.source_node.node_key} -> {self.target_node.node_key} ({self.edge_type})"


class WorkOrder(models.Model):
    """
    Factory production work order specifying product, target quantity,
    assigned process definition/version, and operational schedule.
    """
    STATUS_CHOICES = [
        ("DRAFT", "Draft"),
        ("RELEASED", "Released"),
        ("IN_PROGRESS", "In Progress"),
        ("PAUSED", "Paused"),
        ("COMPLETED", "Completed"),
        ("CANCELLED", "Cancelled"),
    ]
    PRIORITY_CHOICES = [
        ("LOW", "Low"),
        ("NORMAL", "Normal"),
        ("HIGH", "High"),
        ("URGENT", "Urgent"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="work_orders"
    )
    order_number = models.CharField(max_length=50)
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name="work_orders"
    )
    process_definition = models.ForeignKey(
        ProcessDefinition,
        on_delete=models.CASCADE,
        related_name="work_orders"
    )
    process_version = models.ForeignKey(
        ProcessVersion,
        on_delete=models.CASCADE,
        related_name="work_orders"
    )
    assigned_line = models.ForeignKey(
        ProductionLine,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="work_orders"
    )
    quantity_target = models.IntegerField(help_text="Target units to manufacture.")
    quantity_completed = models.IntegerField(default=0)
    quantity_scrapped = models.IntegerField(default=0)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default="DRAFT")
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default="NORMAL")
    planned_start_date = models.DateTimeField(null=True, blank=True)
    planned_due_date = models.DateTimeField(null=True, blank=True)
    actual_start_date = models.DateTimeField(null=True, blank=True)
    actual_end_date = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "work_orders"
        unique_together = [("factory", "order_number")]
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.order_number}: {self.product.name} ({self.quantity_completed}/{self.quantity_target})"

    @property
    def progress_percent(self):
        if not self.quantity_target:
            return 0.0
        return round(min(100.0, (self.quantity_completed / self.quantity_target) * 100.0), 1)


class ProcessExecution(models.Model):
    """
    Active execution run of a work order through the process graph.
    Tracks live state, unit flows, bottleneck identification, and execution mode.
    """
    MODE_CHOICES = [
        ("SIMULATION", "Simulation Mode"),
        ("PRODUCTION", "Production Mode"),
    ]
    STATUS_CHOICES = [
        ("INITIALIZED", "Initialized"),
        ("RUNNING", "Running"),
        ("BLOCKED", "Blocked"),
        ("PAUSED", "Paused"),
        ("COMPLETED", "Completed"),
        ("FAILED", "Failed"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    work_order = models.ForeignKey(
        WorkOrder,
        on_delete=models.CASCADE,
        related_name="executions"
    )
    process_version = models.ForeignKey(
        ProcessVersion,
        on_delete=models.CASCADE,
        related_name="executions"
    )
    execution_number = models.CharField(max_length=50)
    mode = models.CharField(max_length=20, choices=MODE_CHOICES, default="SIMULATION")
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default="INITIALIZED")
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    current_progress_percent = models.FloatField(default=0.0)
    total_units_input = models.IntegerField(default=0)
    total_units_output = models.IntegerField(default=0)
    total_units_scrap = models.IntegerField(default=0)
    bottleneck_node = models.ForeignKey(
        ProcessNode,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="bottlenecked_executions"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "process_executions"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.execution_number} - {self.work_order.order_number} ({self.status})"


class StageExecution(models.Model):
    """
    Execution state of an individual process node/stage in an execution run.
    """
    STATUS_CHOICES = [
        ("PENDING", "Pending Dependencies"),
        ("READY", "Ready to Execute"),
        ("RUNNING", "Running"),
        ("COMPLETED", "Completed"),
        ("BLOCKED", "Blocked"),
        ("FAILED", "Failed"),
        ("SKIPPED", "Skipped Branch"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    process_execution = models.ForeignKey(
        ProcessExecution,
        on_delete=models.CASCADE,
        related_name="stage_executions"
    )
    node = models.ForeignKey(
        ProcessNode,
        on_delete=models.CASCADE,
        related_name="stage_executions"
    )
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default="PENDING")
    assigned_machine = models.ForeignKey(
        Machine,
        null=True,
        blank=True,
        on_delete=models.SET_NULL
    )
    units_queued = models.IntegerField(default=0)
    units_in_progress = models.IntegerField(default=0)
    units_completed = models.IntegerField(default=0)
    units_scrapped = models.IntegerField(default=0)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    duration_seconds = models.FloatField(default=0.0)
    retry_count = models.IntegerField(default=0)
    error_message = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "stage_executions"
        unique_together = [("process_execution", "node")]

    def __str__(self):
        return f"{self.process_execution.execution_number} - {self.node.name} ({self.status})"


class MaterialFlow(models.Model):
    """
    Granular material audit record tracking consumption, WIP transfer,
    finished goods output, and scrap generation per stage execution.
    """
    FLOW_TYPE_CHOICES = [
        ("INPUT_CONSUMPTION", "Raw Material Consumption"),
        ("WIP_TRANSFER", "Work-in-Progress Transfer"),
        ("FINISHED_GOODS", "Finished Output Goods"),
        ("SCRAP_REJECT", "Scrap / Quality Reject"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    process_execution = models.ForeignKey(
        ProcessExecution,
        on_delete=models.CASCADE,
        related_name="material_flows"
    )
    stage_execution = models.ForeignKey(
        StageExecution,
        on_delete=models.CASCADE,
        related_name="material_flows"
    )
    raw_material = models.ForeignKey(
        RawMaterial,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="flows"
    )
    flow_type = models.CharField(max_length=50, choices=FLOW_TYPE_CHOICES, default="INPUT_CONSUMPTION")
    quantity = models.FloatField()
    unit_of_measure = models.CharField(max_length=50, default="pcs")
    previous_stock_level = models.FloatField(default=0.0)
    new_stock_level = models.FloatField(default=0.0)
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, default="")

    class Meta:
        db_table = "material_flows"
        ordering = ["-timestamp"]

    def __str__(self):
        return f"{self.flow_type}: {self.quantity} {self.unit_of_measure} ({self.stage_execution.node.name})"


class ProductionEvent(models.Model):
    """
    Immutable event log capturing all operational and simulation events.
    """
    SEVERITY_CHOICES = [
        ("INFO", "Info"),
        ("WARNING", "Warning"),
        ("ERROR", "Error"),
        ("CRITICAL", "Critical"),
    ]
    SOURCE_CHOICES = [
        ("SIMULATION", "Simulation Engine"),
        ("OPERATOR", "Operator Manual Action"),
        ("SYSTEM_ENGINE", "System Engine Automated"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="production_events"
    )
    work_order = models.ForeignKey(
        WorkOrder,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="events"
    )
    process_execution = models.ForeignKey(
        ProcessExecution,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="events"
    )
    stage_execution = models.ForeignKey(
        StageExecution,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="events"
    )
    event_type = models.CharField(max_length=100)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default="INFO")
    source = models.CharField(max_length=50, choices=SOURCE_CHOICES, default="SIMULATION")
    payload = models.JSONField(default=dict, blank=True)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "production_events"
        ordering = ["-timestamp"]

    def __str__(self):
        return f"[{self.severity}] {self.event_type}: {self.message[:60]}"


class SimulationScenario(models.Model):
    """
    Pre-configured manufacturing anomaly and stress testing scenarios
    for reproducible, deterministic simulation.
    """
    SCENARIO_TYPE_CHOICES = [
        ("MACHINE_BREAKDOWN", "Machine Breakdown / Unscheduled Stoppage"),
        ("MATERIAL_SHORTAGE", "Raw Material Inventory Starvation"),
        ("PRODUCTION_DELAY", "Cycle Time Inflation / Line Bottleneck"),
        ("QUALITY_REJECTION", "Quality Failure Spike / High Scrap"),
        ("DEMAND_SURGE", "Rush Order Surge / Capacity Strain"),
        ("BOTTLENECK_FORMATION", "Dynamic Downstream Queue Bottleneck"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="simulation_scenarios"
    )
    name = models.CharField(max_length=255)
    scenario_type = models.CharField(max_length=50, choices=SCENARIO_TYPE_CHOICES)
    parameters = models.JSONField(default=dict, blank=True)
    random_seed = models.IntegerField(default=42, help_text="Seed for reproducible pseudo-random variance.")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "simulation_scenarios"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.scenario_type}) - {self.factory.name}"
