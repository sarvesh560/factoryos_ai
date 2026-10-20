"""
FactoryOS AI — Production Execution Engine & Parallel Execution Tests
Phase 3: Universal Manufacturing Process Engine (UMPE)
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, Product, RawMaterial, ProductionLine
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    ProcessNode,
    ProcessEdge,
    WorkOrder,
    ProcessExecution,
    StageExecution,
    MaterialFlow,
)
from apps.processes.services.execution_service import ProductionExecutionService
from apps.processes.services.simulation_service import ManufacturingSimulationEngine

class ExecutionEngineTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Universal Exec Org", slug="univ-exec-org")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Smart Robotics Plant",
            code="FAC-ROBO-01",
            industry_type="AUTOMOTIVE_EV",
        )
        self.line = ProductionLine.objects.create(
            factory=self.factory,
            name="Robotics Line 1",
            code="LINE-R1",
            status="RUNNING",
        )
        self.product = Product.objects.create(
            factory=self.factory,
            name="Robotic Actuator Core",
            sku="ROBO-ACT-01",
            unit_of_measure="pcs",
        )
        self.raw_copper = RawMaterial.objects.create(
            factory=self.factory,
            name="High-Purity Copper Wire",
            code="MAT-CU-HIGH",
            unit_of_measure="kg",
            current_stock=1000.0,
            safety_stock=200.0,
        )

        # Build Parallel Graph:
        # START -> SPLIT -> (BRANCH A: WINDING) & (BRANCH B: CORE FORMING) -> JOIN -> END
        self.proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Actuator Core Manufacturing",
            code="PROC-ROBO-01",
        )
        self.v = ProcessVersion.objects.create(
            process_definition=self.proc,
            version_number=1,
            version_tag="v1.0.0",
            status="PUBLISHED",
            is_published=True,
        )

        self.n_start = ProcessNode.objects.create(process_version=self.v, node_key="START", node_type="START")
        self.n_split = ProcessNode.objects.create(process_version=self.v, node_key="SPLIT", node_type="PARALLEL_SPLIT")
        self.n_branch_a = ProcessNode.objects.create(
            process_version=self.v,
            node_key="OP_WIND",
            name="Coil Winding",
            node_type="OPERATION",
            cycle_time_seconds=20.0,
            input_materials=[{"raw_material_id": str(self.raw_copper.id), "quantity": 0.5, "unit": "kg"}],
        )
        self.n_branch_b = ProcessNode.objects.create(
            process_version=self.v,
            node_key="OP_CORE",
            name="Core Lamination Stamping",
            node_type="OPERATION",
            cycle_time_seconds=15.0,
        )
        self.n_join = ProcessNode.objects.create(process_version=self.v, node_key="JOIN", node_type="PARALLEL_JOIN")
        self.n_end = ProcessNode.objects.create(process_version=self.v, node_key="END", node_type="END")

        ProcessEdge.objects.create(process_version=self.v, edge_key="E1", source_node=self.n_start, target_node=self.n_split)
        ProcessEdge.objects.create(process_version=self.v, edge_key="E2", source_node=self.n_split, target_node=self.n_branch_a)
        ProcessEdge.objects.create(process_version=self.v, edge_key="E3", source_node=self.n_split, target_node=self.n_branch_b)
        ProcessEdge.objects.create(process_version=self.v, edge_key="E4", source_node=self.n_branch_a, target_node=self.n_join)
        ProcessEdge.objects.create(process_version=self.v, edge_key="E5", source_node=self.n_branch_b, target_node=self.n_join)
        ProcessEdge.objects.create(process_version=self.v, edge_key="E6", source_node=self.n_join, target_node=self.n_end)

        self.wo = WorkOrder.objects.create(
            factory=self.factory,
            order_number="WO-ACT-001",
            product=self.product,
            process_definition=self.proc,
            process_version=self.v,
            assigned_line=self.line,
            quantity_target=100,
            status="RELEASED",
        )

    def test_start_execution_and_material_consumption(self):
        """Test execution start, stage activation, and atomic material deduction."""
        initial_stock = self.raw_copper.current_stock
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")

        self.assertEqual(execution.status, "RUNNING")
        self.assertEqual(execution.work_order.status, "IN_PROGRESS")

        # START node completed, SPLIT passed, both branch A and branch B activated
        stage_wind = StageExecution.objects.get(process_execution=execution, node=self.n_branch_a)
        self.assertEqual(stage_wind.status, "RUNNING")

        # Verify raw material deduction: 100 units * 0.5 kg = 50 kg consumed
        self.raw_copper.refresh_from_db()
        self.assertEqual(self.raw_copper.current_stock, initial_stock - 50.0)

        # Verify MaterialFlow record created
        flow = MaterialFlow.objects.filter(process_execution=execution, flow_type="INPUT_CONSUMPTION").first()
        self.assertIsNotNone(flow)
        self.assertEqual(flow.quantity, 50.0)

    def test_parallel_join_synchronization(self):
        """Test that PARALLEL_JOIN waits for BOTH concurrent branches before unlocking."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_wind = StageExecution.objects.get(process_execution=execution, node=self.n_branch_a)
        stage_core = StageExecution.objects.get(process_execution=execution, node=self.n_branch_b)
        stage_join = StageExecution.objects.get(process_execution=execution, node=self.n_join)

        self.assertEqual(stage_join.status, "PENDING")

        # 1. Complete Branch A only
        ProductionExecutionService.advance_stage(stage_wind, units_completed=100)
        stage_join.refresh_from_db()
        # Branch B is not done yet, so JOIN must remain PENDING
        self.assertEqual(stage_join.status, "PENDING")

        # 2. Complete Branch B
        ProductionExecutionService.advance_stage(stage_core, units_completed=100)
        stage_join.refresh_from_db()
        # Now BOTH branches are done, JOIN should transition to RUNNING
        self.assertEqual(stage_join.status, "RUNNING")

        # 3. Advance JOIN to COMPLETED
        ProductionExecutionService.advance_stage(stage_join, units_completed=100)
        execution.refresh_from_db()
        self.wo.refresh_from_db()

        # All branches reached END -> execution and work order completed!
        self.assertEqual(execution.status, "COMPLETED")
        self.assertEqual(self.wo.status, "COMPLETED")
        self.assertEqual(self.wo.quantity_completed, 100)

    def test_idempotent_stage_advance(self):
        """Verify advancing an already completed stage returns current state without re-counting."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_core = StageExecution.objects.get(process_execution=execution, node=self.n_branch_b)

        adv1 = ProductionExecutionService.advance_stage(stage_core, units_completed=95, units_scrapped=5)
        self.assertEqual(adv1.status, "COMPLETED")
        self.assertEqual(adv1.units_completed, 95)
        self.assertEqual(adv1.units_scrapped, 5)

        # Call again with different parameters: must return existing completed state idempotently
        adv2 = ProductionExecutionService.advance_stage(stage_core, units_completed=50, units_scrapped=50)
        self.assertEqual(adv2.status, "COMPLETED")
        self.assertEqual(adv2.units_completed, 95) # Preserved original completed value

    def test_simulation_anomaly_breakdown(self):
        """Test simulation anomaly injection: machine breakdown causes BLOCKED status."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        res = ManufacturingSimulationEngine.inject_anomaly(
            execution=execution,
            scenario_type="MACHINE_BREAKDOWN",
        )
        self.assertTrue(res["success"])
        execution.refresh_from_db()
        self.assertEqual(execution.status, "BLOCKED")
        self.assertIsNotNone(execution.bottleneck_node)

    def test_cannot_advance_pending_stage(self):
        """Verify advancing a PENDING stage is rejected and cannot bypass predecessor stages."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_join = StageExecution.objects.get(process_execution=execution, node=self.n_join)
        self.assertEqual(stage_join.status, "PENDING")

        with self.assertRaises(ValueError) as ctx:
            ProductionExecutionService.advance_stage(stage_join, units_completed=100)
        self.assertIn("PENDING status", str(ctx.exception))

        # Also verify HTTP 400 response from API endpoint
        url = f"/api/processes/execution/stages/{stage_join.id}/advance/"
        resp = self.client.post(url, {"units_completed": 100}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("PENDING status", resp.data["error"]["message"])

    def test_cannot_advance_with_excessive_quantity(self):
        """Verify advancing a stage with quantity exceeding available units is rejected."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_wind = StageExecution.objects.get(process_execution=execution, node=self.n_branch_a)
        self.assertEqual(stage_wind.status, "RUNNING")

        # Target batch is 100, attempt 500
        url = f"/api/processes/execution/stages/{stage_wind.id}/advance/"
        resp = self.client.post(url, {"units_completed": 500}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("exceeds available", resp.data["error"]["message"])

        # Attempt negative quantity
        resp_neg = self.client.post(url, {"units_completed": -5}, format="json")
        self.assertEqual(resp_neg.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("cannot be negative", resp_neg.data["error"]["message"])

    def test_cannot_advance_when_execution_paused(self):
        """Verify advancing stages is rejected when execution is PAUSED."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_wind = StageExecution.objects.get(process_execution=execution, node=self.n_branch_a)

        # Pause execution
        ProductionExecutionService.pause_execution(execution, reason="Maintenance hold")
        self.assertEqual(execution.status, "PAUSED")

        url = f"/api/processes/execution/stages/{stage_wind.id}/advance/"
        resp = self.client.post(url, {"units_completed": 100}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("PAUSED", resp.data["error"]["message"])

        # Resume execution
        ProductionExecutionService.resume_execution(execution)
        self.assertEqual(execution.status, "RUNNING")

        # Now advance should succeed
        resp_resumed = self.client.post(url, {"units_completed": 100}, format="json")
        self.assertEqual(resp_resumed.status_code, status.HTTP_200_OK)
        stage_wind.refresh_from_db()
        self.assertEqual(stage_wind.status, "COMPLETED")

    def test_execution_action_api_pause_resume_complete(self):
        """Test direct execution action endpoints: pause, resume, and complete."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        url_pause = f"/api/processes/execution/{execution.id}/pause/"
        url_resume = f"/api/processes/execution/{execution.id}/resume/"
        url_complete = f"/api/processes/execution/{execution.id}/complete/"

        # 1. Pause
        resp_p = self.client.post(url_pause, {"reason": "Quality audit hold"}, format="json")
        self.assertEqual(resp_p.status_code, status.HTTP_200_OK)
        execution.refresh_from_db()
        self.assertEqual(execution.status, "PAUSED")

        # 2. Resume
        resp_r = self.client.post(url_resume, {}, format="json")
        self.assertEqual(resp_r.status_code, status.HTTP_200_OK)
        execution.refresh_from_db()
        self.assertEqual(execution.status, "RUNNING")

        # 3. Complete
        resp_c = self.client.post(url_complete, {}, format="json")
        self.assertEqual(resp_c.status_code, status.HTTP_200_OK)
        execution.refresh_from_db()
        self.assertEqual(execution.status, "COMPLETED")
        self.assertEqual(execution.current_progress_percent, 100.0)
        self.wo.refresh_from_db()
        self.assertEqual(self.wo.status, "COMPLETED")

    def test_fail_stage_guards(self):
        """Test that completed stages cannot be failed and errors are returned properly."""
        execution = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_wind = StageExecution.objects.get(process_execution=execution, node=self.n_branch_a)
        ProductionExecutionService.advance_stage(stage_wind, units_completed=100)

        url_fail = f"/api/processes/execution/stages/{stage_wind.id}/fail/"
        resp = self.client.post(url_fail, {"error_message": "Post-run fault"}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already completed", resp.data["error"]["message"])

