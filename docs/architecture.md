# FactoryOS AI — Enterprise Architecture Specification
## Phase 3: Universal Manufacturing Process Engine (UMPE) & Visual Process Builder

### 1. Executive Summary
FactoryOS AI is an industry-independent, multi-tenant smart manufacturing automation platform designed for commercial production workflows. Phase 3 introduces the **Universal Manufacturing Process Engine (UMPE)**: an arbitrary-topology graph-based manufacturing execution foundation supporting textile, CNC, automotive, food processing, electronics, pharmaceuticals, and custom workflows.

- **Backend**: Python 3.14 + Django 5.0 + Django REST Framework + `drf-spectacular` (OpenAPI 3.0) + `django-cors-headers`.
- **Database Engine**: Multi-engine compatibility supporting SQLite (local development default) and PostgreSQL 15+ (production / staging).
- **Frontend**: Flutter Web (Material 3) + Riverpod 3 + GoRouter + Dio HTTP client + Google Fonts (Inter).
- **Design System**: Industrial High-Tech design tokens (`factory_tokens.dart`), dark/light themes, micro-animations, responsive layout.
- **Workflow Engine**: DAG-based process execution engine with Tarjan/DFS cycle detection, transactional stage progression, material flow tracking, and hardware-isolated simulation.

---

### 2. High-Level Architecture Diagram

```mermaid
graph TD
    subgraph Frontend [Flutter Web Enterprise Client]
        App[MaterialApp.router] --> Shell[AppShell]
        Shell --> CmdCenter[Command Center Dashboard]
        Shell --> LinesView[Production Lines Telemetry]
        Shell --> FacView[Facility Overview]
        Shell --> CompanyView[Company Management Screen]
        Shell --> OnboardView[Universal Onboarding Screen]
        Shell --> ProcLibView[Process Library Screen]
        Shell --> BuilderView[Visual Process Builder Screen]
        Shell --> WOView[Work Order Management Screen]
        Shell --> ExecView[Live Execution Screen]
        Shell --> MatFlowView[Material Flow & WIP Screen]
        Shell --> SimConsoleView[Simulation Console Screen]
        Shell --> HealthView[System Diagnostics]
        
        ProcLibView --> ProcController[ProcessController (Riverpod)]
        BuilderView --> BuilderController[ProcessBuilderController (Riverpod)]
        WOView --> WOController[WorkOrderController (Riverpod)]
        ExecView --> ExecController[ExecutionController (Riverpod)]
        MatFlowView --> MatController[MaterialFlowController (Riverpod)]
        SimConsoleView --> SimController[SimulationController (Riverpod)]
        
        ProcController --> PRepo[ProcessRepository]
        BuilderController --> PRepo
        WOController --> PRepo
        ExecController --> PRepo
        MatController --> PRepo
        SimController --> PRepo
        PRepo --> ApiClient[ApiClient (Dio)]
    end

    subgraph Backend [Django REST Framework Backend]
        ApiClient -->|REST JSON| Urls[config/urls.py]
        Urls --> HealthEndpoint[/api/health/]
        Urls --> ProcessesAPI[/api/processes/]
        Urls --> CompaniesAPI[/api/companies/]
        Urls --> FactoriesAPI[/api/factories/]
        Urls --> OnboardingAPI[/api/onboarding/]
        
        ProcessesAPI --> DefViews[ProcessDefinition / Version Views]
        ProcessesAPI --> BuilderViews[Node / Edge / Layout Views]
        ProcessesAPI --> WOViews[WorkOrder Views]
        ProcessesAPI --> ExecViews[Execution / Stage Advance Views]
        ProcessesAPI --> MatViews[Material Flow / WIP Views]
        ProcessesAPI --> SimViews[Simulation / Anomaly / Step Views]
        
        DefViews --> GraphValidator[GraphValidator (DFS / Tarjan Cycles)]
        ExecViews --> ExecEngine[ProductionExecutionService]
        SimViews --> SimEngine[ManufacturingSimulationEngine]
        
        ExecEngine --> TxAtomic[transaction.atomic()]
        SimEngine --> TxAtomic
    end

    subgraph Storage [Database: SQLite / PostgreSQL]
        TxAtomic --> ProcessDefs[(process_definitions)]
        TxAtomic --> ProcessVers[(process_versions)]
        TxAtomic --> ProcessNodes[(process_nodes)]
        TxAtomic --> ProcessEdges[(process_edges)]
        TxAtomic --> WorkOrders[(work_orders)]
        TxAtomic --> Executions[(process_executions)]
        TxAtomic --> StageExecs[(stage_executions)]
        TxAtomic --> MatFlows[(material_flows)]
        TxAtomic --> ProdEvents[(production_events)]
        TxAtomic --> SimScenarios[(simulation_scenarios)]
    end
```

---

### 3. Backend Module Decomposition
- `config/`: Django settings, multi-engine database configuration (`DB_ENGINE`), CORS whitelist, OpenAPI schema generation, root URL routing.
- `common/`: Cross-cutting concerns:
  - `exceptions.py`: Structured JSON exception handler mapping DRF/system errors into consistent enterprise error envelopes.
  - `pagination.py`: Predictable paginated response format with count, total pages, and navigation URLs.
  - `views.py`: Deep health check verifying database latency and engine metadata.
