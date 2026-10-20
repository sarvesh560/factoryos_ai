import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:factoryos_frontend/core/api/api_client.dart';
import 'package:factoryos_frontend/features/processes/data/models/process_models.dart';
import 'package:factoryos_frontend/features/processes/data/repositories/process_repository.dart';
import 'package:factoryos_frontend/features/processes/presentation/screens/process_library_screen.dart';
import 'package:factoryos_frontend/features/processes/presentation/screens/visual_process_builder_screen.dart';
import 'package:factoryos_frontend/features/processes/presentation/screens/work_order_management_screen.dart';
import 'package:factoryos_frontend/features/processes/presentation/screens/simulation_console_screen.dart';
import 'package:factoryos_frontend/features/processes/presentation/screens/material_flow_screen.dart';
import 'package:factoryos_frontend/features/processes/presentation/screens/live_execution_screen.dart';
import 'package:factoryos_frontend/features/factories/data/models/factory_model.dart';
import 'package:factoryos_frontend/features/factories/data/repositories/factory_repository.dart';
import 'package:factoryos_frontend/features/factories/presentation/controllers/factory_controller.dart';

class MockFactoryRepository extends FactoryRepository {
  @override
  Future<Map<String, dynamic>> checkHealth() async => {'status': 'healthy'};

  @override
  Future<FactoryOverviewData> getFactoryOverview(String factoryId) async {
    return FactoryOverviewData.fromJson({
      'factory': {
        'id': 'test-factory-1',
        'name': 'Apex Precision Textiles',
        'code': 'FAC-TEX-01',
        'industry_type': 'TEXTILE',
        'industry_type_display': 'Textile Manufacturing',
        'configuration_status': 'CONFIGURED',
        'configuration_status_display': 'Configured',
        'location': 'Greensboro, NC',
        'country': 'USA',
        'timezone': 'America/New_York',
        'total_production_lines': 6,
        'active_lines': 5,
        'is_active': true,
      },
      'metrics': {'oee': 85.0},
      'lines_summary': {'total': 6, 'running': 5, 'idle': 1, 'offline': 0},
      'production_lines': [
        {
          'id': 'line-1',
          'name': 'Precision CNC Milling Line 1',
          'code': 'LINE-CNC-01',
          'department': 'Machining Department',
          'status': 'RUNNING',
          'status_display': 'Running',
          'current_product': 'Titanium Impeller',
          'efficiency_rate': 94.5,
          'target_hourly_units': 120,
          'actual_hourly_units': 114,
          'operator_count': 3,
          'machines': [
            {
              'id': 'mach-1',
              'name': 'Haas 5-Axis VF2',
              'code': 'MC-CNC-01',
              'machine_type': 'CNC Milling Center',
              'status': 'RUNNING',
            },
            {
              'id': 'mach-2',
              'name': 'DMG MORI MillTap 700',
              'code': 'MC-CNC-02',
              'machine_type': 'High-Speed CNC Tap',
              'status': 'RUNNING',
            },
          ],
        },
        {
          'id': 'line-2',
          'name': 'Surface Finishing Line 2',
          'code': 'LINE-FIN-02',
          'department': 'Surface Treatment',
          'status': 'IDLE',
          'status_display': 'Idle',
          'current_product': 'None',
          'efficiency_rate': 88.0,
          'target_hourly_units': 80,
          'actual_hourly_units': 0,
          'operator_count': 1,
          'machines': [
            {
              'id': 'mach-3',
              'name': 'Ultrasonic Degreaser 3000',
              'code': 'MC-CLN-01',
              'machine_type': 'Ultrasonic Cleaning Bath',
              'status': 'IDLE',
            },
          ],
        },
      ],
      'alerts_summary': {'critical': 0, 'warning': 0, 'info': 0, 'total_active': 0},
      'shift_progress': {
        'planned_units': 1000,
        'actual_units': 800,
        'scrap_units': 5,
        'completion_percentage': 80.0,
        'current_shift': 'Day Shift',
      },
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
        name: 'Apex Precision Textiles',
        code: 'FAC-TEX-01',
        industryType: 'TEXTILE',
        industryTypeDisplay: 'Textile Manufacturing',
        configurationStatus: 'CONFIGURED',
        configurationStatusDisplay: 'Configured',
        location: 'Greensboro, NC',
        country: 'USA',
        timezone: 'America/New_York',
        totalProductionLines: 6,
        activeLines: 5,
        isActive: true,
      ),
    ];
  }
}

class MockProcessRepository extends ProcessRepository {
  MockProcessRepository() : super(ApiClient());

  bool mockValidationShouldPass = false;
  bool shouldFailDefinitions = false;
  bool shouldFailInstantiation = false;
  bool shouldFailDuplication = false;
  bool shouldFailArchiveConflict = false;
  bool shouldFailUpdateNode = false;
  bool shouldFailWorkOrders = false;
  bool shouldFailCreateWorkOrder = false;
  String? createWorkOrderErrorMessage;

  String? lastInstantiatedTemplateKey;
  Map<String, dynamic>? lastInstantiatedPayload;
  String? lastDuplicatedProcessId;
  Map<String, dynamic>? lastDuplicatedPayload;
  String? lastArchivedProcessId;
  String? lastUpdatedNodeId;
  Map<String, dynamic>? lastUpdatedPayload;
  Map<String, dynamic>? lastCreatedWorkOrderPayload;
  String? lastExecutedAction;
  String? lastExecutedWorkOrderId;
  Completer<Map<String, dynamic>>? actionCompleter;

  List<ProcessDefinitionItem> definitions = [
    const ProcessDefinitionItem(
      id: 'proc-def-1',
      factory: 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      name: 'Automated Textile Yarn Spinning',
      code: 'PROC-TEX-SPIN',
      description: 'Complete high-speed ring spinning and wound bobbin packaging line.',
      category: 'Textile & Apparel',
      industryType: 'TEXTILE',
      targetCycleTimeSeconds: 45.0,
      isActive: true,
      versionCount: 2,
      publishedVersionTag: 'v1.0-PROD',
      latestVersionId: 'ver-published',
      publishedVersionId: 'ver-published',
      versions: [
        ProcessVersionItem(
          id: 'ver-published',
          processDefinition: 'proc-def-1',
          versionNumber: 1,
          versionTag: 'v1.0-PROD',
          status: 'PUBLISHED',
          isPublished: true,
          nodeCount: 5,
          edgeCount: 4,
        ),
        ProcessVersionItem(
          id: 'ver-draft',
          processDefinition: 'proc-def-1',
          versionNumber: 2,
          versionTag: 'v2.0-DRAFT',
          status: 'DRAFT',
          isPublished: false,
          nodeCount: 3,
          edgeCount: 1,
        ),
      ],
    ),
    const ProcessDefinitionItem(
      id: 'proc-def-2',
      factory: 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      name: 'EV Battery Pack Assembly',
      code: 'PROC-EV-BATT',
      description: 'High-voltage electric vehicle battery module integration line.',
      category: 'Automotive & EV',
      industryType: 'AUTOMOTIVE',
      targetCycleTimeSeconds: 65.0,
      isActive: true,
      versionCount: 1,
      publishedVersionTag: null,
      latestVersionId: 'ver-draft-2',
      publishedVersionId: null,
      versions: [
        ProcessVersionItem(
          id: 'ver-draft-2',
          processDefinition: 'proc-def-2',
          versionNumber: 1,
          versionTag: 'v1.0-DRAFT',
          status: 'DRAFT',
          isPublished: false,
          nodeCount: 3,
          edgeCount: 2,
        ),
      ],
    ),
    const ProcessDefinitionItem(
      id: 'proc-def-3',
      factory: 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      name: 'Legacy SMT Assembly',
      code: 'PROC-SMT-LEGACY',
      description: 'Deprecated surface mount line preserved for historical batches.',
      category: 'Electronics & SMT',
      industryType: 'ELECTRONICS',
      targetCycleTimeSeconds: 30.0,
      isActive: false,
      versionCount: 1,
      publishedVersionTag: null,
      latestVersionId: 'ver-archived',
      publishedVersionId: null,
      versions: [
        ProcessVersionItem(
          id: 'ver-archived',
          processDefinition: 'proc-def-3',
          versionNumber: 1,
          versionTag: 'v1.0-ARCHIVED',
          status: 'ARCHIVED',
          isPublished: false,
          nodeCount: 2,
          edgeCount: 1,
        ),
      ],
    ),
    const ProcessDefinitionItem(
      id: 'proc-conflict',
      factory: 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      name: 'Critical Active Sterile Line',
      code: 'PROC-PHARM-ACT',
      description: 'Active sterile cleanroom processing line with active production orders.',
      category: 'Pharmaceutical & Cleanroom',
      industryType: 'PHARMACEUTICALS',
      targetCycleTimeSeconds: 120.0,
      isActive: true,
      versionCount: 1,
      publishedVersionTag: 'v1.0-PROD',
      latestVersionId: 'ver-pharm',
      publishedVersionId: 'ver-pharm',
      versions: [
        ProcessVersionItem(
          id: 'ver-pharm',
          processDefinition: 'proc-conflict',
          versionNumber: 1,
          versionTag: 'v1.0-PROD',
          status: 'PUBLISHED',
          isPublished: true,
          nodeCount: 2,
          edgeCount: 1,
        ),
      ],
    ),
  ];

