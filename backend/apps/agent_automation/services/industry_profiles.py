"""
FactoryOS AI — Universal Manufacturing Industry Profiles Registry
Phase 4, Step 2: Shared Agent Runtime with Versioned Industry Profiles

Defines formal, versioned profiles across the 8 core manufacturing industries:
1. TEXTILES
2. AUTOMOTIVE_EV
3. CNC_MACHINING
4. ELECTRONICS_PCBA
5. PHARMACEUTICALS
6. FOOD_BEVERAGE
7. CHEMICALS
8. GENERAL_DISCRETE

Each profile specifies:
- Unique industry identifier & display name
- Profile version
- Operational status (OPERATIONAL, PREVIEW, UNAVAILABLE)
- Supported capabilities
- Permitted typed tools
- Process constraints & validation rules
- Production terminology
- Safety & regulatory restrictions
"""
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
from enum import Enum


class ProfileStatus(str, Enum):
    OPERATIONAL = "OPERATIONAL"  # Fully verified against working domain models and services
    PREVIEW = "PREVIEW"          # Planning support exists, but specialized IoT/regulatory integrations pending
    UNAVAILABLE = "UNAVAILABLE"  # Core external prerequisites missing


@dataclass
class IndustryProfile:
    key: str
    display_name: str
    version: str
    status: ProfileStatus
    description: str
    supported_capabilities: List[str]
    permitted_tools: List[str]
    process_constraints: Dict[str, Any]
    terminology: Dict[str, str]
    required_approvals: List[str]
    regulatory_framework: str
    supported_templates: List[str]
    status_note: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "key": self.key,
            "display_name": self.display_name,
            "version": self.version,
            "status": self.status.value,
            "status_note": self.status_note,
            "description": self.description,
            "supported_capabilities": self.supported_capabilities,
            "permitted_tools": self.permitted_tools,
            "process_constraints": self.process_constraints,
            "terminology": self.terminology,
            "required_approvals": self.required_approvals,
            "regulatory_framework": self.regulatory_framework,
            "supported_templates": self.supported_templates,
        }


