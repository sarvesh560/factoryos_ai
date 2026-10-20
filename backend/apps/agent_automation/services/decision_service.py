"""
FactoryOS AI — Agent Decision & Event Orchestration Service
Phase 4: Multi-Agent Manufacturing Orchestration & Approvals

Coordinates:
- Ingested event processing
- Relevant agent selection and subscription matching
- Rule-based evaluation via AI provider abstraction
- Approval gating for high-risk actions
- Automated execution for pre-authorized actions
- Audit logging across all lifecycle transitions
"""
import uuid
import logging
from typing import List, Tuple
from django.db import transaction
from django.utils import timezone

from apps.agent_automation.models import (
    ManufacturingEvent,
    EventProcessingStatus,
    AgentConfiguration,
    AgentDecision,
    DecisionStatus,
    ApprovalRequest,
    ApprovalStatus,
    ActionExecution,
    ActionStatus,
    AutomationAuditEvent,
)
from apps.agent_automation.services.ai_provider import (
    BaseAgentAIProvider,
    DeterministicRuleAgentProvider,
)
from apps.agent_automation.services.action_registry import WorkflowActionRegistry
from apps.agent_automation.services.agent_seeder import seed_default_agents

logger = logging.getLogger(__name__)


class AgentDecisionService:
    """
    Core orchestration service for manufacturing event reasoning,
    human approval routing, and action dispatch.
    """

    @classmethod
    def get_provider(cls) -> BaseAgentAIProvider:
        """
        Returns the active AI decision provider.
        Defaults to the deterministic industrial rules provider.
        """
        return DeterministicRuleAgentProvider()

    @classmethod
    @transaction.atomic
    def process_event(cls, event: ManufacturingEvent, actor: str = "SYSTEM") -> List[AgentDecision]:
        """
        Evaluates a manufacturing event against all enabled, subscribed agents.
        Produces decisions, approval requests, and audit logs.
        """
        # Ensure default specialist agents exist
        if not AgentConfiguration.objects.exists():
            seed_default_agents()

        # Idempotency check: if event with correlation_id already has decisions, return them
        if event.correlation_id:
            existing_decisions = list(AgentDecision.objects.filter(event=event))
            if existing_decisions:
                logger.info(f"Event {event.id} already processed with correlation_id {event.correlation_id}.")
                return existing_decisions

        factory = event.factory
        event_type = event.event_type

        # Query enabled agents subscribed to this event type
        all_agents = AgentConfiguration.objects.filter(is_enabled=True)
        relevant_agents = [
            a for a in all_agents
            if (a.factory is None or a.factory_id == factory.id)
            and event_type in (a.supported_event_types or [])
        ]

        # Audit Event Ingested
        AutomationAuditEvent.objects.create(
            factory=factory,
            event_category="EVENT_INGESTED",
            reference_id=str(event.id),
            actor=actor,
            details={
                "event_type": event.event_type,
                "severity": event.severity,
                "source_type": event.source_type,
                "matching_agents": [a.key for a in relevant_agents],
            },
        )

        if not relevant_agents:
            event.status = EventProcessingStatus.IGNORED
            event.save(update_fields=["status", "updated_at"])
            logger.info(f"No enabled agent subscribed to event type '{event_type}'.")
            return []

        provider = cls.get_provider()
        created_decisions: List[AgentDecision] = []

        for agent in relevant_agents:
            # Evaluate using AI Provider abstraction
            eval_result = provider.evaluate(event, agent)

            # Create AgentDecision record
            decision = AgentDecision.objects.create(
                event=event,
                agent=agent,
                status=eval_result.status,
                findings=eval_result.findings,
                evidence=eval_result.evidence,
                proposed_action=eval_result.proposed_action,
                action_parameters=eval_result.action_parameters,
                rationale=eval_result.rationale,
                confidence_score=eval_result.confidence_score,
                provider_info=eval_result.provider_info,
            )

            # Audit Decision Produced
            AutomationAuditEvent.objects.create(
                factory=factory,
                event_category="DECISION_PRODUCED",
                reference_id=str(decision.id),
                actor=agent.name,
                details={
                    "agent_key": agent.key,
                    "status": decision.status,
                    "proposed_action": decision.proposed_action,
                    "confidence": decision.confidence_score,
                },
            )

            # If action proposed, determine approval or execution
            if eval_result.proposed_action:
                idempotency_key = f"{event.id}:{agent.key}:{eval_result.proposed_action}"

                if eval_result.status == DecisionStatus.AWAITING_APPROVAL:
                    # Create ApprovalRequest
                    approval_req = ApprovalRequest.objects.create(
                        decision=decision,
                        factory=factory,
                        status=ApprovalStatus.PENDING,
                        requested_action=eval_result.proposed_action,
                        action_summary=eval_result.findings,
                        action_parameters=eval_result.action_parameters,
                        urgency=event.severity,
                    )

                    # Create ActionExecution in PENDING_APPROVAL status
                    ActionExecution.objects.create(
                        decision=decision,
                        approval_request=approval_req,
                        factory=factory,
                        action_type=eval_result.proposed_action,
                        parameters=eval_result.action_parameters,
                        status=ActionStatus.PENDING_APPROVAL,
                        idempotency_key=idempotency_key,
                    )

                    AutomationAuditEvent.objects.create(
                        factory=factory,
                        event_category="APPROVAL_REQUESTED",
                        reference_id=str(approval_req.id),
                        actor=agent.name,
                        details={
                            "action_type": eval_result.proposed_action,
                            "urgency": event.severity,
                        },
                    )

                elif eval_result.status == DecisionStatus.ACTION_REQUESTED:
                    # Pre-approved action: execute immediately through action registry
                    execution = ActionExecution.objects.create(
                        decision=decision,
                        factory=factory,
                        action_type=eval_result.proposed_action,
                        parameters=eval_result.action_parameters,
                        status=ActionStatus.APPROVED,
                        idempotency_key=idempotency_key,
                    )
                    success, _, err_msg = WorkflowActionRegistry.execute_action(execution, actor=agent.name)
                    if success:
                        decision.status = DecisionStatus.COMPLETED
                    else:
                        decision.status = DecisionStatus.FAILED
                    decision.save(update_fields=["status", "updated_at"])

            created_decisions.append(decision)

        # Mark event PROCESSED
        event.status = EventProcessingStatus.PROCESSED
        event.save(update_fields=["status", "updated_at"])

        return created_decisions

    @classmethod
    @transaction.atomic
    def review_approval(
        cls,
        approval_id: str,
        action: str,
        reviewer: str = "Operator",
        notes: str = "",
    ) -> Tuple[bool, ApprovalRequest, str]:
        """
        Reviews a pending human approval request (APPROVE or REJECT).
        Executes approved actions through the registry atomically.
        """
        try:
            approval = ApprovalRequest.objects.select_for_update().get(id=approval_id)
        except ApprovalRequest.DoesNotExist:
            return False, None, "Approval request not found."

        if approval.status != ApprovalStatus.PENDING:
            return False, approval, f"Approval request is already in status '{approval.status}'."

        norm_action = action.strip().upper()
        if norm_action not in ["APPROVE", "REJECT"]:
            return False, approval, f"Invalid approval review action: '{action}'. Must be APPROVE or REJECT."

        decision = approval.decision
        execution = getattr(approval, "action_execution", None)

        if norm_action == "APPROVE":
            approval.status = ApprovalStatus.APPROVED
            approval.reviewed_by = reviewer
            approval.review_notes = notes
            approval.reviewed_at = timezone.now()
            approval.save(update_fields=["status", "reviewed_by", "review_notes", "reviewed_at", "updated_at"])

            AutomationAuditEvent.objects.create(
                factory=approval.factory,
                event_category="APPROVAL_DECIDED",
                reference_id=str(approval.id),
                actor=reviewer,
                details={"action": "APPROVED", "notes": notes},
            )

            # Revalidate permissions and execute action
            if execution:
                execution.status = ActionStatus.APPROVED
                execution.save(update_fields=["status", "updated_at"])
                success, result, msg = WorkflowActionRegistry.execute_action(execution, actor=reviewer)
                if success:
                    decision.status = DecisionStatus.COMPLETED
                else:
                    decision.status = DecisionStatus.FAILED
                decision.save(update_fields=["status", "updated_at"])
                return success, approval, msg

            decision.status = DecisionStatus.COMPLETED
            decision.save(update_fields=["status", "updated_at"])
            return True, approval, "Approval granted and action processed."

        else:
            # REJECT
            approval.status = ApprovalStatus.REJECTED
            approval.reviewed_by = reviewer
            approval.review_notes = notes
            approval.reviewed_at = timezone.now()
            approval.save(update_fields=["status", "reviewed_by", "review_notes", "reviewed_at", "updated_at"])

            if execution:
                execution.status = ActionStatus.REJECTED
                execution.save(update_fields=["status", "updated_at"])

            decision.status = DecisionStatus.REJECTED
            decision.save(update_fields=["status", "updated_at"])

            AutomationAuditEvent.objects.create(
                factory=approval.factory,
                event_category="APPROVAL_DECIDED",
                reference_id=str(approval.id),
                actor=reviewer,
                details={"action": "REJECTED", "notes": notes},
            )
            return True, approval, "Approval request rejected. Action will not execute."

    @classmethod
    @transaction.atomic
    def retry_action(cls, execution_id: str, actor: str = "Operator") -> Tuple[bool, ActionExecution, str]:
        """
        Safely retries a failed action execution.
        """
        try:
            execution = ActionExecution.objects.select_for_update().get(id=execution_id)
        except ActionExecution.DoesNotExist:
            return False, None, "Action execution not found."

        if execution.status != ActionStatus.FAILED:
            return False, execution, f"Only FAILED actions can be retried (current status: '{execution.status}')."

        success, result, msg = WorkflowActionRegistry.execute_action(execution, actor=actor)
        if execution.decision:
            execution.decision.status = DecisionStatus.COMPLETED if success else DecisionStatus.FAILED
            execution.decision.save(update_fields=["status", "updated_at"])

        return success, execution, msg
