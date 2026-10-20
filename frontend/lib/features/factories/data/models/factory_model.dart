/// FactoryOS AI — Domain & Onboarding Models
/// Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
library;

class CompanyItem {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String website;
  final String contactEmail;
  final bool isActive;
  final int factoryCount;
  final List<FactoryItem> factories;

  const CompanyItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.website,
    required this.contactEmail,
    required this.isActive,
    required this.factoryCount,
    this.factories = const [],
  });

  factory CompanyItem.fromJson(Map<String, dynamic> json) {
    final rawFactories = json['factories'] as List<dynamic>? ?? [];
    return CompanyItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Company',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      website: json['website'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      factoryCount: json['factory_count'] as int? ?? rawFactories.length,
      factories: rawFactories
          .map((e) => FactoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FactoryItem {
  final String id;
  final String name;
  final String code;
  final String industryType;
  final String industryTypeDisplay;
  final String industryCustom;
  final String configurationStatus;
  final String configurationStatusDisplay;
  final String location;
  final String country;
  final String timezone;
  final String operatingHours;
  final List<String> capabilities;
  final int targetDailyCapacity;
  final int totalProductionLines;
  final int activeLines;
  final bool isActive;
  final double overallOee;
  final String factoryType;
  final String factoryTypeDisplay;
  final String manufacturingModel;
  final String manufacturingModelDisplay;
  final String? organizationName;
  final String? organizationId;

  const FactoryItem({
    required this.id,
    required this.name,
    required this.code,
    required this.industryType,
    required this.industryTypeDisplay,
    this.industryCustom = '',
    this.factoryType = 'PRIMARY_MANUFACTURING',
    this.factoryTypeDisplay = 'Primary Manufacturing Plant',
    this.manufacturingModel = 'DISCRETE',
    this.manufacturingModelDisplay = 'Discrete Manufacturing',
    required this.configurationStatus,
    required this.configurationStatusDisplay,
    required this.location,
    required this.country,
    required this.timezone,
    this.operatingHours = '06:00 - 22:00 (Two 8h Shifts)',
    this.capabilities = const [],
    this.targetDailyCapacity = 5000,
    required this.totalProductionLines,
    required this.activeLines,
    required this.isActive,
    this.overallOee = 90.0,
    this.organizationName,
    this.organizationId,
  });

  factory FactoryItem.fromJson(Map<String, dynamic> json) {
    final rawCaps = json['capabilities'];
    List<String> caps = [];
    if (rawCaps is List) {
      caps = rawCaps.map((e) => e.toString()).toList();
    }

    return FactoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Factory',
      code: json['code'] as String? ?? 'FAC-00',
      industryType: json['industry_type'] as String? ?? 'CUSTOM',
      industryTypeDisplay: json['industry_type_display'] as String? ?? json['industry_type'] ?? 'Custom',
      industryCustom: json['industry_custom'] as String? ?? '',
      factoryType: json['factory_type'] as String? ?? 'PRIMARY_MANUFACTURING',
      factoryTypeDisplay: json['factory_type_display'] as String? ?? json['factory_type'] ?? 'Primary Manufacturing Plant',
      manufacturingModel: json['manufacturing_model'] as String? ?? 'DISCRETE',
      manufacturingModelDisplay: json['manufacturing_model_display'] as String? ?? json['manufacturing_model'] ?? 'Discrete Manufacturing',
      configurationStatus: json['configuration_status'] as String? ?? 'CONFIGURED',
      configurationStatusDisplay: json['configuration_status_display'] as String? ?? 'Configured',
      location: json['location'] as String? ?? 'Unspecified',
      country: json['country'] as String? ?? 'USA',
      timezone: json['timezone'] as String? ?? 'UTC',
      operatingHours: json['operating_hours'] as String? ?? '06:00 - 22:00 (Two 8h Shifts)',
      capabilities: caps,
      targetDailyCapacity: json['target_daily_capacity'] as int? ?? 5000,
      totalProductionLines: json['total_production_lines'] as int? ?? 0,
      activeLines: json['active_lines'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      overallOee: (json['overall_oee'] as num?)?.toDouble() ?? 90.0,
      organizationName: json['organization_name'] as String?,
      organizationId: json['organization_id'] as String?,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String sku;
  final String description;
  final String unitOfMeasure;
  final int targetHourlyRate;

  const ProductModel({
    this.id = '',
    required this.name,
    required this.sku,
    this.description = '',
    this.unitOfMeasure = 'units',
    this.targetHourlyRate = 100,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String? ?? '',
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'units',
      targetHourlyRate: json['target_hourly_rate'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sku': sku,
    'description': description,
    'unit_of_measure': unitOfMeasure,
    'target_hourly_rate': targetHourlyRate,
  };
}

class RawMaterialModel {
  final String id;
  final String name;
  final String code;
  final String category;
  final String unitOfMeasure;
  final double safetyStock;
  final double currentStock;

  const RawMaterialModel({
    this.id = '',
    required this.name,
    required this.code,
    this.category = 'General',
    this.unitOfMeasure = 'kg',
    this.safetyStock = 100.0,
    this.currentStock = 500.0,
  });

  factory RawMaterialModel.fromJson(Map<String, dynamic> json) {
    return RawMaterialModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'kg',
      safetyStock: (json['safety_stock'] as num?)?.toDouble() ?? 100.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 500.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'category': category,
    'unit_of_measure': unitOfMeasure,
    'safety_stock': safetyStock,
    'current_stock': currentStock,
  };
}

class ProcessStageModel {
  final String id;
  final String name;
  final int sequence;
  final String description;
  final int cycleTimeSeconds;
  final bool qualityCheckRequired;

  const ProcessStageModel({
    this.id = '',
    required this.name,
    required this.sequence,
    this.description = '',
    this.cycleTimeSeconds = 60,
    this.qualityCheckRequired = false,
  });

  factory ProcessStageModel.fromJson(Map<String, dynamic> json) {
    return ProcessStageModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sequence: json['sequence'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      cycleTimeSeconds: json['cycle_time_seconds'] as int? ?? 60,
      qualityCheckRequired: json['quality_check_required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sequence': sequence,
    'description': description,
    'cycle_time_seconds': cycleTimeSeconds,
    'quality_check_required': qualityCheckRequired,
  };
}

class MachineModel {
  final String id;
  final String name;
  final String code;
  final String machineType;
  final double ratedPowerKw;
  final String status;
  final int? stageSequence;

  const MachineModel({
    this.id = '',
    required this.name,
    required this.code,
    this.machineType = 'General Machine',
    this.ratedPowerKw = 15.0,
    this.status = 'RUNNING',
    this.stageSequence,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      machineType: json['machine_type'] as String? ?? 'General Machine',
      ratedPowerKw: (json['rated_power_kw'] as num?)?.toDouble() ?? 15.0,
      status: json['status'] as String? ?? 'RUNNING',
      stageSequence: json['stage_sequence'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'machine_type': machineType,
    'rated_power_kw': ratedPowerKw,
    'status': status,
    if (stageSequence != null) 'stage_sequence': stageSequence,
  };
}

class ShiftModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final List<String> operatingDays;
  final int plannedCapacityUnits;

  const ShiftModel({
    this.id = '',
    required this.name,
    required this.startTime,
    required this.endTime,
    this.operatingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    this.plannedCapacityUnits = 1000,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['operating_days'];
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    if (rawDays is List) {
      days = rawDays.map((e) => e.toString()).toList();
    }

    return ShiftModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Morning Shift',
      startTime: json['start_time'] as String? ?? '06:00',
      endTime: json['end_time'] as String? ?? '14:00',
      operatingDays: days,
      plannedCapacityUnits: json['planned_capacity_units'] as int? ?? 1000,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'start_time': startTime,
    'end_time': endTime,
    'operating_days': operatingDays,
    'planned_capacity_units': plannedCapacityUnits,
  };
}

class ProductionLineItem {
  final String id;
  final String name;
  final String code;
  final String department;
  final String status;
  final String statusDisplay;
  final String currentProduct;
  final double efficiencyRate;
  final int targetHourlyUnits;
  final int actualHourlyUnits;
  final int operatorCount;
  final String? lastMaintenanceDate;
  final List<MachineModel> machines;

  const ProductionLineItem({
    required this.id,
    required this.name,
    required this.code,
    this.department = 'General Production',
    required this.status,
    required this.statusDisplay,
    required this.currentProduct,
    required this.efficiencyRate,
    required this.targetHourlyUnits,
    required this.actualHourlyUnits,
    required this.operatorCount,
    this.lastMaintenanceDate,
    this.machines = const [],
  });

  factory ProductionLineItem.fromJson(Map<String, dynamic> json) {
    final rawMachines = json['machines'] as List<dynamic>? ?? [];
    return ProductionLineItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Line',
      code: json['code'] as String? ?? 'LINE-00',
      department: json['department'] as String? ?? 'General Production',
      status: json['status'] as String? ?? 'RUNNING',
      statusDisplay: json['status_display'] as String? ?? json['status'] ?? 'Running',
      currentProduct: json['current_product'] as String? ?? '',
      efficiencyRate: (json['efficiency_rate'] as num?)?.toDouble() ?? 0.0,
      targetHourlyUnits: json['target_hourly_units'] as int? ?? 100,
      actualHourlyUnits: json['actual_hourly_units'] as int? ?? 0,
      operatorCount: json['operator_count'] as int? ?? 1,
      lastMaintenanceDate: json['last_maintenance_date'] as String?,
      machines: rawMachines
          .map((e) => MachineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'department': department,
    'target_hourly_units': targetHourlyUnits,
    'operator_count': operatorCount,
    'machines': machines.map((m) => m.toJson()).toList(),
  };
}

class MetricSnapshotItem {
  final String id;
  final double overallOee;
  final double availability;
  final double performance;
  final double qualityRate;
  final double energyConsumptionKwh;
  final int activeAlertsCount;
  final int activeShifts;
  final int plannedUnits;
  final int actualUnits;
  final int scrapUnits;
  final String timestamp;

  const MetricSnapshotItem({
    required this.id,
    required this.overallOee,
    required this.availability,
    required this.performance,
    required this.qualityRate,
    required this.energyConsumptionKwh,
    required this.activeAlertsCount,
    required this.activeShifts,
    required this.plannedUnits,
    required this.actualUnits,
    required this.scrapUnits,
    required this.timestamp,
  });

  factory MetricSnapshotItem.fromJson(Map<String, dynamic> json) {
    return MetricSnapshotItem(
      id: json['id'] as String? ?? '',
      overallOee: (json['overall_oee'] as num?)?.toDouble() ?? 0.0,
      availability: (json['availability'] as num?)?.toDouble() ?? 0.0,
      performance: (json['performance'] as num?)?.toDouble() ?? 0.0,
      qualityRate: (json['quality_rate'] as num?)?.toDouble() ?? 0.0,
      energyConsumptionKwh: (json['energy_consumption_kwh'] as num?)?.toDouble() ?? 0.0,
      activeAlertsCount: json['active_alerts_count'] as int? ?? 0,
      activeShifts: json['active_shifts'] as int? ?? 1,
      plannedUnits: json['planned_units'] as int? ?? 0,
      actualUnits: json['actual_units'] as int? ?? 0,
      scrapUnits: json['scrap_units'] as int? ?? 0,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class LinesSummary {
  final int total;
  final int running;
  final int idle;
  final int maintenance;
  final int offline;
  final double averageEfficiency;

  const LinesSummary({
    required this.total,
    required this.running,
    required this.idle,
    required this.maintenance,
    required this.offline,
    required this.averageEfficiency,
  });

  factory LinesSummary.fromJson(Map<String, dynamic> json) {
    return LinesSummary(
      total: json['total'] as int? ?? 0,
      running: json['running'] as int? ?? 0,
      idle: json['idle'] as int? ?? 0,
      maintenance: json['maintenance'] as int? ?? 0,
      offline: json['offline'] as int? ?? 0,
      averageEfficiency: (json['average_efficiency'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ShiftProgress {
  final int plannedUnits;
  final int actualUnits;
  final int scrapUnits;
  final double completionPercentage;
  final String currentShift;

  const ShiftProgress({
    required this.plannedUnits,
    required this.actualUnits,
    required this.scrapUnits,
    required this.completionPercentage,
    required this.currentShift,
  });

  factory ShiftProgress.fromJson(Map<String, dynamic> json) {
    return ShiftProgress(
      plannedUnits: json['planned_units'] as int? ?? 0,
      actualUnits: json['actual_units'] as int? ?? 0,
      scrapUnits: json['scrap_units'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      currentShift: json['current_shift'] as String? ?? 'Day Shift',
    );
  }
}

class AlertsSummary {
  final int critical;
  final int warning;
  final int info;
  final int totalActive;

  const AlertsSummary({
    required this.critical,
    required this.warning,
    required this.info,
    required this.totalActive,
  });

  factory AlertsSummary.fromJson(Map<String, dynamic> json) {
    return AlertsSummary(
      critical: json['critical'] as int? ?? 0,
      warning: json['warning'] as int? ?? 0,
      info: json['info'] as int? ?? 0,
      totalActive: json['total_active'] as int? ?? 0,
    );
  }
}

class FactoryOverviewData {
  final FactoryItem factory;
  final MetricSnapshotItem? metrics;
  final LinesSummary linesSummary;
  final List<ProductionLineItem> productionLines;
  final AlertsSummary alertsSummary;
  final ShiftProgress shiftProgress;

  const FactoryOverviewData({
    required this.factory,
    this.metrics,
    required this.linesSummary,
    required this.productionLines,
    required this.alertsSummary,
    required this.shiftProgress,
  });

  factory FactoryOverviewData.fromJson(Map<String, dynamic> json) {
    final factoryData = json['factory'] as Map<String, dynamic>? ?? {};
    final metricsData = json['metrics'] as Map<String, dynamic>?;
    final linesSummaryData = json['lines_summary'] as Map<String, dynamic>? ?? {};
    final linesListData = (json['production_lines'] as List<dynamic>?) ?? [];
    final alertsData = json['alerts_summary'] as Map<String, dynamic>? ?? {};
    final shiftData = json['shift_progress'] as Map<String, dynamic>? ?? {};

    return FactoryOverviewData(
      factory: FactoryItem.fromJson(factoryData),
      metrics: metricsData != null ? MetricSnapshotItem.fromJson(metricsData) : null,
      linesSummary: LinesSummary.fromJson(linesSummaryData),
      productionLines: linesListData
          .map((e) => ProductionLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      alertsSummary: AlertsSummary.fromJson(alertsData),
      shiftProgress: ShiftProgress.fromJson(shiftData),
    );
  }
}

class AISuggestionResult {
  final String source;
  final String providerName;
  final String disclaimer;
  final bool confirmationRequired;
  final String originalPrompt;
  final Map<String, dynamic> recommendedConfiguration;

  const AISuggestionResult({
    required this.source,
    required this.providerName,
    required this.disclaimer,
    required this.confirmationRequired,
    required this.originalPrompt,
    required this.recommendedConfiguration,
  });

  factory AISuggestionResult.fromJson(Map<String, dynamic> json) {
    return AISuggestionResult(
      source: json['source'] as String? ?? 'RULE_BASED_HEURISTIC',
      providerName: json['provider_name'] as String? ?? 'Heuristic Engine',
      disclaimer: json['disclaimer'] as String? ?? '',
      confirmationRequired: json['confirmation_required'] as bool? ?? true,
      originalPrompt: json['original_prompt'] as String? ?? '',
      recommendedConfiguration: (json['recommended_configuration'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class IndustryTemplate {
  final String id;
  final String title;
  final String industryType;
  final String industryCustom;
  final String description;
  final String icon;
  final Map<String, dynamic> defaults;

  const IndustryTemplate({
    required this.id,
    required this.title,
    required this.industryType,
    required this.industryCustom,
    required this.description,
    required this.icon,
    required this.defaults,
  });

  factory IndustryTemplate.fromJson(Map<String, dynamic> json) {
    return IndustryTemplate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      industryType: json['industry_type'] as String? ?? 'CUSTOM',
      industryCustom: json['industry_custom'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'domain',
      defaults: (json['defaults'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class OnboardingDraftItem {
  final String id;
  final String name;
  final String status;
  final int currentStep;
  final String aiPrompt;
  final Map<String, dynamic> aiSuggestions;
  final Map<String, dynamic> wizardData;
  final String createdAt;
  final String updatedAt;

  const OnboardingDraftItem({
    required this.id,
    required this.name,
    required this.status,
    required this.currentStep,
    this.aiPrompt = '',
    this.aiSuggestions = const {},
    this.wizardData = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnboardingDraftItem.fromJson(Map<String, dynamic> json) {
    return OnboardingDraftItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Draft',
      status: json['status'] as String? ?? 'DRAFT',
      currentStep: json['current_step'] as int? ?? 1,
      aiPrompt: json['ai_prompt'] as String? ?? '',
      aiSuggestions: (json['ai_suggestions'] as Map<String, dynamic>?) ?? {},
      wizardData: (json['wizard_data'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'current_step': currentStep,
    'ai_prompt': aiPrompt,
    'ai_suggestions': aiSuggestions,
    'wizard_data': wizardData,
  };
}
