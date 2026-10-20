/// FactoryOS AI — Process Library Controller
/// Phase 3: Process Definition Catalog, Search & New Workflow Modal
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class ProcessLibraryState {
  final List<ProcessDefinitionItem> definitions;
  final List<ProcessTemplateItem> templates;
  final bool isLoading;
  final bool isLoadingTemplates;
  final String? errorMessage;
  final String? successMessage;
  final String searchQuery;
  final String? selectedIndustry;
  final String? selectedCategory;
  final String selectedStatus; // 'ALL', 'PUBLISHED', 'DRAFT', 'ARCHIVED'

  const ProcessLibraryState({
    this.definitions = const [],
    this.templates = const [],
    this.isLoading = false,
    this.isLoadingTemplates = false,
    this.errorMessage,
    this.successMessage,
    this.searchQuery = '',
    this.selectedIndustry,
    this.selectedCategory,
    this.selectedStatus = 'ALL',
  });

  ProcessLibraryState copyWith({
    List<ProcessDefinitionItem>? definitions,
    List<ProcessTemplateItem>? templates,
    bool? isLoading,
    bool? isLoadingTemplates,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? searchQuery,
    String? selectedIndustry,
    bool clearIndustry = false,
    String? selectedCategory,
    bool clearCategory = false,
    String? selectedStatus,
  }) {
    return ProcessLibraryState(
      definitions: definitions ?? this.definitions,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTemplates: isLoadingTemplates ?? this.isLoadingTemplates,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIndustry: clearIndustry ? null : (selectedIndustry ?? this.selectedIndustry),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }

  /// Filtered definitions based on active search and filter state
  List<ProcessDefinitionItem> get filteredDefinitions {
    return definitions.where((proc) {
      // 1. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchName = proc.name.toLowerCase().contains(q);
        final matchCode = proc.code.toLowerCase().contains(q);
        if (!matchName && !matchCode) return false;
      }

      // 2. Industry filter
      if (selectedIndustry != null && selectedIndustry!.isNotEmpty) {
        if (proc.industryType != selectedIndustry) return false;
      }

      // 3. Category filter
      if (selectedCategory != null && selectedCategory!.isNotEmpty) {
        if (proc.category != selectedCategory) return false;
      }

      // 4. Status filter: ALL, PUBLISHED, DRAFT, ARCHIVED
      switch (selectedStatus.toUpperCase()) {
        case 'PUBLISHED':
          if (!proc.isActive || proc.publishedVersionTag == null) return false;
          break;
        case 'DRAFT':
          if (!proc.isActive || proc.publishedVersionTag != null) return false;
          break;
        case 'ARCHIVED':
          if (proc.isActive) return false;
          break;
        case 'ALL':
        default:
          // In ALL view, show active workflows by default unless explicitly searching
          break;
      }

      return true;
    }).toList();
  }
}

class ProcessLibraryNotifier extends Notifier<ProcessLibraryState> {
  late final ProcessRepository _repository;

  @override
  ProcessLibraryState build() {
    _repository = ref.watch(processRepositoryProvider);
    Future.microtask(() {
      loadDefinitions();
      loadTemplates();
    });
    return const ProcessLibraryState(isLoading: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setIndustryFilter(String? industry) {
    if (industry == null) {
      state = state.copyWith(clearIndustry: true);
    } else {
      state = state.copyWith(selectedIndustry: industry);
    }
  }

  void setCategoryFilter(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearIndustry: true,
      clearCategory: true,
      selectedStatus: 'ALL',
      clearError: true,
    );
  }

  Future<void> loadDefinitions({String? factoryId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getProcessDefinitions(factoryId: factoryId);
      state = state.copyWith(definitions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load process library: $e',
      );
    }
  }

  Future<void> loadTemplates({String? industryType, String? category}) async {
    state = state.copyWith(isLoadingTemplates: true);
    try {
      final templates = await _repository.getTemplates(
        industryType: industryType,
        category: category,
      );
      state = state.copyWith(templates: templates, isLoadingTemplates: false);
    } catch (e) {
      state = state.copyWith(isLoadingTemplates: false);
    }
  }

  Future<String?> createDefinition({
    required String factoryId,
    required String name,
    required String code,
    String description = '',
    String category = 'General Manufacturing',
    double targetCycleTimeSeconds = 60.0,
  }) async {
    try {
      final payload = {
        'factory': factoryId,
        'name': name,
        'code': code,
        'description': description,
        'category': category,
        'target_cycle_time_seconds': targetCycleTimeSeconds,
      };
      final created = await _repository.createProcessDefinition(payload);
      state = state.copyWith(
        successMessage: "Process workflow '${created.name}' created.",
        clearError: true,
      );
      await loadDefinitions(factoryId: factoryId);
      return created.id;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create process workflow: $e');
      return null;
    }
  }

  Future<ProcessDefinitionItem?> instantiateTemplate({
    required String templateKey,
    required String factoryId,
    String? name,
    String? code,
    String? description,
    double? targetCycleTimeSeconds,
  }) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    try {
      final payload = <String, dynamic>{
        'factory': factoryId,
        'factory_id': factoryId,
      };
      if (name != null && name.trim().isNotEmpty) payload['name'] = name.trim();
      if (code != null && code.trim().isNotEmpty) payload['code'] = code.trim().toUpperCase();
      if (description != null && description.trim().isNotEmpty) payload['description'] = description.trim();
      if (targetCycleTimeSeconds != null) payload['target_cycle_time_seconds'] = targetCycleTimeSeconds;

      final created = await _repository.instantiateTemplate(templateKey, payload);
      state = state.copyWith(
        successMessage: "Process '${created.name}' instantiated from template.",
        clearError: true,
      );
      await loadDefinitions(factoryId: factoryId);
      return created;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to instantiate template: $e');
      rethrow;
    }
  }

  Future<ProcessDefinitionItem?> duplicateDefinition({
    required String id,
    String? name,
    String? code,
    String? description,
    String? factoryId,
  }) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    try {
      final duplicated = await _repository.duplicateProcess(
        id,
        name: name,
        code: code,
        description: description,
      );
      state = state.copyWith(
        successMessage: "Process '${duplicated.name}' duplicated successfully.",
        clearError: true,
      );
      await loadDefinitions(factoryId: factoryId);
      return duplicated;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to duplicate process: $e');
      rethrow;
    }
  }

  Future<bool> archiveDefinition(String id, {String? factoryId}) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    try {
      final archived = await _repository.archiveProcess(id);
      state = state.copyWith(
        successMessage: "Process '${archived.name}' safely archived.",
        clearError: true,
      );
      await loadDefinitions(factoryId: factoryId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to archive process: $e');
      rethrow;
    }
  }
}

final processLibraryControllerProvider =
    NotifierProvider<ProcessLibraryNotifier, ProcessLibraryState>(() => ProcessLibraryNotifier());
