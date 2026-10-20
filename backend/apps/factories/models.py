"""
FactoryOS AI — Factory & Manufacturing Operational Models
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
import uuid
from django.db import models

class IndustryType(models.TextChoices):
    TEXTILE = "TEXTILE", "Textile Manufacturing"
    CNC_ENGINEERING = "CNC_ENGINEERING", "CNC Engineering"
    FOOD_PROCESSING = "FOOD_PROCESSING", "Food Processing"
    AUTOMOTIVE = "AUTOMOTIVE", "Automotive & Parts"
    ELECTRONICS = "ELECTRONICS", "Electronics & High-Tech"
    PHARMACEUTICALS = "PHARMACEUTICALS", "Pharmaceuticals & Biotech"
    AEROSPACE = "AEROSPACE", "Aerospace & Defense"
    HEAVY_MACHINERY = "HEAVY_MACHINERY", "Heavy Machinery & Equipment"
    CHEMICALS = "CHEMICALS", "Chemical Processing"
    CUSTOM = "CUSTOM", "Custom / Specialized Manufacturing"

class ConfigurationStatus(models.TextChoices):
    CONFIGURED = "CONFIGURED", "Configured"
    IN_PROGRESS = "IN_PROGRESS", "In Progress"
    PENDING = "PENDING", "Pending Configuration"

class ManufacturingModel(models.TextChoices):
    DISCRETE = "DISCRETE", "Discrete Manufacturing"
    BATCH = "BATCH", "Batch Processing"
    CONTINUOUS = "CONTINUOUS", "Continuous Process"
    JOB_SHOP = "JOB_SHOP", "Job Shop / Custom Machining"
    REPETITIVE = "REPETITIVE", "Repetitive / High-Volume Assembly"

class FactoryType(models.TextChoices):
    PRIMARY_MANUFACTURING = "PRIMARY_MANUFACTURING", "Primary Manufacturing Plant"
    SUB_ASSEMBLY = "SUB_ASSEMBLY", "Component & Sub-Assembly Facility"
    FINAL_ASSEMBLY = "FINAL_ASSEMBLY", "Final Assembly & Integration"
    PACKAGING_DISTRIBUTION = "PACKAGING_DISTRIBUTION", "Packaging & Finishing Center"
    PILOT_PLANT = "PILOT_PLANT", "Pilot Plant & Prototyping"

class Organization(models.Model):
    """
    Top-level enterprise tenant / company holding.
    Can operate multiple factories across diverse regions and industrial domains.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, help_text="Enterprise Company / Organization Name")
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True, default="")
    website = models.URLField(max_length=255, blank=True, default="")
    contact_email = models.EmailField(max_length=255, blank=True, default="")
    is_active = models.BooleanField(default=True, help_text="False indicates archived company")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Organization"
        verbose_name_plural = "Organizations"

    def __str__(self):
        return self.name

class Factory(models.Model):
    """
    Physical or virtual manufacturing facility running automated operational processes.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(
        Organization,
        on_delete=models.CASCADE,
        related_name="factories",
    )
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, unique=True)
    industry_type = models.CharField(
        max_length=50,
        choices=IndustryType.choices,
        default=IndustryType.CUSTOM,
    )
    industry_custom = models.CharField(
        max_length=100,
        blank=True,
        default="",
        help_text="Custom industry domain when industry_type is CUSTOM or specialized",
    )
    factory_type = models.CharField(
        max_length=50,
        choices=FactoryType.choices,
        default=FactoryType.PRIMARY_MANUFACTURING,
        help_text="Operational classification of manufacturing facility",
    )
    manufacturing_model = models.CharField(
        max_length=50,
        choices=ManufacturingModel.choices,
        default=ManufacturingModel.DISCRETE,
        help_text="Underlying production paradigm (Discrete, Batch, Continuous, Job Shop)",
    )
    configuration_status = models.CharField(
        max_length=50,
        choices=ConfigurationStatus.choices,
        default=ConfigurationStatus.CONFIGURED,
    )
    location = models.CharField(max_length=255)
    country = models.CharField(max_length=100, default="USA")
    timezone = models.CharField(max_length=50, default="UTC")
    operating_hours = models.CharField(
        max_length=255,
        default="06:00 - 22:00 (Two 8h Shifts)",
        blank=True,
        help_text="Operational shifts summary or daily schedule",
    )
    capabilities = models.JSONField(
        default=list,
        blank=True,
        help_text="List of manufacturing capabilities, certifications, and competencies",
    )
    target_daily_capacity = models.PositiveIntegerField(
        default=5000,
        blank=True,
        help_text="Planned daily aggregate output capacity in units",
    )
    total_production_lines = models.PositiveIntegerField(default=1)
    active_lines = models.PositiveIntegerField(default=1)
    is_active = models.BooleanField(
        default=True,
        help_text="False indicates archived factory",
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Factory"
        verbose_name_plural = "Factories"

    def __str__(self):
        return f"{self.name} ({self.code})"

class Product(models.Model):
    """
    Manufactured product, SKU, or part produced within a factory.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="products",
    )
    name = models.CharField(max_length=255)
    sku = models.CharField(max_length=100)
    description = models.TextField(blank=True, default="")
    unit_of_measure = models.CharField(max_length=50, default="units")
    target_hourly_rate = models.PositiveIntegerField(default=100)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        unique_together = ("factory", "sku")
        verbose_name = "Product"
        verbose_name_plural = "Products"

    def __str__(self):
        return f"{self.name} ({self.sku})"

