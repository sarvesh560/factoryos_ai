import '../../../../core/api/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../models/factory_model.dart';

class FactoryRepository {
  final ApiClient _apiClient;

  FactoryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==========================================
  // FACTORIES
  // ==========================================

  /// Retrieve list of factories from Django backend
  Future<List<FactoryItem>> getFactories({
    String? industryType,
    String? status,
    String? search,
    bool includeArchived = false,
  }) async {
    final query = <String, dynamic>{};
    if (industryType != null && industryType.isNotEmpty) {
      query['industry_type'] = industryType;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    if (includeArchived) {
      query['include_archived'] = 'true';
    }

    final data = await _apiClient.get(
      AppConfig.factoriesEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => FactoryItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Retrieve full operational overview for a factory
  Future<FactoryOverviewData> getFactoryOverview(String factoryId) async {
    final data = await _apiClient.get(
      AppConfig.factoryOverviewEndpoint(factoryId),
    );

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return FactoryOverviewData.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Malformed factory overview response from server.');
  }

  /// Archive or unarchive a factory
  Future<FactoryItem> archiveFactory(String factoryId) async {
    final data = await _apiClient.post(
      AppConfig.factoryArchiveEndpoint(factoryId),
      data: {},
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return FactoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle factory archive state.');
  }

  /// Update factory details (capabilities, hours, location)
  Future<FactoryItem> updateFactory(String factoryId, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch(
      AppConfig.factoryDetailEndpoint(factoryId),
      data: payload,
    );
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return FactoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update factory details.');
  }

  // ==========================================
  // COMPANIES (ORGANIZATIONS)
  // ==========================================

  /// Retrieve list of companies
  Future<List<CompanyItem>> getCompanies({bool includeArchived = false}) async {
    final query = <String, dynamic>{};
    if (includeArchived) {
      query['include_archived'] = 'true';
    }

    final data = await _apiClient.get(
      AppConfig.companiesEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => CompanyItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Create a new enterprise company
  Future<CompanyItem> createCompany({
    required String name,
    String description = '',
    String website = '',
    String contactEmail = '',
  }) async {
    final data = await _apiClient.post(
      AppConfig.companiesEndpoint,
      data: {
        'name': name,
        'description': description,
        'website': website,
        'contact_email': contactEmail,
      },
    );

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return CompanyItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create company.');
  }

  /// Update an existing company
  Future<CompanyItem> updateCompany(String companyId, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch(
      AppConfig.companyDetailEndpoint(companyId),
      data: payload,
    );

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return CompanyItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update company.');
  }

  /// Archive or unarchive a company
  Future<CompanyItem> archiveCompany(String companyId) async {
    final data = await _apiClient.post(
      AppConfig.companyArchiveEndpoint(companyId),
      data: {},
    );

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return CompanyItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle company archive state.');
  }

  // ==========================================
  // UNIVERSAL ONBOARDING & AI ADVISOR
  // ==========================================

  /// Request AI-assisted manufacturing onboarding suggestion
  Future<AISuggestionResult> getAISuggestion(String prompt) async {
    final data = await _apiClient.post(
      AppConfig.aiSuggestEndpoint,
      data: {'prompt': prompt},
    );

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return AISuggestionResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to generate AI suggestion from server.');
  }

  /// Retrieve list of starting industry templates
  Future<List<IndustryTemplate>> getIndustryTemplates() async {
    final data = await _apiClient.get(AppConfig.onboardingTemplatesEndpoint);

    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => IndustryTemplate.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Atomically activate factory into production
  Future<FactoryItem> activateOnboarding({
    required Map<String, dynamic> wizardData,
    String? draftId,
  }) async {
    final payload = <String, dynamic>{
      'wizard_data': wizardData,
      if (draftId != null && draftId.isNotEmpty) 'draft_id': draftId,
    };

    final data = await _apiClient.post(
      AppConfig.onboardingActivateEndpoint,
      data: payload,
    );

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return FactoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data is Map ? (data['message'] ?? 'Failed to activate factory.') : 'Activation error');
  }

  /// Retrieve all saved onboarding drafts
  Future<List<OnboardingDraftItem>> getOnboardingDrafts() async {
    final data = await _apiClient.get(AppConfig.onboardingDraftsEndpoint);
    if (data is Map<String, dynamic> && data['results'] is List) {
      final list = data['results'] as List<dynamic>;
      return list.map((e) => OnboardingDraftItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Retrieve a specific onboarding draft by ID
  Future<OnboardingDraftItem> getOnboardingDraft(String draftId) async {
    final data = await _apiClient.get(AppConfig.onboardingDraftDetailEndpoint(draftId));
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return OnboardingDraftItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load draft $draftId');
  }

  /// Save or update an onboarding draft
  Future<OnboardingDraftItem> saveOnboardingDraft({
    String? id,
    required String name,
    required int currentStep,
    String aiPrompt = '',
    Map<String, dynamic> aiSuggestions = const {},
    required Map<String, dynamic> wizardData,
  }) async {
    final payload = <String, dynamic>{
      'name': name.isNotEmpty ? name : 'Untitled Draft',
      'current_step': currentStep,
      'ai_prompt': aiPrompt,
      'ai_suggestions': aiSuggestions,
      'wizard_data': wizardData,
    };

    dynamic data;
    if (id != null && id.isNotEmpty) {
      data = await _apiClient.put(
        AppConfig.onboardingDraftDetailEndpoint(id),
        data: payload,
      );
    } else {
      data = await _apiClient.post(
        AppConfig.onboardingDraftsEndpoint,
        data: payload,
      );
    }

    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return OnboardingDraftItem.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to save onboarding draft.');
  }

  /// Delete a saved onboarding draft
  Future<void> deleteOnboardingDraft(String draftId) async {
    await _apiClient.delete(AppConfig.onboardingDraftDetailEndpoint(draftId));
  }

  // ==========================================
  // SYSTEM HEALTH
  // ==========================================

  /// Check backend system & database health
  Future<Map<String, dynamic>> checkHealth() async {
    final data = await _apiClient.get(AppConfig.healthEndpoint);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'status': 'unknown', 'success': false};
  }
}
