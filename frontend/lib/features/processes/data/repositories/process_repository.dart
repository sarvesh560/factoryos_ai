/// FactoryOS AI — Universal Process Engine Repository
/// Phase 3: Connects Flutter Web frontend to Django REST Framework UMPE APIs
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../factories/data/models/factory_model.dart';
import '../models/process_models.dart';

final processRepositoryProvider = Provider<ProcessRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProcessRepository(apiClient);
});

class ProcessRepository {
  final ApiClient _apiClient;

  ProcessRepository(this._apiClient);

  // ===========================================================================
  // 0. UNIVERSAL PROCESS TEMPLATES
  // ===========================================================================

  /// Retrieve universal manufacturing process templates
  Future<List<ProcessTemplateItem>> getTemplates({String? industryType, String? category}) async {
    final query = <String, dynamic>{};
    if (industryType != null && industryType.isNotEmpty) {
      query['industry_type'] = industryType;
    }
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    final data = await _apiClient.get(
      AppConfig.processTemplatesEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => ProcessTemplateItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Instantiate a universal process template into a concrete factory process definition
  Future<ProcessDefinitionItem> instantiateTemplate(
    String templateKey,
    Map<String, dynamic> payload,
  ) async {
    final data = await _apiClient.post(
      AppConfig.processTemplateInstantiateEndpoint(templateKey),
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessDefinitionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to instantiate process template.');
  }

  // ===========================================================================
  // 1. PROCESS DEFINITIONS & VERSIONS
  // ===========================================================================

  /// Deep duplicate an existing process definition into a new draft workflow
  Future<ProcessDefinitionItem> duplicateProcess(
    String id, {
    String? name,
    String? code,
    String? description,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null && name.isNotEmpty) payload['name'] = name;
    if (code != null && code.isNotEmpty) payload['code'] = code;
    if (description != null && description.isNotEmpty) payload['description'] = description;

    final data = await _apiClient.post(
      AppConfig.processDefinitionDuplicateEndpoint(id),
      data: payload.isEmpty ? null : payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessDefinitionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to duplicate process definition.');
  }

  /// Safely archive a process definition
  Future<ProcessDefinitionItem> archiveProcess(String id) async {
    final data = await _apiClient.post(AppConfig.processDefinitionArchiveEndpoint(id));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessDefinitionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to archive process definition.');
  }

  /// List process definitions (optionally filtered by factory)
  Future<List<ProcessDefinitionItem>> getProcessDefinitions({String? factoryId}) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) {
      query['factory_id'] = factoryId;
    }
    final data = await _apiClient.get(
      AppConfig.processDefinitionsEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => ProcessDefinitionItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Create a new process definition (automatically creates draft v1.0.0)
  Future<ProcessDefinitionItem> createProcessDefinition(Map<String, dynamic> payload) async {
    final data = await _apiClient.post(
      AppConfig.processDefinitionsEndpoint,
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessDefinitionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create process definition.');
  }

  /// Retrieve full details of a process definition
  Future<ProcessDefinitionItem> getProcessDefinition(String id) async {
    final data = await _apiClient.get(AppConfig.processDefinitionDetailEndpoint(id));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessDefinitionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load process definition.');
  }

  /// Retrieve full graph details (nodes & edges) of a process version
  Future<ProcessVersionItem> getProcessVersion(String versionId) async {
    final data = await _apiClient.get(AppConfig.processVersionDetailEndpoint(versionId));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessVersionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load process graph version.');
  }

  /// Clone an existing version into a new editable DRAFT version
  Future<ProcessVersionItem> cloneVersion(String definitionId) async {
    final data = await _apiClient.post(AppConfig.processVersionCloneEndpoint(definitionId));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessVersionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to clone process version.');
  }

  /// Validate graph topology, cycles, and connectivity
  Future<GraphValidationResult> validateVersion(String versionId) async {
    final data = await _apiClient.post(AppConfig.processVersionValidateEndpoint(versionId));
    if (data is Map<String, dynamic>) {
      return GraphValidationResult.fromJson(data);
    }
    throw Exception('Failed to validate process version.');
  }

  /// Publish a validated process version
  Future<ProcessVersionItem> publishVersion(String versionId) async {
    final data = await _apiClient.post(AppConfig.processVersionPublishEndpoint(versionId));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessVersionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    final msg = data is Map ? (data['error']?['message'] ?? 'Publishing failed.') : 'Error';
    throw Exception(msg);
  }

  /// Save canvas visual layout metadata and node coordinates
  Future<void> saveGraphLayout(
    String versionId, {
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? nodes,
  }) async {
    await _apiClient.put(
      AppConfig.processVersionLayoutEndpoint(versionId),
      data: {
        'graph_metadata': ?metadata,
        'nodes': ?nodes,
      },
    );
  }

  // ===========================================================================
  // 2. NODES & EDGES API
  // ===========================================================================

  /// Add a node to a draft process version
  Future<ProcessNodeItem> addNode(String versionId, Map<String, dynamic> payload) async {
    final data = await _apiClient.post(
      AppConfig.processNodesEndpoint(versionId),
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessNodeItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to add process node.');
  }

  /// Update node attributes, position, or resources
  Future<ProcessNodeItem> updateNode(String nodeId, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch(
      AppConfig.processNodeDetailEndpoint(nodeId),
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessNodeItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update process node.');
  }

  /// Delete a node from a draft graph
  Future<void> deleteNode(String nodeId) async {
    await _apiClient.delete(AppConfig.processNodeDetailEndpoint(nodeId));
  }

  /// Add a directed edge between two nodes
  Future<ProcessEdgeItem> addEdge(String versionId, Map<String, dynamic> payload) async {
    final data = await _apiClient.post(
      AppConfig.processEdgesEndpoint(versionId),
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessEdgeItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to connect process edge.');
  }

  /// Delete an edge from a draft graph
  Future<void> deleteEdge(String edgeId) async {
    await _apiClient.delete(AppConfig.processEdgeDetailEndpoint(edgeId));
  }

  // ===========================================================================
  // 3. WORK ORDERS
  // ===========================================================================

  /// List work orders
  Future<List<WorkOrderItem>> getWorkOrders({String? factoryId, String? status}) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) query['factory_id'] = factoryId;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final data = await _apiClient.get(
      AppConfig.workOrdersEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => WorkOrderItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Create a new work order
  Future<WorkOrderItem> createWorkOrder(Map<String, dynamic> payload) async {
    final data = await _apiClient.post(
      AppConfig.workOrdersEndpoint,
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return WorkOrderItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    final msg = data is Map ? (data['error']?['message'] ?? 'Failed to create work order.') : 'Error';
    throw Exception(msg);
  }

  /// Perform a lifecycle action on a work order (release, start, pause, resume, complete, cancel)
  Future<Map<String, dynamic>> executeWorkOrderAction(String workOrderId, String action, {Map<String, dynamic>? payload}) async {
    final data = await _apiClient.post(
      AppConfig.workOrderActionEndpoint(workOrderId, action),
      data: payload ?? {},
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Failed to perform work order action.');
  }

  /// Retrieve products belonging to a specific factory
  Future<List<ProductModel>> getFactoryProducts(String factoryId) async {
    final data = await _apiClient.get(AppConfig.factoryProductsEndpoint(factoryId));
    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ===========================================================================
  // 4. PRODUCTION EXECUTION
  // ===========================================================================

  /// List active process executions
  Future<List<ProcessExecutionItem>> getExecutions({String? factoryId, String? status}) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) query['factory_id'] = factoryId;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final data = await _apiClient.get(
      AppConfig.processExecutionsEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => ProcessExecutionItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Retrieve full live execution state with stage nodes and bottleneck
  Future<ProcessExecutionItem> getExecution(String executionId) async {
    final data = await _apiClient.get(AppConfig.processExecutionDetailEndpoint(executionId));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return ProcessExecutionItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load process execution.');
  }

  /// Advance an active stage to COMPLETED
  Future<Map<String, dynamic>> advanceStage(
    String stageId, {
    int? unitsCompleted,
    int unitsScrapped = 0,
    double? durationSeconds,
  }) async {
    final data = await _apiClient.post(
      AppConfig.stageAdvanceEndpoint(stageId),
      data: {
        'units_completed': ?unitsCompleted,
        'units_scrapped': unitsScrapped,
        'duration_seconds': ?durationSeconds,
      },
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Failed to advance stage execution.');
  }

  /// Perform an action on an execution (pause, resume, complete)
  Future<Map<String, dynamic>> executeExecutionAction(
    String executionId,
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    final data = await _apiClient.post(
      AppConfig.processExecutionActionEndpoint(executionId, action),
      data: payload ?? {},
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Failed to perform execution action.');
  }

  /// Fail a stage with error context
  Future<void> failStage(String stageId, String errorMessage) async {
    await _apiClient.post(
      AppConfig.stageFailEndpoint(stageId),
      data: {'error_message': errorMessage},
    );
  }

  // ===========================================================================
  // 5. MATERIAL FLOW & WIP
  // ===========================================================================

  /// Retrieve material audit movements
  Future<List<MaterialFlowItem>> getMaterialFlows({String? factoryId, String? executionId}) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) query['factory_id'] = factoryId;
    if (executionId != null && executionId.isNotEmpty) query['execution_id'] = executionId;

    final data = await _apiClient.get(
      AppConfig.materialFlowsEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => MaterialFlowItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Retrieve WIP quantities aggregated by active stages
  Future<List<Map<String, dynamic>>> getWipSummary({String? factoryId}) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) query['factory_id'] = factoryId;

    final data = await _apiClient.get(
      AppConfig.materialWipSummaryEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['wip_stages'] is List) {
      final list = data['wip_stages'] as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  // ===========================================================================
  // 6. SIMULATION CONSOLE
  // ===========================================================================

  /// List configured simulation scenarios for a factory
  Future<List<SimulationScenarioItem>> getSimulationScenarios({String? factoryId}) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) query['factory_id'] = factoryId;

    final data = await _apiClient.get(
      AppConfig.simulationScenariosEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => SimulationScenarioItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Inject an operational anomaly into an active execution
  Future<Map<String, dynamic>> injectAnomaly({
    required String executionId,
    required String scenarioType,
    Map<String, dynamic>? parameters,
  }) async {
    final data = await _apiClient.post(
      AppConfig.simulationInjectAnomalyEndpoint,
      data: {
        'execution_id': executionId,
        'scenario_type': scenarioType,
        'parameters': parameters ?? {},
      },
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Failed to inject anomaly.');
  }

  /// Step simulation deterministically
  Future<Map<String, dynamic>> stepSimulation({
    required String executionId,
    int randomSeed = 42,
  }) async {
    final data = await _apiClient.post(
      AppConfig.simulationStepEndpoint,
      data: {
        'execution_id': executionId,
        'random_seed': randomSeed,
      },
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Failed to advance simulation step.');
  }

  /// Run simulation to completion
  Future<Map<String, dynamic>> runFullSimulation({
    required String executionId,
    int randomSeed = 42,
    int maxSteps = 50,
  }) async {
    final data = await _apiClient.post(
      AppConfig.simulationRunFullEndpoint,
      data: {
        'execution_id': executionId,
        'random_seed': randomSeed,
        'max_steps': maxSteps,
      },
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Failed to run full simulation.');
  }

  // ===========================================================================
  // 7. PRODUCTION AUDIT EVENT LOG
  // ===========================================================================

  /// Retrieve real-time production audit events
  Future<List<ProductionEventItem>> getProductionEvents({
    String? factoryId,
    String? workOrderId,
    String? executionId,
    String? severity,
  }) async {
    final query = <String, dynamic>{};
    if (factoryId != null && factoryId.isNotEmpty) query['factory_id'] = factoryId;
    if (workOrderId != null && workOrderId.isNotEmpty) query['work_order_id'] = workOrderId;
    if (executionId != null && executionId.isNotEmpty) query['execution_id'] = executionId;
    if (severity != null && severity.isNotEmpty) query['severity'] = severity;

    final data = await _apiClient.get(
      AppConfig.productionEventsEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => ProductionEventItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
