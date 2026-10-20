"""
FactoryOS AI — Event-Driven AI Agent Automation Engine Models
Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Audit Trail
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone
from apps.factories.models import Factory


class ManufacturingEventType(models.TextChoices):
    MACHINE_ANOMALY = "MACHINE_ANOMALY", "Machine Anomaly / Breakdown"
    PRODUCTION_DELAY = "PRODUCTION_DELAY", "Production Delay / Bottleneck"
    QUALITY_FAILURE = "QUALITY_FAILURE", "Quality Failure / High Scrap Rate"
    INVENTORY_SHORTAGE = "INVENTORY_SHORTAGE", "Inventory Shortage / Starvation"
    MAINTENANCE_DUE = "MAINTENANCE_DUE", "Preventive Maintenance Due"
    WORK_ORDER_STATUS_CHANGED = "WORK_ORDER_STATUS_CHANGED", "Work Order Status Changed"


class EventSeverity(models.TextChoices):
    INFO = "INFO", "Informational"
    WARNING = "WARNING", "Warning"
    ERROR = "ERROR", "Error"
    CRITICAL = "CRITICAL", "Critical / Urgent"


class EventProcessingStatus(models.TextChoices):
    PENDING = "PENDING", "Pending Evaluation"
    PROCESSED = "PROCESSED", "Processed by Agents"
    IGNORED = "IGNORED", "Ignored (No Matching Agent)"
    FAILED = "FAILED", "Processing Failed"


class AgentType(models.TextChoices):
    PRODUCTION = "PRODUCTION", "Production Orchestration Agent"
    MAINTENANCE = "MAINTENANCE", "Predictive & Preventative Maintenance Agent"
    QUALITY = "QUALITY", "Quality Assurance & Scrap Reduction Agent"
    INVENTORY = "INVENTORY", "Inventory Replenishment & WIP Agent"
    ENERGY = "ENERGY", "Energy Optimization & Sustainability Agent"


class DecisionStatus(models.TextChoices):
    NO_ACTION = "NO_ACTION", "No Action Required"
    RECOMMENDATION = "RECOMMENDATION", "Advisory Recommendation"
    AWAITING_APPROVAL = "AWAITING_APPROVAL", "Action Awaiting Human Approval"
    ACTION_REQUESTED = "ACTION_REQUESTED", "Action Approved / Requested"
    REJECTED = "REJECTED", "Action Rejected by Human Reviewer"
    COMPLETED = "COMPLETED", "Action Successfully Executed"
    FAILED = "FAILED", "Action Execution Failed"


class ApprovalStatus(models.TextChoices):
    PENDING = "PENDING", "Pending Review"
    APPROVED = "APPROVED", "Approved"
    REJECTED = "REJECTED", "Rejected"
    EXPIRED = "EXPIRED", "Expired / Superseded"


class ActionStatus(models.TextChoices):
    PENDING_APPROVAL = "PENDING_APPROVAL", "Pending Human Approval"
    APPROVED = "APPROVED", "Approved for Execution"
    EXECUTING = "EXECUTING", "Executing Handler"
    COMPLETED = "COMPLETED", "Executed Successfully"
    REJECTED = "REJECTED", "Rejected by Human"
    FAILED = "FAILED", "Execution Failed"


class ActionType(models.TextChoices):
    CREATE_MAINTENANCE_TICKET = "CREATE_MAINTENANCE_TICKET", "Create Maintenance Ticket"
    CREATE_QUALITY_INSPECTION = "CREATE_QUALITY_INSPECTION", "Create Quality Inspection Order"
    CREATE_INVENTORY_REPLENISHMENT_REQUEST = (
        "CREATE_INVENTORY_REPLENISHMENT_REQUEST",
        "Create Inventory Replenishment Request",
    )
    CREATE_PRODUCTION_INVESTIGATION = (
        "CREATE_PRODUCTION_INVESTIGATION",
        "Create Production Delay Investigation",
    )
    SEND_IN_APP_NOTIFICATION = "SEND_IN_APP_NOTIFICATION", "Send In-App Notification"


class ManufacturingEvent(models.Model):
    """
    Persistent manufacturing operational event ingested from simulated devices,
    future PLC adapters, IoT sensors, or shop-floor interactions.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="manufacturing_events",
        help_text="Factory scope for tenant isolation.",
    )
    event_type = models.CharField(
        max_length=64,
        choices=ManufacturingEventType.choices,
        help_text="Standardized classification of the manufacturing event.",
    )
    source_type = models.CharField(
        max_length=64,
        default="SIMULATION",
        help_text="Originating source (SIMULATION, SENSOR, OPERATOR, PLC_ADAPTER, SYSTEM).",
    )
    source_id = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Optional identifier of originating asset (Machine ID, Line ID, etc.).",
    )
    severity = models.CharField(
        max_length=20,
        choices=EventSeverity.choices,
        default=EventSeverity.INFO,
    )
    payload = models.JSONField(
        default=dict,
        blank=True,
        help_text="Structured operational telemetry and context payload.",
    )
    timestamp = models.DateTimeField(
        default=timezone.now,
        help_text="Time at which the operational event occurred.",
    )
    status = models.CharField(
        max_length=32,
        choices=EventProcessingStatus.choices,
        default=EventProcessingStatus.PENDING,
    )
    correlation_id = models.CharField(
        max_length=128,
        blank=True,
        default="",
        db_index=True,
        help_text="Idempotency or trace correlation identifier.",
    )
    error_message = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "agent_manufacturing_events"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["factory", "-timestamp"]),
            models.Index(fields=["event_type", "status"]),
            models.Index(fields=["correlation_id"]),
        ]

    def __str__(self):
        return f"[{self.severity}] {self.event_type} @ {self.factory.code} ({self.status})"


