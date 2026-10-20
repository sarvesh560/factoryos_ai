"""
FactoryOS AI — Phase 3 Step 2 Process Templates Tests
Tests discovery, schema validity, graph topology, and validator compliance across all 8 industry templates.
"""
from django.test import TestCase
from apps.factories.models import Organization, Factory, IndustryType
from apps.processes.models import ProcessDefinition, ProcessVersion, ProcessNode, ProcessEdge
from apps.processes.services.graph_validator import ProcessGraphValidator
from apps.processes.services.template_service import ProcessTemplateService, UNIVERSAL_PROCESS_TEMPLATES

class Step2ProcessTemplatesTests(TestCase):
    def setUp(self):
        self.org = Organization.objects.create(name="Template Test Org", slug="tpl-test-org")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Universal Demonstration Facility",
            code="FAC-TPL-01",
            industry_type=IndustryType.CUSTOM,
        )

    def test_discovery_and_count(self):
        """Verify all eight manufacturing templates are discoverable via ProcessTemplateService."""
        templates = ProcessTemplateService.get_templates()
        self.assertEqual(len(templates), 8)

        expected_keys = [
            "cnc_precision_machining",
            "ev_battery_module_assembly",
            "electronics_smt_pcba",
            "pharma_sterile_injectable",
            "food_beverage_aseptic_packaging",
            "textile_yarn_weaving",
            "chemical_batch_polymerization",
            "general_discrete_assembly",
        ]
        discovered_keys = [t["key"] for t in templates]
        for key in expected_keys:
            self.assertIn(key, discovered_keys)

    def test_zero_db_side_effects_on_listing(self):
        """Listing and retrieving templates must not create or modify any DB records."""
        initial_defs = ProcessDefinition.objects.count()
        initial_vers = ProcessVersion.objects.count()
        initial_nodes = ProcessNode.objects.count()

        _ = ProcessTemplateService.get_templates()
        _ = ProcessTemplateService.get_template_by_key("cnc_precision_machining")
        _ = ProcessTemplateService.get_template_by_key("ev_battery_module_assembly")

        self.assertEqual(ProcessDefinition.objects.count(), initial_defs)
        self.assertEqual(ProcessVersion.objects.count(), initial_vers)
        self.assertEqual(ProcessNode.objects.count(), initial_nodes)

    def test_unique_keys_and_valid_industry_types(self):
        """Every template must have a unique key, valid IndustryType enum value, and non-empty metadata."""
        valid_industries = set(IndustryType.values)
        seen_keys = set()

        for t in UNIVERSAL_PROCESS_TEMPLATES:
            key = t["key"]
            self.assertNotIn(key, seen_keys, f"Duplicate template key found: {key}")
            seen_keys.add(key)

            self.assertIn(
                t["industry_type"],
                valid_industries,
                f"Template '{key}' has invalid industry_type: {t['industry_type']}"
            )
            self.assertTrue(t["name"])
            self.assertTrue(t["description"])
            self.assertTrue(t["category"])
            self.assertGreater(t["target_cycle_time_seconds"], 0)

    def test_in_memory_graph_topology_validation(self):
        """Every template graph must pass internal in-memory MES graph validation."""
        for t in UNIVERSAL_PROCESS_TEMPLATES:
            is_valid, errors, warnings = ProcessTemplateService.validate_template_graph(t)
            self.assertTrue(
                is_valid,
                f"Template '{t['key']}' failed in-memory validation: {errors}"
            )
            self.assertEqual(len(errors), 0)

    def test_node_properties_and_skill_metadata(self):
        """Ensure operations have cycle time, setup time, operator roles, skills, and yield rates."""
        for t in UNIVERSAL_PROCESS_TEMPLATES:
            for node in t["nodes"]:
                self.assertTrue(node["node_key"])
                self.assertTrue(node["name"])
                self.assertIn(node["node_type"], [
                    "START", "OPERATION", "QUALITY_GATE", "PARALLEL_SPLIT", "PARALLEL_JOIN", "END"
                ])
                self.assertGreaterEqual(node["cycle_time_seconds"], 0.0)
                self.assertGreaterEqual(node["setup_time_seconds"], 0.0)
                self.assertGreaterEqual(node["yield_rate_percent"], 0.0)
                self.assertLessEqual(node["yield_rate_percent"], 100.0)
                self.assertIsInstance(node["required_skills"], list)

    def test_instantiation_passes_actual_graph_validator(self):
        """Instantiating each template into ProcessVersion passes the system's ProcessGraphValidator."""
        for t in UNIVERSAL_PROCESS_TEMPLATES:
            proc = ProcessDefinition.objects.create(
                factory=self.factory,
                name=t["name"],
                code=f"TPL-{t['key'][:10].upper()}",
                category=t["category"],
                industry_type=t["industry_type"],
                description=t["description"],
                target_cycle_time_seconds=t["target_cycle_time_seconds"],
            )
            ver = ProcessVersion.objects.create(
                process_definition=proc,
                version_number=1,
                version_tag="v1.0.0",
                status="DRAFT",
            )

            node_map = {}
            for n in t["nodes"]:
                node = ProcessNode.objects.create(
                    process_version=ver,
                    node_key=n["node_key"],
                    name=n["name"],
                    node_type=n["node_type"],
                    position_x=n["position_x"],
                    position_y=n["position_y"],
                    cycle_time_seconds=n["cycle_time_seconds"],
                    setup_time_seconds=n["setup_time_seconds"],
                    standard_capacity_per_hour=n["standard_capacity_per_hour"],
                    required_operators=n["required_operators"],
                    operator_role=n.get("operator_role", ""),
                    required_skills=n.get("required_skills", []),
                    yield_rate_percent=n.get("yield_rate_percent", 100.0),
                )
                node_map[n["node_key"]] = node

            for e in t["edges"]:
                ProcessEdge.objects.create(
                    process_version=ver,
                    edge_key=e["edge_key"],
                    source_node=node_map[e["source_key"]],
                    target_node=node_map[e["target_key"]],
                    edge_type=e.get("edge_type", "STANDARD"),
                    label=e.get("label", ""),
                )

            # Run actual system ProcessGraphValidator
            is_valid, errors, warnings = ProcessGraphValidator.validate_version(ver)
            self.assertTrue(
                is_valid,
                f"Template '{t['key']}' failed system ProcessGraphValidator: {errors}"
            )
            self.assertEqual(len(errors), 0)
