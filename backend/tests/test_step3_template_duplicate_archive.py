"""
FactoryOS AI — Phase 3 Step 3 Template, Duplicate, and Archive API Tests
Verifies template listing, template instantiation, process duplication, and safe archiving.
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, ProductionLine, Product, IndustryType
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    ProcessNode,
    ProcessEdge,
    WorkOrder,
)
from apps.processes.services.execution_service import ProductionExecutionService

class Step3TemplateDuplicateArchiveTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Universal Step 3 Org", slug="step3-org")
        self.factory1 = Factory.objects.create(
            organization=self.org,
            name="Plant Alpha - CNC & Assembly",
            code="FAC-ALPHA-01",
            industry_type=IndustryType.CNC_ENGINEERING,
        )
        self.factory2 = Factory.objects.create(
            organization=self.org,
            name="Plant Beta - Electronics Facility",
            code="FAC-BETA-02",
            industry_type=IndustryType.ELECTRONICS,
        )
        self.line1 = ProductionLine.objects.create(
            factory=self.factory1,
            name="Line Alpha-1",
            code="LINE-A1",
        )
        self.product1 = Product.objects.create(
            factory=self.factory1,
            name="Precision Turbine Impeller",
            sku="SKU-TURB-01",
        )

    # ==========================================================================
    # 1. TEMPLATE LISTING & FILTERING TESTS
    # ==========================================================================

    def test_template_list_success(self):
        """GET /api/processes/templates/ returns all 8 universal templates with zero DB side effects."""
        initial_defs = ProcessDefinition.objects.count()
        resp = self.client.get("/api/processes/templates/")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertTrue(resp.data["success"])
        self.assertEqual(resp.data["count"], 8)
        self.assertEqual(len(resp.data["results"]), 8)

        # Zero DB creation
        self.assertEqual(ProcessDefinition.objects.count(), initial_defs)

        keys = [t["key"] for t in resp.data["results"]]
        self.assertIn("cnc_precision_machining", keys)
        self.assertIn("ev_battery_module_assembly", keys)
        self.assertIn("electronics_smt_pcba", keys)
        self.assertIn("pharma_sterile_injectable", keys)

    def test_template_list_filters(self):
        """Test filtering templates by valid industry_type and category, plus error on invalid industry."""
        # 1. Valid industry_type filter
        resp_filter = self.client.get("/api/processes/templates/?industry_type=CNC_ENGINEERING")
        self.assertEqual(resp_filter.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_filter.data["count"], 1)
        self.assertEqual(resp_filter.data["results"][0]["key"], "cnc_precision_machining")

        # 2. Invalid industry_type filter returns 400
        resp_invalid = self.client.get("/api/processes/templates/?industry_type=INVALID_SECTOR_999")
        self.assertEqual(resp_invalid.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(resp_invalid.data["success"])
        self.assertIn("Invalid industry_type", resp_invalid.data["error"]["message"])

        # 3. Category search filter
        resp_cat = self.client.get("/api/processes/templates/?category=electronics")
        self.assertEqual(resp_cat.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_cat.data["count"], 1)
        self.assertEqual(resp_cat.data["results"][0]["key"], "electronics_smt_pcba")

    # ==========================================================================
    # 2. TEMPLATE INSTANTIATION TESTS
    # ==========================================================================

    def test_template_instantiate_success(self):
        """POST /api/processes/templates/<key>/instantiate/ creates full valid graph in factory."""
        resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {
                "factory": str(self.factory1.id),
                "name": "Alpha Cell 5-Axis Milling",
                "code": "PRC-CNC-ALPHA-01",
            },
            format="json"
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertTrue(resp.data["success"])
        proc_data = resp.data["data"]

        proc = ProcessDefinition.objects.get(id=proc_data["id"])
        self.assertEqual(proc.name, "Alpha Cell 5-Axis Milling")
        self.assertEqual(proc.code, "PRC-CNC-ALPHA-01")
        self.assertEqual(proc.factory_id, self.factory1.id)
        self.assertEqual(proc.industry_type, IndustryType.CNC_ENGINEERING)
        self.assertTrue(proc.is_active)

        # Verify draft version
        self.assertEqual(proc.versions.count(), 1)
        v1 = proc.versions.first()
        self.assertEqual(v1.status, "DRAFT")
        self.assertFalse(v1.is_published)
        self.assertEqual(v1.version_number, 1)

        # Verify nodes and metadata survived
        self.assertEqual(v1.nodes.count(), 6)
        self.assertEqual(v1.edges.count(), 5)
        rough_node = v1.nodes.get(node_key="OP-ROUGH-01")
        self.assertEqual(rough_node.setup_time_seconds, 600.0)
        self.assertEqual(rough_node.cycle_time_seconds, 180.0)
        self.assertEqual(rough_node.operator_role, "CNC Machinist Level 1")
        self.assertIn("3-Axis CNC Operation", rough_node.required_skills)

        # Verify quality gate exists
        cmm_node = v1.nodes.get(node_key="QG-CMM-03")
        self.assertEqual(cmm_node.node_type, "QUALITY_GATE")

        # Verify edge connectivity
        start_node = v1.nodes.get(node_key="START-01")
        first_edge = v1.edges.get(source_node=start_node)
        self.assertEqual(first_edge.target_node.node_key, "OP-ROUGH-01")

    def test_template_instantiate_parallel_split_join(self):
        """Instantiating EV battery template correctly constructs and links parallel branches."""
        resp = self.client.post(
            "/api/processes/templates/ev_battery_module_assembly/instantiate/",
            {"factory": str(self.factory1.id)},
            format="json"
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        proc_id = resp.data["data"]["id"]
        proc = ProcessDefinition.objects.get(id=proc_id)
        v1 = proc.versions.first()

        split_node = v1.nodes.get(node_key="SPLIT-01")
        join_node = v1.nodes.get(node_key="JOIN-01")
        self.assertEqual(split_node.node_type, "PARALLEL_SPLIT")
        self.assertEqual(join_node.node_type, "PARALLEL_JOIN")

        # Verify outgoing branches from split
        split_out_edges = split_node.outgoing_edges.all()
        self.assertEqual(split_out_edges.count(), 2)

        # Verify incoming branches to join
        join_in_edges = join_node.incoming_edges.all()
        self.assertEqual(join_in_edges.count(), 2)

    def test_template_instantiate_errors(self):
        """Unknown template, missing factory, or duplicate code returns appropriate errors."""
        # 1. Unknown template
        resp_404 = self.client.post(
            "/api/processes/templates/unknown_future_template/instantiate/",
            {"factory": str(self.factory1.id)},
            format="json"
        )
        self.assertEqual(resp_404.status_code, status.HTTP_404_NOT_FOUND)

        # 2. Missing factory
        resp_no_factory = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {},
            format="json"
        )
        self.assertEqual(resp_no_factory.status_code, status.HTTP_400_BAD_REQUEST)

        # 3. Duplicate code conflict
        self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "code": "UNIQUE-CODE-01"},
            format="json"
        )
        resp_dup_code = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "code": "UNIQUE-CODE-01"},
            format="json"
        )
        self.assertEqual(resp_dup_code.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already exists", resp_dup_code.data["error"]["message"])

    # ==========================================================================
    # 3. PROCESS DUPLICATION TESTS
    # ==========================================================================

    def test_process_duplication_success(self):
        """POST /api/processes/definitions/<id>/duplicate/ clones graph into new editable draft."""
        # Instantiate base process
        inst_resp = self.client.post(
            "/api/processes/templates/electronics_smt_pcba/instantiate/",
            {"factory": str(self.factory1.id), "name": "Motherboard Assembly Line 1", "code": "PRC-SMT-01"},
            format="json"
        )
        orig_id = inst_resp.data["data"]["id"]
        orig_proc = ProcessDefinition.objects.get(id=orig_id)

        # Publish original version
        orig_v1 = orig_proc.versions.first()
        pub_resp = self.client.post(f"/api/processes/versions/{orig_v1.id}/publish/")
        self.assertEqual(pub_resp.status_code, status.HTTP_200_OK)
        orig_v1.refresh_from_db()
        self.assertTrue(orig_v1.is_published)

        # Duplicate process
        dup_resp = self.client.post(
            f"/api/processes/definitions/{orig_id}/duplicate/",
            {"name": "Motherboard Assembly Line 2", "code": "PRC-SMT-02"},
            format="json"
        )
        self.assertEqual(dup_resp.status_code, status.HTTP_201_CREATED)
        self.assertTrue(dup_resp.data["success"])
        dup_data = dup_resp.data["data"]

        dup_proc = ProcessDefinition.objects.get(id=dup_data["id"])
        self.assertEqual(dup_proc.name, "Motherboard Assembly Line 2")
        self.assertEqual(dup_proc.code, "PRC-SMT-02")
        self.assertEqual(dup_proc.factory_id, self.factory1.id)
        self.assertTrue(dup_proc.is_active)

        # Original process and version remain unchanged and published
        orig_proc.refresh_from_db()
        orig_v1.refresh_from_db()
        self.assertTrue(orig_v1.is_published)
        self.assertEqual(orig_v1.status, "PUBLISHED")

        # Duplicated process version is in DRAFT
        dup_v1 = dup_proc.versions.first()
        self.assertEqual(dup_v1.status, "DRAFT")
        self.assertFalse(dup_v1.is_published)

        # Nodes and edges count match but have different IDs
        self.assertEqual(dup_v1.nodes.count(), orig_v1.nodes.count())
        self.assertEqual(dup_v1.edges.count(), orig_v1.edges.count())

        orig_node_ids = set(orig_v1.nodes.values_list("id", flat=True))
        dup_node_ids = set(dup_v1.nodes.values_list("id", flat=True))
        self.assertEqual(len(orig_node_ids.intersection(dup_node_ids)), 0)

        # Edge references point to the new nodes
        for edge in dup_v1.edges.all():
            self.assertIn(edge.source_node_id, dup_node_ids)
            self.assertIn(edge.target_node_id, dup_node_ids)

    def test_duplication_does_not_copy_work_orders(self):
        """Duplicating a process never clones work orders or execution history."""
        inst_resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "code": "PRC-CNC-WO-TEST"},
            format="json"
        )
        proc_id = inst_resp.data["data"]["id"]
        proc = ProcessDefinition.objects.get(id=proc_id)
        v1 = proc.versions.first()
        self.client.post(f"/api/processes/versions/{v1.id}/publish/")

        # Create work order against original process
        wo = ProductionExecutionService.create_work_order(
            factory=self.factory1,
            order_number="WO-ORIG-001",
            product=self.product1,
            process_definition=proc,
            quantity_target=50,
            status="RELEASED",
        )
        self.assertEqual(WorkOrder.objects.filter(process_definition=proc).count(), 1)

        # Duplicate process
        dup_resp = self.client.post(f"/api/processes/definitions/{proc_id}/duplicate/")
        self.assertEqual(dup_resp.status_code, status.HTTP_201_CREATED)
        dup_id = dup_resp.data["data"]["id"]
        dup_proc = ProcessDefinition.objects.get(id=dup_id)

        # Duplicated process must have 0 work orders
        self.assertEqual(WorkOrder.objects.filter(process_definition=dup_proc).count(), 0)

    # ==========================================================================
    # 4. SAFE ARCHIVING TESTS
    # ==========================================================================

    def test_archive_success_and_idempotency(self):
        """POST /api/processes/definitions/<id>/archive/ marks process is_active=False non-destructively."""
        inst_resp = self.client.post(
            "/api/processes/templates/textile_yarn_weaving/instantiate/",
            {"factory": str(self.factory1.id), "code": "PRC-TEXT-ARCH"},
            format="json"
        )
        proc_id = inst_resp.data["data"]["id"]
        proc = ProcessDefinition.objects.get(id=proc_id)
        self.assertTrue(proc.is_active)

        # Archive process
        arc_resp1 = self.client.post(f"/api/processes/definitions/{proc_id}/archive/")
        self.assertEqual(arc_resp1.status_code, status.HTTP_200_OK)
        self.assertTrue(arc_resp1.data["success"])
        proc.refresh_from_db()
        self.assertFalse(proc.is_active)

        # Verify draft version was marked ARCHIVED
        draft_ver = proc.versions.first()
        self.assertEqual(draft_ver.status, "ARCHIVED")

        # Verify idempotency on second call
        arc_resp2 = self.client.post(f"/api/processes/definitions/{proc_id}/archive/")
        self.assertEqual(arc_resp2.status_code, status.HTTP_200_OK)
        self.assertIn("already archived", arc_resp2.data["message"])

    def test_archive_blocked_by_active_work_order(self):
        """Archiving is blocked with 409 Conflict if active work orders (RELEASED, IN_PROGRESS, PAUSED) exist."""
        inst_resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "code": "PRC-BLOCK-ARCH"},
            format="json"
        )
        proc_id = inst_resp.data["data"]["id"]
        proc = ProcessDefinition.objects.get(id=proc_id)
        v1 = proc.versions.first()
        self.client.post(f"/api/processes/versions/{v1.id}/publish/")

        # Create active work order
        wo = ProductionExecutionService.create_work_order(
            factory=self.factory1,
            order_number="WO-ACTIVE-001",
            product=self.product1,
            process_definition=proc,
            quantity_target=100,
            status="RELEASED",
        )

        # Attempt to archive while work order is active
        arc_resp = self.client.post(f"/api/processes/definitions/{proc_id}/archive/")
        self.assertEqual(arc_resp.status_code, status.HTTP_409_CONFLICT)
        self.assertFalse(arc_resp.data["success"])
        self.assertEqual(arc_resp.data["error"]["code"], "ACTIVE_WORK_ORDERS_EXIST")
        self.assertIn("WO-ACTIVE-001", arc_resp.data["error"]["message"])

        # Complete the work order
        wo.status = "COMPLETED"
        wo.save(update_fields=["status"])

        # Archiving now succeeds
        arc_resp_after = self.client.post(f"/api/processes/definitions/{proc_id}/archive/")
        self.assertEqual(arc_resp_after.status_code, status.HTTP_200_OK)
        proc.refresh_from_db()
        self.assertFalse(proc.is_active)

        # Creating new work order against archived process definition is rejected
        with self.assertRaises(ValueError) as ctx:
            ProductionExecutionService.create_work_order(
                factory=self.factory1,
                order_number="WO-SHOULD-FAIL",
                product=self.product1,
                process_definition=proc,
                quantity_target=50,
            )
        self.assertIn("inactive or archived", str(ctx.exception))

    # ==========================================================================
    # 5. TENANT ISOLATION & FACTORY AUTHORIZATION TESTS
    # ==========================================================================

    def test_instantiate_inactive_factory_rejected(self):
        """Instantiating into an inactive/archived factory returns 400 Bad Request."""
        inactive_factory = Factory.objects.create(
            organization=self.org,
            name="Archived Plant",
            code="FAC-ARCHIVED-99",
            industry_type=IndustryType.CNC_ENGINEERING,
            is_active=False,
        )
        resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(inactive_factory.id), "name": "Should Fail"},
            format="json",
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(resp.data["success"])
        self.assertIn("inactive or archived", resp.data["error"]["message"])

    def test_instantiate_cross_tenant_header_rejected(self):
        """Supplying a mismatched tenant organization header returns 403 Forbidden."""
        other_org = Organization.objects.create(name="Competitor Org", slug="competitor-org")
        resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "name": "Cross Tenant Attempt"},
            format="json",
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(resp.data["success"])
        self.assertIn("authorized organization context", resp.data["error"]["message"])

    def test_duplicate_cross_tenant_header_rejected(self):
        """Duplication with mismatched tenant organization header returns 403 Forbidden."""
        inst_resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "code": "PRC-CNC-DUP-AUTH"},
            format="json",
        )
        proc_id = inst_resp.data["data"]["id"]
        other_org = Organization.objects.create(name="Rival Org", slug="rival-org")

        resp = self.client.post(
            f"/api/processes/definitions/{proc_id}/duplicate/",
            {"name": "Unauthorized Duplicate"},
            format="json",
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(resp.data["success"])

    def test_archive_cross_tenant_header_rejected(self):
        """Archival with mismatched tenant organization header returns 403 Forbidden."""
        inst_resp = self.client.post(
            "/api/processes/templates/cnc_precision_machining/instantiate/",
            {"factory": str(self.factory1.id), "code": "PRC-CNC-ARC-AUTH"},
            format="json",
        )
        proc_id = inst_resp.data["data"]["id"]
        other_org = Organization.objects.create(name="Another Org", slug="another-org")

        resp = self.client.post(
            f"/api/processes/definitions/{proc_id}/archive/",
            HTTP_X_ORGANIZATION_ID=str(other_org.id),
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(resp.data["success"])