class AgentConfiguration(models.Model):
    """
    Configuration specification for a specialized manufacturing AI agent.
    Controls event subscriptions, permissible action types, and human approval policies.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=128)
    key = models.CharField(
        max_length=64,
        unique=True,
        help_text="Unique stable key (e.g. 'maintenance_agent', 'production_agent').",
    )
    description = models.TextField(blank=True, default="")
    agent_type = models.CharField(max_length=64, choices=AgentType.choices)
    is_enabled = models.BooleanField(
        default=True,
        help_text="When disabled, this agent ignores events and initiates no actions.",
    )
    supported_event_types = models.JSONField(
        default=list,
        blank=True,
        help_text="List of ManufacturingEventType values this agent is configured to handle.",
    )
    allowed_action_types = models.JSONField(
        default=list,
        blank=True,
        help_text="List of ActionType values this agent is permitted to propose.",
    )
    factory = models.ForeignKey(
        Factory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="custom_agents",
        help_text="Null indicates an enterprise-wide default specialist agent.",
    )
    requires_approval = models.BooleanField(
        default=True,
        help_text="When True, proposed actions require human sign-off prior to execution.",
    )
    config = models.JSONField(
        default=dict,
        blank=True,
        help_text="Operational thresholds, sensitivity, and policy parameters.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "agent_configurations"
        ordering = ["name"]

    def __str__(self):
        status_str = "ENABLED" if self.is_enabled else "DISABLED"
        return f"{self.name} ({self.key}) [{status_str}]"


class AgentDecision(models.Model):
    """
    Structured outcome of an agent evaluating a manufacturing event.
    Stores findings, empirical evidence, proposed action, confidence, and rationale.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event = models.ForeignKey(
        ManufacturingEvent,
        on_delete=models.CASCADE,
        related_name="decisions",
    )
    agent = models.ForeignKey(
        AgentConfiguration,
        on_delete=models.CASCADE,
        related_name="decisions",
    )
    status = models.CharField(
        max_length=32,
        choices=DecisionStatus.choices,
        default=DecisionStatus.NO_ACTION,
    )
    findings = models.TextField(help_text="Synthesized factual assessment of the event.")
    evidence = models.JSONField(
        default=dict,
        blank=True,
        help_text="Captured telemetry, metrics, threshold comparisons, and citations.",
    )
    proposed_action = models.CharField(
        max_length=64,
        choices=ActionType.choices,
        blank=True,
        default="",
        help_text="Proposed action handler if intervention is recommended.",
    )
    action_parameters = models.JSONField(
        default=dict,
        blank=True,
        help_text="Validated arguments for executing the proposed action.",
    )
    rationale = models.TextField(help_text="Detailed justification and decision reasoning.")
    confidence_score = models.FloatField(
        default=1.0,
        help_text="Confidence or rule certainty metric (0.0 to 1.0).",
    )
    provider_info = models.JSONField(
        default=dict,
        blank=True,
        help_text="Metadata regarding the decision provider or heuristic rule applied.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "agent_decisions"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["event", "agent"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self):
        return f"{self.agent.key} -> {self.status} on {self.event.event_type}"


class ApprovalRequest(models.Model):
    """
    Formal human-in-the-loop review item for proposed automation interventions.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.ForeignKey(
        AgentDecision,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="approval_requests",
    )
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="approval_requests",
    )
    status = models.CharField(
        max_length=32,
        choices=ApprovalStatus.choices,
        default=ApprovalStatus.PENDING,
    )
    requested_action = models.CharField(max_length=64)
    action_summary = models.TextField()
    action_parameters = models.JSONField(default=dict, blank=True)
    urgency = models.CharField(
        max_length=20,
        choices=EventSeverity.choices,
        default=EventSeverity.WARNING,
    )
    reviewed_by = models.CharField(max_length=128, blank=True, default="")
    review_notes = models.TextField(blank=True, default="")
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "agent_approval_requests"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["factory", "status"]),
        ]

    def __str__(self):
        return f"Approval {self.requested_action} [{self.status}] for {self.factory.name}"


class ActionExecution(models.Model):
    """
    Execution tracking and audit record for an authorized workflow intervention.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.ForeignKey(
        AgentDecision,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="action_executions",
    )
    approval_request = models.OneToOneField(
        ApprovalRequest,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="action_execution",
    )
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="action_executions",
    )
    action_type = models.CharField(max_length=64, choices=ActionType.choices)
    parameters = models.JSONField(default=dict, blank=True)
    status = models.CharField(
        max_length=32,
        choices=ActionStatus.choices,
        default=ActionStatus.PENDING_APPROVAL,
    )
    idempotency_key = models.CharField(max_length=128, db_index=True)
    result_payload = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True, default="")
    retry_count = models.IntegerField(default=0)
    executed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "agent_action_executions"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["factory", "status"]),
            models.Index(fields=["idempotency_key"]),
        ]

    def __str__(self):
        return f"{self.action_type} [{self.status}] @ {self.factory.name}"


