"""
FactoryOS AI — Phase 3 Step 1 Backend Foundation Tests
Tests industry classification, setup times, operator roles, skills metadata, and version cloning.
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, ProductionLine, Machine, IndustryType
from apps.processes.models import ProcessDefinition, ProcessVersion, ProcessNode, ProcessEdge
from apps.processes.serializers import ProcessDefinitionSerializer, ProcessNodeSerializer

class Step1BackendFoundationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Apex Advanced Manufacturing", slug="apex-mfg")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Apex EV Battery & PCBA Facility",
            code="FAC-APEX-01",
            industry_type=IndustryType.ELECTRONICS,
            location="Austin, TX",
            country="United States",
        )
        self.line = ProductionLine.objects.create(
            factory=self.factory,
            name="SMT High-Speed Surface Mount Line",
            code="LINE-SMT-01",
            status="RUNNING",
            target_hourly_units=500,
            actual_hourly_units=480,
        )
        self.machine = Machine.objects.create(
            production_line=self.line,
            name="High-Speed Chip Shooter SMT-1",
            code="MCH-SMT-01",
            status="RUNNING",
        )

    def test_process_definition_industry_type_explicit_and_default(self):
        """Test process definition inherits factory industry_type by default or accepts explicit industry."""
        # 1. Inherit from factory
        resp1 = self.client.post("/api/processes/definitions/", {
            "factory": str(self.factory.id),
            "name": "PCBA Motherboard Assembly",
            "code": "PRC-SMT-001",
        })
        self.assertEqual(resp1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp1.data["data"]["industry_type"], IndustryType.ELECTRONICS)

        # 2. Explicit industry
        resp2 = self.client.post("/api/processes/definitions/", {
            "factory": str(self.factory.id),
            "name": "EV Battery Pack Thermal Interface",
            "code": "PRC-BAT-001",
            "industry_type": IndustryType.AUTOMOTIVE,
        })
        self.assertEqual(resp2.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp2.data["data"]["industry_type"], IndustryType.AUTOMOTIVE)

        # 3. Patch industry_type
        proc_id = resp2.data["data"]["id"]
        patch_resp = self.client.patch(f"/api/processes/definitions/{proc_id}/", {
            "industry_type": IndustryType.CNC_ENGINEERING,
        })
        self.assertEqual(patch_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_resp.data["data"]["industry_type"], IndustryType.CNC_ENGINEERING)

    def test_process_node_setup_time_and_operator_role_metadata(self):
        """Test adding and updating setup_time_seconds, operator_role, and required_skills on nodes."""
        proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Precision Milling",
            code="PRC-CNC-001",
            industry_type=IndustryType.CNC_ENGINEERING,
        )
        ver = ProcessVersion.objects.create(
            process_definition=proc,
            version_number=1,
            version_tag="v1.0.0",
            status="DRAFT",
        )

        # Create node with new fields
        node_resp = self.client.post(
            f"/api/processes/versions/{ver.id}/nodes/",
            {
                "node_key": "OP-ROUGH-01",
                "name": "Rough Milling Stage",
                "node_type": "OPERATION",
                "cycle_time_seconds": 120.0,
                "setup_time_seconds": 900.0,
                "required_operators": 2,
                "operator_role": "Senior CNC Machinist",
                "required_skills": ["5-Axis G-Code", "CAM Toolpath Verification", "CMM Inspection"],
                "assigned_line": str(self.line.id),
                "assigned_machine": str(self.machine.id),
            },
            format="json"
        )
        self.assertEqual(node_resp.status_code, status.HTTP_201_CREATED)
        node_data = node_resp.data["data"]
        self.assertEqual(node_data["setup_time_seconds"], 900.0)
        self.assertEqual(node_data["operator_role"], "Senior CNC Machinist")
        self.assertEqual(len(node_data["required_skills"]), 3)
        self.assertIn("5-Axis G-Code", node_data["required_skills"])

        # Patch node setup time and skills
        node_id = node_data["id"]
        patch_resp = self.client.patch(
            f"/api/processes/nodes/{node_id}/",
            {
                "setup_time_seconds": 600.0,
                "operator_role": "Lead CNC Specialist",
                "required_skills": ["5-Axis G-Code", "MasterCAM L3"],
            },
            format="json"
        )
        self.assertEqual(patch_resp.status_code, status.HTTP_200_OK)
        updated_data = patch_resp.data["data"]
        self.assertEqual(updated_data["setup_time_seconds"], 600.0)
        self.assertEqual(updated_data["operator_role"], "Lead CNC Specialist")
        self.assertEqual(updated_data["required_skills"], ["5-Axis G-Code", "MasterCAM L3"])

    def test_version_cloning_preserves_setup_time_and_operator_metadata(self):
        """Test cloning a version preserves setup time, operator roles, and required skills."""
        proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Pharma Cleanroom Compounding",
            code="PRC-PHARM-001",
            industry_type=IndustryType.PHARMACEUTICALS,
        )
        v1 = ProcessVersion.objects.create(
            process_definition=proc,
            version_number=1,
            version_tag="v1.0.0",
            status="DRAFT",
        )
        node = ProcessNode.objects.create(
            process_version=v1,
            node_key="OP-ASEPTIC-01",
            name="Aseptic Compounding",
            node_type="OPERATION",
            cycle_time_seconds=300.0,
            setup_time_seconds=1800.0,
            operator_role="Cleanroom Technician Level 3",
            required_skills=["ISO Class 5 Protocol", "Sterile Filtration"],
            assigned_line=self.line,
            assigned_machine=self.machine,
        )

        clone_resp = self.client.post(f"/api/processes/versions/{v1.id}/clone/")
        self.assertEqual(clone_resp.status_code, status.HTTP_201_CREATED)
        new_ver_id = clone_resp.data["data"]["id"]

        cloned_ver = ProcessVersion.objects.get(id=new_ver_id)
        cloned_node = cloned_ver.nodes.get(node_key="OP-ASEPTIC-01")
        self.assertEqual(cloned_node.setup_time_seconds, 1800.0)
        self.assertEqual(cloned_node.operator_role, "Cleanroom Technician Level 3")
        self.assertEqual(cloned_node.required_skills, ["ISO Class 5 Protocol", "Sterile Filtration"])
