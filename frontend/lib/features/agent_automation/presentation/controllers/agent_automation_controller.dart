// FactoryOS AI — Agent Automation State & Controller
// Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Goal-Driven Agent Runtime
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/agent_automation_models.dart';
import '../../data/repositories/agent_automation_repository.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';

class AgentAutomationState {
  final AutomationSummaryData? summary;
  final List<AgentItem> agents;
  final List<ManufacturingEventItem> events;
  final List<AgentDecisionItem> decisions;
  final List<ApprovalRequestItem> approvals;
  final List<AutomationAuditItem> audits;

  // Phase 4 Step 2: Goal-Driven Autonomous Runtime
  final ProviderStatusItem? providerStatus;
  final List<IndustryProfileItem> industryProfiles;
  final List<AgentRunItem> goalRuns;
  final AgentRunItem? selectedRun;
  final bool isGoalSubmitting;
  final bool isRunStepping;

  final bool isLoading;
  final bool isSimulating;
  final String? actionLoadingId;
  final int selectedTab;
  final String? factoryFilter;
  final String? errorMessage;
  final String? successMessage;

  const AgentAutomationState({
    this.summary,
    this.agents = const [],
    this.events = const [],
    this.decisions = const [],
    this.approvals = const [],
    this.audits = const [],
    this.providerStatus,
    this.industryProfiles = const [],
    this.goalRuns = const [],
    this.selectedRun,
    this.isGoalSubmitting = false,
    this.isRunStepping = false,
    this.isLoading = false,
    this.isSimulating = false,
    this.actionLoadingId,
    this.selectedTab = 0,
    this.factoryFilter,
    this.errorMessage,
    this.successMessage,
  });

