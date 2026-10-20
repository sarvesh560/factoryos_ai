/// FactoryOS AI — Universal Manufacturing Process Engine (UMPE) Models
/// Phase 3: Graph Nodes, Edges, Work Orders, Execution & Simulation Models
library;

class ProcessEdgeItem {
  final String id;
  final String edgeKey;
  final String sourceNode;
  final String targetNode;
  final String sourceNodeKey;
  final String targetNodeKey;
  final String edgeType; // STANDARD, CONDITIONAL, DEFAULT, EXCEPTION
  final String conditionExpression;
  final String label;
  final int priority;

  const ProcessEdgeItem({
    required this.id,
    required this.edgeKey,
    required this.sourceNode,
    required this.targetNode,
    this.sourceNodeKey = '',
    this.targetNodeKey = '',
    this.edgeType = 'STANDARD',
    this.conditionExpression = '',
    this.label = '',
    this.priority = 0,
  });

  factory ProcessEdgeItem.fromJson(Map<String, dynamic> json) {
    return ProcessEdgeItem(
      id: json['id'] as String? ?? '',
      edgeKey: json['edge_key'] as String? ?? '',
      sourceNode: json['source_node'] as String? ?? '',
      targetNode: json['target_node'] as String? ?? '',
      sourceNodeKey: json['source_node_key'] as String? ?? '',
      targetNodeKey: json['target_node_key'] as String? ?? '',
      edgeType: json['edge_type'] as String? ?? 'STANDARD',
      conditionExpression: json['condition_expression'] as String? ?? '',
      label: json['label'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'edge_key': edgeKey,
    'source_node': sourceNode,
    'target_node': targetNode,
    'edge_type': edgeType,
    'condition_expression': conditionExpression,
    'label': label,
    'priority': priority,
  };
}

class ProcessTemplateItem {
  final String key;
  final String name;
  final String industryType;
  final String category;
  final String description;
  final double nominalCycleTimeSeconds;
  final double estimatedSetupTimeSeconds;
  final List<String> stages;
  final int nodeCount;
  final int edgeCount;

  const ProcessTemplateItem({
    required this.key,
    required this.name,
    required this.industryType,
    required this.category,
    required this.description,
    this.nominalCycleTimeSeconds = 60.0,
    this.estimatedSetupTimeSeconds = 0.0,
    this.stages = const [],
    this.nodeCount = 0,
    this.edgeCount = 0,
  });

  factory ProcessTemplateItem.fromJson(Map<String, dynamic> json) {
    final rawStages = (json['stages'] as List<dynamic>?) ?? [];
    return ProcessTemplateItem(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      industryType: json['industry_type'] as String? ?? 'CUSTOM',
      category: json['category'] as String? ?? 'General Manufacturing',
      description: json['description'] as String? ?? '',
      nominalCycleTimeSeconds: (json['nominal_cycle_time_seconds'] as num?)?.toDouble() ?? 60.0,
      estimatedSetupTimeSeconds: (json['estimated_setup_time_seconds'] as num?)?.toDouble() ?? 0.0,
      stages: rawStages.map((e) => e.toString()).toList(),
      nodeCount: json['node_count'] as int? ?? 0,
      edgeCount: json['edge_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'industry_type': industryType,
    'category': category,
    'description': description,
    'nominal_cycle_time_seconds': nominalCycleTimeSeconds,
    'estimated_setup_time_seconds': estimatedSetupTimeSeconds,
    'stages': stages,
    'node_count': nodeCount,
    'edge_count': edgeCount,
  };
}

class ProcessNodeItem {
  final String id;
  final String nodeKey;
  final String name;
  final String nodeType; // START, OPERATION, PARALLEL_SPLIT, PARALLEL_JOIN, CONDITION_BRANCH, QUALITY_GATE, END
  final double positionX;
  final double positionY;
  final double cycleTimeSeconds;
  final double setupTimeSeconds;
  final int standardCapacityPerHour;
  final String? assignedLine;
  final String? assignedLineName;
  final String? assignedMachine;
  final String? assignedMachineName;
  final int requiredOperators;
  final String operatorRole;
  final List<String> requiredSkills;
  final Map<String, dynamic> resourceSpec;
  final List<dynamic> inputMaterials;
  final List<dynamic> outputMaterials;
  final double yieldRatePercent;
  final Map<String, dynamic> configuration;

  const ProcessNodeItem({
    required this.id,
    required this.nodeKey,
    required this.name,
    this.nodeType = 'OPERATION',
    this.positionX = 100.0,
    this.positionY = 100.0,
    this.cycleTimeSeconds = 30.0,
    this.setupTimeSeconds = 0.0,
    this.standardCapacityPerHour = 60,
    this.assignedLine,
    this.assignedLineName,
    this.assignedMachine,
    this.assignedMachineName,
    this.requiredOperators = 1,
    this.operatorRole = '',
    this.requiredSkills = const [],
    this.resourceSpec = const {},
    this.inputMaterials = const [],
    this.outputMaterials = const [],
    this.yieldRatePercent = 100.0,
    this.configuration = const {},
  });

  factory ProcessNodeItem.fromJson(Map<String, dynamic> json) {
    final rawSkills = (json['required_skills'] as List<dynamic>?) ?? [];
    return ProcessNodeItem(
      id: json['id'] as String? ?? '',
      nodeKey: json['node_key'] as String? ?? '',
      name: json['name'] as String? ?? 'Operation',
      nodeType: json['node_type'] as String? ?? 'OPERATION',
      positionX: (json['position_x'] as num?)?.toDouble() ?? 100.0,
      positionY: (json['position_y'] as num?)?.toDouble() ?? 100.0,
      cycleTimeSeconds: (json['cycle_time_seconds'] as num?)?.toDouble() ?? 30.0,
      setupTimeSeconds: (json['setup_time_seconds'] as num?)?.toDouble() ?? 0.0,
      standardCapacityPerHour: json['standard_capacity_per_hour'] as int? ?? 60,
      assignedLine: json['assigned_line'] as String?,
      assignedLineName: json['assigned_line_name'] as String?,
      assignedMachine: json['assigned_machine'] as String?,
      assignedMachineName: json['assigned_machine_name'] as String?,
      requiredOperators: json['required_operators'] as int? ?? 1,
      operatorRole: json['operator_role'] as String? ?? '',
      requiredSkills: rawSkills.map((e) => e.toString()).toList(),
      resourceSpec: (json['resource_spec'] as Map<String, dynamic>?) ?? {},
      inputMaterials: (json['input_materials'] as List<dynamic>?) ?? [],
      outputMaterials: (json['output_materials'] as List<dynamic>?) ?? [],
      yieldRatePercent: (json['yield_rate_percent'] as num?)?.toDouble() ?? 100.0,
      configuration: (json['configuration'] as Map<String, dynamic>?) ?? {},
    );
  }

  ProcessNodeItem copyWith({
    String? id,
    String? nodeKey,
    String? name,
    String? nodeType,
    double? positionX,
    double? positionY,
    double? cycleTimeSeconds,
    double? setupTimeSeconds,
    int? standardCapacityPerHour,
    String? assignedLine,
    String? assignedLineName,
    String? assignedMachine,
    String? assignedMachineName,
    int? requiredOperators,
    String? operatorRole,
    List<String>? requiredSkills,
    Map<String, dynamic>? resourceSpec,
    List<dynamic>? inputMaterials,
    List<dynamic>? outputMaterials,
    double? yieldRatePercent,
    Map<String, dynamic>? configuration,
  }) {
    return ProcessNodeItem(
      id: id ?? this.id,
      nodeKey: nodeKey ?? this.nodeKey,
      name: name ?? this.name,
      nodeType: nodeType ?? this.nodeType,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      cycleTimeSeconds: cycleTimeSeconds ?? this.cycleTimeSeconds,
      setupTimeSeconds: setupTimeSeconds ?? this.setupTimeSeconds,
      standardCapacityPerHour: standardCapacityPerHour ?? this.standardCapacityPerHour,
      assignedLine: assignedLine ?? this.assignedLine,
      assignedLineName: assignedLineName ?? this.assignedLineName,
      assignedMachine: assignedMachine ?? this.assignedMachine,
      assignedMachineName: assignedMachineName ?? this.assignedMachineName,
      requiredOperators: requiredOperators ?? this.requiredOperators,
      operatorRole: operatorRole ?? this.operatorRole,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      resourceSpec: resourceSpec ?? this.resourceSpec,
      inputMaterials: inputMaterials ?? this.inputMaterials,
      outputMaterials: outputMaterials ?? this.outputMaterials,
      yieldRatePercent: yieldRatePercent ?? this.yieldRatePercent,
      configuration: configuration ?? this.configuration,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'node_key': nodeKey,
    'name': name,
    'node_type': nodeType,
    'position_x': positionX,
    'position_y': positionY,
    'cycle_time_seconds': cycleTimeSeconds,
    'setup_time_seconds': setupTimeSeconds,
    'standard_capacity_per_hour': standardCapacityPerHour,
    'assigned_line': assignedLine,
    'assigned_machine': assignedMachine,
    'required_operators': requiredOperators,
    'operator_role': operatorRole,
    'required_skills': requiredSkills,
    'resource_spec': resourceSpec,
    'input_materials': inputMaterials,
    'output_materials': outputMaterials,
    'yield_rate_percent': yieldRatePercent,
    'configuration': configuration,
  };
}

class ProcessVersionItem {
  final String id;
  final String processDefinition;
  final int versionNumber;
  final String versionTag;
  final String status; // DRAFT, VALIDATED, PUBLISHED, ARCHIVED
  final String changeSummary;
  final bool isPublished;
  final List<String> validationErrors;
  final Map<String, dynamic> graphMetadata;
  final int nodeCount;
  final int edgeCount;
  final List<ProcessNodeItem> nodes;
  final List<ProcessEdgeItem> edges;
  final String? publishedAt;
  final String createdAt;

  const ProcessVersionItem({
    required this.id,
    required this.processDefinition,
    required this.versionNumber,
    required this.versionTag,
    required this.status,
    this.changeSummary = '',
    this.isPublished = false,
    this.validationErrors = const [],
    this.graphMetadata = const {},
    this.nodeCount = 0,
    this.edgeCount = 0,
    this.nodes = const [],
    this.edges = const [],
    this.publishedAt,
    this.createdAt = '',
  });

  factory ProcessVersionItem.fromJson(Map<String, dynamic> json) {
    final rawNodes = (json['nodes'] as List<dynamic>?) ?? [];
    final rawEdges = (json['edges'] as List<dynamic>?) ?? [];
    final rawErrors = (json['validation_errors'] as List<dynamic>?) ?? [];

    return ProcessVersionItem(
      id: json['id'] as String? ?? '',
      processDefinition: json['process_definition'] as String? ?? '',
      versionNumber: json['version_number'] as int? ?? 1,
      versionTag: json['version_tag'] as String? ?? 'v1.0.0',
      status: json['status'] as String? ?? 'DRAFT',
      changeSummary: json['change_summary'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? false,
      validationErrors: rawErrors.map((e) => e.toString()).toList(),
      graphMetadata: (json['graph_metadata'] as Map<String, dynamic>?) ?? {},
      nodeCount: json['node_count'] as int? ?? rawNodes.length,
      edgeCount: json['edge_count'] as int? ?? rawEdges.length,
      nodes: rawNodes.map((n) => ProcessNodeItem.fromJson(n as Map<String, dynamic>)).toList(),
      edges: rawEdges.map((e) => ProcessEdgeItem.fromJson(e as Map<String, dynamic>)).toList(),
      publishedAt: json['published_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ProcessDefinitionItem {
  final String id;
  final String factory;
  final String factoryName;
  final String name;
  final String code;
  final String description;
  final String category;
  final String industryType;
  final double targetCycleTimeSeconds;
  final bool isActive;
  final String? publishedVersionTag;
  final int? latestVersionNumber;
  final String? publishedVersionId;
  final String? latestVersionId;
  final int versionCount;
  final List<ProcessVersionItem> versions;
  final String createdAt;

  const ProcessDefinitionItem({
    required this.id,
    required this.factory,
    required this.factoryName,
    required this.name,
    required this.code,
    this.description = '',
    this.category = 'General Manufacturing',
    this.industryType = 'CUSTOM',
    this.targetCycleTimeSeconds = 60.0,
    this.isActive = true,
    this.publishedVersionTag,
    this.latestVersionNumber,
    this.publishedVersionId,
    this.latestVersionId,
    this.versionCount = 1,
    this.versions = const [],
    this.createdAt = '',
  });

  factory ProcessDefinitionItem.fromJson(Map<String, dynamic> json) {
    final rawVersions = (json['versions'] as List<dynamic>?) ?? [];
    return ProcessDefinitionItem(
      id: json['id'] as String? ?? '',
      factory: json['factory'] as String? ?? '',
      factoryName: json['factory_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General Manufacturing',
      industryType: json['industry_type'] as String? ?? 'CUSTOM',
      targetCycleTimeSeconds: (json['target_cycle_time_seconds'] as num?)?.toDouble() ?? 60.0,
      isActive: json['is_active'] as bool? ?? true,
      publishedVersionTag: json['published_version_tag'] as String?,
      latestVersionNumber: json['latest_version_number'] as int?,
      publishedVersionId: json['published_version_id'] as String?,
      latestVersionId: json['latest_version_id'] as String?,
      versionCount: json['version_count'] as int? ?? rawVersions.length,
      versions: rawVersions.map((v) => ProcessVersionItem.fromJson(v as Map<String, dynamic>)).toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class WorkOrderItem {
  final String id;
  final String factory;
  final String factoryName;
  final String orderNumber;
  final String product;
  final String productName;
  final String productSku;
  final String processDefinition;
  final String processName;
  final String processVersion;
  final String processVersionTag;
  final String? assignedLine;
  final String? assignedLineName;
  final int quantityTarget;
  final int quantityCompleted;
  final int quantityScrapped;
  final String status; // DRAFT, RELEASED, IN_PROGRESS, PAUSED, COMPLETED, CANCELLED
  final String priority; // LOW, NORMAL, HIGH, URGENT
  final double progressPercent;
  final String? plannedStartDate;
  final String? plannedDueDate;
  final String? actualStartDate;
  final String? actualEndDate;
  final String notes;
  final String createdAt;

  const WorkOrderItem({
    required this.id,
    required this.factory,
    required this.factoryName,
    required this.orderNumber,
    required this.product,
    required this.productName,
    required this.productSku,
    required this.processDefinition,
    required this.processName,
    required this.processVersion,
    required this.processVersionTag,
    this.assignedLine,
    this.assignedLineName,
    required this.quantityTarget,
    this.quantityCompleted = 0,
    this.quantityScrapped = 0,
    this.status = 'DRAFT',
    this.priority = 'NORMAL',
    this.progressPercent = 0.0,
    this.plannedStartDate,
    this.plannedDueDate,
    this.actualStartDate,
    this.actualEndDate,
    this.notes = '',
    this.createdAt = '',
  });

  factory WorkOrderItem.fromJson(Map<String, dynamic> json) {
    return WorkOrderItem(
      id: json['id'] as String? ?? '',
      factory: json['factory'] as String? ?? '',
      factoryName: json['factory_name'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      product: json['product'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      productSku: json['product_sku'] as String? ?? '',
      processDefinition: json['process_definition'] as String? ?? '',
      processName: json['process_name'] as String? ?? '',
      processVersion: json['process_version'] as String? ?? '',
      processVersionTag: json['process_version_tag'] as String? ?? '',
      assignedLine: json['assigned_line'] as String?,
      assignedLineName: json['assigned_line_name'] as String?,
      quantityTarget: json['quantity_target'] as int? ?? 100,
      quantityCompleted: json['quantity_completed'] as int? ?? 0,
      quantityScrapped: json['quantity_scrapped'] as int? ?? 0,
      status: json['status'] as String? ?? 'DRAFT',
      priority: json['priority'] as String? ?? 'NORMAL',
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      plannedStartDate: json['planned_start_date'] as String?,
      plannedDueDate: json['planned_due_date'] as String?,
      actualStartDate: json['actual_start_date'] as String?,
      actualEndDate: json['actual_end_date'] as String?,
      notes: json['notes'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class StageExecutionItem {
  final String id;
  final String node;
  final String nodeKey;
  final String nodeName;
  final String nodeType;
  final double cycleTimeSeconds;
  final double setupTimeSeconds;
  final int standardCapacityPerHour;
  final int requiredOperators;
  final String operatorRole;
  final List<String> requiredSkills;
  final double yieldRatePercent;
  final String status; // PENDING, READY, RUNNING, COMPLETED, BLOCKED, FAILED, SKIPPED
  final String? assignedMachine;
  final String? assignedMachineName;
  final int unitsQueued;
  final int unitsInProgress;
  final int unitsCompleted;
  final int unitsScrapped;
  final String? startedAt;
  final String? completedAt;
  final double durationSeconds;
  final int retryCount;
  final String errorMessage;

  const StageExecutionItem({
    required this.id,
    required this.node,
    required this.nodeKey,
    required this.nodeName,
    this.nodeType = 'OPERATION',
    this.cycleTimeSeconds = 0.0,
    this.setupTimeSeconds = 0.0,
    this.standardCapacityPerHour = 0,
    this.requiredOperators = 0,
    this.operatorRole = '',
    this.requiredSkills = const [],
    this.yieldRatePercent = 100.0,
    required this.status,
    this.assignedMachine,
    this.assignedMachineName,
    this.unitsQueued = 0,
    this.unitsInProgress = 0,
    this.unitsCompleted = 0,
    this.unitsScrapped = 0,
    this.startedAt,
    this.completedAt,
    this.durationSeconds = 0.0,
    this.retryCount = 0,
    this.errorMessage = '',
  });

  factory StageExecutionItem.fromJson(Map<String, dynamic> json) {
    return StageExecutionItem(
      id: json['id'] as String? ?? '',
      node: json['node'] as String? ?? '',
      nodeKey: json['node_key'] as String? ?? '',
      nodeName: json['node_name'] as String? ?? '',
      nodeType: json['node_type'] as String? ?? 'OPERATION',
      cycleTimeSeconds: (json['cycle_time_seconds'] as num?)?.toDouble() ?? 0.0,
      setupTimeSeconds: (json['setup_time_seconds'] as num?)?.toDouble() ?? 0.0,
      standardCapacityPerHour: json['standard_capacity_per_hour'] as int? ?? 0,
      requiredOperators: json['required_operators'] as int? ?? 0,
      operatorRole: json['operator_role'] as String? ?? '',
      requiredSkills: (json['required_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      yieldRatePercent: (json['yield_rate_percent'] as num?)?.toDouble() ?? 100.0,
      status: json['status'] as String? ?? 'PENDING',
      assignedMachine: json['assigned_machine'] as String?,
      assignedMachineName: json['assigned_machine_name'] as String?,
      unitsQueued: json['units_queued'] as int? ?? 0,
      unitsInProgress: json['units_in_progress'] as int? ?? 0,
      unitsCompleted: json['units_completed'] as int? ?? 0,
      unitsScrapped: json['units_scrapped'] as int? ?? 0,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      retryCount: json['retry_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String? ?? '',
    );
  }
}

class ProcessExecutionItem {
  final String id;
  final String workOrder;
  final String orderNumber;
  final String productName;
  final int quantityTarget;
  final String processVersion;
  final String executionNumber;
  final String mode; // SIMULATION, PRODUCTION
  final String status; // INITIALIZED, RUNNING, BLOCKED, PAUSED, COMPLETED, FAILED
  final String? startedAt;
  final String? completedAt;
  final double currentProgressPercent;
  final int totalUnitsInput;
  final int totalUnitsOutput;
  final int totalUnitsScrap;
  final String? bottleneckNode;
  final String? bottleneckNodeName;
  final List<StageExecutionItem> stageExecutions;

  const ProcessExecutionItem({
    required this.id,
    required this.workOrder,
    required this.orderNumber,
    required this.productName,
    required this.quantityTarget,
    required this.processVersion,
    required this.executionNumber,
    this.mode = 'SIMULATION',
    required this.status,
    this.startedAt,
    this.completedAt,
    this.currentProgressPercent = 0.0,
    this.totalUnitsInput = 0,
    this.totalUnitsOutput = 0,
    this.totalUnitsScrap = 0,
    this.bottleneckNode,
    this.bottleneckNodeName,
    this.stageExecutions = const [],
  });

  factory ProcessExecutionItem.fromJson(Map<String, dynamic> json) {
    final rawStages = (json['stage_executions'] as List<dynamic>?) ?? [];
    return ProcessExecutionItem(
      id: json['id'] as String? ?? '',
      workOrder: json['work_order'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      quantityTarget: json['quantity_target'] as int? ?? 0,
      processVersion: json['process_version'] as String? ?? '',
      executionNumber: json['execution_number'] as String? ?? '',
      mode: json['mode'] as String? ?? 'SIMULATION',
      status: json['status'] as String? ?? 'INITIALIZED',
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      currentProgressPercent: (json['current_progress_percent'] as num?)?.toDouble() ?? 0.0,
      totalUnitsInput: json['total_units_input'] as int? ?? 0,
      totalUnitsOutput: json['total_units_output'] as int? ?? 0,
      totalUnitsScrap: json['total_units_scrap'] as int? ?? 0,
      bottleneckNode: json['bottleneck_node'] as String?,
      bottleneckNodeName: json['bottleneck_node_name'] as String?,
      stageExecutions: rawStages.map((s) => StageExecutionItem.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class MaterialFlowItem {
  final String id;
  final String processExecution;
  final String stageExecution;
  final String stageName;
  final String? rawMaterial;
  final String? rawMaterialName;
  final String flowType; // INPUT_CONSUMPTION, WIP_TRANSFER, FINISHED_GOODS, SCRAP_REJECT
  final double quantity;
  final String unitOfMeasure;
  final double previousStockLevel;
  final double newStockLevel;
  final String timestamp;
  final String notes;

  const MaterialFlowItem({
    required this.id,
    required this.processExecution,
    required this.stageExecution,
    this.stageName = '',
    this.rawMaterial,
    this.rawMaterialName,
    required this.flowType,
    required this.quantity,
    this.unitOfMeasure = 'pcs',
    this.previousStockLevel = 0.0,
    this.newStockLevel = 0.0,
    required this.timestamp,
    this.notes = '',
  });

  factory MaterialFlowItem.fromJson(Map<String, dynamic> json) {
    return MaterialFlowItem(
      id: json['id'] as String? ?? '',
      processExecution: json['process_execution'] as String? ?? '',
      stageExecution: json['stage_execution'] as String? ?? '',
      stageName: json['stage_name'] as String? ?? '',
      rawMaterial: json['raw_material'] as String?,
      rawMaterialName: json['raw_material_name'] as String?,
      flowType: json['flow_type'] as String? ?? 'INPUT_CONSUMPTION',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'pcs',
      previousStockLevel: (json['previous_stock_level'] as num?)?.toDouble() ?? 0.0,
      newStockLevel: (json['new_stock_level'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class ProductionEventItem {
  final String id;
  final String factory;
  final String? workOrder;
  final String? workOrderNumber;
  final String? processExecution;
  final String? stageExecution;
  final String? stageName;
  final String eventType;
  final String severity; // INFO, WARNING, ERROR, CRITICAL
  final String source; // SIMULATION, OPERATOR, SYSTEM_ENGINE
  final Map<String, dynamic> payload;
  final String message;
  final String timestamp;

  const ProductionEventItem({
    required this.id,
    required this.factory,
    this.workOrder,
    this.workOrderNumber,
    this.processExecution,
    this.stageExecution,
    this.stageName,
    required this.eventType,
    this.severity = 'INFO',
    this.source = 'SIMULATION',
    this.payload = const {},
    required this.message,
    required this.timestamp,
  });

  factory ProductionEventItem.fromJson(Map<String, dynamic> json) {
    return ProductionEventItem(
      id: json['id'] as String? ?? '',
      factory: json['factory'] as String? ?? '',
      workOrder: json['work_order'] as String?,
      workOrderNumber: json['work_order_number'] as String?,
      processExecution: json['process_execution'] as String?,
      stageExecution: json['stage_execution'] as String?,
      stageName: json['stage_name'] as String?,
      eventType: json['event_type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      source: json['source'] as String? ?? 'SIMULATION',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class SimulationScenarioItem {
  final String id;
  final String factory;
  final String factoryName;
  final String name;
  final String description;
  final String scenarioType; // MACHINE_BREAKDOWN, MATERIAL_SHORTAGE, PRODUCTION_DELAY, QUALITY_REJECTION, etc.
  final Map<String, dynamic> parameters;
  final int randomSeed;
  final bool isActive;

  const SimulationScenarioItem({
    required this.id,
    required this.factory,
    required this.factoryName,
    required this.name,
    this.description = '',
    required this.scenarioType,
    this.parameters = const {},
    this.randomSeed = 42,
    this.isActive = true,
  });

  factory SimulationScenarioItem.fromJson(Map<String, dynamic> json) {
    return SimulationScenarioItem(
      id: json['id'] as String? ?? '',
      factory: json['factory'] as String? ?? '',
      factoryName: json['factory_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scenarioType: json['scenario_type'] as String? ?? 'MACHINE_BREAKDOWN',
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
      randomSeed: json['random_seed'] as int? ?? 42,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class GraphValidationResult {
  final bool isValid;
  final String status;
  final List<String> errors;
  final List<String> warnings;
  final List<String> invalidNodeKeys;

  const GraphValidationResult({
    required this.isValid,
    this.status = 'DRAFT',
    this.errors = const [],
    this.warnings = const [],
    this.invalidNodeKeys = const [],
  });

  factory GraphValidationResult.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] as List<dynamic>?) ??
        (json['validation_errors'] as List<dynamic>?) ??
        (json['error'] is Map ? (json['error']['errors'] as List<dynamic>? ?? json['error']['validation_errors'] as List<dynamic>?) : null) ??
        [];
    final rawWarnings = (json['warnings'] as List<dynamic>?) ??
        (json['error'] is Map ? (json['error']['warnings'] as List<dynamic>?) : null) ??
        [];
    final rawInvalid = (json['invalid_node_keys'] as List<dynamic>?) ??
        (json['error'] is Map ? (json['error']['invalid_node_keys'] as List<dynamic>?) : null) ??
        [];

    final parsedInvalid = Set<String>.from(rawInvalid.map((e) => e.toString()));
    for (final err in rawErrors) {
      final matches = RegExp(r"'([A-Za-z0-9_-]+)'").allMatches(err.toString());
      for (final m in matches) {
        final key = m.group(1);
        if (key != null && key.isNotEmpty && !key.contains(' ')) {
          parsedInvalid.add(key);
        }
      }
    }

    final bool validVal = json['is_valid'] as bool? ?? (rawErrors.isEmpty && json['success'] == true);

    return GraphValidationResult(
      isValid: validVal,
      status: json['status'] as String? ?? (validVal ? 'VALIDATED' : 'DRAFT'),
      errors: rawErrors.map((e) => e.toString()).toList(),
      warnings: rawWarnings.map((w) => w.toString()).toList(),
      invalidNodeKeys: parsedInvalid.toList(),
    );
  }
}
