"""
FactoryOS AI — Manufacturing Simulation Engine & Material Flow Tests
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
    SimulationScenario,
)
from apps.processes.services.execution_service import ProductionExecutionService
from apps.processes.services.simulation_service import ManufacturingSimulationEngine

class SimulationEngineTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Sim Test Org", slug="sim-test-org")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Nordic Pure BioFoods Test",
            code="FAC-FOOD-TST",
            industry_type="FOOD_PROCESSING",
        )
        self.product = Product.objects.create(
            factory=self.factory,
            name="Organic Beverage Pack",
            sku="FOOD-BEV-01",
            unit_of_measure="pcs",
        )
        self.proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Beverage Packaging Flow",
            code="PROC-BEV-01",
        )
        self.version = ProcessVersion.objects.create(
            process_definition=self.proc,
            version_number=1,
            version_tag="v1.0.0",
            status="PUBLISHED",
            is_published=True,
        )
        n_start = ProcessNode.objects.create(process_version=self.version, node_key="START", node_type="START")
        n_pasteurize = ProcessNode.objects.create(
            process_version=self.version,
            node_key="PAST",
            name="UHT Pasteurization",
            node_type="OPERATION",
            cycle_time_seconds=5.0,
            yield_rate_percent=99.0,
        )
        n_fill = ProcessNode.objects.create(
            process_version=self.version,
            node_key="FILL",
            name="Aseptic Filling",
            node_type="OPERATION",
            cycle_time_seconds=3.0,
            yield_rate_percent=98.5,
        )
        n_end = ProcessNode.objects.create(process_version=self.version, node_key="END", node_type="END")

        ProcessEdge.objects.create(process_version=self.version, edge_key="E1", source_node=n_start, target_node=n_pasteurize)
        ProcessEdge.objects.create(process_version=self.version, edge_key="E2", source_node=n_pasteurize, target_node=n_fill)
        ProcessEdge.objects.create(process_version=self.version, edge_key="E3", source_node=n_fill, target_node=n_end)

        self.wo = WorkOrder.objects.create(
            factory=self.factory,
            order_number="WO-SIM-001",
            product=self.product,
            process_definition=self.proc,
            process_version=self.version,
            quantity_target=50,
            status="RELEASED",
        )

    def test_simulation_step_and_deterministic_reproducibility(self):
        """Test stepping simulation deterministically with random seed."""
        exec1 = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")
        stage_past = StageExecution.objects.get(process_execution=exec1, node__node_key="PAST")
        self.assertEqual(stage_past.status, "RUNNING")

        # Step 1: Advance Pasteurization
        adv1 = ManufacturingSimulationEngine.step_simulation(exec1, random_seed=42)
        self.assertIsNotNone(adv1)
        self.assertEqual(adv1.node.node_key, "PAST")
        self.assertEqual(adv1.status, "COMPLETED")

        # Step 2: Advance Filling
        adv2 = ManufacturingSimulationEngine.step_simulation(exec1, random_seed=42)
        self.assertIsNotNone(adv2)
        self.assertEqual(adv2.node.node_key, "FILL")
        self.assertEqual(adv2.status, "COMPLETED")

        exec1.refresh_from_db()
        self.assertEqual(exec1.status, "COMPLETED")
        self.assertEqual(exec1.current_progress_percent, 100.0)

    def test_simulation_api_endpoints(self):
        """Test API endpoints for simulation scenarios, stepping, and anomaly injection."""
        exec_run = ProductionExecutionService.start_execution(self.wo, mode="SIMULATION")

        # 1. Inject Delay
        resp_inj = self.client.post("/api/processes/simulation/inject-anomaly/", {
            "execution_id": str(exec_run.id),
            "scenario_type": "PRODUCTION_DELAY",
            "parameters": {"delay_multiplier": 3.0},
        }, format="json")
        self.assertEqual(resp_inj.status_code, status.HTTP_200_OK)
        self.assertTrue(resp_inj.data["success"])

        # 2. Step via API
        resp_step = self.client.post("/api/processes/simulation/step/", {
            "execution_id": str(exec_run.id),
            "random_seed": 100,
        })
        self.assertEqual(resp_step.status_code, status.HTTP_200_OK)
        self.assertTrue(resp_step.data["success"])

        # 3. Run full simulation via API
        resp_full = self.client.post("/api/processes/simulation/run-full/", {
            "execution_id": str(exec_run.id),
            "random_seed": 42,
            "max_steps": 20,
        })
        self.assertEqual(resp_full.status_code, status.HTTP_200_OK)
        self.assertTrue(resp_full.data["success"])
        self.assertEqual(resp_full.data["result"]["status"], "COMPLETED")