  AgentAutomationState copyWith({
    AutomationSummaryData? summary,
    List<AgentItem>? agents,
    List<ManufacturingEventItem>? events,
    List<AgentDecisionItem>? decisions,
    List<ApprovalRequestItem>? approvals,
    List<AutomationAuditItem>? audits,
    ProviderStatusItem? providerStatus,
    List<IndustryProfileItem>? industryProfiles,
    List<AgentRunItem>? goalRuns,
    AgentRunItem? selectedRun,
    bool clearSelectedRun = false,
    bool? isGoalSubmitting,
    bool? isRunStepping,
    bool? isLoading,
    bool? isSimulating,
    String? actionLoadingId,
    bool clearActionLoading = false,
    int? selectedTab,
    String? factoryFilter,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return AgentAutomationState(
      summary: summary ?? this.summary,
      agents: agents ?? this.agents,
      events: events ?? this.events,
      decisions: decisions ?? this.decisions,
      approvals: approvals ?? this.approvals,
      audits: audits ?? this.audits,
      providerStatus: providerStatus ?? this.providerStatus,
      industryProfiles: industryProfiles ?? this.industryProfiles,
      goalRuns: goalRuns ?? this.goalRuns,
      selectedRun: clearSelectedRun ? null : (selectedRun ?? this.selectedRun),
      isGoalSubmitting: isGoalSubmitting ?? this.isGoalSubmitting,
      isRunStepping: isRunStepping ?? this.isRunStepping,
      isLoading: isLoading ?? this.isLoading,
      isSimulating: isSimulating ?? this.isSimulating,
      actionLoadingId: clearActionLoading ? null : (actionLoadingId ?? this.actionLoadingId),
      selectedTab: selectedTab ?? this.selectedTab,
      factoryFilter: factoryFilter ?? this.factoryFilter,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AgentAutomationNotifier extends Notifier<AgentAutomationState> {
  AgentAutomationRepository get _repository => ref.read(agentAutomationRepositoryProvider);

  @override
  AgentAutomationState build() {
    final currentFactory = ref.watch(factoryControllerProvider).selectedFactory;
    final factoryId = currentFactory?.id;

    Future.microtask(() => loadAll(factoryId: factoryId));
    return AgentAutomationState(isLoading: true, factoryFilter: factoryId);
  }

  Future<void> loadAll({String? factoryId}) async {
    final targetFactory = factoryId ?? state.factoryFilter;
    state = state.copyWith(isLoading: true, clearErrorMessage: true, factoryFilter: targetFactory);

    try {
      final summaryFuture = _repository.getSummary(factoryId: targetFactory);
      final agentsFuture = _repository.getAgents();
      final eventsFuture = _repository.getEvents(factoryId: targetFactory, limit: 30);
      final decisionsFuture = _repository.getDecisions(factoryId: targetFactory, limit: 30);
      final approvalsFuture = _repository.getApprovals(factoryId: targetFactory);
      final auditsFuture = _repository.getAudits(factoryId: targetFactory, limit: 30);
      final providerFuture = _repository.getProviderStatus();
      final industriesFuture = _repository.getIndustryProfiles();
      final runsFuture = _repository.getGoalRuns(factoryId: targetFactory);

      final results = await Future.wait([
        summaryFuture,
        agentsFuture,
        eventsFuture,
        decisionsFuture,
        approvalsFuture,
        auditsFuture,
        providerFuture,
        industriesFuture,
        runsFuture,
      ]);

      final goalRunsList = results[8] as List<AgentRunItem>;
      AgentRunItem? updatedSelectedRun = state.selectedRun;
      if (updatedSelectedRun != null) {
        final match = goalRunsList.where((r) => r.id == updatedSelectedRun!.id).toList();
        if (match.isNotEmpty) {
          try {
            updatedSelectedRun = await _repository.getGoalRun(updatedSelectedRun.id);
          } catch (_) {
            updatedSelectedRun = match.first;
          }
        }
      } else if (goalRunsList.isNotEmpty) {
        try {
          updatedSelectedRun = await _repository.getGoalRun(goalRunsList.first.id);
        } catch (_) {
          updatedSelectedRun = goalRunsList.first;
        }
      }

      state = state.copyWith(
        summary: results[0] as AutomationSummaryData,
        agents: results[1] as List<AgentItem>,
        events: results[2] as List<ManufacturingEventItem>,
        decisions: results[3] as List<AgentDecisionItem>,
        approvals: results[4] as List<ApprovalRequestItem>,
        audits: results[5] as List<AutomationAuditItem>,
        providerStatus: results[6] as ProviderStatusItem,
        industryProfiles: results[7] as List<IndustryProfileItem>,
        goalRuns: goalRunsList,
        selectedRun: updatedSelectedRun,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load automation engine state: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
    }
  }

  void setSelectedTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  void selectGoalRun(AgentRunItem? run) async {
    if (run == null) {
      state = state.copyWith(clearSelectedRun: true);
      return;
    }
    state = state.copyWith(selectedRun: run);
    try {
      final detailed = await _repository.getGoalRun(run.id);
      state = state.copyWith(selectedRun: detailed);
    } catch (_) {}
  }

  Future<bool> submitGoal({
    required String factoryId,
    required String goalText,
    String industryProfileKey = 'GENERAL_DISCRETE',
    String? providerModeOverride,
  }) async {
    state = state.copyWith(isGoalSubmitting: true, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final payload = <String, dynamic>{
        'factory_id': factoryId,
        'goal_text': goalText,
        'industry_profile_key': industryProfileKey,
      };
      if (providerModeOverride != null && providerModeOverride.isNotEmpty) {
        payload['provider_mode_override'] = providerModeOverride;
      }
      final newRun = await _repository.createGoalRun(payload);
      final updatedRuns = [newRun, ...state.goalRuns];
      state = state.copyWith(
        isGoalSubmitting: false,
        goalRuns: updatedRuns,
        selectedRun: newRun,
        successMessage: "Goal registered (${newRun.statusDisplay}). Plan generated with ${newRun.activePlan?.steps.length ?? 0} step(s).",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        isGoalSubmitting: false,
        errorMessage: 'Goal submission failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    }
  }

  Future<bool> advanceRun(String runId) async {
    state = state.copyWith(isRunStepping: true, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final advanced = await _repository.advanceGoalRunStep(runId);
      final updatedRuns = state.goalRuns.map((r) => r.id == runId ? advanced : r).toList();
      state = state.copyWith(
        isRunStepping: false,
        goalRuns: updatedRuns,
        selectedRun: advanced,
        successMessage: "Step executed. Run status: ${advanced.statusDisplay}.",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        isRunStepping: false,
        errorMessage: 'Step advancement failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    }
  }

  Future<bool> decideGoalApproval(
    String runId,
    String action, {
    String notes = '',
    String reviewer = 'Plant Operator',
  }) async {
    state = state.copyWith(actionLoadingId: runId, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final decided = await _repository.approveGoalRun(
        runId,
        action: action,
        notes: notes,
        reviewer: reviewer,
      );
      final updatedRuns = state.goalRuns.map((r) => r.id == runId ? decided : r).toList();
      state = state.copyWith(
        goalRuns: updatedRuns,
        selectedRun: decided,
        successMessage: "Approval decision recorded: $action. Next step ready for execution.",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Approval decision failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }

  Future<bool> submitClarificationAnswer(String runId, String answer) async {
    state = state.copyWith(actionLoadingId: runId, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final clarified = await _repository.submitClarification(runId, answer);
      final updatedRuns = state.goalRuns.map((r) => r.id == runId ? clarified : r).toList();
      state = state.copyWith(
        goalRuns: updatedRuns,
        selectedRun: clarified,
        successMessage: "Clarification provided. Goal replanned successfully.",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Clarification submission failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }

  Future<bool> cancelRun(String runId, {String reason = 'Cancelled by operator'}) async {
    state = state.copyWith(actionLoadingId: runId, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final cancelled = await _repository.cancelGoalRun(runId, reason: reason);
      final updatedRuns = state.goalRuns.map((r) => r.id == runId ? cancelled : r).toList();
      state = state.copyWith(
        goalRuns: updatedRuns,
        selectedRun: cancelled,
        successMessage: "Run was CANCELLED.",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Cancellation failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }

  Future<void> toggleAgent(String agentKey, bool isEnabled) async {
    state = state.copyWith(actionLoadingId: agentKey, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final updated = await _repository.toggleAgent(agentKey, isEnabled: isEnabled);
      final updatedAgents = state.agents.map((a) => a.key == agentKey ? updated : a).toList();
      state = state.copyWith(
        agents: updatedAgents,
        successMessage: "Agent '${updated.name}' is now ${updated.isEnabled ? 'ACTIVE' : 'DISABLED'}.",
      );
      final summary = await _repository.getSummary(factoryId: state.factoryFilter);
      state = state.copyWith(summary: summary);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to toggle agent: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }

  Future<bool> simulateEvent(Map<String, dynamic> payload) async {
    state = state.copyWith(isSimulating: true, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final event = await _repository.simulateEvent(payload);
      state = state.copyWith(
        isSimulating: false,
        successMessage: "Simulated '${event.eventTypeDisplay}' ingested. Produced ${event.decisions.length} agent decision(s).",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSimulating: false,
        errorMessage: 'Event simulation failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    }
  }

  Future<bool> decideApproval(String approvalId, String action, {String notes = ''}) async {
    state = state.copyWith(actionLoadingId: approvalId, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final decided = await _repository.decideApproval(approvalId, action: action, notes: notes);
      state = state.copyWith(
        successMessage: "Action '${decided.requestedAction}' was ${decided.status.toUpperCase()}.",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Approval decision failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }

  Future<bool> retryAction(String executionId) async {
    state = state.copyWith(actionLoadingId: executionId, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final retried = await _repository.retryAction(executionId);
      state = state.copyWith(
        successMessage: "Action '${retried.actionType}' retried: ${retried.statusDisplay}.",
      );
      await loadAll(factoryId: state.factoryFilter);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Action retry failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
      return false;
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }

  void clearMessages() {
    state = state.copyWith(clearErrorMessage: true, clearSuccessMessage: true);
  }
}

final agentAutomationControllerProvider =
    NotifierProvider<AgentAutomationNotifier, AgentAutomationState>(() => AgentAutomationNotifier());
