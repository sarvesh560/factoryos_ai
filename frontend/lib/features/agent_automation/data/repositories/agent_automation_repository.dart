// FactoryOS AI — Agent Automation Repository
// Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Audit Trail
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/agent_automation_models.dart';

final agentAutomationRepositoryProvider = Provider<AgentAutomationRepository>((ref) {
  return AgentAutomationRepository(ApiClient());
});

class AgentAutomationRepository {
  final ApiClient _client;

  AgentAutomationRepository(this._client);

  Future<AutomationSummaryData> getSummary({String? factoryId}) async {
    final params = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) {
      params['factory_id'] = factoryId;
    }
    final response = await _client.get('/api/automation/summary/', queryParameters: params);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return AutomationSummaryData.fromJson(response['data'] as Map<String, dynamic>);
    }
    return const AutomationSummaryData();
  }

  Future<List<AgentItem>> getAgents({String? agentType}) async {
    final params = <String, dynamic>{};
    if (agentType != null && agentType.isNotEmpty) {
      params['agent_type'] = agentType;
    }
    final response = await _client.get('/api/automation/agents/', queryParameters: params);
    if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => AgentItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AgentItem> getAgent(String agentIdentifier) async {
    final response = await _client.get('/api/automation/agents/$agentIdentifier/');
    if (response is Map<String, dynamic> && response['agent'] != null) {
      return AgentItem.fromJson(response['agent'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load agent details.');
  }

  Future<AgentItem> toggleAgent(String agentIdentifier, {bool? isEnabled}) async {
    final payload = <String, dynamic>{};
    if (isEnabled != null) {
      payload['is_enabled'] = isEnabled;
    }
    final response = await _client.post('/api/automation/agents/$agentIdentifier/toggle/', data: payload);
    if (response is Map<String, dynamic> && response['agent'] != null) {
      return AgentItem.fromJson(response['agent'] as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle agent state.');
  }

  Future<List<ManufacturingEventItem>> getEvents({
    String? factoryId,
    String? eventType,
    String? severity,
    String? status,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (factoryId != null && factoryId.isNotEmpty) params['factory_id'] = factoryId;
    if (eventType != null && eventType.isNotEmpty) params['event_type'] = eventType;
    if (severity != null && severity.isNotEmpty) params['severity'] = severity;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _client.get('/api/automation/events/', queryParameters: params);
    if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => ManufacturingEventItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ManufacturingEventItem> simulateEvent(Map<String, dynamic> payload) async {
    final response = await _client.post('/api/automation/events/simulate/', data: payload);
    if (response is Map<String, dynamic> && response['event'] != null) {
      return ManufacturingEventItem.fromJson(response['event'] as Map<String, dynamic>);
    }
    throw Exception(response['error'] ?? 'Event simulation failed.');
  }

  Future<ManufacturingEventItem> getEvent(String eventId) async {
    final response = await _client.get('/api/automation/events/$eventId/');
    if (response is Map<String, dynamic> && response['event'] != null) {
      return ManufacturingEventItem.fromJson(response['event'] as Map<String, dynamic>);
    }
    throw Exception('Event not found.');
  }

  Future<List<AgentDecisionItem>> getDecisions({
    String? factoryId,
    String? status,
    String? agentKey,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (factoryId != null && factoryId.isNotEmpty) params['factory_id'] = factoryId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (agentKey != null && agentKey.isNotEmpty) params['agent_key'] = agentKey;

    final response = await _client.get('/api/automation/decisions/', queryParameters: params);
    if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => AgentDecisionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ApprovalRequestItem>> getApprovals({String? factoryId, String? status}) async {
    final params = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) params['factory_id'] = factoryId;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _client.get('/api/automation/approvals/', queryParameters: params);
    if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => ApprovalRequestItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ApprovalRequestItem> decideApproval(
    String approvalId, {
    required String action,
    String notes = '',
    String reviewer = 'Plant Operator',
  }) async {
    final response = await _client.post(
      '/api/automation/approvals/$approvalId/decide/',
      data: {
        'action': action,
        'notes': notes,
        'reviewer': reviewer,
      },
    );
    if (response is Map<String, dynamic> && response['approval'] != null) {
      return ApprovalRequestItem.fromJson(response['approval'] as Map<String, dynamic>);
    }
    throw Exception(response['error'] ?? 'Approval decision failed.');
  }

  Future<ActionExecutionItem> retryAction(String executionId) async {
    final response = await _client.post('/api/automation/actions/$executionId/retry/');
    if (response is Map<String, dynamic> && response['action_execution'] != null) {
      return ActionExecutionItem.fromJson(response['action_execution'] as Map<String, dynamic>);
    }
    throw Exception(response['error'] ?? 'Action retry failed.');
  }

  Future<List<AutomationAuditItem>> getAudits({String? factoryId, String? category, int limit = 50}) async {
    final params = <String, dynamic>{'limit': limit};
    if (factoryId != null && factoryId.isNotEmpty) params['factory_id'] = factoryId;
    if (category != null && category.isNotEmpty) params['event_category'] = category;

    final response = await _client.get('/api/automation/audits/', queryParameters: params);
    if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => AutomationAuditItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // =====================================================================
  // PHASE 4 STEP 2: GOAL-DRIVEN RUNTIME REPOSITORY METHODS
  // =====================================================================

  Future<ProviderStatusItem> getProviderStatus() async {
    final response = await _client.get('/api/automation/provider-status/');
    if (response is Map<String, dynamic>) {
      return ProviderStatusItem.fromJson(response);
    }
    return const ProviderStatusItem();
  }

  Future<List<IndustryProfileItem>> getIndustryProfiles() async {
    final response = await _client.get('/api/automation/industries/');
    if (response is Map<String, dynamic> && response['industries'] is List) {
      return (response['industries'] as List)
          .map((e) => IndustryProfileItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<AgentRunItem>> getGoalRuns({String? factoryId, String? status}) async {
    final params = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) params['factory_id'] = factoryId;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _client.get('/api/automation/runs/', queryParameters: params);
    if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => AgentRunItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AgentRunItem> getGoalRun(String runId) async {
    final response = await _client.get('/api/automation/runs/$runId/');
    if (response is Map<String, dynamic>) {
      return AgentRunItem.fromJson(response);
    }
    throw Exception('Goal run not found.');
  }

  Future<AgentRunItem> createGoalRun(Map<String, dynamic> payload) async {
    final response = await _client.post('/api/automation/runs/', data: payload);
    if (response is Map<String, dynamic>) {
      return AgentRunItem.fromJson(response);
    }
    throw Exception('Failed to create goal run.');
  }

  Future<AgentRunItem> advanceGoalRunStep(String runId) async {
    final response = await _client.post('/api/automation/runs/$runId/step/');
    if (response is Map<String, dynamic> && response['run'] != null) {
      return AgentRunItem.fromJson(response['run'] as Map<String, dynamic>);
    }
    throw Exception(response is Map && response['error'] != null ? response['error'] : 'Failed to advance goal step.');
  }

  Future<AgentRunItem> approveGoalRun(
    String runId, {
    required String action,
    String notes = '',
    String reviewer = 'Plant Operator',
  }) async {
    final response = await _client.post(
      '/api/automation/runs/$runId/approve/',
      data: {
        'action': action,
        'notes': notes,
        'reviewer': reviewer,
      },
    );
    if (response is Map<String, dynamic> && response['run'] != null) {
      return AgentRunItem.fromJson(response['run'] as Map<String, dynamic>);
    }
    throw Exception(response is Map && response['error'] != null ? response['error'] : 'Approval action failed.');
  }

  Future<AgentRunItem> submitClarification(String runId, String answer) async {
    final response = await _client.post(
      '/api/automation/runs/$runId/clarify/',
      data: {'answer': answer},
    );
    if (response is Map<String, dynamic> && response['run'] != null) {
      return AgentRunItem.fromJson(response['run'] as Map<String, dynamic>);
    }
    throw Exception(response is Map && response['error'] != null ? response['error'] : 'Clarification submission failed.');
  }

  Future<AgentRunItem> cancelGoalRun(String runId, {String reason = 'Cancelled by operator'}) async {
    final response = await _client.post(
      '/api/automation/runs/$runId/cancel/',
      data: {'reason': reason},
    );
    if (response is Map<String, dynamic> && response['run'] != null) {
      return AgentRunItem.fromJson(response['run'] as Map<String, dynamic>);
    }
    throw Exception(response is Map && response['error'] != null ? response['error'] : 'Failed to cancel run.');
  }
}

