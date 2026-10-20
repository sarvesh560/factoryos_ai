"""
FactoryOS AI — Universal Manufacturing Process Templates Service
Phase 3: Pre-configured, Topologically Valid Process Graph Templates across Core Industries

Zero-side-effect, in-memory template registry. Templates define realistic manufacturing
routings, cycle times, setup durations, operator competencies, and quality gates.
"""
import uuid
from typing import Dict, Any, List, Optional, Tuple
from django.db import transaction
from apps.factories.models import Factory, IndustryType
from apps.processes.models import (
    ProcessDefinition,
    ProcessVersion,
    ProcessNode,
    ProcessEdge,
    WorkOrder,
)
from apps.processes.services.graph_validator import ProcessGraphValidator

UNIVERSAL_PROCESS_TEMPLATES: List[Dict[str, Any]] = [
    # 1. CNC Precision Machining
    {
        "key": "cnc_precision_machining",
        "name": "5-Axis CNC Precision Machining & Finishing",
        "industry_type": IndustryType.CNC_ENGINEERING,
        "category": "CNC Machining",
        "description": "Multi-stage subtractive machining flow with raw billet prep, rough milling, semi-finish, high-precision finishing, dimensional CMM inspection gate, and deburring.",
        "target_cycle_time_seconds": 480.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Production Release & Material Prep",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 100,
                "required_operators": 1,
                "operator_role": "Material Handler",
                "required_skills": ["Material Handling", "Inventory Barcoding"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-ROUGH-01",
                "name": "Heavy Rough Milling (3-Axis)",
                "node_type": "OPERATION",
                "position_x": 300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 180.0,
                "setup_time_seconds": 600.0,
                "standard_capacity_per_hour": 20,
                "required_operators": 1,
                "operator_role": "CNC Machinist Level 1",
                "required_skills": ["3-Axis CNC Operation", "Tool Setting", "Coolant Monitoring"],
                "yield_rate_percent": 99.0,
            },
            {
                "node_key": "OP-FINISH-02",
                "name": "High-Precision 5-Axis Contour Milling",
                "node_type": "OPERATION",
                "position_x": 500.0,
                "position_y": 250.0,
                "cycle_time_seconds": 240.0,
                "setup_time_seconds": 900.0,
                "standard_capacity_per_hour": 15,
                "required_operators": 1,
                "operator_role": "Senior 5-Axis CNC Specialist",
                "required_skills": ["5-Axis Simultaneous Machining", "CAM Toolpath Verification", "Geometric Dimensioning & Tolerancing (GD&T)"],
                "yield_rate_percent": 98.5,
            },
            {
                "node_key": "QG-CMM-03",
                "name": "Automated CMM Dimensional Inspection",
                "node_type": "QUALITY_GATE",
                "position_x": 700.0,
                "position_y": 250.0,
                "cycle_time_seconds": 60.0,
                "setup_time_seconds": 120.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 1,
                "operator_role": "Metrology Quality Inspector",
                "required_skills": ["Coordinate Measuring Machine (CMM)", "Laser Scanning", "First Article Inspection"],
                "yield_rate_percent": 99.5,
            },
            {
                "node_key": "OP-DEBURR-04",
                "name": "Ultrasonic Cleaning & Edge Deburring",
                "node_type": "OPERATION",
                "position_x": 900.0,
                "position_y": 250.0,
                "cycle_time_seconds": 45.0,
                "setup_time_seconds": 60.0,
                "standard_capacity_per_hour": 80,
                "required_operators": 1,
                "operator_role": "Finishing Technician",
                "required_skills": ["Micro-Deburring", "Ultrasonic Bath Operation"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "END-01",
                "name": "Finished Part Pack & Store",
                "node_type": "END",
                "position_x": 1100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 100,
                "required_operators": 1,
                "operator_role": "Packaging Specialist",
                "required_skills": ["Anti-Corrosion Packaging", "Final Labeling"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-ROUGH-01", "edge_type": "STANDARD", "label": "Start to Roughing"},
            {"edge_key": "ED-02", "source_key": "OP-ROUGH-01", "target_key": "OP-FINISH-02", "edge_type": "STANDARD", "label": "Rough to Finish"},
            {"edge_key": "ED-03", "source_key": "OP-FINISH-02", "target_key": "QG-CMM-03", "edge_type": "STANDARD", "label": "Finish to Metrology Gate"},
            {"edge_key": "ED-04", "source_key": "QG-CMM-03", "target_key": "OP-DEBURR-04", "edge_type": "STANDARD", "label": "Pass Metrology to Deburr"},
            {"edge_key": "ED-05", "source_key": "OP-DEBURR-04", "target_key": "END-01", "edge_type": "STANDARD", "label": "Deburr to Process End"},
        ],
    },

    # 2. Automotive & EV Battery Assembly (With Parallel Split & Join)
    {
        "key": "ev_battery_module_assembly",
        "name": "Automotive EV Battery Module & Pack Integration",
        "industry_type": IndustryType.AUTOMOTIVE,
        "category": "Automotive & EV Assembly",
        "description": "High-throughput lithium-ion battery module assembly with parallel cell testing & stack preparation, robotic laser busbar welding, Hi-Pot insulation gate, thermal gap filling, and end-of-line pack integration.",
        "target_cycle_time_seconds": 360.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Kitting & Batch Initialization",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Battery Assembly Lead",
                "required_skills": ["High-Voltage Safety", "Lot Traceability"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "SPLIT-01",
                "name": "Parallel Sub-Assembly Fork",
                "node_type": "PARALLEL_SPLIT",
                "position_x": 280.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Assembly Automation Specialist",
                "required_skills": ["Automated Conveyor Routing"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-CELL-TEST-02",
                "name": "High-Precision Cell OCV & IR Grading",
                "node_type": "OPERATION",
                "position_x": 480.0,
                "position_y": 180.0,
                "cycle_time_seconds": 90.0,
                "setup_time_seconds": 300.0,
                "standard_capacity_per_hour": 40,
                "required_operators": 1,
                "operator_role": "Battery Cell Test Technician",
                "required_skills": ["Open Circuit Voltage (OCV) Testing", "Internal Resistance Grading"],
                "yield_rate_percent": 99.2,
            },
            {
                "node_key": "OP-TRAY-PREP-03",
                "name": "Module Tray Structural Prep & Insulator Apply",
                "node_type": "OPERATION",
                "position_x": 480.0,
                "position_y": 320.0,
                "cycle_time_seconds": 90.0,
                "setup_time_seconds": 300.0,
                "standard_capacity_per_hour": 40,
                "required_operators": 1,
                "operator_role": "Structural Prep Technician",
                "required_skills": ["Aerogel Insulation Placement", "Dielectric Film Application"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "JOIN-01",
                "name": "Cell Stack & Tray Synchronization",
                "node_type": "PARALLEL_JOIN",
                "position_x": 680.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Assembly Automation Specialist",
                "required_skills": ["Robotic Stacker Calibration"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-LASER-WELD-04",
                "name": "Robotic Fiber Laser Busbar Welding",
                "node_type": "OPERATION",
                "position_x": 880.0,
                "position_y": 250.0,
                "cycle_time_seconds": 120.0,
                "setup_time_seconds": 600.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Laser Welding Robotics Engineer",
                "required_skills": ["Fiber Laser Welding", "Weld Seam Tracking", "Laser Safety L3"],
                "yield_rate_percent": 98.8,
            },
            {
                "node_key": "QG-HIPOT-05",
                "name": "High-Voltage Hi-Pot & Insulation Gate",
                "node_type": "QUALITY_GATE",
                "position_x": 1080.0,
                "position_y": 250.0,
                "cycle_time_seconds": 45.0,
                "setup_time_seconds": 120.0,
                "standard_capacity_per_hour": 80,
                "required_operators": 1,
                "operator_role": "High-Voltage Quality Inspector",
                "required_skills": ["Dielectric Withstand Testing", "BMS Communication Check"],
                "yield_rate_percent": 99.5,
            },
            {
                "node_key": "OP-THERMAL-06",
                "name": "Automated Thermal Gap Filler Dispense & Cure",
                "node_type": "OPERATION",
                "position_x": 1280.0,
                "position_y": 250.0,
                "cycle_time_seconds": 90.0,
                "setup_time_seconds": 240.0,
                "standard_capacity_per_hour": 40,
                "required_operators": 1,
                "operator_role": "Chemical Dispensing Technician",
                "required_skills": ["Two-Part Epoxy Dispense", "Viscosity Monitoring"],
                "yield_rate_percent": 99.7,
            },
            {
                "node_key": "END-01",
                "name": "Module Final Enclosure & Pack Line Handoff",
                "node_type": "END",
                "position_x": 1480.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Pack Line Operator",
                "required_skills": ["Final Battery Pack Serialization"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "SPLIT-01", "edge_type": "STANDARD", "label": "Start to Split"},
            {"edge_key": "ED-02", "source_key": "SPLIT-01", "target_key": "OP-CELL-TEST-02", "edge_type": "STANDARD", "label": "Fork to Cell Test"},
            {"edge_key": "ED-03", "source_key": "SPLIT-01", "target_key": "OP-TRAY-PREP-03", "edge_type": "STANDARD", "label": "Fork to Tray Prep"},
            {"edge_key": "ED-04", "source_key": "OP-CELL-TEST-02", "target_key": "JOIN-01", "edge_type": "STANDARD", "label": "Cell Test to Join"},
            {"edge_key": "ED-05", "source_key": "OP-TRAY-PREP-03", "target_key": "JOIN-01", "edge_type": "STANDARD", "label": "Tray Prep to Join"},
            {"edge_key": "ED-06", "source_key": "JOIN-01", "target_key": "OP-LASER-WELD-04", "edge_type": "STANDARD", "label": "Synchronized to Laser Weld"},
            {"edge_key": "ED-07", "source_key": "OP-LASER-WELD-04", "target_key": "QG-HIPOT-05", "edge_type": "STANDARD", "label": "Weld to Hi-Pot Gate"},
            {"edge_key": "ED-08", "source_key": "QG-HIPOT-05", "target_key": "OP-THERMAL-06", "edge_type": "STANDARD", "label": "Pass Hi-Pot to Thermal Filler"},
            {"edge_key": "ED-09", "source_key": "OP-THERMAL-06", "target_key": "END-01", "edge_type": "STANDARD", "label": "Thermal to Process End"},
        ],
    },

    # 3. Electronics SMT & PCBA
    {
        "key": "electronics_smt_pcba",
        "name": "Surface Mount Technology (SMT) & PCBA Assembly",
        "industry_type": IndustryType.ELECTRONICS,
        "category": "Electronics Assembly",
        "description": "High-speed electronics manufacturing line featuring automated solder paste printing, SPI 3D inspection, dual high-speed pick-and-place, reflow soldering, AOI automated optical inspection gate, and ICT in-circuit testing.",
        "target_cycle_time_seconds": 180.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Bare Board De-stacking & Laser Etching",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 300,
                "required_operators": 1,
                "operator_role": "SMT Line Operator",
                "required_skills": ["SMT Feeders", "ESD Protection Standards"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-PRINT-01",
                "name": "High-Precision Solder Paste Stencil Print",
                "node_type": "OPERATION",
                "position_x": 280.0,
                "position_y": 250.0,
                "cycle_time_seconds": 25.0,
                "setup_time_seconds": 450.0,
                "standard_capacity_per_hour": 140,
                "required_operators": 1,
                "operator_role": "SMT Process Engineer",
                "required_skills": ["Stencil Alignment", "Solder Rheology Monitoring"],
                "yield_rate_percent": 99.5,
            },
            {
                "node_key": "QG-SPI-02",
                "name": "3D Solder Paste Inspection (SPI Gate)",
                "node_type": "QUALITY_GATE",
                "position_x": 460.0,
                "position_y": 250.0,
                "cycle_time_seconds": 20.0,
                "setup_time_seconds": 120.0,
                "standard_capacity_per_hour": 180,
                "required_operators": 1,
                "operator_role": "SMT Quality Inspector",
                "required_skills": ["3D SPI Volumetric Defect Analysis"],
                "yield_rate_percent": 99.2,
            },
            {
                "node_key": "OP-PICKPLACE-03",
                "name": "Dual Gantry High-Speed Component Placement",
                "node_type": "OPERATION",
                "position_x": 640.0,
                "position_y": 250.0,
                "cycle_time_seconds": 45.0,
                "setup_time_seconds": 600.0,
                "standard_capacity_per_hour": 80,
                "required_operators": 1,
                "operator_role": "Pick & Place Specialist",
                "required_skills": ["Nozzle Calibration", "Feeder Loading", "BGA/0201 Component Handling"],
                "yield_rate_percent": 99.4,
            },
            {
                "node_key": "OP-REFLOW-04",
                "name": "10-Zone Nitrogen Convection Reflow Soldering",
                "node_type": "OPERATION",
                "position_x": 820.0,
                "position_y": 250.0,
                "cycle_time_seconds": 60.0,
                "setup_time_seconds": 900.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 1,
                "operator_role": "Thermal Profile Engineer",
                "required_skills": ["Thermal Profiling", "Nitrogen Atmosphere Control"],
                "yield_rate_percent": 99.1,
            },
            {
                "node_key": "QG-AOI-05",
                "name": "Automated Optical Inspection (AOI Gate)",
                "node_type": "QUALITY_GATE",
                "position_x": 1000.0,
                "position_y": 250.0,
                "cycle_time_seconds": 25.0,
                "setup_time_seconds": 180.0,
                "standard_capacity_per_hour": 140,
                "required_operators": 1,
                "operator_role": "AOI Metrology Inspector",
                "required_skills": ["IPC-A-610 Class 3 Standards", "Solder Bridging / Tombstone Detection"],
                "yield_rate_percent": 98.9,
            },
            {
                "node_key": "OP-ICT-06",
                "name": "Bed-of-Nails In-Circuit Test (ICT) & Firmware Flash",
                "node_type": "OPERATION",
                "position_x": 1180.0,
                "position_y": 250.0,
                "cycle_time_seconds": 35.0,
                "setup_time_seconds": 300.0,
                "standard_capacity_per_hour": 100,
                "required_operators": 1,
                "operator_role": "Test Fixture Engineer",
                "required_skills": ["Boundary Scan Test", "Firmware Flashing"],
                "yield_rate_percent": 99.7,
            },
            {
                "node_key": "END-01",
                "name": "PCBA De-paneling & Magazine Unload",
                "node_type": "END",
                "position_x": 1360.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 300,
                "required_operators": 1,
                "operator_role": "SMT Line Operator",
                "required_skills": ["ESD Magazine Handling"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-PRINT-01", "edge_type": "STANDARD", "label": "Start to Print"},
            {"edge_key": "ED-02", "source_key": "OP-PRINT-01", "target_key": "QG-SPI-02", "edge_type": "STANDARD", "label": "Print to SPI Gate"},
            {"edge_key": "ED-03", "source_key": "QG-SPI-02", "target_key": "OP-PICKPLACE-03", "edge_type": "STANDARD", "label": "Pass SPI to Placement"},
            {"edge_key": "ED-04", "source_key": "OP-PICKPLACE-03", "target_key": "OP-REFLOW-04", "edge_type": "STANDARD", "label": "Placement to Reflow"},
            {"edge_key": "ED-05", "source_key": "OP-REFLOW-04", "target_key": "QG-AOI-05", "edge_type": "STANDARD", "label": "Reflow to AOI Gate"},
            {"edge_key": "ED-06", "source_key": "QG-AOI-05", "target_key": "OP-ICT-06", "edge_type": "STANDARD", "label": "Pass AOI to ICT"},
            {"edge_key": "ED-07", "source_key": "OP-ICT-06", "target_key": "END-01", "edge_type": "STANDARD", "label": "ICT to Completion"},
        ],
    },

    # 4. Pharmaceuticals & Cleanroom Production
    {
        "key": "pharma_sterile_injectable",
        "name": "Sterile Injectable Vial Compounding & Aseptic Filling",
        "industry_type": IndustryType.PHARMACEUTICALS,
        "category": "Pharmaceuticals & Biotech",
        "description": "GMP Grade A/B cleanroom formulation flow with API sterile compounding, 0.22 micron sterile filtration, robotic aseptic vial filling, headspace moisture & particle inspection gate, and capping.",
        "target_cycle_time_seconds": 540.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Cleanroom Gowning & Material Pass-Through",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 1,
                "operator_role": "Cleanroom Technician Grade B",
                "required_skills": ["ISO Class 5 Gowning", "Sterile Airlock Transfer"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-COMPOUND-01",
                "name": "API & Excipient Sterile Compounding in Isolator",
                "node_type": "OPERATION",
                "position_x": 320.0,
                "position_y": 250.0,
                "cycle_time_seconds": 180.0,
                "setup_time_seconds": 1200.0,
                "standard_capacity_per_hour": 20,
                "required_operators": 2,
                "operator_role": "Formulation Pharmacist",
                "required_skills": ["Sterile API Weighing", "Bio-Reactor Agitation Control", "pH & Osmolality Balancing"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "OP-STERILE-FILT-02",
                "name": "0.22-Micron Dual Sterile Microfiltration",
                "node_type": "OPERATION",
                "position_x": 540.0,
                "position_y": 250.0,
                "cycle_time_seconds": 120.0,
                "setup_time_seconds": 600.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Filtration Specialist",
                "required_skills": ["Bubble Point Filter Integrity Testing", "Sterile Fluid Transfer"],
                "yield_rate_percent": 99.9,
            },
            {
                "node_key": "OP-ASEPTIC-FILL-03",
                "name": "Robotic Grade A Vial Aseptic Fill & Stoppering",
                "node_type": "OPERATION",
                "position_x": 760.0,
                "position_y": 250.0,
                "cycle_time_seconds": 90.0,
                "setup_time_seconds": 1800.0,
                "standard_capacity_per_hour": 40,
                "required_operators": 2,
                "operator_role": "Aseptic Filling Specialist",
                "required_skills": ["Peristaltic Dosing Calibration", "Lyophilization Stopper Placement"],
                "yield_rate_percent": 99.5,
            },
            {
                "node_key": "QG-VIAL-INSPECT-04",
                "name": "Automated Particle & Headspace Inspection Gate",
                "node_type": "QUALITY_GATE",
                "position_x": 980.0,
                "position_y": 250.0,
                "cycle_time_seconds": 40.0,
                "setup_time_seconds": 300.0,
                "standard_capacity_per_hour": 90,
                "required_operators": 1,
                "operator_role": "GMP Quality Assurance Inspector",
                "required_skills": ["Automated High-Speed Visual Inspection", "Laser Headspace Gas Analysis"],
                "yield_rate_percent": 99.2,
            },
            {
                "node_key": "OP-CRIMP-CAP-05",
                "name": "Aluminum Flip-Off Overseal Crimping",
                "node_type": "OPERATION",
                "position_x": 1200.0,
                "position_y": 250.0,
                "cycle_time_seconds": 50.0,
                "setup_time_seconds": 240.0,
                "standard_capacity_per_hour": 72,
                "required_operators": 1,
                "operator_role": "Packaging Line Operator",
                "required_skills": ["Crimping Blade Setup", "Vacuum Seal Verification"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "END-01",
                "name": "Sterile Tray Storage & Batch Cold Storage",
                "node_type": "END",
                "position_x": 1420.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 1,
                "operator_role": "Cold Chain Logistics Lead",
                "required_skills": ["2-8C Cold Chain Logging", "GMP Batch Record Sign-off"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-COMPOUND-01", "edge_type": "STANDARD", "label": "Start to Compounding"},
            {"edge_key": "ED-02", "source_key": "OP-COMPOUND-01", "target_key": "OP-STERILE-FILT-02", "edge_type": "STANDARD", "label": "Compounding to Filtration"},
            {"edge_key": "ED-03", "source_key": "OP-STERILE-FILT-02", "target_key": "OP-ASEPTIC-FILL-03", "edge_type": "STANDARD", "label": "Filtration to Aseptic Fill"},
            {"edge_key": "ED-04", "source_key": "OP-ASEPTIC-FILL-03", "target_key": "QG-VIAL-INSPECT-04", "edge_type": "STANDARD", "label": "Fill to Quality Gate"},
            {"edge_key": "ED-05", "source_key": "QG-VIAL-INSPECT-04", "target_key": "OP-CRIMP-CAP-05", "edge_type": "STANDARD", "label": "Pass Inspection to Crimp"},
            {"edge_key": "ED-06", "source_key": "OP-CRIMP-CAP-05", "target_key": "END-01", "edge_type": "STANDARD", "label": "Crimp to Cold Store End"},
        ],
    },

    # 5. Food and Beverage Packaging
    {
        "key": "food_beverage_aseptic_packaging",
        "name": "High-Speed Aseptic Beverage Bottling & Packaging",
        "industry_type": IndustryType.FOOD_PROCESSING,
        "category": "Food & Beverage Processing",
        "description": "Continuous beverage processing line encompassing bulk liquid blending, rotary bottle sanitization, isobaric aseptic filling, induction cap sealing, dynamic checkweigher gate, and automated case packing.",
        "target_cycle_time_seconds": 120.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "CIP Sanitization Complete & Ingredient Intake",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 600,
                "required_operators": 1,
                "operator_role": "Beverage Plant Operator",
                "required_skills": ["Clean-in-Place (CIP) Verification", "HACCP Logging"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-BLEND-PAST-01",
                "name": "Continuous Flash Pasteurization & Brix Adjustment",
                "node_type": "OPERATION",
                "position_x": 300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 30.0,
                "setup_time_seconds": 600.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Pasteurization Operator",
                "required_skills": ["HTST Thermal Curve Monitoring", "Refractometer Brix Testing"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "OP-BOTTLE-RINSE-02",
                "name": "Rotary Ionized Air Rinsing & UV Sterilization",
                "node_type": "OPERATION",
                "position_x": 500.0,
                "position_y": 250.0,
                "cycle_time_seconds": 15.0,
                "setup_time_seconds": 180.0,
                "standard_capacity_per_hour": 240,
                "required_operators": 1,
                "operator_role": "Bottling Line Specialist",
                "required_skills": ["Rotary Infeed Timing", "UV Lamp Intensity Verification"],
                "yield_rate_percent": 99.9,
            },
            {
                "node_key": "OP-ASEPTIC-FILL-03",
                "name": "Isobaric Rotary Liquid Filling & Induction Capping",
                "node_type": "OPERATION",
                "position_x": 700.0,
                "position_y": 250.0,
                "cycle_time_seconds": 25.0,
                "setup_time_seconds": 450.0,
                "standard_capacity_per_hour": 144,
                "required_operators": 1,
                "operator_role": "Filling Machine Specialist",
                "required_skills": ["Flowmeter Dosing Tuning", "Torque Induction Sealing"],
                "yield_rate_percent": 99.4,
            },
            {
                "node_key": "QG-CHECKWEIGH-04",
                "name": "Dynamic High-Speed Checkweigher & Fill Level Gate",
                "node_type": "QUALITY_GATE",
                "position_x": 900.0,
                "position_y": 250.0,
                "cycle_time_seconds": 10.0,
                "setup_time_seconds": 60.0,
                "standard_capacity_per_hour": 360,
                "required_operators": 1,
                "operator_role": "F&B Quality Inspector",
                "required_skills": ["Dynamic Scale Calibration", "X-Ray Fill Level & Foreign Body Detection"],
                "yield_rate_percent": 99.6,
            },
            {
                "node_key": "OP-LABEL-CASE-05",
                "name": "Hot-Melt Sleeve Labeling & Robotic Case Packing",
                "node_type": "OPERATION",
                "position_x": 1100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 20.0,
                "setup_time_seconds": 240.0,
                "standard_capacity_per_hour": 180,
                "required_operators": 1,
                "operator_role": "Packaging Automation Lead",
                "required_skills": ["Shrink Tunnel Tuning", "Case Packer Pick-and-Place"],
                "yield_rate_percent": 99.9,
            },
            {
                "node_key": "END-01",
                "name": "Automated Palletizing & Cold Staging",
                "node_type": "END",
                "position_x": 1300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 600,
                "required_operators": 1,
                "operator_role": "Warehouse & Palletizer Operator",
                "required_skills": ["Stretch Wrap Tensioning", "Lot SSCC Labeling"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-BLEND-PAST-01", "edge_type": "STANDARD", "label": "Start to Pasteurization"},
            {"edge_key": "ED-02", "source_key": "OP-BLEND-PAST-01", "target_key": "OP-BOTTLE-RINSE-02", "edge_type": "STANDARD", "label": "Pasteurize to Bottle Rinse"},
            {"edge_key": "ED-03", "source_key": "OP-BOTTLE-RINSE-02", "target_key": "OP-ASEPTIC-FILL-03", "edge_type": "STANDARD", "label": "Rinse to Aseptic Fill"},
            {"edge_key": "ED-04", "source_key": "OP-ASEPTIC-FILL-03", "target_key": "QG-CHECKWEIGH-04", "edge_type": "STANDARD", "label": "Fill to Checkweigher Gate"},
            {"edge_key": "ED-05", "source_key": "QG-CHECKWEIGH-04", "target_key": "OP-LABEL-CASE-05", "edge_type": "STANDARD", "label": "Pass Weight to Label/Pack"},
            {"edge_key": "ED-06", "source_key": "OP-LABEL-CASE-05", "target_key": "END-01", "edge_type": "STANDARD", "label": "Pack to Palletize End"},
        ],
    },

    # 6. Textile Manufacturing
    {
        "key": "textile_yarn_weaving",
        "name": "High-Speed Shuttleless Weaving & Fabric Finishing",
        "industry_type": IndustryType.TEXTILE,
        "category": "Textile Manufacturing",
        "description": "Integrated yarn spinning, warp beam sizing, high-speed air-jet weaving, continuous fabric scouring/heat-setting, and 4-point visual fabric grading inspection.",
        "target_cycle_time_seconds": 300.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Yarn Creel Loading & Lot Staging",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 150,
                "required_operators": 1,
                "operator_role": "Creel Tender",
                "required_skills": ["Yarn Count Verification", "Creel Knotting"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-WARP-SIZE-01",
                "name": "Warp Beam Preparation & Chemical Sizing",
                "node_type": "OPERATION",
                "position_x": 300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 60.0,
                "setup_time_seconds": 900.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 2,
                "operator_role": "Sizing Machine Operator",
                "required_skills": ["Size Viscosity Control", "Yarn Tension Uniformity"],
                "yield_rate_percent": 99.3,
            },
            {
                "node_key": "OP-WEAVE-02",
                "name": "High-Speed Air-Jet Loom Weaving",
                "node_type": "OPERATION",
                "position_x": 500.0,
                "position_y": 250.0,
                "cycle_time_seconds": 120.0,
                "setup_time_seconds": 1200.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Weaving Technician",
                "required_skills": ["Air-Jet Nozzle Pressure Tuning", "Warp Stop Motion Recovery"],
                "yield_rate_percent": 98.7,
            },
            {
                "node_key": "OP-SCOUR-FINISH-03",
                "name": "Continuous Scouring & Stenter Heat-Setting",
                "node_type": "OPERATION",
                "position_x": 700.0,
                "position_y": 250.0,
                "cycle_time_seconds": 75.0,
                "setup_time_seconds": 450.0,
                "standard_capacity_per_hour": 48,
                "required_operators": 1,
                "operator_role": "Dyeing & Finishing Specialist",
                "required_skills": ["Stenter Temperature Profiling", "Fabric Width Control"],
                "yield_rate_percent": 99.5,
            },
            {
                "node_key": "QG-FABRIC-INSPECT-04",
                "name": "4-Point Standard Automated Fabric Defect Gate",
                "node_type": "QUALITY_GATE",
                "position_x": 900.0,
                "position_y": 250.0,
                "cycle_time_seconds": 40.0,
                "setup_time_seconds": 120.0,
                "standard_capacity_per_hour": 90,
                "required_operators": 1,
                "operator_role": "Fabric Quality Grader",
                "required_skills": ["ASTM D5430 4-Point System", "Vision Defect Mapping"],
                "yield_rate_percent": 99.0,
            },
            {
                "node_key": "OP-BATCH-ROLL-05",
                "name": "Precision Rolling, Slitting & Moisture Barrier Packing",
                "node_type": "OPERATION",
                "position_x": 1100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 30.0,
                "setup_time_seconds": 180.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Roll Packing Operator",
                "required_skills": ["Automatic Edge Trimming", "Moisture-Proof Shrink Wrapping"],
                "yield_rate_percent": 99.9,
            },
            {
                "node_key": "END-01",
                "name": "Fabric Roll Stacking & Warehouse Release",
                "node_type": "END",
                "position_x": 1300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 150,
                "required_operators": 1,
                "operator_role": "Warehouse Material Handler",
                "required_skills": ["Batch RFID Tagging"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-WARP-SIZE-01", "edge_type": "STANDARD", "label": "Start to Sizing"},
            {"edge_key": "ED-02", "source_key": "OP-WARP-SIZE-01", "target_key": "OP-WEAVE-02", "edge_type": "STANDARD", "label": "Sizing to Weave"},
            {"edge_key": "ED-03", "source_key": "OP-WEAVE-02", "target_key": "OP-SCOUR-FINISH-03", "edge_type": "STANDARD", "label": "Weave to Scour/Finish"},
            {"edge_key": "ED-04", "source_key": "OP-SCOUR-FINISH-03", "target_key": "QG-FABRIC-INSPECT-04", "edge_type": "STANDARD", "label": "Finish to 4-Point Inspection"},
            {"edge_key": "ED-05", "source_key": "QG-FABRIC-INSPECT-04", "target_key": "OP-BATCH-ROLL-05", "edge_type": "STANDARD", "label": "Pass Defect Gate to Roll"},
            {"edge_key": "ED-06", "source_key": "OP-BATCH-ROLL-05", "target_key": "END-01", "edge_type": "STANDARD", "label": "Roll to Warehouse End"},
        ],
    },

    # 7. Chemical Batch Processing
    {
        "key": "chemical_batch_polymerization",
        "name": "Multi-Stage Emulsion Polymerization Batch Flow",
        "industry_type": IndustryType.CHEMICALS,
        "category": "Chemical Processing",
        "description": "Exothermic reactor batch sequence with raw monomer metering, jacketed reactor emulsion polymerization, chemical titration quality gate, vacuum degassing/stripping, and filtration/drumming.",
        "target_cycle_time_seconds": 720.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Nitrogen Reactor Purge & Safety Interlock Clearance",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Chemical Process Lead",
                "required_skills": ["Process Safety Management (PSM)", "Oxygen Deficiency Verification"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-MONOMER-FEED-01",
                "name": "Automated Mass-Flow Monomer & Surfactant Metering",
                "node_type": "OPERATION",
                "position_x": 300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 120.0,
                "setup_time_seconds": 450.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Chemical Batch Operator",
                "required_skills": ["Coriolis Meter Calibration", "Hazardous Chemical Handling"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "OP-REACT-POLY-02",
                "name": "Jacketed Reactor Polymerization (Exothermic Control)",
                "node_type": "OPERATION",
                "position_x": 520.0,
                "position_y": 250.0,
                "cycle_time_seconds": 360.0,
                "setup_time_seconds": 900.0,
                "standard_capacity_per_hour": 10,
                "required_operators": 2,
                "operator_role": "Reactor Control Engineer",
                "required_skills": ["Exothermic Runaway Mitigation", "Cascade Temperature Control"],
                "yield_rate_percent": 98.9,
            },
            {
                "node_key": "QG-TITRATION-03",
                "name": "Inline Titration & Brookfield Viscosity Gate",
                "node_type": "QUALITY_GATE",
                "position_x": 740.0,
                "position_y": 250.0,
                "cycle_time_seconds": 60.0,
                "setup_time_seconds": 180.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 1,
                "operator_role": "Analytical Chemist",
                "required_skills": ["Free Monomer GC Analysis", "Brookfield Viscometry"],
                "yield_rate_percent": 99.4,
            },
            {
                "node_key": "OP-VAC-DEGAS-04",
                "name": "Vacuum Monomer Stripping & Thermal Degassing",
                "node_type": "OPERATION",
                "position_x": 960.0,
                "position_y": 250.0,
                "cycle_time_seconds": 120.0,
                "setup_time_seconds": 300.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Chemical Batch Operator",
                "required_skills": ["Vacuum Pump Operation", "Condenser Scrubbing Systems"],
                "yield_rate_percent": 99.7,
            },
            {
                "node_key": "OP-FILT-DRUM-05",
                "name": "Cartridge Micro-Filtration & Tote Loading",
                "node_type": "OPERATION",
                "position_x": 1180.0,
                "position_y": 250.0,
                "cycle_time_seconds": 90.0,
                "setup_time_seconds": 240.0,
                "standard_capacity_per_hour": 40,
                "required_operators": 1,
                "operator_role": "Drumming & Packaging Technician",
                "required_skills": ["Pressure Leaf Filter Maintenance", "UN Intermediate Bulk Container (IBC) Filling"],
                "yield_rate_percent": 99.9,
            },
            {
                "node_key": "END-01",
                "name": "Chemical Tote Seal & Finished Goods Quarantine",
                "node_type": "END",
                "position_x": 1400.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 30,
                "required_operators": 1,
                "operator_role": "Hazmat Warehouse Lead",
                "required_skills": ["GHS Hazard Labeling", "DOT Hazmat Transport Documentation"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-MONOMER-FEED-01", "edge_type": "STANDARD", "label": "Start to Monomer Feed"},
            {"edge_key": "ED-02", "source_key": "OP-MONOMER-FEED-01", "target_key": "OP-REACT-POLY-02", "edge_type": "STANDARD", "label": "Feed to Polymerization"},
            {"edge_key": "ED-03", "source_key": "OP-REACT-POLY-02", "target_key": "QG-TITRATION-03", "edge_type": "STANDARD", "label": "React to Titration Gate"},
            {"edge_key": "ED-04", "source_key": "QG-TITRATION-03", "target_key": "OP-VAC-DEGAS-04", "edge_type": "STANDARD", "label": "Pass Titration to Degas"},
            {"edge_key": "ED-05", "source_key": "OP-VAC-DEGAS-04", "target_key": "OP-FILT-DRUM-05", "edge_type": "STANDARD", "label": "Degas to Micro-Filter"},
            {"edge_key": "ED-06", "source_key": "OP-FILT-DRUM-05", "target_key": "END-01", "edge_type": "STANDARD", "label": "Filter to Chemical End"},
        ],
    },

    # 8. General Discrete Manufacturing
    {
        "key": "general_discrete_assembly",
        "name": "Modular Sub-Assembly & Precision Fastening Cell",
        "industry_type": IndustryType.CUSTOM,
        "category": "General Discrete Manufacturing",
        "description": "Flexible discrete manufacturing cell featuring kitted component verification, multi-axis automated torque fastening, in-line optical verification gate, functional electrical run-in, and final serialization.",
        "target_cycle_time_seconds": 240.0,
        "nodes": [
            {
                "node_key": "START-01",
                "name": "Work Order Release & Kit Staging",
                "node_type": "START",
                "position_x": 100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 150,
                "required_operators": 1,
                "operator_role": "Assembly Cell Lead",
                "required_skills": ["Work Order Kitting", "Kanban Replenishment"],
                "yield_rate_percent": 100.0,
            },
            {
                "node_key": "OP-KIT-PREP-01",
                "name": "Component Pick-to-Light & Barcode Scan",
                "node_type": "OPERATION",
                "position_x": 300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 30.0,
                "setup_time_seconds": 120.0,
                "standard_capacity_per_hour": 120,
                "required_operators": 1,
                "operator_role": "Assembly Technician",
                "required_skills": ["Pick-to-Light Systems", "Barcode Traceability"],
                "yield_rate_percent": 99.8,
            },
            {
                "node_key": "OP-TORQUE-FASTEN-02",
                "name": "Automated Multi-Spindle Precision Torque Fastening",
                "node_type": "OPERATION",
                "position_x": 500.0,
                "position_y": 250.0,
                "cycle_time_seconds": 60.0,
                "setup_time_seconds": 300.0,
                "standard_capacity_per_hour": 60,
                "required_operators": 1,
                "operator_role": "Mechanical Assembler",
                "required_skills": ["DC Electric Torque Tool Operation", "Angle-Torque Monitoring"],
                "yield_rate_percent": 99.4,
            },
            {
                "node_key": "QG-OPTICAL-ALIGN-03",
                "name": "Vision System Fastener & Alignment Gate",
                "node_type": "QUALITY_GATE",
                "position_x": 700.0,
                "position_y": 250.0,
                "cycle_time_seconds": 20.0,
                "setup_time_seconds": 60.0,
                "standard_capacity_per_hour": 180,
                "required_operators": 1,
                "operator_role": "Quality Inspector",
                "required_skills": ["Vision Inspection Setup", "Defect Tagging"],
                "yield_rate_percent": 99.6,
            },
            {
                "node_key": "OP-RUNIN-TEST-04",
                "name": "Functional Mechanical & Electrical Run-In Test",
                "node_type": "OPERATION",
                "position_x": 900.0,
                "position_y": 250.0,
                "cycle_time_seconds": 90.0,
                "setup_time_seconds": 180.0,
                "standard_capacity_per_hour": 40,
                "required_operators": 1,
                "operator_role": "Test Bench Technician",
                "required_skills": ["Functional Load Testing", "Vibration Monitoring"],
                "yield_rate_percent": 99.1,
            },
            {
                "node_key": "OP-SERIALIZE-PACK-05",
                "name": "Laser Marking Serialization & Protective Packaging",
                "node_type": "OPERATION",
                "position_x": 1100.0,
                "position_y": 250.0,
                "cycle_time_seconds": 40.0,
                "setup_time_seconds": 120.0,
                "standard_capacity_per_hour": 90,
                "required_operators": 1,
                "operator_role": "Final Packaging Specialist",
                "required_skills": ["Laser Serialization", "Cushion Packaging"],
                "yield_rate_percent": 99.9,
            },
            {
                "node_key": "END-01",
                "name": "Finished Product Warehouse Staging",
                "node_type": "END",
                "position_x": 1300.0,
                "position_y": 250.0,
                "cycle_time_seconds": 0.0,
                "setup_time_seconds": 0.0,
                "standard_capacity_per_hour": 150,
                "required_operators": 1,
                "operator_role": "Shipping Lead",
                "required_skills": ["Warehouse Management System (WMS) Entry"],
                "yield_rate_percent": 100.0,
            },
        ],
        "edges": [
            {"edge_key": "ED-01", "source_key": "START-01", "target_key": "OP-KIT-PREP-01", "edge_type": "STANDARD", "label": "Start to Kit Prep"},
            {"edge_key": "ED-02", "source_key": "OP-KIT-PREP-01", "target_key": "OP-TORQUE-FASTEN-02", "edge_type": "STANDARD", "label": "Kit to Torque Fastening"},
            {"edge_key": "ED-03", "source_key": "OP-TORQUE-FASTEN-02", "target_key": "QG-OPTICAL-ALIGN-03", "edge_type": "STANDARD", "label": "Torque to Alignment Gate"},
            {"edge_key": "ED-04", "source_key": "QG-OPTICAL-ALIGN-03", "target_key": "OP-RUNIN-TEST-04", "edge_type": "STANDARD", "label": "Pass Gate to Run-In"},
            {"edge_key": "ED-05", "source_key": "OP-RUNIN-TEST-04", "target_key": "OP-SERIALIZE-PACK-05", "edge_type": "STANDARD", "label": "Run-In to Serialize"},
            {"edge_key": "ED-06", "source_key": "OP-SERIALIZE-PACK-05", "target_key": "END-01", "edge_type": "STANDARD", "label": "Serialize to End"},
        ],
    },
]


class ProcessTemplateService:
    """
    Service for discovering and validating Universal Manufacturing Process Templates.
    Completely decoupled from database persistence; zero side-effects.
    """

    @classmethod
    def get_templates(cls) -> List[Dict[str, Any]]:
        """
        Lists all available universal manufacturing process templates with summary metadata.
        Zero database operations.
        """
        summaries = []
        for t in UNIVERSAL_PROCESS_TEMPLATES:
            summaries.append({
                "key": t["key"],
                "name": t["name"],
                "industry_type": t["industry_type"],
                "category": t["category"],
                "description": t["description"],
                "target_cycle_time_seconds": t["target_cycle_time_seconds"],
                "node_count": len(t.get("nodes", [])),
                "edge_count": len(t.get("edges", [])),
                "operation_stages": [
                    n["name"] for n in t.get("nodes", []) if n.get("node_type") in ("OPERATION", "QUALITY_GATE")
                ],
            })
        return summaries

    @classmethod
    def get_template_by_key(cls, template_key: str) -> Optional[Dict[str, Any]]:
        """
        Retrieves a full template specification (metadata, nodes, edges) by its unique key.
        Zero database operations.
        """
        for t in UNIVERSAL_PROCESS_TEMPLATES:
            if t["key"] == template_key:
                return t
        return None

    @classmethod
    def validate_template_graph(cls, template: Dict[str, Any]) -> Tuple[bool, List[str], List[str]]:
        """
        Validates in-memory template topology against MES rules without database interaction.
        Enforces:
        - Unique node keys
        - START and END node presence
        - Zero incoming on START, zero outgoing on END
        - Intermediate nodes have incoming and outgoing connections
        - Valid edge source/target references
        - Reachability from START to all nodes
        - Reachability from all nodes to END
        - Acyclicity (cycle detection)
        - Branch balance on PARALLEL_SPLIT and PARALLEL_JOIN
        """
        errors: List[str] = []
        warnings: List[str] = []

        nodes = template.get("nodes", [])
        edges = template.get("edges", [])

        if not nodes:
            return False, ["Template contains no nodes."], []

        node_keys = [n["node_key"] for n in nodes]
        if len(node_keys) != len(set(node_keys)):
            errors.append("Duplicate node keys found in template.")

        key_set = set(node_keys)
        start_nodes = [n for n in nodes if n.get("node_type") == "START"]
        end_nodes = [n for n in nodes if n.get("node_type") == "END"]

        if not start_nodes:
            errors.append("Template missing START node.")
        if not end_nodes:
            errors.append("Template missing END node.")

        from collections import defaultdict, deque
        outgoing = defaultdict(list)
        incoming = defaultdict(list)

        for edge in edges:
            src = edge.get("source_key")
            tgt = edge.get("target_key")

            if src not in key_set:
                errors.append(f"Edge references invalid source_key '{src}'.")
            if tgt not in key_set:
                errors.append(f"Edge references invalid target_key '{tgt}'.")
            if src == tgt:
                errors.append(f"Edge forms invalid self-loop on '{src}'.")

            outgoing[src].append(tgt)
            incoming[tgt].append(src)

        # START / END constraints
        for s in start_nodes:
            k = s["node_key"]
            if incoming[k]:
                errors.append(f"START node '{k}' cannot have incoming edges.")
            if not outgoing[k]:
                errors.append(f"START node '{k}' must have outgoing edges.")

        for e in end_nodes:
            k = e["node_key"]
            if outgoing[k]:
                errors.append(f"END node '{k}' cannot have outgoing edges.")
            if not incoming[k]:
                errors.append(f"END node '{k}' must have incoming edges.")

        # Intermediate nodes
        for n in nodes:
            k = n["node_key"]
            ntype = n.get("node_type")
            if ntype not in ("START", "END"):
                if not incoming[k]:
                    errors.append(f"Node '{k}' has no incoming edges (unreachable).")
                if not outgoing[k]:
                    errors.append(f"Node '{k}' has no outgoing edges (dead end).")

            if ntype == "PARALLEL_SPLIT" and len(outgoing[k]) < 2:
                warnings.append(f"PARALLEL_SPLIT '{k}' has fewer than 2 outgoing paths.")
            if ntype == "PARALLEL_JOIN" and len(incoming[k]) < 2:
                warnings.append(f"PARALLEL_JOIN '{k}' has fewer than 2 incoming branches.")

        # Forward reachability
        reachable_from_start = set()
        queue = deque([s["node_key"] for s in start_nodes])
        while queue:
            curr = queue.popleft()
            if curr not in reachable_from_start:
                reachable_from_start.add(curr)
                for nxt in outgoing[curr]:
                    if nxt not in reachable_from_start:
                        queue.append(nxt)

        unreachable = key_set - reachable_from_start
        if unreachable:
            errors.append(f"Nodes unreachable from START: {', '.join(sorted(unreachable))}")

        # Backward reachability
        can_reach_end = set()
        rev_queue = deque([e["node_key"] for e in end_nodes])
        while rev_queue:
            curr = rev_queue.popleft()
            if curr not in can_reach_end:
                can_reach_end.add(curr)
                for prev in incoming[curr]:
                    if prev not in can_reach_end:
                        rev_queue.append(prev)

        cannot_reach = key_set - can_reach_end
        if cannot_reach:
            errors.append(f"Nodes cannot reach END: {', '.join(sorted(cannot_reach))}")

        # Cycle detection
        visited = {k: 0 for k in key_set}
        cycles = []

        def dfs(curr: str, path: List[str]):
            visited[curr] = 1
            path.append(curr)
            for nxt in outgoing[curr]:
                if visited[nxt] == 1:
                    cycle_start = path.index(nxt)
                    cycles.append(path[cycle_start:] + [nxt])
                elif visited[nxt] == 0:
                    dfs(nxt, path)
            path.pop()
            visited[curr] = 2

        for s in start_nodes:
            if visited[s["node_key"]] == 0:
                dfs(s["node_key"], [])

        if cycles:
            errors.append(f"Cyclic dependency detected: {' -> '.join(cycles[0])}")

        is_valid = len(errors) == 0
        return is_valid, errors, warnings

    @classmethod
    @transaction.atomic
    def instantiate_template(
        cls,
        template_key: str,
        factory: Factory,
        name: Optional[str] = None,
        code: Optional[str] = None,
        description: Optional[str] = None,
        target_cycle_time_seconds: Optional[float] = None,
    ) -> Tuple[ProcessDefinition, ProcessVersion]:
        """
        Instantiates a universal process template into a concrete factory process definition and draft graph.
        Atomically creates definition, version, nodes, and edges, then verifies graph topology.
        Rolls back completely if graph validation or model integrity fails.
        """
        template = cls.get_template_by_key(template_key)
        if not template:
            raise ValueError(f"Template '{template_key}' does not exist.")

        # In-memory graph validation prior to record creation
        is_valid_tpl, tpl_errors, _ = cls.validate_template_graph(template)
        if not is_valid_tpl:
            raise ValueError(f"Template graph definition is invalid: {'; '.join(tpl_errors)}")

        proc_name = (name or template["name"]).strip()
        if not proc_name:
            raise ValueError("Process name cannot be empty.")

        # Resolve or auto-generate unique process code within the factory
        if code and code.strip():
            proc_code = code.strip().upper()
            if ProcessDefinition.objects.filter(factory=factory, code=proc_code).exists():
                raise ValueError(f"Process definition with code '{proc_code}' already exists in this factory.")
        else:
            base_code = f"PRC-{template_key[:8].upper()}"
            counter = 1
            proc_code = f"{base_code}-{counter:02d}"
            while ProcessDefinition.objects.filter(factory=factory, code=proc_code).exists():
                counter += 1
                proc_code = f"{base_code}-{counter:02d}"

        proc_desc = description if description is not None else template.get("description", "")
        cycle_time = float(
            target_cycle_time_seconds
            if target_cycle_time_seconds is not None
            else template.get("target_cycle_time_seconds", 60.0)
        )

        # 1. Create ProcessDefinition
        proc = ProcessDefinition.objects.create(
            factory=factory,
            name=proc_name,
            code=proc_code,
            description=proc_desc,
            category=template.get("category", "General Manufacturing"),
            industry_type=template.get("industry_type", factory.industry_type),
            target_cycle_time_seconds=cycle_time,
            is_active=True,
        )

        # 2. Create Initial Version (Draft)
        ver = ProcessVersion.objects.create(
            process_definition=proc,
            version_number=1,
            version_tag="v1.0.0",
            status="DRAFT",
            change_summary=f"Instantiated from template '{template['name']}'",
            graph_metadata={"zoom": 1.0, "pan_x": 0.0, "pan_y": 0.0},
        )

        # 3. Create Nodes
        node_map: Dict[str, ProcessNode] = {}
        for n in template.get("nodes", []):
            node = ProcessNode.objects.create(
                process_version=ver,
                node_key=n["node_key"],
                name=n["name"],
                node_type=n.get("node_type", "OPERATION"),
                position_x=float(n.get("position_x", 100.0)),
                position_y=float(n.get("position_y", 100.0)),
                cycle_time_seconds=float(n.get("cycle_time_seconds", 30.0)),
                setup_time_seconds=float(n.get("setup_time_seconds", 0.0)),
                standard_capacity_per_hour=int(n.get("standard_capacity_per_hour", 60)),
                assigned_line=None,
                assigned_machine=None,
                required_operators=int(n.get("required_operators", 1)),
                operator_role=n.get("operator_role", ""),
                required_skills=n.get("required_skills", []),
                resource_spec=n.get("resource_spec", {}),
                input_materials=n.get("input_materials", []),
                output_materials=n.get("output_materials", []),
                yield_rate_percent=float(n.get("yield_rate_percent", 100.0)),
                configuration=n.get("configuration", {}),
            )
            node_map[n["node_key"]] = node

        # 4. Create Edges
        for e in template.get("edges", []):
            src_key = e["source_key"]
            tgt_key = e["target_key"]
            if src_key not in node_map or tgt_key not in node_map:
                raise ValueError(f"Template edge '{e.get('edge_key')}' references missing nodes ({src_key} -> {tgt_key}).")

            ProcessEdge.objects.create(
                process_version=ver,
                edge_key=e["edge_key"],
                source_node=node_map[src_key],
                target_node=node_map[tgt_key],
                edge_type=e.get("edge_type", "STANDARD"),
                condition_expression=e.get("condition_expression", ""),
                label=e.get("label", ""),
                priority=int(e.get("priority", 0)),
            )

        # 5. Graph topology validation with ProcessGraphValidator
        is_valid, errors, _ = ProcessGraphValidator.validate_version(ver)
        if not is_valid:
            raise ValueError(f"Instantiated graph validation failed: {'; '.join(errors)}")

        return proc, ver

    @classmethod
    @transaction.atomic
    def duplicate_process_definition(
        cls,
        source_proc: ProcessDefinition,
        new_name: Optional[str] = None,
        new_code: Optional[str] = None,
        new_description: Optional[str] = None,
    ) -> Tuple[ProcessDefinition, ProcessVersion]:
        """
        Deep duplicates an existing process definition and its latest/published graph into a new editable draft.
        Enforces factory tenancy, copies all operational node metadata, and isolates from runtime execution history.
        """
        factory = source_proc.factory
        source_ver = source_proc.published_version or source_proc.latest_version
        if not source_ver:
            raise ValueError(f"Source process '{source_proc.name}' has no process versions to duplicate.")

        dup_name = (new_name or f"{source_proc.name} (Copy)").strip()
        if not dup_name:
            raise ValueError("Duplicate process name cannot be empty.")

        if new_code and new_code.strip():
            dup_code = new_code.strip().upper()
            if ProcessDefinition.objects.filter(factory=factory, code=dup_code).exists():
                raise ValueError(f"Process definition with code '{dup_code}' already exists in this factory.")
        else:
            base_code = f"{source_proc.code[:38]}-COPY"
            counter = 1
            dup_code = base_code
            while ProcessDefinition.objects.filter(factory=factory, code=dup_code).exists():
                counter += 1
                dup_code = f"{base_code}-{counter:02d}"

        dup_desc = new_description if new_description is not None else source_proc.description

        # 1. Create duplicate ProcessDefinition
        new_proc = ProcessDefinition.objects.create(
            factory=factory,
            name=dup_name,
            code=dup_code,
            description=dup_desc,
            category=source_proc.category,
            industry_type=source_proc.industry_type,
            target_cycle_time_seconds=source_proc.target_cycle_time_seconds,
            is_active=True,
        )

        # 2. Create initial draft version
        new_ver = ProcessVersion.objects.create(
            process_definition=new_proc,
            version_number=1,
            version_tag="v1.0.0",
            status="DRAFT",
            change_summary=f"Duplicated from '{source_proc.name}' [{source_proc.code}] version {source_ver.version_tag}",
            graph_metadata=source_ver.graph_metadata,
        )

        # 3. Deep clone nodes
        node_map: Dict[uuid.UUID, ProcessNode] = {}
        for old_node in source_ver.nodes.all():
            new_node = ProcessNode.objects.create(
                process_version=new_ver,
                node_key=old_node.node_key,
                name=old_node.name,
                node_type=old_node.node_type,
                position_x=old_node.position_x,
                position_y=old_node.position_y,
                cycle_time_seconds=old_node.cycle_time_seconds,
                setup_time_seconds=old_node.setup_time_seconds,
                standard_capacity_per_hour=old_node.standard_capacity_per_hour,
                assigned_line=old_node.assigned_line,
                assigned_machine=old_node.assigned_machine,
                required_operators=old_node.required_operators,
                operator_role=old_node.operator_role,
                required_skills=old_node.required_skills,
                resource_spec=old_node.resource_spec,
                input_materials=old_node.input_materials,
                output_materials=old_node.output_materials,
                yield_rate_percent=old_node.yield_rate_percent,
                configuration=old_node.configuration,
            )
            node_map[old_node.id] = new_node

        # 4. Deep clone edges
        for old_edge in source_ver.edges.all():
            if old_edge.source_node_id in node_map and old_edge.target_node_id in node_map:
                ProcessEdge.objects.create(
                    process_version=new_ver,
                    edge_key=old_edge.edge_key,
                    source_node=node_map[old_edge.source_node_id],
                    target_node=node_map[old_edge.target_node_id],
                    edge_type=old_edge.edge_type,
                    condition_expression=old_edge.condition_expression,
                    label=old_edge.label,
                    priority=old_edge.priority,
                )

        # 5. Graph topology validation with ProcessGraphValidator
        is_valid, errors, _ = ProcessGraphValidator.validate_version(new_ver)
        if not is_valid:
            raise ValueError(f"Duplicated graph validation failed: {'; '.join(errors)}")

        return new_proc, new_ver

    @classmethod
    def archive_process_definition(cls, proc: ProcessDefinition) -> Tuple[bool, Optional[str]]:
        """
        Safely archives a process definition without destroying historical execution data.
        Blocks archival if active work orders (RELEASED, IN_PROGRESS, PAUSED) exist.
        Returns: (success: bool, error_message: Optional[str])
        """
        active_statuses = ["RELEASED", "IN_PROGRESS", "PAUSED"]
        active_orders = WorkOrder.objects.filter(process_definition=proc, status__in=active_statuses)
        if active_orders.exists():
            order_nums = list(active_orders.values_list("order_number", flat=True)[:3])
            orders_str = ", ".join(order_nums)
            count = active_orders.count()
            return (
                False,
                f"Cannot archive process '{proc.name}' because {count} work order(s) are currently active ({orders_str}). "
                "Please complete, cancel, or reassign them before archiving."
            )

        if not proc.is_active:
            # Idempotent success
            return True, None

        proc.is_active = False
        proc.save(update_fields=["is_active", "updated_at"])

        # Mark draft versions as ARCHIVED; preserved published versions remain for completed work orders
        proc.versions.filter(status="DRAFT").update(status="ARCHIVED")
        return True, None