  ProcessVersionItem draftVersion = ProcessVersionItem(
    id: 'ver-draft',
    processDefinition: 'proc-def-1',
    versionNumber: 2,
    versionTag: 'v2.0-DRAFT',
    status: 'DRAFT',
    isPublished: false,
    nodeCount: 3,
    edgeCount: 1,
    nodes: [
      const ProcessNodeItem(
        id: 'n-1',
        nodeKey: 'START-01',
        name: 'Process Start',
        nodeType: 'START',
        positionX: 50,
        positionY: 100,
      ),
      const ProcessNodeItem(
        id: 'n-2',
        nodeKey: 'OP-01',
        name: 'Carding Operation',
        nodeType: 'OPERATION',
        positionX: 250,
        positionY: 100,
        cycleTimeSeconds: 45.0,
        setupTimeSeconds: 30.0,
        standardCapacityPerHour: 100,
        requiredOperators: 2,
        operatorRole: 'Spinning Technician',
        requiredSkills: ['Sliver Splicing', 'Tension Calibration'],
        yieldRatePercent: 99.5,
      ),
      const ProcessNodeItem(
        id: 'n-8',
        nodeKey: 'NODE-08',
        name: 'Inspection / Assembly Cell',
        nodeType: 'OPERATION',
        positionX: 450,
        positionY: 100,
      ),
    ],
    edges: const [
      ProcessEdgeItem(
        id: 'e-1',
        edgeKey: 'E-01',
        sourceNode: 'n-1',
        targetNode: 'n-2',
        sourceNodeKey: 'START-01',
        targetNodeKey: 'OP-01',
      ),
    ],
  );

  @override
  Future<List<ProcessDefinitionItem>> getProcessDefinitions({String? factoryId, String? category}) async {
    if (shouldFailDefinitions) {
      throw Exception('Failed to load process definitions from API.');
    }
    return List.from(definitions);
  }

