"""
FactoryOS AI — Onboarding Activation Tests
Phase 2: Universal Manufacturing Onboarding
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.factories.models import (
    Organization,
    Factory,
    Product,
    RawMaterial,
    ProcessStage,
    ProductionLine,
    Machine,
    ShiftConfiguration,
    FactoryMetricSnapshot,
)
from apps.onboarding.models import OnboardingDraft, DraftStatus

class OnboardingActivationTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.draft = OnboardingDraft.objects.create(
            name="Munich EV Mobility Facility",
            current_step=8,
            ai_prompt="EV propulsion component line",
            wizard_data={},
        )

    def test_atomic_onboarding_activation(self):
        payload = {
            "draft_id": str(self.draft.id),
            "wizard_data": {
                "company": {
                    "name": "Bavaria Mobility Group",
                    "description": "Next-generation automotive e-mobility systems",
                    "website": "https://bavariamobility.example.com",
                    "contact_email": "ops@bavariamobility.example.com",
                },
                "factory": {
                    "name": "Munich EV Propulsion Center",
                    "code": "FAC-BAV-EV01",
                    "industry_type": "AUTOMOTIVE",
                    "industry_custom": "Electric Vehicle Powertrain",
                    "location": "Munich High-Tech Park, Germany",
                    "country": "Germany",
                    "timezone": "Europe/Berlin",
                    "operating_hours": "24/7 Continuous (3 Shifts)",
                    "target_daily_capacity": 4500,
                    "capabilities": ["Robotic Laser Welding", "5-Axis Milling", "Cleanroom Assembly"],
                },
                "products": [
                    {"name": "EV Inverter Power Module", "sku": "BAV-INV-01", "unit_of_measure": "units", "target_hourly_rate": 180},
                    {"name": "Stator Rotor Core Pack", "sku": "BAV-STAT-02", "unit_of_measure": "units", "target_hourly_rate": 140},
                ],
                "raw_materials": [
                    {"name": "Cast A356 Ingot", "code": "RAW-AL-356", "category": "Metals", "unit_of_measure": "kg", "safety_stock": 5000.0},
                    {"name": "Thermal Paste Gap Filler", "code": "RAW-THM-01", "category": "Chemicals", "unit_of_measure": "liters", "safety_stock": 800.0},
                ],
                "process_stages": [
                    {"sequence": 1, "name": "Billet Slicing & Roughing", "cycle_time_seconds": 45, "quality_check_required": False, "description": "Raw stock preparation"},
                    {"sequence": 2, "name": "5-Axis Precision Contouring", "cycle_time_seconds": 150, "quality_check_required": True, "description": "Tolerance milling"},
                    {"sequence": 3, "name": "Cleanroom Optical Metrology", "cycle_time_seconds": 60, "quality_check_required": True, "description": "Inline 3D verification"},
                ],
                "production_lines": [
                    {
                        "name": "EV Inverter High-Speed Cell 01",
                        "code": "LINE-INV-01",
                        "target_hourly_units": 180,
                        "operator_count": 3,
                        "machines": [
                            {"name": "Twin-Spindle 5-Axis CNC Mill", "code": "M-CNC-01", "machine_type": "CNC Mill", "rated_power_kw": 35.0, "stage_sequence": 2},
                            {"name": "Inline Laser 3D CMM", "code": "M-CMM-01", "machine_type": "Metrology", "rated_power_kw": 5.0, "stage_sequence": 3},
                        ]
                    }
                ],
                "shifts": [
                    {"name": "Early Shift", "start_time": "06:00", "end_time": "14:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 1500},
                    {"name": "Late Shift", "start_time": "14:00", "end_time": "22:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 1500},
                    {"name": "Night Shift", "start_time": "22:00", "end_time": "06:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 1500},
                ]
            }
        }

        res = self.client.post("/api/onboarding/activate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data["success"])

        # Verify Company created
        org = Organization.objects.get(name="Bavaria Mobility Group")
        self.assertEqual(org.contact_email, "ops@bavariamobility.example.com")

        # Verify Factory created with universal manufacturing attributes
        factory = Factory.objects.get(code="FAC-BAV-EV01")
        self.assertEqual(factory.name, "Munich EV Propulsion Center")
        self.assertEqual(factory.total_production_lines, 1)
        self.assertIn("Cleanroom Assembly", factory.capabilities)
        self.assertEqual(factory.factory_type, "PRIMARY_MANUFACTURING")
        self.assertEqual(factory.manufacturing_model, "DISCRETE")

        # Verify Products
        self.assertEqual(Product.objects.filter(factory=factory).count(), 2)

        # Verify Raw Materials
        self.assertEqual(RawMaterial.objects.filter(factory=factory).count(), 2)

        # Verify Process Stages
        self.assertEqual(ProcessStage.objects.filter(factory=factory).count(), 3)

        # Verify Production Lines & Machines
        self.assertEqual(ProductionLine.objects.filter(factory=factory).count(), 1)
        line = ProductionLine.objects.get(factory=factory, code="LINE-INV-01")
        self.assertEqual(Machine.objects.filter(production_line=line).count(), 2)
        self.assertEqual(line.department, "General Production")

        # Verify Shifts
        self.assertEqual(ShiftConfiguration.objects.filter(factory=factory).count(), 3)

        # Verify Initial Metric Snapshot for immediate Command Center display
        snapshot = FactoryMetricSnapshot.objects.filter(factory=factory).first()
        self.assertIsNotNone(snapshot)
        self.assertGreater(snapshot.overall_oee, 80.0)

        # Verify Draft status updated to ACTIVATED
        self.draft.refresh_from_db()
        self.assertEqual(self.draft.status, DraftStatus.ACTIVATED)

    def test_validation_fails_on_missing_company(self):
        payload = {
            "wizard_data": {
                "company": {"name": ""},
                "factory": {"name": "Test Factory"},
            }
        }
        res = self.client.post("/api/onboarding/activate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_prevent_duplicate_factory_name_in_company(self):
        # Create initial company and factory
        org = Organization.objects.create(name="Stuttgart Motors AG", slug="stuttgart-motors")
        Factory.objects.create(
            organization=org,
            name="Plant 01 Main",
            code="FAC-STG-01",
            industry_type="AUTOMOTIVE",
        )

        # Try to onboard another factory with the exact same name under the same company
        payload = {
            "wizard_data": {
                "company": {"id": str(org.id), "name": "Stuttgart Motors AG"},
                "factory": {
                    "name": "Plant 01 Main",
                    "industry_type": "AUTOMOTIVE",
                },
            }
        }
        res = self.client.post("/api/onboarding/activate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already exists", str(res.data))

    def test_prevent_activating_already_activated_draft(self):
        activated_draft = OnboardingDraft.objects.create(
            name="Completed Project",
            status=DraftStatus.ACTIVATED,
            current_step=8,
            wizard_data={},
        )
        payload = {
            "draft_id": str(activated_draft.id),
            "wizard_data": {
                "company": {"name": "Test Holding Corp"},
                "factory": {"name": "New Plant 99"},
            },
        }
        res = self.client.post("/api/onboarding/activate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already been activated", str(res.data))

    def test_prevent_duplicate_factory_code(self):
        org = Organization.objects.create(name="Nordic Industrial", slug="nordic-ind")
        Factory.objects.create(
            organization=org,
            name="Stockholm Plant",
            code="FAC-STOCK-01",
            industry_type="ELECTRONICS",
        )
        payload = {
            "wizard_data": {
                "company": {"name": "Different Company Corp"},
                "factory": {
                    "name": "Different Name",
                    "code": "FAC-STOCK-01",
                },
            }
        }
        res = self.client.post("/api/onboarding/activate/", payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already assigned", str(res.data))
