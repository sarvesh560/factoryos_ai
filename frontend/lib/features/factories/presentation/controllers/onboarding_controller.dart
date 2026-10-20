/// FactoryOS AI — Universal Onboarding Controller
/// Phase 2: Universal Manufacturing Onboarding
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/factory_controller.dart';
import '../../data/models/factory_model.dart';
import '../../data/repositories/factory_repository.dart';

class OnboardingState {
  final int currentStep;
  final bool isLoading;
  final bool isAiLoading;
  final bool isDraftSaving;
  final String? errorMessage;
  final String? successMessage;
  final AISuggestionResult? aiSuggestion;
  final List<IndustryTemplate> templates;
  final List<CompanyItem> availableCompanies;
  final List<OnboardingDraftItem> savedDrafts;

  // Active Draft Session Pointer
  final String? draftId;
  final String? draftName;

  // Step 1: Company
  final String? selectedCompanyId;
  final String companyName;
  final String companyDescription;
  final String companyWebsite;
  final String companyEmail;

  // Step 2: Factory
  final String factoryName;
  final String factoryCode;
  final String industryType;
  final String industryCustom;
  final String factoryType;
  final String manufacturingModel;
  final String complianceStandard;
  final String cleanroomGrade;
  final String location;
  final String country;
  final String timezone;
  final String operatingHours;
  final List<String> capabilities;
  final int targetDailyCapacity;

  // Step 3: Products
  final List<ProductModel> products;

  // Step 4: Raw Materials
  final List<RawMaterialModel> rawMaterials;

  // Step 5: Process Stages
  final List<ProcessStageModel> processStages;

  // Step 6: Production Lines
  final List<ProductionLineItem> productionLines;

  // Step 7: Shifts
  final List<ShiftModel> shifts;

  const OnboardingState({
    this.currentStep = 1,
    this.isLoading = false,
    this.isAiLoading = false,
    this.isDraftSaving = false,
    this.errorMessage,
    this.successMessage,
    this.aiSuggestion,
    this.templates = const [],
    this.availableCompanies = const [],
    this.savedDrafts = const [],
    this.draftId,
    this.draftName,
    this.selectedCompanyId,
    this.companyName = '',
    this.companyDescription = '',
    this.companyWebsite = '',
    this.companyEmail = '',
    this.factoryName = '',
    this.factoryCode = '',
    this.industryType = 'AUTOMOTIVE',
    this.industryCustom = '',
    this.factoryType = 'PRIMARY_MANUFACTURING',
    this.manufacturingModel = 'DISCRETE',
    this.complianceStandard = 'IATF 16949:2016 / APQP',
    this.cleanroomGrade = 'Standard Industrial (Non-Cleanroom)',
    this.location = 'North American High-Tech Corridor',
    this.country = 'USA',
    this.timezone = 'America/New_York',
    this.operatingHours = '06:00 - 22:00 (Two 8h Shifts)',
    this.capabilities = const ['Precision Machining', 'Inline Quality Gate'],
    this.targetDailyCapacity = 3000,
    this.products = const [],
    this.rawMaterials = const [],
    this.processStages = const [],
    this.productionLines = const [],
    this.shifts = const [],
  });