- `apps/factories/`: Multi-tenant hierarchy (`Organization`, `Factory`, `Product`, `RawMaterial`, `ProcessStage`, `ProductionLine`, `Machine`, `ShiftConfiguration`, `FactoryMetricSnapshot`).
- `apps/onboarding/`: Universal onboarding wizard engine (`OnboardingDraft`, `AIService`, `IndustryTemplates`, `OnboardingService.activate_factory`).
- `apps/processes/`: Universal Manufacturing Process Engine (UMPE):
  - `models.py`:
    - `ProcessDefinition`, `ProcessVersion`: Workflow definition, semantic versioning, and publishing lifecycle.
    - `ProcessNode`, `ProcessEdge`: Visual workflow nodes (8 types) and edges with dynamic condition expressions.
    - `WorkOrder`: Order dispatching with priorities, scheduled dates, and status transitions.
    - `ProcessExecution`, `StageExecution`: Transactional execution run state and per-node stage executions.
    - `MaterialFlow`: Append-only material ledger (consumption, scrap, output, transfer).
    - `ProductionEvent`: Industrial event journal (operational anomalies, quality alarms, bottlenecks).
    - `SimulationScenario`: Preconfigured simulation blueprints with anomaly parameters.
  - `services/graph_validator.py`: Graph structural integrity and cycle detection using DFS and Tarjan's algorithms.
  - `services/execution_service.py`: Transactional workflow execution service with idempotent stage advancement and stock deduction.
  - `services/simulation_service.py`: Hardware-isolated simulation engine with anomaly injection and reproducible random seed stepping.
  - `serializers.py`: Typed, safe serializers for definitions, versions, nodes, edges, orders, executions, flows, and scenarios.
  - `views.py`: REST endpoints for workflow authoring, graph validation, publishing, execution tracking, stage advancing, and simulation control.

---

### 4. Frontend Component Hierarchy
- `app/`: Application bootstrap, `FactoryOSApp`, `appRouter` (GoRouter with `/command-center`, `/lines`, `/overview`, `/companies`, `/onboarding`, `/processes`, `/processes/builder`, `/work-orders`, `/processes/execution`, `/processes/materials`, `/processes/simulation`, `/health`).
- `core/`:
  - `theme/factory_tokens.dart`: Strict industrial design tokens (palette, typography, radii, elevations, spacing).
  - `theme/app_theme.dart`: Material 3 Light and Dark theme configurations with Inter font family.
  - `theme/theme_provider.dart`: StateNotifier for instant light/dark toggle.
  - `api/api_client.dart`: Dio HTTP client with GET, POST, PATCH, and DELETE support.
  - `animations/app_animations.dart`: Performant durations (120ms-280ms), cubic easing, respect for reduced-motion settings.
- `shared/`:
  - `layout/app_shell.dart`: Responsive shell with collapsible animated sidebar, top navigation, factory switcher, live backend status indicator, quick onboarding button.
  - `widgets/`: `StatusBadge`, `KpiCard`, `FactoryButton`, `FactoryDataTable`, `FactoryDialog`, `SkeletonLoader`, `EmptyStateView`, `ErrorStateView`.
- `features/processes/`:
  - `data/models/process_models.dart`: Typed data models for `ProcessDefinition`, `ProcessVersion`, `ProcessNode`, `ProcessEdge`, `WorkOrder`, `ProcessExecution`, `StageExecution`, `MaterialFlow`, `ProductionEvent`, and `SimulationScenario`.
  - `data/repositories/process_repository.dart`: Centralized repository interfacing with Django REST Framework UMPE endpoints.
  - `presentation/controllers/`:
    - `process_controller.dart`: Process definition library and version cloning management.
    - `process_builder_controller.dart`: Visual graph designer state, node dragging, edge creation, validation, and publishing.
    - `work_order_controller.dart`: Order dispatching, filtering, and execution launching.
    - `execution_controller.dart`: Real-time execution DAG state, stage advancement, and failure logging.
    - `material_flow_controller.dart`: WIP tracking, inventory stock gauges, and flow ledger filtering.
    - `simulation_controller.dart`: Hardware-isolated simulation studio, anomaly triggers, and deterministic stepping.
  - `presentation/screens/`:
    - `process_library_screen.dart`: Process catalog, version history, and new process creation.
    - `visual_process_builder_screen.dart`: Interactive graph builder with custom grid painter, pan/zoom, draggable nodes, cubic Bezier curves, and node inspector.
    - `work_order_management_screen.dart`: Dispatched orders, priority badges, and execution launcher.
    - `live_execution_screen.dart`: Live execution DAG visualizer with stage controls and event stream.
    - `material_flow_screen.dart`: WIP distribution, raw material levels, and audit ledger.
    - `simulation_console_screen.dart`: Anomaly injection deck, stepping controls, and preconfigured scenario catalog.
