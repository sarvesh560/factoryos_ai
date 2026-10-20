#!/usr/bin/env python
"""
FactoryOS AI — Database Verification Script
Verifies all sample factories, production lines, and metric snapshots in the database.
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

backend_dir = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(backend_dir))
load_dotenv(backend_dir / ".env")

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
import django
django.setup()

from apps.factories.models import Factory, ProductionLine, FactoryMetricSnapshot, Organization

print("=" * 60)
print("FACTORYOS AI — DATABASE VERIFICATION REPORT")
print("=" * 60)

org_count = Organization.objects.count()
factory_count = Factory.objects.count()
line_count = ProductionLine.objects.count()
snapshot_count = FactoryMetricSnapshot.objects.count()

print(f"Total Organizations:      {org_count}")
print(f"Total Factories:          {factory_count}")
print(f"Total Production Lines:   {line_count}")
print(f"Total Telemetry Snapshots:{snapshot_count}")
print("-" * 60)

for f in Factory.objects.all():
    lines = f.production_lines.all()
    metrics = f.metric_snapshots.first()
    oee = metrics.overall_oee if metrics else 0.0
    print(f"\n[FACTORY] {f.name} ({f.code})")
    print(f"  Industry Domain: {f.get_industry_type_display()}")
    print(f"  Status:          {f.get_configuration_status_display()}")
    print(f"  Location:        {f.location}, {f.country}")
    print(f"  OEE Rating:      {oee}%")
    print(f"  Production Lines ({lines.count()} cells):")
    for line in lines:
        prod = line.current_product if line.current_product else "Idle/Scheduled"
        print(f"    - [{line.code}] {line.name:<45} | Status: {line.get_status_display():<11} | Eff: {line.efficiency_rate:>5.1f}% | Out: {line.actual_hourly_units}/{line.target_hourly_units} u/h")

print("\n" + "=" * 60)
if factory_count >= 3 and line_count >= 18:
    print(f"VERIFICATION SUCCESS: All seeded factories preserved ({factory_count} factories, {line_count} production lines verified)!")
    sys.exit(0)
else:
    print(f"VERIFICATION WARNING: Expected at least 3 factories & 18 lines, found {factory_count} & {line_count}.")
    sys.exit(1)
