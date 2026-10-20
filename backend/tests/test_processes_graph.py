"""
FactoryOS AI — Process Graph Validation & Versioning Tests
Phase 3: Universal Manufacturing Process Engine (UMPE)
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, ProductionLine, Machine
from apps.processes.models import ProcessDefinition, ProcessVersion, ProcessNode, ProcessEdge
from apps.processes.services.graph_validator import ProcessGraphValidator

class ProcessGraphTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Universal Test Org", slug="univ-test-org")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Advanced Test Plant",
            code="FAC-TST-01",
            industry_type="CNC_ENGINEERING",
            location="Detroit, MI",
            country="United States",
        )
        self.line = ProductionLine.objects.create(
            factory=self.factory,
            name="Machining Cell 1",
            code="LINE-M1",
            status="RUNNING",
            target_hourly_units=100,
            actual_hourly_units=95,
        )

    def test_process_definition_lifecycle(self):
        """Test creating, retrieving, and updating a process definition."""
        resp = self.client.post("/api/processes/definitions/", {
            "factory": str(self.factory.id),
            "name": "Precision Milling Flow",
            "code": "PROC-MILL-01",
            "description": "5-axis milling workflow",
            "category": "Machining",
            "target_cycle_time_seconds": 45.0,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        proc_id = resp.data["data"]["id"]

        # Verify default v1.0.0 was created with START, OP, and END nodes
        proc = ProcessDefinition.objects.get(id=proc_id)
        self.assertEqual(proc.versions.count(), 1)
        v1 = proc.versions.first()
        self.assertEqual(v1.nodes.count(), 3)
        self.assertEqual(v1.edges.count(), 2)

        # Retrieve detail
        detail_resp = self.client.get(f"/api/processes/definitions/{proc_id}/")
        self.assertEqual(detail_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_resp.data["data"]["name"], "Precision Milling Flow")

        # Patch
        patch_resp = self.client.patch(f"/api/processes/definitions/{proc_id}/", {
            "name": "Precision 5-Axis Milling Flow"
        })
        self.assertEqual(patch_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_resp.data["data"]["name"], "Precision 5-Axis Milling Flow")

    def test_graph_validation_valid_and_cyclic(self):
        """Test graph validator for valid workflow and cycle detection."""
        proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Test Cycle Flow",
            code="PROC-CYC-01",
        )
        v = ProcessVersion.objects.create(
            process_definition=proc,
            version_number=1,
            version_tag="v1.0.0",
            status="DRAFT"
        )
        n_start = ProcessNode.objects.create(process_version=v, node_key="START", node_type="START")
        n_op1 = ProcessNode.objects.create(process_version=v, node_key="OP1", node_type="OPERATION")
        n_op2 = ProcessNode.objects.create(process_version=v, node_key="OP2", node_type="OPERATION")
        n_end = ProcessNode.objects.create(process_version=v, node_key="END", node_type="END")

        e1 = ProcessEdge.objects.create(process_version=v, edge_key="E1", source_node=n_start, target_node=n_op1)
        e2 = ProcessEdge.objects.create(process_version=v, edge_key="E2", source_node=n_op1, target_node=n_op2)
        e3 = ProcessEdge.objects.create(process_version=v, edge_key="E3", source_node=n_op2, target_node=n_end)

        is_valid, errors, _ = ProcessGraphValidator.validate_version(v)
        self.assertTrue(is_valid)
        self.assertEqual(len(errors), 0)

        # Inject cycle: OP2 -> OP1
        cycle_edge = ProcessEdge.objects.create(process_version=v, edge_key="E_CYC", source_node=n_op2, target_node=n_op1)
        is_valid_cyclic, errs_cyclic, _ = ProcessGraphValidator.validate_version(v)
        self.assertFalse(is_valid_cyclic)
        self.assertTrue(any("cyclic dependency" in e.lower() for e in errs_cyclic))

    def test_graph_validation_unreachable_node(self):
        """Test detection of dangling / unreachable node."""
        proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Test Dangling Flow",
            code="PROC-DANG-01",
        )
        v = ProcessVersion.objects.create(process_definition=proc, version_number=1)
        n_start = ProcessNode.objects.create(process_version=v, node_key="START", node_type="START")
        n_end = ProcessNode.objects.create(process_version=v, node_key="END", node_type="END")
        ProcessEdge.objects.create(process_version=v, edge_key="E1", source_node=n_start, target_node=n_end)

        # Dangling node with no edges
        ProcessNode.objects.create(process_version=v, node_key="ORPHAN", node_type="OPERATION")

        is_valid, errors, _ = ProcessGraphValidator.validate_version(v)
        self.assertFalse(is_valid)
        self.assertTrue(any("unreachable" in e.lower() for e in errors))

    def test_version_publishing_and_immutability(self):
        """Test publishing a validated version and verifying immutable node edits."""
        proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Publishable Flow",
            code="PROC-PUB-01",
        )
        v = ProcessVersion.objects.create(process_definition=proc, version_number=1)
        n_start = ProcessNode.objects.create(process_version=v, node_key="START", node_type="START")
        n_end = ProcessNode.objects.create(process_version=v, node_key="END", node_type="END")
        ProcessEdge.objects.create(process_version=v, edge_key="E1", source_node=n_start, target_node=n_end)

        # Publish via API
        pub_resp = self.client.post(f"/api/processes/versions/{v.id}/publish/")
        self.assertEqual(pub_resp.status_code, status.HTTP_200_OK)
        v.refresh_from_db()
        self.assertEqual(v.status, "PUBLISHED")
        self.assertTrue(v.is_published)

        # Attempt to add node to published version must be rejected
        add_node_resp = self.client.post(f"/api/processes/versions/{v.id}/nodes/", {
            "name": "Illegal Node",
            "node_type": "OPERATION",
        })
        self.assertEqual(add_node_resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue("immutable" in add_node_resp.data["error"]["message"].lower())

    def test_version_cloning(self):
        """Test cloning a published version into a new editable draft."""
        proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Clonable Flow",
            code="PROC-CLONE-01",
        )
        v1 = ProcessVersion.objects.create(process_definition=proc, version_number=1, status="PUBLISHED", is_published=True)
        n1 = ProcessNode.objects.create(process_version=v1, node_key="START", node_type="START")
        n2 = ProcessNode.objects.create(process_version=v1, node_key="END", node_type="END")
        ProcessEdge.objects.create(process_version=v1, edge_key="E1", source_node=n1, target_node=n2)

        clone_resp = self.client.post(f"/api/processes/definitions/{proc.id}/clone-version/")
        self.assertEqual(clone_resp.status_code, status.HTTP_201_CREATED)
        new_v_id = clone_resp.data["data"]["id"]

        v2 = ProcessVersion.objects.get(id=new_v_id)
        self.assertEqual(v2.version_number, 2)
        self.assertEqual(v2.status, "DRAFT")
        self.assertFalse(v2.is_published)
        self.assertEqual(v2.nodes.count(), 2)
        self.assertEqual(v2.edges.count(), 1)