  @override
  Future<List<ProcessTemplateItem>> getTemplates({String? industryType, String? category}) async {
    return const [
      ProcessTemplateItem(
        key: 'cnc_precision_machining',
        name: 'CNC Precision Machining',
        industryType: 'CNC_ENGINEERING',
        category: 'Precision Machining',
        description: 'Multi-axis CNC milling and turning workflow with roughing and finishing.',
        nominalCycleTimeSeconds: 90.0,
        estimatedSetupTimeSeconds: 300.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Stock Material Ingest & Clamping',
          'Rough 3-Axis Milling',
          'Precision 5-Axis Profiling',
          'Coolant Wash & Deburring',
          'Coordinate Measuring Machine (CMM)',
          'Final Part Preservation & Serialization',
        ],
      ),
      ProcessTemplateItem(
        key: 'automotive_ev_battery',
        name: 'Automotive / EV Battery Module Assembly',
        industryType: 'AUTOMOTIVE',
        category: 'Automotive & Clean Energy',
        description: 'Prismatic lithium-ion cell staging, laser welding, and high-voltage testing.',
        nominalCycleTimeSeconds: 65.0,
        estimatedSetupTimeSeconds: 600.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Cell Incoming Inspection & Voltage Grading',
          'Module Laser Welding',
          'Busbar Installation',
          'Thermal Interface Material Dispensing',
          'EOL Electrical & High-Voltage Testing',
          'Enclosure Seal & Final Pack Output',
        ],
      ),
      ProcessTemplateItem(
        key: 'electronics_smt_pcba',
        name: 'Electronics SMT / PCBA',
        industryType: 'ELECTRONICS',
        category: 'Electronics Manufacturing',
        description: 'High-speed surface mount technology and automated optical inspection line.',
        nominalCycleTimeSeconds: 35.0,
        estimatedSetupTimeSeconds: 180.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Bare Board Loading & Solder Paste Printing',
          'Solder Paste Inspection (SPI)',
          'High-Speed SMT Pick & Place',
          'Multi-Zone Convection Reflow Oven',
          'Automated Optical Inspection (AOI)',
          'In-Circuit Test & Depaneling',
        ],
      ),
      ProcessTemplateItem(
        key: 'pharma_sterile_vial',
        name: 'Pharmaceuticals / Sterile Production',
        industryType: 'PHARMACEUTICALS',
        category: 'Pharmaceutical & Cleanroom',
        description: 'Aseptic vial washing, depyrogenation tunnel, cleanroom filling, and inspection.',
        nominalCycleTimeSeconds: 120.0,
        estimatedSetupTimeSeconds: 900.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Vial Ultrasonic Washing & Sterilization',
          'Depyrogenation Tunnel',
          'Aseptic Cleanroom Filling & Stoppering',
          'Freeze-Drying (Lyophilization)',
          'Aluminum Crimp Capping',
          'Automated Particle Inspection',
        ],
      ),
      ProcessTemplateItem(
        key: 'food_beverage_packaging',
        name: 'Food & Beverage Packaging',
        industryType: 'FOOD_PROCESSING',
        category: 'Food & Consumer Goods',
        description: 'High-throughput sanitary filling, nitrogen purge, induction sealing, and cartoning.',
        nominalCycleTimeSeconds: 15.0,
        estimatedSetupTimeSeconds: 240.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Bottle Air Rinse & Infeed',
          'Rotary Volumetric Liquid Filling',
          'Nitrogen Flush & Capping',
          'Induction Foil Heat Sealing',
          'High-Speed Labeling & Inkjet Coding',
          'Automated Case Packing & Palletizing',
        ],
      ),
      ProcessTemplateItem(
        key: 'textile_yarn_spinning',
        name: 'Textile Yarn / Weaving',
        industryType: 'TEXTILE',
        category: 'Textile & Apparel',
        description: 'Bale opening, high-speed carding, draw frame roving, and ring spinning.',
        nominalCycleTimeSeconds: 45.0,
        estimatedSetupTimeSeconds: 360.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Raw Bale Opening & Blending',
          'High-Speed Carding & Web Formation',
          'Breaker & Finisher Draw Frames',
          'Roving Frame Package Formation',
          'Ring Spinning Frame',
          'Automatic Cone Winding & Yarn Clearing',
        ],
      ),
      ProcessTemplateItem(
        key: 'chemical_batch_processing',
        name: 'Chemical Batch Processing',
        industryType: 'CHEMICALS',
        category: 'Chemical Processing',
        description: 'Jacketed reactor charging, exothermic heating/agitation, and filter pressing.',
        nominalCycleTimeSeconds: 180.0,
        estimatedSetupTimeSeconds: 1200.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Precursor Raw Material Charging',
          'Jacketed Reactor Heating & Agitation',
          'Catalyst Dosing & Polymerization',
          'Reflux Condensation & Quality Sampling',
          'Filter Press Clarification',
          'Bulk Drum Dispensing & Inert Sealing',
        ],
      ),
      ProcessTemplateItem(
        key: 'general_discrete_assembly',
        name: 'General Discrete Assembly',
        industryType: 'CUSTOM',
        category: 'General Manufacturing',
        description: 'Flexible discrete staging, mechanical assembly, torque fastening, and packaging.',
        nominalCycleTimeSeconds: 60.0,
        estimatedSetupTimeSeconds: 120.0,
        nodeCount: 6,
        edgeCount: 5,
        stages: [
          'Subcomponent Staging & Kitting',
          'Subassembly Cell A',
          'Main Line Fixture Assembly',
          'Calibrated Torque Fastening',
          'Functional Quality Gate',
          'Protective Packaging & Labeling',
        ],
      ),
    ];
  }

  @override
  Future<ProcessDefinitionItem> instantiateTemplate(String templateKey, Map<String, dynamic> payload) async {
    lastInstantiatedTemplateKey = templateKey;
    lastInstantiatedPayload = payload;
    if (shouldFailInstantiation) {
      throw Exception('Template instantiation failed: unauthorized factory access.');
    }
    final newId = 'proc-inst-${DateTime.now().millisecondsSinceEpoch}';
    final newProc = ProcessDefinitionItem(
      id: newId,
      factory: payload['factory_id']?.toString() ?? 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      name: payload['name']?.toString() ?? 'Instantiated Process',
      code: payload['code']?.toString() ?? 'PRC-INST-01',
      description: payload['description']?.toString() ?? '',
      category: 'Instantiated Workflow',
      industryType: 'CNC_ENGINEERING',
      targetCycleTimeSeconds: (payload['target_cycle_time_seconds'] as num?)?.toDouble() ?? 60.0,
      isActive: true,
      versionCount: 1,
      latestVersionId: 'ver-inst-1',
      versions: [
        ProcessVersionItem(
          id: 'ver-inst-1',
          processDefinition: newId,
          versionNumber: 1,
          versionTag: 'v1.0-DRAFT',
          status: 'DRAFT',
          isPublished: false,
          nodeCount: 4,
          edgeCount: 3,
        ),
      ],
    );
    definitions.add(newProc);
    return newProc;
  }

  @override
  Future<ProcessDefinitionItem> duplicateProcess(
    String processId, {
    String? name,
    String? code,
    String? description,
  }) async {
    lastDuplicatedProcessId = processId;
    lastDuplicatedPayload = <String, dynamic>{
      'name': name,
      'code': code,
      'description': description,
    };
    if (shouldFailDuplication) {
      throw Exception('Duplication failed: process code already exists.');
    }
    final newId = 'proc-dup-${DateTime.now().millisecondsSinceEpoch}';
    final newProc = ProcessDefinitionItem(
      id: newId,
      factory: 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      name: name ?? 'Duplicated Process',
      code: code ?? 'PRC-DUP-01',
      description: description ?? '',
      category: 'Duplicated Category',
      industryType: 'TEXTILE',
      targetCycleTimeSeconds: 45.0,
      isActive: true,
      versionCount: 1,
      latestVersionId: 'ver-dup-1',
      versions: [
        ProcessVersionItem(
          id: 'ver-dup-1',
          processDefinition: newId,
          versionNumber: 1,
          versionTag: 'v1.0-DRAFT',
          status: 'DRAFT',
          isPublished: false,
          nodeCount: 5,
          edgeCount: 4,
        ),
      ],
    );
    definitions.add(newProc);
    return newProc;
  }

  @override
  Future<ProcessDefinitionItem> archiveProcess(String processId) async {
    lastArchivedProcessId = processId;
    if (processId == 'proc-conflict' || shouldFailArchiveConflict) {
      throw Exception('Cannot archive process definition: Active work order WO-2026-0001 is currently IN_PROGRESS.');
    }
    final idx = definitions.indexWhere((p) => p.id == processId);
    if (idx != -1) {
      final p = definitions[idx];
      final updated = ProcessDefinitionItem(
        id: p.id,
        factory: p.factory,
        factoryName: p.factoryName,
        name: p.name,
        code: p.code,
        description: p.description,
        category: p.category,
        industryType: p.industryType,
        targetCycleTimeSeconds: p.targetCycleTimeSeconds,
        isActive: false,
        versionCount: p.versionCount,
        latestVersionId: p.latestVersionId,
        publishedVersionId: p.publishedVersionId,
        publishedVersionTag: p.publishedVersionTag,
        versions: p.versions,
      );
      definitions[idx] = updated;
      return updated;
    }
    throw Exception('Process not found');
  }

  @override
  Future<ProcessNodeItem> updateNode(String nodeId, Map<String, dynamic> payload) async {
    lastUpdatedNodeId = nodeId;
    lastUpdatedPayload = payload;
    if (shouldFailUpdateNode) {
      throw Exception('Failed to update node properties: invalid machine parameters.');
    }
    final rawSkills = payload['required_skills'];
    List<String> skills = [];
    if (rawSkills is List) {
      skills = rawSkills.map((e) => e.toString()).toList();
    }
    final updated = ProcessNodeItem(
      id: nodeId,
      nodeKey: 'OP-01',
      name: payload['name'] ?? 'Updated Operation',
      nodeType: payload['node_type'] ?? 'OPERATION',
      cycleTimeSeconds: (payload['cycle_time_seconds'] as num?)?.toDouble() ?? 30.0,
      setupTimeSeconds: (payload['setup_time_seconds'] as num?)?.toDouble() ?? 0.0,
      standardCapacityPerHour: (payload['standard_capacity_per_hour'] as num?)?.toInt() ?? 60,
      requiredOperators: (payload['required_operators'] as num?)?.toInt() ?? 1,
      operatorRole: payload['operator_role'] ?? '',
      requiredSkills: skills,
      yieldRatePercent: (payload['yield_rate_percent'] as num?)?.toDouble() ?? 100.0,
      assignedLine: payload['assigned_line'],
      assignedMachine: payload['assigned_machine'],
      positionX: 250,
      positionY: 100,
    );

    final updatedNodes = draftVersion.nodes.map((n) => n.id == nodeId ? updated : n).toList();
    draftVersion = ProcessVersionItem(
      id: draftVersion.id,
      processDefinition: draftVersion.processDefinition,
      versionNumber: draftVersion.versionNumber,
      versionTag: draftVersion.versionTag,
      status: draftVersion.status,
      isPublished: draftVersion.isPublished,
      nodeCount: updatedNodes.length,
      edgeCount: draftVersion.edgeCount,
      nodes: updatedNodes,
      edges: draftVersion.edges,
    );
    return updated;
  }

  @override
  Future<ProcessVersionItem> getProcessVersion(String versionId) async {
    if (versionId == 'ver-draft') {
      return draftVersion;
    }
    return const ProcessVersionItem(
      id: 'ver-published',
      processDefinition: 'proc-def-1',
      versionNumber: 1,
      versionTag: 'v1.0-PROD',
      status: 'PUBLISHED',
      isPublished: true,
      nodeCount: 2,
      edgeCount: 1,
      nodes: [
        ProcessNodeItem(
          id: 'n-1',
          nodeKey: 'START-01',
          name: 'Process Start',
          nodeType: 'START',
          positionX: 50,
          positionY: 100,
        ),
        ProcessNodeItem(
          id: 'n-2',
          nodeKey: 'OP-01',
          name: 'Carding Operation',
          nodeType: 'OPERATION',
          positionX: 250,
          positionY: 100,
        ),
      ],
      edges: [
        ProcessEdgeItem(
          id: 'e-1',
          edgeKey: 'E-01',
          sourceNode: 'n-1',
          targetNode: 'n-2',
          sourceNodeKey: 'START-01',
          targetNodeKey: 'OP-01',
        ),
      ],
    );
  }

  @override
  Future<GraphValidationResult> validateVersion(String versionId) async {
    if (!mockValidationShouldPass) {
      return const GraphValidationResult(
        isValid: false,
        status: 'FAILED',
        errors: [
          "Operation node 'NODE-08' has no incoming connections (unreachable).",
          "The following nodes are unreachable from any START node: NODE-08",
        ],
        warnings: [],
        invalidNodeKeys: ['NODE-08'],
      );
    } else {
      return const GraphValidationResult(
        isValid: true,
        status: 'VALID',
        errors: [],
        warnings: [],
        invalidNodeKeys: [],
      );
    }
  }

  @override
  Future<List<WorkOrderItem>> getWorkOrders({String? factoryId, String? status, String? priority}) async {
    if (shouldFailWorkOrders) {
      throw Exception('Failed to load work orders from backend API.');
    }
    return [
      const WorkOrderItem(
        id: 'wo-1',
        factory: 'test-factory-1',
        factoryName: 'Apex Precision Textiles',
        orderNumber: 'WO-2026-0001',
        product: 'prod-1',
        productName: 'Combed Cotton Yarn 30s',
        productSku: 'SKU-TEX-01',
        processDefinition: 'proc-def-1',
        processName: 'Automated Textile Yarn Spinning',
        processVersion: 'ver-1',
        processVersionTag: 'v1.0-PROD',
        quantityTarget: 1000,
        quantityCompleted: 650,
        quantityScrapped: 12,
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        progressPercent: 65.0,
      ),
    ];
  }

  @override
  Future<List<ProductModel>> getFactoryProducts(String factoryId) async {
    return [
      const ProductModel(
        id: 'prod-1',
        name: 'Combed Cotton Yarn 30s',
        sku: 'SKU-TEX-01',
        unitOfMeasure: 'kg',
      ),
    ];
  }

  @override
  Future<WorkOrderItem> createWorkOrder(Map<String, dynamic> payload) async {
    lastCreatedWorkOrderPayload = payload;
    if (shouldFailCreateWorkOrder) {
      throw Exception(createWorkOrderErrorMessage ?? 'Work order creation failed: Duplicate order number.');
    }
    return const WorkOrderItem(
      id: 'wo-new-1',
      factory: 'test-factory-1',
      factoryName: 'Apex Precision Textiles',
      orderNumber: 'WO-2026-9999',
      product: 'prod-1',
      productName: 'Combed Cotton Yarn 30s',
      productSku: 'SKU-TEX-01',
      processDefinition: 'proc-def-1',
      processName: 'Automated Textile Yarn Spinning',
      processVersion: 'ver-published',
      processVersionTag: 'v1.0-PROD',
      quantityTarget: 100,
      status: 'RELEASED',
      priority: 'NORMAL',
    );
  }

  @override
  Future<Map<String, dynamic>> executeWorkOrderAction(String workOrderId, String action, {Map<String, dynamic>? payload}) async {
    lastExecutedWorkOrderId = workOrderId;
    lastExecutedAction = action;
    if (actionCompleter != null) {
      return await actionCompleter!.future;
    }
    return {'success': true, 'message': 'Action $action executed'};
  }

  @override
  Future<Map<String, dynamic>> executeExecutionAction(String executionId, String action, {Map<String, dynamic>? payload}) async {
    return {'success': true, 'message': 'Execution action $action executed'};
  }

  @override
  Future<ProcessExecutionItem> getExecution(String executionId) async {
    final list = await getExecutions();
    return list.first;
  }

  @override
  Future<Map<String, dynamic>> advanceStage(String stageId, {int? unitsCompleted, int unitsScrapped = 0, double? durationSeconds}) async {
    return {
      'success': true,
      'stage': {'id': stageId, 'status': 'COMPLETED'},
      'execution': {
        'id': 'exec-1',
        'work_order': 'wo-1',
        'order_number': 'WO-2026-0001',
        'product_name': 'Combed Cotton Yarn 30s',
        'quantity_target': 1000,
        'process_version': 'ver-1',
        'execution_number': 'EXEC-2026-0001',
        'status': 'RUNNING',
        'mode': 'SIMULATION',
        'current_progress_percent': 75.0,
        'total_units_input': 1000,
        'total_units_output': 750,
        'total_units_scrap': 12,
        'stage_executions': [
          {
            'id': 'stg-1',
            'node': 'node-1',
            'node_key': 'OP-01',
            'node_name': 'Carding & Web Formation',
            'node_type': 'OPERATION',
            'status': 'COMPLETED',
            'units_queued': 0,
            'units_in_progress': 0,
            'units_completed': 1000,
            'units_scrapped': 5,
          }
        ]
      }
    };
  }

  @override
  Future<List<ProcessExecutionItem>> getExecutions({String? factoryId, String? status, String? workOrderId}) async {
    return [
      const ProcessExecutionItem(
        id: 'exec-1',
        workOrder: 'wo-1',
        orderNumber: 'WO-2026-0001',
        productName: 'Combed Cotton Yarn 30s',
        quantityTarget: 1000,
        processVersion: 'ver-1',
        executionNumber: 'EXEC-2026-0001',
        status: 'RUNNING',
        mode: 'SIMULATION',
        currentProgressPercent: 65.0,
        totalUnitsInput: 1000,
        totalUnitsOutput: 650,
        totalUnitsScrap: 12,
        stageExecutions: [
          StageExecutionItem(
            id: 'stg-1',
            node: 'node-1',
            nodeKey: 'OP-01',
            nodeName: 'Carding & Web Formation',
            nodeType: 'OPERATION',
            status: 'RUNNING',
            unitsQueued: 350,
            unitsInProgress: 50,
            unitsCompleted: 600,
            unitsScrapped: 5,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<ProductionEventItem>> getProductionEvents({
    String? factoryId,
    String? workOrderId,
    String? executionId,
    String? severity,
  }) async {
    return [
      const ProductionEventItem(
        id: 'evt-1',
        factory: 'test-factory-1',
        workOrder: 'wo-1',
        processExecution: 'exec-1',
        eventType: 'EXECUTION_STARTED',
        severity: 'INFO',
        source: 'SIMULATION',
        message: 'Execution started for WO-2026-0001',
        timestamp: '2026-10-16T10:00:00Z',
      ),
    ];
  }

  @override
  Future<List<SimulationScenarioItem>> getSimulationScenarios({String? factoryId, String? scenarioType}) async {
    return [
      const SimulationScenarioItem(
        id: 'scen-1',
        factory: 'test-factory-1',
        factoryName: 'Apex Precision Textiles',
        name: 'Spindle Bearing Thermal Seizure',
        description: 'Simulates mechanical failure on spinning frame spindle rail.',
        scenarioType: 'MACHINE_BREAKDOWN',
        randomSeed: 42,
        isActive: true,
      ),
    ];
  }

  @override
  Future<List<MaterialFlowItem>> getMaterialFlows({String? factoryId, String? executionId}) async {
    return [
      const MaterialFlowItem(
        id: 'mf-1',
        processExecution: 'exec-1',
        stageExecution: 'stg-1',
        stageName: 'Carding & Web Formation',
        rawMaterial: 'raw-1',
        rawMaterialName: 'Raw Pima Cotton Bales',
        flowType: 'INPUT_CONSUMPTION',
        quantity: 500.0,
        unitOfMeasure: 'kg',
        previousStockLevel: 5000.0,
        newStockLevel: 4500.0,
        timestamp: '2026-10-15T12:00:00Z',
        notes: 'Batch consumption for WO-2026-0001',
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getWipSummary({String? factoryId, String? executionId}) async {
    return [
      {
        'node_key': 'OP-01',
        'node_name': 'Carding & Web Formation',
        'status': 'RUNNING',
        'units_queued': 350,
        'units_in_progress': 50,
        'units_completed': 600,
        'units_scrapped': 5,
      },
    ];
  }
}

Widget createTestApp(Widget child, {MockFactoryRepository? factoryRepo, MockProcessRepository? processRepo}) {
  return ProviderScope(
    overrides: [
      factoryRepositoryProvider.overrideWithValue(factoryRepo ?? MockFactoryRepository()),
      processRepositoryProvider.overrideWithValue(processRepo ?? MockProcessRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Phase 3 Universal Process Engine — Widget & Screen Tests', () {
    testWidgets('ProcessLibraryScreen renders workflow catalogue and create action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Universal Process Workflows'), findsOneWidget);
      expect(find.text('Start from Industry Template'), findsOneWidget);
      expect(find.text('New Process Workflow'), findsOneWidget);
      expect(find.text('Automated Textile Yarn Spinning'), findsOneWidget);
      expect(find.text('Open Visual Canvas'), findsWidgets);
    });

    testWidgets('ProcessLibraryScreen filters workflows by industry', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Automated Textile Yarn Spinning'), findsOneWidget);
      expect(find.text('EV Battery Pack Assembly'), findsOneWidget);

      // Select TEXTILE from industry filter dropdown
      await tester.tap(find.byKey(const Key('filter_industry_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TEXTILE').last);
      await tester.pumpAndSettle();

      expect(find.text('Automated Textile Yarn Spinning'), findsOneWidget);
      expect(find.text('EV Battery Pack Assembly'), findsNothing);

      // Select All Industries to restore
      await tester.tap(find.byKey(const Key('filter_industry_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All Industries').last);
      await tester.pumpAndSettle();

      expect(find.text('Automated Textile Yarn Spinning'), findsOneWidget);
      expect(find.text('EV Battery Pack Assembly'), findsOneWidget);
    });

    testWidgets('ProcessLibraryScreen filters workflows by status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen()));
      await tester.pumpAndSettle();

      // Tap PUBLISHED status chip
      await tester.tap(find.byKey(const Key('filter_status_PUBLISHED')));
      await tester.pumpAndSettle();

      expect(find.text('Automated Textile Yarn Spinning'), findsOneWidget);
      expect(find.text('EV Battery Pack Assembly'), findsNothing);
      expect(find.text('Legacy SMT Assembly'), findsNothing);

      // Tap DRAFT status chip
      await tester.tap(find.byKey(const Key('filter_status_DRAFT')));
      await tester.pumpAndSettle();

      expect(find.text('EV Battery Pack Assembly'), findsOneWidget);
      expect(find.text('Automated Textile Yarn Spinning'), findsNothing);
      expect(find.text('Legacy SMT Assembly'), findsNothing);

      // Tap ARCHIVED status chip
      await tester.tap(find.byKey(const Key('filter_status_ARCHIVED')));
      await tester.pumpAndSettle();

      expect(find.text('Legacy SMT Assembly'), findsOneWidget);
      expect(find.text('Automated Textile Yarn Spinning'), findsNothing);
      expect(find.text('EV Battery Pack Assembly'), findsNothing);
    });

    testWidgets('ProcessLibraryScreen combines search query with filters and resets filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen()));
      await tester.pumpAndSettle();

      // Enter "Battery" into search field
      await tester.enterText(find.byKey(const Key('process_search_field')), 'Battery');
      await tester.pumpAndSettle();

      expect(find.text('EV Battery Pack Assembly'), findsOneWidget);
      expect(find.text('Automated Textile Yarn Spinning'), findsNothing);

      // Apply TEXTILE industry filter while searching for Battery -> should yield empty state
      await tester.tap(find.byKey(const Key('filter_industry_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TEXTILE').last);
      await tester.pumpAndSettle();

      expect(find.text('EV Battery Pack Assembly'), findsNothing);
      expect(find.text('No Matching Process Workflows'), findsOneWidget);

      // Tap Reset Filters button
      expect(find.byKey(const Key('reset_filters_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('reset_filters_button')));
      await tester.pumpAndSettle();

      // Both workflows restored and search text cleared
      expect(find.text('Automated Textile Yarn Spinning'), findsOneWidget);
      expect(find.text('EV Battery Pack Assembly'), findsOneWidget);
    });

    testWidgets('ProcessLibraryScreen renders archived workflow with distinct read-only badge and restricted actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen()));
      await tester.pumpAndSettle();

      // Switch to Archived filter
      await tester.tap(find.byKey(const Key('filter_status_ARCHIVED')));
      await tester.pumpAndSettle();

      expect(find.text('Legacy SMT Assembly'), findsOneWidget);
      expect(find.text('Read-Only Archived Process'), findsOneWidget);
      expect(find.text('View Graph Canvas'), findsOneWidget);

      // Open card context menu
      await tester.tap(find.byKey(const Key('process_card_menu_proc-def-3')));
      await tester.pumpAndSettle();

      // Verify Duplicate is available, but Archive is NOT shown for already-archived process
      expect(find.text('Duplicate Workflow'), findsOneWidget);
      expect(find.text('Archive Workflow'), findsNothing);
    });

    testWidgets('Template picker dialog opens, displays all 8 industry templates with stage previews, and filters by search', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen()));
      await tester.pumpAndSettle();

      // Open template browser
      await tester.tap(find.byKey(const Key('start_from_template_button')));
      await tester.pumpAndSettle();

      expect(find.text('Universal Manufacturing Process Templates'), findsOneWidget);
      expect(find.text('CNC Precision Machining'), findsOneWidget);
      expect(find.text('Automotive / EV Battery Module Assembly'), findsOneWidget);
      expect(find.text('Electronics SMT / PCBA'), findsOneWidget);
      expect(find.text('Pharmaceuticals / Sterile Production'), findsOneWidget);

      // Verify stage previews
      expect(find.text('1. Stock Material Ingest & Clamping'), findsOneWidget);

      // Search inside template modal
      await tester.enterText(find.byKey(const Key('template_search_input')), 'Chemical');
      await tester.pumpAndSettle();

      expect(find.text('Chemical Batch Processing'), findsOneWidget);
      expect(find.text('CNC Precision Machining'), findsNothing);
    });

    testWidgets('Template instantiation validates required fields, uses authorized factory context, and succeeds', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Open template browser
      await tester.tap(find.byKey(const Key('start_from_template_button')));
      await tester.pumpAndSettle();

      // Click "Use Template" on CNC template
      await tester.tap(find.byKey(const Key('use_template_button_cnc_precision_machining')));
      await tester.pumpAndSettle();

      expect(find.text('Instantiate Process Template'), findsOneWidget);
      expect(find.textContaining('Target Factory: Apex Precision Textiles'), findsOneWidget);

      // Clear name and test required-field validation
      await tester.enterText(find.byKey(const Key('template_instantiate_name')), '');
      await tester.tap(find.byKey(const Key('template_instantiate_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Process name is required.'), findsOneWidget);

      // Provide valid name and submit
      await tester.enterText(find.byKey(const Key('template_instantiate_name')), 'Aero Turbine Impeller Cell');
      await tester.tap(find.byKey(const Key('template_instantiate_submit_button')));
      await tester.pumpAndSettle();

      // Check repository call
      expect(mockRepo.lastInstantiatedTemplateKey, 'cnc_precision_machining');
      expect(mockRepo.lastInstantiatedPayload?['factory_id'], 'test-factory-1');
      expect(mockRepo.lastInstantiatedPayload?['name'], 'Aero Turbine Impeller Cell');

      // Modal closed and success feedback displayed
      expect(find.text('Instantiate Process Template'), findsNothing);
      expect(find.textContaining("instantiated successfully"), findsOneWidget);
    });

    testWidgets('Template instantiation handles API failure and preserves form inputs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();
      mockRepo.shouldFailInstantiation = true;

      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Open template browser and choose template
      await tester.tap(find.byKey(const Key('start_from_template_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('use_template_button_automotive_ev_battery')));
      await tester.pumpAndSettle();

      // Submit form
      await tester.enterText(find.byKey(const Key('template_instantiate_name')), 'NextGen EV Pack');
      await tester.tap(find.byKey(const Key('template_instantiate_submit_button')));
      await tester.pumpAndSettle();

      // Check error displayed without closing dialog
      expect(find.textContaining('Template instantiation failed: unauthorized factory access.'), findsWidgets);
      expect(find.text('Instantiate Process Template'), findsOneWidget);
      expect(find.text('NextGen EV Pack'), findsOneWidget);
    });

    testWidgets('Duplicate process action opens dialog, validates input, and duplicates definition', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Open card menu for proc-def-1 and select Duplicate Workflow
      await tester.tap(find.byKey(const Key('process_card_menu_proc-def-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate Workflow'));
      await tester.pumpAndSettle();

      expect(find.text('Duplicate Process Workflow'), findsOneWidget);
      expect(find.text('Automated Textile Yarn Spinning (Copy)'), findsOneWidget);

      // Submit duplicate request
      await tester.tap(find.byKey(const Key('duplicate_process_submit_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastDuplicatedProcessId, 'proc-def-1');
      expect(mockRepo.lastDuplicatedPayload?['name'], 'Automated Textile Yarn Spinning (Copy)');
      expect(mockRepo.lastDuplicatedPayload?['code'], 'PROC-TEX-SPIN-COPY');
      expect(find.textContaining("duplicated"), findsWidgets);
    });

    testWidgets('Archive process action shows confirmation, warns about non-deletion, and safely archives', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Open card menu for proc-def-1 and select Archive Workflow
      await tester.tap(find.byKey(const Key('process_card_menu_proc-def-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Workflow'));
      await tester.pumpAndSettle();

      expect(find.text('Archive Process Definition'), findsOneWidget);
      expect(find.textContaining("This operation does NOT delete any database records."), findsOneWidget);

      // Confirm archive
      await tester.tap(find.byKey(const Key('confirm_archive_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastArchivedProcessId, 'proc-def-1');
      expect(find.textContaining("safely archived"), findsWidgets);
    });

    testWidgets('Archive process action displays backend 409 conflict error when active work orders exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(createTestApp(const ProcessLibraryScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Open card menu for proc-conflict which has active work orders
      await tester.tap(find.byKey(const Key('process_card_menu_proc-conflict')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Workflow'));
      await tester.pumpAndSettle();

      // Confirm archive
      await tester.tap(find.byKey(const Key('confirm_archive_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastArchivedProcessId, 'proc-conflict');
      expect(find.textContaining('Cannot archive process definition: Active work order WO-2026-0001 is currently IN_PROGRESS.'), findsWidgets);
      expect(find.text('Archive Process Definition'), findsOneWidget);
    });

    testWidgets('VisualProcessBuilderScreen Inspector displays and edits setup time, operator role, skills, and yield rate', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VisualProcessBuilderScreen(versionId: 'ver-draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click node n-2 (Carding Operation)
      await tester.tap(find.text('Carding Operation'));
      await tester.pumpAndSettle();

      expect(find.text('Node Inspector'), findsOneWidget);
      expect(find.text('Key: OP-01'), findsOneWidget);

      // Inspect pre-filled values
      final setupField = tester.widget<TextField>(find.byKey(const Key('inspector_setup_time')));
      expect(setupField.controller?.text, '30.0');

      final roleField = tester.widget<TextField>(find.byKey(const Key('inspector_operator_role')));
      expect(roleField.controller?.text, 'Spinning Technician');

      final skillsField = tester.widget<TextField>(find.byKey(const Key('inspector_required_skills')));
      expect(skillsField.controller?.text, 'Sliver Splicing, Tension Calibration');

      final yieldField = tester.widget<TextField>(find.byKey(const Key('inspector_yield_rate')));
      expect(yieldField.controller?.text, '99.5');

      // Edit fields
      await tester.enterText(find.byKey(const Key('inspector_setup_time')), '120.0');
      await tester.enterText(find.byKey(const Key('inspector_operator_role')), 'Lead CNC Specialist');
      await tester.enterText(find.byKey(const Key('inspector_required_skills')), 'G-Code Programming, Precision Metrology');
      await tester.ensureVisible(find.byKey(const Key('inspector_yield_rate')));
      await tester.enterText(find.byKey(const Key('inspector_yield_rate')), '98.0');

      // Apply changes
      await tester.ensureVisible(find.byKey(const Key('inspector_apply_changes_button')));
      await tester.tap(find.byKey(const Key('inspector_apply_changes_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastUpdatedNodeId, 'n-2');
      expect(mockRepo.lastUpdatedPayload?['setup_time_seconds'], 120.0);
      expect(mockRepo.lastUpdatedPayload?['operator_role'], 'Lead CNC Specialist');
      expect(mockRepo.lastUpdatedPayload?['required_skills'], ['G-Code Programming', 'Precision Metrology']);
      expect(mockRepo.lastUpdatedPayload?['yield_rate_percent'], 98.0);
    });

    testWidgets('VisualProcessBuilderScreen Inspector filters machines by assigned line and clears on mismatch', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VisualProcessBuilderScreen(versionId: 'ver-draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Carding Operation
      await tester.tap(find.text('Carding Operation'));
      await tester.pumpAndSettle();

      // Select Precision CNC Milling Line 1
      await tester.tap(find.byKey(const Key('inspector_line_assignment')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Precision CNC Milling Line 1 [LINE-CNC-01]').last);
      await tester.pumpAndSettle();

      // Open Machine assignment dropdown and verify machines from Line 1 are available
      await tester.tap(find.byKey(const Key('inspector_machine_assignment')));
      await tester.pumpAndSettle();

      expect(find.text('Haas 5-Axis VF2 [MC-CNC-01]').last, findsOneWidget);
      expect(find.text('DMG MORI MillTap 700 [MC-CNC-02]').last, findsOneWidget);

      // Select Haas machine
      await tester.tap(find.text('Haas 5-Axis VF2 [MC-CNC-01]').last);
      await tester.pumpAndSettle();

      // Change line to Line 2 (Surface Finishing Line)
      await tester.tap(find.byKey(const Key('inspector_line_assignment')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Surface Finishing Line 2 [LINE-FIN-02]').last);
      await tester.pumpAndSettle();

      // Verify machine dropdown is now cleared or updated (Haas is no longer selected)
      await tester.tap(find.byKey(const Key('inspector_machine_assignment')));
      await tester.pumpAndSettle();

      expect(find.text('Ultrasonic Degreaser 3000 [MC-CLN-01]').last, findsOneWidget);
      expect(find.text('Haas 5-Axis VF2 [MC-CNC-01]'), findsNothing);
    });

    testWidgets('VisualProcessBuilderScreen Inspector rejects invalid numeric inputs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VisualProcessBuilderScreen(versionId: 'ver-draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Carding Operation
      await tester.tap(find.text('Carding Operation'));
      await tester.pumpAndSettle();

      // Enter negative cycle time
      await tester.enterText(find.byKey(const Key('inspector_cycle_time')), '-15.0');
      await tester.ensureVisible(find.byKey(const Key('inspector_apply_changes_button')));
      await tester.tap(find.byKey(const Key('inspector_apply_changes_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cycle time must be a non-negative number.'), findsOneWidget);
      expect(mockRepo.lastUpdatedNodeId, isNull);

      // Fix cycle time, enter invalid yield rate (> 100%)
      await tester.ensureVisible(find.byKey(const Key('inspector_cycle_time')));
      await tester.enterText(find.byKey(const Key('inspector_cycle_time')), '45.0');
      await tester.ensureVisible(find.byKey(const Key('inspector_yield_rate')));
      await tester.enterText(find.byKey(const Key('inspector_yield_rate')), '150.0');
      await tester.ensureVisible(find.byKey(const Key('inspector_apply_changes_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inspector_apply_changes_button')));
      await tester.pumpAndSettle();

      expect(find.text('Yield rate must be between 0% and 100%.'), findsOneWidget);
      expect(mockRepo.lastUpdatedNodeId, isNull);
    });

    testWidgets('WorkOrderManagementScreen renders order metrics and order list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Manufacturing Work Orders'), findsOneWidget);
      expect(find.text('Create Work Order'), findsOneWidget);
      expect(find.text('WO-2026-0001'), findsOneWidget);
      expect(find.textContaining('Combed Cotton Yarn 30s'), findsOneWidget);
      expect(find.text('IN_PROGRESS'), findsWidgets);
    });

    testWidgets('WorkOrderManagementScreen renders lifecycle action buttons for in-progress order', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Live Monitor'), findsOneWidget);
    });

    testWidgets('WorkOrderManagementScreen opens create order dialog with product and published process', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Work Order'));
      await tester.pumpAndSettle();

      expect(find.text('Create Production Work Order'), findsOneWidget);
      expect(find.text('Manufactured Product (SKU) *'), findsOneWidget);
      expect(find.text('Published Process Workflow *'), findsOneWidget);
      expect(find.text('Target Production Units *'), findsOneWidget);
      expect(find.text('Operational Priority'), findsOneWidget);
      expect(find.text('Initial Order Status'), findsOneWidget);
    });

    testWidgets('WorkOrderManagementScreen excludes inactive or draft process definitions and includes line selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Work Order'));
      await tester.pumpAndSettle();

      // Check line dropdown exists
      expect(find.byKey(const Key('create_work_order_line_dropdown')), findsOneWidget);

      // Check published process dropdown contents
      await tester.tap(find.byKey(const Key('create_work_order_process_dropdown')));
      await tester.pumpAndSettle();

      // Active published workflows are present
      expect(find.textContaining('Automated Textile Yarn Spinning [PROC-TEX-SPIN]'), findsWidgets);
      expect(find.textContaining('Critical Active Sterile Line [PROC-PHARM-ACT]'), findsWidgets);

      // Draft-only workflow and archived workflow are NOT selectable
      expect(find.textContaining('EV Battery Pack Assembly'), findsNothing);
      expect(find.textContaining('Legacy SMT Assembly'), findsNothing);

      // Close dropdown by tapping outside or picking an item
      await tester.tap(find.textContaining('Automated Textile Yarn Spinning [PROC-TEX-SPIN]').last);
      await tester.pumpAndSettle();

      // Select assigned production line
      await tester.tap(find.byKey(const Key('create_work_order_line_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Precision CNC Milling Line 1').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Precision CNC Milling Line 1'), findsWidgets);
    });

    testWidgets('WorkOrderManagementScreen preserves form inputs and displays dialog error banner on API rejection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();
      mockRepo.shouldFailCreateWorkOrder = true;
      mockRepo.createWorkOrderErrorMessage = 'Work order number WO-2026-0001 already exists for this tenant.';

      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Work Order'));
      await tester.pumpAndSettle();

      // Enter unique order values
      await tester.enterText(find.byKey(const Key('create_work_order_number_field')), 'WO-DUPLICATE-001');
      await tester.enterText(find.byKey(const Key('create_work_order_qty_field')), '750');

      // Submit creation
      await tester.tap(find.byKey(const Key('create_work_order_submit_button')));
      await tester.pumpAndSettle();

      // Dialog must remain open with error banner visible
      expect(find.text('Create Production Work Order'), findsOneWidget);
      expect(find.byKey(const Key('create_work_order_dialog_error')), findsOneWidget);
      expect(find.textContaining('Work order number WO-2026-0001 already exists for this tenant.'), findsWidgets);

      // Values entered by user are preserved without loss
      final orderField = tester.widget<TextField>(find.byKey(const Key('create_work_order_number_field')));
      expect(orderField.controller?.text, 'WO-DUPLICATE-001');

      final qtyField = tester.widget<TextField>(find.byKey(const Key('create_work_order_qty_field')));
      expect(qtyField.controller?.text, '750');
    });

    testWidgets('WorkOrderManagementScreen creates work order with selected process version and line and closes dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();

      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Work Order'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('create_work_order_number_field')), 'WO-2026-9001');
      await tester.enterText(find.byKey(const Key('create_work_order_qty_field')), '250');

      // Select line
      await tester.tap(find.byKey(const Key('create_work_order_line_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Precision CNC Milling Line 1').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('create_work_order_submit_button')));
      await tester.pumpAndSettle();

      // Verify payload passed to repository
      expect(mockRepo.lastCreatedWorkOrderPayload?['order_number'], 'WO-2026-9001');
      expect(mockRepo.lastCreatedWorkOrderPayload?['process_definition'], 'proc-def-1');
      expect(mockRepo.lastCreatedWorkOrderPayload?['process_version'], 'ver-published');
      expect(mockRepo.lastCreatedWorkOrderPayload?['assigned_line'], 'line-1');
      expect(mockRepo.lastCreatedWorkOrderPayload?['quantity_target'], 250);

      // Dialog is dismissed
      expect(find.text('Create Production Work Order'), findsNothing);
      expect(find.textContaining('created successfully'), findsWidgets);
    });

    testWidgets('WorkOrderManagementScreen disables action buttons and shows spinner while action is in flight', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();
      mockRepo.actionCompleter = Completer<Map<String, dynamic>>();

      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Find Pause button for wo-1
      final pauseButtonFinder = find.widgetWithText(OutlinedButton, 'Pause');
      expect(pauseButtonFinder, findsOneWidget);

      // Tap Pause to initiate lifecycle transition
      await tester.tap(pauseButtonFinder);
      await tester.pump(); // Advance one frame to let actionLoadingOrderId take effect

      // Verify action was invoked
      expect(mockRepo.lastExecutedWorkOrderId, 'wo-1');
      expect(mockRepo.lastExecutedAction, 'pause');

      // Verify that during in-flight action, action buttons are disabled to prevent duplicate submissions
      final runningPause = tester.widget<OutlinedButton>(pauseButtonFinder);
      expect(runningPause.onPressed, isNull);

      final completeButtonFinder = find.widgetWithText(ElevatedButton, 'Complete');
      final runningComplete = tester.widget<ElevatedButton>(completeButtonFinder);
      expect(runningComplete.onPressed, isNull);

      // Complete async action
      mockRepo.actionCompleter!.complete({'success': true});
      await tester.pumpAndSettle();

      // Verify completion restored state
      expect(find.textContaining("Work order action 'PAUSE' executed successfully."), findsOneWidget);
    });

    testWidgets('WorkOrderManagementScreen renders retry button on load failure and reloads successfully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();
      mockRepo.shouldFailWorkOrders = true;

      await tester.pumpWidget(createTestApp(const WorkOrderManagementScreen(), processRepo: mockRepo));
      await tester.pumpAndSettle();

      // Error banner and retry button should be visible
      expect(find.byKey(const Key('work_order_error_banner')), findsOneWidget);
      expect(find.byKey(const Key('work_order_retry_button')), findsOneWidget);
      expect(find.textContaining('Failed to load work orders from backend API.'), findsOneWidget);

      // Fix failure condition and tap retry
      mockRepo.shouldFailWorkOrders = false;
      await tester.tap(find.byKey(const Key('work_order_retry_button')));
      await tester.pumpAndSettle();

      // Error banner disappears, orders load
      expect(find.byKey(const Key('work_order_error_banner')), findsNothing);
      expect(find.text('WO-2026-0001'), findsOneWidget);
    });

    testWidgets('SimulationConsoleScreen renders hardware isolation banner and anomaly deck', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      await tester.pumpWidget(createTestApp(const SimulationConsoleScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SIMULATION ENVIRONMENT — ISOLATED FROM HARDWARE'), findsOneWidget);
      expect(find.text('SOFTWARE MODEL ONLY'), findsOneWidget);
      expect(find.text('Production Simulation Console'), findsOneWidget);
      expect(find.text('Machine Breakdown'), findsOneWidget);
      expect(find.text('Material Shortage'), findsOneWidget);
      expect(find.text('Production Cycle Delay'), findsOneWidget);
      expect(find.text('Quality Rejection Spike'), findsOneWidget);
      expect(find.text('Bottleneck Formation'), findsOneWidget);
      expect(find.text('Demand Surge Pressure'), findsOneWidget);
      expect(find.text('Deterministic Random Seed'), findsOneWidget);
    });

    testWidgets('MaterialFlowScreen renders inventory metrics and flow ledger', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp(const MaterialFlowScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Material Flow & WIP Tracking'), findsOneWidget);
      expect(find.text('Raw Consumed'), findsOneWidget);
      expect(find.text('Active WIP'), findsOneWidget);
      expect(find.text('Finished Output'), findsOneWidget);
      expect(find.text('Total Scrap'), findsOneWidget);
      expect(find.textContaining('Raw Pima Cotton Bales'), findsWidgets);
    });

    testWidgets('ProcessLibraryScreen navigates to Visual Process Builder when Open Visual Canvas is clicked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final router = GoRouter(
        initialLocation: '/processes',
        routes: [
          GoRoute(
            path: '/processes',
            builder: (context, state) => const ProcessLibraryScreen(),
          ),
          GoRoute(
            path: '/processes/:versionId/builder',
            builder: (context, state) => VisualProcessBuilderScreen(
              versionId: state.pathParameters['versionId'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(MockProcessRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open_canvas_button_proc-def-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('open_canvas_button_proc-def-1')));
      await tester.pumpAndSettle();

      // Verify navigation occurred and VisualProcessBuilderScreen is rendered in read-only mode for published version
      expect(find.text('Workflow Canvas'), findsOneWidget);
      expect(find.textContaining('v1.0-PROD [PUBLISHED]'), findsOneWidget);
      expect(find.text('Read-Only (Published)'), findsOneWidget);
      expect(find.text('Clone Editable Draft'), findsOneWidget);
    });

    testWidgets('VisualProcessBuilderScreen renders editable controls for DRAFT version', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(MockProcessRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VisualProcessBuilderScreen(versionId: 'ver-draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workflow Canvas'), findsOneWidget);
      expect(find.textContaining('v2.0-DRAFT [DRAFT]'), findsOneWidget);
      expect(find.text('Add Node'), findsOneWidget);
      expect(find.text('Validate Graph'), findsOneWidget);
      expect(find.text('Publish Version'), findsOneWidget);
    });

    testWidgets('VisualProcessBuilderScreen displays persistent error validation panel, highlights invalid node, and disables Publish button on validation failure', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();
      mockRepo.mockValidationShouldPass = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VisualProcessBuilderScreen(versionId: 'ver-draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click "Validate Graph"
      final validateButton = find.text('Validate Graph');
      expect(validateButton, findsOneWidget);
      await tester.tap(validateButton);
      await tester.pumpAndSettle();

      // Validation failure panel should be visible
      expect(find.textContaining('Graph Validation Failed'), findsOneWidget);
      expect(find.text('CANNOT PUBLISH'), findsOneWidget);
      expect(find.text('NODE-08'), findsWidgets);
      expect(find.textContaining("Operation node 'NODE-08' has no incoming connections"), findsOneWidget);

      // Verify "Publish Version" button is disabled
      final publishButtonFinder = find.widgetWithText(ElevatedButton, 'Publish Version');
      expect(publishButtonFinder, findsOneWidget);
      final publishButton = tester.widget<ElevatedButton>(publishButtonFinder);
      expect(publishButton.onPressed, isNull);
    });

    testWidgets('VisualProcessBuilderScreen displays persistent success panel and enables Publish button on validation pass', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final mockRepo = MockProcessRepository();
      mockRepo.mockValidationShouldPass = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
            processRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VisualProcessBuilderScreen(versionId: 'ver-draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click "Validate Graph"
      final validateButton = find.text('Validate Graph');
      expect(validateButton, findsOneWidget);
      await tester.tap(validateButton);
      await tester.pumpAndSettle();

      // Validation success panel should be visible
      expect(find.text('Graph Topology Validation Passed'), findsOneWidget);
      expect(find.text('READY TO PUBLISH'), findsOneWidget);

      // Verify "Publish Version" button is enabled
      final publishButtonFinder = find.widgetWithText(ElevatedButton, 'Publish Version');
      expect(publishButtonFinder, findsOneWidget);
      final publishButton = tester.widget<ElevatedButton>(publishButtonFinder);
      expect(publishButton.onPressed, isNotNull);
    });

    testWidgets('LiveExecutionScreen renders execution metrics, routing stages and lifecycle controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp(const LiveExecutionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Live Production Execution Monitor'), findsOneWidget);
      expect(find.text('EXEC-2026-0001'), findsOneWidget);
      expect(find.text('Carding & Web Formation'), findsOneWidget);
      expect(find.text('Advance Step'), findsOneWidget);
      expect(find.text('Pause Run'), findsOneWidget);
      expect(find.text('Complete Run'), findsOneWidget);

      // Tap Advance Step
      await tester.tap(find.text('Advance Step'));
      await tester.pumpAndSettle();

      expect(find.text('Stage advanced successfully.'), findsOneWidget);
    });
  });
}
