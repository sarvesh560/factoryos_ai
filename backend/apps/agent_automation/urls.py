"""
FactoryOS AI — Agent Automation URL Patterns
Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Audit Trail
"""
from django.urls import path
from .views import (
    AutomationSummaryView,
    AgentListView,
    AgentDetailView,
    AgentToggleView,
    ManufacturingEventListCreateView,
    ManufacturingEventDetailView,
    AgentDecisionListView,
    ApprovalRequestListView,
    ApprovalRequestDecideView,
    ActionExecutionRetryView,
    AutomationAuditListView,
    IndustryProfileListView,
    ProviderStatusView,
    AgentRunListCreateView,
    AgentRunDetailView,
    AgentRunStepAdvanceView,
    AgentRunApprovalView,
    AgentRunClarificationView,
    AgentRunCancelView,
)

urlpatterns = [
    # Summary Dashboard
    path("summary/", AutomationSummaryView.as_view(), name="automation-summary"),

    # Industry Profiles & Provider Status
    path("industries/", IndustryProfileListView.as_view(), name="automation-industry-profiles"),
    path("provider-status/", ProviderStatusView.as_view(), name="automation-provider-status"),

    # Goal-Driven Agent Runs
    path("runs/", AgentRunListCreateView.as_view(), name="automation-run-list-create"),
    path("runs/<uuid:run_id>/", AgentRunDetailView.as_view(), name="automation-run-detail"),
    path("runs/<uuid:run_id>/step/", AgentRunStepAdvanceView.as_view(), name="automation-run-step-advance"),
    path("runs/<uuid:run_id>/approve/", AgentRunApprovalView.as_view(), name="automation-run-approve"),
    path("runs/<uuid:run_id>/clarify/", AgentRunClarificationView.as_view(), name="automation-run-clarify"),
    path("runs/<uuid:run_id>/cancel/", AgentRunCancelView.as_view(), name="automation-run-cancel"),

    # Agent Configurations
    path("agents/", AgentListView.as_view(), name="automation-agent-list"),
    path("agents/<str:agent_identifier>/", AgentDetailView.as_view(), name="automation-agent-detail"),
    path("agents/<str:agent_identifier>/toggle/", AgentToggleView.as_view(), name="automation-agent-toggle"),

    # Manufacturing Events & Ingestion
    path("events/", ManufacturingEventListCreateView.as_view(), name="automation-event-list-create"),
    path("events/simulate/", ManufacturingEventListCreateView.as_view(), name="automation-event-simulate"),
    path("events/<uuid:event_id>/", ManufacturingEventDetailView.as_view(), name="automation-event-detail"),

    # Agent Decisions
    path("decisions/", AgentDecisionListView.as_view(), name="automation-decision-list"),

    # Human-in-the-Loop Approvals
    path("approvals/", ApprovalRequestListView.as_view(), name="automation-approval-list"),
    path("approvals/<uuid:approval_id>/decide/", ApprovalRequestDecideView.as_view(), name="automation-approval-decide"),

    # Action Execution & Retries
    path("actions/<uuid:execution_id>/retry/", ActionExecutionRetryView.as_view(), name="automation-action-retry"),

    # Audit Trail
    path("audits/", AutomationAuditListView.as_view(), name="automation-audit-list"),
]