class RawMaterial(models.Model):
    """
    Raw material, stock inventory, or component consumed in the manufacturing process.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="raw_materials",
    )
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=100)
    category = models.CharField(max_length=100, default="General")
    unit_of_measure = models.CharField(max_length=50, default="kg")
    safety_stock = models.FloatField(default=100.0)
    current_stock = models.FloatField(default=500.0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        unique_together = ("factory", "code")
        verbose_name = "Raw Material"
        verbose_name_plural = "Raw Materials"

    def __str__(self):
        return f"{self.name} [{self.code}]"

class ProcessStage(models.Model):
    """
    Discrete manufacturing process stage or routing step within the factory workflow.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="process_stages",
    )
    name = models.CharField(max_length=255)
    sequence = models.PositiveIntegerField(default=1)
    description = models.TextField(blank=True, default="")
    cycle_time_seconds = models.PositiveIntegerField(default=60)
    quality_check_required = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sequence", "name"]
        unique_together = ("factory", "sequence")
        verbose_name = "Process Stage"
        verbose_name_plural = "Process Stages"

    def __str__(self):
        return f"Stage {self.sequence}: {self.name}"

class LineStatus(models.TextChoices):
    RUNNING = "RUNNING", "Running"
    IDLE = "IDLE", "Idle"
    MAINTENANCE = "MAINTENANCE", "Maintenance"
    OFFLINE = "OFFLINE", "Offline"

class ProductionLine(models.Model):
    """
    Discrete production line, cell, or automated line within a manufacturing facility.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="production_lines",
    )
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50)
    department = models.CharField(
        max_length=100,
        default="General Production",
        blank=True,
        help_text="Department or operational plant area",
    )
    status = models.CharField(
        max_length=50,
        choices=LineStatus.choices,
        default=LineStatus.RUNNING,
    )
    current_product = models.CharField(max_length=255, blank=True)
    efficiency_rate = models.FloatField(default=0.0, help_text="Current efficiency percentage (0-100)")
    target_hourly_units = models.PositiveIntegerField(default=100)
    actual_hourly_units = models.PositiveIntegerField(default=0)
    operator_count = models.PositiveIntegerField(default=2)
    last_maintenance_date = models.DateField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["code"]
        unique_together = ("factory", "code")
        verbose_name = "Production Line"
        verbose_name_plural = "Production Lines"

    def __str__(self):
        return f"{self.factory.code} - {self.name} ({self.status})"

class Machine(models.Model):
    """
    Individual machine, asset, or robotics unit attached to a production line and process stage.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    production_line = models.ForeignKey(
        ProductionLine,
        on_delete=models.CASCADE,
        related_name="machines",
    )
    process_stage = models.ForeignKey(
        ProcessStage,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="machines",
    )
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=100)
    machine_type = models.CharField(max_length=100, default="General Equipment")
    rated_power_kw = models.FloatField(default=15.0)
    status = models.CharField(
        max_length=50,
        choices=LineStatus.choices,
        default=LineStatus.RUNNING,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Machine"
        verbose_name_plural = "Machines"

    def __str__(self):
        return f"{self.name} ({self.code})"

class ShiftConfiguration(models.Model):
    """
    Operating shift schedule and planned capacity allocation.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="shifts",
    )
    name = models.CharField(max_length=100)
    start_time = models.TimeField()
    end_time = models.TimeField()
    operating_days = models.JSONField(
        default=list,
        blank=True,
        help_text="Active weekdays e.g. ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']",
    )
    planned_capacity_units = models.PositiveIntegerField(default=1000)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["start_time"]
        verbose_name = "Shift Configuration"
        verbose_name_plural = "Shift Configurations"

    def __str__(self):
        return f"{self.factory.name} - {self.name} ({self.start_time} - {self.end_time})"

class FactoryMetricSnapshot(models.Model):
    """
    Point-in-time KPI telemetry snapshot for factory operational performance.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factory = models.ForeignKey(
        Factory,
        on_delete=models.CASCADE,
        related_name="metric_snapshots",
    )
    overall_oee = models.FloatField(help_text="Overall Equipment Effectiveness %")
    availability = models.FloatField(help_text="Machine availability rate %")
    performance = models.FloatField(help_text="Operational throughput rate %")
    quality_rate = models.FloatField(help_text="Quality yield percentage %")
    energy_consumption_kwh = models.FloatField(default=0.0)
    active_alerts_count = models.PositiveIntegerField(default=0)
    active_shifts = models.PositiveIntegerField(default=1)
    planned_units = models.PositiveIntegerField(default=1000)
    actual_units = models.PositiveIntegerField(default=950)
    scrap_units = models.PositiveIntegerField(default=10)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["factory", "-timestamp"]),
        ]
        verbose_name = "Factory Metric Snapshot"
        verbose_name_plural = "Factory Metric Snapshots"

    def __str__(self):
        return f"{self.factory.name} Metrics @ {self.timestamp.strftime('%Y-%m-%d %H:%M')}"
