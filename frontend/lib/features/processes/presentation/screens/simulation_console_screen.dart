/// FactoryOS AI — Manufacturing Simulation Console Screen
/// Phase 3: Deterministic Anomaly Injection, Speed Controls, Seed Configuration & Hardware Isolation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../controllers/simulation_controller.dart';
import '../controllers/execution_controller.dart';

class SimulationConsoleScreen extends ConsumerStatefulWidget {
  const SimulationConsoleScreen({super.key});

  @override
  ConsumerState<SimulationConsoleScreen> createState() => _SimulationConsoleScreenState();
}

class _SimulationConsoleScreenState extends ConsumerState<SimulationConsoleScreen> {
  final TextEditingController _seedController = TextEditingController(text: '42');

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final simState = ref.watch(simulationControllerProvider);
    final simNotifier = ref.read(simulationControllerProvider.notifier);
    final execState = ref.watch(executionControllerProvider);
    final execNotifier = ref.read(executionControllerProvider.notifier);

    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final selectedExec = execState.activeExecution;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FactorySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety & Isolation Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(FactoryRadius.md),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, color: Color(0xFFF59E0B), size: 24),
                  const SizedBox(width: FactorySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'SIMULATION ENVIRONMENT — ISOLATED FROM HARDWARE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SOFTWARE MODEL ONLY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All production events, sensor deviations, equipment faults, and inventory adjustments are deterministic simulation artifacts. No physical PLC commands or machine actuators are operated.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? FactoryColors.darkTextSecondary : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FactorySpacing.xl),

            // Screen Title & Refresh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Production Simulation Console',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inject controlled anomalies, stress-test scheduling, and verify failure recovery scenarios deterministically.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh Scenarios'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    backgroundColor: cardBg,
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                  ),
                  onPressed: () {
                    simNotifier.loadScenarios();
                    execNotifier.loadExecutions();
                  },
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Execution Selector & Simulation Config Deck
            Container(
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
                    children: [
                      const Icon(Icons.tune_rounded, size: 18, color: FactoryColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Simulation Execution Configuration',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: FactorySpacing.md),
                  Wrap(
                    spacing: FactorySpacing.xl,
                    runSpacing: FactorySpacing.md,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Active Execution Run Dropdown
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Target Execution Run', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(FactoryRadius.sm),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedExec?.id,
                                  hint: Text('Select Work Order Execution', style: TextStyle(fontSize: 12, color: textSecondary)),
                                  items: execState.executions.map((e) {
                                    return DropdownMenuItem(
                                      value: e.id,
                                      child: Text(
                                        '${e.executionNumber} (${e.orderNumber}) [${e.status}]',
                                        style: TextStyle(fontSize: 12, color: textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      execNotifier.selectExecution(id);
                                      simNotifier.setActiveExecution(id);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Speed Multipliers
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Simulation Speed Multiplier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [1.0, 2.0, 5.0, 10.0].map((speed) {
                              final isSelected = simState.speedMultiplier == speed;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text('${speed.toStringAsFixed(0)}x'),
                                  selected: isSelected,
                                  selectedColor: FactoryColors.primaryBlue,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                  onSelected: (val) {
                                    if (val) simNotifier.setSpeed(speed);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      // Deterministic Seed Control
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deterministic Random Seed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                height: 36,
                                child: TextField(
                                  controller: _seedController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                                  ),
                                  style: TextStyle(fontSize: 13, color: textPrimary),
                                  onSubmitted: (val) {
                                    final seed = int.tryParse(val) ?? 42;
                                    simNotifier.setSeed(seed);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onPressed: () {
                                  final seed = int.tryParse(_seedController.text) ?? 42;
                                  simNotifier.setSeed(seed);
                                },
                                child: const Text('Set Seed', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 4),
                              ActionChip(
                                label: const Text('42', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  _seedController.text = '42';
                                  simNotifier.setSeed(42);
                                },
                              ),
                              const SizedBox(width: 4),
                              ActionChip(
                                label: const Text('101', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  _seedController.text = '101';
                                  simNotifier.setSeed(101);
                                },
                              ),
                              const SizedBox(width: 4),
                              ActionChip(
                                label: const Text('777', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  _seedController.text = '777';
                                  simNotifier.setSeed(777);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: FactorySpacing.lg),

                  // Action Buttons: Step & Full Run
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: simState.isSimulating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.fast_forward_rounded, size: 16),
                        label: const Text('Step 1 Operation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FactoryColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                        ),
                        onPressed: (selectedExec == null || simState.isSimulating)
                            ? null
                            : () async {
                                await simNotifier.stepSimulation(selectedExec.id);
                                await execNotifier.selectExecution(selectedExec.id);
                              },
                      ),
                      const SizedBox(width: FactorySpacing.md),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                        label: const Text('Run Full Simulation to Completion'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                        ),
                        onPressed: (selectedExec == null || simState.isSimulating)
                            ? null
                            : () async {
                                await simNotifier.runFullSimulation(selectedExec.id);
                                await execNotifier.selectExecution(selectedExec.id);
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: FactorySpacing.xl),

            // Anomaly Injection Deck
            Text(
              'Configurable Simulation Anomaly Scenarios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Select an industrial failure mode to perturb active process stages, trigger safety interlocks, and test rerouting.',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: FactorySpacing.md),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: FactorySpacing.md,
                  mainAxisSpacing: FactorySpacing.md,
                  childAspectRatio: 2.1,
                  children: [
                    _buildAnomalyCard(
                      context,
                      title: 'Machine Breakdown',
                      scenarioType: 'MACHINE_BREAKDOWN',
                      icon: Icons.error_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      description: 'Simulates sudden actuator/motor seizure. Halts the active stage in FAILED state and locks downstream tasks.',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedExecId: selectedExec?.id,
                      isSimulating: simState.isSimulating,
                      onInject: (type) => _triggerAnomaly(context, type, selectedExec?.id),
                    ),
                    _buildAnomalyCard(
                      context,
                      title: 'Material Shortage',
                      scenarioType: 'MATERIAL_SHORTAGE',
                      icon: Icons.inventory_2_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      description: 'Depletes buffer inventory below threshold. Restricts upcoming operations from consuming bill of materials.',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedExecId: selectedExec?.id,
                      isSimulating: simState.isSimulating,
                      onInject: (type) => _triggerAnomaly(context, type, selectedExec?.id),
                    ),
                    _buildAnomalyCard(
                      context,
                      title: 'Production Cycle Delay',
                      scenarioType: 'PRODUCTION_DELAY',
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      description: 'Introduces a 2.5x thermal or curing delay to simulate cycle variance, testing WIP queue resilience.',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedExecId: selectedExec?.id,
                      isSimulating: simState.isSimulating,
                      onInject: (type) => _triggerAnomaly(context, type, selectedExec?.id),
                    ),
                    _buildAnomalyCard(
                      context,
                      title: 'Quality Rejection Spike',
                      scenarioType: 'QUALITY_REJECTION',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFEC4899),
                      description: 'Simulates visual or dimensional defect burst. Increases scrap quantity and deducts acceptable batch yield.',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedExecId: selectedExec?.id,
                      isSimulating: simState.isSimulating,
                      onInject: (type) => _triggerAnomaly(context, type, selectedExec?.id),
                    ),
                    _buildAnomalyCard(
                      context,
                      title: 'Bottleneck Formation',
                      scenarioType: 'BOTTLENECK_FORMATION',
                      icon: Icons.hourglass_top_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      description: 'Throttles node capacity to create upstream WIP accumulation and downstream starvation.',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedExecId: selectedExec?.id,
                      isSimulating: simState.isSimulating,
                      onInject: (type) => _triggerAnomaly(context, type, selectedExec?.id),
                    ),
                    _buildAnomalyCard(
                      context,
                      title: 'Demand Surge Pressure',
                      scenarioType: 'DEMAND_SURGE',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF10B981),
                      description: 'Simulates unexpected customer rush orders, evaluating machine capacity limits and takt compliance.',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedExecId: selectedExec?.id,
                      isSimulating: simState.isSimulating,
                      onInject: (type) => _triggerAnomaly(context, type, selectedExec?.id),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: FactorySpacing.xl),

            // Pre-Configured Scenario Library & Live Console
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Configured Scenarios Catalog
                Expanded(
                  flex: 3,
                  child: Container(
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
                          children: [
                            const Icon(Icons.bookmark_border_rounded, size: 18, color: FactoryColors.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Predefined Scenarios (${simState.scenarios.length})',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: FactorySpacing.md),
                        if (simState.isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        else if (simState.scenarios.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('No predefined scenarios registered for current plant.', style: TextStyle(color: textSecondary)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: simState.scenarios.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final sc = simState.scenarios[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sc.name,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: FactoryColors.primaryBlue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        sc.scenarioType,
                                        style: const TextStyle(fontSize: 10, color: FactoryColors.primaryBlue, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  sc.description.isNotEmpty ? sc.description : 'Configured anomaly preset',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: (selectedExec == null || simState.isSimulating)
                                      ? null
                                      : () async {
                                          await simNotifier.injectAnomaly(
                                            selectedExec.id,
                                            sc.scenarioType,
                                            params: sc.parameters,
                                          );
                                          await execNotifier.selectExecution(selectedExec.id);
                                        },
                                  child: const Text('Apply'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: FactorySpacing.lg),

                // Live Monospace Telemetry / Event Console
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 440,
                    padding: const EdgeInsets.all(FactorySpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(FactoryRadius.md),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            const Text(
                              'SIMULATOR EVENT STREAM // HARDWARE INTERLOCK ACTIVE',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFF334155), height: 1),
                        const SizedBox(height: 8),
                        Expanded(
                          child: simState.simulationLog.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No simulated events dispatched yet.\nSelect an execution run and trigger an anomaly or step to observe deterministic runtime telemetry.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: simState.simulationLog.length,
                                  itemBuilder: (context, idx) {
                                    final log = simState.simulationLog[idx];
                                    Color logColor = const Color(0xFFE2E8F0);
                                    if (log.contains('BREAKDOWN') || log.contains('FAILED')) {
                                      logColor = const Color(0xFFF87171);
                                    } else if (log.contains('SHORTAGE') || log.contains('Warning')) {
                                      logColor = const Color(0xFFFBBF24);
                                    } else if (log.contains('completed') || log.contains('finished')) {
                                      logColor = const Color(0xFF34D399);
                                    } else if (log.contains('Step executed')) {
                                      logColor = const Color(0xFF38BDF8);
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text(
                                        log,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: logColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(
    BuildContext context, {
    required String title,
    required String scenarioType,
    required IconData icon,
    required Color iconColor,
    required String description,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String? selectedExecId,
    required bool isSimulating,
    required Function(String type) onInject,
  }) {
    return Container(
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bolt_rounded, size: 14),
              label: const Text('Inject Anomaly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                foregroundColor: iconColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: BorderSide(color: iconColor.withValues(alpha: 0.4)),
              ),
              onPressed: (selectedExecId == null || isSimulating) ? null : () => onInject(scenarioType),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerAnomaly(BuildContext context, String type, String? execId) async {
    if (execId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active execution run first.')),
      );
      return;
    }
    final simNotifier = ref.read(simulationControllerProvider.notifier);
    final execNotifier = ref.read(executionControllerProvider.notifier);
    await simNotifier.injectAnomaly(execId, type);
    await execNotifier.selectExecution(execId);
  }
}
