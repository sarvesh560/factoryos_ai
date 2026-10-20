// FactoryOS AI — Agent Automation Widget & Screen Tests
// Phase 4: Multi-Agent Manufacturing Orchestration, Approvals, & Goal-Driven Agent Runtime
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:factoryos_frontend/core/api/api_client.dart';
import 'package:factoryos_frontend/features/factories/data/models/factory_model.dart';
import 'package:factoryos_frontend/features/factories/data/repositories/factory_repository.dart';
import 'package:factoryos_frontend/features/factories/presentation/controllers/factory_controller.dart';
import 'package:factoryos_frontend/features/agent_automation/data/models/agent_automation_models.dart';
import 'package:factoryos_frontend/features/agent_automation/data/repositories/agent_automation_repository.dart';
import 'package:factoryos_frontend/features/agent_automation/presentation/screens/agent_automation_screen.dart';

class MockFactoryRepository extends FactoryRepository {
  @override
  Future<Map<String, dynamic>> checkHealth() async => {'status': 'healthy'};

  @override
  Future<FactoryOverviewData> getFactoryOverview(String factoryId) async {
    return FactoryOverviewData.fromJson({
      'factory': {
        'id': 'test-factory-1',
        'name': 'Apex Precision Plant 1',
        'code': 'FAC-APX-01',
        'industry_type': 'CNC_ENGINEERING',
        'configuration_status': 'CONFIGURED',
        'total_production_lines': 4,
        'active_lines': 4,
        'is_active': true,
      },
      'metrics': {'oee': 88.5},
      'lines_summary': {'total': 4, 'running': 4, 'idle': 0, 'offline': 0},
      'production_lines': [],
      'alerts_summary': {'critical': 0, 'warning': 0, 'info': 0, 'total_active': 0},
    });
  }

  @override
  Future<List<FactoryItem>> getFactories({
    String? industryType,
    String? status,
    String? search,
    bool includeArchived = false,
  }) async {
    return [
      const FactoryItem(
        id: 'test-factory-1',
        name: 'Apex Precision Plant 1',
        code: 'FAC-APX-01',
        industryType: 'CNC_ENGINEERING',
        industryTypeDisplay: 'CNC Engineering',
        configurationStatus: 'CONFIGURED',
        configurationStatusDisplay: 'Configured',
        location: 'Detroit, MI',
        country: 'USA',
        timezone: 'America/Detroit',
        totalProductionLines: 4,
        activeLines: 4,
        isActive: true,
      ),
    ];
  }
}

class MockAgentAutomationRepository extends AgentAutomationRepository {
  MockAgentAutomationRepository() : super(ApiClient());

  bool shouldFail = false;
  String? lastToggledAgentKey;
  bool? lastToggledAgentValue;
  Map<String, dynamic>? lastSimulatedPayload;
  String? lastDecidedApprovalId;
  String? lastDecidedAction;

  // Phase 4 Step 2 Trackers
  Map<String, dynamic>? lastGoalPayload;
  String? lastAdvancedRunId;
  String? lastGoalApprovedId;
  String? lastGoalApprovedAction;
  String? lastClarificationAnswer;