  OnboardingState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isAiLoading,
    bool? isDraftSaving,
    String? errorMessage,
    String? successMessage,
    AISuggestionResult? aiSuggestion,
    List<IndustryTemplate>? templates,
    List<CompanyItem>? availableCompanies,
    List<OnboardingDraftItem>? savedDrafts,
    String? draftId,
    String? draftName,
    bool clearDraft = false,
    String? selectedCompanyId,
    String? companyName,
    String? companyDescription,
    String? companyWebsite,
    String? companyEmail,
    String? factoryName,
    String? factoryCode,
    String? industryType,
    String? industryCustom,
    String? factoryType,
    String? manufacturingModel,
    String? complianceStandard,
    String? cleanroomGrade,
    String? location,
    String? country,
    String? timezone,
    String? operatingHours,
    List<String>? capabilities,
    int? targetDailyCapacity,
    List<ProductModel>? products,
    List<RawMaterialModel>? rawMaterials,
    List<ProcessStageModel>? processStages,
    List<ProductionLineItem>? productionLines,
    List<ShiftModel>? shifts,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      isDraftSaving: isDraftSaving ?? this.isDraftSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      templates: templates ?? this.templates,
      availableCompanies: availableCompanies ?? this.availableCompanies,
      savedDrafts: savedDrafts ?? this.savedDrafts,
      draftId: clearDraft ? null : (draftId ?? this.draftId),
      draftName: clearDraft ? null : (draftName ?? this.draftName),
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyEmail: companyEmail ?? this.companyEmail,
      factoryName: factoryName ?? this.factoryName,
      factoryCode: factoryCode ?? this.factoryCode,
      industryType: industryType ?? this.industryType,
      industryCustom: industryCustom ?? this.industryCustom,
      factoryType: factoryType ?? this.factoryType,
      manufacturingModel: manufacturingModel ?? this.manufacturingModel,
      complianceStandard: complianceStandard ?? this.complianceStandard,
      cleanroomGrade: cleanroomGrade ?? this.cleanroomGrade,
      location: location ?? this.location,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      operatingHours: operatingHours ?? this.operatingHours,
      capabilities: capabilities ?? this.capabilities,
      targetDailyCapacity: targetDailyCapacity ?? this.targetDailyCapacity,
      products: products ?? this.products,
      rawMaterials: rawMaterials ?? this.rawMaterials,
      processStages: processStages ?? this.processStages,
      productionLines: productionLines ?? this.productionLines,
      shifts: shifts ?? this.shifts,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  late final FactoryRepository _repository;

  @override
  OnboardingState build() {
    _repository = ref.watch(factoryRepositoryProvider);
    Future.microtask(() => _initialize());
    return const OnboardingState();
  }

  Future<void> _initialize() async {
    try {
      final companies = await _repository.getCompanies();
      final templates = await _repository.getIndustryTemplates();
      final drafts = await _repository.getOnboardingDrafts();
      state = state.copyWith(
        availableCompanies: companies,
        templates: templates,
        savedDrafts: drafts,
        companyName: companies.isNotEmpty ? companies.first.name : 'Apex Global Holding',
        selectedCompanyId: companies.isNotEmpty ? companies.first.id : null,
      );
      // Auto-load automotive template defaults for initial starting state
      if (templates.isNotEmpty) {
        applyTemplate(templates.first);
      }
    } catch (_) {}
  }

  void setStep(int step) {
    if (step >= 1 && step <= 8) {
      state = state.copyWith(currentStep: step, errorMessage: null);
    }
  }

  /// Client-side step validator
  String? validateStep(int step) {
    if (step == 1) {
      if (state.companyName.trim().isEmpty) {
        return 'Enterprise company name is required to proceed.';
      }
    } else if (step == 2) {
      if (state.factoryName.trim().isEmpty) {
        return 'Manufacturing facility name is required to proceed.';
      }
      // Check for duplicate factory within selected company
      if (state.selectedCompanyId != null) {
        final existingOrg = state.availableCompanies.where((c) => c.id == state.selectedCompanyId).firstOrNull;
        if (existingOrg != null) {
          final isDup = existingOrg.factories.any(
            (f) => f.name.trim().toLowerCase() == state.factoryName.trim().toLowerCase(),
          );
          if (isDup) {
            return 'A factory named "${state.factoryName.trim()}" already exists in ${existingOrg.name}. Please specify a unique name.';
          }
        }
      }
    }
    return null;
  }

  bool nextStep() {
    final validationError = validateStep(state.currentStep);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    if (state.currentStep < 8) {
      setStep(state.currentStep + 1);
      return true;
    }
    return true;
  }

  void previousStep() {
    if (state.currentStep > 1) {
      setStep(state.currentStep - 1);
    }
  }

