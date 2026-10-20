# FactoryOS AI — Phase 4, Step 2 Preflight Audit Report
**Universal Goal-Driven Manufacturing Agent Runtime + Real LLM Integration**
**Date:** October 20, 2026  
**Auditor:** Antigravity Agent  
**Repository:** `C:\Users\projects\universal favtory ai\factoryos_AI`

---

## 1. Executive Summary

This audit establishes whether the existing FactoryOS AI codebase genuinely invokes an LLM, examines current agent and automation architectures, evaluates domain service integrations (processes, work orders, simulations, inventory), and details the design decisions for implementing the **Universal Goal-Driven Manufacturing Agent Runtime** with real LLM integration.

---

## 2. Evidence-Based LLM Call-Path Audit

| Audit Question | Verified Reality in Source Code | Source References & Lines |
|---|---|---|
| **1. Is an LLM SDK or HTTP client installed?** | **Yes, HTTP clients and selective SDKs are present.** Python virtual environment contains `httpx` (0.28.1), `requests` (2.34.1), `urllib3` (2.7.0), `pydantic` (2.13.4), `anthropic` (0.102.0), and `google-genai` (2.2.0). The `openai` package is not installed; however, `httpx` and `requests` are fully capable of communicating with standard OpenAI-compatible REST endpoints. | Virtual environment packages (`pip list`) |
| **2. Does a provider implementation exist beyond an abstract base class?** | **In `apps.agent_automation`: NO.** Only `BaseAgentAIProvider` (ABC) and `DeterministicRuleAgentProvider` exist. In `apps.onboarding`, a `GeminiAIService` exists for text-to-layout drafting during factory setup, but it is completely detached from the manufacturing runtime. | [`apps/agent_automation/services/ai_provider.py:38-55`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/agent_automation/services/ai_provider.py#L38-L55)<br>[`apps/onboarding/services/ai_service.py:325-380`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/onboarding/services/ai_service.py#L325-L380) |
| **3. Does any code send requests to an actual model endpoint in automation?** | **NO.** Zero HTTP or socket requests are transmitted to OpenAI, Anthropic, or any LLM server during event evaluation, agent decision-making, or action handling. | Entire `apps/agent_automation/` tree |
| **4. Are model responses parsed and used for decisions or plans?** | **NO.** Decisions are computed by deterministic conditional logic checking physical telemetry (`temperature_c > 85.0`, `vibration_rms > 6.5`, `scrap_rate_pct > 2.0%`, etc.). | [`apps/agent_automation/services/ai_provider.py:80-350`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/agent_automation/services/ai_provider.py#L80-L350) |
| **5. Are API keys and model settings loaded securely from environment variables?** | **PARTIAL/DEAD CODE.** Neither `backend/config/settings.py` nor `backend/.env` nor `backend/.env.example` defines `FACTORYOS_AI_PROVIDER`, `FACTORYOS_AI_MODEL`, or `FACTORYOS_AI_API_KEY`. In `apps/onboarding/services/ai_service.py:386`, `OPENAI_API_KEY` was read into an unused local variable. | [`backend/config/settings.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/config/settings.py)<br>[`backend/.env.example`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/.env.example)<br>[`apps/onboarding/services/ai_service.py:386`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/onboarding/services/ai_service.py#L386) |
| **6. Do runtime requests actually invoke the provider?** | **The deterministic provider is invoked.** `AgentDecisionService` explicitly instantiates `DeterministicRuleAgentProvider()`. No LLM is touched. | [`apps/agent_automation/services/decision_service.py:53`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/agent_automation/services/decision_service.py#L53) |
| **7. Are errors, timeouts, invalid output and provider unavailability handled?** | **For deterministic rules: Yes.** For LLMs: Not implemented because no LLM provider has been integrated into the agent automation engine. | [`apps/agent_automation/services/decision_service.py:75-85`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/agent_automation/services/decision_service.py#L75-L85) |
| **8. Does the application silently fall back to deterministic rules?** | **NO silent deception.** The system in Phase 4 Step 1 truthfully documented that decisions were 100% deterministic heuristics. | Phase 4 Step 1 Completion Report |
| **9. Is the actual execution mode exposed to users and in audit logs?** | **PARTIALLY.** `rule_name` is recorded on `AgentDecision` (`DETERMINISTIC_INDUSTRIAL_RULES_V1`), but there is no goal-level execution mode (`llm`, `deterministic`, `hybrid`) visible on runs or the Flutter UI. | [`apps/agent_automation/models.py:175`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/agent_automation/models.py#L175) |

**Conclusion:** The existing FactoryOS AI application currently has **no LLM provider integrated into its automation engine**. Step 2 must build a genuine OpenAI-compatible provider alongside the deterministic provider, supporting `llm`, `deterministic`, and `hybrid` modes.

---

## 3. Existing Domain Architecture & Service Audit

### 3.1. Process Definitions and Execution Services
- **Models:** `ProcessDefinition`, `ProcessVersion`, `ProcessNode`, `ProcessEdge`, `WorkOrder`, `ProcessExecution`, `StageExecution`, `MaterialFlow`, `ProductionEvent`, `SimulationScenario` in [`apps/processes/models.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/processes/models.py).
- **Execution Engine:** `ProductionExecutionService` in [`apps/processes/services/execution_service.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/processes/services/execution_service.py) provides tested, transaction-safe methods:
  - `create_work_order(factory, order_number, product, process_definition, quantity_target, ...)`
  - `start_execution(work_order, mode="SIMULATION")`
  - `advance_stage(stage_execution, units_processed, units_scrapped)`
  - `pause_execution(execution, reason)`
  - `resume_execution(execution)`
- **Graph Validator:** `ProcessGraphValidator.validate_version(version)` in [`apps/processes/services/graph_validator.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/processes/services/graph_validator.py) checks cycle detection, isolated nodes, reachability, and quality gates.
- **Simulation Engine:** `ManufacturingSimulationEngine.inject_anomaly(execution, scenario_type)` in [`apps/processes/services/simulation_service.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/processes/services/simulation_service.py).

### 3.2. Inventory and Material Management
- **Audit Discovery:** There is no standalone `apps.inventory` Django app. Instead, material stock is tracked in two places:
  1. [`RawMaterial`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/factories/models.py#L166): Stores `factory`, `name`, `code`, `category`, `unit_of_measure`, `safety_stock`, and `current_stock` (live balances).
  2. [`MaterialFlow`](file:///C:/Users/processes/models.py#L415): Ledger records of `INPUT_CONSUMPTION`, `WIP_TRANSFER`, `FINISHED_GOODS`, and `SCRAP_REJECT`.
- **Finding:** A genuine inventory inquiry tool must inspect `RawMaterial.objects.filter(factory=factory)` rather than fabricating external inventory services.

### 3.3. Action Registry Audit
- Current `WorkflowActionRegistry` in [`apps/agent_automation/services/action_registry.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/agent_automation/services/action_registry.py) executes 5 handlers:
  - `_handle_create_maintenance_ticket`: Updates `Machine.status` to `MAINTENANCE` and logs `ProductionEvent`.
  - `_handle_create_quality_inspection`: Generates inspection code and logs `ProductionEvent`.
  - `_handle_create_inventory_replenishment`: Generates requisition code and logs `ProductionEvent`.
  - `_handle_create_production_investigation`: Generates investigation ticket and logs `ProductionEvent`.
  - `_handle_send_notification`: Logs in-app notification `ProductionEvent`.
- **Finding:** The action handlers generate real `ProductionEvent` records and update `Machine` records, but they do NOT interface with `ProductionExecutionService` or `ProcessGraphValidator`. In Step 2, we will create a **Typed Manufacturing Tool Registry** that exposes real domain operations:
  - `inspect_inventory_stock`: Reads `RawMaterial` balances against safety stock.
  - `discover_and_validate_process`: Queries published `ProcessDefinition` and validates via `ProcessGraphValidator`.
  - `create_work_order`: Invokes `ProductionExecutionService.create_work_order` (consequential: requires human approval).
  - `simulate_process_execution`: Runs a dry-run execution simulation via `ProductionExecutionService.start_execution` in `SIMULATION` mode.
  - `inspect_work_order_status`: Queries live `WorkOrder` progress.

---

## 4. Universal Industry Taxonomy Audit

In [`apps/factories/models.py:8-19`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/factories/models.py#L8-L19) and [`apps/processes/services/template_service.py`](file:///C:/Users/projects/universal%20favtory%20ai/factoryos_AI/backend/apps/processes/services/template_service.py), 8 universal industries are defined:
1. `TEXTILES` (`TEXTILE`) — High-speed yarn ring spinning and weaving.
2. `AUTOMOTIVE_EV` (`AUTOMOTIVE`) — Battery module robotic stacking, laser welding, testing.
3. `CNC_MACHINING` (`CNC_ENGINEERING`) — 5-axis precision milling, turning, CMM metrology.
4. `ELECTRONICS_PCBA` (`ELECTRONICS`) — SMT solder paste, pick-and-place, reflow, AOI/ICT.
5. `PHARMACEUTICALS` (`PHARMACEUTICALS`) — Sterile compounding, cleanroom filling, lyophilizate vial sealing.
6. `FOOD_BEVERAGE` (`FOOD_PROCESSING`) — Pasteurization, aseptic packaging, hermetic sealing.
7. `CHEMICALS` (`CHEMICALS`) — Exothermic batch reactor polymerization, vacuum distillation.
8. `GENERAL_DISCRETE` (`CUSTOM` / Discrete) — Multi-station manual and mechanical assembly.

**Decision:** We will create a dedicated `IndustryProfileRegistry` in `apps.agent_automation` that formally encapsulates each profile's version, terminology, capabilities, constraints, tool permissions, safety requirements, and operational status (`OPERATIONAL`, `PREVIEW`, `UNAVAILABLE`) without scattering `if/else` checks throughout the runtime.

---

## 5. Architectural Blueprint for Phase 4 Step 2

```
                       ┌──────────────────────────────────────┐
                       │ User Goal (Natural Language Text)   │
                       └──────────────────┬───────────────────┘
                                          │
                                          ▼
                      ┌────────────────────────────────────────┐
                      │ AgentRun Orchestrator (Backend)        │
                      │ - Resolves Factory & Tenant Access     │
                      │ - Resolves Industry Profile (v1.0.0)   │
                      │ - Bounded Loop (Max Steps, Max Replans)│
                      └──────────────────┬─────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
   ┌───────────────────────────┐                   ┌───────────────────────────┐
   │ Real LLM Provider         │                   │ Deterministic Provider    │
   │ (OpenAI-compatible HTTP)  │                   │ (Industrial Heuristics)   │
   │ - Parse Goal to Plan      │                   │ - Fallback & Zero-Key Mode│
   │ - Typed Structured JSON   │                   │ - Explicit Audit Trail    │
   └─────────────┬─────────────┘                   └─────────────┬─────────────┘
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         ▼
                      ┌────────────────────────────────────────┐
                      │ AgentPlan & Steps (Validated Schema)   │
                      └──────────────────┬─────────────────────┘
                                         │
                                         ▼
                      ┌────────────────────────────────────────┐
                      │ Typed Manufacturing Tool Registry     │
                      │ - Tool Permissions & Industry Scope    │
                      │ - Read-Only vs Consequential Gate      │
                      └──────────┬───────────────────┬─────────┘
                                 │                   │
                     Read-Only   │                   │ Consequential Action
                     Tool Call   │                   │
                                 ▼                   ▼
                      ┌─────────────────┐ ┌────────────────────────────┐
                      │ Execute Handler │ │ ApprovalRequest (PENDING)  │
                      │ (DB Query/Sim)  │ │ -> Human-in-the-Loop Signoff│
                      └────────┬────────┘ └──────────────┬─────────────┘
                               │                         │ Approved
                               │                         ▼
                               │                 ┌─────────────────────┐
                               │                 │ Execute Domain      │
                               │                 │ Handler (WorkOrder) │
                               │                 └─────────┬───────────┘
                               │                           │
                               └─────────────┬─────────────┘
                                             ▼
                               ┌──────────────────────────┐
                               │ Observation & Audit Log  │
                               │ State Verification Check │
                               └─────────────┬────────────┘
                                             ▼
                               ┌──────────────────────────┐
                               │ Completion Verification  │
                               └──────────────────────────┘
```

---

## 6. Security, Tenancy & Safety Safeguards

1. **Strict Tenant & Factory Isolation**: Every tool call and goal run resolves the factory context from the authenticated user and verifies authorization via `check_factory_authorization`.
2. **Consequential Action Approval Barrier**: Creating real work orders or committing production resources requires explicit human signoff via `ApprovalRequest`. The LLM cannot approve its own actions.
3. **Replay & Idempotency Protection**: Every tool execution generates a deterministic idempotency key. Duplicate calls return the cached domain state without executing duplicate DB mutations.
4. **Prompt Injection & Code Execution Defense**: The LLM outputs strict JSON schemas conforming to `AgentPlanSchema`. Tool execution runs through hardcoded, validated Python handler functions; no `eval()`, `exec()`, raw SQL, or shell commands are allowed.
5. **No Key Leakage**: API keys, bearer tokens, and internal prompt bodies are never persisted in `AutomationAuditEvent` or serialized to the Flutter UI.
