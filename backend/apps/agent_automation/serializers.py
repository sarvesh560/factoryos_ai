"""
FactoryOS AI — Serializers for Agent Automation Engine
Phase 4: Multi-Agent Manufacturing Orchestration & Approvals
"""
from rest_framework import serializers
from apps.agent_automation.models import (
    ManufacturingEvent,
    AgentConfiguration,
    AgentDecision,
    ApprovalRequest,
    ActionExecution,
    AutomationAuditEvent,
    ManufacturingEventType,
    EventSeverity,
    AgentRun,
    AgentRunStatus,
    AgentPlan,
    AgentStep,
    AgentStepStatus,
    AgentToolCall,
    AgentObservation,
)


class AgentConfigurationSerializer(serializers.ModelSerializer):
    agent_type_display = serializers.CharField(source="get_agent_type_display", read_only=True)
    factory_name = serializers.CharField(source="factory.name", read_only=True, default=None)

    class Meta:
        model = AgentConfiguration
        fields = [
            "id",
            "name",
            "key",
            "description",
            "agent_type",
            "agent_type_display",
            "is_enabled",
            "supported_event_types",
            "allowed_action_types",
            "factory",
            "factory_name",
            "requires_approval",
            "config",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AgentDecisionSerializer(serializers.ModelSerializer):
    agent_name = serializers.CharField(source="agent.name", read_only=True)
    agent_key = serializers.CharField(source="agent.key", read_only=True)
    agent_type = serializers.CharField(source="agent.agent_type", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    event_type = serializers.CharField(source="event.event_type", read_only=True)
    event_severity = serializers.CharField(source="event.severity", read_only=True)

    class Meta:
        model = AgentDecision
        fields = [
            "id",
            "event",
            "event_type",
            "event_severity",
            "agent",
            "agent_name",
            "agent_key",
            "agent_type",
            "status",
            "status_display",
            "findings",
            "evidence",
            "proposed_action",
            "action_parameters",
            "rationale",
            "confidence_score",
            "provider_info",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class ManufacturingEventSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    factory_code = serializers.CharField(source="factory.code", read_only=True)
    event_type_display = serializers.CharField(source="get_event_type_display", read_only=True)
    severity_display = serializers.CharField(source="get_severity_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    decisions = AgentDecisionSerializer(many=True, read_only=True)

    class Meta:
        model = ManufacturingEvent
        fields = [
            "id",
            "factory",
            "factory_name",
            "factory_code",
            "event_type",
            "event_type_display",
            "source_type",
            "source_id",
            "severity",
            "severity_display",
            "payload",
            "timestamp",
            "status",
            "status_display",
            "correlation_id",
            "error_message",
            "decisions",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class ManufacturingEventSimulateSerializer(serializers.Serializer):
    factory_id = serializers.UUIDField(required=True)
    event_type = serializers.ChoiceField(choices=ManufacturingEventType.choices, required=True)
    severity = serializers.ChoiceField(choices=EventSeverity.choices, default=EventSeverity.WARNING)
    source_type = serializers.CharField(max_length=64, default="SIMULATION")
    source_id = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")
    payload = serializers.DictField(required=False, default=dict)
    correlation_id = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")


class ApprovalRequestSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    agent_name = serializers.CharField(source="decision.agent.name", read_only=True)
    agent_key = serializers.CharField(source="decision.agent.key", read_only=True)
    event_id = serializers.CharField(source="decision.event.id", read_only=True)
    event_type = serializers.CharField(source="decision.event.event_type", read_only=True)
    decision_rationale = serializers.CharField(source="decision.rationale", read_only=True)
    action_execution_id = serializers.CharField(source="action_execution.id", read_only=True, default=None)
    action_execution_status = serializers.CharField(source="action_execution.status", read_only=True, default=None)

    class Meta:
        model = ApprovalRequest
        fields = [
            "id",
            "decision",
            "factory",
            "factory_name",
            "agent_name",
            "agent_key",
            "event_id",
            "event_type",
            "status",
            "requested_action",
            "action_summary",
            "action_parameters",
            "decision_rationale",
            "urgency",
            "reviewed_by",
            "review_notes",
            "reviewed_at",
            "action_execution_id",
            "action_execution_status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class ApprovalReviewActionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=["APPROVE", "REJECT"], required=True)
    notes = serializers.CharField(required=False, allow_blank=True, default="")
    reviewer = serializers.CharField(required=False, allow_blank=True, default="Plant Operator")


class ActionExecutionSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = ActionExecution
        fields = [
            "id",
            "decision",
            "approval_request",
            "factory",
            "factory_name",
            "action_type",
            "parameters",
            "status",
            "status_display",
            "idempotency_key",
            "result_payload",
            "error_message",
            "retry_count",
            "executed_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AutomationAuditEventSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)

    class Meta:
        model = AutomationAuditEvent
        fields = [
            "id",
            "factory",
            "factory_name",
            "event_category",
            "reference_id",
            "actor",
            "details",
            "timestamp",
        ]
        read_only_fields = ["id", "timestamp"]


class AutomationSummarySerializer(serializers.Serializer):
    total_agents = serializers.IntegerField()
    enabled_agents = serializers.IntegerField()
    total_events_processed = serializers.IntegerField()
    pending_approvals = serializers.IntegerField()
    successful_actions = serializers.IntegerField()
    failed_actions = serializers.IntegerField()


# =====================================================================
# GOAL-DRIVEN AGENT RUNTIME SERIALIZERS
# =====================================================================

class AgentStepSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    approval_id = serializers.UUIDField(source="approval_request_id", read_only=True, allow_null=True)

    class Meta:
        model = AgentStep
        fields = [
            "id",
            "step_number",
            "title",
            "description",
            "tool_name",
            "tool_arguments",
            "is_consequential",
            "status",
            "status_display",
            "result_data",
            "error_message",
            "approval_id",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AgentPlanSerializer(serializers.ModelSerializer):
    steps = AgentStepSerializer(many=True, read_only=True)

    class Meta:
        model = AgentPlan
        fields = [
            "id",
            "version",
            "goal_summary",
            "completion_criteria",
            "is_active",
            "steps",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class AgentToolCallSerializer(serializers.ModelSerializer):
    class Meta:
        model = AgentToolCall
        fields = [
            "id",
            "step_id",
            "tool_name",
            "arguments",
            "result_payload",
            "status",
            "error_message",
            "idempotency_key",
            "duration_ms",
            "executed_at",
        ]
        read_only_fields = ["id", "executed_at"]


class AgentObservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AgentObservation
        fields = [
            "id",
            "step_id",
            "observation_type",
            "content",
            "data",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class AgentRunListSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = AgentRun
        fields = [
            "id",
            "factory",
            "factory_name",
            "goal_text",
            "industry_profile_key",
            "profile_version",
            "status",
            "status_display",
            "provider_type",
            "model_name",
            "execution_mode",
            "fallback_occurred",
            "current_step_index",
            "max_steps",
            "created_at",
            "completed_at",
        ]
        read_only_fields = ["id", "created_at", "completed_at"]


class AgentRunDetailSerializer(serializers.ModelSerializer):
    factory_name = serializers.CharField(source="factory.name", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    active_plan = AgentPlanSerializer(read_only=True)
    observations = AgentObservationSerializer(many=True, read_only=True)
    tool_calls = AgentToolCallSerializer(many=True, read_only=True)

    class Meta:
        model = AgentRun
        fields = [
            "id",
            "factory",
            "factory_name",
            "goal_text",
            "industry_profile_key",
            "profile_version",
            "status",
            "status_display",
            "provider_type",
            "model_name",
            "execution_mode",
            "fallback_occurred",
            "fallback_reason",
            "max_steps",
            "current_step_index",
            "replan_count",
            "max_replans",
            "clarification_question",
            "clarification_answer",
            "completion_summary",
            "error_message",
            "active_plan",
            "observations",
            "tool_calls",
            "created_at",
            "updated_at",
            "completed_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "completed_at"]


class CreateAgentRunInputSerializer(serializers.Serializer):
    factory_id = serializers.UUIDField(required=True)
    goal_text = serializers.CharField(required=True, min_length=5, max_length=1000)
    industry_profile_key = serializers.CharField(required=False, default="GENERAL_DISCRETE")
    provider_mode_override = serializers.CharField(required=False, allow_blank=True, default=None)


class ProviderStatusSerializer(serializers.Serializer):
    configured_provider = serializers.CharField()
    active_mode = serializers.CharField()
    is_llm_available = serializers.BooleanField()
    model_name = serializers.CharField()
    base_url = serializers.CharField()
    masked_api_key = serializers.CharField()
    timeout_seconds = serializers.IntegerField()
    max_retries = serializers.IntegerField()
    provider_version = serializers.CharField()

