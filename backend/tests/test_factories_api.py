"""
FactoryOS AI — Factory API & Overview Automated Tests
"""
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.factories.models import (
    Organization,
    Factory,
    ProductionLine,
    FactoryMetricSnapshot,
    IndustryType,
    ConfigurationStatus,
    LineStatus,
)

class FactoryAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(
            name="Test Industrial Corp",
            slug="test-industrial-corp",
        )
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Test CNC Facility",
            code="TEST-CNC-01",
            industry_type=IndustryType.CNC_ENGINEERING,
            configuration_status=ConfigurationStatus.CONFIGURED,
            location="Test City",
            total_production_lines=2,
            active_lines=2,
        )
        self.line1 = ProductionLine.objects.create(
            factory=self.factory,
            name="Milling Center A",
            code="LINE-A",
            status=LineStatus.RUNNING,
            efficiency_rate=95.0,
            target_hourly_units=100,
            actual_hourly_units=95,
        )
        self.line2 = ProductionLine.objects.create(
            factory=self.factory,
            name="Turning Center B",
            code="LINE-B",
            status=LineStatus.IDLE,
            efficiency_rate=0.0,
            target_hourly_units=50,
            actual_hourly_units=0,
        )
        self.metrics = FactoryMetricSnapshot.objects.create(
            factory=self.factory,
            overall_oee=92.5,
            availability=95.0,
            performance=97.0,
            quality_rate=99.5,
            energy_consumption_kwh=1200.0,
            active_alerts_count=1,
            planned_units=1000,
            actual_units=980,
            scrap_units=5,
        )

    def test_factory_list(self):
        url = reverse("factory-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertGreaterEqual(data["count"], 1)
        found = any(f["code"] == "TEST-CNC-01" for f in data["results"])
        self.assertTrue(found)

    def test_factory_list_filter_industry(self):
        url = f"{reverse('factory-list')}?industry_type=CNC_ENGINEERING"
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        for f in data["results"]:
            self.assertEqual(f["industry_type"], "CNC_ENGINEERING")

    def test_factory_detail(self):
        url = reverse("factory-detail", kwargs={"pk": self.factory.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["data"]["code"], "TEST-CNC-01")
        self.assertEqual(len(data["data"]["production_lines"]), 2)
        self.assertIsNotNone(data["data"]["latest_metrics"])
        self.assertEqual(data["data"]["latest_metrics"]["overall_oee"], 92.5)

    def test_factory_overview(self):
        url = reverse("factory-overview", kwargs={"pk": self.factory.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        overview = data["data"]
        self.assertEqual(overview["lines_summary"]["total"], 2)
        self.assertEqual(overview["lines_summary"]["running"], 1)
        self.assertEqual(overview["lines_summary"]["idle"], 1)
        self.assertEqual(overview["metrics"]["overall_oee"], 92.5)
        self.assertIn("shift_progress", overview)
        self.assertEqual(overview["shift_progress"]["planned_units"], 1000)

    def test_factory_detail_not_found_structured_error(self):
        import uuid
        random_id = uuid.uuid4()
        url = reverse("factory-detail", kwargs={"pk": random_id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        data = response.json()
        self.assertFalse(data["success"])
        self.assertIn("error", data)
        self.assertEqual(data["error"]["code"], "NOT_FOUND")
