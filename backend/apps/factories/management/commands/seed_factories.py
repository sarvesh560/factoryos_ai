"""
FactoryOS AI — Idempotent Factory Seed Command
Seeds 3 simulated industrial manufacturing facilities:
1. Textile Manufacturing (Spinning, Weaving, Dyeing, Inspection)
2. CNC Engineering (Milling, Lathe, EDM, Metrology)
3. Food Processing (Bottling, Vacuum Sealing, Pasteurization, Cold Chain)
"""
from datetime import date
from django.core.management.base import BaseCommand
from django.db import transaction
from apps.factories.models import (
    Organization,
    Factory,
    ProductionLine,
    FactoryMetricSnapshot,
    IndustryType,
    ConfigurationStatus,
    LineStatus,
)

class Command(BaseCommand):
    help = "Idempotently seed 3 realistic industrial factories with lines and telemetry snapshots"

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Initializing FactoryOS AI simulated factory seed..."))

        with transaction.atomic():
            # 1. Root Enterprise Organization
            org, _ = Organization.objects.update_or_create(
                slug="universal-automation-corp",
                defaults={
                    "name": "Universal Manufacturing Global Corp",
                    "description": "Enterprise industrial automation holding operating multi-sector smart factories.",
                },
            )

            # 2. Factory Data Specifications
            factories_data = [
                {
                    "name": "Apex Precision Textiles",
                    "code": "FAC-TEX-01",
                    "industry_type": IndustryType.TEXTILE,
                    "configuration_status": ConfigurationStatus.CONFIGURED,
                    "location": "Greensboro Manufacturing Park, NC",
                    "country": "United States",
                    "timezone": "America/New_York",
                    "total_production_lines": 6,
                    "active_lines": 5,
                    "metadata": {
                        "primary_fiber": "Combed Cotton & Technical Synthetics",
                        "facility_sqm": 42000,
                        "certifications": ["ISO 9001", "OEKO-TEX Standard 100", "ISO 14001"],
                        "daily_target_meters": 75000,
                    },
                    "metrics": {
                        "overall_oee": 89.4,
                        "availability": 94.2,
                        "performance": 96.0,
                        "quality_rate": 98.8,
                        "energy_consumption_kwh": 3420.5,
                        "active_alerts_count": 2,
                        "active_shifts": 3,
                        "planned_units": 75000,
                        "actual_units": 72400,
                        "scrap_units": 850,
                    },
                    "lines": [
                        {
                            "code": "TEX-SPIN-01",
                            "name": "Automated Ring Spinning Frame A1",
                            "status": LineStatus.RUNNING,
                            "current_product": "30s Combed Cotton Yarn",
                            "efficiency_rate": 94.8,
                            "target_hourly_units": 450,
                            "actual_hourly_units": 438,
                            "operator_count": 2,
                        },
                        {
                            "code": "TEX-WEAV-02",
                            "name": "Air-Jet Weaving Loom Cell Alpha",
                            "status": LineStatus.RUNNING,
                            "current_product": "Twill High-Density Denim Weave",
                            "efficiency_rate": 91.2,
                            "target_hourly_units": 320,
                            "actual_hourly_units": 298,
                            "operator_count": 3,
                        },
                        {
                            "code": "TEX-DYE-03",
                            "name": "Continuous Dyeing & Finishing Range",
                            "status": LineStatus.RUNNING,
                            "current_product": "Indigo Reactive Dye 400gsm",
                            "efficiency_rate": 88.5,
                            "target_hourly_units": 600,
                            "actual_hourly_units": 542,
                            "operator_count": 4,
                        },
                        {
                            "code": "TEX-LOOM-04",
                            "name": "Jacquard High-Speed Weaving Unit",
                            "status": LineStatus.RUNNING,
                            "current_product": "Technical Structural Jacquard",
                            "efficiency_rate": 93.0,
                            "target_hourly_units": 280,
                            "actual_hourly_units": 264,
                            "operator_count": 2,
                        },
                        {
                            "code": "TEX-INSP-05",
                            "name": "AI Optical Fabric Inspection Line",
                            "status": LineStatus.RUNNING,
                            "current_product": "Automated Defect Scanning",
                            "efficiency_rate": 97.4,
                            "target_hourly_units": 800,
                            "actual_hourly_units": 788,
                            "operator_count": 1,
                        },
                        {
                            "code": "TEX-PACK-06",
                            "name": "Roll Packaging & Automatic Palletizer",
                            "status": LineStatus.MAINTENANCE,
                            "current_product": "Scheduled Seal Head Replacement",
                            "efficiency_rate": 0.0,
                            "target_hourly_units": 500,
                            "actual_hourly_units": 0,
                            "operator_count": 0,
                        },
                    ],
                },
                {
                    "name": "Vanguard Precision CNC",
                    "code": "FAC-CNC-02",
                    "industry_type": IndustryType.CNC_ENGINEERING,
                    "configuration_status": ConfigurationStatus.CONFIGURED,
                    "location": "Stuttgart Industrial High-Tech Corridor",
                    "country": "Germany",
                    "timezone": "Europe/Berlin",
                    "total_production_lines": 8,
                    "active_lines": 7,
                    "metadata": {
                        "machining_tolerance": "± 0.002 mm",
                        "facility_sqm": 28500,
                        "certifications": ["AS9100D", "ISO 13485", "IATF 16949"],
                        "daily_target_parts": 12500,
                    },
                    "metrics": {
                        "overall_oee": 92.8,
                        "availability": 96.5,
                        "performance": 97.2,
                        "quality_rate": 99.1,
                        "energy_consumption_kwh": 5180.2,
                        "active_alerts_count": 1,
                        "active_shifts": 3,
                        "planned_units": 12500,
                        "actual_units": 12150,
                        "scrap_units": 110,
                    },
                    "lines": [
                        {
                            "code": "CNC-MILL-01",
                            "name": "5-Axis High-Torque Milling Cell 01",
                            "status": LineStatus.RUNNING,
                            "current_product": "Titanium Turbine Impeller Blades",
                            "efficiency_rate": 96.2,
                            "target_hourly_units": 45,
                            "actual_hourly_units": 44,
                            "operator_count": 1,
                        },
                        {
                            "code": "CNC-LATHE-02",
                            "name": "Multi-Spindle Swiss Turning Center",
                            "status": LineStatus.RUNNING,
                            "current_product": "Hydraulic Valve Spools (Medical)",
                            "efficiency_rate": 95.0,
                            "target_hourly_units": 120,
                            "actual_hourly_units": 116,
                            "operator_count": 2,
                        },
                        {
                            "code": "CNC-ROBO-03",
                            "name": "Robotic Lathe Bank & Gantry Loader",
                            "status": LineStatus.RUNNING,
                            "current_product": "Aerospace Fastener Bushings",
                            "efficiency_rate": 93.8,
                            "target_hourly_units": 200,
                            "actual_hourly_units": 191,
                            "operator_count": 1,
                        },
                        {
                            "code": "CNC-EDM-04",
                            "name": "Wire Electrical Discharge Machine (EDM)",
                            "status": LineStatus.RUNNING,
                            "current_product": "Extrusion Die Tooling Steels",
                            "efficiency_rate": 91.5,
                            "target_hourly_units": 15,
                            "actual_hourly_units": 14,
                            "operator_count": 1,
                        },
                        {
                            "code": "CNC-CMM-05",
                            "name": "Zeiss High-Precision CMM Metrology Line",
                            "status": LineStatus.RUNNING,
                            "current_product": "Automated 3D Geometric Verification",
                            "efficiency_rate": 99.2,
                            "target_hourly_units": 150,
                            "actual_hourly_units": 149,
                            "operator_count": 2,
                        },
                        {
                            "code": "CNC-GRIND-06",
                            "name": "Centerless Cylindrical Grinding Line",
                            "status": LineStatus.RUNNING,
                            "current_product": "Hardened Drive Shaft Pins",
                            "efficiency_rate": 89.4,
                            "target_hourly_units": 300,
                            "actual_hourly_units": 272,
                            "operator_count": 2,
                        },
                        {
                            "code": "CNC-HEAT-07",
                            "name": "Vacuum Heat Treatment & Quench Cell",
                            "status": LineStatus.RUNNING,
                            "current_product": "Inconel 718 Stress Relieving",
                            "efficiency_rate": 94.0,
                            "target_hourly_units": 80,
                            "actual_hourly_units": 77,
                            "operator_count": 2,
                        },
                        {
                            "code": "CNC-ASSY-08",
                            "name": "Robotic Ultrasonic Clean & Laser Etch",
                            "status": LineStatus.IDLE,
                            "current_product": "Waiting for Batch 4492 Clearance",
                            "efficiency_rate": 0.0,
                            "target_hourly_units": 250,
                            "actual_hourly_units": 0,
                            "operator_count": 1,
                        },
                    ],
                },
                {
                    "name": "Nordic Pure BioFoods",
                    "code": "FAC-FOOD-03",
                    "industry_type": IndustryType.FOOD_PROCESSING,
                    "configuration_status": ConfigurationStatus.CONFIGURED,
                    "location": "Odense Clean Agro-Tech Cluster",
                    "country": "Denmark",
                    "timezone": "Europe/Copenhagen",
                    "total_production_lines": 4,
                    "active_lines": 4,
                    "metadata": {
                        "cleanroom_grade": "ISO Class 5 (Aseptic Zone)",
                        "facility_sqm": 36000,
                        "certifications": ["BRCGS Food Safety Grade AA+", "IFS Food v8", "HACCP Certified"],
                        "daily_target_liters": 180000,
                    },
                    "metrics": {
                        "overall_oee": 86.8,
                        "availability": 91.0,
                        "performance": 95.8,
                        "quality_rate": 99.6,
                        "energy_consumption_kwh": 2890.0,
                        "active_alerts_count": 0,
                        "active_shifts": 2,
                        "planned_units": 90000,
                        "actual_units": 87200,
                        "scrap_units": 320,
                    },
                    "lines": [
                        {
                            "code": "FOOD-PAST-01",
                            "name": "Ultra-High Temperature (UHT) Flash Pasteurizer",
                            "status": LineStatus.RUNNING,
                            "current_product": "Organic Oat Milk Base 1000L/hr",
                            "efficiency_rate": 94.2,
                            "target_hourly_units": 650,
                            "actual_hourly_units": 620,
                            "operator_count": 2,
                        },
                        {
                            "code": "FOOD-BOTT-02",
                            "name": "Aseptic Rotary Liquid Bottling Line",
                            "status": LineStatus.RUNNING,
                            "current_product": "1.0L Eco-Bio Glass Bottles",
                            "efficiency_rate": 91.8,
                            "target_hourly_units": 1200,
                            "actual_hourly_units": 1115,
                            "operator_count": 3,
                        },
                        {
                            "code": "FOOD-SEAL-03",
                            "name": "Nitrogen-Flush Vacuum Pouching Cell",
                            "status": LineStatus.RUNNING,
                            "current_product": "Freeze-Dried Superfood Powders",
                            "efficiency_rate": 88.0,
                            "target_hourly_units": 850,
                            "actual_hourly_units": 765,
                            "operator_count": 2,
                        },
                        {
                            "code": "FOOD-COLD-04",
                            "name": "Automated Cold-Chain Palletizer & Wrapper",
                            "status": LineStatus.RUNNING,
                            "current_product": "Controlled 4°C Distribution Pallets",
                            "efficiency_rate": 96.5,
                            "target_hourly_units": 400,
                            "actual_hourly_units": 389,
                            "operator_count": 1,
                        },
                    ],
                },
            ]

            for fdata in factories_data:
                factory, created = Factory.objects.update_or_create(
                    code=fdata["code"],
                    defaults={
                        "organization": org,
                        "name": fdata["name"],
                        "industry_type": fdata["industry_type"],
                        "factory_type": fdata.get("factory_type", "PRIMARY_MANUFACTURING"),
                        "manufacturing_model": fdata.get("manufacturing_model", "DISCRETE"),
                        "configuration_status": fdata["configuration_status"],
                        "location": fdata["location"],
                        "country": fdata["country"],
                        "timezone": fdata["timezone"],
                        "total_production_lines": fdata["total_production_lines"],
                        "active_lines": fdata["active_lines"],
                        "is_active": True,
                        "metadata": fdata["metadata"],
                    },
                )
                action = "Created" if created else "Updated"
                self.stdout.write(self.style.SUCCESS(f"  [{action}] Factory: {factory.name} ({factory.code})"))

                # Seed production lines
                for ldata in fdata["lines"]:
                    line, lcreated = ProductionLine.objects.update_or_create(
                        factory=factory,
                        code=ldata["code"],
                        defaults={
                            "name": ldata["name"],
                            "department": ldata.get("department", "General Production"),
                            "status": ldata["status"],
                            "current_product": ldata["current_product"],
                            "efficiency_rate": ldata["efficiency_rate"],
                            "target_hourly_units": ldata["target_hourly_units"],
                            "actual_hourly_units": ldata["actual_hourly_units"],
                            "operator_count": ldata["operator_count"],
                            "last_maintenance_date": date.today(),
                            "metadata": {},
                        },
                    )

                # Seed telemetry metrics snapshot
                m = fdata["metrics"]
                FactoryMetricSnapshot.objects.update_or_create(
                    factory=factory,
                    overall_oee=m["overall_oee"],
                    defaults={
                        "availability": m["availability"],
                        "performance": m["performance"],
                        "quality_rate": m["quality_rate"],
                        "energy_consumption_kwh": m["energy_consumption_kwh"],
                        "active_alerts_count": m["active_alerts_count"],
                        "active_shifts": m["active_shifts"],
                        "planned_units": m["planned_units"],
                        "actual_units": m["actual_units"],
                        "scrap_units": m["scrap_units"],
                    },
                )

        self.stdout.write(self.style.SUCCESS("All 3 industrial factories successfully seeded idempotently into PostgreSQL."))
