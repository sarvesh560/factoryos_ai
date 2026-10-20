"""
FactoryOS AI — AI Advisor & Templates Tests
Phase 2: Universal Manufacturing Onboarding
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

class AIAdvisorTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_ai_suggestion_rule_based_mode(self):
        """
        Verify AI suggestion returns structured response with explicit rule-based labeling
        when no external LLM API key is present.
        """
        payload = {
            "prompt": "We manufacture automobile components using cutting, CNC machining, inspection, and packaging."
        }
        res = self.client.post("/api/onboarding/ai-suggest/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["success"])
        data = res.data["data"]

        # Explicit label assertion
        self.assertEqual(data["source"], "RULE_BASED_HEURISTIC")
        self.assertIn("Rule-based Smart Heuristic Mode", data["disclaimer"])
        self.assertTrue(data["confirmation_required"])

        # Check recommended configuration structure
        cfg = data["recommended_configuration"]
        self.assertIn("factory", cfg)
        self.assertIn("products", cfg)
        self.assertIn("raw_materials", cfg)
        self.assertIn("process_stages", cfg)
        self.assertIn("production_lines", cfg)
        self.assertIn("shifts", cfg)
        self.assertIn("target_kpis", cfg)

        self.assertEqual(cfg["factory"]["industry_type"], "AUTOMOTIVE")
        self.assertGreaterEqual(len(cfg["products"]), 2)
        self.assertGreaterEqual(len(cfg["process_stages"]), 4)

    def test_list_industry_templates(self):
        res = self.client.get("/api/onboarding/templates/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["success"])
        self.assertGreaterEqual(res.data["count"], 3)
        template_ids = [t["id"] for t in res.data["results"]]
        self.assertIn("automotive_ev", template_ids)
        self.assertIn("electronics_smt", template_ids)
        self.assertIn("custom_blank", template_ids)
