"""
FactoryOS AI — Factory Management Tests
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, IndustryType

class FactoryManagementTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Apex Enterprises", slug="apex-ent")
        self.factory = Factory.objects.create(
            organization=self.org,
            name="Apex Assembly Center",
            code="FAC-ASSEM-01",
            industry_type=IndustryType.AUTOMOTIVE,
            location="Detroit, MI",
            operating_hours="06:00 - 22:00",
            capabilities=["Robotic Welding", "Vision Metrology"],
            target_daily_capacity=2000,
            is_active=True,
        )

    def test_update_factory_capabilities_and_hours(self):
        payload = {
            "operating_hours": "24/7 Continuous (3 Shifts)",
            "capabilities": ["Robotic Welding", "Vision Metrology", "Laser Etching", "Cleanroom Packing"],
            "target_daily_capacity": 4500,
        }
        res = self.client.patch(f"/api/factories/{self.factory.id}/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.factory.refresh_from_db()
        self.assertEqual(self.factory.operating_hours, "24/7 Continuous (3 Shifts)")
        self.assertIn("Cleanroom Packing", self.factory.capabilities)
        self.assertEqual(self.factory.target_daily_capacity, 4500)

    def test_archive_factory(self):
        # Archive
        res = self.client.post(f"/api/factories/{self.factory.id}/archive/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.factory.refresh_from_db()
        self.assertFalse(self.factory.is_active)

        # Default list excludes archived
        list_res = self.client.get("/api/factories/")
        self.assertEqual(list_res.data["count"], 0)

        # List with include_archived=true
        archived_res = self.client.get("/api/factories/?include_archived=true")
        self.assertEqual(archived_res.data["count"], 1)

        # Unarchive
        res2 = self.client.post(f"/api/factories/{self.factory.id}/archive/")
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.factory.refresh_from_db()
        self.assertTrue(self.factory.is_active)