  void selectCompany(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      state = state.copyWith(selectedCompanyId: null);
      return;
    }
    final comp = state.availableCompanies.firstWhere(
      (c) => c.id == companyId,
      orElse: () => const CompanyItem(id: '', name: '', slug: '', description: '', website: '', contactEmail: '', isActive: true, factoryCount: 0),
    );
    state = state.copyWith(
      selectedCompanyId: companyId,
      companyName: comp.name,
      companyDescription: comp.description,
      companyWebsite: comp.website,
      companyEmail: comp.contactEmail,
    );
  }

  void updateCompanyInfo({
    String? name,
    String? description,
    String? website,
    String? email,
  }) {
    state = state.copyWith(
      companyName: name ?? state.companyName,
      companyDescription: description ?? state.companyDescription,
      companyWebsite: website ?? state.companyWebsite,
      companyEmail: email ?? state.companyEmail,
    );
  }

  void updateFactoryInfo({
    String? name,
    String? code,
    String? industryType,
    String? industryCustom,
    String? factoryType,
    String? manufacturingModel,
    String? complianceStandard,
    String? cleanroomGrade,
    String? location,
    String? country,
    String? timezone,
    String? operatingHours,
    int? targetDailyCapacity,
  }) {
    // When industry changes, conditionally populate industry defaults if not explicitly passed
    String? newModel = manufacturingModel;
    String? newStd = complianceStandard;
    String? newClean = cleanroomGrade;

    if (industryType != null && industryType != state.industryType) {
      switch (industryType) {
        case 'AUTOMOTIVE':
          newModel ??= 'DISCRETE';
          newStd ??= 'IATF 16949:2016 / APQP';
          newClean ??= 'Standard Industrial (Non-Cleanroom)';
        case 'ELECTRONICS':
          newModel ??= 'REPETITIVE';
          newStd ??= 'IPC-A-610 Class 3 / RoHS';
          newClean ??= 'ISO 14644 Class 7 Cleanroom';
        case 'PHARMACEUTICALS':
          newModel ??= 'BATCH';
          newStd ??= 'FDA cGMP / 21 CFR Part 11';
          newClean ??= 'ISO 14644 Class 5 Cleanroom';
        case 'FOOD_PROCESSING':
          newModel ??= 'BATCH';
          newStd ??= 'HACCP / FDA FSMA / BRCGS';
          newClean ??= 'Sanitation Zone 1 (High Hygiene)';
        case 'TEXTILE':
          newModel ??= 'REPETITIVE';
          newStd ??= 'OEKO-TEX Standard 100 / ISO 9001';
          newClean ??= 'Controlled Humidity Weaving Hall';
        case 'AEROSPACE':
          newModel ??= 'DISCRETE';
          newStd ??= 'AS9100 Rev D / NADCAP';
          newClean ??= 'ISO 14644 Class 8 Cleanroom';
        case 'CNC_ENGINEERING':
          newModel ??= 'JOB_SHOP';
          newStd ??= 'ISO 9001:2015 Precision Machining';
          newClean ??= 'Temperature-Controlled Inspection Bay';
        case 'CHEMICALS':
          newModel ??= 'CONTINUOUS';
          newStd ??= 'OSHA Process Safety (PSM) / REACH';
          newClean ??= 'ATEX / Explosion-Proof Enclosure';
        default:
          newModel ??= 'JOB_SHOP';
          newStd ??= 'ISO 9001 Quality Management';
          newClean ??= 'Standard Industrial';
      }
    }

    state = state.copyWith(
      factoryName: name ?? state.factoryName,
      factoryCode: code ?? state.factoryCode,
      industryType: industryType ?? state.industryType,
      industryCustom: industryCustom ?? state.industryCustom,
      factoryType: factoryType ?? state.factoryType,
      manufacturingModel: newModel ?? state.manufacturingModel,
      complianceStandard: newStd ?? state.complianceStandard,
      cleanroomGrade: newClean ?? state.cleanroomGrade,
      location: location ?? state.location,
      country: country ?? state.country,
      timezone: timezone ?? state.timezone,
      operatingHours: operatingHours ?? state.operatingHours,
      targetDailyCapacity: targetDailyCapacity ?? state.targetDailyCapacity,
    );
  }

  void addCapability(String cap) {
    if (cap.trim().isEmpty) return;
    final updated = List<String>.from(state.capabilities);
    if (!updated.contains(cap.trim())) {
      updated.add(cap.trim());
      state = state.copyWith(capabilities: updated);
    }
  }

  void removeCapability(String cap) {
    final updated = List<String>.from(state.capabilities)..remove(cap);
    state = state.copyWith(capabilities: updated);
  }

  // Products
  void addProduct(ProductModel product) {
    state = state.copyWith(products: [...state.products, product]);
  }

  void removeProduct(int index) {
    if (index >= 0 && index < state.products.length) {
      final updated = List<ProductModel>.from(state.products)..removeAt(index);
      state = state.copyWith(products: updated);
    }
  }

  // Raw Materials
  void addRawMaterial(RawMaterialModel material) {
    state = state.copyWith(rawMaterials: [...state.rawMaterials, material]);
  }

  void removeRawMaterial(int index) {
    if (index >= 0 && index < state.rawMaterials.length) {
      final updated = List<RawMaterialModel>.from(state.rawMaterials)..removeAt(index);
      state = state.copyWith(rawMaterials: updated);
    }
  }

  // Process Stages
  void addProcessStage(ProcessStageModel stage) {
    state = state.copyWith(processStages: [...state.processStages, stage]);
  }

  void removeProcessStage(int index) {
    if (index >= 0 && index < state.processStages.length) {
      final updated = List<ProcessStageModel>.from(state.processStages)..removeAt(index);
      // Re-index sequences
      for (int i = 0; i < updated.length; i++) {
        updated[i] = ProcessStageModel(
          id: updated[i].id,
          name: updated[i].name,
          sequence: i + 1,
          description: updated[i].description,
          cycleTimeSeconds: updated[i].cycleTimeSeconds,
          qualityCheckRequired: updated[i].qualityCheckRequired,
        );
      }
      state = state.copyWith(processStages: updated);
    }
  }

  // Production Lines
  void addProductionLine(ProductionLineItem line) {
    state = state.copyWith(productionLines: [...state.productionLines, line]);
  }

  void removeProductionLine(int index) {
    if (index >= 0 && index < state.productionLines.length) {
      final updated = List<ProductionLineItem>.from(state.productionLines)..removeAt(index);
      state = state.copyWith(productionLines: updated);
    }
  }

  void addMachineToLine(int lineIndex, MachineModel machine) {
    if (lineIndex >= 0 && lineIndex < state.productionLines.length) {
      final lines = List<ProductionLineItem>.from(state.productionLines);
      final target = lines[lineIndex];
      lines[lineIndex] = ProductionLineItem(
        id: target.id,
        name: target.name,
        code: target.code,
        department: target.department,
        status: target.status,
        statusDisplay: target.statusDisplay,
        currentProduct: target.currentProduct,
        efficiencyRate: target.efficiencyRate,
        targetHourlyUnits: target.targetHourlyUnits,
        actualHourlyUnits: target.actualHourlyUnits,
        operatorCount: target.operatorCount,
        machines: [...target.machines, machine],
      );
      state = state.copyWith(productionLines: lines);
    }
  }

  // Shifts
  void addShift(ShiftModel shift) {
    state = state.copyWith(shifts: [...state.shifts, shift]);
  }

  void removeShift(int index) {
    if (index >= 0 && index < state.shifts.length) {
      final updated = List<ShiftModel>.from(state.shifts)..removeAt(index);
      state = state.copyWith(shifts: updated);
    }
  }

  // Template Application
  void applyTemplate(IndustryTemplate template) {
    final d = template.defaults;
    final fName = d['factory_name'] as String? ?? 'New Facility';
    final codePref = d['code_prefix'] as String? ?? 'FAC';
    final fType = d['factory_type'] as String? ?? 'PRIMARY_MANUFACTURING';
    final mModel = d['manufacturing_model'] as String? ?? 'DISCRETE';
    final loc = d['location'] as String? ?? 'Industrial District';
    final hours = d['operating_hours'] as String? ?? '06:00 - 22:00';
    final capacity = d['target_daily_capacity'] as int? ?? 3000;
    final caps = (d['capabilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    final rawProds = (d['products'] as List<dynamic>?) ?? [];
    final prods = rawProds.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();

    final rawMats = (d['raw_materials'] as List<dynamic>?) ?? [];
    final mats = rawMats.map((e) => RawMaterialModel.fromJson(e as Map<String, dynamic>)).toList();

    final rawStages = (d['process_stages'] as List<dynamic>?) ?? [];
    final stages = rawStages.map((e) => ProcessStageModel.fromJson(e as Map<String, dynamic>)).toList();

    final rawLines = (d['production_lines'] as List<dynamic>?) ?? [];
    final lines = rawLines.map((e) => ProductionLineItem.fromJson(e as Map<String, dynamic>)).toList();

    final rawShifts = (d['shifts'] as List<dynamic>?) ?? [];
    final shifts = rawShifts.map((e) => ShiftModel.fromJson(e as Map<String, dynamic>)).toList();

    state = state.copyWith(
      factoryName: fName,
      factoryCode: 'FAC-$codePref-01',
      industryType: template.industryType,
      industryCustom: template.industryCustom,
      factoryType: fType,
      manufacturingModel: mModel,
      location: loc,
      operatingHours: hours,
      targetDailyCapacity: capacity,
      capabilities: caps,
      products: prods,
      rawMaterials: mats,
      processStages: stages,
      productionLines: lines,
      shifts: shifts,
      successMessage: "Applied '${template.title}' template.",
    );
  }

  // Request AI Recommendation
  Future<void> requestAISuggestion(String prompt) async {
    if (prompt.trim().isEmpty) return;
    state = state.copyWith(isAiLoading: true, errorMessage: null);

    try {
      final result = await _repository.getAISuggestion(prompt);
      state = state.copyWith(
        isAiLoading: false,
        aiSuggestion: result,
      );
    } catch (e) {
      state = state.copyWith(
        isAiLoading: false,
        errorMessage: 'AI Advisor request failed: $e',
      );
    }
  }

  // User explicitly confirms applying AI suggestions
  void confirmAndApplyAISuggestion() {
    final sug = state.aiSuggestion;
    if (sug == null) return;

    final cfg = sug.recommendedConfiguration;
    final f = (cfg['factory'] as Map<String, dynamic>?) ?? {};
    final rawProds = (cfg['products'] as List<dynamic>?) ?? [];
    final rawMats = (cfg['raw_materials'] as List<dynamic>?) ?? [];
    final rawStages = (cfg['process_stages'] as List<dynamic>?) ?? [];
    final rawLines = (cfg['production_lines'] as List<dynamic>?) ?? [];
    final rawShifts = (cfg['shifts'] as List<dynamic>?) ?? [];

    final caps = (f['capabilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? state.capabilities;

    state = state.copyWith(
      factoryName: f['name'] as String? ?? state.factoryName,
      factoryCode: f['code'] as String? ?? state.factoryCode,
      industryType: f['industry_type'] as String? ?? state.industryType,
      industryCustom: f['industry_custom'] as String? ?? state.industryCustom,
      factoryType: f['factory_type'] as String? ?? state.factoryType,
      manufacturingModel: f['manufacturing_model'] as String? ?? state.manufacturingModel,
      location: f['location'] as String? ?? state.location,
      operatingHours: f['operating_hours'] as String? ?? state.operatingHours,
      targetDailyCapacity: f['target_daily_capacity'] as int? ?? state.targetDailyCapacity,
      capabilities: caps,
      products: rawProds.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
      rawMaterials: rawMats.map((e) => RawMaterialModel.fromJson(e as Map<String, dynamic>)).toList(),
      processStages: rawStages.map((e) => ProcessStageModel.fromJson(e as Map<String, dynamic>)).toList(),
      productionLines: rawLines.map((e) => ProductionLineItem.fromJson(e as Map<String, dynamic>)).toList(),
      shifts: rawShifts.map((e) => ShiftModel.fromJson(e as Map<String, dynamic>)).toList(),
      successMessage: 'AI suggestions verified and applied to wizard successfully!',
    );
  }

  // ==========================================
  // DRAFT SAVING & RESUMING
  // ==========================================

  Map<String, dynamic> _buildWizardPayload() {
    return <String, dynamic>{
      'company': {
        if (state.selectedCompanyId != null) 'id': state.selectedCompanyId,
        'name': state.companyName.isNotEmpty ? state.companyName : 'Enterprise Holdings',
        'description': state.companyDescription,
        'website': state.companyWebsite,
        'contact_email': state.companyEmail,
      },
      'factory': {
        'name': state.factoryName.isNotEmpty ? state.factoryName : 'New Manufacturing Facility',
        'code': state.factoryCode,
        'industry_type': state.industryType,
        'industry_custom': state.industryCustom,
        'factory_type': state.factoryType,
        'manufacturing_model': state.manufacturingModel,
        'compliance_standard': state.complianceStandard,
        'cleanroom_grade': state.cleanroomGrade,
        'location': state.location,
        'country': state.country,
        'timezone': state.timezone,
        'operating_hours': state.operatingHours,
        'capabilities': state.capabilities,
        'target_daily_capacity': state.targetDailyCapacity,
      },
      'products': state.products.map((p) => p.toJson()).toList(),
      'raw_materials': state.rawMaterials.map((m) => m.toJson()).toList(),
      'process_stages': state.processStages.map((s) => s.toJson()).toList(),
      'production_lines': state.productionLines.map((l) => l.toJson()).toList(),
      'shifts': state.shifts.map((s) => s.toJson()).toList(),
    };
  }

  Future<void> fetchSavedDrafts() async {
    try {
      final drafts = await _repository.getOnboardingDrafts();
      state = state.copyWith(savedDrafts: drafts);
    } catch (_) {}
  }

  Future<bool> saveCurrentAsDraft({String? draftName}) async {
    state = state.copyWith(isDraftSaving: true, errorMessage: null, successMessage: null);

    final resolvedName = draftName?.trim().isNotEmpty == true
        ? draftName!.trim()
        : (state.factoryName.trim().isNotEmpty
            ? state.factoryName.trim()
            : 'Draft Factory (${state.industryType})');

    try {
      final savedDraft = await _repository.saveOnboardingDraft(
        id: state.draftId,
        name: resolvedName,
        currentStep: state.currentStep,
        aiPrompt: state.aiSuggestion?.originalPrompt ?? '',
        aiSuggestions: state.aiSuggestion?.recommendedConfiguration ?? {},
        wizardData: _buildWizardPayload(),
      );

      state = state.copyWith(
        isDraftSaving: false,
        draftId: savedDraft.id,
        draftName: savedDraft.name,
        successMessage: 'Progress saved as draft "${savedDraft.name}" (Step ${state.currentStep}).',
      );
      await fetchSavedDrafts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isDraftSaving: false,
        errorMessage: 'Failed to save draft: $e',
      );
      return false;
    }
  }

  Future<bool> loadSavedDraft(String draftId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final draft = await _repository.getOnboardingDraft(draftId);
      final wz = draft.wizardData;

      final comp = (wz['company'] as Map<String, dynamic>?) ?? {};
      final fac = (wz['factory'] as Map<String, dynamic>?) ?? {};
      final rawProds = (wz['products'] as List<dynamic>?) ?? [];
      final rawMats = (wz['raw_materials'] as List<dynamic>?) ?? [];
      final rawStages = (wz['process_stages'] as List<dynamic>?) ?? [];
      final rawLines = (wz['production_lines'] as List<dynamic>?) ?? [];
      final rawShifts = (wz['shifts'] as List<dynamic>?) ?? [];

      final caps = (fac['capabilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      state = state.copyWith(
        isLoading: false,
        draftId: draft.id,
        draftName: draft.name,
        currentStep: draft.currentStep.clamp(1, 8),
        selectedCompanyId: comp['id'] as String?,
        companyName: comp['name'] as String? ?? '',
        companyDescription: comp['description'] as String? ?? '',
        companyWebsite: comp['website'] as String? ?? '',
        companyEmail: comp['contact_email'] as String? ?? '',
        factoryName: fac['name'] as String? ?? '',
        factoryCode: fac['code'] as String? ?? '',
        industryType: fac['industry_type'] as String? ?? 'AUTOMOTIVE',
        industryCustom: fac['industry_custom'] as String? ?? '',
        factoryType: fac['factory_type'] as String? ?? 'PRIMARY_MANUFACTURING',
        manufacturingModel: fac['manufacturing_model'] as String? ?? 'DISCRETE',
        complianceStandard: fac['compliance_standard'] as String? ?? 'IATF 16949:2016 / APQP',
        cleanroomGrade: fac['cleanroom_grade'] as String? ?? 'Standard Industrial (Non-Cleanroom)',
        location: fac['location'] as String? ?? '',
        country: fac['country'] as String? ?? 'USA',
        timezone: fac['timezone'] as String? ?? 'UTC',
        operatingHours: fac['operating_hours'] as String? ?? '06:00 - 22:00 (Two 8h Shifts)',
        capabilities: caps,
        targetDailyCapacity: fac['target_daily_capacity'] as int? ?? 3000,
        products: rawProds.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
        rawMaterials: rawMats.map((e) => RawMaterialModel.fromJson(e as Map<String, dynamic>)).toList(),
        processStages: rawStages.map((e) => ProcessStageModel.fromJson(e as Map<String, dynamic>)).toList(),
        productionLines: rawLines.map((e) => ProductionLineItem.fromJson(e as Map<String, dynamic>)).toList(),
        shifts: rawShifts.map((e) => ShiftModel.fromJson(e as Map<String, dynamic>)).toList(),
        successMessage: 'Loaded saved draft "${draft.name}" at Step ${draft.currentStep}.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load draft: $e',
      );
      return false;
    }
  }

  Future<void> deleteSavedDraft(String draftId) async {
    try {
      await _repository.deleteOnboardingDraft(draftId);
      if (state.draftId == draftId) {
        state = state.copyWith(clearDraft: true);
      }
      await fetchSavedDrafts();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete draft: $e');
    }
  }

  void startNewDraft() {
    state = state.copyWith(
      clearDraft: true,
      currentStep: 1,
      factoryName: '',
      factoryCode: '',
      products: [],
      rawMaterials: [],
      processStages: [],
      productionLines: [],
      shifts: [],
      successMessage: 'Started a fresh onboarding session.',
    );
  }

  // ==========================================
  // ATOMIC PRODUCTION ACTIVATION
  // ==========================================

  Future<FactoryItem?> activateFactory() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    try {
      final wizardPayload = _buildWizardPayload();

      final createdFactory = await _repository.activateOnboarding(
        wizardData: wizardPayload,
        draftId: state.draftId,
      );

      state = state.copyWith(
        isLoading: false,
        clearDraft: true,
        successMessage: "Factory '${createdFactory.name}' is now LIVE in production!",
      );

      // Refresh factory switcher and switch active factory
      ref.read(factoryControllerProvider.notifier).refreshCurrentFactory();

      return createdFactory;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Activation failed: $e',
      );
      return null;
    }
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() => OnboardingNotifier());