  List<AgentItem> agents = [
    const AgentItem(
      id: 'agent-1',
      name: 'Production Orchestration Agent',
      key: 'production_agent',
      agentType: 'PRODUCTION',
      agentTypeDisplay: 'Production Orchestration Agent',
      description: 'Monitors shop floor throughput pacing and bottlenecks.',
      isEnabled: true,
      supportedEventTypes: ['PRODUCTION_DELAY', 'WORK_ORDER_STATUS_CHANGED'],
      allowedActionTypes: ['CREATE_PRODUCTION_INVESTIGATION'],
      requiresApproval: true,
    ),
    const AgentItem(
      id: 'agent-2',
      name: 'Predictive & Preventative Maintenance Agent',
      key: 'maintenance_agent',
      agentType: 'MAINTENANCE',
      agentTypeDisplay: 'Predictive & Preventative Maintenance Agent',
      description: 'Monitors vibration, thermal limits, and operating hours.',
      isEnabled: true,
      supportedEventTypes: ['MACHINE_ANOMALY', 'MAINTENANCE_DUE'],
      allowedActionTypes: ['CREATE_MAINTENANCE_TICKET'],
      requiresApproval: true,
    ),
    const AgentItem(
      id: 'agent-3',
      name: 'Quality Assurance & Scrap Reduction Agent',
      key: 'quality_agent',
      agentType: 'QUALITY',
      agentTypeDisplay: 'Quality Assurance & Scrap Reduction Agent',
      description: 'Evaluates scrap spikes and inspection non-conformances.',
      isEnabled: true,
      supportedEventTypes: ['QUALITY_FAILURE'],
      allowedActionTypes: ['CREATE_QUALITY_INSPECTION'],
      requiresApproval: true,
    ),
    const AgentItem(
      id: 'agent-4',
      name: 'Inventory Replenishment & WIP Agent',
      key: 'inventory_agent',
      agentType: 'INVENTORY',
      agentTypeDisplay: 'Inventory Replenishment & WIP Agent',
      description: 'Monitors buffer stock levels and triggers reorders.',
      isEnabled: true,
      supportedEventTypes: ['INVENTORY_SHORTAGE'],
      allowedActionTypes: ['CREATE_INVENTORY_REPLENISHMENT_REQUEST'],
      requiresApproval: true,
    ),
    const AgentItem(
      id: 'agent-5',
      name: 'Energy Optimization & Sustainability Agent',
      key: 'energy_agent',
      agentType: 'ENERGY',
      agentTypeDisplay: 'Energy Optimization & Sustainability Agent',
      description: 'Provides non-intrusive peak load-shifting recommendations.',
      isEnabled: false,
      supportedEventTypes: ['MACHINE_ANOMALY', 'PRODUCTION_DELAY'],
      allowedActionTypes: ['SEND_IN_APP_NOTIFICATION'],
      requiresApproval: false,
    ),
  ];

  List<ManufacturingEventItem> events = [
    ManufacturingEventItem(
      id: 'evt-1',
      factoryId: 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      eventType: 'MACHINE_ANOMALY',
      eventTypeDisplay: 'Machine Anomaly / Breakdown',
      sourceType: 'SIMULATION',
      sourceId: 'M-VF2-01',
      severity: 'CRITICAL',
      payload: const {
        'machine_name': 'Haas 5-Axis VF2',
        'temperature_c': 94.2,
        'vibration_rms': 8.3,
      },
      status: 'PROCESSED',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      decisions: const [
        AgentDecisionItem(
          id: 'dec-1',
          eventId: 'evt-1',
          agentId: 'agent-2',
          agentName: 'Predictive & Preventative Maintenance Agent',
          agentKey: 'maintenance_agent',
          status: 'AWAITING_APPROVAL',
          findings: 'Critical spindle bearing thermal breach (94.2°C).',
          proposedAction: 'CREATE_MAINTENANCE_TICKET',
          confidenceScore: 0.98,
        ),
      ],
    ),
  ];

  List<AgentDecisionItem> decisions = [
    const AgentDecisionItem(
      id: 'dec-1',
      eventId: 'evt-1',
      agentId: 'agent-2',
      agentName: 'Predictive & Preventative Maintenance Agent',
      agentKey: 'maintenance_agent',
      status: 'AWAITING_APPROVAL',
      findings: 'Critical spindle bearing thermal breach (94.2°C).',
      rationale: 'Thermal limits exceed ISO standards; emergency maintenance order required.',
      proposedAction: 'CREATE_MAINTENANCE_TICKET',
      actionParameters: {'machine_id': 'M-VF2-01', 'priority': 'HIGH'},
      confidenceScore: 0.98,
    ),
  ];

  List<ApprovalRequestItem> approvals = [
    const ApprovalRequestItem(
      id: 'appr-1',
      decisionId: 'dec-1',
      factoryId: 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      agentName: 'Predictive & Preventative Maintenance Agent',
      agentKey: 'maintenance_agent',
      status: 'PENDING',
      requestedAction: 'CREATE_MAINTENANCE_TICKET',
      actionSummary: 'Critical spindle bearing thermal breach (94.2°C).',
      actionParameters: {'machine_id': 'M-VF2-01', 'priority': 'HIGH'},
      decisionRationale: 'Thermal limits exceed ISO standards; emergency maintenance order required.',
      urgency: 'CRITICAL',
    ),
  ];

