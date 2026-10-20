"""
FactoryOS AI — Seed Process Workflows, Work Orders, & Simulation Scenarios
Phase 3: Universal Manufacturing Process Engine (UMPE) Idempotent Seeding
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.factories.models import Factory, Product, RawMaterial, ProductionLine, Machine
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    ProcessNode,
    ProcessEdge,
    WorkOrder,
    ProcessExecution,
    StageExecution,
    MaterialFlow,
    ProductionEvent,
    SimulationScenario,
)
from apps.processes.services.graph_validator import ProcessGraphValidator

class Command(BaseCommand):
    help = "Seeds universal manufacturing process graphs, work orders, and simulation scenarios."

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Seeding Universal Manufacturing Process Engine (UMPE) data..."))

        # 1. Apex Precision Textiles (FAC-TEX-01)
        tex_factory = Factory.objects.filter(code="FAC-TEX-01").first()
        if tex_factory:
            self._seed_textile_workflow(tex_factory)

        # 2. Vanguard Precision CNC (FAC-CNC-02)
        cnc_factory = Factory.objects.filter(code="FAC-CNC-02").first()
        if cnc_factory:
            self._seed_cnc_workflow(cnc_factory)

        # 3. Nordic Pure BioFoods (FAC-FOOD-03)
        food_factory = Factory.objects.filter(code="FAC-FOOD-03").first()
        if food_factory:
            self._seed_food_workflow(food_factory)

        self.stdout.write(self.style.SUCCESS("UMPE workflow seeding completed successfully!"))

    def _seed_textile_workflow(self, factory: Factory):
        self.stdout.write(f" -> Seeding workflow for '{factory.name}'...")

        # Product
        product, _ = Product.objects.get_or_create(
            factory=factory,
            sku="TEX-YARN-80S",
            defaults={
                "name": "Combed Ring-Spun Organic Cotton 80s",
                "description": "Spun Yarn (Nominal Cycle 25s)",
                "unit_of_measure": "kg",
                "target_hourly_rate": 450,
            }
        )

        # Raw Material
        raw_cotton, _ = RawMaterial.objects.get_or_create(
            factory=factory,
            code="MAT-COT-G4",
            defaults={
                "name": "Long-Staple Raw Cotton Bale Grade 4",
                "category": "Raw Fiber",
                "unit_of_measure": "kg",
                "current_stock": 15000.0,
                "safety_stock": 3000.0,
            }
        )

        # Process Definition
        proc, _ = ProcessDefinition.objects.get_or_create(
            factory=factory,
            code="PROC-TEX-01",
            defaults={
                "name": "High-Speed Ring Spinning & Weaving Flow",
                "description": "Continuous fiber carding, ring spinning, parallel AI optical inspection and air-jet weaving, finished on automatic cone winders.",
                "category": "Textile Manufacturing",
                "target_cycle_time_seconds": 25.0,
            }
        )

        # Version 1 (Published)
        v1, _ = ProcessVersion.objects.get_or_create(
            process_definition=proc,
            version_number=1,
            defaults={
                "version_tag": "v1.0.0",
                "status": "PUBLISHED",
                "is_published": True,
                "published_at": timezone.now(),
                "change_summary": "Production baseline with parallel weaving and optical inspection.",
                "graph_metadata": {"zoom": 1.0, "pan_x": 50, "pan_y": 50},
            }
        )

        # Nodes
        line_spin = factory.production_lines.filter(code="TEX-SPIN-01").first()
        line_weav = factory.production_lines.filter(code="TEX-WEAV-02").first()
        line_insp = factory.production_lines.filter(code="TEX-INSP-05").first()

        nodes_spec = [
            ("START-01", "Bale Infeed & Opening", "START", 100.0, 250.0, 0.0, None),
            ("CARD-01", "Automated Cotton Carding", "OPERATION", 320.0, 250.0, 15.0, line_spin),
            ("DRAW-01", "High-Speed Drawing & Leveling", "OPERATION", 540.0, 250.0, 20.0, line_spin),
            ("SPIN-01", "Ring Frame Spindle Twisting", "OPERATION", 760.0, 250.0, 30.0, line_spin),
            ("SPLIT-01", "Fabric Processing Fork", "PARALLEL_SPLIT", 980.0, 250.0, 5.0, None),
            ("WEAV-01", "Air-Jet Loom Weaving", "OPERATION", 1200.0, 150.0, 45.0, line_weav),
            ("INSP-01", "AI Optical Defect Scanning", "QUALITY_GATE", 1200.0, 350.0, 20.0, line_insp),
            ("JOIN-01", "Yarn & Fabric Merge Sync", "PARALLEL_JOIN", 1420.0, 250.0, 5.0, None),
            ("WIND-01", "Automatic Cone Winding & Pack", "OPERATION", 1640.0, 250.0, 25.0, line_weav),
            ("END-01", "Finished Goods Warehouse", "END", 1860.0, 250.0, 0.0, None),
        ]

        node_map = {}
        for key, name, ntype, x, y, cycle, line in nodes_spec:
            node, _ = ProcessNode.objects.get_or_create(
                process_version=v1,
                node_key=key,
                defaults={
                    "name": name,
                    "node_type": ntype,
                    "position_x": x,
                    "position_y": y,
                    "cycle_time_seconds": cycle,
                    "assigned_line": line,
                    "yield_rate_percent": 98.5 if ntype == "OPERATION" else 100.0,
                    "input_materials": [{"raw_material_id": str(raw_cotton.id), "quantity": 1.05, "unit": "kg"}] if key == "CARD-01" else [],
                }
            )
            node_map[key] = node

        # Edges
        edges_spec = [
            ("EDGE-01", "START-01", "CARD-01", "STANDARD"),
            ("EDGE-02", "CARD-01", "DRAW-01", "STANDARD"),
            ("EDGE-03", "DRAW-01", "SPIN-01", "STANDARD"),
            ("EDGE-04", "SPIN-01", "SPLIT-01", "STANDARD"),
            ("EDGE-05", "SPLIT-01", "WEAV-01", "STANDARD"),
            ("EDGE-06", "SPLIT-01", "INSP-01", "STANDARD"),
            ("EDGE-07", "WEAV-01", "JOIN-01", "STANDARD"),
            ("EDGE-08", "INSP-01", "JOIN-01", "STANDARD"),
            ("EDGE-09", "JOIN-01", "WIND-01", "STANDARD"),
            ("EDGE-10", "WIND-01", "END-01", "STANDARD"),
        ]

        for ekey, src_key, tgt_key, etype in edges_spec:
            ProcessEdge.objects.get_or_create(
                process_version=v1,
                edge_key=ekey,
                defaults={
                    "source_node": node_map[src_key],
                    "target_node": node_map[tgt_key],
                    "edge_type": etype,
                }
            )

        # Validate
        is_valid, errs, _ = ProcessGraphValidator.validate_version(v1)
        if not is_valid:
            self.stdout.write(self.style.WARNING(f"Validation errors for Textile graph: {errs}"))

        # Simulation Scenarios
        self._seed_scenarios(factory)

        # Active Work Order
        wo, _ = WorkOrder.objects.get_or_create(
            factory=factory,
            order_number="WO-TEX-2026-001",
            defaults={
                "product": product,
                "process_definition": proc,
                "process_version": v1,
                "assigned_line": line_spin,
                "quantity_target": 1200,
                "quantity_completed": 450,
                "quantity_scrapped": 12,
                "status": "IN_PROGRESS",
                "priority": "HIGH",
                "planned_start_date": timezone.now() - timezone.timedelta(hours=6),
                "planned_due_date": timezone.now() + timezone.timedelta(days=1),
                "actual_start_date": timezone.now() - timezone.timedelta(hours=6),
                "notes": "Rush commercial yarn order for seasonal apparel production.",
            }
        )

        # Process Execution & Stage Executions
        exec_run, _ = ProcessExecution.objects.get_or_create(
            work_order=wo,
            execution_number="EXEC-WO-TEX-2026-001-1",
            defaults={
                "process_version": v1,
                "mode": "SIMULATION",
                "status": "RUNNING",
                "started_at": timezone.now() - timezone.timedelta(hours=6),
                "current_progress_percent": 45.0,
                "total_units_input": 1200,
                "total_units_output": 450,
                "total_units_scrap": 12,
            }
        )

        for key, node in node_map.items():
            if key in ("START-01", "CARD-01", "DRAW-01"):
                st_status = "COMPLETED"
                units_comp = 1200
            elif key == "SPIN-01":
                st_status = "RUNNING"
                units_comp = 450
            else:
                st_status = "PENDING"
                units_comp = 0

            StageExecution.objects.get_or_create(
                process_execution=exec_run,
                node=node,
                defaults={
                    "status": st_status,
                    "units_queued": 1200 if st_status != "PENDING" else 0,
                    "units_in_progress": 750 if st_status == "RUNNING" else 0,
                    "units_completed": units_comp,
                    "units_scrapped": 12 if key == "CARD-01" else 0,
                    "started_at": timezone.now() - timezone.timedelta(hours=4) if st_status != "PENDING" else None,
                    "completed_at": timezone.now() - timezone.timedelta(hours=2) if st_status == "COMPLETED" else None,
                }
            )

        # Initial Events
        ProductionEvent.objects.get_or_create(
            factory=factory,
            work_order=wo,
            process_execution=exec_run,
            event_type="EXECUTION_STARTED",
            defaults={
                "severity": "INFO",
                "source": "SIMULATION",
                "message": f"Execution started for Work Order {wo.order_number}.",
            }
        )

    def _seed_cnc_workflow(self, factory: Factory):
        self.stdout.write(f" -> Seeding workflow for '{factory.name}'...")

        product, _ = Product.objects.get_or_create(
            factory=factory,
            sku="CNC-TURB-TI6",
            defaults={
                "name": "Titanium Ti-6Al-4V Blisk Rotor Disk",
                "description": "Aerospace Machining (Nominal Cycle 120s)",
                "unit_of_measure": "pcs",
                "target_hourly_rate": 30,
            }
        )

        raw_ti, _ = RawMaterial.objects.get_or_create(
            factory=factory,
            code="MAT-TI-B5",
            defaults={
                "name": "Titanium Forged Billet Stock Grade 5",
                "category": "Superalloys",
                "unit_of_measure": "kg",
                "current_stock": 8500.0,
                "safety_stock": 1500.0,
            }
        )

        proc, _ = ProcessDefinition.objects.get_or_create(
            factory=factory,
            code="PROC-CNC-01",
            defaults={
                "name": "5-Axis Aerospace Turbine Machining",
                "description": "Billet preparation, 5-axis DMG MORI high-torque milling, wire EDM profiling, Zeiss CMM metrology, and ultrasonic cleaning.",
                "category": "CNC Precision Engineering",
                "target_cycle_time_seconds": 120.0,
            }
        )

        v1, _ = ProcessVersion.objects.get_or_create(
            process_definition=proc,
            version_number=1,
            defaults={
                "version_tag": "v1.0.0",
                "status": "PUBLISHED",
                "is_published": True,
                "published_at": timezone.now(),
                "change_summary": "Validated aerospace precision machining process.",
                "graph_metadata": {"zoom": 1.0, "pan_x": 50, "pan_y": 50},
            }
        )

        line_mill = factory.production_lines.filter(code="CNC-MILL-01").first()
        line_edm = factory.production_lines.filter(code="CNC-EDM-04").first()
        line_cmm = factory.production_lines.filter(code="CNC-CMM-05").first()

        nodes_spec = [
            ("START-01", "Billet Infeed & Prep", "START", 100.0, 250.0, 0.0, None),
            ("FACE-01", "Billet Facing & Datum Milling", "OPERATION", 340.0, 250.0, 45.0, line_mill),
            ("MILL-01", "5-Axis Blade Airfoil Milling", "OPERATION", 580.0, 250.0, 180.0, line_mill),
            ("EDM-01", "Wire EDM Dovetail Profiling", "OPERATION", 820.0, 250.0, 90.0, line_edm),
            ("CMM-01", "Zeiss 3D Coordinate Metrology", "QUALITY_GATE", 1060.0, 250.0, 30.0, line_cmm),
            ("CLEAN-01", "Ultrasonic Wash & Laser Marking", "OPERATION", 1300.0, 250.0, 25.0, None),
            ("END-01", "Aerospace Finished Vault", "END", 1540.0, 250.0, 0.0, None),
        ]

        node_map = {}
        for key, name, ntype, x, y, cycle, line in nodes_spec:
            node, _ = ProcessNode.objects.get_or_create(
                process_version=v1,
                node_key=key,
                defaults={
                    "name": name,
                    "node_type": ntype,
                    "position_x": x,
                    "position_y": y,
                    "cycle_time_seconds": cycle,
                    "assigned_line": line,
                    "yield_rate_percent": 99.2,
                    "input_materials": [{"raw_material_id": str(raw_ti.id), "quantity": 18.5, "unit": "kg"}] if key == "FACE-01" else [],
                }
            )
            node_map[key] = node

        edges_spec = [
            ("EDGE-01", "START-01", "FACE-01", "STANDARD"),
            ("EDGE-02", "FACE-01", "MILL-01", "STANDARD"),
            ("EDGE-03", "MILL-01", "EDM-01", "STANDARD"),
            ("EDGE-04", "EDM-01", "CMM-01", "STANDARD"),
            ("EDGE-05", "CMM-01", "CLEAN-01", "STANDARD"),
            ("EDGE-06", "CLEAN-01", "END-01", "STANDARD"),
        ]

        for ekey, src_key, tgt_key, etype in edges_spec:
            ProcessEdge.objects.get_or_create(
                process_version=v1,
                edge_key=ekey,
                defaults={
                    "source_node": node_map[src_key],
                    "target_node": node_map[tgt_key],
                    "edge_type": etype,
                }
            )

        ProcessGraphValidator.validate_version(v1)
        self._seed_scenarios(factory)

        WorkOrder.objects.get_or_create(
            factory=factory,
            order_number="WO-CNC-2026-001",
            defaults={
                "product": product,
                "process_definition": proc,
                "process_version": v1,
                "assigned_line": line_mill,
                "quantity_target": 150,
                "quantity_completed": 60,
                "status": "IN_PROGRESS",
                "priority": "URGENT",
                "planned_start_date": timezone.now() - timezone.timedelta(hours=10),
                "planned_due_date": timezone.now() + timezone.timedelta(days=3),
                "actual_start_date": timezone.now() - timezone.timedelta(hours=10),
                "notes": "Turbine rotor batch for defense flight engine assembly.",
            }
        )

    def _seed_food_workflow(self, factory: Factory):
        self.stdout.write(f" -> Seeding workflow for '{factory.name}'...")

        product, _ = Product.objects.get_or_create(
            factory=factory,
            sku="FOOD-OAT-500",
            defaults={
                "name": "BioNordic Aseptic Oat Beverage 500ml",
                "description": "Organic Beverages (Nominal Cycle 3s)",
                "unit_of_measure": "pcs",
                "target_hourly_rate": 1200,
            }
        )

        proc, _ = ProcessDefinition.objects.get_or_create(
            factory=factory,
            code="PROC-FOOD-01",
            defaults={
                "name": "Aseptic Liquid Bottling & Pasteurization",
                "description": "Continuous aseptic UHT flash pasteurization, rotary liquid bottling, nitrogen-flush vacuum sealing, and cold-chain case packing.",
                "category": "Cleanroom Food & Beverage",
                "target_cycle_time_seconds": 3.0,
            }
        )

        v1, _ = ProcessVersion.objects.get_or_create(
            process_definition=proc,
            version_number=1,
            defaults={
                "version_tag": "v1.0.0",
                "status": "PUBLISHED",
                "is_published": True,
                "published_at": timezone.now(),
                "change_summary": "Sterile food packaging continuous workflow.",
                "graph_metadata": {"zoom": 1.0, "pan_x": 50, "pan_y": 50},
            }
        )

        line_past = factory.production_lines.filter(code="FOOD-PAST-01").first()
        line_bott = factory.production_lines.filter(code="FOOD-BOTT-02").first()
        line_seal = factory.production_lines.filter(code="FOOD-SEAL-03").first()
        line_cold = factory.production_lines.filter(code="FOOD-COLD-04").first()

        nodes_spec = [
            ("START-01", "Raw Formulation Infeed", "START", 100.0, 250.0, 0.0, None),
            ("PAST-01", "UHT Flash Pasteurization (135°C)", "OPERATION", 350.0, 250.0, 5.0, line_past),
            ("BOTT-01", "Aseptic Rotary Liquid Filling", "OPERATION", 600.0, 250.0, 3.0, line_bott),
            ("SEAL-01", "Vacuum Cap & Nitrogen Flush", "OPERATION", 850.0, 250.0, 2.5, line_seal),
            ("INSP-01", "X-Ray Seal & Foreign Body QC", "QUALITY_GATE", 1100.0, 250.0, 2.0, None),
            ("PACK-01", "Cold-Chain Palletizer & Wrap", "OPERATION", 1350.0, 250.0, 4.0, line_cold),
            ("END-01", "Refrigerated Distribution Dock", "END", 1600.0, 250.0, 0.0, None),
        ]

        node_map = {}
        for key, name, ntype, x, y, cycle, line in nodes_spec:
            node, _ = ProcessNode.objects.get_or_create(
                process_version=v1,
                node_key=key,
                defaults={
                    "name": name,
                    "node_type": ntype,
                    "position_x": x,
                    "position_y": y,
                    "cycle_time_seconds": cycle,
                    "assigned_line": line,
                    "yield_rate_percent": 99.8,
                }
            )
            node_map[key] = node

        edges_spec = [
            ("EDGE-01", "START-01", "PAST-01", "STANDARD"),
            ("EDGE-02", "PAST-01", "BOTT-01", "STANDARD"),
            ("EDGE-03", "BOTT-01", "SEAL-01", "STANDARD"),
            ("EDGE-04", "SEAL-01", "INSP-01", "STANDARD"),
            ("EDGE-05", "INSP-01", "PACK-01", "STANDARD"),
            ("EDGE-06", "PACK-01", "END-01", "STANDARD"),
        ]

        for ekey, src_key, tgt_key, etype in edges_spec:
            ProcessEdge.objects.get_or_create(
                process_version=v1,
                edge_key=ekey,
                defaults={
                    "source_node": node_map[src_key],
                    "target_node": node_map[tgt_key],
                    "edge_type": etype,
                }
            )

        ProcessGraphValidator.validate_version(v1)
        self._seed_scenarios(factory)

        WorkOrder.objects.get_or_create(
            factory=factory,
            order_number="WO-FOOD-2026-001",
            defaults={
                "product": product,
                "process_definition": proc,
                "process_version": v1,
                "assigned_line": line_bott,
                "quantity_target": 5000,
                "quantity_completed": 3400,
                "status": "IN_PROGRESS",
                "priority": "NORMAL",
                "planned_start_date": timezone.now() - timezone.timedelta(hours=4),
                "planned_due_date": timezone.now() + timezone.timedelta(hours=20),
                "actual_start_date": timezone.now() - timezone.timedelta(hours=4),
                "notes": "Export retail order for European organic grocery chains.",
            }
        )

    def _seed_scenarios(self, factory: Factory):
        scenarios = [
            ("MACHINE_BREAKDOWN", "Primary Spindle Motor Bearing Overheat", {"delay_seconds": 300}),
            ("MATERIAL_SHORTAGE", "Infeed Raw Material Stock Depletion", {"threshold": 50}),
            ("PRODUCTION_DELAY", "Manual Fixture Setup Cycle Inflation", {"delay_multiplier": 2.2}),
            ("QUALITY_REJECTION", "Airfoil Profile Surface Roughness Spike", {"scrap_units": 18}),
            ("BOTTLENECK_FORMATION", "Downstream Inspection Buffer Overflow", {"queue_limit": 25}),
        ]
        for stype, name, params in scenarios:
            SimulationScenario.objects.get_or_create(
                factory=factory,
                scenario_type=stype,
                defaults={
                    "name": name,
                    "parameters": params,
                    "random_seed": 42,
                    "is_active": True,
                }
            )
