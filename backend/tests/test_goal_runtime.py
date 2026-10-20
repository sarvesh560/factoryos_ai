"""
FactoryOS AI — Goal-Driven Manufacturing Agent Runtime & LLM Integration Tests
Phase 4, Step 2: Goal Planning, Typed Tools, Approvals, Industry Profiles, and Tenancy

Verifies:
- 8 Industry Profiles with honest operational/preview statuses
- Sanitized AI provider status introspection (zero secret leakage)
- Deterministic heuristic goal planner
- Mocked OpenAI-compatible LLM provider with structured plan validation
- Hybrid mode deterministic fallback when no API key is configured
- Real domain tool execution (RawMaterial, ProcessDefinition, ProcessGraphValidator, WorkOrder)
- Human-in-the-loop approval pause before consequential work order creation
- State verification on work order creation
- Approval rejection safety halting execution
- Tenant isolation across factories (403 Forbidden)
"""
import uuid
import json
from unittest.mock import patch, MagicMock
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.factories.models import Organization, Factory, IndustryType, RawMaterial, Product
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    ProcessNode,
    ProcessEdge,
    WorkOrder,
)
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
from apps.agent_automation.services.llm_provider import OpenAICompatibleAgentProvider, LLMProviderError
from apps.agent_automation.services.provider_manager import ProviderManager, DeterministicGoalPlanner
from apps.agent_automation.services.goal_runtime import GoalRuntimeService

User = get_user_model()


class GoalRuntimeAndLLMTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Organizations & Factories
        self.org1 = Organization.objects.create(name="Apex Advanced Systems", slug="apex-corp")
        self.factory1 = Factory.objects.create(
            organization=self.org1,
            name="Apex Precision Plant 1",
            code="FAC-APX-01",
            industry_type=IndustryType.CNC_ENGINEERING,
            configuration_status="CONFIGURED",
            total_production_lines=4,
            active_lines=4,
            location="Detroit, MI",
            country="USA",
            timezone="America/Detroit",
        )

        self.org2 = Organization.objects.create(name="Nexus Global Corp", slug="nexus-corp")
        self.factory2 = Factory.objects.create(
            organization=self.org2,
            name="Nexus Aerospace Facility",
            code="FAC-NEX-01",
            industry_type=IndustryType.AEROSPACE,
            configuration_status="CONFIGURED",
            total_production_lines=2,
            active_lines=2,
            location="Seattle, WA",
            country="USA",
            timezone="America/Los_Angeles",
        )

        # Users
        self.user1 = User.objects.create_user(username="sarvesh", password="password123")
        self.user2 = User.objects.create_user(username="external_operator", password="password123")

        # Associate user1 with factory1
        self.factory1.metadata["authorized_users"] = [self.user1.username]
        self.factory1.save()

        # Seed Domain Data in Factory 1: RawMaterial, Product, ProcessDefinition
        self.material = RawMaterial.objects.create(
            factory=self.factory1,
            name="Aerospace Titanium Billet Ti-6Al-4V",
            code="MAT-TI-01",
            category="Alloy Billets",
            unit_of_measure="kg",
            safety_stock=50.0,
            current_stock=250.0,
        )

        self.product = Product.objects.create(
            factory=self.factory1,
            name="High-Pressure Turbine Impeller",
            sku="SKU-IMP-900",
            unit_of_measure="pcs",
            target_hourly_rate=20,
        )

        # Process Definition & Version
        self.process_def = ProcessDefinition.objects.create(
            factory=self.factory1,
            name="5-Axis Impeller Machining Process",
            code="PRC-IMP-5AX",
            category="Precision Machining",
            industry_type=IndustryType.CNC_ENGINEERING,
            target_cycle_time_seconds=120.0,
            is_active=True,
        )
        self.version = ProcessVersion.objects.create(
            process_definition=self.process_def,
            version_number=1,
            version_tag="v1.0.0",
            status="PUBLISHED",
            is_published=True,
        )
        self.start_node = ProcessNode.objects.create(
            process_version=self.version,
            node_key="START-01",
            name="Billet Ingest",
            node_type="START",
            position_x=100.0,
            position_y=100.0,
        )
        self.op_node = ProcessNode.objects.create(
            process_version=self.version,
            node_key="OP-MILL-01",
            name="5-Axis Profiling",
            node_type="OPERATION",
            position_x=300.0,
            position_y=100.0,
            cycle_time_seconds=120.0,
            yield_rate_percent=99.0,
        )
        self.end_node = ProcessNode.objects.create(
            process_version=self.version,
            node_key="END-01",
            name="Preservation & CMM Signoff",
            node_type="END",
            position_x=500.0,
            position_y=100.0,
        )
        ProcessEdge.objects.create(
            process_version=self.version,
            edge_key="E-01",
            source_node=self.start_node,
            target_node=self.op_node,
        )
        ProcessEdge.objects.create(
            process_version=self.version,
            edge_key="E-02",
            source_node=self.op_node,
            target_node=self.end_node,
        )

    # -----------------------------------------------------------------
    # 1. Industry Profiles Registry Tests
    # -----------------------------------------------------------------
    def test_industry_profiles_registry_contains_all_eight_industries(self):
        profiles = IndustryProfileRegistry.list_all()
        self.assertEqual(len(profiles), 8)

        keys = {p.key for p in profiles}
        expected_keys = {
            "TEXTILES",
            "AUTOMOTIVE_EV",
            "CNC_MACHINING",
            "ELECTRONICS_PCBA",
            "PHARMACEUTICALS",
            "FOOD_BEVERAGE",
            "CHEMICALS",
            "GENERAL_DISCRETE",
        }
        self.assertEqual(keys, expected_keys)

        # Verify honest status representation
        cnc = IndustryProfileRegistry.get("CNC_MACHINING")
        self.assertEqual(cnc.status, ProfileStatus.OPERATIONAL)

        pharma = IndustryProfileRegistry.get("PHARMACEUTICALS")
        self.assertEqual(pharma.status, ProfileStatus.PREVIEW)
        self.assertIn("PREVIEW", pharma.status_note)

    # -----------------------------------------------------------------
    # 2. Provider Status & Redaction Tests
    # -----------------------------------------------------------------
    def test_provider_status_endpoint_redacts_api_keys(self):
        self.client.force_authenticate(user=self.user1)
        with patch.dict("os.environ", {"FACTORYOS_AI_API_KEY": "sk-live-secret-test-key-998877", "FACTORYOS_AI_PROVIDER": "hybrid"}):
            res = self.client.get("/api/automation/provider-status/")
            self.assertEqual(res.status_code, status.HTTP_200_OK)
            data = res.data["provider_status"]
            self.assertTrue(data["is_llm_available"])
            self.assertEqual(data["masked_api_key"], "sk-...8877")
            self.assertNotIn("sk-live-secret-test-key-998877", json.dumps(res.data))

    # -----------------------------------------------------------------
    # 3. Deterministic Planner Tests
    # -----------------------------------------------------------------
    def test_deterministic_goal_planner_generates_valid_steps(self):
        profile = IndustryProfileRegistry.get("CNC_MACHINING")
        goal = "Prepare a 150-unit production order. Check material availability, validate process, simulate execution, and request approval before releasing."
        plan = DeterministicGoalPlanner.generate_plan(goal, profile, self.factory1.name)

        self.assertIn("steps", plan)
        steps = plan["steps"]
        self.assertTrue(len(steps) >= 4)

        tool_names = [s["tool_name"] for s in steps]
        self.assertIn("inspect_inventory_stock", tool_names)
        self.assertIn("discover_and_validate_process", tool_names)
        self.assertIn("simulate_process_execution", tool_names)
        self.assertIn("create_work_order", tool_names)

        # Verify create_work_order is consequential
        wo_step = next(s for s in steps if s["tool_name"] == "create_work_order")
        self.assertTrue(wo_step["is_consequential"])
        self.assertEqual(wo_step["tool_arguments"]["quantity_target"], 150)

    # -----------------------------------------------------------------
    # 4. Mocked LLM Provider Tests
    # -----------------------------------------------------------------
    def test_openai_compatible_provider_parses_structured_plan(self):
        profile = IndustryProfileRegistry.get("CNC_MACHINING")
        provider = OpenAICompatibleAgentProvider(api_key="sk-test-key-12345", base_url="https://api.openai.com/v1")

        mock_llm_response = {
            "choices": [
                {
                    "message": {
                        "content": json.dumps({
                            "goal_summary": "Precision CNC impeller production plan for 75 units.",
                            "completion_criteria": ["Inventory checked", "Process validated", "Order released"],
                            "steps": [
                                {
                                    "step_number": 1,
                                    "title": "Check Alloy Billet Stock",
                                    "description": "Inspect stock for titanium alloy",
                                    "tool_name": "inspect_inventory_stock",
                                    "tool_arguments": {"material_name_or_code": "MAT-TI-01"},
                                    "is_consequential": False,
                                },
                                {
                                    "step_number": 2,
                                    "title": "Release Impeller Work Order",
                                    "description": "Dispatches 75 units to shop floor",
                                    "tool_name": "create_work_order",
                                    "tool_arguments": {"quantity_target": 75},
                                    "is_consequential": True,
                                },
                            ],
                        })
                    }
                }
            ]
        }

        mock_http_res = MagicMock()
        mock_http_res.status_code = 200
        mock_http_res.json.return_value = mock_llm_response

        with patch("httpx.Client.post", return_value=mock_http_res):
            plan = provider.generate_plan(
                goal="Produce 75 titanium impellers with stock check and work order release.",
                industry_profile=profile,
                factory_name=self.factory1.name,
            )

        self.assertEqual(len(plan["steps"]), 2)
        self.assertEqual(plan["steps"][0]["tool_name"], "inspect_inventory_stock")
        self.assertEqual(plan["steps"][1]["tool_name"], "create_work_order")
        self.assertTrue(plan["steps"][1]["is_consequential"])

    def test_openai_compatible_provider_rejects_unpermitted_tools(self):
        profile = IndustryProfileRegistry.get("CNC_MACHINING")
        provider = OpenAICompatibleAgentProvider(api_key="sk-test-key-12345")

        mock_malicious_response = {
            "choices": [
                {
                    "message": {
                        "content": json.dumps({
                            "goal_summary": "Malicious plan with unauthorized shell tool",
                            "steps": [
                                {
                                    "step_number": 1,
                                    "title": "Arbitrary Shell Execution",
                                    "tool_name": "run_bash_script_on_host",  # UNPERMITTED!
                                    "tool_arguments": {"command": "rm -rf /"},
                                }
                            ],
                        })
                    }
                }
            ]
        }

        mock_http_res = MagicMock()
        mock_http_res.status_code = 200
        mock_http_res.json.return_value = mock_malicious_response

        with patch("httpx.Client.post", return_value=mock_http_res):
            with self.assertRaises(LLMProviderError) as ctx:
                provider.generate_plan("Do something bad", profile, self.factory1.name)
            self.assertIn("not permitted", str(ctx.exception))

    # -----------------------------------------------------------------
    # 5. Hybrid Fallback Tests
    # -----------------------------------------------------------------
    def test_hybrid_mode_falls_back_deterministically_without_api_key(self):
        profile = IndustryProfileRegistry.get("CNC_MACHINING")
        with patch.dict("os.environ", {"FACTORYOS_AI_PROVIDER": "hybrid", "FACTORYOS_AI_API_KEY": ""}):
            plan, p_type, m_name, fallback, reason = ProviderManager.plan_goal(
                goal="Prepare a 100-unit production order.",
                industry_profile=profile,
                factory_name=self.factory1.name,
            )
            self.assertEqual(p_type, "hybrid")
            self.assertTrue(fallback)
            self.assertIn("No FACTORYOS_AI_API_KEY", reason)
            self.assertTrue(len(plan["steps"]) >= 3)

    # -----------------------------------------------------------------
    # 6. Tool Registry Real Domain Execution Tests
    # -----------------------------------------------------------------
    def test_tool_inspect_inventory_stock_reads_real_materials(self):
        result = ManufacturingToolRegistry.execute_tool(
            tool_name="inspect_inventory_stock",
            factory=self.factory1,
            arguments={"material_name_or_code": "MAT-TI-01"},
        )
        self.assertTrue(result.success)
        materials = result.data["materials"]
        self.assertEqual(len(materials), 1)
        self.assertEqual(materials[0]["name"], "Aerospace Titanium Billet Ti-6Al-4V")
        self.assertEqual(materials[0]["current_stock"], 250.0)

    def test_tool_discover_and_validate_process_uses_graph_validator(self):
        result = ManufacturingToolRegistry.execute_tool(
            tool_name="discover_and_validate_process",
            factory=self.factory1,
            arguments={"process_code_or_name": "PRC-IMP-5AX"},
        )
        self.assertTrue(result.success)
        self.assertEqual(result.data["process_name"], "5-Axis Impeller Machining Process")
        self.assertTrue(result.data["graph_validation"]["is_valid"])

    def test_tool_simulate_process_execution_calculates_estimates(self):
        result = ManufacturingToolRegistry.execute_tool(
            tool_name="simulate_process_execution",
            factory=self.factory1,
            arguments={"units_to_produce": 100},
        )
        self.assertTrue(result.success)
        self.assertEqual(result.data["units_target"], 100)
        self.assertTrue(result.data["estimated_production_hours"] > 0)

    # -----------------------------------------------------------------
    # 7. Goal Runtime Execution Loop & Approval Pause Tests
    # -----------------------------------------------------------------
    def test_goal_run_pauses_for_approval_before_consequential_step(self):
        self.client.force_authenticate(user=self.user1)

        payload = {
            "factory_id": str(self.factory1.id),
            "goal_text": "Prepare a 100-unit production order for impellers.",
            "industry_profile_key": "CNC_MACHINING",
            "provider_mode_override": "deterministic",
        }

        res = self.client.post("/api/automation/runs/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        run_data = res.data["run"]
        run_id = run_data["id"]

        run = AgentRun.objects.get(id=run_id)
        # Advance through read-only steps
        while run.status == AgentRunStatus.RUNNING:
            run = GoalRuntimeService.advance_run(run)

        # Must be paused at AWAITING_APPROVAL because of create_work_order
        self.assertEqual(run.status, AgentRunStatus.AWAITING_APPROVAL)

        active_plan = run.active_plan
        wo_step = active_plan.steps.filter(tool_name="create_work_order").first()
        self.assertIsNotNone(wo_step)
        self.assertEqual(wo_step.status, AgentStepStatus.AWAITING_APPROVAL)
        self.assertIsNotNone(wo_step.approval_request)
        self.assertEqual(wo_step.approval_request.status, ApprovalStatus.PENDING)

        # Ensure no WorkOrder has been created yet!
        self.assertEqual(WorkOrder.objects.filter(factory=self.factory1).count(), 0)

    def test_approving_consequential_step_creates_real_work_order_and_verifies_state(self):
        self.client.force_authenticate(user=self.user1)

        run = GoalRuntimeService.create_goal_run(
            factory=self.factory1,
            goal_text="Prepare a 100-unit production order.",
            user=self.user1,
            industry_profile_key="CNC_MACHINING",
            provider_mode_override="deterministic",
        )

        # Advance until paused
        while run.status == AgentRunStatus.RUNNING:
            run = GoalRuntimeService.advance_run(run)

        self.assertEqual(run.status, AgentRunStatus.AWAITING_APPROVAL)
        active_plan = run.active_plan
        wo_step = active_plan.steps.get(tool_name="create_work_order")
        appr_id = str(wo_step.approval_request.id)

        # Operator Approves
        res = self.client.post(f"/api/automation/runs/{run.id}/approve/", {
            "approval_id": appr_id,
            "action": "APPROVE",
            "review_notes": "Authorized 100-unit run by plant supervisor.",
        }, format="json")

        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Verify WorkOrder was actually created in database
        wo = WorkOrder.objects.filter(factory=self.factory1).first()
        self.assertIsNotNone(wo)
        self.assertEqual(wo.quantity_target, 100)
        self.assertEqual(wo.status, "RELEASED")

        # Verify run advanced to COMPLETED
        run.refresh_from_db()
        self.assertEqual(run.status, AgentRunStatus.COMPLETED)
        self.assertIn("verified", run.completion_summary.lower())

    def test_rejecting_consequential_step_halts_execution_and_blocks_run(self):
        self.client.force_authenticate(user=self.user1)

        run = GoalRuntimeService.create_goal_run(
            factory=self.factory1,
            goal_text="Prepare a 100-unit production order.",
            user=self.user1,
            industry_profile_key="CNC_MACHINING",
            provider_mode_override="deterministic",
        )

        while run.status == AgentRunStatus.RUNNING:
            run = GoalRuntimeService.advance_run(run)

        self.assertEqual(run.status, AgentRunStatus.AWAITING_APPROVAL)
        active_plan = run.active_plan
        wo_step = active_plan.steps.get(tool_name="create_work_order")
        appr_id = str(wo_step.approval_request.id)

        # Operator Rejects
        res = self.client.post(f"/api/automation/runs/{run.id}/approve/", {
            "approval_id": appr_id,
            "action": "REJECT",
            "review_notes": "Insufficient alloy stock on hand; holding run.",
        }, format="json")

        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Zero WorkOrders created!
        self.assertEqual(WorkOrder.objects.filter(factory=self.factory1).count(), 0)

        run.refresh_from_db()
        self.assertEqual(run.status, AgentRunStatus.BLOCKED)
        self.assertIn("rejected", run.error_message.lower())

    # -----------------------------------------------------------------
    # 8. Cross-Factory Tenant Isolation Tests
    # -----------------------------------------------------------------
    def test_user_cannot_access_or_create_runs_in_unauthorized_factory(self):
        self.client.force_authenticate(user=self.user2)

        # Attempt to create run in factory1 with org2 tenant header
        res = self.client.post(
            "/api/automation/runs/",
            {
                "factory_id": str(self.factory1.id),
                "goal_text": "Produce unauthorized batch.",
            },
            format="json",
            HTTP_X_ORGANIZATION_ID=str(self.org2.id),
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        # Attempt to list runs for factory1 with org2 tenant header
        res = self.client.get(
            f"/api/automation/runs/?factory_id={self.factory1.id}",
            HTTP_X_ORGANIZATION_ID=str(self.org2.id),
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
