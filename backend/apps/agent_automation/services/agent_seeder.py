"""
FactoryOS AI — Idempotent Specialist Agent Seeding Service
Phase 4: Multi-Agent Manufacturing Orchestration

Seeds the 5 core specialist agents safely and idempotently without duplicate records.
"""
import logging
from typing import List
from apps.agent_automation.models import (
    AgentConfiguration,
    AgentType,
    ManufacturingEventType,
    ActionType,
)

logger = logging.getLogger(__name__)

DEFAULT_AGENTS = [
    {
        "key": "production_agent",
        "name": "Production Orchestration Agent",
        "agent_type": AgentType.PRODUCTION,
        "description": "Monitors shop-floor throughput pacing, cycle time inflation, and bottleneck queues to initiate production investigation audits.",
        "supported_event_types": [
            ManufacturingEventType.PRODUCTION_DELAY,
            ManufacturingEventType.WORK_ORDER_STATUS_CHANGED,
        ],
        "allowed_action_types": [
            ActionType.CREATE_PRODUCTION_INVESTIGATION,
            ActionType.SEND_IN_APP_NOTIFICATION,
        ],
        "requires_approval": True,
        "config": {
            "max_cycle_variance_pct": 15.0,
            "escalation_threshold_pct": 30.0,
            "auto_investigation_delay_seconds": 60,
        },
    },
    {
        "key": "maintenance_agent",
        "name": "Predictive & Preventative Maintenance Agent",
        "agent_type": AgentType.MAINTENANCE,
        "description": "Monitors continuous asset vibration, thermal telemetry, and operating hours to schedule corrective and preventive maintenance tickets.",
        "supported_event_types": [
            ManufacturingEventType.MACHINE_ANOMALY,
            ManufacturingEventType.MAINTENANCE_DUE,
        ],
        "allowed_action_types": [
            ActionType.CREATE_MAINTENANCE_TICKET,
            ActionType.SEND_IN_APP_NOTIFICATION,
        ],
        "requires_approval": True,
        "config": {
            "vibration_threshold_rms": 6.5,
            "thermal_threshold_celsius": 85.0,
            "routine_interval_hours": 250,
        },
    },
    {
        "key": "quality_agent",
        "name": "Quality Assurance & Scrap Reduction Agent",
        "agent_type": AgentType.QUALITY,
        "description": "Evaluates scrap rate spikes, dimensional tolerances, and defect counts at inspection gates to order immediate containment inspections.",
        "supported_event_types": [
            ManufacturingEventType.QUALITY_FAILURE,
        ],
        "allowed_action_types": [
            ActionType.CREATE_QUALITY_INSPECTION,
            ActionType.SEND_IN_APP_NOTIFICATION,
        ],
        "requires_approval": True,
        "config": {
            "max_acceptable_scrap_pct": 2.0,
            "containment_threshold_units": 5,
        },
    },
    {
        "key": "inventory_agent",
        "name": "Inventory Replenishment & WIP Agent",
        "agent_type": AgentType.INVENTORY,
        "description": "Monitors safety buffer stock levels and active work order raw material consumption to trigger replenishment requisitions.",
        "supported_event_types": [
            ManufacturingEventType.INVENTORY_SHORTAGE,
        ],
        "allowed_action_types": [
            ActionType.CREATE_INVENTORY_REPLENISHMENT_REQUEST,
            ActionType.SEND_IN_APP_NOTIFICATION,
        ],
        "requires_approval": True,
        "config": {
            "buffer_threshold_multiplier": 1.0,
            "emergency_reorder_units": 200,
        },
    },
    {
        "key": "energy_agent",
        "name": "Energy Optimization & Sustainability Agent",
        "agent_type": AgentType.ENERGY,
        "description": "Analyzes machine power consumption and utility surge profiles to generate non-intrusive advisory load-shifting recommendations.",
        "supported_event_types": [
            ManufacturingEventType.MACHINE_ANOMALY,
            ManufacturingEventType.PRODUCTION_DELAY,
        ],
        "allowed_action_types": [
            ActionType.SEND_IN_APP_NOTIFICATION,
        ],
        "requires_approval": False,
        "config": {
            "peak_surge_multiplier": 1.35,
            "off_peak_shift_hours": ["22:00", "06:00"],
        },
    },
]


def seed_default_agents() -> List[AgentConfiguration]:
    """
    Ensures default enterprise specialist agents exist in the database.
    Updates configurations if existing, creates if missing.
    """
    seeded = []
    for agent_data in DEFAULT_AGENTS:
        key = agent_data["key"]
        agent, created = AgentConfiguration.objects.get_or_create(
            key=key,
            defaults={
                "name": agent_data["name"],
                "agent_type": agent_data["agent_type"],
                "description": agent_data["description"],
                "supported_event_types": agent_data["supported_event_types"],
                "allowed_action_types": agent_data["allowed_action_types"],
                "requires_approval": agent_data["requires_approval"],
                "config": agent_data["config"],
                "is_enabled": True,
                "factory": None,  # Enterprise standard agent
            },
        )
        if not created:
            # Sync metadata while preserving user's is_enabled toggle
            agent.name = agent_data["name"]
            agent.agent_type = agent_data["agent_type"]
            agent.description = agent_data["description"]
            agent.supported_event_types = agent_data["supported_event_types"]
            agent.allowed_action_types = agent_data["allowed_action_types"]
            agent.config = agent_data["config"]
            agent.save(update_fields=[
                "name",
                "agent_type",
                "description",
                "supported_event_types",
                "allowed_action_types",
                "config",
                "updated_at",
            ])
        seeded.append(agent)
        logger.info(f"Agent '{key}' ({'created' if created else 'updated'}).")

    return seeded
