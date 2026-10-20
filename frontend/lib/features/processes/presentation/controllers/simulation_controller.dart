/// FactoryOS AI — Simulation Console Controller
/// Phase 3: Anomaly Injection, Simulation Speed & Deterministic Seed Control
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class SimulationState {
  final List<SimulationScenarioItem> scenarios;
  final bool isLoading;
  final bool isSimulating;
  final double speedMultiplier;
  final int randomSeed;
  final String? activeExecutionId;
  final String? errorMessage;
  final String? successMessage;
  final List<String> simulationLog;

  const SimulationState({
    this.scenarios = const [],
    this.isLoading = false,
    this.isSimulating = false,
    this.speedMultiplier = 1.0,
    this.randomSeed = 42,
    this.activeExecutionId,
    this.errorMessage,
    this.successMessage,
    this.simulationLog = const [],
  });

  SimulationState copyWith({
    List<SimulationScenarioItem>? scenarios,
    bool? isLoading,
    bool? isSimulating,
    double? speedMultiplier,
    int? randomSeed,
    String? activeExecutionId,
    String? errorMessage,
    String? successMessage,
    List<String>? simulationLog,
  }) {
    return SimulationState(
      scenarios: scenarios ?? this.scenarios,
      isLoading: isLoading ?? this.isLoading,
      isSimulating: isSimulating ?? this.isSimulating,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      randomSeed: randomSeed ?? this.randomSeed,
      activeExecutionId: activeExecutionId ?? this.activeExecutionId,
      errorMessage: errorMessage,
      successMessage: successMessage,
      simulationLog: simulationLog ?? this.simulationLog,
    );
  }
}

class SimulationNotifier extends Notifier<SimulationState> {
  late final ProcessRepository _repository;

  @override
  SimulationState build() {
    _repository = ref.watch(processRepositoryProvider);
    Future.microtask(() => loadScenarios());
    return const SimulationState(isLoading: true);
  }

  Future<void> loadScenarios({String? factoryId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getSimulationScenarios(factoryId: factoryId);
      state = state.copyWith(scenarios: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load scenarios: $e');
    }
  }

  void setSpeed(double speed) {
    state = state.copyWith(speedMultiplier: speed);
  }

  void setSeed(int seed) {
    state = state.copyWith(randomSeed: seed);
  }

  void setActiveExecution(String executionId) {
    state = state.copyWith(activeExecutionId: executionId);
  }

  Future<void> injectAnomaly(String executionId, String scenarioType, {Map<String, dynamic>? params}) async {
    state = state.copyWith(isSimulating: true, errorMessage: null);
    try {
      final res = await _repository.injectAnomaly(
        executionId: executionId,
        scenarioType: scenarioType,
        parameters: params,
      );
      final msg = res['message'] as String? ?? "Injected $scenarioType.";
      final logs = [
        "[${DateTime.now().toIso8601String().substring(11, 19)}] $msg",
        ...state.simulationLog,
      ];
      state = state.copyWith(
        isSimulating: false,
        successMessage: msg,
        simulationLog: logs.take(50).toList(),
      );
    } catch (e) {
      state = state.copyWith(isSimulating: false, errorMessage: 'Failed to inject anomaly: $e');
    }
  }

  Future<void> stepSimulation(String executionId) async {
    state = state.copyWith(isSimulating: true, errorMessage: null);
    try {
      final res = await _repository.stepSimulation(
        executionId: executionId,
        randomSeed: state.randomSeed,
      );
      final advanced = res['advanced'] as bool? ?? false;
      final msg = advanced
          ? "Step executed: Stage '${res['stage']?['node_name']}' completed."
          : "Simulation step: No eligible stages ready to advance.";
      final logs = [
        "[${DateTime.now().toIso8601String().substring(11, 19)}] $msg",
        ...state.simulationLog,
      ];
      state = state.copyWith(
        isSimulating: false,
        successMessage: msg,
        simulationLog: logs.take(50).toList(),
      );
    } catch (e) {
      state = state.copyWith(isSimulating: false, errorMessage: 'Failed to step simulation: $e');
    }
  }

  Future<void> runFullSimulation(String executionId) async {
    state = state.copyWith(isSimulating: true, errorMessage: null);
    try {
      final res = await _repository.runFullSimulation(
        executionId: executionId,
        randomSeed: state.randomSeed,
        maxSteps: 50,
      );
      final resultData = res['result'] as Map<String, dynamic>? ?? {};
      final msg = "Full simulation finished: ${resultData['steps_executed']} steps executed, status '${resultData['status']}'.";
      final logs = [
        "[${DateTime.now().toIso8601String().substring(11, 19)}] $msg",
        ...state.simulationLog,
      ];
      state = state.copyWith(
        isSimulating: false,
        successMessage: msg,
        simulationLog: logs.take(50).toList(),
      );
    } catch (e) {
      state = state.copyWith(isSimulating: false, errorMessage: 'Failed to run full simulation: $e');
    }
  }
}

final simulationControllerProvider =
    NotifierProvider<SimulationNotifier, SimulationState>(() => SimulationNotifier());
