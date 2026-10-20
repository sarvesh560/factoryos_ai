// FactoryOS AI — Agent Automation Data Models
// Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Audit Trail

class AutomationSummaryData {
  final int totalAgents;
  final int enabledAgents;
  final int totalEventsProcessed;
  final int pendingApprovals;
  final int successfulActions;
  final int failedActions;

  const AutomationSummaryData({
    this.totalAgents = 0,
    this.enabledAgents = 0,
    this.totalEventsProcessed = 0,
    this.pendingApprovals = 0,
    this.successfulActions = 0,
    this.failedActions = 0,
  });

  factory AutomationSummaryData.fromJson(Map<String, dynamic> json) {
    return AutomationSummaryData(
      totalAgents: (json['total_agents'] as num?)?.toInt() ?? 0,
      enabledAgents: (json['enabled_agents'] as num?)?.toInt() ?? 0,
      totalEventsProcessed: (json['total_events_processed'] as num?)?.toInt() ?? 0,
      pendingApprovals: (json['pending_approvals'] as num?)?.toInt() ?? 0,
      successfulActions: (json['successful_actions'] as num?)?.toInt() ?? 0,
      failedActions: (json['failed_actions'] as num?)?.toInt() ?? 0,
    );
  }
}

class AgentItem {
  final String id;
  final String name;
  final String key;
  final String description;
  final String agentType;
  final String agentTypeDisplay;
  final bool isEnabled;
  final List<String> supportedEventTypes;
  final List<String> allowedActionTypes;
  final String? factoryId;
  final String? factoryName;
  final bool requiresApproval;
  final Map<String, dynamic> config;
  final DateTime? updatedAt;

  const AgentItem({
    required this.id,
    required this.name,
    required this.key,
    this.description = '',
    required this.agentType,
    this.agentTypeDisplay = '',
    this.isEnabled = true,
    this.supportedEventTypes = const [],
    this.allowedActionTypes = const [],
    this.factoryId,
    this.factoryName,
    this.requiresApproval = true,
    this.config = const {},
    this.updatedAt,
  });

