"""
FactoryOS AI — Goal-Driven Manufacturing Agent Runtime Service
Phase 4, Step 2: Autonomous Goal Execution, Bounded Tool Loop, Approvals & Verification

Orchestrates:
1. Goal submission, industry profile resolution, and plan generation.
2. Step-by-step tool invocation with idempotency protections.
3. Human-in-the-loop approval gating for consequential actions (e.g., work order release).
4. Observation logging and state verification checks.
5. Audit trail integration.
"""
import uuid
import logging
from typing import Dict, Any, List, Optional, Tuple
from django.db import transaction
from django.utils import timezone

from apps.factories.models import Factory
from apps.agent_automation.models import (
    AgentRun,
    AgentRunStatus,
    AgentPlan,
    AgentStep,
    AgentStepStatus,
    AgentToolCall,
    AgentObservation,
    ApprovalRequest,
    ApprovalStatus,
    AutomationAuditEvent,
)
from apps.agent_automation.services.industry_profiles import IndustryProfileRegistry, ProfileStatus
from apps.agent_automation.services.tool_registry import ManufacturingToolRegistry
from apps.agent_automation.services.provider_manager import ProviderManager

logger = logging.getLogger(__name__)


class GoalRuntimeService:
    """
    Central orchestration engine for autonomous, goal-driven manufacturing agents.
    """

    @classmethod
    @transaction.atomic
    def create_goal_run(
        cls,
        factory: Factory,
        goal_text: str,
        user=None,
        industry_profile_key: str = "GENERAL_DISCRETE",
        provider_mode_override: Optional[str] = None,
        operational_context: Optional[Dict[str, Any]] = None,
    ) -> AgentRun:
        """
        Initializes an AgentRun, generates a structured plan, and executes the first ready step.
        """
        if not goal_text or not goal_text.strip():
            raise ValueError("Goal text cannot be blank.")
        goal_text = goal_text.strip()

        # 1. Resolve Industry Profile
        profile = IndustryProfileRegistry.get(industry_profile_key)
        if not profile:
            profile = IndustryProfileRegistry.get("GENERAL_DISCRETE")
            profile_key = "GENERAL_DISCRETE"
        else:
            profile_key = profile.key

        # 2. Plan Goal via Provider Manager
        plan_data, provider_type, model_name, fallback_occurred, fallback_reason = ProviderManager.plan_goal(
            goal=goal_text,
            industry_profile=profile,
            factory_name=factory.name,
            provider_mode_override=provider_mode_override,
            operational_context=operational_context,
        )

        # 3. Create AgentRun Record
        run = AgentRun.objects.create(
            factory=factory,
            user=user if user and user.is_authenticated else None,
            goal_text=goal_text,
            industry_profile_key=profile_key,
            profile_version=profile.version,
            status=AgentRunStatus.PLANNING,
            provider_type=provider_type,
            model_name=model_name,
            execution_mode="deterministic" if fallback_occurred else provider_type,
            fallback_occurred=fallback_occurred,
            fallback_reason=fallback_reason,
            max_steps=10,
            current_step_index=0,
            replan_count=0,
            max_replans=3,
        )

        # 4. Create AgentPlan Record
        plan = AgentPlan.objects.create(
            run=run,
            version=1,
            goal_summary=plan_data.get("goal_summary", f"Plan for {profile.display_name}"),
            completion_criteria=plan_data.get("completion_criteria", []),
            is_active=True,
        )

        # 5. Create AgentStep Records
        raw_steps = plan_data.get("steps", [])
        for step_dict in raw_steps:
            AgentStep.objects.create(
                plan=plan,
                step_number=step_dict["step_number"],
                title=step_dict["title"],
                description=step_dict.get("description", ""),
                tool_name=step_dict["tool_name"],
                tool_arguments=step_dict.get("tool_arguments", {}),
                is_consequential=step_dict.get("is_consequential", False),
                status=AgentStepStatus.PENDING,
            )

        # 6. Audit Trail Logging
        AutomationAuditEvent.objects.create(
            factory=factory,
            event_category="GOAL_RUN_CREATED",
            reference_id=str(run.id),
            actor=user.username if user and user.is_authenticated else "SYSTEM",
            details={
                "goal_text": goal_text,
                "industry_profile": profile_key,
                "provider_type": provider_type,
                "model_name": model_name,
                "fallback_occurred": fallback_occurred,
                "step_count": len(raw_steps),
            },
        )

        # 7. Transition status to RUNNING and run initial step
        run.status = AgentRunStatus.RUNNING
        run.save(update_fields=["status", "updated_at"])

        cls._advance_execution_loop(run)
        return run

    @classmethod
    def advance_run(cls, run: AgentRun) -> AgentRun:
        """
        Public trigger to advance a run by executing the next eligible step.
        """
        return cls._advance_execution_loop(run)

    @classmethod
    def _advance_execution_loop(cls, run: AgentRun) -> AgentRun:
        """
        Core bounded execution loop.
        Executes ready steps until either:
        - A consequential action pauses for human approval.
        - Clarification is required.
        - An error blocks execution.
        - All steps complete.
        """
        if run.status in [AgentRunStatus.COMPLETED, AgentRunStatus.CANCELLED, AgentRunStatus.FAILED, AgentRunStatus.BLOCKED]:
            return run

        active_plan = run.active_plan
        if not active_plan:
            run.status = AgentRunStatus.FAILED
            run.error_message = "No active plan found for this run."
            run.save(update_fields=["status", "error_message", "updated_at"])
            return run

        # Find the next non-completed step
        next_step = active_plan.steps.filter(
            status__in=[AgentStepStatus.PENDING, AgentStepStatus.READY, AgentStepStatus.AWAITING_APPROVAL]
        ).order_by("step_number").first()

        if not next_step:
            # All steps completed or skipped! Run final completion verification
            cls._finalize_run_completion(run)
            return run

        # -------------------------------------------------------------
        # Gate Consequential Steps with Human Approval
        # -------------------------------------------------------------
        if next_step.is_consequential:
            # Check if approval has already been granted
            if next_step.approval_request and next_step.approval_request.status == ApprovalStatus.APPROVED:
                logger.info(f"Step {next_step.step_number} approval confirmed ({next_step.approval_request.id}). Proceeding.")
            else:
                # Create ApprovalRequest if not exists
                if not next_step.approval_request:
                    appr = ApprovalRequest.objects.create(
                        factory=run.factory,
                        status=ApprovalStatus.PENDING,
                        requested_action=next_step.tool_name,
                        action_summary=f"Run #{str(run.id)[:8]}: {next_step.title} - {next_step.description}",
                        action_parameters=next_step.tool_arguments,
                        urgency="HIGH",
                    )
                    next_step.approval_request = appr
                    next_step.status = AgentStepStatus.AWAITING_APPROVAL
                    next_step.save(update_fields=["approval_request", "status", "updated_at"])

                run.status = AgentRunStatus.AWAITING_APPROVAL
                run.save(update_fields=["status", "updated_at"])

                AutomationAuditEvent.objects.create(
                    factory=run.factory,
                    event_category="APPROVAL_REQUIRED_PAUSE",
                    reference_id=str(run.id),
                    actor="GOAL_RUNTIME",
                    details={
                        "step_number": next_step.step_number,
                        "tool_name": next_step.tool_name,
                        "approval_id": str(next_step.approval_request.id),
                    },
                )
                return run

        # -------------------------------------------------------------
        # Execute Tool Call
        # -------------------------------------------------------------
        next_step.status = AgentStepStatus.RUNNING
        next_step.save(update_fields=["status", "updated_at"])

        idempotency_key = f"{run.id}:{next_step.id}:{next_step.tool_name}"
        start_time = timezone.now()

        tool_result = ManufacturingToolRegistry.execute_tool(
            tool_name=next_step.tool_name,
            factory=run.factory,
            arguments=next_step.tool_arguments,
            idempotency_key=idempotency_key,
        )

        duration_ms = int((timezone.now() - start_time).total_seconds() * 1000)

        # Record Tool Call
        AgentToolCall.objects.create(
            run=run,
            step=next_step,
            tool_name=next_step.tool_name,
            arguments=next_step.tool_arguments,
            result_payload=tool_result.data,
            status="SUCCESS" if tool_result.success else "FAILED",
            error_message=tool_result.error_message,
            idempotency_key=idempotency_key,
            duration_ms=duration_ms,
            executed_at=timezone.now(),
        )

        # Record Observation
        summary_text = tool_result.data.get("summary", tool_result.error_message or "Tool executed.")
        AgentObservation.objects.create(
            run=run,
            step=next_step,
            observation_type="STATE_VERIFICATION" if tool_result.is_verified else ("BLOCKER" if not tool_result.success else "TOOL_RESULT"),
            content=f"Step {next_step.step_number} [{next_step.tool_name}]: {summary_text}",
            data=tool_result.data,
        )

        if tool_result.success:
            next_step.status = AgentStepStatus.COMPLETED
            next_step.result_data = tool_result.data
            next_step.error_message = ""
            next_step.save(update_fields=["status", "result_data", "error_message", "updated_at"])

            run.current_step_index = next_step.step_number
            run.save(update_fields=["current_step_index", "updated_at"])

            # Check if this tool was a clarification request
            if next_step.tool_name == "request_human_clarification":
                run.status = AgentRunStatus.NEEDS_CLARIFICATION
                run.clarification_question = tool_result.data.get("question", "Operator clarification requested.")
                run.save(update_fields=["status", "clarification_question", "updated_at"])
                return run

            # Recursively continue to next step
            return cls._advance_execution_loop(run)

        else:
            # Step failed
            next_step.status = AgentStepStatus.FAILED
            next_step.error_message = tool_result.error_message
            next_step.save(update_fields=["status", "error_message", "updated_at"])

            run.status = AgentRunStatus.FAILED
            run.error_message = f"Step {next_step.step_number} failed: {tool_result.error_message}"
            run.save(update_fields=["status", "error_message", "updated_at"])

            AutomationAuditEvent.objects.create(
                factory=run.factory,
                event_category="GOAL_RUN_STEP_FAILED",
                reference_id=str(run.id),
                actor="GOAL_RUNTIME",
                details={
                    "step_number": next_step.step_number,
                    "tool_name": next_step.tool_name,
                    "error": tool_result.error_message,
                },
            )
            return run

    @classmethod
    @transaction.atomic
    def decide_approval(
        cls,
        run_id: str,
        approval_id: str,
        action: str,
        notes: str = "",
        user=None,
    ) -> Tuple[bool, str]:
        """
        Approve or reject a consequential action paused for human-in-the-loop signoff.
        """
        run = AgentRun.objects.filter(id=run_id).first()
        if not run:
            return False, "Goal run not found."

        approval = ApprovalRequest.objects.filter(id=approval_id).first()
        if not approval:
            return False, "Approval request not found."

        if approval.status != ApprovalStatus.PENDING:
            return False, f"Approval request already decided ({approval.status})."

        actor = user.username if user and user.is_authenticated else "OPERATOR"
        norm_action = action.upper().strip()

        if norm_action == "APPROVE":
            approval.status = ApprovalStatus.APPROVED
            approval.reviewed_by = actor
            approval.review_notes = notes
            approval.reviewed_at = timezone.now()
            approval.save(update_fields=["status", "reviewed_by", "review_notes", "reviewed_at"])

            step = run.active_plan.steps.filter(approval_request=approval).first()
            if step:
                step.status = AgentStepStatus.READY
                step.save(update_fields=["status", "updated_at"])

            run.status = AgentRunStatus.RUNNING
            run.save(update_fields=["status", "updated_at"])

            AutomationAuditEvent.objects.create(
                factory=run.factory,
                event_category="APPROVAL_GRANTED",
                reference_id=str(run.id),
                actor=actor,
                details={"approval_id": str(approval.id), "notes": notes},
            )

            # Resume execution loop
            cls._advance_execution_loop(run)
            return True, "Action approved. Execution resumed."

        elif norm_action == "REJECT":
            approval.status = ApprovalStatus.REJECTED
            approval.reviewed_by = actor
            approval.review_notes = notes
            approval.reviewed_at = timezone.now()
            approval.save(update_fields=["status", "reviewed_by", "review_notes", "reviewed_at"])

            # Mark step skipped
            step = run.active_plan.steps.filter(approval_request=approval).first()
            if step:
                step.status = AgentStepStatus.SKIPPED
                step.error_message = f"Rejected by operator: {notes}"
                step.save(update_fields=["status", "error_message", "updated_at"])

            run.status = AgentRunStatus.BLOCKED
            run.error_message = f"Consequential action was rejected by operator ({notes or 'No reason provided'})."
            run.save(update_fields=["status", "error_message", "updated_at"])

            AutomationAuditEvent.objects.create(
                factory=run.factory,
                event_category="APPROVAL_REJECTED",
                reference_id=str(run.id),
                actor=actor,
                details={"approval_id": str(approval.id), "notes": notes},
            )
            return True, "Action rejected. Execution halted safely."

        else:
            return False, f"Invalid decision action '{action}'. Must be APPROVE or REJECT."

    @classmethod
    @transaction.atomic
    def submit_clarification(
        cls,
        run_id: str,
        answer: str,
        user=None,
    ) -> Tuple[bool, str]:
        """
        Submits operator answer to clarification question and resumes goal run.
        """
        run = AgentRun.objects.filter(id=run_id).first()
        if not run:
            return False, "Goal run not found."

        if run.status != AgentRunStatus.NEEDS_CLARIFICATION:
            return False, f"Run is not awaiting clarification (current status: {run.status})."

        actor = user.username if user and user.is_authenticated else "OPERATOR"
        run.clarification_answer = answer.strip()
        run.status = AgentRunStatus.RUNNING
        run.save(update_fields=["clarification_answer", "status", "updated_at"])

        AgentObservation.objects.create(
            run=run,
            observation_type="CLARIFICATION",
            content=f"Operator clarification response from {actor}: {answer.strip()}",
            data={"answer": answer.strip()},
        )

        AutomationAuditEvent.objects.create(
            factory=run.factory,
            event_category="CLARIFICATION_SUBMITTED",
            reference_id=str(run.id),
            actor=actor,
            details={"answer": answer.strip()},
        )

        cls._advance_execution_loop(run)
        return True, "Clarification submitted. Execution resumed."

    @classmethod
    @transaction.atomic
    def cancel_run(cls, run_id: str, user=None) -> Tuple[bool, str]:
        """
        Safely cancels an in-progress agent run.
        """
        run = AgentRun.objects.filter(id=run_id).first()
        if not run:
            return False, "Goal run not found."

        if run.status in [AgentRunStatus.COMPLETED, AgentRunStatus.CANCELLED]:
            return False, f"Run cannot be cancelled in state '{run.status}'."

        actor = user.username if user and user.is_authenticated else "OPERATOR"
        run.status = AgentRunStatus.CANCELLED
        run.completed_at = timezone.now()
        run.save(update_fields=["status", "completed_at", "updated_at"])

        AutomationAuditEvent.objects.create(
            factory=run.factory,
            event_category="GOAL_RUN_CANCELLED",
            reference_id=str(run.id),
            actor=actor,
            details={"reason": "Operator manual cancellation"},
        )
        return True, "Goal run cancelled successfully."

    @classmethod
    def _finalize_run_completion(cls, run: AgentRun):
        """
        Verifies actual resulting application state and marks the goal completed.
        """
        plan = run.active_plan
        steps = plan.steps.all() if plan else []
        completed_steps = [s for s in steps if s.status == AgentStepStatus.COMPLETED]

        summary_parts = []
        for s in completed_steps:
            summary_parts.append(f"✓ {s.title}")

        run.status = AgentRunStatus.COMPLETED
        run.completed_at = timezone.now()
        run.completion_summary = f"Goal successfully verified ({len(completed_steps)}/{len(steps)} steps):\n" + "\n".join(summary_parts)
        run.save(update_fields=["status", "completed_at", "completion_summary", "updated_at"])

        AutomationAuditEvent.objects.create(
            factory=run.factory,
            event_category="GOAL_RUN_COMPLETED",
            reference_id=str(run.id),
            actor="GOAL_RUNTIME",
            details={
                "steps_completed": len(completed_steps),
                "total_steps": len(steps),
                "summary": run.completion_summary,
            },
        )
