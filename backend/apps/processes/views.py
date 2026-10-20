"""
FactoryOS AI — Universal Process Engine Views & REST APIs
Phase 3: APIs for Process Builder, Work Orders, Execution Engine, Materials & Simulation
"""
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db import transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from drf_spectacular.utils import extend_schema, OpenApiResponse

from apps.factories.models import Factory, Product, ProductionLine, Machine, IndustryType
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
from apps.processes.serializers import (
    ProcessDefinitionSerializer,
    ProcessDefinitionDetailSerializer,
    ProcessVersionSerializer,
    ProcessVersionDetailSerializer,
    ProcessNodeSerializer,
    ProcessEdgeSerializer,
    WorkOrderSerializer,
    ProcessExecutionSerializer,
    StageExecutionSerializer,
    MaterialFlowSerializer,
    ProductionEventSerializer,
    SimulationScenarioSerializer,
)
from apps.processes.services.graph_validator import ProcessGraphValidator
from apps.processes.services.execution_service import ProductionExecutionService
from apps.processes.services.simulation_service import ManufacturingSimulationEngine
from apps.processes.services.template_service import ProcessTemplateService

# ==============================================================================
# 0. UNIVERSAL PROCESS TEMPLATES
# ==============================================================================

class ProcessTemplateListView(APIView):
    """
    List universal manufacturing process templates with optional filtering.
    """
    @extend_schema(summary="List Universal Process Templates")
    def get(self, request):
        industry_type = request.query_params.get("industry_type")
        category = request.query_params.get("category")

        if industry_type:
            industry_type = industry_type.strip().upper()
            if industry_type not in IndustryType.values:
                return Response(
                    {
                        "success": False,
                        "error": {
                            "message": f"Invalid industry_type '{industry_type}'. Allowed choices: {', '.join(IndustryType.values)}"
                        },
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

        templates = ProcessTemplateService.get_templates()
        if industry_type:
            templates = [t for t in templates if t["industry_type"] == industry_type]
        if category:
            cat_str = category.strip().lower()
            templates = [t for t in templates if cat_str in t.get("category", "").lower()]

        return Response({"success": True, "count": len(templates), "results": templates})


def check_factory_authorization(request, factory):
    """
    Validates tenant isolation and factory access.
    - Rejects if factory or its organization is archived or inactive.
    - If user is authenticated, ensures user belongs to factory's organization or has direct factory access.
    - If X-Organization-ID header is present, verifies factory belongs to that organization.
    """
    if not factory.is_active:
        return False, f"Target factory '{factory.name}' is inactive or archived.", status.HTTP_400_BAD_REQUEST

    if not factory.organization.is_active:
        return False, f"Organization '{factory.organization.name}' is inactive or archived.", status.HTTP_400_BAD_REQUEST

    # Scoped user check if request user is authenticated
    if hasattr(request, "user") and request.user and request.user.is_authenticated:
        user_org = getattr(request.user, "organization", None)
        if user_org and user_org != factory.organization:
            return False, "User does not have authorization to access this factory.", status.HTTP_403_FORBIDDEN
        user_factory = getattr(request.user, "factory", None)
        if user_factory and user_factory != factory:
            return False, "User does not have authorization to access this factory.", status.HTTP_403_FORBIDDEN

    # Tenant isolation header check if provided
    org_header = request.headers.get("X-Organization-ID") or request.headers.get("X-Organization-Id")
    if org_header:
        if str(factory.organization_id) != str(org_header):
            return False, "Factory does not belong to the authorized organization context.", status.HTTP_403_FORBIDDEN

    return True, None, None


class ProcessTemplateInstantiateView(APIView):
    """
    Instantiates a universal process template into a concrete factory process definition.
    """
    @extend_schema(
        summary="Instantiate Process Template",
        responses={201: ProcessDefinitionDetailSerializer},
    )
    def post(self, request, template_key):
        template = ProcessTemplateService.get_template_by_key(template_key)
        if not template:
            return Response(
                {
                    "success": False,
                    "error": {"message": f"Universal process template '{template_key}' does not exist."},
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        data = request.data or {}
        factory_id = data.get("factory") or data.get("factory_id")
        if not factory_id:
            return Response(
                {"success": False, "error": {"message": "Factory ID ('factory' or 'factory_id') is required."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        factory = get_object_or_404(Factory, pk=factory_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )

        try:
            proc, ver = ProcessTemplateService.instantiate_template(
                template_key=template_key,
                factory=factory,
                name=data.get("name"),
                code=data.get("code"),
                description=data.get("description"),
                target_cycle_time_seconds=data.get("target_cycle_time_seconds"),
            )
            serializer = ProcessDefinitionDetailSerializer(proc)
            return Response(
                {
                    "success": True,
                    "message": f"Process '{proc.name}' instantiated from template '{template['name']}'.",
                    "data": serializer.data,
                },
                status=status.HTTP_201_CREATED,
            )
        except ValueError as e:
            return Response(
                {"success": False, "error": {"message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )


# ==============================================================================
# 1. PROCESS DEFINITIONS
# ==============================================================================

class ProcessDefinitionListCreateView(APIView):
    """
    List and create manufacturing process definitions.
    """
    @extend_schema(
        summary="List Process Definitions",
        responses={200: ProcessDefinitionSerializer(many=True)},
    )
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        qs = ProcessDefinition.objects.select_related("factory").prefetch_related("versions").all()
        if factory_id:
            qs = qs.filter(factory_id=factory_id)
        serializer = ProcessDefinitionSerializer(qs, many=True)
        return Response({"success": True, "count": qs.count(), "results": serializer.data})

    @extend_schema(
        summary="Create Process Definition",
        request=ProcessDefinitionSerializer,
        responses={201: ProcessDefinitionDetailSerializer},
    )
    def post(self, request):
        data = request.data
        factory_id = data.get("factory") or data.get("factory_id")
        factory = get_object_or_404(Factory, pk=factory_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )

        code = data.get("code", "").strip().upper()
        name = data.get("name", "").strip()
        if not code or not name:
            return Response(
                {"success": False, "error": {"message": "Process name and code are required."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if ProcessDefinition.objects.filter(factory=factory, code=code).exists():
            return Response(
                {"success": False, "error": {"message": f"Process definition with code '{code}' already exists in this factory."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        proc = ProcessDefinition.objects.create(
            factory=factory,
            name=name,
            code=code,
            description=data.get("description", ""),
            category=data.get("category", "General Manufacturing"),
            industry_type=data.get("industry_type") or factory.industry_type,
            target_cycle_time_seconds=float(data.get("target_cycle_time_seconds", 60.0)),
        )

        # Initialize Draft Version 1 with default Start and End nodes
        v1 = ProcessVersion.objects.create(
            process_definition=proc,
            version_number=1,
            version_tag="v1.0.0",
            status="DRAFT",
            change_summary="Initial process graph definition.",
        )
        start_node = ProcessNode.objects.create(
            process_version=v1,
            node_key="START-01",
            name="Process Start",
            node_type="START",
            position_x=100.0,
            position_y=250.0,
            cycle_time_seconds=0.0,
        )
        end_node = ProcessNode.objects.create(
            process_version=v1,
            node_key="END-01",
            name="Process Completion",
            node_type="END",
            position_x=800.0,
            position_y=250.0,
            cycle_time_seconds=0.0,
        )
        # Default operation
        op_node = ProcessNode.objects.create(
            process_version=v1,
            node_key="OP-01",
            name=f"{proc.name} Operation 1",
            node_type="OPERATION",
            position_x=450.0,
            position_y=250.0,
            cycle_time_seconds=proc.target_cycle_time_seconds,
        )
        ProcessEdge.objects.create(
            process_version=v1,
            edge_key="EDGE-01",
            source_node=start_node,
            target_node=op_node,
            edge_type="STANDARD",
        )
        ProcessEdge.objects.create(
            process_version=v1,
            edge_key="EDGE-02",
            source_node=op_node,
            target_node=end_node,
            edge_type="STANDARD",
        )

        serializer = ProcessDefinitionDetailSerializer(proc)
        return Response({"success": True, "data": serializer.data}, status=status.HTTP_201_CREATED)

class ProcessDefinitionDetailView(APIView):
    """
    Retrieve, update or delete a process definition.
    """
    @extend_schema(summary="Get Process Definition", responses={200: ProcessDefinitionDetailSerializer})
    def get(self, request, pk):
        proc = get_object_or_404(ProcessDefinition.objects.select_related("factory").prefetch_related("versions"), pk=pk)
        return Response({"success": True, "data": ProcessDefinitionDetailSerializer(proc).data})

    @extend_schema(summary="Update Process Definition", responses={200: ProcessDefinitionSerializer})
    def patch(self, request, pk):
        proc = get_object_or_404(ProcessDefinition, pk=pk)
        data = request.data
        if "name" in data:
            proc.name = data["name"].strip()
        if "description" in data:
            proc.description = data["description"]
        if "category" in data:
            proc.category = data["category"]
        if "industry_type" in data:
            proc.industry_type = data["industry_type"]
        if "target_cycle_time_seconds" in data:
            proc.target_cycle_time_seconds = float(data["target_cycle_time_seconds"])
        if "is_active" in data:
            proc.is_active = bool(data["is_active"])
        proc.save()
        return Response({"success": True, "data": ProcessDefinitionSerializer(proc).data})

    @extend_schema(summary="Delete Process Definition", responses={204: OpenApiResponse(description="Deleted")})
    def delete(self, request, pk):
        proc = get_object_or_404(ProcessDefinition, pk=pk)
        proc.delete()
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)


class ProcessDefinitionDuplicateView(APIView):
    """
    Duplicate a process definition and its graph into a new editable draft.
    """
    @extend_schema(
        summary="Duplicate Process Definition",
        responses={201: ProcessDefinitionDetailSerializer},
    )
    def post(self, request, pk):
        proc = get_object_or_404(ProcessDefinition, pk=pk)
        is_auth, err_msg, err_status = check_factory_authorization(request, proc.factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )
        data = request.data or {}
        new_name = data.get("name")
        new_code = data.get("code")
        new_desc = data.get("description")

        try:
            new_proc, new_ver = ProcessTemplateService.duplicate_process_definition(
                source_proc=proc,
                new_name=new_name,
                new_code=new_code,
                new_description=new_desc,
            )
            serializer = ProcessDefinitionDetailSerializer(new_proc)
            return Response(
                {
                    "success": True,
                    "message": f"Process definition '{new_proc.name}' duplicated successfully.",
                    "data": serializer.data,
                },
                status=status.HTTP_201_CREATED,
            )
        except ValueError as e:
            return Response(
                {"success": False, "error": {"message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )


class ProcessDefinitionArchiveView(APIView):
    """
    Safely archives a process definition without deleting records.
    Blocks archival if active work orders exist.
    """
    @extend_schema(
        summary="Archive Process Definition",
        responses={200: ProcessDefinitionSerializer},
    )
    def post(self, request, pk):
        proc = get_object_or_404(ProcessDefinition, pk=pk)
        is_auth, err_msg, err_status = check_factory_authorization(request, proc.factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )
        was_already_archived = not proc.is_active
        success, error_msg = ProcessTemplateService.archive_process_definition(proc)
        if not success:
            return Response(
                {
                    "success": False,
                    "error": {
                        "code": "ACTIVE_WORK_ORDERS_EXIST",
                        "message": error_msg,
                    },
                },
                status=status.HTTP_409_CONFLICT,
            )

        serializer = ProcessDefinitionSerializer(proc)
        msg = (
            f"Process definition '{proc.name}' is already archived."
            if was_already_archived
            else f"Process definition '{proc.name}' has been safely archived."
        )
        return Response(
            {
                "success": True,
                "message": msg,
                "data": serializer.data,
            },
            status=status.HTTP_200_OK,
        )

# ==============================================================================
# 2. PROCESS VERSIONS & GRAPH VALIDATION / PUBLISHING
# ==============================================================================

class ProcessVersionDetailView(APIView):
    """
    Retrieve full version graph detail (nodes and edges) for canvas rendering.
    """
    @extend_schema(summary="Get Process Version Graph", responses={200: ProcessVersionDetailSerializer})
    def get(self, request, pk):
        version = get_object_or_404(
            ProcessVersion.objects.prefetch_related("nodes", "edges", "nodes__assigned_machine", "nodes__assigned_line"),
            pk=pk
        )
        return Response({"success": True, "data": ProcessVersionDetailSerializer(version).data})

class ProcessVersionCloneView(APIView):
    """
    Clones an existing version into a new editable DRAFT version.
    """
    def post(self, request, pk):
        source_ver = ProcessVersion.objects.filter(pk=pk).first()
        if not source_ver:
            proc = get_object_or_404(ProcessDefinition, pk=pk)
            source_ver = proc.published_version or proc.latest_version
            if not source_ver:
                return Response(
                    {"success": False, "error": {"message": "No version available to clone."}},
                    status=status.HTTP_404_NOT_FOUND,
                )
        else:
            proc = source_ver.process_definition

        new_ver_num = proc.versions.count() + 1
        new_tag = f"v{new_ver_num}.0.0-draft"
        new_ver = ProcessVersion.objects.create(
            process_definition=proc,
            version_number=new_ver_num,
            version_tag=new_tag,
            status="DRAFT",
            change_summary=f"Cloned from {source_ver.version_tag}",
            graph_metadata=source_ver.graph_metadata,
        )

        # Deep clone nodes and edges
        node_map = {}
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

        return Response({"success": True, "data": ProcessVersionDetailSerializer(new_ver).data}, status=status.HTTP_201_CREATED)

class ProcessVersionValidateView(APIView):
    """
    Validates process graph topology, cycle detection, and connectivity.
    """
    @extend_schema(summary="Validate Process Graph")
    def post(self, request, pk):
        version = get_object_or_404(ProcessVersion, pk=pk)
        is_valid, errors, warnings = ProcessGraphValidator.validate_version(version)

        version.validation_errors = errors
        if is_valid and version.status == "DRAFT":
            version.status = "VALIDATED"
        elif not is_valid and version.status == "VALIDATED":
            version.status = "DRAFT"
        version.save(update_fields=["validation_errors", "status", "updated_at"])

        invalid_keys = set()
        node_keys = set(version.nodes.values_list("node_key", flat=True))
        for err in errors:
            for k in node_keys:
                if f"'{k}'" in err or f": {k}" in err or f" {k}," in err or f", {k}" in err or f" {k} " in err:
                    invalid_keys.add(k)

        return Response({
            "success": True,
            "is_valid": is_valid,
            "status": version.status,
            "errors": errors,
            "warnings": warnings,
            "invalid_node_keys": sorted(list(invalid_keys)),
        })

class ProcessVersionPublishView(APIView):
    """
    Validates and publishes a process version, making it available for work orders.
    Enforces immutability: once published, the version cannot be edited directly.
    """
    @extend_schema(summary="Publish Process Version")
    def post(self, request, pk):
        version = get_object_or_404(ProcessVersion, pk=pk)
        is_valid, errors, warnings = ProcessGraphValidator.validate_version(version)

        if not is_valid:
            invalid_keys = set()
            node_keys = set(version.nodes.values_list("node_key", flat=True))
            for err in errors:
                for k in node_keys:
                    if f"'{k}'" in err or f": {k}" in err or f" {k}," in err or f", {k}" in err or f" {k} " in err:
                        invalid_keys.add(k)

            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "Cannot publish invalid process graph. Resolve validation errors first.",
                        "errors": errors,
                        "validation_errors": errors,
                        "warnings": warnings,
                        "invalid_node_keys": sorted(list(invalid_keys)),
                    }
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Archive previous published versions of this definition
        version.process_definition.versions.filter(status="PUBLISHED").update(status="ARCHIVED", is_published=False)

        version.status = "PUBLISHED"
        version.is_published = True
        version.published_at = timezone.now()
        version.validation_errors = []
        version.save(update_fields=["status", "is_published", "published_at", "validation_errors", "updated_at"])

        ProductionEvent.objects.create(
            factory=version.process_definition.factory,
            event_type="PROCESS_VERSION_PUBLISHED",
            severity="INFO",
            source="OPERATOR",
            message=f"Process version '{version.version_tag}' for '{version.process_definition.name}' published into production.",
            payload={"version_id": str(version.id), "tag": version.version_tag}
        )

        return Response({
            "success": True,
            "message": f"Version '{version.version_tag}' published successfully.",
            "data": ProcessVersionDetailSerializer(version).data,
        })

class ProcessVersionLayoutView(APIView):
    """
    Save canvas layout metadata (zoom, pan, node visual coordinates).
    """
    @extend_schema(summary="Save Process Graph Layout")
    def put(self, request, pk):
        version = get_object_or_404(ProcessVersion, pk=pk)
        if version.is_published:
            return Response(
                {"success": False, "error": {"message": "Published versions are immutable. Clone a new draft version to edit."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        metadata = request.data.get("graph_metadata")
        if metadata and isinstance(metadata, dict):
            version.graph_metadata = metadata
            version.save(update_fields=["graph_metadata", "updated_at"])

        nodes_data = request.data.get("nodes", [])
        for nd in nodes_data:
            node_id = nd.get("id")
            if node_id:
                ProcessNode.objects.filter(id=node_id, process_version=version).update(
                    position_x=float(nd.get("position_x", 0.0)),
                    position_y=float(nd.get("position_y", 0.0)),
                )

        return Response({"success": True, "message": "Graph layout saved successfully."})

# ==============================================================================
# 3. NODES & EDGES API
# ==============================================================================

class ProcessNodeListCreateView(APIView):
    """
    Add a node to a draft process version.
    """
    @extend_schema(summary="Add Process Node", request=ProcessNodeSerializer, responses={201: ProcessNodeSerializer})
    def post(self, request, version_id):
        version = get_object_or_404(ProcessVersion, pk=version_id)
        if version.is_published:
            return Response(
                {"success": False, "error": {"message": "Published versions are immutable."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = request.data
        node_key = data.get("node_key") or f"NODE-{version.nodes.count() + 1:02d}"
        if ProcessNode.objects.filter(process_version=version, node_key=node_key).exists():
            node_key = f"{node_key}-{version.nodes.count() + 1}"

        node = ProcessNode.objects.create(
            process_version=version,
            node_key=node_key,
            name=data.get("name", "New Operation"),
            node_type=data.get("node_type", "OPERATION"),
            position_x=float(data.get("position_x", 200.0)),
            position_y=float(data.get("position_y", 200.0)),
            cycle_time_seconds=float(data.get("cycle_time_seconds", 30.0)),
            setup_time_seconds=float(data.get("setup_time_seconds", 0.0)),
            standard_capacity_per_hour=int(data.get("standard_capacity_per_hour", 60)),
            assigned_line_id=data.get("assigned_line"),
            assigned_machine_id=data.get("assigned_machine"),
            required_operators=int(data.get("required_operators", 1)),
            operator_role=data.get("operator_role", ""),
            required_skills=data.get("required_skills", []),
            resource_spec=data.get("resource_spec", {}),
            input_materials=data.get("input_materials", []),
            output_materials=data.get("output_materials", []),
            yield_rate_percent=float(data.get("yield_rate_percent", 100.0)),
        )

        version.status = "DRAFT"
        version.save(update_fields=["status", "updated_at"])

        return Response({"success": True, "data": ProcessNodeSerializer(node).data}, status=status.HTTP_201_CREATED)

class ProcessNodeDetailView(APIView):
    """
    Update or delete a process node.
    """
    @extend_schema(summary="Update Process Node", request=ProcessNodeSerializer, responses={200: ProcessNodeSerializer})
    def patch(self, request, pk):
        node = get_object_or_404(ProcessNode, pk=pk)
        if node.process_version.is_published:
            return Response(
                {"success": False, "error": {"message": "Published versions are immutable."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = request.data
        for field in [
            "name", "node_type", "cycle_time_seconds", "setup_time_seconds", "standard_capacity_per_hour",
            "required_operators", "operator_role", "required_skills", "resource_spec", "input_materials", "output_materials",
            "yield_rate_percent", "configuration", "position_x", "position_y"
        ]:
            if field in data:
                setattr(node, field, data[field])

        if "assigned_line" in data:
            node.assigned_line_id = data["assigned_line"]
        if "assigned_machine" in data:
            node.assigned_machine_id = data["assigned_machine"]

        node.save()
        node.process_version.status = "DRAFT"
        node.process_version.save(update_fields=["status", "updated_at"])

        return Response({"success": True, "data": ProcessNodeSerializer(node).data})

    @extend_schema(summary="Delete Process Node", responses={204: OpenApiResponse(description="Deleted")})
    def delete(self, request, pk):
        node = get_object_or_404(ProcessNode, pk=pk)
        if node.process_version.is_published:
            return Response(
                {"success": False, "error": {"message": "Published versions are immutable."}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        version = node.process_version
        node.delete()
        version.status = "DRAFT"
        version.save(update_fields=["status", "updated_at"])
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)

class ProcessEdgeListCreateView(APIView):
    """
    Create a directed edge between two process nodes.
    """
    @extend_schema(summary="Create Process Edge", request=ProcessEdgeSerializer, responses={201: ProcessEdgeSerializer})
    def post(self, request, version_id):
        version = get_object_or_404(ProcessVersion, pk=version_id)
        if version.is_published:
            return Response(
                {"success": False, "error": {"message": "Published versions are immutable."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = request.data
        src_id = data.get("source_node")
        tgt_id = data.get("target_node")

        src = get_object_or_404(ProcessNode, pk=src_id, process_version=version)
        tgt = get_object_or_404(ProcessNode, pk=tgt_id, process_version=version)

        if src.id == tgt.id:
            return Response(
                {"success": False, "error": {"message": "Cannot create self-loop edge on a node."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if ProcessEdge.objects.filter(source_node=src, target_node=tgt).exists():
            return Response(
                {"success": False, "error": {"message": "An edge already exists between these two nodes."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        edge_key = data.get("edge_key") or f"EDGE-{version.edges.count() + 1:02d}"
        if ProcessEdge.objects.filter(process_version=version, edge_key=edge_key).exists():
            edge_key = f"{edge_key}-{version.edges.count() + 1}"

        edge = ProcessEdge.objects.create(
            process_version=version,
            edge_key=edge_key,
            source_node=src,
            target_node=tgt,
            edge_type=data.get("edge_type", "STANDARD"),
            condition_expression=data.get("condition_expression", ""),
            label=data.get("label", ""),
            priority=int(data.get("priority", 0)),
        )

        version.status = "DRAFT"
        version.save(update_fields=["status", "updated_at"])

        return Response({"success": True, "data": ProcessEdgeSerializer(edge).data}, status=status.HTTP_201_CREATED)

class ProcessEdgeDetailView(APIView):
    """
    Delete a process edge.
    """
    @extend_schema(summary="Delete Process Edge", responses={204: OpenApiResponse(description="Deleted")})
    def delete(self, request, pk):
        edge = get_object_or_404(ProcessEdge, pk=pk)
        if edge.process_version.is_published:
            return Response(
                {"success": False, "error": {"message": "Published versions are immutable."}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        version = edge.process_version
        edge.delete()
        version.status = "DRAFT"
        version.save(update_fields=["status", "updated_at"])
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)

# ==============================================================================
# 4. WORK ORDERS API
# ==============================================================================

class WorkOrderListCreateView(APIView):
    """
    List and create manufacturing work orders.
    """
    @extend_schema(summary="List Work Orders", responses={200: WorkOrderSerializer(many=True)})
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        status_param = request.query_params.get("status")
        qs = WorkOrder.objects.select_related(
            "factory", "product", "process_definition", "process_version", "assigned_line"
        ).all()
        if factory_id:
            factory = get_object_or_404(Factory, pk=factory_id)
            is_auth, err_msg, err_status = check_factory_authorization(request, factory)
            if not is_auth:
                return Response(
                    {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                    status=err_status,
                )
            qs = qs.filter(factory_id=factory_id)
        elif hasattr(request, "user") and request.user and request.user.is_authenticated:
            user_org = getattr(request.user, "organization", None)
            if user_org:
                qs = qs.filter(factory__organization=user_org)
            user_factory = getattr(request.user, "factory", None)
            if user_factory:
                qs = qs.filter(factory=user_factory)
        if status_param:
            qs = qs.filter(status=status_param.upper())

        serializer = WorkOrderSerializer(qs, many=True)
        return Response({"success": True, "count": qs.count(), "results": serializer.data})

    @extend_schema(summary="Create Work Order", request=WorkOrderSerializer, responses={201: WorkOrderSerializer})
    @transaction.atomic
    def post(self, request):
        data = request.data
        factory_id = data.get("factory") or data.get("factory_id")
        if not factory_id:
            return Response({"success": False, "error": {"message": "Factory ID is required."}}, status=status.HTTP_400_BAD_REQUEST)
        factory = get_object_or_404(Factory, pk=factory_id)
        is_auth, err_msg, err_status = check_factory_authorization(request, factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )

        product_id = data.get("product") or data.get("product_id")
        if not product_id:
            return Response({"success": False, "error": {"message": "Product is required."}}, status=status.HTTP_400_BAD_REQUEST)
        product = get_object_or_404(Product, pk=product_id)

        proc_id = data.get("process_definition") or data.get("process_definition_id")
        if not proc_id:
            return Response({"success": False, "error": {"message": "Process definition is required."}}, status=status.HTTP_400_BAD_REQUEST)
        proc_def = get_object_or_404(ProcessDefinition, pk=proc_id)

        version_id = data.get("process_version") or data.get("process_version_id")
        version = get_object_or_404(ProcessVersion, pk=version_id) if version_id else None

        line_id = data.get("assigned_line")
        line = get_object_or_404(ProductionLine, pk=line_id) if line_id else None

        order_num = data.get("order_number")
        if not order_num or not str(order_num).strip():
            order_num = f"WO-{timezone.now().strftime('%Y%m%d')}-{WorkOrder.objects.filter(factory=factory).count() + 1:03d}"
        else:
            order_num = str(order_num).strip()

        raw_qty = data.get("quantity_target", 100)
        try:
            qty = int(raw_qty)
        except (ValueError, TypeError):
            return Response({"success": False, "error": {"message": "Target quantity must be a valid integer."}}, status=status.HTTP_400_BAD_REQUEST)

        planned_start = data.get("planned_start_date")
        planned_due = data.get("planned_due_date")
        status_val = data.get("status", "RELEASED")

        try:
            wo = ProductionExecutionService.create_work_order(
                factory=factory,
                order_number=order_num,
                product=product,
                process_definition=proc_def,
                process_version=version,
                assigned_line=line,
                quantity_target=qty,
                status=status_val,
                priority=data.get("priority", "NORMAL"),
                planned_start_date=planned_start,
                planned_due_date=planned_due,
                notes=data.get("notes", ""),
            )
            return Response({"success": True, "data": WorkOrderSerializer(wo).data}, status=status.HTTP_201_CREATED)
        except ValueError as e:
            return Response({"success": False, "error": {"message": str(e)}}, status=status.HTTP_400_BAD_REQUEST)

class WorkOrderDetailView(APIView):
    """
    Retrieve or update a specific work order.
    """
    @extend_schema(summary="Get Work Order", responses={200: WorkOrderSerializer})
    def get(self, request, pk):
        wo = get_object_or_404(WorkOrder.objects.select_related("factory", "product", "process_definition", "process_version", "assigned_line"), pk=pk)
        is_auth, err_msg, err_status = check_factory_authorization(request, wo.factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )
        return Response({"success": True, "data": WorkOrderSerializer(wo).data})

class WorkOrderActionView(APIView):
    """
    Release, Start, Pause, Resume, Complete, or Cancel a work order with transition guards.
    """
    @extend_schema(summary="Execute Work Order Action")
    @transaction.atomic
    def post(self, request, pk, action):
        wo = get_object_or_404(WorkOrder.objects.select_related("factory", "process_definition", "process_version"), pk=pk)
        is_auth, err_msg, err_status = check_factory_authorization(request, wo.factory)
        if not is_auth:
            return Response(
                {"success": False, "error": {"code": "FORBIDDEN" if err_status == status.HTTP_403_FORBIDDEN else "FACTORY_INACTIVE", "message": err_msg}},
                status=err_status,
            )
        action = action.lower()

        if action == "release":
            if wo.status not in ("DRAFT", "PLANNED"):
                return Response(
                    {"success": False, "error": {"message": f"Cannot release work order in '{wo.status}' status (must be DRAFT or PLANNED)."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if not wo.process_definition.is_active:
                return Response(
                    {"success": False, "error": {"message": f"Cannot release work order against inactive or archived process definition '{wo.process_definition.name}'."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if not wo.process_version.is_published or wo.process_version.status != "PUBLISHED":
                return Response(
                    {"success": False, "error": {"message": f"Cannot release work order referencing non-published process version '{wo.process_version.version_tag}'."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            wo.status = "RELEASED"
            wo.save(update_fields=["status", "updated_at"])
            ProductionEvent.objects.create(
                factory=wo.factory,
                work_order=wo,
                event_type="WORK_ORDER_RELEASED",
                severity="INFO",
                source="OPERATOR",
                message=f"Work order '{wo.order_number}' released to shop floor.",
                payload={"status": "RELEASED"}
            )
            return Response({"success": True, "message": "Work order released.", "work_order": WorkOrderSerializer(wo).data})

        elif action == "start":
            if wo.status in ("COMPLETED", "CANCELLED"):
                return Response(
                    {"success": False, "error": {"message": f"Cannot start work order in terminal '{wo.status}' status."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if not wo.process_definition.is_active:
                return Response(
                    {"success": False, "error": {"message": f"Cannot start work order against inactive or archived process definition '{wo.process_definition.name}'."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            mode = request.data.get("mode", "SIMULATION")
            exec_run = ProductionExecutionService.start_execution(wo, mode=mode)
            return Response({
                "success": True,
                "message": f"Work order '{wo.order_number}' execution started.",
                "execution": ProcessExecutionSerializer(exec_run).data,
                "work_order": WorkOrderSerializer(wo).data,
            })

        elif action == "pause":
            if wo.status != "IN_PROGRESS":
                return Response(
                    {"success": False, "error": {"message": f"Cannot pause work order in '{wo.status}' status (only IN_PROGRESS orders can be paused)."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            active_exec = wo.executions.filter(status="RUNNING").first()
            if active_exec:
                ProductionExecutionService.pause_execution(active_exec, reason=request.data.get("reason", "Operator hold"))
            wo.status = "PAUSED"
            wo.save(update_fields=["status", "updated_at"])
            return Response({"success": True, "message": "Work order paused.", "work_order": WorkOrderSerializer(wo).data})

        elif action == "resume":
            if wo.status != "PAUSED":
                return Response(
                    {"success": False, "error": {"message": f"Cannot resume work order in '{wo.status}' status (only PAUSED orders can be resumed)."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if not wo.process_definition.is_active:
                return Response(
                    {"success": False, "error": {"message": f"Cannot resume work order against inactive or archived process definition '{wo.process_definition.name}'."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            paused_exec = wo.executions.filter(status="PAUSED").first()
            if paused_exec:
                ProductionExecutionService.resume_execution(paused_exec)
            wo.status = "IN_PROGRESS"
            wo.save(update_fields=["status", "updated_at"])
            return Response({"success": True, "message": "Work order resumed.", "work_order": WorkOrderSerializer(wo).data})

        elif action == "complete":
            if wo.status in ("COMPLETED", "CANCELLED"):
                return Response(
                    {"success": False, "error": {"message": f"Work order is already {wo.status.lower()}."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            active_exec = wo.executions.filter(status__in=["RUNNING", "PAUSED"]).first()
            if active_exec:
                active_exec.status = "COMPLETED"
                active_exec.completed_at = timezone.now()
                active_exec.total_units_output = wo.quantity_target
                active_exec.current_progress_percent = 100.0
                active_exec.save(update_fields=["status", "completed_at", "total_units_output", "current_progress_percent", "updated_at"])
            wo.status = "COMPLETED"
            wo.quantity_completed = wo.quantity_target
            wo.actual_end_date = timezone.now()
            wo.save(update_fields=["status", "quantity_completed", "actual_end_date", "updated_at"])

            ProductionEvent.objects.create(
                factory=wo.factory,
                work_order=wo,
                event_type="WORK_ORDER_COMPLETED",
                severity="INFO",
                source="OPERATOR",
                message=f"Work order '{wo.order_number}' marked as completed by operator.",
                payload={"quantity_completed": wo.quantity_target}
            )
            return Response({"success": True, "message": "Work order marked as completed.", "work_order": WorkOrderSerializer(wo).data})

        elif action == "cancel":
            if wo.status == "COMPLETED":
                return Response(
                    {"success": False, "error": {"message": "Cannot cancel a completed work order."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
            wo.status = "CANCELLED"
            wo.save(update_fields=["status", "updated_at"])
            wo.executions.filter(status__in=["INITIALIZED", "RUNNING", "PAUSED"]).update(status="FAILED")
            ProductionEvent.objects.create(
                factory=wo.factory,
                work_order=wo,
                event_type="WORK_ORDER_CANCELLED",
                severity="WARNING",
                source="OPERATOR",
                message=f"Work order '{wo.order_number}' cancelled by operator.",
                payload={"status": "CANCELLED"}
            )
            return Response({"success": True, "message": "Work order cancelled.", "work_order": WorkOrderSerializer(wo).data})

        return Response({"success": False, "error": {"message": f"Unknown action '{action}'."}}, status=status.HTTP_400_BAD_REQUEST)

# ==============================================================================
# 5. PROCESS EXECUTION & STAGE PROGRESSION
# ==============================================================================

class ProcessExecutionListView(APIView):
    """
    List executions with live status filtering.
    """
    @extend_schema(summary="List Process Executions", responses={200: ProcessExecutionSerializer(many=True)})
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        status_param = request.query_params.get("status")
        qs = ProcessExecution.objects.select_related(
            "work_order", "work_order__product", "process_version", "bottleneck_node"
        ).prefetch_related("stage_executions", "stage_executions__node", "stage_executions__assigned_machine").all()

        if factory_id:
            qs = qs.filter(work_order__factory_id=factory_id)
        if status_param:
            qs = qs.filter(status=status_param.upper())

        return Response({"success": True, "count": qs.count(), "results": ProcessExecutionSerializer(qs, many=True).data})

class ProcessExecutionDetailView(APIView):
    """
    Retrieve live execution graph state, node statuses, metrics, and bottlenecks.
    """
    @extend_schema(summary="Get Process Execution Details", responses={200: ProcessExecutionSerializer})
    def get(self, request, pk):
        exec_run = get_object_or_404(
            ProcessExecution.objects.select_related(
                "work_order", "work_order__product", "process_version", "bottleneck_node"
            ).prefetch_related("stage_executions", "stage_executions__node", "stage_executions__assigned_machine"),
            pk=pk
        )
        return Response({"success": True, "data": ProcessExecutionSerializer(exec_run).data})

class StageExecutionAdvanceView(APIView):
    """
    Advance a stage to COMPLETED, progressing output units and unlocking downstream stages.
    """
    @extend_schema(summary="Advance Stage Execution")
    def post(self, request, pk):
        stage_exec = get_object_or_404(StageExecution, pk=pk)
        units_good = request.data.get("units_completed")
        try:
            units_scrapped = int(request.data.get("units_scrapped", 0))
        except (ValueError, TypeError):
            return Response(
                {"success": False, "error": {"message": "Invalid units_scrapped parameter (must be an integer)."}},
                status=status.HTTP_400_BAD_REQUEST
            )
        duration = request.data.get("duration_seconds")

        try:
            advanced = ProductionExecutionService.advance_stage(
                stage_execution=stage_exec,
                units_completed=int(units_good) if units_good is not None else None,
                units_scrapped=units_scrapped,
                duration_seconds=float(duration) if duration is not None else None,
            )
            return Response({
                "success": True,
                "stage": StageExecutionSerializer(advanced).data,
                "execution": ProcessExecutionSerializer(stage_exec.process_execution).data,
            })
        except ValueError as e:
            return Response(
                {"success": False, "error": {"message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST
            )

class StageExecutionFailView(APIView):
    """
    Marks a stage as failed with error context.
    """
    @extend_schema(summary="Fail Stage Execution")
    def post(self, request, pk):
        stage_exec = get_object_or_404(StageExecution, pk=pk)
        err_msg = request.data.get("error_message", "Operational fault occurred.")
        try:
            failed = ProductionExecutionService.fail_stage(stage_exec, error_message=err_msg)
            return Response({
                "success": True,
                "stage": StageExecutionSerializer(failed).data,
                "execution": ProcessExecutionSerializer(stage_exec.process_execution).data,
            })
        except ValueError as e:
            return Response(
                {"success": False, "error": {"message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST
            )

class ProcessExecutionActionView(APIView):
    """
    Perform lifecycle actions directly on a Process Execution run.
    Supported actions: pause, resume, complete
    """
    @extend_schema(summary="Perform Process Execution Action")
    def post(self, request, pk, action):
        exec_run = get_object_or_404(ProcessExecution, pk=pk)
        action = action.lower()

        try:
            if action == "pause":
                reason = request.data.get("reason", "Operator hold")
                res = ProductionExecutionService.pause_execution(exec_run, reason=reason)
                return Response({
                    "success": True,
                    "message": "Process execution paused.",
                    "execution": ProcessExecutionSerializer(res).data
                })
            elif action == "resume":
                res = ProductionExecutionService.resume_execution(exec_run)
                return Response({
                    "success": True,
                    "message": "Process execution resumed.",
                    "execution": ProcessExecutionSerializer(res).data
                })
            elif action == "complete":
                if exec_run.status in ("COMPLETED", "FAILED"):
                    return Response(
                        {"success": False, "error": {"message": f"Execution is already {exec_run.status.lower()}."}},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                now = timezone.now()
                for se in exec_run.stage_executions.exclude(status="COMPLETED"):
                    se.status = "COMPLETED"
                    se.completed_at = now
                    se.units_completed = se.units_in_progress or se.units_queued or exec_run.work_order.quantity_target
                    se.units_in_progress = 0
                    se.save()

                exec_run.status = "COMPLETED"
                exec_run.completed_at = now
                exec_run.total_units_output = exec_run.work_order.quantity_target
                exec_run.current_progress_percent = 100.0
                exec_run.bottleneck_node = None
                exec_run.save()

                wo = exec_run.work_order
                wo.status = "COMPLETED"
                wo.quantity_completed = wo.quantity_target
                wo.actual_end_date = now
                wo.save(update_fields=["status", "quantity_completed", "actual_end_date", "updated_at"])

                ProductionEvent.objects.create(
                    factory=wo.factory,
                    work_order=wo,
                    process_execution=exec_run,
                    event_type="WORK_ORDER_COMPLETED",
                    severity="INFO",
                    source="OPERATOR",
                    message=f"Process execution '{exec_run.execution_number}' marked as completed by operator.",
                    payload={"completed_units": wo.quantity_target}
                )
                return Response({
                    "success": True,
                    "message": "Process execution marked as completed.",
                    "execution": ProcessExecutionSerializer(exec_run).data
                })
            else:
                return Response(
                    {"success": False, "error": {"message": f"Unknown execution action '{action}'."}},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except ValueError as e:
            return Response(
                {"success": False, "error": {"message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST
            )


# ==============================================================================
# 6. MATERIAL FLOW & WIP TRACKING
# ==============================================================================

class MaterialFlowListView(APIView):
    """
    List material movements, raw material consumption, and WIP transfers.
    """
    @extend_schema(summary="List Material Flows", responses={200: MaterialFlowSerializer(many=True)})
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        exec_id = request.query_params.get("execution_id")

        qs = MaterialFlow.objects.select_related("process_execution", "stage_execution", "stage_execution__node", "raw_material").all()
        if factory_id:
            qs = qs.filter(process_execution__work_order__factory_id=factory_id)
        if exec_id:
            qs = qs.filter(process_execution_id=exec_id)

        return Response({"success": True, "count": qs.count(), "results": MaterialFlowSerializer(qs[:100], many=True).data})

class MaterialWipSummaryView(APIView):
    """
    Aggregates active work-in-progress (WIP) quantities by stage across a factory.
    """
    @extend_schema(summary="WIP Summary By Stage")
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        stages_qs = StageExecution.objects.filter(status__in=["READY", "RUNNING", "BLOCKED"])
        if factory_id:
            stages_qs = stages_qs.filter(process_execution__work_order__factory_id=factory_id)

        summary = []
        for s in stages_qs.select_related("node", "process_execution", "process_execution__work_order"):
            summary.append({
                "stage_id": str(s.id),
                "node_name": s.node.name,
                "node_key": s.node.node_key,
                "work_order": s.process_execution.work_order.order_number,
                "status": s.status,
                "units_queued": s.units_queued,
                "units_in_progress": s.units_in_progress,
                "units_completed": s.units_completed,
                "units_scrapped": s.units_scrapped,
            })

        return Response({"success": True, "count": len(summary), "wip_stages": summary})

# ==============================================================================
# 7. MANUFACTURING SIMULATION CONSOLE
# ==============================================================================

class SimulationScenarioListView(APIView):
    """
    List configured simulation scenarios for a factory.
    """
    @extend_schema(summary="List Simulation Scenarios", responses={200: SimulationScenarioSerializer(many=True)})
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        qs = SimulationScenario.objects.all()
        if factory_id:
            qs = qs.filter(factory_id=factory_id)
        return Response({"success": True, "results": SimulationScenarioSerializer(qs, many=True).data})

class SimulationInjectAnomalyView(APIView):
    """
    Injects a simulated breakdown, shortage, delay, scrap surge, or bottleneck.
    """
    @extend_schema(summary="Inject Simulation Anomaly")
    def post(self, request):
        exec_id = request.data.get("execution_id")
        scenario_type = request.data.get("scenario_type")
        params = request.data.get("parameters", {})

        execution = get_object_or_404(ProcessExecution, pk=exec_id)
        res = ManufacturingSimulationEngine.inject_anomaly(
            execution=execution,
            scenario_type=scenario_type,
            parameters=params,
        )
        return Response(res)

class SimulationStepView(APIView):
    """
    Advance the next operation in a process execution by one deterministic step.
    """
    @extend_schema(summary="Step Simulation")
    def post(self, request):
        exec_id = request.data.get("execution_id")
        seed = int(request.data.get("random_seed", 42))

        execution = get_object_or_404(ProcessExecution, pk=exec_id)
        advanced = ManufacturingSimulationEngine.step_simulation(execution, random_seed=seed)

        return Response({
            "success": True,
            "advanced": advanced is not None,
            "stage": StageExecutionSerializer(advanced).data if advanced else None,
            "execution": ProcessExecutionSerializer(execution).data,
        })

class SimulationRunFullView(APIView):
    """
    Executes a process execution run to completion deterministically.
    """
    @extend_schema(summary="Run Full Simulation")
    def post(self, request):
        exec_id = request.data.get("execution_id")
        seed = int(request.data.get("random_seed", 42))
        max_steps = int(request.data.get("max_steps", 50))

        execution = get_object_or_404(ProcessExecution, pk=exec_id)
        res = ManufacturingSimulationEngine.run_full_simulation(
            execution=execution,
            random_seed=seed,
            max_steps=max_steps,
        )
        return Response({"success": True, "result": res})

# ==============================================================================
# 8. PRODUCTION AUDIT EVENT LOG
# ==============================================================================

class ProductionEventListView(APIView):
    """
    Retrieve real-time and historical production event logs.
    """
    @extend_schema(summary="List Production Events", responses={200: ProductionEventSerializer(many=True)})
    def get(self, request):
        factory_id = request.query_params.get("factory_id")
        order_id = request.query_params.get("work_order_id")
        exec_id = request.query_params.get("execution_id")
        severity = request.query_params.get("severity")

        qs = ProductionEvent.objects.select_related("factory", "work_order", "stage_execution", "stage_execution__node").all()
        if factory_id:
            qs = qs.filter(factory_id=factory_id)
        if order_id:
            qs = qs.filter(work_order_id=order_id)
        if exec_id:
            qs = qs.filter(process_execution_id=exec_id)
        if severity:
            qs = qs.filter(severity=severity.upper())

        return Response({"success": True, "count": qs.count(), "results": ProductionEventSerializer(qs[:100], many=True).data})
