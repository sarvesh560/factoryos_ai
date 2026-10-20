/// FactoryOS AI — Company & Multi-Tenant Controller
/// Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/factory_controller.dart';
import '../../data/models/factory_model.dart';
import '../../data/repositories/factory_repository.dart';

class CompanyState {
  final List<CompanyItem> companies;
  final bool isLoading;
  final bool includeArchived;
  final String? errorMessage;
  final String? successMessage;

  const CompanyState({
    this.companies = const [],
    this.isLoading = false,
    this.includeArchived = false,
    this.errorMessage,
    this.successMessage,
  });

  CompanyState copyWith({
    List<CompanyItem>? companies,
    bool? isLoading,
    bool? includeArchived,
    String? errorMessage,
    String? successMessage,
  }) {
    return CompanyState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      includeArchived: includeArchived ?? this.includeArchived,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class CompanyNotifier extends Notifier<CompanyState> {
  late final FactoryRepository _repository;

  @override
  CompanyState build() {
    _repository = ref.watch(factoryRepositoryProvider);
    Future.microtask(() => _fetchCompanies());
    return const CompanyState(isLoading: true);
  }

  Future<void> _fetchCompanies() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final comps = await _repository.getCompanies(includeArchived: state.includeArchived);
      state = state.copyWith(companies: comps, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load companies: $e');
    }
  }

  void toggleIncludeArchived() {
    final next = !state.includeArchived;
    state = state.copyWith(includeArchived: next);
    _fetchCompanies();
  }

  Future<bool> createCompany({
    required String name,
    String description = '',
    String website = '',
    String contactEmail = '',
  }) async {
    try {
      await _repository.createCompany(
        name: name,
        description: description,
        website: website,
        contactEmail: contactEmail,
      );
      state = state.copyWith(successMessage: "Company '$name' created successfully.");
      await _fetchCompanies();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create company: $e');
      return false;
    }
  }

  Future<bool> updateCompany(String companyId, Map<String, dynamic> data) async {
    try {
      await _repository.updateCompany(companyId, data);
      state = state.copyWith(successMessage: 'Company updated successfully.');
      await _fetchCompanies();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update company: $e');
      return false;
    }
  }

  Future<void> toggleArchiveCompany(String companyId) async {
    try {
      final updated = await _repository.archiveCompany(companyId);
      final statusText = updated.isActive ? 'unarchived' : 'archived';
      state = state.copyWith(successMessage: "Company '${updated.name}' $statusText.");
      await _fetchCompanies();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to toggle company archive: $e');
    }
  }

  Future<void> toggleArchiveFactory(String factoryId) async {
    try {
      final updated = await _repository.archiveFactory(factoryId);
      final statusText = updated.isActive ? 'unarchived' : 'archived';
      state = state.copyWith(successMessage: "Factory '${updated.name}' $statusText.");
      await _fetchCompanies();
      ref.read(factoryControllerProvider.notifier).refreshCurrentFactory();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to toggle factory archive: $e');
    }
  }
}

final companyControllerProvider =
    NotifierProvider<CompanyNotifier, CompanyState>(() => CompanyNotifier());
