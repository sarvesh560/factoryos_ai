"""
FactoryOS AI — Company / Organization Management Tests
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import Organization, Factory, IndustryType

class CompanyManagementTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org1 = Organization.objects.create(
            name="Apex Global Holdings",
            slug="apex-global-holdings",
            description="Global multi-sector manufacturing group",
            website="https://apexholdings.example.com",
            contact_email="ops@apexholdings.example.com",
            is_active=True,
        )
        self.factory1 = Factory.objects.create(
            organization=self.org1,
            name="Apex Textile Plant 1",
            code="FAC-APEX-01",
            industry_type=IndustryType.TEXTILE,
            location="Greensboro, NC",
        )
        self.factory2 = Factory.objects.create(
            organization=self.org1,
            name="Apex Precision CNC 2",
            code="FAC-APEX-02",
            industry_type=IndustryType.CNC_ENGINEERING,
            location="Stuttgart, Germany",
        )

    def test_list_companies(self):
        res = self.client.get("/api/companies/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["success"])
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["name"], "Apex Global Holdings")
        self.assertEqual(res.data["results"][0]["factory_count"], 2)

    def test_create_company(self):
        payload = {
            "name": "Nordic BioFoods Corp",
            "description": "Clean agro-processing and sustainable nutrition",
            "website": "https://nordicbiofoods.example.com",
            "contact_email": "info@nordicbiofoods.example.com",
        }
        res = self.client.post("/api/companies/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data["success"])
        self.assertEqual(res.data["data"]["name"], "Nordic BioFoods Corp")
        self.assertTrue(Organization.objects.filter(name="Nordic BioFoods Corp").exists())

    def test_update_company(self):
        payload = {
            "description": "Updated global manufacturing strategy",
            "website": "https://apex-updated.example.com",
        }
        res = self.client.patch(f"/api/companies/{self.org1.id}/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.org1.refresh_from_db()
        self.assertEqual(self.org1.description, "Updated global manufacturing strategy")
        self.assertEqual(self.org1.website, "https://apex-updated.example.com")

    def test_archive_and_unarchive_company(self):
        # Archive
        res = self.client.post(f"/api/companies/{self.org1.id}/archive/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.org1.refresh_from_db()
        self.assertFalse(self.org1.is_active)

        # Default list excludes archived
        list_res = self.client.get("/api/companies/")
        self.assertEqual(list_res.data["count"], 0)

        # List with include_archived=true
        archived_res = self.client.get("/api/companies/?include_archived=true")
        self.assertEqual(archived_res.data["count"], 1)

        # Unarchive
        res2 = self.client.post(f"/api/companies/{self.org1.id}/archive/")
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.org1.refresh_from_db()
        self.assertTrue(self.org1.is_active)

    def test_list_company_factories(self):
        res = self.client.get(f"/api/companies/{self.org1.id}/factories/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)
        factory_codes = [f["code"] for f in res.data["results"]]
        self.assertIn("FAC-APEX-01", factory_codes)
        self.assertIn("FAC-APEX-02", factory_codes)