  factory AgentItem.fromJson(Map<String, dynamic> json) {
    return AgentItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Specialist Agent',
      key: json['key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      agentType: json['agent_type']?.toString() ?? 'CUSTOM',
      agentTypeDisplay: json['agent_type_display']?.toString() ?? json['agent_type']?.toString() ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
      supportedEventTypes: (json['supported_event_types'] as List?)?.map((e) => e.toString()).toList() ?? [],
      allowedActionTypes: (json['allowed_action_types'] as List?)?.map((e) => e.toString()).toList() ?? [],
      factoryId: json['factory']?.toString(),
      factoryName: json['factory_name']?.toString(),
      requiresApproval: json['requires_approval'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}

class AgentDecisionItem {
  final String id;
  final String eventId;
  final String eventType;
  final String eventSeverity;
  final String agentId;
  final String agentName;
  final String agentKey;
  final String agentType;
  final String status;
  final String statusDisplay;
  final String findings;
  final Map<String, dynamic> evidence;
  final String proposedAction;
  final Map<String, dynamic> actionParameters;
  final String rationale;
  final double confidenceScore;
  final Map<String, dynamic> providerInfo;
  final DateTime? createdAt;

  const AgentDecisionItem({
    required this.id,
    required this.eventId,
    this.eventType = '',
    this.eventSeverity = 'INFO',
    required this.agentId,
    this.agentName = '',
    this.agentKey = '',
    this.agentType = '',
    required this.status,
    this.statusDisplay = '',
    this.findings = '',
    this.evidence = const {},
    this.proposedAction = '',
    this.actionParameters = const {},
    this.rationale = '',
    this.confidenceScore = 1.0,
    this.providerInfo = const {},
    this.createdAt,
  });

  factory AgentDecisionItem.fromJson(Map<String, dynamic> json) {
    return AgentDecisionItem(
      id: json['id']?.toString() ?? '',
      eventId: json['event']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      eventSeverity: json['event_severity']?.toString() ?? 'INFO',
      agentId: json['agent']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? 'Agent',
      agentKey: json['agent_key']?.toString() ?? '',
      agentType: json['agent_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NO_ACTION',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      findings: json['findings']?.toString() ?? '',
      evidence: json['evidence'] as Map<String, dynamic>? ?? {},
      proposedAction: json['proposed_action']?.toString() ?? '',
      actionParameters: json['action_parameters'] as Map<String, dynamic>? ?? {},
      rationale: json['rationale']?.toString() ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 1.0,
      providerInfo: json['provider_info'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class ManufacturingEventItem {
  final String id;
  final String factoryId;
  final String factoryName;
  final String factoryCode;
  final String eventType;
  final String eventTypeDisplay;
  final String sourceType;
  final String sourceId;
  final String severity;
  final String severityDisplay;
  final Map<String, dynamic> payload;
  final DateTime? timestamp;
  final String status;
  final String statusDisplay;
  final String correlationId;
  final String errorMessage;
  final List<AgentDecisionItem> decisions;
  final DateTime? createdAt;

  const ManufacturingEventItem({
    required this.id,
    required this.factoryId,
    this.factoryName = '',
    this.factoryCode = '',
    required this.eventType,
    this.eventTypeDisplay = '',
    this.sourceType = 'SIMULATION',
    this.sourceId = '',
    this.severity = 'INFO',
    this.severityDisplay = '',
    this.payload = const {},
    this.timestamp,
    this.status = 'PENDING',
    this.statusDisplay = '',
    this.correlationId = '',
    this.errorMessage = '',
    this.decisions = const [],
    this.createdAt,
  });

  factory ManufacturingEventItem.fromJson(Map<String, dynamic> json) {
    var rawDecisions = json['decisions'];
    List<AgentDecisionItem> parsedDecisions = [];
    if (rawDecisions is List) {
      parsedDecisions = rawDecisions.map((d) => AgentDecisionItem.fromJson(d as Map<String, dynamic>)).toList();
    }

    return ManufacturingEventItem(
      id: json['id']?.toString() ?? '',
      factoryId: json['factory']?.toString() ?? '',
      factoryName: json['factory_name']?.toString() ?? '',
      factoryCode: json['factory_code']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      eventTypeDisplay: json['event_type_display']?.toString() ?? json['event_type']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? 'SIMULATION',
      sourceId: json['source_id']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'INFO',
      severityDisplay: json['severity_display']?.toString() ?? json['severity']?.toString() ?? '',
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
      status: json['status']?.toString() ?? 'PENDING',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      correlationId: json['correlation_id']?.toString() ?? '',
      errorMessage: json['error_message']?.toString() ?? '',
      decisions: parsedDecisions,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class ApprovalRequestItem {
  final String id;
  final String decisionId;
  final String factoryId;
  final String factoryName;
  final String agentName;
  final String agentKey;
  final String eventId;
  final String eventType;
  final String status;
  final String requestedAction;
  final String actionSummary;
  final Map<String, dynamic> actionParameters;
  final String decisionRationale;
  final String urgency;
  final String reviewedBy;
  final String reviewNotes;
  final DateTime? reviewedAt;
  final String? actionExecutionId;
  final String? actionExecutionStatus;
  final DateTime? createdAt;

  const ApprovalRequestItem({
    required this.id,
    required this.decisionId,
    required this.factoryId,
    this.factoryName = '',
    this.agentName = '',
    this.agentKey = '',
    this.eventId = '',
    this.eventType = '',
    required this.status,
    required this.requestedAction,
    this.actionSummary = '',
    this.actionParameters = const {},
    this.decisionRationale = '',
    this.urgency = 'WARNING',
    this.reviewedBy = '',
    this.reviewNotes = '',
    this.reviewedAt,
    this.actionExecutionId,
    this.actionExecutionStatus,
    this.createdAt,
  });

  factory ApprovalRequestItem.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestItem(
      id: json['id']?.toString() ?? '',
      decisionId: json['decision']?.toString() ?? '',
      factoryId: json['factory']?.toString() ?? '',
      factoryName: json['factory_name']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? '',
      agentKey: json['agent_key']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      requestedAction: json['requested_action']?.toString() ?? '',
      actionSummary: json['action_summary']?.toString() ?? '',
      actionParameters: json['action_parameters'] as Map<String, dynamic>? ?? {},
      decisionRationale: json['decision_rationale']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'WARNING',
      reviewedBy: json['reviewed_by']?.toString() ?? '',
      reviewNotes: json['review_notes']?.toString() ?? '',
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'].toString()) : null,
      actionExecutionId: json['action_execution_id']?.toString(),
      actionExecutionStatus: json['action_execution_status']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class ActionExecutionItem {
  final String id;
  final String? decisionId;
  final String? approvalRequestId;
  final String factoryId;
  final String factoryName;
  final String actionType;
  final Map<String, dynamic> parameters;
  final String status;
  final String statusDisplay;
  final String idempotencyKey;
  final Map<String, dynamic> resultPayload;
  final String errorMessage;
  final int retryCount;
  final DateTime? executedAt;
  final DateTime? createdAt;

  const ActionExecutionItem({
    required this.id,
    this.decisionId,
    this.approvalRequestId,
    required this.factoryId,
    this.factoryName = '',
    required this.actionType,
    this.parameters = const {},
    required this.status,
    this.statusDisplay = '',
    this.idempotencyKey = '',
    this.resultPayload = const {},
    this.errorMessage = '',
    this.retryCount = 0,
    this.executedAt,
    this.createdAt,
  });

  factory ActionExecutionItem.fromJson(Map<String, dynamic> json) {
    return ActionExecutionItem(
      id: json['id']?.toString() ?? '',
      decisionId: json['decision']?.toString(),
      approvalRequestId: json['approval_request']?.toString(),
      factoryId: json['factory']?.toString() ?? '',
      factoryName: json['factory_name']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      status: json['status']?.toString() ?? 'PENDING_APPROVAL',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      idempotencyKey: json['idempotency_key']?.toString() ?? '',
      resultPayload: json['result_payload'] as Map<String, dynamic>? ?? {},
      errorMessage: json['error_message']?.toString() ?? '',
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      executedAt: json['executed_at'] != null ? DateTime.tryParse(json['executed_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class AutomationAuditItem {
  final String id;
  final String factoryId;
  final String factoryName;
  final String eventCategory;
  final String referenceId;
  final String actor;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  const AutomationAuditItem({
    required this.id,
    required this.factoryId,
    this.factoryName = '',
    required this.eventCategory,
    this.referenceId = '',
    this.actor = 'SYSTEM',
    this.details = const {},
    required this.timestamp,
  });

  factory AutomationAuditItem.fromJson(Map<String, dynamic> json) {
    return AutomationAuditItem(
      id: json['id']?.toString() ?? '',
      factoryId: json['factory']?.toString() ?? '',
      factoryName: json['factory_name']?.toString() ?? '',
      eventCategory: json['event_category']?.toString() ?? '',
      referenceId: json['reference_id']?.toString() ?? '',
      actor: json['actor']?.toString() ?? 'SYSTEM',
      details: json['details'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// =====================================================================
// PHASE 4 STEP 2: GOAL-DRIVEN AGENT RUNTIME & LLM DATA MODELS
// =====================================================================

class ProviderStatusItem {
  final String configuredProvider;
  final String activeMode;
  final bool isLlmAvailable;
  final String modelName;
  final String baseUrl;
  final String maskedApiKey;
  final int timeoutSeconds;
  final int maxRetries;
  final String providerVersion;

  const ProviderStatusItem({
    this.configuredProvider = 'deterministic',
    this.activeMode = 'deterministic',
    this.isLlmAvailable = false,
    this.modelName = '',
    this.baseUrl = '',
    this.maskedApiKey = '',
    this.timeoutSeconds = 30,
    this.maxRetries = 2,
    this.providerVersion = '1.0.0',
  });

  factory ProviderStatusItem.fromJson(Map<String, dynamic> json) {
    return ProviderStatusItem(
      configuredProvider: json['configured_provider']?.toString() ?? 'deterministic',
      activeMode: json['active_mode']?.toString() ?? 'deterministic',
      isLlmAvailable: json['is_llm_available'] as bool? ?? false,
      modelName: json['model_name']?.toString() ?? '',
      baseUrl: json['base_url']?.toString() ?? '',
      maskedApiKey: json['masked_api_key']?.toString() ?? '',
      timeoutSeconds: (json['timeout_seconds'] as num?)?.toInt() ?? 30,
      maxRetries: (json['max_retries'] as num?)?.toInt() ?? 2,
      providerVersion: json['provider_version']?.toString() ?? '1.0.0',
    );
  }
}

class IndustryProfileItem {
  final String industry;
  final String displayName;
  final String version;
  final String status;
  final List<String> capabilities;
  final List<String> supportedTools;
  final Map<String, dynamic> terminology;
  final List<String> safetyRestrictions;
  final List<String> workflowTemplates;

  const IndustryProfileItem({
    required this.industry,
    required this.displayName,
    this.version = '1.0.0',
    this.status = 'OPERATIONAL',
    this.capabilities = const [],
    this.supportedTools = const [],
    this.terminology = const {},
    this.safetyRestrictions = const [],
    this.workflowTemplates = const [],
  });

  bool get isOperational => status == 'OPERATIONAL';
  bool get isPreview => status == 'PREVIEW';
  bool get isUnavailable => status == 'UNAVAILABLE';

  factory IndustryProfileItem.fromJson(Map<String, dynamic> json) {
    return IndustryProfileItem(
      industry: json['industry']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['industry']?.toString() ?? '',
      version: json['version']?.toString() ?? '1.0.0',
      status: json['status']?.toString() ?? 'OPERATIONAL',
      capabilities: (json['capabilities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      supportedTools: (json['supported_tools'] as List?)?.map((e) => e.toString()).toList() ?? [],
      terminology: json['terminology'] as Map<String, dynamic>? ?? {},
      safetyRestrictions: (json['safety_restrictions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      workflowTemplates: (json['workflow_templates'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class AgentToolCallItem {
  final String id;
  final String? stepId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic> resultPayload;
  final String status;
  final String errorMessage;
  final String idempotencyKey;
  final int durationMs;
  final DateTime? executedAt;

  const AgentToolCallItem({
    required this.id,
    this.stepId,
    required this.toolName,
    this.arguments = const {},
    this.resultPayload = const {},
    required this.status,
    this.errorMessage = '',
    this.idempotencyKey = '',
    this.durationMs = 0,
    this.executedAt,
  });

  factory AgentToolCallItem.fromJson(Map<String, dynamic> json) {
    return AgentToolCallItem(
      id: json['id']?.toString() ?? '',
      stepId: json['step_id']?.toString(),
      toolName: json['tool_name']?.toString() ?? '',
      arguments: json['arguments'] as Map<String, dynamic>? ?? {},
      resultPayload: json['result_payload'] as Map<String, dynamic>? ?? {},
      status: json['status']?.toString() ?? 'EXECUTED',
      errorMessage: json['error_message']?.toString() ?? '',
      idempotencyKey: json['idempotency_key']?.toString() ?? '',
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      executedAt: json['executed_at'] != null ? DateTime.tryParse(json['executed_at'].toString()) : null,
    );
  }
}

class AgentObservationItem {
  final String id;
  final String? stepId;
  final String observationType;
  final String content;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  const AgentObservationItem({
    required this.id,
    this.stepId,
    required this.observationType,
    this.content = '',
    this.data = const {},
    this.createdAt,
  });

  factory AgentObservationItem.fromJson(Map<String, dynamic> json) {
    return AgentObservationItem(
      id: json['id']?.toString() ?? '',
      stepId: json['step_id']?.toString(),
      observationType: json['observation_type']?.toString() ?? 'INFO',
      content: json['content']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class AgentStepItem {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String toolName;
  final Map<String, dynamic> toolArguments;
  final bool isConsequential;
  final String status;
  final String statusDisplay;
  final Map<String, dynamic> resultData;
  final String errorMessage;
  final String? approvalId;
  final DateTime? createdAt;

  const AgentStepItem({
    required this.id,
    required this.stepNumber,
    required this.title,
    this.description = '',
    required this.toolName,
    this.toolArguments = const {},
    this.isConsequential = false,
    required this.status,
    this.statusDisplay = '',
    this.resultData = const {},
    this.errorMessage = '',
    this.approvalId,
    this.createdAt,
  });

  factory AgentStepItem.fromJson(Map<String, dynamic> json) {
    return AgentStepItem(
      id: json['id']?.toString() ?? '',
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      toolName: json['tool_name']?.toString() ?? '',
      toolArguments: json['tool_arguments'] as Map<String, dynamic>? ?? {},
      isConsequential: json['is_consequential'] as bool? ?? false,
      status: json['status']?.toString() ?? 'PENDING',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      resultData: json['result_data'] as Map<String, dynamic>? ?? {},
      errorMessage: json['error_message']?.toString() ?? '',
      approvalId: json['approval_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class AgentPlanItem {
  final String id;
  final int version;
  final String goalSummary;
  final Map<String, dynamic> completionCriteria;
  final bool isActive;
  final List<AgentStepItem> steps;
  final DateTime? createdAt;

  const AgentPlanItem({
    required this.id,
    required this.version,
    required this.goalSummary,
    this.completionCriteria = const {},
    this.isActive = true,
    this.steps = const [],
    this.createdAt,
  });

  factory AgentPlanItem.fromJson(Map<String, dynamic> json) {
    return AgentPlanItem(
      id: json['id']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      goalSummary: json['goal_summary']?.toString() ?? '',
      completionCriteria: json['completion_criteria'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      steps: (json['steps'] as List?)?.map((e) => AgentStepItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class AgentRunItem {
  final String id;
  final String factoryId;
  final String factoryName;
  final String goalText;
  final String industryProfileKey;
  final String profileVersion;
  final String status;
  final String statusDisplay;
  final String providerType;
  final String modelName;
  final String executionMode;
  final bool fallbackOccurred;
  final String fallbackReason;
  final int maxSteps;
  final int currentStepIndex;
  final int replanCount;
  final int maxReplans;
  final String clarificationQuestion;
  final String clarificationAnswer;
  final Map<String, dynamic> completionSummary;
  final String errorMessage;
  final AgentPlanItem? activePlan;
  final List<AgentObservationItem> observations;
  final List<AgentToolCallItem> toolCalls;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const AgentRunItem({
    required this.id,
    required this.factoryId,
    this.factoryName = '',
    required this.goalText,
    required this.industryProfileKey,
    this.profileVersion = '1.0.0',
    required this.status,
    this.statusDisplay = '',
    this.providerType = 'deterministic',
    this.modelName = '',
    this.executionMode = 'deterministic',
    this.fallbackOccurred = false,
    this.fallbackReason = '',
    this.maxSteps = 10,
    this.currentStepIndex = 0,
    this.replanCount = 0,
    this.maxReplans = 3,
    this.clarificationQuestion = '',
    this.clarificationAnswer = '',
    this.completionSummary = const {},
    this.errorMessage = '',
    this.activePlan,
    this.observations = const [],
    this.toolCalls = const [],
    this.createdAt,
    this.completedAt,
  });

  bool get isRunning => status == 'RUNNING';
  bool get isAwaitingApproval => status == 'AWAITING_APPROVAL';
  bool get isNeedsClarification => status == 'NEEDS_CLARIFICATION';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isBlocked => status == 'BLOCKED';
  bool get isCancelled => status == 'CANCELLED';

  factory AgentRunItem.fromJson(Map<String, dynamic> json) {
    return AgentRunItem(
      id: json['id']?.toString() ?? '',
      factoryId: json['factory']?.toString() ?? '',
      factoryName: json['factory_name']?.toString() ?? '',
      goalText: json['goal_text']?.toString() ?? '',
      industryProfileKey: json['industry_profile_key']?.toString() ?? 'GENERAL_DISCRETE',
      profileVersion: json['profile_version']?.toString() ?? '1.0.0',
      status: json['status']?.toString() ?? 'PLANNING',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      providerType: json['provider_type']?.toString() ?? 'deterministic',
      modelName: json['model_name']?.toString() ?? '',
      executionMode: json['execution_mode']?.toString() ?? 'deterministic',
      fallbackOccurred: json['fallback_occurred'] as bool? ?? false,
      fallbackReason: json['fallback_reason']?.toString() ?? '',
      maxSteps: (json['max_steps'] as num?)?.toInt() ?? 10,
      currentStepIndex: (json['current_step_index'] as num?)?.toInt() ?? 0,
      replanCount: (json['replan_count'] as num?)?.toInt() ?? 0,
      maxReplans: (json['max_replans'] as num?)?.toInt() ?? 3,
      clarificationQuestion: json['clarification_question']?.toString() ?? '',
      clarificationAnswer: json['clarification_answer']?.toString() ?? '',
      completionSummary: json['completion_summary'] as Map<String, dynamic>? ?? {},
      errorMessage: json['error_message']?.toString() ?? '',
      activePlan: json['active_plan'] != null ? AgentPlanItem.fromJson(json['active_plan'] as Map<String, dynamic>) : null,
      observations: (json['observations'] as List?)?.map((e) => AgentObservationItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      toolCalls: (json['tool_calls'] as List?)?.map((e) => AgentToolCallItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
    );
  }
}

