"""
FactoryOS AI — Work Order Management Tests
Phase 3: Universal Manufacturing Process Engine (UMPE)
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, Product, ProductionLine
from apps.processes.models import ProcessDefinition, ProcessVersion, ProcessNode, ProcessEdge, WorkOrder

class WorkOrderTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Universal Test Org", slug="univ-test-wo")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="EV Powertrain Facility",
            code="FAC-EV-01",
            industry_type="AUTOMOTIVE_EV",
        )
        self.line = ProductionLine.objects.create(
            factory=self.factory,
            name="Stator Line 1",
            code="LINE-STAT-01",
            status="RUNNING",
        )
        self.product = Product.objects.create(
            factory=self.factory,
            name="EV Stator Assembly",
            sku="EV-STAT-01",
            unit_of_measure="pcs",
        )
        self.proc = ProcessDefinition.objects.create(
            factory=self.factory,
            name="Stator Assembly Process",
            code="PROC-STAT-01",
        )
        self.version = ProcessVersion.objects.create(
            process_definition=self.proc,
            version_number=1,
            version_tag="v1.0.0",
            status="PUBLISHED",
            is_published=True,
        )
        n_start = ProcessNode.objects.create(process_version=self.version, node_key="START", node_type="START")
        n_op = ProcessNode.objects.create(process_version=self.version, node_key="WIND", node_type="OPERATION")
        n_end = ProcessNode.objects.create(process_version=self.version, node_key="END", node_type="END")
        ProcessEdge.objects.create(process_version=self.version, edge_key="E1", source_node=n_start, target_node=n_op)
        ProcessEdge.objects.create(process_version=self.version, edge_key="E2", source_node=n_op, target_node=n_end)

    def test_work_order_crud_and_lifecycle(self):
        """Test work order creation, listing, detail, and state actions."""
        create_resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-EV-2026-001",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "process_version": str(self.version.id),
            "assigned_line": str(self.line.id),
            "quantity_target": 500,
            "priority": "HIGH",
            "notes": "Q4 EV delivery",
        })
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        wo_id = create_resp.data["data"]["id"]

        wo = WorkOrder.objects.get(id=wo_id)
        self.assertEqual(wo.order_number, "WO-EV-2026-001")
        self.assertEqual(wo.status, "RELEASED")
        self.assertEqual(wo.quantity_target, 500)

        # Start Work Order
        start_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/start/", {"mode": "SIMULATION"})
        self.assertEqual(start_resp.status_code, status.HTTP_200_OK)
        wo.refresh_from_db()
        self.assertEqual(wo.status, "IN_PROGRESS")
        self.assertIsNotNone(wo.actual_start_date)

        # Pause Work Order
        pause_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/pause/", {"reason": "Maintenance"})
        self.assertEqual(pause_resp.status_code, status.HTTP_200_OK)
        wo.refresh_from_db()
        self.assertEqual(wo.status, "PAUSED")

        # Resume Work Order
        resume_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/resume/")
        self.assertEqual(resume_resp.status_code, status.HTTP_200_OK)
        wo.refresh_from_db()
        self.assertEqual(wo.status, "IN_PROGRESS")

        # Cancel Work Order
        cancel_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/cancel/")
        self.assertEqual(cancel_resp.status_code, status.HTTP_200_OK)
        wo.refresh_from_db()
        self.assertEqual(wo.status, "CANCELLED")

    def test_rejection_of_draft_process_version(self):
        """Verify that work orders cannot be created referencing draft or unverified process versions."""
        draft_version = ProcessVersion.objects.create(
            process_definition=self.proc,
            version_number=2,
            version_tag="v2.0.0-draft",
            status="DRAFT",
            is_published=False,
        )
        resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-DRAFT-REJECT",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "process_version": str(draft_version.id),
            "quantity_target": 100,
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Only PUBLISHED versions can be used", resp.data["error"]["message"])

    def test_factory_boundary_isolation(self):
        """Enforce strict backend boundaries: foreign products, lines, or processes must be rejected."""
        foreign_factory = Factory.objects.create(
            organization=self.org,
            name="Foreign Food Plant",
            code="FAC-FOOD-99",
            industry_type="FOOD_BEVERAGE",
        )
        foreign_product = Product.objects.create(
            factory=foreign_factory,
            name="Foreign Cereal",
            sku="FOOD-CER-99",
        )

        # 1. Foreign product rejected
        resp1 = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-FOREIGN-PROD",
            "product": str(foreign_product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 100,
        })
        self.assertEqual(resp1.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Product does not belong to the selected factory", resp1.data["error"]["message"])

        # 2. Foreign process definition rejected
        foreign_proc = ProcessDefinition.objects.create(
            factory=foreign_factory,
            name="Foreign Baking Process",
            code="PROC-BAKE-99",
        )
        resp2 = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-FOREIGN-PROC",
            "product": str(self.product.id),
            "process_definition": str(foreign_proc.id),
            "quantity_target": 100,
        })
        self.assertEqual(resp2.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Process definition does not belong to the selected factory", resp2.data["error"]["message"])

    def test_validation_invalid_quantity_and_duplicate_number(self):
        """Verify target quantity must be positive and order number duplicates are rejected."""
        # Zero quantity
        resp_zero = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-ZERO-QTY",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 0,
        })
        self.assertEqual(resp_zero.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("positive integer", resp_zero.data["error"]["message"])

        # Create valid order first
        resp_ok = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-UNIQUE-001",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 250,
        })
        self.assertEqual(resp_ok.status_code, status.HTTP_201_CREATED)

        # Duplicate number
        resp_dup = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-UNIQUE-001",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 300,
        })
        self.assertEqual(resp_dup.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already exists", resp_dup.data["error"]["message"])

    def test_full_lifecycle_and_transition_guards(self):
        """Test PLANNED -> RELEASED -> IN_PROGRESS -> PAUSED -> RESUMED -> COMPLETED and guard errors."""
        create_resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-LIFECYCLE-100",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 100,
            "status": "PLANNED",
        })
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        wo_id = create_resp.data["data"]["id"]

        # 1. Cannot pause a planned order
        pause_fail = self.client.post(f"/api/processes/work-orders/{wo_id}/pause/")
        self.assertEqual(pause_fail.status_code, status.HTTP_400_BAD_REQUEST)

        # 2. Release order
        rel_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/release/")
        self.assertEqual(rel_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(rel_resp.data["work_order"]["status"], "RELEASED")

        # 3. Start order
        start_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/start/")
        self.assertEqual(start_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(start_resp.data["work_order"]["status"], "IN_PROGRESS")

        # 4. Pause order
        pause_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/pause/", {"reason": "Quality check"})
        self.assertEqual(pause_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(pause_resp.data["work_order"]["status"], "PAUSED")

        # 5. Resume order
        res_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/resume/")
        self.assertEqual(res_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(res_resp.data["work_order"]["status"], "IN_PROGRESS")

        # 6. Complete order
        comp_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/complete/")
        self.assertEqual(comp_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(comp_resp.data["work_order"]["status"], "COMPLETED")
        self.assertEqual(comp_resp.data["work_order"]["quantity_completed"], 100)

        # 7. Cannot cancel or start a completed order
        cancel_fail = self.client.post(f"/api/processes/work-orders/{wo_id}/cancel/")
        self.assertEqual(cancel_fail.status_code, status.HTTP_400_BAD_REQUEST)
        start_fail = self.client.post(f"/api/processes/work-orders/{wo_id}/start/")
        self.assertEqual(start_fail.status_code, status.HTTP_400_BAD_REQUEST)

    def test_factory_product_listing_api(self):
        """Verify GET /api/factories/<id>/products/ returns products scoped strictly to that factory."""
        resp = self.client.get(f"/api/factories/{self.factory.id}/products/")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data["count"], 1)
        self.assertEqual(resp.data["results"][0]["sku"], "EV-STAT-01")

    def test_release_rejected_on_archived_or_inactive_process(self):
        """Cannot release or start a work order if its process definition was archived."""
        create_resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-ARCHIVED-TEST",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "process_version": str(self.version.id),
            "quantity_target": 100,
            "status": "PLANNED",
        })
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        wo_id = create_resp.data["data"]["id"]

        # Deactivate process definition
        self.proc.is_active = False
        self.proc.save(update_fields=["is_active"])

        # Release attempt must fail
        rel_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/release/")
        self.assertEqual(rel_resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("inactive or archived", rel_resp.data["error"]["message"])

        # Start attempt must fail
        start_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/start/")
        self.assertEqual(start_resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("inactive or archived", start_resp.data["error"]["message"])

    def test_release_rejected_on_non_published_version(self):
        """Cannot release a work order if its process version is in draft/unverified status."""
        create_resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-DRAFT-VER-TEST",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "process_version": str(self.version.id),
            "quantity_target": 100,
            "status": "PLANNED",
        })
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        wo_id = create_resp.data["data"]["id"]

        # Modify version status
        self.version.status = "DRAFT"
        self.version.is_published = False
        self.version.save(update_fields=["status", "is_published"])

        rel_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/release/")
        self.assertEqual(rel_resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("non-published process version", rel_resp.data["error"]["message"])

    def test_cross_tenant_work_order_security(self):
        """Work order creation, reads, and lifecycle mutations reject foreign organization requests."""
        other_org = Organization.objects.create(name="Rival Aerospace", slug="rival-aero")

        # 1. Foreign tenant header on create
        resp_create = self.client.post(
            "/api/processes/work-orders/",
            {
                "factory": str(self.factory.id),
                "order_number": "WO-TENANT-REJECT",
                "product": str(self.product.id),
                "process_definition": str(self.proc.id),
                "quantity_target": 100,
            },
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp_create.status_code, status.HTTP_403_FORBIDDEN)

        # 2. Foreign tenant header on list
        resp_list = self.client.get(
            f"/api/processes/work-orders/?factory_id={self.factory.id}",
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp_list.status_code, status.HTTP_403_FORBIDDEN)

        # Create valid order first
        ok_create = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-TENANT-OK",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 100,
            "status": "PLANNED",
        })
        wo_id = ok_create.data["data"]["id"]

        # 3. Foreign tenant header on detail
        resp_detail = self.client.get(
            f"/api/processes/work-orders/{wo_id}/",
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp_detail.status_code, status.HTTP_403_FORBIDDEN)

        # 4. Foreign tenant header on action
        resp_action = self.client.post(
            f"/api/processes/work-orders/{wo_id}/release/",
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp_action.status_code, status.HTTP_403_FORBIDDEN)

    def test_version_integrity_when_new_version_published(self):
        """
        Confirm existing work orders retain their original version reference when a newer
        version is published, and execution uses the original version's graph nodes.
        """
        # Create work order referencing version 1 (3 nodes: START, WIND, END)
        create_resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-V1-PERSIST",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "process_version": str(self.version.id),
            "quantity_target": 100,
            "status": "RELEASED",
        })
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        wo_id = create_resp.data["data"]["id"]
        wo = WorkOrder.objects.get(id=wo_id)
        self.assertEqual(wo.process_version_id, self.version.id)

        # Create Version 2 with an additional node
        v2 = ProcessVersion.objects.create(
            process_definition=self.proc,
            version_number=2,
            version_tag="v2.0.0",
            status="PUBLISHED",
            is_published=True,
        )
        # Previous version becomes ARCHIVED
        self.version.status = "ARCHIVED"
        self.version.is_published = False
        self.version.save()

        n2_start = ProcessNode.objects.create(process_version=v2, node_key="START_V2", node_type="START")
        n2_op1 = ProcessNode.objects.create(process_version=v2, node_key="WIND_V2", node_type="OPERATION")
        n2_op2 = ProcessNode.objects.create(process_version=v2, node_key="INSPECT_V2", node_type="QUALITY_GATE")
        n2_end = ProcessNode.objects.create(process_version=v2, node_key="END_V2", node_type="END")
        ProcessEdge.objects.create(process_version=v2, edge_key="E1_V2", source_node=n2_start, target_node=n2_op1)
        ProcessEdge.objects.create(process_version=v2, edge_key="E2_V2", source_node=n2_op1, target_node=n2_op2)
        ProcessEdge.objects.create(process_version=v2, edge_key="E3_V2", source_node=n2_op2, target_node=n2_end)

        # Verify work order still points to original version
        wo.refresh_from_db()
        self.assertEqual(wo.process_version_id, self.version.id)

        # Start execution of the original work order
        start_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/start/", {"mode": "SIMULATION"})
        self.assertEqual(start_resp.status_code, status.HTTP_200_OK)

        # Stage executions must derive from v1's 3 nodes (START, WIND, END), NOT v2's 4 nodes
        exec_data = start_resp.data["execution"]
        stage_keys = [s["node_key"] for s in exec_data["stage_executions"]]
        self.assertEqual(len(stage_keys), 3)
        self.assertIn("START", stage_keys)
        self.assertIn("WIND", stage_keys)
        self.assertIn("END", stage_keys)
        self.assertNotIn("INSPECT_V2", stage_keys)

    def test_stage_executions_derive_from_linked_version_and_include_universal_fields(self):
        """Derived stage executions expose setup_time_seconds, operator_role, skills, and yield rate."""
        op_node = self.version.nodes.get(node_key="WIND")
        op_node.setup_time_seconds = 45.0
        op_node.operator_role = "Coil Winding Specialist"
        op_node.required_skills = ["Tension Calibration", "Wire Routing"]
        op_node.yield_rate_percent = 98.7
        op_node.save()

        create_resp = self.client.post("/api/processes/work-orders/", {
            "factory": str(self.factory.id),
            "order_number": "WO-UNIV-FIELDS",
            "product": str(self.product.id),
            "process_definition": str(self.proc.id),
            "quantity_target": 200,
            "status": "RELEASED",
        })
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        wo_id = create_resp.data["data"]["id"]

        start_resp = self.client.post(f"/api/processes/work-orders/{wo_id}/start/", {"mode": "SIMULATION"})
        self.assertEqual(start_resp.status_code, status.HTTP_200_OK)

        stages = start_resp.data["execution"]["stage_executions"]
        wind_stage = next(s for s in stages if s["node_key"] == "WIND")
        self.assertEqual(wind_stage["setup_time_seconds"], 45.0)
        self.assertEqual(wind_stage["operator_role"], "Coil Winding Specialist")
        self.assertEqual(wind_stage["required_skills"], ["Tension Calibration", "Wire Routing"])
        self.assertEqual(wind_stage["yield_rate_percent"], 98.7)