  List<AutomationAuditItem> audits = [
    AutomationAuditItem(
      id: 'audit-1',
      factoryId: 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      eventCategory: 'EVENT_INGESTED',
      referenceId: 'evt-1',
      actor: 'SIMULATOR',
      details: const {'event_type': 'MACHINE_ANOMALY', 'severity': 'CRITICAL'},
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AutomationAuditItem(
      id: 'audit-2',
      factoryId: 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      eventCategory: 'APPROVAL_REQUESTED',
      referenceId: 'appr-1',
      actor: 'maintenance_agent',
      details: const {'action_type': 'CREATE_MAINTENANCE_TICKET', 'urgency': 'CRITICAL'},
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
  ];

  // Phase 4 Step 2 Mock Data
  ProviderStatusItem providerStatus = const ProviderStatusItem(
    configuredProvider: 'openai_compatible',
    activeMode: 'llm',
    isLlmAvailable: true,
    modelName: 'gpt-4o-mini',
    baseUrl: 'https://api.openai.com/v1',
    maskedApiKey: 'sk-...TEST',
    timeoutSeconds: 30,
    maxRetries: 2,
    providerVersion: '1.0.0',
  );

  List<IndustryProfileItem> industryProfiles = [
    const IndustryProfileItem(
      industry: 'GENERAL_DISCRETE',
      displayName: 'General Discrete Manufacturing',
      version: '1.0.0',
      status: 'OPERATIONAL',
      capabilities: ['INVENTORY_QUERY', 'WORK_ORDER_CREATION', 'PROCESS_DISCOVERY', 'PROCESS_SIMULATION'],
      supportedTools: ['inspect_inventory_stock', 'create_work_order', 'discover_and_validate_process', 'simulate_process_execution'],
    ),
    const IndustryProfileItem(
      industry: 'CNC_MACHINING',
      displayName: 'CNC Machining & Precision Engineering',
      version: '1.0.0',
      status: 'OPERATIONAL',
      capabilities: ['INVENTORY_QUERY', 'WORK_ORDER_CREATION', 'PROCESS_DISCOVERY', 'PROCESS_SIMULATION'],
      supportedTools: ['inspect_inventory_stock', 'create_work_order', 'discover_and_validate_process', 'simulate_process_execution'],
    ),
    const IndustryProfileItem(
      industry: 'TEXTILES',
      displayName: 'Textiles & Apparel Manufacturing',
      version: '1.0.0',
      status: 'OPERATIONAL',
      capabilities: ['INVENTORY_QUERY', 'WORK_ORDER_CREATION', 'PROCESS_DISCOVERY', 'PROCESS_SIMULATION'],
      supportedTools: ['inspect_inventory_stock', 'create_work_order', 'discover_and_validate_process', 'simulate_process_execution'],
    ),
    const IndustryProfileItem(
      industry: 'AUTOMOTIVE_EV',
      displayName: 'Automotive & EV Assembly',
      version: '1.0.0',
      status: 'OPERATIONAL',
      capabilities: ['INVENTORY_QUERY', 'WORK_ORDER_CREATION', 'PROCESS_DISCOVERY', 'PROCESS_SIMULATION'],
      supportedTools: ['inspect_inventory_stock', 'create_work_order', 'discover_and_validate_process', 'simulate_process_execution'],
    ),
    const IndustryProfileItem(
      industry: 'ELECTRONICS_PCBA',
      displayName: 'Electronics & PCBA Manufacturing',
      version: '1.0.0',
      status: 'OPERATIONAL',
      capabilities: ['INVENTORY_QUERY', 'WORK_ORDER_CREATION', 'PROCESS_DISCOVERY', 'PROCESS_SIMULATION'],
      supportedTools: ['inspect_inventory_stock', 'create_work_order', 'discover_and_validate_process', 'simulate_process_execution'],
    ),
    const IndustryProfileItem(
      industry: 'PHARMACEUTICALS',
      displayName: 'Pharmaceuticals & Life Sciences',
      version: '1.0.0',
      status: 'PREVIEW',
      capabilities: ['BATCH_TRACEABILITY'],
      supportedTools: ['inspect_inventory_stock'],
    ),
    const IndustryProfileItem(
      industry: 'FOOD_BEVERAGE',
      displayName: 'Food & Beverage Processing',
      version: '1.0.0',
      status: 'PREVIEW',
      capabilities: ['RECIPE_MANAGEMENT'],
      supportedTools: ['inspect_inventory_stock'],
    ),
    const IndustryProfileItem(
      industry: 'CHEMICALS',
      displayName: 'Specialty Chemicals & Polymers',
      version: '1.0.0',
      status: 'PREVIEW',
      capabilities: ['REACTOR_MONITORING'],
      supportedTools: ['inspect_inventory_stock'],
    ),
  ];

  List<AgentRunItem> goalRuns = [
    AgentRunItem(
      id: 'run-test-101',
      factoryId: 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      goalText: 'Prepare a 100-unit production order. Check material availability, identify the applicable process, estimate execution using simulation, and request approval before releasing the order.',
      industryProfileKey: 'GENERAL_DISCRETE',
      profileVersion: '1.0.0',
      status: 'AWAITING_APPROVAL',
      statusDisplay: 'Awaiting Approval',
      providerType: 'openai_compatible',
      modelName: 'gpt-4o-mini',
      executionMode: 'llm',
      currentStepIndex: 4,
      maxSteps: 10,
      activePlan: AgentPlanItem(
        id: 'plan-101',
        version: 1,
        goalSummary: 'Verify stock, discover process, simulate execution, create work order',
        completionCriteria: const {'work_order_created': true, 'inventory_verified': true},
        steps: const [
          AgentStepItem(
            id: 'step-1',
            stepNumber: 1,
            title: 'Inspect Stock',
            toolName: 'inspect_inventory_stock',
            isConsequential: false,
            status: 'COMPLETED',
            statusDisplay: 'Completed',
            resultData: {'available': true, 'current_stock': 150.0},
          ),
          AgentStepItem(
            id: 'step-2',
            stepNumber: 2,
            title: 'Discover Process',
            toolName: 'discover_and_validate_process',
            isConsequential: false,
            status: 'COMPLETED',
            statusDisplay: 'Completed',
            resultData: {'is_valid': true, 'process_version_id': 'pv-101'},
          ),
          AgentStepItem(
            id: 'step-3',
            stepNumber: 3,
            title: 'Simulate Execution',
            toolName: 'simulate_process_execution',
            isConsequential: false,
            status: 'COMPLETED',
            statusDisplay: 'Completed',
            resultData: {'estimated_lead_time_minutes': 85.0},
          ),
          AgentStepItem(
            id: 'step-4',
            stepNumber: 4,
            title: 'Create Production Work Order',
            toolName: 'create_work_order',
            toolArguments: {'quantity': 100, 'priority': 'HIGH'},
            isConsequential: true,
            status: 'AWAITING_APPROVAL',
            statusDisplay: 'Awaiting Approval',
          ),
        ],
      ),
      toolCalls: const [
        AgentToolCallItem(
          id: 'tc-1',
          toolName: 'inspect_inventory_stock',
          status: 'EXECUTED',
          durationMs: 42,
        ),
      ],
      observations: const [
        AgentObservationItem(
          id: 'obs-1',
          observationType: 'INVENTORY_CONFIRMED',
          content: 'Stock verified at 150.0 units.',
        ),
      ],
    ),
  ];

  @override
  Future<AutomationSummaryData> getSummary({String? factoryId}) async {
    if (shouldFail) throw Exception('API connection timeout');
    return AutomationSummaryData(
      totalAgents: agents.length,
      enabledAgents: agents.where((a) => a.isEnabled).length,
      totalEventsProcessed: events.length,
      pendingApprovals: approvals.where((a) => a.status == 'PENDING').length,
      successfulActions: 1,
      failedActions: 0,
    );
  }

  @override
  Future<List<AgentItem>> getAgents({String? agentType}) async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(agents);
  }

  @override
  Future<AgentItem> toggleAgent(String agentIdentifier, {bool? isEnabled}) async {
    lastToggledAgentKey = agentIdentifier;
    lastToggledAgentValue = isEnabled;
    final idx = agents.indexWhere((a) => a.key == agentIdentifier || a.id == agentIdentifier);
    if (idx != -1) {
      final old = agents[idx];
      final updated = AgentItem(
        id: old.id,
        name: old.name,
        key: old.key,
        agentType: old.agentType,
        agentTypeDisplay: old.agentTypeDisplay,
        description: old.description,
        isEnabled: isEnabled ?? !old.isEnabled,
        supportedEventTypes: old.supportedEventTypes,
        allowedActionTypes: old.allowedActionTypes,
        requiresApproval: old.requiresApproval,
      );
      agents[idx] = updated;
      return updated;
    }
    throw Exception('Agent not found');
  }

  @override
  Future<List<ManufacturingEventItem>> getEvents({
    String? factoryId,
    String? eventType,
    String? severity,
    String? status,
    int limit = 50,
  }) async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(events);
  }

