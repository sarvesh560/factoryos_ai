"""
FactoryOS AI — Universal Process Engine URL Routing
Phase 3: Universal Manufacturing Process Engine (UMPE) Endpoints
"""
from django.urls import path
from apps.processes.views import (
    ProcessTemplateListView,
    ProcessTemplateInstantiateView,
    ProcessDefinitionListCreateView,
    ProcessDefinitionDetailView,
    ProcessDefinitionDuplicateView,
    ProcessDefinitionArchiveView,
    ProcessVersionDetailView,
    ProcessVersionCloneView,
    ProcessVersionValidateView,
    ProcessVersionPublishView,
    ProcessVersionLayoutView,
    ProcessNodeListCreateView,
    ProcessNodeDetailView,
    ProcessEdgeListCreateView,
    ProcessEdgeDetailView,
    WorkOrderListCreateView,
    WorkOrderDetailView,
    WorkOrderActionView,
    ProcessExecutionListView,
    ProcessExecutionDetailView,
    ProcessExecutionActionView,
    StageExecutionAdvanceView,
    StageExecutionFailView,
    MaterialFlowListView,
    MaterialWipSummaryView,
    SimulationScenarioListView,
    SimulationInjectAnomalyView,
    SimulationStepView,
    SimulationRunFullView,
    ProductionEventListView,
)

urlpatterns = [
    # Universal Process Templates
    path("templates/", ProcessTemplateListView.as_view(), name="process-template-list"),
    path("templates/<str:template_key>/instantiate/", ProcessTemplateInstantiateView.as_view(), name="process-template-instantiate"),

    # Process Definitions & Versions
    path("definitions/", ProcessDefinitionListCreateView.as_view(), name="process-definition-list-create"),
    path("definitions/<uuid:pk>/", ProcessDefinitionDetailView.as_view(), name="process-definition-detail"),
    path("definitions/<uuid:pk>/duplicate/", ProcessDefinitionDuplicateView.as_view(), name="process-definition-duplicate"),
    path("definitions/<uuid:pk>/archive/", ProcessDefinitionArchiveView.as_view(), name="process-definition-archive"),
    path("definitions/<uuid:pk>/clone-version/", ProcessVersionCloneView.as_view(), name="process-version-clone"),
    path("versions/<uuid:pk>/", ProcessVersionDetailView.as_view(), name="process-version-detail"),
    path("versions/<uuid:pk>/clone/", ProcessVersionCloneView.as_view(), name="process-version-clone-direct"),
    path("versions/<uuid:pk>/validate/", ProcessVersionValidateView.as_view(), name="process-version-validate"),
    path("versions/<uuid:pk>/publish/", ProcessVersionPublishView.as_view(), name="process-version-publish"),
    path("versions/<uuid:pk>/layout/", ProcessVersionLayoutView.as_view(), name="process-version-layout"),
    path("versions/<uuid:version_id>/nodes/", ProcessNodeListCreateView.as_view(), name="process-node-list-create"),
    path("nodes/<uuid:pk>/", ProcessNodeDetailView.as_view(), name="process-node-detail"),
    path("versions/<uuid:version_id>/edges/", ProcessEdgeListCreateView.as_view(), name="process-edge-list-create"),
    path("edges/<uuid:pk>/", ProcessEdgeDetailView.as_view(), name="process-edge-detail"),

    # Work Orders
    path("work-orders/", WorkOrderListCreateView.as_view(), name="work-order-list-create"),
    path("work-orders/<uuid:pk>/", WorkOrderDetailView.as_view(), name="work-order-detail"),
    path("work-orders/<uuid:pk>/<str:action>/", WorkOrderActionView.as_view(), name="work-order-action"),

    # Execution & Stage Progression
    path("execution/", ProcessExecutionListView.as_view(), name="process-execution-list"),
    path("execution/<uuid:pk>/", ProcessExecutionDetailView.as_view(), name="process-execution-detail"),
    path("execution/<uuid:pk>/<str:action>/", ProcessExecutionActionView.as_view(), name="process-execution-action"),
    path("execution/stages/<uuid:pk>/advance/", StageExecutionAdvanceView.as_view(), name="stage-execution-advance"),
    path("execution/stages/<uuid:pk>/fail/", StageExecutionFailView.as_view(), name="stage-execution-fail"),

    # Material Flow & WIP Tracking
    path("materials/flows/", MaterialFlowListView.as_view(), name="material-flow-list"),
    path("materials/wip-summary/", MaterialWipSummaryView.as_view(), name="material-wip-summary"),

    # Simulation Console
    path("simulation/scenarios/", SimulationScenarioListView.as_view(), name="simulation-scenario-list"),
    path("simulation/inject-anomaly/", SimulationInjectAnomalyView.as_view(), name="simulation-inject-anomaly"),
    path("simulation/step/", SimulationStepView.as_view(), name="simulation-step"),
    path("simulation/run-full/", SimulationRunFullView.as_view(), name="simulation-run-full"),

    # Production Audit Events
    path("events/", ProductionEventListView.as_view(), name="production-event-list"),
]