class AutomationAuditEvent(models.Model):
    """
    Immutable audit trail logging every step of the event-agent-approval-action pipeline.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="automation_audits",
    )
    event_category = models.CharField(
        max_length=64,
        help_text="Classification: EVENT_INGESTED, DECISION_PRODUCED, APPROVAL_REQUESTED, APPROVAL_DECIDED, ACTION_EXECUTED, ACTION_FAILED, AGENT_TOGGLED",
    )
    reference_id = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="ID of the related event, decision, approval, or action.",
    )
    actor = models.CharField(max_length=128, default="SYSTEM")
    details = models.JSONField(
        default=dict,
        blank=True,
        help_text="Structured non-sensitive audit details and outcomes.",
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "agent_automation_audits"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["factory", "-timestamp"]),
            models.Index(fields=["event_category"]),
        ]

    def __str__(self):
        return f"[{self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}] {self.event_category} by {self.actor}"


class AgentRunStatus(models.TextChoices):
    PLANNING = "PLANNING", "Planning Execution"
    RUNNING = "RUNNING", "Running Steps"
    AWAITING_APPROVAL = "AWAITING_APPROVAL", "Awaiting Human Approval"
    NEEDS_CLARIFICATION = "NEEDS_CLARIFICATION", "Needs Operator Clarification"
    BLOCKED = "BLOCKED", "Execution Blocked"
    COMPLETED = "COMPLETED", "Goal Completed"
    FAILED = "FAILED", "Execution Failed"
    CANCELLED = "CANCELLED", "Goal Cancelled"


class AgentStepStatus(models.TextChoices):
    PENDING = "PENDING", "Pending Execution"
    READY = "READY", "Ready to Execute"
    RUNNING = "RUNNING", "Executing Tool"
    AWAITING_APPROVAL = "AWAITING_APPROVAL", "Awaiting Approval"
    COMPLETED = "COMPLETED", "Completed"
    FAILED = "FAILED", "Failed"
    SKIPPED = "SKIPPED", "Skipped"


class AgentRun(models.Model):
    """
    Goal-driven autonomous manufacturing agent execution run.
    Represents an overarching user goal evaluated across versioned industry profiles,
    executed tool-by-tool with strict safety barriers and verification.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="agent_runs",
        help_text="Factory scope for tenant authorization.",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="agent_runs",
        help_text="User initiating the goal run.",
    )
    goal_text = models.TextField(help_text="Original natural-language manufacturing goal.")
    industry_profile_key = models.CharField(
        max_length=64,
        default="GENERAL_DISCRETE",
        help_text="Resolved industry profile key (e.g., CNC_MACHINING, AUTOMOTIVE_EV).",
    )
    profile_version = models.CharField(max_length=32, default="1.0.0")
    status = models.CharField(
        max_length=32,
        choices=AgentRunStatus.choices,
        default=AgentRunStatus.PLANNING,
    )
    provider_type = models.CharField(
        max_length=32,
        default="hybrid",
        help_text="Configured provider mode: 'llm', 'deterministic', or 'hybrid'.",
    )
    model_name = models.CharField(
        max_length=128,
        default="deterministic-rules-v1",
        help_text="Active model identifier (e.g. gpt-4o, gemini-1.5-flash, deterministic).",
    )
    execution_mode = models.CharField(
        max_length=32,
        default="hybrid",
        help_text="Actual runtime mode executed for this run.",
    )
    fallback_occurred = models.BooleanField(
        default=False,
        help_text="True if LLM was unavailable and deterministic fallback was invoked.",
    )
    fallback_reason = models.TextField(blank=True, default="")
    max_steps = models.IntegerField(default=10)
    current_step_index = models.IntegerField(default=0)
    replan_count = models.IntegerField(default=0)
    max_replans = models.IntegerField(default=3)
    clarification_question = models.TextField(blank=True, default="")
    clarification_answer = models.TextField(blank=True, default="")
    completion_summary = models.TextField(blank=True, default="")
    error_message = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "agent_runs"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["factory", "-created_at"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self):
        return f"Run [{self.status}] {self.goal_text[:50]}... ({self.factory.name})"

    @property
    def active_plan(self):
        return self.plans.filter(is_active=True).order_by("-version").first()


