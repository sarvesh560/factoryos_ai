"""
FactoryOS AI — Industry Templates Registry
Phase 2: Universal Manufacturing Onboarding

Predefined starting templates across high-value industrial sectors.
Every field, process stage, and equipment specification remains 100% customizable.
"""

INDUSTRY_TEMPLATES = [
    {
        "id": "automotive_ev",
        "title": "Automotive & EV Powertrain",
        "industry_type": "AUTOMOTIVE",
        "industry_custom": "Electric Vehicle & Powertrain Manufacturing",
        "description": "High-volume automotive machining, robotic sub-assembly, stamping, and automated metrology.",
        "icon": "directions_car",
        "defaults": {
            "factory_name": "NextGen EV Propulsion Facility",
            "code_prefix": "EV-PWR",
            "factory_type": "PRIMARY_MANUFACTURING",
            "manufacturing_model": "DISCRETE",
            "location": "Detroit Metro Tech Corridor, MI, USA",
            "operating_hours": "24/7 Continuous (Three 8h Shifts)",
            "target_daily_capacity": 3600,
            "capabilities": ["5-Axis High-Torque Milling", "Robotic Laser Welding", "Zero-Defect Inline CMM", "Cleanroom Pack"],
            "products": [
                {"name": "EV Stator Core Rotor Assembly", "sku": "EV-STAT-80", "unit_of_measure": "units", "target_hourly_rate": 150},
                {"name": "Die-Cast Aluminum Battery Housing Tray", "sku": "EV-BATT-TR", "unit_of_measure": "units", "target_hourly_rate": 80},
                {"name": "Inverter Power Module Heat Sink", "sku": "EV-HSNK-12", "unit_of_measure": "units", "target_hourly_rate": 200},
            ],
            "raw_materials": [
                {"name": "Silicon Electrical Steel Lamination Sheets", "code": "RAW-STL-SIL", "category": "Metals", "unit_of_measure": "kg", "safety_stock": 15000.0},
                {"name": "Alloy 6061-T6 Extruded Aluminum Billet", "code": "RAW-AL-6061", "category": "Metals", "unit_of_measure": "kg", "safety_stock": 8000.0},
                {"name": "High-Thermal-Conductivity Gap Filler", "code": "RAW-GAP-THM", "category": "Chemicals", "unit_of_measure": "liters", "safety_stock": 1200.0},
            ],
            "process_stages": [
                {"sequence": 1, "name": "Precision High-Speed Stamping", "cycle_time_seconds": 15, "quality_check_required": True, "description": "Lamination stamping with burr height monitoring"},
                {"sequence": 2, "name": "Automated Core Interlocking & Stacking", "cycle_time_seconds": 45, "quality_check_required": True, "description": "Hydraulic skew stacking and epoxy bonding"},
                {"sequence": 3, "name": "5-Axis CNC Finish Milling", "cycle_time_seconds": 120, "quality_check_required": True, "description": "Bearing journal and stator housing tolerance milling"},
                {"sequence": 4, "name": "Robotic Laser Welding & Balancing", "cycle_time_seconds": 60, "quality_check_required": True, "description": "Fiber laser seam welding and dynamic spin balancing"},
                {"sequence": 5, "name": "End-of-Line Electrical & Optical Inspection", "cycle_time_seconds": 30, "quality_check_required": True, "description": "High-pot insulation testing and 3D optical profilometry"},
            ],
            "production_lines": [
                {
                    "name": "Stator Lamination & Assembly Line Alpha",
                    "code": "LINE-EV-01",
                    "department": "EV Powertrain & Stator Assembly",
                    "target_hourly_units": 150,
                    "machines": [
                        {"name": "300-Ton High-Speed Stamping Press", "code": "M-STAMP-300", "machine_type": "Press", "rated_power_kw": 45.0},
                        {"name": "Robotic Laser Seam Welder", "code": "M-ROB-LS-01", "machine_type": "Laser Welder", "rated_power_kw": 28.0},
                    ]
                },
                {
                    "name": "Battery Enclosure Machining Cell Beta",
                    "code": "LINE-EV-02",
                    "department": "Battery Enclosure Machining Bay",
                    "target_hourly_units": 100,
                    "machines": [
                        {"name": "Gantry 5-Axis Twin-Spindle Mill", "code": "M-GANT-01", "machine_type": "CNC Mill", "rated_power_kw": 55.0},
                        {"name": "Zeiss Inline Bridge Metrology CMM", "code": "M-CMM-INL", "machine_type": "Metrology", "rated_power_kw": 6.0},
                    ]
                }
            ],
            "shifts": [
                {"name": "Day Shift 1", "start_time": "06:00", "end_time": "14:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], "planned_capacity_units": 1200},
                {"name": "Swing Shift 2", "start_time": "14:00", "end_time": "22:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], "planned_capacity_units": 1200},
                {"name": "Graveyard Shift 3", "start_time": "22:00", "end_time": "06:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], "planned_capacity_units": 1200},
            ]
        }
    },
    {
        "id": "electronics_smt",
        "title": "Electronics & SMT Assembly",
        "industry_type": "ELECTRONICS",
        "industry_custom": "Surface Mount Technology & Micro-Assembly",
        "description": "High-density PCB printing, multi-chip placement, reflow soldering, and automated 3D optical inspection.",
        "icon": "memory",
        "defaults": {
            "factory_name": "OmniMicro High-Tech SMT Plant",
            "code_prefix": "SMT-MIC",
            "factory_type": "SUB_ASSEMBLY",
            "manufacturing_model": "REPETITIVE",
            "location": "Austin Silicon Hills Tech Park, TX, USA",
            "operating_hours": "06:00 - 22:00 (Two 8h Shifts)",
            "target_daily_capacity": 6000,
            "capabilities": ["01005 Micro-Component Placement", "Lead-Free Reflow", "Inline 3D AOI & X-Ray", "IPC-610 Class 3"],
            "products": [
                {"name": "Multi-Channel Edge-AI Processing Board", "sku": "SMT-EDGE-01", "unit_of_measure": "units", "target_hourly_rate": 350},
                {"name": "Industrial Sensor Controller Sub-Board", "sku": "SMT-SENS-44", "unit_of_measure": "units", "target_hourly_rate": 500},
            ],
            "raw_materials": [
                {"name": "8-Layer High-TG FR4 Multi-Panel PCB", "code": "RAW-PCB-8L", "category": "Substrates", "unit_of_measure": "units", "safety_stock": 8000.0},
                {"name": "Senju SAC305 Lead-Free Solder Paste", "code": "RAW-SLD-305", "category": "Chemicals", "unit_of_measure": "kg", "safety_stock": 300.0},
                {"name": "0402 SMD Ceramic Capacitor Reels", "code": "RAW-CAP-0402", "category": "Electronic Components", "unit_of_measure": "units", "safety_stock": 100000.0},
            ],
            "process_stages": [
                {"sequence": 1, "name": "Automatic Solder Paste Screen Printing", "cycle_time_seconds": 22, "quality_check_required": True, "description": "3D SPI paste volume and height inspection"},
                {"sequence": 2, "name": "Ultra-High-Speed Modular SMT Placement", "cycle_time_seconds": 30, "quality_check_required": False, "description": "120,000 cph component placement on PCB array"},
                {"sequence": 3, "name": "12-Zone Nitrogen Atmosphere Reflow", "cycle_time_seconds": 150, "quality_check_required": True, "description": "Controlled peak reflow at 245°C with oxygen < 50ppm"},
                {"sequence": 4, "name": "3D Automated Optical & X-Ray Inspection", "cycle_time_seconds": 35, "quality_check_required": True, "description": "BGA voiding check and solder fillet verification"},
                {"sequence": 5, "name": "Robotic Selective Conformal Coating", "cycle_time_seconds": 45, "quality_check_required": True, "description": "Moisture and vibration protective elastomer barrier"},
            ],
            "production_lines": [
                {
                    "name": "SMT Ultra-Density Surface Mount Line 01",
                    "code": "LINE-SMT-01",
                    "department": "Surface Mount Technology Bay Alpha",
                    "target_hourly_units": 400,
                    "machines": [
                        {"name": "Yamaha High-Speed Modular Mounter", "code": "M-YAM-01", "machine_type": "Pick and Place", "rated_power_kw": 22.0},
                        {"name": "Heller 12-Zone Convection Reflow Oven", "code": "M-HEL-12Z", "machine_type": "Reflow Oven", "rated_power_kw": 50.0},
                    ]
                }
            ],
            "shifts": [
                {"name": "Alpha Shift", "start_time": "06:00", "end_time": "14:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 3000},
                {"name": "Beta Shift", "start_time": "14:00", "end_time": "22:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 3000},
            ]
        }
    },
    {
        "id": "medical_pharma",
        "title": "Medical Devices & Diagnostics",
        "industry_type": "PHARMACEUTICALS",
        "industry_custom": "Medical Device & Diagnostics Manufacturing",
        "description": "Cleanroom injection molding, automated micro-assembly, ultrasonic welding, and sterile packaging.",
        "icon": "medical_services",
        "defaults": {
            "factory_name": "Apex CleanBio Medical Systems",
            "code_prefix": "MED-BIO",
            "factory_type": "PRIMARY_MANUFACTURING",
            "manufacturing_model": "BATCH",
            "location": "Zurich MedTech Industrial Park, Switzerland",
            "operating_hours": "06:00 - 22:00 (Two 8h Shifts)",
            "target_daily_capacity": 4500,
            "capabilities": ["ISO 13485 Certified", "Cleanroom ISO Class 6", "Ultrasonic Welding", "100% Vision Verification"],
            "products": [
                {"name": "Single-Use Disposable Trocar Cannula", "sku": "MED-TRC-10", "unit_of_measure": "units", "target_hourly_rate": 300},
                {"name": "Microfluidic Point-of-Care Bio-Cartridge", "sku": "MED-CART-02", "unit_of_measure": "units", "target_hourly_rate": 450},
            ],
            "raw_materials": [
                {"name": "Medical-Grade Polycarbonate Resin (USP Class VI)", "code": "RAW-PC-USP", "category": "Polymers", "unit_of_measure": "kg", "safety_stock": 4000.0},
                {"name": "316L Medical Stainless Steel Cannula Tubing", "code": "RAW-TUB-316", "category": "Metals", "unit_of_measure": "meters", "safety_stock": 12000.0},
                {"name": "Tyvek Sterile Medical Packaging Pouches", "code": "RAW-TYV-POU", "category": "Packaging", "unit_of_measure": "units", "safety_stock": 25000.0},
            ],
            "process_stages": [
                {"sequence": 1, "name": "Precision Cleanroom Micro-Injection Molding", "cycle_time_seconds": 25, "quality_check_required": True, "description": "Cavity pressure monitored all-electric injection"},
                {"sequence": 2, "name": "Automated Cannula Insertion & Bonding", "cycle_time_seconds": 35, "quality_check_required": True, "description": "UV-curable adhesive robotic dispensing with 365nm cure"},
                {"sequence": 3, "name": "Ultrasonic Weld & Seal Housing", "cycle_time_seconds": 20, "quality_check_required": True, "description": "Hermetic ultrasonic acoustic welding with collapse limit"},
                {"sequence": 4, "name": "Helium Leak Detection & Flow Metrology", "cycle_time_seconds": 30, "quality_check_required": True, "description": "Mass spectrometer vacuum seal integrity test"},
                {"sequence": 5, "name": "Tyvek Blister Heat Seal & Gamma Pre-Pack", "cycle_time_seconds": 25, "quality_check_required": True, "description": "Validated medical packaging with UDI GS1 serialization"},
            ],
            "production_lines": [
                {
                    "name": "Class 6 Cleanroom Assembly Cell 01",
                    "code": "LINE-MED-01",
                    "department": "ISO Class 6 Cleanroom Assembly Bay",
                    "target_hourly_units": 350,
                    "machines": [
                        {"name": "Fanuc All-Electric Cleanroom Molding Machine", "code": "M-FAN-EL50", "machine_type": "Molding Press", "rated_power_kw": 25.0},
                        {"name": "Dukane Ultrasonic Plastic Welder Unit", "code": "M-DUK-WLD", "machine_type": "Ultrasonic Welder", "rated_power_kw": 5.0},
                    ]
                }
            ],
            "shifts": [
                {"name": "Cleanroom Shift A", "start_time": "06:00", "end_time": "14:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 2250},
                {"name": "Cleanroom Shift B", "start_time": "14:00", "end_time": "22:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 2250},
            ]
        }
    },
    {
        "id": "custom_blank",
        "title": "Custom / Specialized Blank Slate",
        "industry_type": "CUSTOM",
        "industry_custom": "Specialized Industrial Automation",
        "description": "Start with a fully flexible framework to define proprietary manufacturing stages, equipment, and metrics from scratch.",
        "icon": "settings_suggest",
        "defaults": {
            "factory_name": "Pinnacle Manufacturing Facility",
            "code_prefix": "PIN",
            "factory_type": "PRIMARY_MANUFACTURING",
            "manufacturing_model": "JOB_SHOP",
            "location": "Global Industrial Zone",
            "operating_hours": "08:00 - 17:00 (Standard Shift)",
            "target_daily_capacity": 1000,
            "capabilities": ["Custom Manufacturing", "Configurable Routing", "Real-Time Telemetry"],
            "products": [
                {"name": "Primary Finished Product A", "sku": "PIN-PROD-01", "unit_of_measure": "units", "target_hourly_rate": 100},
            ],
            "raw_materials": [
                {"name": "Primary Raw Material Stock", "code": "RAW-PIN-01", "category": "Base Stock", "unit_of_measure": "kg", "safety_stock": 500.0},
            ],
            "process_stages": [
                {"sequence": 1, "name": "Raw Material Preparation", "cycle_time_seconds": 60, "quality_check_required": False, "description": "Material intake, sizing, and staging"},
                {"sequence": 2, "name": "Primary Transformation & Fabrication", "cycle_time_seconds": 120, "quality_check_required": True, "description": "Core machining, molding, or synthesis"},
                {"sequence": 3, "name": "Quality Validation & Final Pack", "cycle_time_seconds": 45, "quality_check_required": True, "description": "Inspection, serial labeling, and packaging"},
            ],
            "production_lines": [
                {
                    "name": "Main Production Line 01",
                    "code": "LINE-PIN-01",
                    "department": "Fabrication & Integration Area",
                    "target_hourly_units": 100,
                    "machines": [
                        {"name": "Primary Processing Unit 01", "code": "M-PIN-01", "machine_type": "Processing Unit", "rated_power_kw": 18.0},
                    ]
                }
            ],
            "shifts": [
                {"name": "Standard Production Shift", "start_time": "08:00", "end_time": "17:00", "operating_days": ["Mon", "Tue", "Wed", "Thu", "Fri"], "planned_capacity_units": 1000},
            ]
        }
    }
]

def get_templates():
    return INDUSTRY_TEMPLATES

def get_template_by_id(template_id: str):
    for t in INDUSTRY_TEMPLATES:
        if t["id"] == template_id:
            return t
    return None
