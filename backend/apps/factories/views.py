"""
FactoryOS AI — Factory Views & Multi-Tenant Operational APIs
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils.text import slugify
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiResponse

from .models import (
    Organization,
    Factory,
    ProductionLine,
    FactoryMetricSnapshot,
    LineStatus,
    Product,
    RawMaterial,
    ProcessStage,
    ShiftConfiguration,
)
from .serializers import (
    OrganizationSerializer,
    FactoryListSerializer,
    FactoryDetailSerializer,
    FactoryOverviewSerializer,
    ProductSerializer,
    RawMaterialSerializer,
    ProcessStageSerializer,
    ShiftConfigurationSerializer,
)

# ==========================================
# COMPANY (ORGANIZATION) MANAGEMENT APIS
# ==========================================

class CompanyListCreateView(APIView):
    """
    List enterprise companies or register a new company/organization holding.
    """

    @extend_schema(
        summary="List Companies",
        description="Retrieve all companies/organizations with factory counts and active status.",
        parameters=[
            OpenApiParameter(
                name="include_archived",
                description="Include archived companies (default: false)",
                required=False,
                type=bool,
            ),
        ],
        responses={200: OrganizationSerializer(many=True)},
    )
    def get(self, request):
        include_archived = request.query_params.get("include_archived", "false").lower() == "true"
        queryset = Organization.objects.all().prefetch_related("factories")
        if not include_archived:
            queryset = queryset.filter(is_active=True)

        serializer = OrganizationSerializer(queryset, many=True)
        return Response(
            {
                "success": True,
                "count": queryset.count(),
                "results": serializer.data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Create Company",
        description="Register a new enterprise company / tenant organization.",
        request=OrganizationSerializer,
        responses={201: OrganizationSerializer},
    )
    def post(self, request):
        data = request.data.copy()
        name = data.get("name", "").strip()
        if not name:
            return Response(
                {"success": False, "error": {"message": "Company name is required."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        slug = slugify(name) or "enterprise"
        orig_slug = slug
        c = 1
        while Organization.objects.filter(slug=slug).exists():
            slug = f"{orig_slug}-{c}"
            c += 1

        org = Organization.objects.create(
            name=name,
            slug=slug,
            description=data.get("description", ""),
            website=data.get("website", ""),
            contact_email=data.get("contact_email", ""),
            is_active=True,
        )

        return Response(
            {
                "success": True,
                "data": OrganizationSerializer(org).data,
            },
            status=status.HTTP_201_CREATED,
        )

class CompanyDetailView(APIView):
    """
    View, update, or delete a specific enterprise company.
    """

    @extend_schema(
        summary="Get Company Details",
        description="Retrieve company details, metadata, and all affiliated factories.",
        responses={200: OrganizationSerializer, 404: OpenApiResponse(description="Company not found")},
    )
    def get(self, request, pk):
        org = get_object_or_404(Organization.objects.prefetch_related("factories"), pk=pk)
        return Response(
            {
                "success": True,
                "data": OrganizationSerializer(org).data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Update Company",
        description="Update company name, description, website, or contact email.",
        request=OrganizationSerializer,
        responses={200: OrganizationSerializer},
    )
    def patch(self, request, pk):
        org = get_object_or_404(Organization, pk=pk)
        name = request.data.get("name")
        if name:
            org.name = name.strip()
        if "description" in request.data:
            org.description = request.data["description"]
        if "website" in request.data:
            org.website = request.data["website"]
        if "contact_email" in request.data:
            org.contact_email = request.data["contact_email"]
        if "is_active" in request.data:
            org.is_active = bool(request.data["is_active"])

        org.save()
        return Response(
            {
                "success": True,
                "data": OrganizationSerializer(org).data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Delete Company",
        description="Delete a company and its affiliated factories.",
        responses={204: OpenApiResponse(description="Company deleted")},
    )
    def delete(self, request, pk):
        org = get_object_or_404(Organization, pk=pk)
        org.delete()
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)

class CompanyArchiveView(APIView):
    """
    Toggle archive state for a company.
    """

    @extend_schema(
        summary="Archive / Unarchive Company",
        description="Toggles the active state of a company.",
        responses={200: OrganizationSerializer},
    )
    def post(self, request, pk):
        org = get_object_or_404(Organization, pk=pk)
        org.is_active = not org.is_active
        org.save(update_fields=["is_active"])
        action = "archived" if not org.is_active else "unarchived"
        return Response(
            {
                "success": True,
                "message": f"Company '{org.name}' successfully {action}.",
                "data": OrganizationSerializer(org).data,
            },
            status=status.HTTP_200_OK,
        )

class CompanyFactoriesView(APIView):
    """
    List all factories operating under a specific enterprise company.
    """

    @extend_schema(
        summary="List Company Factories",
        description="Retrieve all factories belonging to a given company/organization.",
        responses={200: FactoryListSerializer(many=True)},
    )
    def get(self, request, pk):
        org = get_object_or_404(Organization, pk=pk)
        factories = org.factories.all()
        serializer = FactoryListSerializer(factories, many=True)
        return Response(
            {
                "success": True,
                "company": {"id": str(org.id), "name": org.name},
                "count": factories.count(),
                "results": serializer.data,
            },
            status=status.HTTP_200_OK,
        )

# ==========================================
# FACTORY MANAGEMENT APIS
# ==========================================

class FactoryListView(APIView):
    """
    List all factories with optional industry filtering, status filtering, and search.
    Used by the frontend Factory Selector and Command Center header.
    """

    @extend_schema(
        summary="List Factories",
        description="Retrieve all registered factories with industry categorization, configuration status and active line counts.",
        parameters=[
            OpenApiParameter(
                name="industry_type",
                description="Filter by industry type (TEXTILE, CNC_ENGINEERING, FOOD_PROCESSING, etc.)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="status",
                description="Filter by configuration status (CONFIGURED, IN_PROGRESS, PENDING)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="search",
                description="Search by factory name or code",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="include_archived",
                description="Include archived factories (default: false)",
                required=False,
                type=bool,
            ),
        ],
        responses={200: FactoryListSerializer(many=True)},
    )
    def get(self, request):
        include_archived = request.query_params.get("include_archived", "false").lower() == "true"
        queryset = Factory.objects.all().select_related("organization")
        if not include_archived:
            queryset = queryset.filter(is_active=True)

        industry = request.query_params.get("industry_type")
        if industry:
            queryset = queryset.filter(industry_type=industry)

        config_status = request.query_params.get("status")
        if config_status:
            queryset = queryset.filter(configuration_status=config_status)

        search = request.query_params.get("search")
        if search:
            queryset = queryset.filter(name__icontains=search) | queryset.filter(code__icontains=search)

        serializer = FactoryListSerializer(queryset, many=True)
        return Response(
            {
                "success": True,
                "count": queryset.count(),
                "results": serializer.data,
            }
        )

    @extend_schema(
        summary="Create Factory",
        description="Register a new factory under an existing enterprise company.",
        request=FactoryDetailSerializer,
        responses={201: FactoryDetailSerializer},
    )
    def post(self, request):
        data = request.data
        org_id = data.get("organization_id")
        if not org_id:
            org = Organization.objects.first()
            if not org:
                org = Organization.objects.create(name="Default Enterprise", slug="default-enterprise")
        else:
            org = get_object_or_404(Organization, pk=org_id)

        name = data.get("name", "New Manufacturing Plant").strip()
        code = data.get("code", "").strip()
        if not code or Factory.objects.filter(code=code).exists():
            import uuid, re
            prefix = re.sub(r"[^A-Za-z0-9]", "", name).upper()[:4] or "FACT"
            code = f"FAC-{prefix}-{uuid.uuid4().hex[:4].upper()}"

        factory = Factory.objects.create(
            organization=org,
            name=name,
            code=code,
            industry_type=data.get("industry_type", "CUSTOM"),
            industry_custom=data.get("industry_custom", ""),
            location=data.get("location", "Standard Industrial Park"),
            country=data.get("country", "USA"),
            timezone=data.get("timezone", "UTC"),
            operating_hours=data.get("operating_hours", "06:00 - 22:00 (Two 8h Shifts)"),
            capabilities=data.get("capabilities", []),
            target_daily_capacity=int(data.get("target_daily_capacity", 5000)),
            is_active=True,
        )

        return Response(
            {
                "success": True,
                "data": FactoryDetailSerializer(factory).data,
            },
            status=status.HTTP_201_CREATED,
        )

class FactoryDetailView(APIView):
    """
    Retrieve or update comprehensive details for a specific factory.
    """

    @extend_schema(
        summary="Get Factory Details",
        description="Retrieve factory details, production lines, products, materials, stages, shifts, and recent telemetry snapshot.",
        responses={
            200: FactoryDetailSerializer,
            404: OpenApiResponse(description="Factory not found"),
        },
    )
    def get(self, request, pk):
        factory = get_object_or_404(
            Factory.objects.prefetch_related(
                "production_lines__machines",
                "products",
                "raw_materials",
                "process_stages",
                "shifts",
                "metric_snapshots",
            ).select_related("organization"),
            pk=pk,
        )
        serializer = FactoryDetailSerializer(factory)
        return Response(
            {
                "success": True,
                "data": serializer.data,
            }
        )

    @extend_schema(
        summary="Update Factory",
        description="Update factory name, capabilities, operating hours, timezone, or location.",
        request=FactoryDetailSerializer,
        responses={200: FactoryDetailSerializer},
    )
    def patch(self, request, pk):
        factory = get_object_or_404(Factory, pk=pk)
        for field in ["name", "industry_type", "industry_custom", "location", "country", "timezone", "operating_hours", "target_daily_capacity"]:
            if field in request.data:
                setattr(factory, field, request.data[field])

        if "capabilities" in request.data:
            factory.capabilities = request.data["capabilities"]
        if "is_active" in request.data:
            factory.is_active = bool(request.data["is_active"])

        factory.save()
        return Response(
            {
                "success": True,
                "data": FactoryDetailSerializer(factory).data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Delete Factory",
        description="Delete a factory and its child production assets.",
        responses={204: OpenApiResponse(description="Factory deleted")},
    )
    def delete(self, request, pk):
        factory = get_object_or_404(Factory, pk=pk)
        factory.delete()
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)

class FactoryArchiveView(APIView):
    """
    Toggle archive state for a factory.
    """

    @extend_schema(
        summary="Archive / Unarchive Factory",
        description="Toggles the active state of a factory without deleting operational telemetry.",
        responses={200: FactoryListSerializer},
    )
    def post(self, request, pk):
        factory = get_object_or_404(Factory, pk=pk)
        factory.is_active = not factory.is_active
        factory.save(update_fields=["is_active"])
        action = "archived" if not factory.is_active else "unarchived"
        return Response(
            {
                "success": True,
                "message": f"Factory '{factory.name}' successfully {action}.",
                "data": FactoryListSerializer(factory).data,
            },
            status=status.HTTP_200_OK,
        )

class FactoryOverviewView(APIView):
    """
    Get full Command Center operational overview for a factory:
    - Real-time OEE, Availability, Performance, Quality
    - Production lines grouped by status (Running, Idle, Maintenance, Offline)
    - Shift production progress vs planned target
    - Energy consumption and active operational alerts
    """

    @extend_schema(
        summary="Get Factory Operational Overview",
        description="Consolidated telemetry, KPI calculations, and line status breakdown for the Factory Command Center.",
        responses={
            200: FactoryOverviewSerializer,
            404: OpenApiResponse(description="Factory not found"),
        },
    )
    def get(self, request, pk):
        factory = get_object_or_404(
            Factory.objects.prefetch_related("production_lines", "metric_snapshots").select_related("organization"),
            pk=pk,
        )

        lines = list(factory.production_lines.all())
        latest_metrics = factory.metric_snapshots.first()

        # Aggregate line statuses
        total_lines = len(lines)
        running_lines = sum(1 for l in lines if l.status == LineStatus.RUNNING)
        idle_lines = sum(1 for l in lines if l.status == LineStatus.IDLE)
        maintenance_lines = sum(1 for l in lines if l.status == LineStatus.MAINTENANCE)
        offline_lines = sum(1 for l in lines if l.status == LineStatus.OFFLINE)

        # Average efficiency across running lines
        avg_efficiency = (
            round(sum(l.efficiency_rate for l in lines) / total_lines, 1)
            if total_lines > 0
            else 0.0
        )

        # Shift production progress
        planned = latest_metrics.planned_units if latest_metrics else 1000
        actual = latest_metrics.actual_units if latest_metrics else 950
        scrap = latest_metrics.scrap_units if latest_metrics else 10
        completion_pct = round((actual / planned) * 100, 1) if planned > 0 else 0.0

        overview_payload = {
            "factory": FactoryListSerializer(factory).data,
            "metrics": (
                {
                    "id": str(latest_metrics.id),
                    "overall_oee": latest_metrics.overall_oee,
                    "availability": latest_metrics.availability,
                    "performance": latest_metrics.performance,
                    "quality_rate": latest_metrics.quality_rate,
                    "energy_consumption_kwh": latest_metrics.energy_consumption_kwh,
                    "active_alerts_count": latest_metrics.active_alerts_count,
                    "active_shifts": latest_metrics.active_shifts,
                    "planned_units": latest_metrics.planned_units,
                    "actual_units": latest_metrics.actual_units,
                    "scrap_units": latest_metrics.scrap_units,
                    "timestamp": latest_metrics.timestamp.isoformat(),
                }
                if latest_metrics
                else None
            ),
            "lines_summary": {
                "total": total_lines,
                "running": running_lines,
                "idle": idle_lines,
                "maintenance": maintenance_lines,
                "offline": offline_lines,
                "average_efficiency": avg_efficiency,
            },
            "production_lines": [
                {
                    "id": str(l.id),
                    "name": l.name,
                    "code": l.code,
                    "status": l.status,
                    "status_display": l.get_status_display(),
                    "current_product": l.current_product,
                    "efficiency_rate": l.efficiency_rate,
                    "target_hourly_units": l.target_hourly_units,
                    "actual_hourly_units": l.actual_hourly_units,
                    "operator_count": l.operator_count,
                    "last_maintenance_date": (
                        l.last_maintenance_date.isoformat()
                        if l.last_maintenance_date
                        else None
                    ),
                    "metadata": l.metadata,
                }
                for l in lines
            ],
            "alerts_summary": {
                "critical": 0,
                "warning": latest_metrics.active_alerts_count if latest_metrics else 1,
                "info": 2,
                "total_active": latest_metrics.active_alerts_count if latest_metrics else 1,
            },
            "shift_progress": {
                "planned_units": planned,
                "actual_units": actual,
                "scrap_units": scrap,
                "completion_percentage": completion_pct,
                "current_shift": "Day Shift 01 (06:00 - 14:00)",
            },
        }

        return Response(
            {
                "success": True,
                "data": overview_payload,
            }
        )

class FactoryProductListView(APIView):
    """
    List products belonging to a specific factory.
    """
    @extend_schema(summary="List Factory Products", responses={200: ProductSerializer(many=True)})
    def get(self, request, pk):
        factory = get_object_or_404(Factory, pk=pk)
        products = Product.objects.filter(factory=factory).order_by("name")
        serializer = ProductSerializer(products, many=True)
        return Response({
            "success": True,
            "count": products.count(),
            "results": serializer.data,
        })

