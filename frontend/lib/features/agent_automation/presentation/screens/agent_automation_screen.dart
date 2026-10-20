// FactoryOS AI — Agent Automation Workspace Screen
// Phase 4: Multi-Agent Manufacturing Orchestration, Approvals & Audit Trail
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';
import '../../data/models/agent_automation_models.dart';
import '../controllers/agent_automation_controller.dart';

class AgentAutomationScreen extends ConsumerStatefulWidget {
  const AgentAutomationScreen({super.key});

  @override
  ConsumerState<AgentAutomationScreen> createState() => _AgentAutomationScreenState();
}

class _AgentAutomationScreenState extends ConsumerState<AgentAutomationScreen> {
  final TextEditingController _reviewNotesController = TextEditingController();
  final TextEditingController _goalTextController = TextEditingController(
    text: 'Prepare a 100-unit production order. Check material availability, identify the applicable process, estimate execution using simulation, and request approval before releasing the order.',
  );
  final TextEditingController _clarificationController = TextEditingController();
  final TextEditingController _goalApprovalNotesController = TextEditingController();
  String _selectedIndustry = 'GENERAL_DISCRETE';
  String? _selectedProviderOverride;

  @override
  void dispose() {
    _reviewNotesController.dispose();
    _goalTextController.dispose();
    _clarificationController.dispose();
    _goalApprovalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentAutomationControllerProvider);
    final notifier = ref.read(agentAutomationControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFactory = ref.watch(factoryControllerProvider).selectedFactory;

    final bgCanvas = isDark ? FactoryColors.darkCanvas : FactoryColors.lightCanvas;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FactorySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Context Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          const Icon(Icons.smart_toy_outlined, color: FactoryColors.primaryBlue, size: 28),
                          Text(
                            'AI Agent Automation Engine',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FactoryColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(FactoryRadius.sm),
                              border: Border.all(color: FactoryColors.primaryBlue.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'EVENT & GOAL-DRIVEN RUNTIME',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: FactoryColors.primaryBlue,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Multi-industry manufacturing orchestration with real LLM reasoning, bounded goal planning, human approvals, and verified state completion.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildProviderStatusBadge(state.providerStatus, isDark),
                    OutlinedButton.icon(
                      key: const Key('open_industry_profiles_button'),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.business_outlined, size: 16),
                      label: Text(
                        'Profiles (${state.industryProfiles.isNotEmpty ? state.industryProfiles.length : 8})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _showIndustryProfilesDialog(context, state.industryProfiles, isDark),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                      onPressed: () => notifier.loadAll(factoryId: currentFactory?.id),
                    ),
                    ElevatedButton.icon(
                      key: const Key('open_simulator_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FactoryColors.primaryBlue,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('Simulate Event', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showSimulateEventDialog(context, notifier, currentFactory?.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Notification / Flash Alerts
            if (state.errorMessage != null)
              Container(
                key: const Key('automation_error_banner'),
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: FactoryColors.statusOfflineBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: FactoryColors.statusOffline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: FactoryColors.statusOffline, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      key: const Key('automation_retry_button'),
                      onPressed: () => notifier.loadAll(factoryId: currentFactory?.id),
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, color: FactoryColors.statusOffline)),
                    ),
                  ],
                ),
              ),