  @override
  Future<ManufacturingEventItem> simulateEvent(Map<String, dynamic> payload) async {
    lastSimulatedPayload = payload;
    final newEvt = ManufacturingEventItem(
      id: 'evt-sim-${DateTime.now().millisecondsSinceEpoch}',
      factoryId: payload['factory_id']?.toString() ?? 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      eventType: payload['event_type']?.toString() ?? 'MACHINE_ANOMALY',
      eventTypeDisplay: 'Machine Anomaly / Breakdown',
      sourceType: 'SIMULATION',
      severity: payload['severity']?.toString() ?? 'WARNING',
      payload: payload['payload'] as Map<String, dynamic>? ?? {},
      status: 'PROCESSED',
      timestamp: DateTime.now(),
      decisions: const [
        AgentDecisionItem(
          id: 'dec-sim-1',
          eventId: 'evt-sim-1',
          agentId: 'agent-2',
          agentName: 'Predictive & Preventative Maintenance Agent',
          agentKey: 'maintenance_agent',
          status: 'AWAITING_APPROVAL',
          findings: 'Simulated thermal variance detected.',
          proposedAction: 'CREATE_MAINTENANCE_TICKET',
        ),
      ],
    );
    events.insert(0, newEvt);
    return newEvt;
  }

  @override
  Future<List<AgentDecisionItem>> getDecisions({String? factoryId, String? status, String? agentKey, int limit = 50}) async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(decisions);
  }

  @override
  Future<List<ApprovalRequestItem>> getApprovals({String? factoryId, String? status}) async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(approvals);
  }

  @override
  Future<ApprovalRequestItem> decideApproval(String approvalId, {required String action, String notes = '', String reviewer = 'Plant Operator'}) async {
    lastDecidedApprovalId = approvalId;
    lastDecidedAction = action;

    final idx = approvals.indexWhere((a) => a.id == approvalId);
    if (idx != -1) {
      final old = approvals[idx];
      final updated = ApprovalRequestItem(
        id: old.id,
        decisionId: old.decisionId,
        factoryId: old.factoryId,
        factoryName: old.factoryName,
        agentName: old.agentName,
        agentKey: old.agentKey,
        eventId: old.eventId,
        eventType: old.eventType,
        status: action == 'APPROVE' ? 'APPROVED' : 'REJECTED',
        requestedAction: old.requestedAction,
        actionSummary: old.actionSummary,
        actionParameters: old.actionParameters,
        decisionRationale: old.decisionRationale,
        urgency: old.urgency,
        reviewedBy: reviewer,
        reviewNotes: notes,
        reviewedAt: DateTime.now(),
      );
      approvals[idx] = updated;
      return updated;
    }
    throw Exception('Approval not found');
  }

  @override
  Future<List<AutomationAuditItem>> getAudits({String? factoryId, String? category, int limit = 50}) async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(audits);
  }

  // =====================================================================
  // PHASE 4 STEP 2 REPOSITORY IMPLEMENTATIONS
  // =====================================================================

  @override
  Future<ProviderStatusItem> getProviderStatus() async {
    if (shouldFail) throw Exception('API connection timeout');
    return providerStatus;
  }

  @override
  Future<List<IndustryProfileItem>> getIndustryProfiles() async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(industryProfiles);
  }

  @override
  Future<List<AgentRunItem>> getGoalRuns({String? factoryId, String? status}) async {
    if (shouldFail) throw Exception('API connection timeout');
    return List.from(goalRuns);
  }

  @override
  Future<AgentRunItem> getGoalRun(String runId) async {
    if (shouldFail) throw Exception('API connection timeout');
    final match = goalRuns.where((r) => r.id == runId).toList();
    if (match.isNotEmpty) return match.first;
    throw Exception('Run not found');
  }

  @override
  Future<AgentRunItem> createGoalRun(Map<String, dynamic> payload) async {
    lastGoalPayload = payload;
    final newRun = AgentRunItem(
      id: 'run-new-${DateTime.now().millisecondsSinceEpoch}',
      factoryId: payload['factory_id']?.toString() ?? 'test-factory-1',
      factoryName: 'Apex Precision Plant 1',
      goalText: payload['goal_text']?.toString() ?? '',
      industryProfileKey: payload['industry_profile_key']?.toString() ?? 'GENERAL_DISCRETE',
      status: 'RUNNING',
      statusDisplay: 'Running',
      providerType: 'openai_compatible',
      modelName: 'gpt-4o-mini',
      executionMode: 'llm',
      currentStepIndex: 1,
      maxSteps: 10,
      activePlan: const AgentPlanItem(
        id: 'plan-new',
        version: 1,
        goalSummary: 'Generated autonomous plan',
        steps: [
          AgentStepItem(
            id: 'step-new-1',
            stepNumber: 1,
            title: 'Inspect Stock',
            toolName: 'inspect_inventory_stock',
            status: 'READY',
            statusDisplay: 'Ready',
          ),
        ],
      ),
    );
    goalRuns.insert(0, newRun);
    return newRun;
  }

  @override
  Future<AgentRunItem> advanceGoalRunStep(String runId) async {
    lastAdvancedRunId = runId;
    final idx = goalRuns.indexWhere((r) => r.id == runId);
    if (idx != -1) {
      final old = goalRuns[idx];
      final updated = AgentRunItem(
        id: old.id,
        factoryId: old.factoryId,
        factoryName: old.factoryName,
        goalText: old.goalText,
        industryProfileKey: old.industryProfileKey,
        status: 'COMPLETED',
        statusDisplay: 'Completed',
        providerType: old.providerType,
        modelName: old.modelName,
        executionMode: old.executionMode,
        currentStepIndex: old.currentStepIndex + 1,
        maxSteps: old.maxSteps,
        completionSummary: const {'verified': true, 'work_order_id': 'WO-20261020-001'},
        activePlan: old.activePlan,
        toolCalls: old.toolCalls,
        observations: old.observations,
      );
      goalRuns[idx] = updated;
      return updated;
    }
    throw Exception('Run not found');
  }

  @override
  Future<AgentRunItem> approveGoalRun(
    String runId, {
    required String action,
    String notes = '',
    String reviewer = 'Plant Operator',
  }) async {
    lastGoalApprovedId = runId;
    lastGoalApprovedAction = action;
    final idx = goalRuns.indexWhere((r) => r.id == runId);
    if (idx != -1) {
      final old = goalRuns[idx];
      final updated = AgentRunItem(
        id: old.id,
        factoryId: old.factoryId,
        factoryName: old.factoryName,
        goalText: old.goalText,
        industryProfileKey: old.industryProfileKey,
        status: action == 'APPROVE' ? 'RUNNING' : 'FAILED',
        statusDisplay: action == 'APPROVE' ? 'Running' : 'Failed',
        providerType: old.providerType,
        modelName: old.modelName,
        executionMode: old.executionMode,
        currentStepIndex: old.currentStepIndex,
        maxSteps: old.maxSteps,
        activePlan: old.activePlan,
        toolCalls: old.toolCalls,
        observations: old.observations,
      );
      goalRuns[idx] = updated;
      return updated;
    }
    throw Exception('Run not found');
  }

  @override
  Future<AgentRunItem> submitClarification(String runId, String answer) async {
    lastClarificationAnswer = answer;
    final idx = goalRuns.indexWhere((r) => r.id == runId);
    if (idx != -1) {
      final old = goalRuns[idx];
      final updated = AgentRunItem(
        id: old.id,
        factoryId: old.factoryId,
        goalText: old.goalText,
        industryProfileKey: old.industryProfileKey,
        status: 'RUNNING',
        statusDisplay: 'Running',
        clarificationAnswer: answer,
        activePlan: old.activePlan,
      );
      goalRuns[idx] = updated;
      return updated;
    }
    throw Exception('Run not found');
  }

  @override
  Future<AgentRunItem> cancelGoalRun(String runId, {String reason = 'Cancelled by operator'}) async {
    final idx = goalRuns.indexWhere((r) => r.id == runId);
    if (idx != -1) {
      final old = goalRuns[idx];
      final updated = AgentRunItem(
        id: old.id,
        factoryId: old.factoryId,
        goalText: old.goalText,
        industryProfileKey: old.industryProfileKey,
        status: 'CANCELLED',
        statusDisplay: 'Cancelled',
        activePlan: old.activePlan,
      );
      goalRuns[idx] = updated;
      return updated;
    }
    throw Exception('Run not found');
  }
}

