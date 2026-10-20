/// FactoryOS AI — Live Production Execution & Monitoring Screen
/// Phase 3: Real-Time Graph Traversal, Bottleneck Detection, Stage Controls & Event Timeline

library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';
import '../controllers/execution_controller.dart';
import '../../data/models/process_models.dart';

class LiveExecutionScreen extends ConsumerStatefulWidget {
  final String? initialExecutionId;
  final String? initialWorkOrderId;

  const LiveExecutionScreen({
    super.key,
    this.initialExecutionId,
    this.initialWorkOrderId,
  });

  @override
  ConsumerState<LiveExecutionScreen> createState() => _LiveExecutionScreenState();
}

class _LiveExecutionScreenState extends ConsumerState<LiveExecutionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialExecutionId != null && widget.initialExecutionId!.isNotEmpty) {
        ref.read(executionControllerProvider.notifier).selectExecution(widget.initialExecutionId!);
      } else if (widget.initialWorkOrderId != null && widget.initialWorkOrderId!.isNotEmpty) {
        ref.read(executionControllerProvider.notifier).selectExecutionByWorkOrderId(widget.initialWorkOrderId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(executionControllerProvider);
    final notifier = ref.read(executionControllerProvider.notifier);
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    // Listen to factory changes from top navigation bar
    ref.listen(
      factoryControllerProvider.select((s) => s.selectedFactory?.id),
      (previous, next) {
        if (next != null && next != previous) {
          notifier.loadExecutions(factoryId: next);
        }
      },
    );

    final exec = state.activeExecution;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FactorySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Production Execution Monitor',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time manufacturing operations, stage routing states, bottleneck diagnostics, and event streams.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Execution Data',
                  onPressed: () => notifier.loadExecutions(factoryId: ref.read(factoryControllerProvider).selectedFactory?.id),
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.md),

            // Error Banner
            if (state.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: FactoryColors.statusOffline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusOffline.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: FactoryColors.statusOffline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: FactoryColors.statusOffline, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: FactoryColors.statusOffline),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => notifier.clearMessages(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FactorySpacing.md),
            ],

            // Success Banner
            if (state.successMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: FactoryColors.statusRunning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusRunning.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: FactoryColors.statusRunning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(fontSize: 13, color: FactoryColors.statusRunning, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: FactoryColors.statusRunning),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => notifier.clearMessages(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FactorySpacing.md),
            ],

            // Execution Selector
            if (state.executions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text('Select Execution Run:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: exec?.id,
                          isDense: true,
                          isExpanded: true,
                          items: state.executions.map((e) {
                            return DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                '${e.executionNumber} — ${e.orderNumber} (${e.productName}) [${e.status}]',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) notifier.selectExecution(id);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: FactorySpacing.lg),

            if (state.isLoading && state.executions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 16),
                    Text('Loading live production execution runs...', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
              )
            else if (exec == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.precision_manufacturing_outlined, size: 48, color: textSecondary),
                    const SizedBox(height: 12),
                    Text('No Active Executions for Factory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('Release and start a work order in the Work Orders screen to monitor live production routing.', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
              )
            else ...[
              // Execution Metrics Header Card with Lifecycle Action Controls
              Container(
                padding: const EdgeInsets.all(FactorySpacing.lg),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exec.executionNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text('Work Order: ${exec.orderNumber} • ${exec.productName}', style: TextStyle(fontSize: 13, color: textSecondary)),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (exec.bottleneckNodeName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(FactoryRadius.sm),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('Bottleneck: ${exec.bottleneckNodeName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber)),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: exec.status == 'COMPLETED'
                                    ? FactoryColors.statusRunningBgLight
                                    : exec.status == 'PAUSED'
                                        ? Colors.amber.withValues(alpha: 0.15)
                                        : FactoryColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(FactoryRadius.sm),
                              ),
                              child: Text(
                                exec.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: exec.status == 'COMPLETED'
                                      ? FactoryColors.statusRunning
                                      : exec.status == 'PAUSED'
                                          ? Colors.amber
                                          : FactoryColors.primaryBlue,
                                ),
                              ),
                            ),
                            // Lifecycle Action Buttons
                            if (exec.status == 'RUNNING') ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber,
                                  side: const BorderSide(color: Colors.amber),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.pause, size: 14),
                                label: const Text('Pause Run', style: TextStyle(fontSize: 11)),
                                onPressed: () => notifier.pauseActiveExecution(),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FactoryColors.statusRunning,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.done_all, size: 14),
                                label: const Text('Complete Run', style: TextStyle(fontSize: 11)),
                                onPressed: () => notifier.completeActiveExecution(),
                              ),
                            ] else if (exec.status == 'PAUSED') ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FactoryColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.play_arrow, size: 14),
                                label: const Text('Resume Run', style: TextStyle(fontSize: 11)),
                                onPressed: () => notifier.resumeActiveExecution(),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FactoryColors.statusRunning,
                                  side: const BorderSide(color: FactoryColors.statusRunning),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.done_all, size: 14),
                                label: const Text('Complete Run', style: TextStyle(fontSize: 11)),
                                onPressed: () => notifier.completeActiveExecution(),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: FactorySpacing.md),
                    // Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Batch Progress: ${exec.totalUnitsOutput} / ${exec.quantityTarget} units', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        Text('${exec.currentProgressPercent}% Completed (Scrap: ${exec.totalUnitsScrap})', style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: exec.currentProgressPercent / 100.0,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(exec.status == 'COMPLETED' ? FactoryColors.statusRunning : FactoryColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FactorySpacing.lg),

              // Stage Flow Cards Grid
              Text('Manufacturing Routing Stages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 185,
                  crossAxisSpacing: FactorySpacing.md,
                  mainAxisSpacing: FactorySpacing.md,
                ),
                itemCount: exec.stageExecutions.length,
                itemBuilder: (ctx, idx) {
                  final stage = exec.stageExecutions[idx];
                  return _buildStageCard(context, ref, stage, exec, notifier, isDark, textPrimary, textSecondary, cardBg, borderColor);
                },
              ),
              const SizedBox(height: FactorySpacing.xl),

              // Production Events Audit Timeline
              Text('Live Event Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.events.take(15).length,
                  separatorBuilder: (ctx, idx) => Divider(height: 1, color: borderColor),
                  itemBuilder: (ctx, idx) {
                    final evt = state.events[idx];
                    return _buildEventItem(evt, isDark, textPrimary, textSecondary);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    WidgetRef ref,
    StageExecutionItem stage,
    ProcessExecutionItem exec,
    ExecutionNotifier notifier,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    Color statusColor;
    IconData icon;
    switch (stage.status) {
      case 'RUNNING':
        statusColor = FactoryColors.primaryBlue;
        icon = Icons.sync;
        break;
      case 'COMPLETED':
        statusColor = FactoryColors.statusRunning;
        icon = Icons.check_circle;
        break;
      case 'BLOCKED':
        statusColor = Colors.amber;
        icon = Icons.warning_amber;
        break;
      case 'FAILED':
        statusColor = FactoryColors.statusOffline;
        icon = Icons.error;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        icon = Icons.schedule;
    }

    final isExecutionPaused = exec.status == 'PAUSED';
    final canAdvance = (stage.status == 'RUNNING' || stage.status == 'READY') && !isExecutionPaused;

    return Container(
      padding: const EdgeInsets.all(FactorySpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(
          color: stage.status == 'RUNNING' ? FactoryColors.primaryBlue : borderColor,
          width: stage.status == 'RUNNING' ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stage.nodeKey,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(stage.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stage.nodeName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Completed: ${stage.unitsCompleted} • Scrap: ${stage.unitsScrapped}',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          if (stage.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                stage.errorMessage,
                style: const TextStyle(fontSize: 10, color: FactoryColors.statusOffline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          if (stage.status == 'RUNNING' || stage.status == 'READY')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAdvance ? FactoryColors.statusRunning : Colors.grey,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: Text(isExecutionPaused ? 'Paused' : 'Advance Step', style: const TextStyle(fontSize: 11)),
                    onPressed: canAdvance ? () => notifier.advanceStage(stage.id) : null,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.report_problem_outlined, size: 16, color: FactoryColors.statusOffline),
                  tooltip: 'Report Failure',
                  onPressed: isExecutionPaused ? null : () => notifier.failStage(stage.id, 'Operator reported defect'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem(ProductionEventItem evt, bool isDark, Color textPrimary, Color textSecondary) {
    Color sevColor;
    switch (evt.severity) {
      case 'CRITICAL':
      case 'ERROR':
        sevColor = FactoryColors.statusOffline;
        break;
      case 'WARNING':
        sevColor = Colors.amber;
        break;
      default:
        sevColor = FactoryColors.primaryBlue;
    }

    final timeStr = evt.timestamp.length >= 19 ? evt.timestamp.substring(11, 19) : evt.timestamp;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(evt.severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sevColor)),
          ),
          const SizedBox(width: 10),
          Text(timeStr, style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evt.message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary)),
                Text('${evt.eventType} • Source: ${evt.source}', style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
