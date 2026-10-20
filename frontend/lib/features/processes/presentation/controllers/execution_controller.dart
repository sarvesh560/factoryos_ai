/// FactoryOS AI — Production Execution Controller
/// Phase 3: Live Execution Flow, Stage Advancement, Bottleneck Monitoring & Event Log
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';

class ExecutionState {
  final List<ProcessExecutionItem> executions;
  final ProcessExecutionItem? activeExecution;
  final List<ProductionEventItem> events;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ExecutionState({
    this.executions = const [],
    this.activeExecution,
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ExecutionState copyWith({
    List<ProcessExecutionItem>? executions,
    ProcessExecutionItem? activeExecution,
    bool clearActiveExecution = false,
    List<ProductionEventItem>? events,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ExecutionState(
      executions: executions ?? this.executions,
      activeExecution: clearActiveExecution ? null : (activeExecution ?? this.activeExecution),
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ExecutionNotifier extends Notifier<ExecutionState> {
  ProcessRepository get _repository => ref.read(processRepositoryProvider);
  String? _currentFactoryFilter;

  @override
  ExecutionState build() {
    final factoryState = ref.watch(factoryControllerProvider);
    _currentFactoryFilter = factoryState.selectedFactory?.id;
    Future.microtask(() => loadExecutions(factoryId: _currentFactoryFilter));
    return const ExecutionState(isLoading: true);
  }

  Future<void> loadExecutions({String? factoryId, String? status}) async {
    final targetFactory = factoryId ?? _currentFactoryFilter;
    if (factoryId != null) {
      _currentFactoryFilter = factoryId;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final list = await _repository.getExecutions(factoryId: targetFactory, status: status);
      ProcessExecutionItem? current;
      final cur = state.activeExecution;
      if (cur != null) {
        current = list.where((e) => e.id == cur.id).firstOrNull;
      }
      if (current == null && list.isNotEmpty) {
        current = list.first;
      }

      state = state.copyWith(
        executions: list,
        activeExecution: current,
        clearActiveExecution: current == null,
        isLoading: false,
      );

      if (current != null) {
        await loadEvents(executionId: current.id, factoryId: targetFactory);
      } else {
        state = state.copyWith(events: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load executions: $e');
    }
  }

  Future<void> selectExecution(String executionId) async {
    try {
      final item = await _repository.getExecution(executionId);
      state = state.copyWith(activeExecution: item);
      await loadEvents(executionId: executionId, factoryId: _currentFactoryFilter);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load execution details: $e');
    }
  }

  Future<void> selectExecutionByWorkOrderId(String workOrderId) async {
    try {
      final list = await _repository.getExecutions(factoryId: _currentFactoryFilter);
      final match = list.where((e) => e.workOrder == workOrderId).firstOrNull;
      if (match != null) {
        await selectExecution(match.id);
      } else {
        await loadExecutions(factoryId: _currentFactoryFilter);
      }
    } catch (_) {}
  }

  Future<void> loadEvents({String? executionId, String? factoryId}) async {
    try {
      final evts = await _repository.getProductionEvents(
        executionId: executionId,
        factoryId: factoryId ?? _currentFactoryFilter,
      );
      state = state.copyWith(events: evts);
    } catch (_) {}
  }

  Future<void> advanceStage(String stageId, {int? unitsCompleted, int unitsScrapped = 0}) async {
    try {
      final resp = await _repository.advanceStage(
        stageId,
        unitsCompleted: unitsCompleted,
        unitsScrapped: unitsScrapped,
      );
      if (resp['execution'] is Map<String, dynamic>) {
        final updatedExec = ProcessExecutionItem.fromJson(resp['execution'] as Map<String, dynamic>);
        state = state.copyWith(
          activeExecution: updatedExec,
          successMessage: 'Stage advanced successfully.',
        );
      } else if (state.activeExecution != null) {
        await selectExecution(state.activeExecution!.id);
      }
      if (state.activeExecution != null) {
        await loadEvents(executionId: state.activeExecution!.id, factoryId: _currentFactoryFilter);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to advance stage: $e');
    }
  }

  Future<void> failStage(String stageId, String errorMessage) async {
    try {
      await _repository.failStage(stageId, errorMessage);
      if (state.activeExecution != null) {
        await selectExecution(state.activeExecution!.id);
        await loadEvents(executionId: state.activeExecution!.id, factoryId: _currentFactoryFilter);
      }
      state = state.copyWith(errorMessage: 'Stage marked as failed: $errorMessage');
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to report stage failure: $e');
    }
  }

  Future<void> pauseActiveExecution({String reason = 'Operator hold'}) async {
    final exec = state.activeExecution;
    if (exec == null) return;
    try {
      final res = await _repository.executeExecutionAction(exec.id, 'pause', payload: {'reason': reason});
      if (res['execution'] is Map<String, dynamic>) {
        final updated = ProcessExecutionItem.fromJson(res['execution'] as Map<String, dynamic>);
        state = state.copyWith(activeExecution: updated, successMessage: 'Execution paused.');
      } else {
        await selectExecution(exec.id);
      }
      await loadExecutions(factoryId: _currentFactoryFilter);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pause execution: $e');
    }
  }

  Future<void> resumeActiveExecution() async {
    final exec = state.activeExecution;
    if (exec == null) return;
    try {
      final res = await _repository.executeExecutionAction(exec.id, 'resume');
      if (res['execution'] is Map<String, dynamic>) {
        final updated = ProcessExecutionItem.fromJson(res['execution'] as Map<String, dynamic>);
        state = state.copyWith(activeExecution: updated, successMessage: 'Execution resumed.');
      } else {
        await selectExecution(exec.id);
      }
      await loadExecutions(factoryId: _currentFactoryFilter);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resume execution: $e');
    }
  }

  Future<void> completeActiveExecution() async {
    final exec = state.activeExecution;
    if (exec == null) return;
    try {
      final res = await _repository.executeExecutionAction(exec.id, 'complete');
      if (res['execution'] is Map<String, dynamic>) {
        final updated = ProcessExecutionItem.fromJson(res['execution'] as Map<String, dynamic>);
        state = state.copyWith(activeExecution: updated, successMessage: 'Execution completed.');
      } else {
        await selectExecution(exec.id);
      }
      await loadExecutions(factoryId: _currentFactoryFilter);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to complete execution: $e');
    }
  }

  void clearMessages() {
    state = state.copyWith(clearErrorMessage: true, clearSuccessMessage: true);
  }
}

final executionControllerProvider =
    NotifierProvider<ExecutionNotifier, ExecutionState>(() => ExecutionNotifier());
