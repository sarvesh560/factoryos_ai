"""
FactoryOS AI — Phase 4 Step 1: Agent Automation Engine Tests
Tests:
- Specialist agent seeding and configuration listing/toggling
- Event ingestion and simulation pipeline
- Deterministic rule reasoning and decision production
- Human-in-the-loop approval workflow (approve vs reject)
- Workflow action registry execution and idempotency
- Multi-tenant boundary isolation and security
- Audit logging across all automation transitions
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from apps.factories.models import Organization, Factory, ProductionLine, Machine, RawMaterial
from apps.processes.models import WorkOrder, ProcessDefinition, ProcessVersion
from apps.agent_automation.models import (
    ManufacturingEvent,
    AgentConfiguration,
    AgentDecision,
    ApprovalRequest,
    ActionExecution,
    AutomationAuditEvent,
    ManufacturingEventType,
    EventSeverity,
    DecisionStatus,
    ApprovalStatus,
    ActionStatus,
    ActionType,
)
from apps.agent_automation.services.agent_seeder import seed_default_agents
from apps.agent_automation.services.decision_service import AgentDecisionService


class AgentAutomationEngineTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Organization 1
        self.org1 = Organization.objects.create(
            name="Apex Precision Enterprise",
            slug="apex-precision",
            is_active=True,
        )
        self.factory1 = Factory.objects.create(
            organization=self.org1,
            name="Apex Precision Plant 1",
            code="FAC-APX-01",
            is_active=True,
        )
        self.line1 = ProductionLine.objects.create(
            factory=self.factory1,
            name="Machining Cell 1",
            code="LINE-MC-01",
        )
        self.machine1 = Machine.objects.create(
            production_line=self.line1,
            name="5-Axis Haas VF2",
            code="M-VF2-01",
            status="RUNNING",
        )
        self.raw_mat1 = RawMaterial.objects.create(
            factory=self.factory1,
            name="Aerospace Titanium Ingot",
            code="RAW-TI-01",
            unit_of_measure="kg",
            safety_stock=500.0,
            current_stock=40.0,
        )

        # Organization 2 (Tenant isolation testing)
        self.org2 = Organization.objects.create(
            name="Rival Systems",
            slug="rival-systems",
            is_active=True,
        )
        self.factory2 = Factory.objects.create(
            organization=self.org2,
            name="Rival Manufacturing",
            code="FAC-RIV-02",
            is_active=True,
        )

        # Seed agents
        seed_default_agents()

    def test_default_agents_seeded_idempotently(self):
        """Verifies all 5 specialist agents are created and seeding twice causes no duplicates."""
        agents = AgentConfiguration.objects.all()
        self.assertEqual(agents.count(), 5)

        keys = set(AgentConfiguration.objects.values_list("key", flat=True))
        expected_keys = {
            "production_agent",
            "maintenance_agent",
            "quality_agent",
            "inventory_agent",
            "energy_agent",
        }
        self.assertEqual(keys, expected_keys)

        # Seed again
        seed_default_agents()
        self.assertEqual(AgentConfiguration.objects.count(), 5)

    def test_list_agents_api(self):
        """Tests GET /api/automation/agents/ returns all specialist agents."""
        response = self.client.get("/api/automation/agents/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["success"])
        self.assertEqual(response.data["count"], 5)

    def test_toggle_agent_state(self):
        """Tests enabling/disabling an agent via POST /api/automation/agents/<key>/toggle/."""
        agent = AgentConfiguration.objects.get(key="maintenance_agent")
        self.assertTrue(agent.is_enabled)

        # Disable
        res = self.client.post(
            f"/api/automation/agents/{agent.key}/toggle/",
            {"is_enabled": False},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        agent.refresh_from_db()
        self.assertFalse(agent.is_enabled)

        # Re-enable
        res2 = self.client.post(
            f"/api/automation/agents/{agent.key}/toggle/",
            {"is_enabled": True},
            format="json",
        )
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        agent.refresh_from_db()
        self.assertTrue(agent.is_enabled)

    def test_machine_anomaly_event_generates_approval_and_maintenance_ticket(self):
        """
        End-to-End Test:
        1. Ingest simulated machine anomaly event.
        2. Maintenance agent evaluates telemetry and breaches thermal/vibration threshold.
        3. Proposes CREATE_MAINTENANCE_TICKET in AWAITING_APPROVAL status.
        4. Human approves the request.
        5. Action executes, updates machine status to MAINTENANCE, and generates ticket code.
        """
        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.MACHINE_ANOMALY,
            "severity": EventSeverity.CRITICAL,
            "source_type": "SIMULATION",
            "source_id": str(self.machine1.id),
            "payload": {
                "machine_id": str(self.machine1.id),
                "machine_name": self.machine1.name,
                "temperature_c": 92.5,
                "vibration_rms": 8.1,
                "anomaly_type": "High Spindle Vibration & Overheating",
            },
            "correlation_id": "TEST-EVT-ANOMALY-001",
        }

        # 1. Ingest Event via API
        response = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data["success"])

        event_data = response.data["event"]
        self.assertEqual(event_data["status"], "PROCESSED")
        self.assertEqual(len(event_data["decisions"]), 2)  # Maintenance Agent + Energy Agent

        # Check maintenance agent decision
        maint_decision = next(d for d in event_data["decisions"] if d["agent_key"] == "maintenance_agent")
        self.assertEqual(maint_decision["status"], DecisionStatus.AWAITING_APPROVAL)
        self.assertEqual(maint_decision["proposed_action"], ActionType.CREATE_MAINTENANCE_TICKET)

        # 2. Verify Approval Request created
        approvals = ApprovalRequest.objects.filter(factory=self.factory1, status=ApprovalStatus.PENDING)
        self.assertEqual(approvals.count(), 1)
        approval = approvals.first()
        self.assertEqual(approval.requested_action, ActionType.CREATE_MAINTENANCE_TICKET)

        # 3. Verify ActionExecution created in PENDING_APPROVAL
        execution = ActionExecution.objects.get(approval_request=approval)
        self.assertEqual(execution.status, ActionStatus.PENDING_APPROVAL)
        self.assertEqual(self.machine1.status, "RUNNING")  # Not yet executed!

        # 4. Human Approves Action
        decide_res = self.client.post(
            f"/api/automation/approvals/{approval.id}/decide/",
            {"action": "APPROVE", "notes": "Approved for emergency cell inspection", "reviewer": "Lead Technician"},
            format="json",
        )
        self.assertEqual(decide_res.status_code, status.HTTP_200_OK)
        self.assertTrue(decide_res.data["success"])

        # 5. Verify Execution and Machine Status
        approval.refresh_from_db()
        self.assertEqual(approval.status, ApprovalStatus.APPROVED)
        self.assertEqual(approval.reviewed_by, "Lead Technician")

        execution.refresh_from_db()
        self.assertEqual(execution.status, ActionStatus.COMPLETED)
        self.assertTrue(execution.result_payload["reference_code"].startswith("MNT-"))

        self.machine1.refresh_from_db()
        self.assertEqual(self.machine1.status, "MAINTENANCE")

        # 6. Verify Audit Trail
        audits = AutomationAuditEvent.objects.filter(factory=self.factory1)
        categories = set(audits.values_list("event_category", flat=True))
        self.assertIn("EVENT_INGESTED", categories)
        self.assertIn("DECISION_PRODUCED", categories)
        self.assertIn("APPROVAL_REQUESTED", categories)
        self.assertIn("APPROVAL_DECIDED", categories)
        self.assertIn("ACTION_EXECUTED", categories)

    def test_rejection_prevents_action_execution(self):
        """Verifies that rejecting an approval request sets REJECTED and executes no action."""
        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.MACHINE_ANOMALY,
            "severity": EventSeverity.CRITICAL,
            "payload": {
                "machine_id": str(self.machine1.id),
                "machine_name": self.machine1.name,
                "temperature_c": 95.0,
                "vibration_rms": 7.8,
            },
        }
        res = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        approval = ApprovalRequest.objects.filter(factory=self.factory1, status=ApprovalStatus.PENDING).first()
        self.assertIsNotNone(approval)

        # Reject
        decide_res = self.client.post(
            f"/api/automation/approvals/{approval.id}/decide/",
            {"action": "REJECT", "notes": "Sensor false positive during calibration"},
            format="json",
        )
        self.assertEqual(decide_res.status_code, status.HTTP_200_OK)

        approval.refresh_from_db()
        self.assertEqual(approval.status, ApprovalStatus.REJECTED)

        execution = ActionExecution.objects.get(approval_request=approval)
        self.assertEqual(execution.status, ActionStatus.REJECTED)
        self.assertEqual(self.machine1.status, "RUNNING")  # Still RUNNING!

    def test_inventory_shortage_replenishment_workflow(self):
        """Tests inventory agent proposing replenishment on raw material deficit."""
        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.INVENTORY_SHORTAGE,
            "severity": EventSeverity.WARNING,
            "payload": {
                "material_id": str(self.raw_mat1.id),
                "material_name": self.raw_mat1.name,
                "current_stock": 40.0,
                "safety_stock": 500.0,
                "unit_of_measure": "kg",
            },
        }
        res = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        approval = ApprovalRequest.objects.filter(factory=self.factory1, status=ApprovalStatus.PENDING).first()
        self.assertEqual(approval.requested_action, ActionType.CREATE_INVENTORY_REPLENISHMENT_REQUEST)

        # Approve replenishment
        self.client.post(f"/api/automation/approvals/{approval.id}/decide/", {"action": "APPROVE"}, format="json")
        approval.refresh_from_db()
        self.assertEqual(approval.status, ApprovalStatus.APPROVED)
        self.assertTrue(approval.action_execution.result_payload["reference_code"].startswith("REQ-MAT-"))

    def test_production_delay_investigation_workflow(self):
        """Tests production agent proposing investigation on throughput pacing variance."""
        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.PRODUCTION_DELAY,
            "severity": EventSeverity.ERROR,
            "payload": {
                "line_id": str(self.line1.id),
                "line_name": self.line1.name,
                "cycle_variance_pct": 34.0,
                "stage_name": "Precision CNC Contouring",
            },
        }
        res = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        approval = ApprovalRequest.objects.filter(factory=self.factory1, status=ApprovalStatus.PENDING).first()
        self.assertEqual(approval.requested_action, ActionType.CREATE_PRODUCTION_INVESTIGATION)

    def test_disabled_agent_produces_no_actions(self):
        """Verifies that an agent configured with is_enabled=False is ignored."""
        AgentConfiguration.objects.filter(key="maintenance_agent").update(is_enabled=False)

        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.MACHINE_ANOMALY,
            "severity": EventSeverity.CRITICAL,
            "payload": {"temperature_c": 110.0, "vibration_rms": 12.0},
        }
        res = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # Energy agent may still evaluate, but maintenance agent should not have run
        decisions = res.data["event"]["decisions"]
        agent_keys = [d["agent_key"] for d in decisions]
        self.assertNotIn("maintenance_agent", agent_keys)
        self.assertEqual(ApprovalRequest.objects.filter(factory=self.factory1).count(), 0)

    def test_idempotent_event_ingestion(self):
        """Verifies submitting an event with an identical correlation_id does not re-process or duplicate records."""
        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.MACHINE_ANOMALY,
            "severity": EventSeverity.CRITICAL,
            "payload": {"temperature_c": 99.0, "vibration_rms": 9.0},
            "correlation_id": "CORR-UNIQUE-IDEMPOTENT-001",
        }
        res1 = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)

        initial_event_count = ManufacturingEvent.objects.count()
        initial_decision_count = AgentDecision.objects.count()

        # Resubmit with same correlation_id
        res2 = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res2.status_code, status.HTTP_200_OK)

        self.assertEqual(ManufacturingEvent.objects.count(), initial_event_count)
        self.assertEqual(AgentDecision.objects.count(), initial_decision_count)

    def test_cross_tenant_isolation(self):
        """Verifies users cannot access or approve events from an unauthorized organization context."""
        payload = {
            "factory_id": str(self.factory1.id),
            "event_type": ManufacturingEventType.MACHINE_ANOMALY,
            "payload": {"temperature_c": 95.0},
        }
        res = self.client.post("/api/automation/events/simulate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        approval = ApprovalRequest.objects.filter(factory=self.factory1).first()

        # Attempt to access using foreign organization header (Org2)
        decide_res = self.client.post(
            f"/api/automation/approvals/{approval.id}/decide/",
            {"action": "APPROVE"},
            format="json",
            HTTP_X_ORGANIZATION_ID=str(self.org2.id),
        )
        self.assertEqual(decide_res.status_code, status.HTTP_403_FORBIDDEN)

    def test_automation_summary_api(self):
        """Tests GET /api/automation/summary/ returns correct aggregate metrics."""
        res = self.client.get(f"/api/automation/summary/?factory_id={self.factory1.id}")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.data["data"]
        self.assertEqual(data["total_agents"], 5)
        self.assertEqual(data["enabled_agents"], 5)
        self.assertIn("total_events_processed", data)
        self.assertIn("pending_approvals", data)
