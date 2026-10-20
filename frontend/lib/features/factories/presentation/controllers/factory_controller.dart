import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/factory_model.dart';
import '../../data/repositories/factory_repository.dart';

class FactoryState {
  final bool isLoading;
  final bool isInitialLoading;
  final List<FactoryItem> factories;
  final FactoryItem? selectedFactory;
  final FactoryOverviewData? overview;
  final ConnectionStatus connectionStatus;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const FactoryState({
    this.isLoading = false,
    this.isInitialLoading = true,
    this.factories = const [],
    this.selectedFactory,
    this.overview,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.errorMessage,
    this.lastUpdated,
  });

  FactoryState copyWith({
    bool? isLoading,
    bool? isInitialLoading,
    List<FactoryItem>? factories,
    FactoryItem? selectedFactory,
    FactoryOverviewData? overview,
    ConnectionStatus? connectionStatus,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return FactoryState(
      isLoading: isLoading ?? this.isLoading,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      factories: factories ?? this.factories,
      selectedFactory: selectedFactory ?? this.selectedFactory,
      overview: overview ?? this.overview,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class FactoryNotifier extends Notifier<FactoryState> {
  late final FactoryRepository _repository;

  @override
  FactoryState build() {
    _repository = ref.watch(factoryRepositoryProvider);
    // Trigger initial load
    Future.microtask(() => loadFactories());
    return const FactoryState();
  }

  Future<void> loadFactories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Health check
      final health = await _repository.checkHealth();
      final isHealthy = health['status'] == 'healthy';
      final status = isHealthy ? ConnectionStatus.connected : ConnectionStatus.degraded;

      // 2. Fetch factories from Django PostgreSQL
      final factories = await _repository.getFactories();

      FactoryItem? nextSelected = state.selectedFactory;
      if (factories.isNotEmpty) {
        if (nextSelected == null || !factories.any((f) => f.id == nextSelected!.id)) {
          nextSelected = factories.first;
        }
      }

      state = state.copyWith(
        isLoading: false,
        isInitialLoading: false,
        factories: factories,
        selectedFactory: nextSelected,
        connectionStatus: status,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      // 3. Load overview for selected factory
      if (nextSelected != null) {
        await loadOverview(nextSelected.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialLoading: false,
        connectionStatus: ConnectionStatus.disconnected,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> selectFactory(FactoryItem factory) async {
    if (state.selectedFactory?.id == factory.id && state.overview != null) {
      return; // Already selected
    }
    state = state.copyWith(
      selectedFactory: factory,
      isLoading: true,
      clearError: true,
    );
    await loadOverview(factory.id);
  }

  Future<void> loadOverview(String factoryId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final overview = await _repository.getFactoryOverview(factoryId);
      state = state.copyWith(
        isLoading: false,
        overview: overview,
        connectionStatus: ConnectionStatus.connected,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        connectionStatus: ConnectionStatus.degraded,
        errorMessage: 'Failed to load telemetry overview: $e',
      );
    }
  }

  Future<void> refreshCurrentFactory() async {
    final current = state.selectedFactory;
    if (current != null) {
      await loadOverview(current.id);
    } else {
      await loadFactories();
    }
  }
}

// Providers
final factoryRepositoryProvider = Provider<FactoryRepository>((ref) {
  return FactoryRepository();
});

final factoryControllerProvider =
    NotifierProvider<FactoryNotifier, FactoryState>(FactoryNotifier.new);
