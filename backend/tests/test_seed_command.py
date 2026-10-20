"""
FactoryOS AI — Seed Command Idempotency Tests
"""
from io import StringIO
from django.test import TestCase
from django.core.management import call_command
from apps.factories.models import Factory, ProductionLine, FactoryMetricSnapshot, IndustryType

class SeedFactoriesCommandTests(TestCase):
    def test_seed_factories_idempotency(self):
        out = StringIO()
        # First call
        call_command("seed_factories", stdout=out)
        self.assertEqual(Factory.objects.count(), 3)
        self.assertEqual(
            Factory.objects.filter(industry_type=IndustryType.TEXTILE).count(), 1
        )
        self.assertEqual(
            Factory.objects.filter(industry_type=IndustryType.CNC_ENGINEERING).count(), 1
        )
        self.assertEqual(
            Factory.objects.filter(industry_type=IndustryType.FOOD_PROCESSING).count(), 1
        )
        initial_lines_count = ProductionLine.objects.count()
        self.assertEqual(initial_lines_count, 6 + 8 + 4)  # 18 lines total

        # Second call to verify idempotency
        out2 = StringIO()
        call_command("seed_factories", stdout=out2)
        self.assertEqual(Factory.objects.count(), 3)
        self.assertEqual(ProductionLine.objects.count(), initial_lines_count)
        self.assertEqual(FactoryMetricSnapshot.objects.count(), 3)