Widget createTestApp(Widget child, {MockFactoryRepository? factoryRepo, MockAgentAutomationRepository? agentRepo}) {
  return ProviderScope(
    overrides: [
      factoryRepositoryProvider.overrideWithValue(factoryRepo ?? MockFactoryRepository()),
      agentAutomationRepositoryProvider.overrideWithValue(agentRepo ?? MockAgentAutomationRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Phase 4 Step 1: Agent Automation Workspace Widget Tests', () {
    testWidgets('AgentAutomationScreen renders KPI deck and specialist agents', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const AgentAutomationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('AI Agent Automation Engine'), findsOneWidget);
      expect(find.text('EVENT & GOAL-DRIVEN RUNTIME'), findsOneWidget);
      expect(find.text('Specialist Agents'), findsWidgets);
      expect(find.text('Events Ingested'), findsOneWidget);
      expect(find.text('Pending Approvals'), findsOneWidget);
      expect(find.text('Actions Executed'), findsOneWidget);

      // Verify specialist agent cards
      expect(find.text('Production Orchestration Agent'), findsOneWidget);
      expect(find.text('Predictive & Preventative Maintenance Agent'), findsOneWidget);
      expect(find.text('Quality Assurance & Scrap Reduction Agent'), findsOneWidget);
      expect(find.text('Inventory Replenishment & WIP Agent'), findsOneWidget);
      expect(find.text('Energy Optimization & Sustainability Agent'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen toggles agent active status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const Key('agent_toggle_maintenance_agent'));
      expect(toggleFinder, findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(mockRepo.lastToggledAgentKey, 'maintenance_agent');
      expect(mockRepo.lastToggledAgentValue, false);
      expect(find.textContaining('is now DISABLED'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen navigates between tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const AgentAutomationScreen()));
      await tester.pumpAndSettle();

      // Switch to Event Pipeline tab
      await tester.tap(find.text('Event Pipeline'));
      await tester.pumpAndSettle();

      expect(find.text('MACHINE_ANOMALY'), findsOneWidget);
      expect(find.text('SIMULATED DATA'), findsOneWidget);

      // Switch to Agent Decisions tab
      await tester.tap(find.text('Agent Decisions'));
      await tester.pumpAndSettle();

      expect(find.text('Critical spindle bearing thermal breach (94.2°C).'), findsOneWidget);
      expect(find.textContaining('CREATE_MAINTENANCE_TICKET'), findsOneWidget);

      // Switch to Approval Inbox tab
      await tester.tap(find.text('Approval Inbox'));
      await tester.pumpAndSettle();

      expect(find.text('Approve & Execute'), findsOneWidget);
      expect(find.text('Reject Action'), findsOneWidget);

      // Switch to Audit Trail tab
      await tester.tap(find.text('Audit Trail'));
      await tester.pumpAndSettle();

      expect(find.text('EVENT_INGESTED'), findsOneWidget);
      expect(find.text('APPROVAL_REQUESTED'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen approves pending action request', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approval Inbox'));
      await tester.pumpAndSettle();

      final approveBtn = find.byKey(const Key('approve_button_appr-1'));
      expect(approveBtn, findsOneWidget);

      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastDecidedApprovalId, 'appr-1');
      expect(mockRepo.lastDecidedAction, 'APPROVE');
      expect(find.textContaining('was APPROVED'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen rejects pending action request', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approval Inbox'));
      await tester.pumpAndSettle();

      final rejectBtn = find.byKey(const Key('reject_button_appr-1'));
      expect(rejectBtn, findsOneWidget);

      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastDecidedApprovalId, 'appr-1');
      expect(mockRepo.lastDecidedAction, 'REJECT');
      expect(find.textContaining('was REJECTED'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen opens event simulation modal and submits event', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_simulator_button')));
      await tester.pumpAndSettle();

      expect(find.text('Simulate Manufacturing Event'), findsOneWidget);
      expect(find.byKey(const Key('simulate_event_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('submit_simulation_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('submit_simulation_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastSimulatedPayload?['event_type'], 'MACHINE_ANOMALY');
      expect(find.text('Simulate Manufacturing Event'), findsNothing);
      expect(find.textContaining('Simulated'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen displays error banner and reloads upon retry', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();
      mockRepo.shouldFail = true;

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('automation_error_banner')), findsOneWidget);
      expect(find.byKey(const Key('automation_retry_button')), findsOneWidget);

      mockRepo.shouldFail = false;
      await tester.tap(find.byKey(const Key('automation_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('automation_error_banner')), findsNothing);
      expect(find.text('Production Orchestration Agent'), findsOneWidget);
    });
  });

  group('Phase 4 Step 2: Universal Goal-Driven Agent Runtime Widget Tests', () {
    testWidgets('AgentAutomationScreen switches to Goal-Driven Agent tab and displays goal input card, prompt chips, and profile selector', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      // Switch to Goal-Driven Agent tab
      await tester.tap(find.text('Goal-Driven Agent'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('goal_input_card')), findsOneWidget);
      expect(find.text('Universal Manufacturing Goal Agent'), findsOneWidget);
      expect(find.byKey(const Key('goal_text_field')), findsOneWidget);
      expect(find.byKey(const Key('industry_profile_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('submit_goal_button')), findsOneWidget);

      // Verify active run detail is displayed
      expect(find.byKey(const Key('goal_run_header_card')), findsOneWidget);
      expect(find.byKey(const Key('consequential_approval_card')), findsOneWidget);
      expect(find.byKey(const Key('structured_plan_card')), findsOneWidget);
      expect(find.text('#4 Create Production Work Order'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen submits manufacturing goal and renders plan', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      // Switch to Goal-Driven Agent tab
      await tester.tap(find.text('Goal-Driven Agent'));
      await tester.pumpAndSettle();

      // Tap Generate Plan & Launch
      await tester.tap(find.byKey(const Key('submit_goal_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastGoalPayload, isNotNull);
      expect(mockRepo.lastGoalPayload?['goal_text'], contains('Prepare a 100-unit production order'));
      expect(find.textContaining('Goal registered'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen approves consequential goal action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      // Switch to Goal-Driven Agent tab
      await tester.tap(find.text('Goal-Driven Agent'));
      await tester.pumpAndSettle();

      // Find consequential approval card
      expect(find.byKey(const Key('consequential_approval_card')), findsOneWidget);
      final approveBtn = find.byKey(const Key('approve_goal_action_button'));
      expect(approveBtn, findsOneWidget);

      // Ensure visible and approve action
      await tester.ensureVisible(approveBtn);
      await tester.pumpAndSettle();
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastGoalApprovedId, 'run-test-101');
      expect(mockRepo.lastGoalApprovedAction, 'APPROVE');
      expect(find.textContaining('Approval decision recorded: APPROVE'), findsOneWidget);
    });

    testWidgets('AgentAutomationScreen opens Industry Profiles dialog displaying 8 profiles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockAgentAutomationRepository();

      await tester.pumpWidget(createTestApp(const AgentAutomationScreen(), agentRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap Industry Profiles button in header
      final profilesBtn = find.byKey(const Key('open_industry_profiles_button'));
      expect(profilesBtn, findsOneWidget);

      await tester.tap(profilesBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('industry_profiles_dialog')), findsOneWidget);
      expect(find.text('Universal Industry Profiles (8)'), findsOneWidget);
      expect(find.textContaining('CNC Machining & Precision Engineering'), findsOneWidget);
      expect(find.textContaining('Textiles & Apparel Manufacturing'), findsOneWidget);
      expect(find.textContaining('Automotive & EV Assembly'), findsOneWidget);
      expect(find.textContaining('Pharmaceuticals & Life Sciences'), findsOneWidget);
      expect(find.text('OPERATIONAL'), findsWidgets);
      expect(find.text('PREVIEW'), findsWidgets);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('industry_profiles_dialog')), findsNothing);
    });
  });
}