class AgentPlan(models.Model):
    """
    Validated execution plan generated by the AI provider for an AgentRun.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    run = models.ForeignKey(
        AgentRun,
        on_delete=models.CASCADE,
        related_name="plans",
    )
    version = models.PositiveIntegerField(default=1)
    goal_summary = models.TextField(blank=True, default="")
    completion_criteria = models.JSONField(default=list, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "agent_plans"
        ordering = ["run", "-version"]
        unique_together = [("run", "version")]

    def __str__(self):
        return f"Plan v{self.version} for Run {self.run_id}"


class AgentStep(models.Model):
    """
    Ordered execution step in an AgentPlan invoking a registered, typed manufacturing tool.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(
        AgentPlan,
        on_delete=models.CASCADE,
        related_name="steps",
    )
    step_number = models.PositiveIntegerField()
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default="")
    tool_name = models.CharField(max_length=128)
    tool_arguments = models.JSONField(default=dict, blank=True)
    is_consequential = models.BooleanField(
        default=False,
        help_text="True if this tool causes irreversible production/inventory mutations requiring human approval.",
    )
    status = models.CharField(
        max_length=32,
        choices=AgentStepStatus.choices,
        default=AgentStepStatus.PENDING,
    )
    result_data = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True, default="")
    approval_request = models.ForeignKey(
        ApprovalRequest,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="agent_steps",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "agent_steps"
        ordering = ["plan", "step_number"]
        unique_together = [("plan", "step_number")]

    def __str__(self):
        return f"Step {self.step_number}: {self.title} [{self.status}]"


class AgentToolCall(models.Model):
    """
    Execution record of an authorized tool call with idempotency guarantees.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    run = models.ForeignKey(
        AgentRun,
        on_delete=models.CASCADE,
        related_name="tool_calls",
    )
    step = models.ForeignKey(
        AgentStep,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tool_calls",
    )
    tool_name = models.CharField(max_length=128)
    arguments = models.JSONField(default=dict, blank=True)
    result_payload = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=32, default="SUCCESS")
    error_message = models.TextField(blank=True, default="")
    idempotency_key = models.CharField(max_length=128, db_index=True)
    duration_ms = models.IntegerField(default=0)
    executed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "agent_tool_calls"
        ordering = ["-executed_at"]

    def __str__(self):
        return f"{self.tool_name} [{self.status}] @ {self.executed_at.strftime('%H:%M:%S')}"


class AgentObservation(models.Model):
    """
    Structured observation produced by tool results or state inspections during an AgentRun.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    run = models.ForeignKey(
        AgentRun,
        on_delete=models.CASCADE,
        related_name="observations",
    )
    step = models.ForeignKey(
        AgentStep,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="observations",
    )
    observation_type = models.CharField(
        max_length=64,
        default="TOOL_RESULT",
        help_text="Classification: TOOL_RESULT, STATE_VERIFICATION, BLOCKER, ANOMALY, CLARIFICATION",
    )
    content = models.TextField()
    data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "agent_observations"
        ordering = ["-created_at"]

    def __str__(self):
        return f"[{self.observation_type}] {self.content[:60]}"