class IndustryProfileRegistry:
    """
    Central, versioned registry of industry profiles.
    Used by the goal runtime to validate plans, restrict tool access,
    and enforce industry-specific safety barriers without scattered if/else checks.
    """

    _PROFILES: Dict[str, IndustryProfile] = {
        # 1. CNC Precision Machining
        "CNC_MACHINING": IndustryProfile(
            key="CNC_MACHINING",
            display_name="CNC Precision Machining & Aerospace Finishing",
            version="1.2.0",
            status=ProfileStatus.OPERATIONAL,
            description="Multi-axis subtractive milling, turning, coordinate measuring metrology (CMM), and cryogenic deburring.",
            supported_capabilities=[
                "SUBTRACTIVE_MILLING",
                "MULTI_AXIS_TURNING",
                "METROLOGY_CMM_INSPECTION",
                "COOLANT_TEMPERATURE_MONITORING",
                "TOOL_WEAR_COMPENSATION",
                "WORK_ORDER_DISPATCH",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "min_tool_changeover_seconds": 180,
                "cmm_quality_gate_mandatory": True,
                "spindle_vibration_rms_limit": 6.5,
                "spindle_temp_c_limit": 85.0,
            },
            terminology={
                "workpiece": "Billet / Blank",
                "operation": "Machining Pass",
                "quality_check": "CMM Metrology Gate",
                "waste": "Metal Chips / Scrap Turnings",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "CHANGE_TOOL_OFFSETS",
                "SCRAP_OVERRIDE",
            ],
            regulatory_framework="AS9100D / ISO 9001:2015",
            supported_templates=["cnc_precision_machining"],
            status_note="Verified end-to-end against live work orders, graph validator, and simulation engine.",
        ),

        # 2. Automotive & EV
        "AUTOMOTIVE_EV": IndustryProfile(
            key="AUTOMOTIVE_EV",
            display_name="Automotive & EV Battery Assembly",
            version="1.1.0",
            status=ProfileStatus.OPERATIONAL,
            description="Robotic cell placement, ultrasonic wire bonding, laser busbar welding, and high-voltage dielectric testing.",
            supported_capabilities=[
                "ROBOTIC_CELL_HANDLING",
                "LASER_BUSBAR_WELDING",
                "HIGH_VOLTAGE_INSULATION_TEST",
                "BATTERY_CELL_BALANCING",
                "TRACEABILITY_SERIALIZATION",
                "WORK_ORDER_DISPATCH",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "hi_pot_dielectric_test_mandatory": True,
                "weld_seam_optical_verification": True,
                "cleanroom_iso_class": 8,
            },
            terminology={
                "workpiece": "Battery Module / Carrier",
                "operation": "Robotic Welding / Assembly",
                "quality_check": "High-Voltage Isolation Verification",
                "waste": "Reject Pouch Cell / Defective Busbar",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "RELEASE_HV_SAFETY_INTERLOCK",
                "BATCH_REWORK_SIGN_OFF",
            ],
            regulatory_framework="IATF 16949 / ISO 26262",
            supported_templates=["ev_battery_module_assembly"],
            status_note="Verified end-to-end against live work orders, graph validator, and simulation engine.",
        ),

        # 3. Textiles & Technical Fabrics
        "TEXTILES": IndustryProfile(
            key="TEXTILES",
            display_name="Textiles & Technical Fabric Manufacturing",
            version="1.0.0",
            status=ProfileStatus.OPERATIONAL,
            description="Fiber opening, carding, ring spinning, warping, air-jet weaving, and optical continuous fabric inspection.",
            supported_capabilities=[
                "HIGH_SPEED_SPINNING",
                "AIR_JET_WEAVING",
                "OPTICAL_FABRIC_INSPECTION",
                "HUMIDITY_TOLERANCE_TRACKING",
                "YARN_TENSION_MONITORING",
                "WORK_ORDER_DISPATCH",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "relative_humidity_min_pct": 55.0,
                "relative_humidity_max_pct": 70.0,
                "maximum_yarn_break_rate_per_k_picks": 1.2,
            },
            terminology={
                "workpiece": "Cotton Bale / Bobbin / Loom Beam",
                "operation": "Drafting / Spinning / Weaving",
                "quality_check": "Optical Slub & Warp Fault Inspection",
                "waste": "Lint / Warp Waste / Off-Cut Selvage",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "LOOM_SPEED_ADJUSTMENT",
                "DYE_LOT_VARIANCE_RELEASE",
            ],
            regulatory_framework="OEKO-TEX Standard 100 / ISO 14001",
            supported_templates=["textile_yarn_weaving"],
            status_note="Verified end-to-end against live work orders, graph validator, and simulation engine.",
        ),

        # 4. Electronics & PCBA
        "ELECTRONICS_PCBA": IndustryProfile(
            key="ELECTRONICS_PCBA",
            display_name="Electronics SMT & PCBA Manufacturing",
            version="1.1.0",
            status=ProfileStatus.OPERATIONAL,
            description="Solder paste jet printing, high-speed SMT pick-and-place, reflow thermal profiling, AOI, and in-circuit testing.",
            supported_capabilities=[
                "SOLDER_PASTE_INSPECTION_SPI",
                "HIGH_SPEED_SMT_PLACEMENT",
                "REFLOW_THERMAL_PROFILING",
                "AUTOMATED_OPTICAL_INSPECTION_AOI",
                "IN_CIRCUIT_TESTING_ICT",
                "WORK_ORDER_DISPATCH",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "aoi_inspection_gate_mandatory": True,
                "reflow_peak_temperature_max_c": 250.0,
                "esd_grounding_verification_required": True,
            },
            terminology={
                "workpiece": "Bare PCB Panel",
                "operation": "SMT Placement / Reflow",
                "quality_check": "3D AOI & X-Ray BGA Inspection",
                "waste": "Tombstoned Component / Solder Bridge Scrap",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "REFLOW_OVEN_PROFILE_REVISION",
                "COMPONENT_REEL_SPLICING_VERIFICATION",
            ],
            regulatory_framework="IPC-A-610 Class 3 / ANSI/ESD S20.20",
            supported_templates=["electronics_smt_pcba"],
            status_note="Verified end-to-end against live work orders, graph validator, and simulation engine.",
        ),

        # 5. Pharmaceuticals & Cleanroom
        "PHARMACEUTICALS": IndustryProfile(
            key="PHARMACEUTICALS",
            display_name="Pharmaceuticals & Sterile Formulations",
            version="1.0.0",
            status=ProfileStatus.PREVIEW,
            description="Cleanroom aseptic compounding, sterile filtration (0.22 micron), depyrogenated vial filling, and freeze drying.",
            supported_capabilities=[
                "ASEPTIC_CLEANROOM_COMPOUNDING",
                "STERILE_MICRO_FILTRATION",
                "HIGH_SPEED_VIAL_FILLING",
                "LYOPHILIZATION",
                "ELECTRONIC_BATCH_RECORD_EBR",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "iso_cleanroom_class_limit": 5,
                "airlock_pressure_differential_pa": 15.0,
                "sterile_filter_integrity_test_mandatory": True,
                "quarantine_hold_before_release": True,
            },
            terminology={
                "workpiece": "Active Pharmaceutical Ingredient (API) Batch",
                "operation": "Compounding / Aseptic Filling",
                "quality_check": "Sterility & Endotoxin Bioburden Assay",
                "waste": "Contaminated Lot / Particulate Reject",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "QUALIFIED_PERSON_QP_BATCH_RELEASE",
                "ENVIRONMENTAL_EXCURSION_DEVIATION",
            ],
            regulatory_framework="FDA 21 CFR Part 11 / EU GMP Annex 1",
            supported_templates=["pharma_sterile_injectable"],
            status_note="PREVIEW: Process templates and planning workflows supported. Electronic batch signature integration scheduled for future milestone.",
        ),

        # 6. Food & Beverage Processing
        "FOOD_BEVERAGE": IndustryProfile(
            key="FOOD_BEVERAGE",
            display_name="Food & Beverage Aseptic Packaging",
            version="1.0.0",
            status=ProfileStatus.PREVIEW,
            description="Sanitary batch pasteurization, aseptic tetra-pack filling, hermetic ultrasonic sealing, and metal detection.",
            supported_capabilities=[
                "HIGH_TEMPERATURE_PASTEURIZATION_HTST",
                "ASEPTIC_LIQUID_FILLING",
                "HERMETIC_SEAL_VERIFICATION",
                "IN_LINE_METAL_DETECTION",
                "ALLERGEN_CROSS_CONTAMINATION_CONTROL",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "min_pasteurization_temp_c": 72.0,
                "min_pasteurization_hold_seconds": 15,
                "metal_detector_check_frequency_minutes": 60,
                "cip_clean_in_place_enforced": True,
            },
            terminology={
                "workpiece": "Raw Liquid Formulation / Bulk Mash",
                "operation": "Thermal Pasteurization / Filling",
                "quality_check": "Seal Integrity & ATP Swab Test",
                "waste": "Leaker Carton / Off-Spec Flavor Reject",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "CIP_CYCLE_OVERRIDE",
                "ALLERGEN_LINE_CHANGEOVER_SIGN_OFF",
            ],
            regulatory_framework="FDA FSMA / HACCP / BRCGS Global Standard",
            supported_templates=["food_beverage_aseptic_packaging"],
            status_note="PREVIEW: Simulation and routing supported. CIP sensor hardware telemetry listener scheduled for future milestone.",
        ),

        # 7. Chemicals & Continuous Polymerization
        "CHEMICALS": IndustryProfile(
            key="CHEMICALS",
            display_name="Chemical Processing & Batch Polymerization",
            version="1.0.0",
            status=ProfileStatus.PREVIEW,
            description="Exothermic jacketed reactor blending, catalyst metering, degassing, and volatile organic compound containment.",
            supported_capabilities=[
                "EXOTHERMIC_REACTOR_CONTROL",
                "CATALYST_PRECISION_METERING",
                "VACUUM_DEGASSING",
                "VISCOSITY_MONITORING",
                "SCRUBBER_EFFLUENT_MONITORING",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "max_reactor_temperature_c": 190.0,
                "pressure_relief_valve_redundancy": True,
                "inert_nitrogen_purge_required": True,
            },
            terminology={
                "workpiece": "Polymer Monomer Charge",
                "operation": "Exothermic Reaction / Distillation",
                "quality_check": "Gel Permeation Chromatography (GPC)",
                "waste": "Distillation Residue / Off-Spec Polymer",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "REACTOR_SETPOINT_VARIANCE",
                "HAZMAT_TRANSFER_AUTHORIZATION",
            ],
            regulatory_framework="OSHA PSM 1910.119 / REACH Compliance",
            supported_templates=["chemical_batch_polymerization"],
            status_note="PREVIEW: Thermodynamic model routing supported. Real-time explosion-proof sensor telemetry listener scheduled for future milestone.",
        ),

        # 8. General Discrete Manufacturing
        "GENERAL_DISCRETE": IndustryProfile(
            key="GENERAL_DISCRETE",
            display_name="General Discrete Mechanical Assembly",
            version="1.2.0",
            status=ProfileStatus.OPERATIONAL,
            description="Multi-station mechanical assembly, torque fastening, pneumatic testing, and packaging line operations.",
            supported_capabilities=[
                "MANUAL_AND_SEMI_AUTO_ASSEMBLY",
                "TORQUE_FASTENER_VERIFICATION",
                "PNEUMATIC_PRESSURE_LEAK_TEST",
                "BARCODE_SERIAL_PACKAGING",
                "WORK_ORDER_DISPATCH",
            ],
            permitted_tools=[
                "inspect_inventory_stock",
                "discover_and_validate_process",
                "simulate_process_execution",
                "create_work_order",
                "inspect_work_order_status",
                "request_human_clarification",
            ],
            process_constraints={
                "calibrated_torque_check_mandatory": True,
                "leak_test_pressure_bar": 4.0,
            },
            terminology={
                "workpiece": "Sub-Assembly Kit",
                "operation": "Mechanical Assembly Station",
                "quality_check": "End-of-Line Functional Test",
                "waste": "Damaged Fastener / Scrap Housing",
            },
            required_approvals=[
                "CREATE_WORK_ORDER",
                "LINE_SPEED_OVERRIDE",
            ],
            regulatory_framework="ISO 9001:2015",
            supported_templates=["general_discrete_assembly"],
            status_note="Verified end-to-end against live work orders, graph validator, and simulation engine.",
        ),
    }

    @classmethod
    def list_all(cls) -> List[IndustryProfile]:
        """Returns all configured industry profiles."""
        return list(cls._PROFILES.values())

    @classmethod
    def get(cls, profile_key: str) -> Optional[IndustryProfile]:
        """Retrieves an industry profile by key, supporting aliases."""
        if not profile_key:
            return None
        norm_key = profile_key.strip().upper()
        # Direct lookup
        if norm_key in cls._PROFILES:
            return cls._PROFILES[norm_key]
        
        # Friendly mapping / aliases
        aliases = {
            "TEXTILE": "TEXTILES",
            "AUTOMOTIVE": "AUTOMOTIVE_EV",
            "CNC": "CNC_MACHINING",
            "CNC_ENGINEERING": "CNC_MACHINING",
            "ELECTRONICS": "ELECTRONICS_PCBA",
            "PHARMA": "PHARMACEUTICALS",
            "FOOD": "FOOD_BEVERAGE",
            "FOOD_PROCESSING": "FOOD_BEVERAGE",
            "CHEMICAL": "CHEMICALS",
            "DISCRETE": "GENERAL_DISCRETE",
            "CUSTOM": "GENERAL_DISCRETE",
        }
        mapped = aliases.get(norm_key)
        if mapped and mapped in cls._PROFILES:
            return cls._PROFILES[mapped]
        
        return None

    @classmethod
    def is_tool_permitted(cls, profile_key: str, tool_name: str) -> bool:
        """Verifies if a specific tool is permitted under the active industry profile."""
        profile = cls.get(profile_key)
        if not profile:
            return False
        return tool_name in profile.permitted_tools