            if (state.successMessage != null)
              Container(
                key: const Key('automation_success_banner'),
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: FactoryColors.statusRunningBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusRunningBorderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: FactoryColors.statusRunning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(color: FactoryColors.statusRunning, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: FactoryColors.statusRunning),
                      onPressed: notifier.clearMessages,
                    ),
                  ],
                ),
              ),

            // Summary Metric Deck
            _buildMetricDeck(state, cardBg, borderColor, textPrimary, textSecondary),
            const SizedBox(height: FactorySpacing.lg),

            // Navigation Tabs
            _buildTabBar(state.selectedTab, notifier, textPrimary, isDark),
            const SizedBox(height: FactorySpacing.md),

            // Active Tab Content
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (state.selectedTab == 0)
              _buildAgentsTab(state, notifier, cardBg, borderColor, textPrimary, textSecondary)
            else if (state.selectedTab == 1)
              _buildGoalAgentTab(state, notifier, currentFactory?.id, cardBg, borderColor, textPrimary, textSecondary, isDark)
            else if (state.selectedTab == 2)
              _buildEventsTab(state, cardBg, borderColor, textPrimary, textSecondary)
            else if (state.selectedTab == 3)
              _buildDecisionsTab(state, cardBg, borderColor, textPrimary, textSecondary)
            else if (state.selectedTab == 4)
              _buildApprovalsTab(state, notifier, cardBg, borderColor, textPrimary, textSecondary)
            else
              _buildAuditsTab(state, cardBg, borderColor, textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // PROVIDER STATUS BADGE
  // =====================================================================
  Widget _buildProviderStatusBadge(ProviderStatusItem? provider, bool isDark) {
    final mode = provider?.activeMode.toUpperCase() ?? 'DETERMINISTIC';
    final isLlm = provider?.isLlmAvailable ?? false;
    final model = provider?.modelName.isNotEmpty == true ? provider!.modelName : 'gpt-4o-mini';
    final label = isLlm ? 'LLM: $model' : 'MODE: $mode';
    final color = isLlm ? FactoryColors.statusRunning : Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FactoryRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // METRIC SUMMARY DECK
  // =====================================================================
  Widget _buildMetricDeck(
    AgentAutomationState state,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final s = state.summary ?? const AutomationSummaryData();
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Specialist Agents',
            '${s.enabledAgents} / ${s.totalAgents}',
            'Active / Configured',
            Icons.smart_toy_outlined,
            FactoryColors.primaryBlue,
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        ),
        const SizedBox(width: FactorySpacing.md),
        Expanded(
          child: _buildMetricTile(
            'Autonomous Goals',
            '${state.goalRuns.length}',
            '${state.goalRuns.where((r) => r.isCompleted).length} Completed Runs',
            Icons.auto_awesome_outlined,
            const Color(0xFF8B5CF6),
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        ),
        const SizedBox(width: FactorySpacing.md),
        Expanded(
          child: _buildMetricTile(
            'Events Ingested',
            '${s.totalEventsProcessed}',
            'Processed Pipeline Events',
            Icons.sensors_outlined,
            const Color(0xFF6366F1),
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        ),
        const SizedBox(width: FactorySpacing.md),
        Expanded(
          child: _buildMetricTile(
            'Pending Approvals',
            '${s.pendingApprovals}',
            'Human-in-the-Loop Signoff',
            Icons.pending_actions_outlined,
            s.pendingApprovals > 0 ? FactoryColors.statusMaintenance : FactoryColors.statusRunning,
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        ),
        const SizedBox(width: FactorySpacing.md),
        Expanded(
          child: _buildMetricTile(
            'Actions Executed',
            '${s.successfulActions}',
            '${s.failedActions} Failed / Retried',
            Icons.task_alt_outlined,
            FactoryColors.statusRunning,
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(FactoryRadius.sm),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // TAB NAVIGATION BAR
  // =====================================================================
  Widget _buildTabBar(int selectedTab, AgentAutomationNotifier notifier, Color textPrimary, bool isDark) {
    final tabs = [
      {'label': 'Specialist Agents', 'icon': Icons.smart_toy_outlined},
      {'label': 'Goal-Driven Agent', 'icon': Icons.auto_awesome_outlined},
      {'label': 'Event Pipeline', 'icon': Icons.stream_outlined},
      {'label': 'Agent Decisions', 'icon': Icons.psychology_outlined},
      {'label': 'Approval Inbox', 'icon': Icons.rule_outlined},
      {'label': 'Audit Trail', 'icon': Icons.receipt_long_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = selectedTab == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(FactoryRadius.md),
              onTap: () => notifier.setSelectedTab(idx),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FactoryColors.primaryBlue.withValues(alpha: 0.15)
                      : (isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface),
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(
                    color: isSelected ? FactoryColors.primaryBlue : (isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[idx]['icon'] as IconData,
                      size: 16,
                      color: isSelected ? FactoryColors.primaryBlue : (isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tabs[idx]['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? FactoryColors.primaryBlue : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =====================================================================
  // TAB 1: SPECIALIST AGENTS OVERVIEW
  // =====================================================================
  Widget _buildAgentsTab(
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (state.agents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No specialist agents configured.', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return Column(
      children: state.agents.map((agent) {
        final isActing = state.actionLoadingId == agent.key;
        return Container(
          key: Key('agent_card_${agent.key}'),
          margin: const EdgeInsets.only(bottom: FactorySpacing.md),
          padding: const EdgeInsets.all(FactorySpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: agent.isEnabled
                      ? FactoryColors.primaryBlue.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: agent.isEnabled ? FactoryColors.primaryBlue : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(agent.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: agent.isEnabled ? FactoryColors.statusRunningBgLight : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            agent.isEnabled ? 'ACTIVE' : 'DISABLED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: agent.isEnabled ? FactoryColors.statusRunning : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            agent.requiresApproval ? 'HUMAN APPROVAL REQUIRED' : 'AUTONOMOUS PERMITTED',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(agent.description, style: TextStyle(fontSize: 12, color: textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...agent.supportedEventTypes.map((evt) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                          ),
                          child: Text(evt, style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.w600)),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (isActing)
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Switch(
                      key: Key('agent_toggle_${agent.key}'),
                      value: agent.isEnabled,
                      activeTrackColor: FactoryColors.primaryBlue.withValues(alpha: 0.5),
                      activeThumbColor: FactoryColors.primaryBlue,
                      onChanged: (val) => notifier.toggleAgent(agent.key, val),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // TAB 1: GOAL-DRIVEN AUTONOMOUS AGENT WORKSPACE
  // =====================================================================
  Widget _buildGoalAgentTab(
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    String? factoryId,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final run = state.selectedRun;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Goal Input Card
        _buildGoalInputCard(state, notifier, factoryId, cardBg, borderColor, textPrimary, textSecondary, isDark),
        const SizedBox(height: FactorySpacing.lg),

        // 2. Active Run Detail (if any selected)
        if (run != null) ...[
          _buildGoalRunDetailCard(run, state, notifier, cardBg, borderColor, textPrimary, textSecondary, isDark),
          const SizedBox(height: FactorySpacing.lg),
        ],

        // 3. Goal Runs History List
        _buildGoalRunsHistory(state, notifier, cardBg, borderColor, textPrimary, textSecondary, isDark),
      ],
    );
  }

  Widget _buildGoalInputCard(
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    String? factoryId,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final provider = state.providerStatus;
    final isLlm = provider?.isLlmAvailable ?? false;
    final mode = provider?.activeMode.toUpperCase() ?? 'DETERMINISTIC';

    return Container(
      key: const Key('goal_input_card'),
      padding: const EdgeInsets.all(FactorySpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                      ),
                      child: const Icon(Icons.auto_awesome, color: FactoryColors.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Universal Manufacturing Goal Agent',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                          Text(
                            'Executes bounded ReAct plans across verified domain services and safe simulation.',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLlm ? FactoryColors.statusRunningBgLight : FactoryColors.statusMaintenanceBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.sm),
                  border: Border.all(
                    color: isLlm ? FactoryColors.statusRunningBorderLight : FactoryColors.statusMaintenanceBorderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLlm ? Icons.smart_toy : Icons.rule,
                      size: 14,
                      color: isLlm ? FactoryColors.statusRunning : FactoryColors.statusMaintenance,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLlm ? 'PROVIDER: LLM (${provider?.modelName})' : 'PROVIDER: $mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLlm ? FactoryColors.statusRunning : FactoryColors.statusMaintenance,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FactorySpacing.md),

          // Quick Prompt Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('100-Unit Production Order & Approval', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _goalTextController.text =
                      'Prepare a 100-unit production order. Check material availability, identify the applicable process, estimate execution using simulation, and request approval before releasing the order.';
                },
              ),
              ActionChip(
                label: const Text('Stock Inspection (RAW-STL-01)', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _goalTextController.text =
                      'Check raw material stock levels for RAW-STL-01 and verify buffer capacity.';
                },
              ),
              ActionChip(
                label: const Text('Process Discovery & Simulation', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _goalTextController.text =
                      'Discover published CNC manufacturing process, validate process graph, and simulate execution.';
                },
              ),
            ],
          ),
          const SizedBox(height: FactorySpacing.md),

          // Goal Prompt Text Field
          TextField(
            key: const Key('goal_text_field'),
            controller: _goalTextController,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter a manufacturing goal in natural language...',
              labelText: 'Natural Language Manufacturing Goal',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(FactoryRadius.md)),
            ),
          ),
          const SizedBox(height: FactorySpacing.md),

          // Options Row: Industry Dropdown + Provider Mode + Submit Button
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  key: const Key('industry_profile_dropdown'),
                  initialValue: _selectedIndustry,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Industry Profile',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GENERAL_DISCRETE', child: Text('General Discrete [OPERATIONAL]')),
                    DropdownMenuItem(value: 'CNC_MACHINING', child: Text('CNC Machining [OPERATIONAL]')),
                    DropdownMenuItem(value: 'TEXTILES', child: Text('Textiles & Apparel [OPERATIONAL]')),
                    DropdownMenuItem(value: 'AUTOMOTIVE_EV', child: Text('Automotive & EV [OPERATIONAL]')),
                    DropdownMenuItem(value: 'ELECTRONICS_PCBA', child: Text('Electronics & PCBA [OPERATIONAL]')),
                    DropdownMenuItem(value: 'PHARMACEUTICALS', child: Text('Pharmaceuticals [PREVIEW]')),
                    DropdownMenuItem(value: 'FOOD_BEVERAGE', child: Text('Food & Beverage [PREVIEW]')),
                    DropdownMenuItem(value: 'CHEMICALS', child: Text('Specialty Chemicals [PREVIEW]')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIndustry = val);
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  key: const Key('provider_mode_override_dropdown'),
                  initialValue: _selectedProviderOverride,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Provider Override',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('System Default')),
                    DropdownMenuItem(value: 'llm', child: Text('Enforce LLM')),
                    DropdownMenuItem(value: 'deterministic', child: Text('Enforce Deterministic')),
                    DropdownMenuItem(value: 'hybrid', child: Text('Hybrid Mode')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedProviderOverride = val);
                  },
                ),
              ),
              ElevatedButton.icon(
                key: const Key('submit_goal_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactoryColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: state.isGoalSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.rocket_launch, size: 18),
                label: Text(
                  state.isGoalSubmitting ? 'Planning...' : 'Generate Plan & Launch',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: state.isGoalSubmitting || (factoryId == null || factoryId.isEmpty)
                    ? null
                    : () async {
                        final text = _goalTextController.text.trim();
                        if (text.isEmpty) return;
                        await notifier.submitGoal(
                          factoryId: factoryId,
                          goalText: text,
                          industryProfileKey: _selectedIndustry,
                          providerModeOverride: _selectedProviderOverride,
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRunDetailCard(
    AgentRunItem run,
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    Color statusColor;
    if (run.isCompleted) {
      statusColor = FactoryColors.statusRunning;
    } else if (run.isAwaitingApproval) {
      statusColor = FactoryColors.statusMaintenance;
    } else if (run.isNeedsClarification) {
      statusColor = const Color(0xFF8B5CF6);
    } else if (run.isFailed || run.isBlocked) {
      statusColor = FactoryColors.statusOffline;
    } else if (run.isCancelled) {
      statusColor = Colors.grey;
    } else {
      statusColor = FactoryColors.primaryBlue;
    }

    return Container(
      key: const Key('goal_run_header_card'),
      padding: const EdgeInsets.all(FactorySpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(FactoryRadius.sm),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            run.statusDisplay.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Run ID: ${run.id}',
                          style: TextStyle(fontSize: 11, color: textSecondary, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${run.goalText}"',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Industry: ${run.industryProfileKey} (v${run.profileVersion}) | Mode: ${run.executionMode.toUpperCase()} | Provider: ${run.providerType}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  if (run.isRunning || run.status == 'PLANNING')
                    ElevatedButton.icon(
                      key: const Key('advance_step_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FactoryColors.primaryBlue,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: state.isRunStepping
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Advance Step'),
                      onPressed: state.isRunStepping ? null : () => notifier.advanceRun(run.id),
                    ),
                  const SizedBox(width: 8),
                  if (!run.isCompleted && !run.isFailed && !run.isCancelled)
                    OutlinedButton.icon(
                      key: const Key('cancel_run_button'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: FactoryColors.statusOffline,
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel Run'),
                      onPressed: () => notifier.cancelRun(run.id),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: FactorySpacing.md),

          // Fallback notice if occurred
          if (run.fallbackOccurred)
            Container(
              margin: const EdgeInsets.only(bottom: FactorySpacing.md),
              padding: const EdgeInsets.all(FactorySpacing.sm),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(FactoryRadius.sm),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Provider Fallback Triggered: ${run.fallbackReason}',
                      style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Execution Bounds Counters
          Row(
            children: [
              _buildProgressChip('Steps', '${run.currentStepIndex} / ${run.maxSteps}', Icons.format_list_numbered, textSecondary),
              const SizedBox(width: 12),
              _buildProgressChip('Replans', '${run.replanCount} / ${run.maxReplans}', Icons.cached, textSecondary),
              const SizedBox(width: 12),
              _buildProgressChip('Tool Calls', '${run.toolCalls.length}', Icons.build_outlined, textSecondary),
            ],
          ),
          const SizedBox(height: FactorySpacing.md),

          // Consequential Approval Card
          if (run.isAwaitingApproval) ...[
            _buildConsequentialApprovalCard(run, state, notifier, textPrimary, textSecondary),
            const SizedBox(height: FactorySpacing.md),
          ],

          // Clarification Request Card
          if (run.isNeedsClarification) ...[
            _buildClarificationCard(run, state, notifier, textPrimary, textSecondary),
            const SizedBox(height: FactorySpacing.md),
          ],

          // Active Plan Steps Timeline
          if (run.activePlan != null) ...[
            _buildPlanStepsTimeline(run.activePlan!, textPrimary, textSecondary, isDark),
            const SizedBox(height: FactorySpacing.md),
          ],

          // Verification Summary (Completed State)
          if (run.isCompleted && run.completionSummary.isNotEmpty) ...[
            _buildVerificationSummaryCard(run, textPrimary, textSecondary),
            const SizedBox(height: FactorySpacing.md),
          ],

          // Tool Calls & Observations Stream
          _buildToolCallsAndObservations(run, textPrimary, textSecondary, isDark),
        ],
      ),
    );
  }

  Widget _buildConsequentialApprovalCard(
    AgentRunItem run,
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    Color textPrimary,
    Color textSecondary,
  ) {
    final pendingStep = run.activePlan?.steps.firstWhere(
      (s) => s.status == 'AWAITING_APPROVAL' || s.isConsequential,
      orElse: () => run.activePlan!.steps.first,
    );

    return Container(
      key: const Key('consequential_approval_card'),
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: FactoryColors.statusMaintenanceBgLight,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: FactoryColors.statusMaintenanceBorderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: FactoryColors.statusMaintenance, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONSEQUENTIAL MANUFACTURING ACTION REQUIRES HUMAN APPROVAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: FactoryColors.statusMaintenance,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'The agent proposed an irreversible operation. Human operator sign-off is required before execution.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingStep != null) ...[
            Text(
              'Proposed Action: ${pendingStep.toolName} — ${pendingStep.title}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              pendingStep.description,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Arguments: ${pendingStep.toolArguments}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _goalApprovalNotesController,
            decoration: const InputDecoration(
              labelText: 'Operator Review Notes (Optional)',
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                key: const Key('approve_goal_action_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactoryColors.statusRunning,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Approve & Execute'),
                onPressed: () => notifier.decideGoalApproval(
                  run.id,
                  'APPROVE',
                  notes: _goalApprovalNotesController.text,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('reject_goal_action_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FactoryColors.statusOffline,
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject Action'),
                onPressed: () => notifier.decideGoalApproval(
                  run.id,
                  'REJECT',
                  notes: _goalApprovalNotesController.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClarificationCard(
    AgentRunItem run,
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      key: const Key('clarification_card'),
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.help_outline, color: Color(0xFF8B5CF6), size: 20),
              SizedBox(width: 8),
              Text(
                'AGENT REQUIRES CLARIFICATION TO PROCEED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            run.clarificationQuestion.isNotEmpty ? run.clarificationQuestion : 'Please provide additional production specifications.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _clarificationController,
            decoration: const InputDecoration(
              labelText: 'Operator Clarification / Manufacturing Context',
              hintText: 'Enter missing specifications (e.g. quantity, material code, line ID)...',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            key: const Key('submit_clarification_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Submit Clarification'),
            onPressed: () => notifier.submitClarificationAnswer(
              run.id,
              _clarificationController.text.trim(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStepsTimeline(
    AgentPlanItem plan,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      key: const Key('structured_plan_card'),
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: isDark ? FactoryColors.darkCanvas : FactoryColors.lightCanvas,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Plan (v${plan.version})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              Text(
                '${plan.steps.length} Steps',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
          if (plan.goalSummary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Summary: ${plan.goalSummary}',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Column(
            children: plan.steps.map((step) {
              Color stepColor;
              IconData stepIcon;
              if (step.status == 'COMPLETED') {
                stepColor = FactoryColors.statusRunning;
                stepIcon = Icons.check_circle;
              } else if (step.status == 'RUNNING') {
                stepColor = FactoryColors.primaryBlue;
                stepIcon = Icons.play_arrow;
              } else if (step.status == 'AWAITING_APPROVAL') {
                stepColor = FactoryColors.statusMaintenance;
                stepIcon = Icons.hourglass_top;
              } else if (step.status == 'FAILED') {
                stepColor = FactoryColors.statusOffline;
                stepIcon = Icons.error;
              } else {
                stepColor = textSecondary.withValues(alpha: 0.6);
                stepIcon = Icons.radio_button_unchecked;
              }

              return Container(
                key: Key('plan_step_${step.stepNumber}'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface,
                  borderRadius: BorderRadius.circular(FactoryRadius.sm),
                  border: Border.all(
                    color: step.status == 'RUNNING' || step.status == 'AWAITING_APPROVAL'
                        ? stepColor
                        : (isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stepIcon, color: stepColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${step.stepNumber} ${step.title}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  step.toolName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: FactoryColors.primaryBlue,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              if (step.isConsequential) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: FactoryColors.statusMaintenance.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'CONSEQUENTIAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: FactoryColors.statusMaintenance,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                          if (step.resultData.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: FactoryColors.statusRunning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Result: ${step.resultData}',
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                          if (step.errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Error: ${step.errorMessage}',
                              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stepColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        step.statusDisplay.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: stepColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSummaryCard(AgentRunItem run, Color textPrimary, Color textSecondary) {
    return Container(
      key: const Key('verification_summary_card'),
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: FactoryColors.statusRunningBgLight,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: FactoryColors.statusRunningBorderLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified, color: FactoryColors.statusRunning, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETION CRITERIA VERIFIED AGAINST DOMAIN STATE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: FactoryColors.statusRunning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Application domain state successfully reconciled. All plan completion criteria met.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verification Summary: ${run.completionSummary}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallsAndObservations(
    AgentRunItem run,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      key: const Key('tool_calls_card'),
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: isDark ? FactoryColors.darkCanvas : FactoryColors.lightCanvas,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tool Executions & Observations (${run.toolCalls.length} tool calls, ${run.observations.length} observations)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (run.toolCalls.isEmpty && run.observations.isEmpty)
            Text('No tool executions recorded yet.', style: TextStyle(fontSize: 12, color: textSecondary))
          else ...[
            ...run.toolCalls.map((tc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.code, size: 14, color: FactoryColors.primaryBlue),
                      const SizedBox(width: 6),
                      Text('${tc.toolName} (${tc.durationMs}ms)', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('Status: ${tc.status}', style: TextStyle(fontSize: 11, color: tc.status == 'EXECUTED' ? FactoryColors.statusRunning : FactoryColors.statusOffline)),
                    ],
                  ),
                )),
            if (run.observations.isNotEmpty) ...[
              const Divider(height: 16),
              ...run.observations.map((obs) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '[${obs.observationType}] ${obs.content}',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGoalRunsHistory(
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (state.goalRuns.isEmpty) {
      return Container(
        key: const Key('goal_runs_history_card'),
        padding: const EdgeInsets.all(FactorySpacing.lg),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(FactoryRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_outlined, size: 36, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('No previous goal runs for this facility.', style: TextStyle(color: textSecondary)),
              const SizedBox(height: 4),
              Text('Submit a manufacturing goal above to start autonomous planning.', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      key: const Key('goal_runs_history_card'),
      padding: const EdgeInsets.all(FactorySpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal Runs History (${state.goalRuns.length})',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: state.goalRuns.map((r) {
              final isSelected = state.selectedRun?.id == r.id;
              return InkWell(
                key: Key('select_run_${r.id}'),
                onTap: () => notifier.selectGoalRun(r),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? FactoryColors.primaryBlue.withValues(alpha: 0.08) : (isDark ? FactoryColors.darkCanvas : FactoryColors.lightCanvas),
                    borderRadius: BorderRadius.circular(FactoryRadius.sm),
                    border: Border.all(
                      color: isSelected ? FactoryColors.primaryBlue : (isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 16,
                        color: isSelected ? FactoryColors.primaryBlue : textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.goalText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Profile: ${r.industryProfileKey} | Provider: ${r.providerType} | Steps: ${r.currentStepIndex}/${r.maxSteps}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.isCompleted ? FactoryColors.statusRunning.withValues(alpha: 0.15) : FactoryColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.statusDisplay.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: r.isCompleted ? FactoryColors.statusRunning : FactoryColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showIndustryProfilesDialog(BuildContext context, List<IndustryProfileItem> profiles, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('industry_profiles_dialog'),
        title: Row(
          children: const [
            Icon(Icons.business_center, color: FactoryColors.primaryBlue),
            SizedBox(width: 8),
            Text('Universal Industry Profiles (8)'),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shared agent runtime with specialized domain profiles and safety boundaries:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...profiles.map((p) {
                  final statusColor = p.isOperational
                      ? FactoryColors.statusRunning
                      : (p.isPreview ? Colors.amber.shade700 : Colors.red);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? FactoryColors.darkCanvas : FactoryColors.lightCanvas,
                      borderRadius: BorderRadius.circular(FactoryRadius.sm),
                      border: Border.all(color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${p.displayName} (v${p.version})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.status,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capabilities: ${p.capabilities.join(", ")}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tools: ${p.supportedTools.join(", ")}',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChip(String label, String value, IconData icon, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(FactoryRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // TAB 2: MANUFACTURING EVENT PIPELINE
  // =====================================================================
  Widget _buildEventsTab(
    AgentAutomationState state,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.stream_outlined, size: 48, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('No manufacturing events ingested yet.', style: TextStyle(color: textSecondary)),
              const SizedBox(height: 4),
              Text('Click "Simulate Event" above to test the multi-agent pipeline.', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: state.events.map((evt) {
        final severityColor = evt.severity == 'CRITICAL'
            ? FactoryColors.statusOffline
            : (evt.severity == 'ERROR'
                ? Colors.deepOrange
                : (evt.severity == 'WARNING' ? FactoryColors.statusMaintenance : FactoryColors.primaryBlue));

        return Container(
          key: Key('event_card_${evt.id}'),
          margin: const EdgeInsets.only(bottom: FactorySpacing.sm),
          padding: const EdgeInsets.all(FactorySpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          evt.severity,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: severityColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(evt.eventType, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          evt.sourceType == 'SIMULATION' ? 'SIMULATED DATA' : evt.sourceType,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    evt.timestamp?.toIso8601String().substring(0, 19).replaceAll('T', ' ') ?? '',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Source ID: ${evt.sourceId.isEmpty ? 'N/A' : evt.sourceId} | Factory: ${evt.factoryName}',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              if (evt.payload.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    evt.payload.toString(),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Produced Decisions: ${evt.decisions.length} | Status: ${evt.status}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // TAB 3: AGENT DECISIONS & FINDINGS
  // =====================================================================
  Widget _buildDecisionsTab(
    AgentAutomationState state,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (state.decisions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No agent decisions recorded yet.', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return Column(
      children: state.decisions.map((dec) {
        return Container(
          key: Key('decision_card_${dec.id}'),
          margin: const EdgeInsets.only(bottom: FactorySpacing.md),
          padding: const EdgeInsets.all(FactorySpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 18, color: FactoryColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(dec.agentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(dec.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: FactoryColors.primaryBlue)),
                      ),
                    ],
                  ),
                  Text(
                    'Confidence: ${(dec.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(dec.findings, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 6),
              Text(dec.rationale, style: TextStyle(fontSize: 12, color: textSecondary)),
              if (dec.proposedAction.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FactoryColors.statusMaintenanceBgLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: FactoryColors.statusMaintenanceBorderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, size: 16, color: FactoryColors.statusMaintenance),
                      const SizedBox(width: 6),
                      Text(
                        'Proposed Action: ${dec.proposedAction}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FactoryColors.statusMaintenance),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // TAB 4: HUMAN APPROVAL INBOX
  // =====================================================================
  Widget _buildApprovalsTab(
    AgentAutomationState state,
    AgentAutomationNotifier notifier,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (state.approvals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, size: 48, color: FactoryColors.statusRunning),
              const SizedBox(height: 8),
              Text('Approval inbox clear. No pending human sign-offs.', style: TextStyle(color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: state.approvals.map((appr) {
        final isActing = state.actionLoadingId == appr.id;

        return Container(
          key: Key('approval_card_${appr.id}'),
          margin: const EdgeInsets.only(bottom: FactorySpacing.md),
          padding: const EdgeInsets.all(FactorySpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(
              color: appr.status == 'PENDING' ? FactoryColors.statusMaintenance : borderColor,
              width: appr.status == 'PENDING' ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FactoryColors.statusMaintenanceBgLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appr.urgency,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: FactoryColors.statusMaintenance),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(appr.requestedAction, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: appr.status == 'PENDING' ? FactoryColors.statusMaintenanceBgLight : FactoryColors.statusRunningBgLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      appr.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: appr.status == 'PENDING' ? FactoryColors.statusMaintenance : FactoryColors.statusRunning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(appr.actionSummary, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 4),
              Text('Reasoning: ${appr.decisionRationale}', style: TextStyle(fontSize: 12, color: textSecondary)),
              if (appr.actionParameters.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    appr.actionParameters.toString(),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (appr.status == 'PENDING') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      key: Key('reject_button_${appr.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FactoryColors.statusOffline,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Reject Action', style: TextStyle(fontSize: 11)),
                      onPressed: isActing
                          ? null
                          : () => notifier.decideApproval(appr.id, 'REJECT', notes: 'Rejected by operator sign-off'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      key: Key('approve_button_${appr.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FactoryColors.statusRunning,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: isActing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 14),
                      label: const Text('Approve & Execute', style: TextStyle(fontSize: 11)),
                      onPressed: isActing
                          ? null
                          : () => notifier.decideApproval(appr.id, 'APPROVE', notes: 'Operator authorized execution'),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Reviewed by: ${appr.reviewedBy} at ${appr.reviewedAt?.toIso8601String().substring(0, 19).replaceAll('T', ' ') ?? ''}',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textSecondary),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // TAB 5: AUDIT TRAIL
  // =====================================================================
  Widget _buildAuditsTab(
    AgentAutomationState state,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (state.audits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No audit events logged yet.', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return Column(
      children: state.audits.map((audit) {
        return Container(
          key: Key('audit_card_${audit.id}'),
          margin: const EdgeInsets.only(bottom: FactorySpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(FactoryRadius.sm),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Text(
                audit.timestamp.toIso8601String().substring(11, 19),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  audit.eventCategory,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${audit.actor}: ${audit.details}',
                  style: TextStyle(fontSize: 11, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // INTERACTIVE SIMULATION DIALOG
  // =====================================================================
  void _showSimulateEventDialog(BuildContext context, AgentAutomationNotifier notifier, String? factoryId) {
    if (factoryId == null || factoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active factory from the top selector first.')),
      );
      return;
    }

    String selectedType = 'MACHINE_ANOMALY';
    String selectedSeverity = 'CRITICAL';
    final machineNameCtrl = TextEditingController(text: 'Haas 5-Axis VF2');
    final tempCtrl = TextEditingController(text: '92.5');
    final vibCtrl = TextEditingController(text: '8.4');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.bolt, color: FactoryColors.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Simulate Manufacturing Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Injects a safe, simulated event into the agent automation engine. Triggers deterministic evaluation and human approval.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('simulate_event_type_dropdown'),
                      isExpanded: true,
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Event Type'),
                      items: const [
                        DropdownMenuItem(value: 'MACHINE_ANOMALY', child: Text('Machine Anomaly (Spindle Breakdown)')),
                        DropdownMenuItem(value: 'PRODUCTION_DELAY', child: Text('Production Delay (Cycle Time Inflation)')),
                        DropdownMenuItem(value: 'QUALITY_FAILURE', child: Text('Quality Failure (High Scrap Rate)')),
                        DropdownMenuItem(value: 'INVENTORY_SHORTAGE', child: Text('Inventory Shortage (Material Starvation)')),
                      ],
                      onChanged: (val) => setDlgState(() => selectedType = val ?? selectedType),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: const Key('simulate_severity_dropdown'),
                      isExpanded: true,
                      initialValue: selectedSeverity,
                      decoration: const InputDecoration(labelText: 'Severity Level'),
                      items: const [
                        DropdownMenuItem(value: 'INFO', child: Text('INFO')),
                        DropdownMenuItem(value: 'WARNING', child: Text('WARNING')),
                        DropdownMenuItem(value: 'ERROR', child: Text('ERROR')),
                        DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                      ],
                      onChanged: (val) => setDlgState(() => selectedSeverity = val ?? selectedSeverity),
                    ),
                    const SizedBox(height: 10),
                    if (selectedType == 'MACHINE_ANOMALY') ...[
                      TextField(
                        controller: machineNameCtrl,
                        decoration: const InputDecoration(labelText: 'Machine Name'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tempCtrl,
                              decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: vibCtrl,
                              decoration: const InputDecoration(labelText: 'Vibration (mm/s)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('submit_simulation_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactoryColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDlgState(() => isSubmitting = true);
                        Map<String, dynamic> payload = {};

                        if (selectedType == 'MACHINE_ANOMALY') {
                          payload = {
                            'machine_name': machineNameCtrl.text.trim(),
                            'temperature_c': double.tryParse(tempCtrl.text) ?? 92.5,
                            'vibration_rms': double.tryParse(vibCtrl.text) ?? 8.4,
                            'anomaly_type': 'Spindle Bearing Thermal Seizure',
                          };
                        } else if (selectedType == 'PRODUCTION_DELAY') {
                          payload = {
                            'line_name': 'Precision CNC Machining Line 1',
                            'cycle_variance_pct': 32.5,
                            'stage_name': '5-Axis Profiling',
                          };
                        } else if (selectedType == 'QUALITY_FAILURE') {
                          payload = {
                            'product_name': 'Titanium Impeller',
                            'stage_name': 'CMM Quality Gate',
                            'scrap_rate_pct': 9.2,
                            'defect_type': 'Bore Diameter Runout',
                            'defect_units': 14,
                          };
                        } else if (selectedType == 'INVENTORY_SHORTAGE') {
                          payload = {
                            'material_name': 'Aerospace Titanium Billet',
                            'current_stock': 25.0,
                            'safety_stock': 200.0,
                            'unit_of_measure': 'kg',
                          };
                        }

                        final success = await notifier.simulateEvent({
                          'factory_id': factoryId,
                          'event_type': selectedType,
                          'severity': selectedSeverity,
                          'source_type': 'SIMULATION',
                          'payload': payload,
                          'correlation_id': 'SIM-${DateTime.now().millisecondsSinceEpoch}',
                        });

                        if (ctx.mounted) {
                          if (success) {
                            Navigator.pop(ctx);
                          } else {
                            setDlgState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Inject Event'),
              ),
            ],
          );
        },
      ),
    );
  }
}
