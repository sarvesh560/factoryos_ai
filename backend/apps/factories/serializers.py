"""
FactoryOS AI — Factory & Multi-Tenant Serializers
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field
from .models import (
    Organization,
    Factory,
    Product,
    RawMaterial,
    ProcessStage,
    ProductionLine,
    Machine,
    ShiftConfiguration,
    FactoryMetricSnapshot,
    IndustryType,
    FactoryType,
    ManufacturingModel,
    ConfigurationStatus,
    LineStatus,
)

class MachineSerializer(serializers.ModelSerializer):
    process_stage_name = serializers.CharField(source="process_stage.name", read_only=True)

    class Meta:
        model = Machine
        fields = [
            "id",
            "name",
            "code",
            "machine_type",
            "rated_power_kw",
            "status",
            "process_stage",
            "process_stage_name",
            "created_at",
        ]

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = [
            "id",
            "factory",
            "name",
            "sku",
            "description",
            "unit_of_measure",
            "target_hourly_rate",
            "metadata",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

class RawMaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = RawMaterial
        fields = [
            "id",
            "factory",
            "name",
            "code",
            "category",
            "unit_of_measure",
            "safety_stock",
            "current_stock",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

class ProcessStageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProcessStage
        fields = [
            "id",
            "factory",
            "name",
            "sequence",
            "description",
            "cycle_time_seconds",
            "quality_check_required",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

class ShiftConfigurationSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShiftConfiguration
        fields = [
            "id",
            "factory",
            "name",
            "start_time",
            "end_time",
            "operating_days",
            "planned_capacity_units",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

class ProductionLineSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    machines = MachineSerializer(many=True, read_only=True)

    class Meta:
        model = ProductionLine
        fields = [
            "id",
            "name",
            "code",
            "department",
            "status",
            "status_display",
            "current_product",
            "efficiency_rate",
            "target_hourly_units",
            "actual_hourly_units",
            "operator_count",
            "last_maintenance_date",
            "metadata",
            "machines",
        ]

class FactoryMetricSnapshotSerializer(serializers.ModelSerializer):
    class Meta:
        model = FactoryMetricSnapshot
        fields = [
            "id",
            "overall_oee",
            "availability",
            "performance",
            "quality_rate",
            "energy_consumption_kwh",
            "active_alerts_count",
            "active_shifts",
            "planned_units",
            "actual_units",
            "scrap_units",
            "timestamp",
        ]

class FactoryListSerializer(serializers.ModelSerializer):
    """
    Concise serializer for the factory switcher and enterprise factory list.
    """
    industry_type_display = serializers.CharField(source="get_industry_type_display", read_only=True)
    factory_type_display = serializers.CharField(source="get_factory_type_display", read_only=True)
    manufacturing_model_display = serializers.CharField(source="get_manufacturing_model_display", read_only=True)
    configuration_status_display = serializers.CharField(source="get_configuration_status_display", read_only=True)
    organization_name = serializers.CharField(source="organization.name", read_only=True)
    overall_oee = serializers.SerializerMethodField()

    class Meta:
        model = Factory
        fields = [
            "id",
            "name",
            "code",
            "industry_type",
            "industry_type_display",
            "industry_custom",
            "factory_type",
            "factory_type_display",
            "manufacturing_model",
            "manufacturing_model_display",
            "configuration_status",
            "configuration_status_display",
            "location",
            "country",
            "timezone",
            "operating_hours",
            "capabilities",
            "target_daily_capacity",
            "total_production_lines",
            "active_lines",
            "is_active",
            "overall_oee",
            "organization_name",
            "organization_id",
            "created_at",
            "updated_at",
        ]

    def get_overall_oee(self, obj):
        first_metric = obj.metric_snapshots.first()
        return first_metric.overall_oee if first_metric else 90.0

class OrganizationSerializer(serializers.ModelSerializer):
    factory_count = serializers.SerializerMethodField()
    factories = FactoryListSerializer(many=True, read_only=True)

    class Meta:
        model = Organization
        fields = [
            "id",
            "name",
            "slug",
            "description",
            "website",
            "contact_email",
            "is_active",
            "factory_count",
            "factories",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "slug", "created_at", "updated_at"]

    def get_factory_count(self, obj):
        return obj.factories.count()

class FactoryDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer including related production lines, products, materials, stages, shifts, and latest telemetry.
    """
    industry_type_display = serializers.CharField(source="get_industry_type_display", read_only=True)
    factory_type_display = serializers.CharField(source="get_factory_type_display", read_only=True)
    manufacturing_model_display = serializers.CharField(source="get_manufacturing_model_display", read_only=True)
    configuration_status_display = serializers.CharField(source="get_configuration_status_display", read_only=True)
    organization = OrganizationSerializer(read_only=True)
    production_lines = ProductionLineSerializer(many=True, read_only=True)
    products = ProductSerializer(many=True, read_only=True)
    raw_materials = RawMaterialSerializer(many=True, read_only=True)
    process_stages = ProcessStageSerializer(many=True, read_only=True)
    shifts = ShiftConfigurationSerializer(many=True, read_only=True)
    latest_metrics = serializers.SerializerMethodField()

    class Meta:
        model = Factory
        fields = [
            "id",
            "name",
            "code",
            "industry_type",
            "industry_type_display",
            "industry_custom",
            "factory_type",
            "factory_type_display",
            "manufacturing_model",
            "manufacturing_model_display",
            "configuration_status",
            "configuration_status_display",
            "location",
            "country",
            "timezone",
            "operating_hours",
            "capabilities",
            "target_daily_capacity",
            "total_production_lines",
            "active_lines",
            "is_active",
            "metadata",
            "organization",
            "production_lines",
            "products",
            "raw_materials",
            "process_stages",
            "shifts",
            "latest_metrics",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(FactoryMetricSnapshotSerializer)
    def get_latest_metrics(self, obj):
        latest = obj.metric_snapshots.first()
        if latest:
            return FactoryMetricSnapshotSerializer(latest).data
        return None

class FactoryOverviewSerializer(serializers.Serializer):
    """
    Executive and Command Center operational overview payload for a single factory.
    Combines factory metadata, latest telemetry, line status aggregations and shift data.
    """
    factory = FactoryListSerializer()
    metrics = FactoryMetricSnapshotSerializer(allow_null=True)
    lines_summary = serializers.DictField()
    production_lines = ProductionLineSerializer(many=True)
    alerts_summary = serializers.DictField()
    shift_progress = serializers.DictField()
