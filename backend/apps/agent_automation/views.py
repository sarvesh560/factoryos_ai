"""
FactoryOS AI — Agent Automation Views & API Endpoints
Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Audit Trail
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.db import transaction
from drf_spectacular.utils import extend_schema, OpenApiParameter

from apps.factories.models import Factory
from apps.processes.views import check_factory_authorization
from apps.agent_automation.models import (
    ManufacturingEvent,
    AgentConfiguration,
    AgentDecision,
    ApprovalRequest,
    ActionExecution,
    AutomationAuditEvent,
    ApprovalStatus,
    ActionStatus,
    EventProcessingStatus,
    AgentRun,
    AgentRunStatus,
    AgentPlan,
    AgentStep,
)
from apps.agent_automation.serializers import (
    AgentConfigurationSerializer,
    AgentDecisionSerializer,
    ManufacturingEventSerializer,
    ManufacturingEventSimulateSerializer,
    ApprovalRequestSerializer,
    ApprovalReviewActionSerializer,
    ActionExecutionSerializer,
    AutomationAuditEventSerializer,
    AutomationSummarySerializer,
    AgentRunListSerializer,
    AgentRunDetailSerializer,
    CreateAgentRunInputSerializer,
    ProviderStatusSerializer,
)
from apps.agent_automation.services.agent_seeder import seed_default_agents
from apps.agent_automation.services.decision_service import AgentDecisionService
from apps.agent_automation.services.industry_profiles import IndustryProfileRegistry
from apps.agent_automation.services.provider_manager import ProviderManager
from apps.agent_automation.services.goal_runtime import GoalRuntimeService


# =====================================================================
# 1. AUTOMATION KPI SUMMARY
# =====================================================================

class AutomationSummaryView(APIView):
    """
    Returns aggregate operational health and pipeline metrics for agent automation.
    """
    @extend_schema(
        summary="Automation Summary",
        description="Returns counts of active agents, processed events, pending approvals, and executions.",
        parameters=[
            OpenApiParameter("factory_id", str, description="Factory UUID filter", required=False),
        ],
        responses={200: AutomationSummarySerializer},
    )
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        factory = None
        if factory_id:
            factory = get_object_or_404(Factory, id=factory_id)
            is_auth, err_msg, err_status = check_factory_authorization(request, factory)
            if not is_auth:
                return Response({"success": False, "error": err_msg}, status=err_status)

        # Seed defaults if empty
        if not AgentConfiguration.objects.exists():
            seed_default_agents()

        agent_qs = AgentConfiguration.objects.all()
        event_qs = ManufacturingEvent.objects.all()
        approval_qs = ApprovalRequest.objects.all()
        action_qs = ActionExecution.objects.all()

        if factory:
            event_qs = event_qs.filter(factory=factory)
            approval_qs = approval_qs.filter(factory=factory)
            action_qs = action_qs.filter(factory=factory)

        data = {
            "total_agents": agent_qs.count(),
            "enabled_agents": agent_qs.filter(is_enabled=True).count(),
            "total_events_processed": event_qs.filter(status=EventProcessingStatus.PROCESSED).count(),
            "pending_approvals": approval_qs.filter(status=ApprovalStatus.PENDING).count(),
            "successful_actions": action_qs.filter(status=ActionStatus.COMPLETED).count(),
            "failed_actions": action_qs.filter(status=ActionStatus.FAILED).count(),
        }
        return Response({"success": True, "data": data})


# =====================================================================
# 2. AGENT CONFIGURATION MANAGEMENT
# =====================================================================

class AgentListView(APIView):
    """
    Lists all specialist AI agents. Idempotently provisions default agents if none exist.
    """
    @extend_schema(
        summary="List Agents",
        description="List all available specialist AI agents and their operational status.",
        parameters=[
            OpenApiParameter("agent_type", str, description="Filter by AgentType", required=False),
        ],
        responses={200: AgentConfigurationSerializer(many=True)},
    )
    def get(self, request):
        if not AgentConfiguration.objects.exists():
            seed_default_agents()

        queryset = AgentConfiguration.objects.all().order_by("name")
        agent_type = request.query_params.get("agent_type")
        if agent_type:
            queryset = queryset.filter(agent_type=agent_type.upper())

        serializer = AgentConfigurationSerializer(queryset, many=True)
        return Response({"success": True, "count": queryset.count(), "results": serializer.data})


class AgentDetailView(APIView):
    """
    Retrieves configuration details for a specific specialist agent.
    """
    @extend_schema(summary="Get Agent Details", responses={200: AgentConfigurationSerializer})
    def get(self, request, agent_identifier):
        if not AgentConfiguration.objects.exists():
            seed_default_agents()

        # Support lookup by UUID or key
        agent = None
        try:
            agent = AgentConfiguration.objects.filter(id=agent_identifier).first()
        except Exception:
            pass
        if not agent:
            agent = get_object_or_404(AgentConfiguration, key=agent_identifier)

        serializer = AgentConfigurationSerializer(agent)
        return Response({"success": True, "agent": serializer.data})


class AgentToggleView(APIView):
    """
    Enables or disables a specialist agent.
    """
    @extend_schema(
        summary="Toggle Agent State",
        description="Enable or disable an AI agent. When disabled, the agent ignores events.",
        request={"application/json": {"type": "object", "properties": {"is_enabled": {"type": "boolean"}}}},
        responses={200: AgentConfigurationSerializer},
    )
    @transaction.atomic
    def post(self, request, agent_identifier):
        agent = None
        try:
            agent = AgentConfiguration.objects.filter(id=agent_identifier).first()
        except Exception:
            pass
        if not agent:
            agent = get_object_or_404(AgentConfiguration, key=agent_identifier)

        is_enabled = request.data.get("is_enabled")
        if is_enabled is None:
            # Toggle current state if not specified
            is_enabled = not agent.is_enabled

        agent.is_enabled = bool(is_enabled)
        agent.save(update_fields=["is_enabled", "updated_at"])

        # Audit
        AutomationAuditEvent.objects.create(
            factory=agent.factory or Factory.objects.filter(is_active=True).first(),
            event_category="AGENT_TOGGLED",
            reference_id=str(agent.id),
            actor=request.user.username if getattr(request, "user", None) and request.user.is_authenticated else "Operator",
            details={"agent_key": agent.key, "is_enabled": agent.is_enabled},
        )

        serializer = AgentConfigurationSerializer(agent)
        return Response({
            "success": True,
            "message": f"Agent '{agent.name}' is now {'ENABLED' if agent.is_enabled else 'DISABLED'}.",
            "agent": serializer.data,
        })


# =====================================================================
# 3. MANUFACTURING EVENT INGESTION & PIPELINE
# =====================================================================

class ManufacturingEventListCreateView(APIView):
    """
    Lists manufacturing events or submits a simulated event into the agent automation pipeline.
    """
    @extend_schema(
        summary="List Manufacturing Events",
        parameters=[
            OpenApiParameter("factory_id", str, required=False),
            OpenApiParameter("event_type", str, required=False),
            OpenApiParameter("severity", str, required=False),
            OpenApiParameter("status", str, required=False),
            OpenApiParameter("limit", int, required=False),
        ],
        responses={200: ManufacturingEventSerializer(many=True)},
    )
    def get(self, request):
        queryset = ManufacturingEvent.objects.all().select_related("factory").prefetch_related("decisions__agent")
        factory_id = request.query_params.get("factory_id")
        if factory_id:
            factory = get_object_or_404(Factory, id=factory_id)
            is_auth, err_msg, err_status = check_factory_authorization(request, factory)
            if not is_auth:
                return Response({"success": False, "error": err_msg}, status=err_status)
            queryset = queryset.filter(factory=factory)

        event_type = request.query_params.get("event_type")
        if event_type:
            queryset = queryset.filter(event_type=event_type)

        severity = request.query_params.get("severity")
        if severity:
            queryset = queryset.filter(severity=severity)

        status_val = request.query_params.get("status")
        if status_val:
            queryset = queryset.filter(status=status_val)

        limit = int(request.query_params.get("limit", 50))
        results = queryset[:limit]
        serializer = ManufacturingEventSerializer(results, many=True)
        return Response({"success": True, "count": len(results), "results": serializer.data})

    @extend_schema(
        summary="Submit / Simulate Manufacturing Event",
        description="Submits a manufacturing event into the agent evaluation and action pipeline.",
        request=ManufacturingEventSimulateSerializer,
        responses={201: ManufacturingEventSerializer},
    )
    @transaction.atomic
    def post(self, request):
        serializer = ManufacturingEventSimulateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"success": False, "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        vdata = serializer.validated_data
        factory = get_object_or_404(Factory, id=vdata["factory_id"])
        is_auth, err_msg, err_status = check_factory_authorization(request, factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        # Idempotency check if correlation_id given
        correlation_id = vdata.get("correlation_id", "")
        if correlation_id:
            existing = ManufacturingEvent.objects.filter(factory=factory, correlation_id=correlation_id).first()
            if existing:
                res_serializer = ManufacturingEventSerializer(existing)
                return Response({
                    "success": True,
                    "message": "Event already processed (idempotent replay).",
                    "event": res_serializer.data,
                }, status=status.HTTP_200_OK)

        # Create event
        event = ManufacturingEvent.objects.create(
            factory=factory,
            event_type=vdata["event_type"],
            source_type=vdata.get("source_type", "SIMULATION"),
            source_id=vdata.get("source_id", ""),
            severity=vdata.get("severity", "WARNING"),
            payload=vdata.get("payload", {}),
            correlation_id=correlation_id,
        )

        actor = request.user.username if getattr(request, "user", None) and request.user.is_authenticated else "Simulator"

        # Execute decision pipeline
        decisions = AgentDecisionService.process_event(event, actor=actor)

        # Reload event with related decisions
        event.refresh_from_db()
        res_serializer = ManufacturingEventSerializer(event)
        return Response({
            "success": True,
            "message": f"Event '{event.event_type}' processed by {len(decisions)} agent(s).",
            "event": res_serializer.data,
        }, status=status.HTTP_201_CREATED)


class ManufacturingEventDetailView(APIView):
    """
    Retrieves full details of a manufacturing event including all agent decisions and evidence.
    """
    @extend_schema(summary="Get Event Details", responses={200: ManufacturingEventSerializer})
    def get(self, request, event_id):
        event = get_object_or_404(
            ManufacturingEvent.objects.select_related("factory").prefetch_related("decisions__agent"),
            id=event_id,
        )
        is_auth, err_msg, err_status = check_factory_authorization(request, event.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        serializer = ManufacturingEventSerializer(event)
        return Response({"success": True, "event": serializer.data})


# =====================================================================
# 4. DECISIONS & RECOMMENDATIONS
# =====================================================================

class AgentDecisionListView(APIView):
    """
    Lists decisions produced by agents across manufacturing events.
    """
    @extend_schema(
        summary="List Agent Decisions",
        parameters=[
            OpenApiParameter("factory_id", str, required=False),
            OpenApiParameter("status", str, required=False),
            OpenApiParameter("agent_key", str, required=False),
            OpenApiParameter("limit", int, required=False),
        ],
        responses={200: AgentDecisionSerializer(many=True)},
    )
    def get(self, request):
        queryset = AgentDecision.objects.all().select_related("event__factory", "agent")

        factory_id = request.query_params.get("factory_id")
        if factory_id:
            factory = get_object_or_404(Factory, id=factory_id)
            is_auth, err_msg, err_status = check_factory_authorization(request, factory)
            if not is_auth:
                return Response({"success": False, "error": err_msg}, status=err_status)
            queryset = queryset.filter(event__factory=factory)

        status_val = request.query_params.get("status")
        if status_val:
            queryset = queryset.filter(status=status_val)

        agent_key = request.query_params.get("agent_key")
        if agent_key:
            queryset = queryset.filter(agent__key=agent_key)

        limit = int(request.query_params.get("limit", 50))
        results = queryset[:limit]
        serializer = AgentDecisionSerializer(results, many=True)
        return Response({"success": True, "count": len(results), "results": serializer.data})


# =====================================================================
# 5. HUMAN-IN-THE-LOOP APPROVAL INBOX
# =====================================================================

class ApprovalRequestListView(APIView):
    """
    Lists approval requests awaiting human operator sign-off.
    """
    @extend_schema(
        summary="List Approvals",
        parameters=[
            OpenApiParameter("factory_id", str, required=False),
            OpenApiParameter("status", str, description="Default: PENDING", required=False),
        ],
        responses={200: ApprovalRequestSerializer(many=True)},
    )
    def get(self, request):
        queryset = ApprovalRequest.objects.all().select_related("decision__agent", "decision__event", "factory", "action_execution")

        factory_id = request.query_params.get("factory_id")
        if factory_id:
            factory = get_object_or_404(Factory, id=factory_id)
            is_auth, err_msg, err_status = check_factory_authorization(request, factory)
            if not is_auth:
                return Response({"success": False, "error": err_msg}, status=err_status)
            queryset = queryset.filter(factory=factory)

        status_val = request.query_params.get("status", ApprovalStatus.PENDING)
        if status_val != "ALL":
            queryset = queryset.filter(status=status_val)

        serializer = ApprovalRequestSerializer(queryset, many=True)
        return Response({"success": True, "count": queryset.count(), "results": serializer.data})


class ApprovalRequestDecideView(APIView):
    """
    Approves or rejects a pending human-in-the-loop action request.
    """
    @extend_schema(
        summary="Approve or Reject Action",
        request=ApprovalReviewActionSerializer,
        responses={200: ApprovalRequestSerializer},
    )
    @transaction.atomic
    def post(self, request, approval_id):
        serializer = ApprovalReviewActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"success": False, "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        approval = get_object_or_404(ApprovalRequest, id=approval_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, approval.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        vdata = serializer.validated_data
        reviewer = vdata.get("reviewer") or (request.user.username if getattr(request, "user", None) and request.user.is_authenticated else "Plant Operator")

        success, updated_approval, message = AgentDecisionService.review_approval(
            approval_id=str(approval.id),
            action=vdata["action"],
            reviewer=reviewer,
            notes=vdata.get("notes", ""),
        )

        if not success:
            return Response({"success": False, "error": message}, status=status.HTTP_400_BAD_REQUEST)

        res_serializer = ApprovalRequestSerializer(updated_approval)
        return Response({"success": True, "message": message, "approval": res_serializer.data})


# =====================================================================
# 6. ACTION EXECUTION & RETRY
# =====================================================================

class ActionExecutionRetryView(APIView):
    """
    Retries execution of an eligible FAILED action request.
    """
    @extend_schema(summary="Retry Failed Action", responses={200: ActionExecutionSerializer})
    @transaction.atomic
    def post(self, request, execution_id):
        execution = get_object_or_404(ActionExecution, id=execution_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, execution.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        actor = request.user.username if getattr(request, "user", None) and request.user.is_authenticated else "Operator"
        success, updated_exec, msg = AgentDecisionService.retry_action(str(execution.id), actor=actor)

        if not success:
            return Response({"success": False, "error": msg}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ActionExecutionSerializer(updated_exec)
        return Response({"success": True, "message": msg, "action_execution": serializer.data})


# =====================================================================
# 7. AUTOMATION AUDIT TRAIL
# =====================================================================

class AutomationAuditListView(APIView):
    """
    Lists immutable audit log records capturing all automation decisions, approvals, and executions.
    """
    @extend_schema(
        summary="List Automation Audits",
        parameters=[
            OpenApiParameter("factory_id", str, required=False),
            OpenApiParameter("event_category", str, required=False),
            OpenApiParameter("limit", int, required=False),
        ],
        responses={200: AutomationAuditEventSerializer(many=True)},
    )
    def get(self, request):
        queryset = AutomationAuditEvent.objects.all().select_related("factory")
        factory_id = request.query_params.get("factory_id")
        if factory_id:
            factory = get_object_or_404(Factory, id=factory_id)
            is_auth, err_msg, err_status = check_factory_authorization(request, factory)
            if not is_auth:
                return Response({"success": False, "error": err_msg}, status=err_status)
            queryset = queryset.filter(factory=factory)

        category = request.query_params.get("event_category")
        if category:
            queryset = queryset.filter(event_category=category)

        limit = int(request.query_params.get("limit", 50))
        results = queryset[:limit]
        serializer = AutomationAuditEventSerializer(results, many=True)
        return Response({"success": True, "count": len(results), "results": serializer.data})


# =====================================================================
# 8. INDUSTRY PROFILES & PROVIDER STATUS
# =====================================================================

class IndustryProfileListView(APIView):
    """
    Returns all 8 versioned industry profiles with supported capabilities,
    permitted tools, constraints, and operational statuses.
    """
    @extend_schema(summary="List Manufacturing Industry Profiles")
    def get(self, request):
        profiles = IndustryProfileRegistry.list_all()
        data = [p.to_dict() for p in profiles]
        return Response({"success": True, "count": len(data), "results": data})


class ProviderStatusView(APIView):
    """
    Returns sanitized LLM & provider configuration status without exposing secrets.
    """
    @extend_schema(summary="Inspect AI Provider Configuration Status")
    def get(self, request):
        status_data = ProviderManager.get_provider_status()
        return Response({"success": True, "provider_status": status_data})


# =====================================================================
# 9. GOAL-DRIVEN AGENT RUNS
# =====================================================================

class AgentRunListCreateView(APIView):
    """
    Lists and initiates autonomous goal-driven manufacturing agent runs.
    """
    @extend_schema(
        summary="List Goal Runs",
        parameters=[
            OpenApiParameter("factory_id", str, required=True),
            OpenApiParameter("status", str, required=False),
        ],
        responses={200: AgentRunListSerializer(many=True)},
    )
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        if not factory_id:
            return Response({"success": False, "error": "factory_id query parameter is required."}, status=status.HTTP_400_BAD_REQUEST)

        factory = get_object_or_404(Factory, id=factory_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        queryset = AgentRun.objects.filter(factory=factory).order_by("-created_at")
        run_status = request.query_params.get("status")
        if run_status:
            queryset = queryset.filter(status=run_status)

        serializer = AgentRunListSerializer(queryset[:50], many=True)
        return Response({"success": True, "count": len(serializer.data), "results": serializer.data})

    @extend_schema(
        summary="Submit Manufacturing Goal",
        request=CreateAgentRunInputSerializer,
        responses={201: AgentRunDetailSerializer},
    )
    @transaction.atomic
    def post(self, request):
        input_serializer = CreateAgentRunInputSerializer(data=request.data)
        if not input_serializer.is_valid():
            return Response({"success": False, "error": input_serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        data = input_serializer.validated_data
        factory = get_object_or_404(Factory, id=data["factory_id"])
        is_auth, err_msg, err_status = check_factory_authorization(request, factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        try:
            run = GoalRuntimeService.create_goal_run(
                factory=factory,
                goal_text=data["goal_text"],
                user=request.user if getattr(request, "user", None) and request.user.is_authenticated else None,
                industry_profile_key=data.get("industry_profile_key", "GENERAL_DISCRETE"),
                provider_mode_override=data.get("provider_mode_override"),
            )
            serializer = AgentRunDetailSerializer(run)
            return Response({"success": True, "message": "Goal run initiated.", "run": serializer.data}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AgentRunDetailView(APIView):
    """
    Retrieves full detail of a goal run including plan, steps, observations, and tool calls.
    """
    @extend_schema(summary="Retrieve Goal Run Detail")
    def get(self, request, run_id):
        run = get_object_or_404(AgentRun.objects.prefetch_related("plans__steps", "observations", "tool_calls"), id=run_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, run.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        serializer = AgentRunDetailSerializer(run)
        return Response({"success": True, "run": serializer.data})


class AgentRunStepAdvanceView(APIView):
    """
    Advances execution of a goal run to execute the next pending step.
    """
    @extend_schema(summary="Advance Goal Run Step")
    def post(self, request, run_id):
        run = get_object_or_404(AgentRun, id=run_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, run.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        updated_run = GoalRuntimeService.advance_run(run)
        serializer = AgentRunDetailSerializer(updated_run)
        return Response({"success": True, "run": serializer.data})


class AgentRunApprovalView(APIView):
    """
    Approve or reject a consequential action paused for human-in-the-loop review.
    """
    @extend_schema(
        summary="Decide Consequential Action Approval",
        request=ApprovalReviewActionSerializer,
    )
    def post(self, request, run_id):
        run = get_object_or_404(AgentRun, id=run_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, run.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        serializer = ApprovalReviewActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"success": False, "error": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        approval_id = request.data.get("approval_id")
        if not approval_id:
            # Fall back to checking any pending approval linked to active plan
            active_plan = run.active_plan
            step = active_plan.steps.filter(status=AgentStepStatus.AWAITING_APPROVAL).first() if active_plan else None
            if step and step.approval_request_id:
                approval_id = str(step.approval_request_id)
            else:
                return Response({"success": False, "error": "approval_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        action = serializer.validated_data["action"]
        notes = serializer.validated_data.get("review_notes", "")

        success, msg = GoalRuntimeService.decide_approval(
            run_id=str(run.id),
            approval_id=approval_id,
            action=action,
            notes=notes,
            user=request.user,
        )

        if not success:
            return Response({"success": False, "error": msg}, status=status.HTTP_400_BAD_REQUEST)

        updated_run = AgentRun.objects.get(id=run.id)
        detail_serializer = AgentRunDetailSerializer(updated_run)
        return Response({"success": True, "message": msg, "run": detail_serializer.data})


class AgentRunClarificationView(APIView):
    """
    Submits operator answer to clarification question.
    """
    @extend_schema(summary="Submit Clarification Response")
    def post(self, request, run_id):
        run = get_object_or_404(AgentRun, id=run_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, run.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        answer = request.data.get("answer", "").strip()
        if not answer:
            return Response({"success": False, "error": "answer field is required."}, status=status.HTTP_400_BAD_REQUEST)

        success, msg = GoalRuntimeService.submit_clarification(
            run_id=str(run.id),
            answer=answer,
            user=request.user,
        )

        if not success:
            return Response({"success": False, "error": msg}, status=status.HTTP_400_BAD_REQUEST)

        updated_run = AgentRun.objects.get(id=run.id)
        detail_serializer = AgentRunDetailSerializer(updated_run)
        return Response({"success": True, "message": msg, "run": detail_serializer.data})


class AgentRunCancelView(APIView):
    """
    Cancels an in-progress goal run.
    """
    @extend_schema(summary="Cancel Goal Run")
    def post(self, request, run_id):
        run = get_object_or_404(AgentRun, id=run_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, run.factory)
        if not is_auth:
            return Response({"success": False, "error": err_msg}, status=err_status)

        success, msg = GoalRuntimeService.cancel_run(run_id=str(run.id), user=request.user)
        if not success:
            return Response({"success": False, "error": msg}, status=status.HTTP_400_BAD_REQUEST)

        updated_run = AgentRun.objects.get(id=run.id)
        detail_serializer = AgentRunDetailSerializer(updated_run)
        return Response({"success": True, "message": msg, "run": detail_serializer.data})

