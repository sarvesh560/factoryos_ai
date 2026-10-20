import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/factory_button.dart';
import '../../../../shared/widgets/factory_data_table.dart';
import '../../../../shared/widgets/factory_dialog.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/factory_model.dart';
import '../controllers/factory_controller.dart';


class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(factoryControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isInitialLoading) {
      return _buildLoadingState(isDark);
    }

    if (state.errorMessage != null && state.overview == null) {
      return ErrorStateView(
        title: 'Factory Telemetry Unavailable',
        message: 'Could not connect to FactoryOS AI backend services to retrieve factory operational data.',
        technicalDetails: state.errorMessage,
        onRetry: () => ref.read(factoryControllerProvider.notifier).loadFactories(),
      );
    }

    final overview = state.overview;
    final selectedFactory = state.selectedFactory;

    if (overview == null || selectedFactory == null) {
      return EmptyStateView(
        title: 'No Active Factory Selected',
        message: 'Select a manufacturing facility from the top bar to inspect live telemetry and production line status.',
        actionText: 'Load Factories',
        onAction: () => ref.read(factoryControllerProvider.notifier).loadFactories(),
      );
    }

    final metrics = overview.metrics;
    final lines = overview.productionLines;
    final summary = overview.linesSummary;
    final shift = overview.shiftProgress;
    final alerts = overview.alertsSummary;

    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FactorySpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FactorySpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Facility Banner Header
              Container(
                padding: const EdgeInsets.all(FactorySpacing.xl),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: isDark ? FactoryShadows.darkCard : FactoryShadows.card,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: FactoryColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FactoryRadius.md),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing,
                        size: 26,
                        color: FactoryColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: FactorySpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                selectedFactory.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: FactorySpacing.sm),
                              StatusBadge(
                                status: selectedFactory.configurationStatus,
                                label: selectedFactory.configurationStatusDisplay,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${selectedFactory.code} • ${selectedFactory.industryTypeDisplay}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                '${selectedFactory.location}, ${selectedFactory.country}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action: Factory Info Dialog
                    FactoryButton(
                      text: 'Facility Details',
                      variant: ButtonVariant.outline,
                      icon: Icons.info_outline,
                      onPressed: () {
                        _showFacilityDetailsDialog(context, selectedFactory);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: FactorySpacing.lg),

              // 2. Primary KPI Telemetry Row (OEE, Availability, Performance, Quality)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final cardWidth = isWide ? (constraints.maxWidth - 3 * FactorySpacing.lg) / 4 : (constraints.maxWidth - FactorySpacing.md) / 2;

                  final oeeVal = metrics != null ? '${metrics.overallOee.toStringAsFixed(1)}%' : '—';
                  final availVal = metrics != null ? '${metrics.availability.toStringAsFixed(1)}%' : '—';
                  final perfVal = metrics != null ? '${metrics.performance.toStringAsFixed(1)}%' : '—';
                  final qualVal = metrics != null ? '${metrics.qualityRate.toStringAsFixed(1)}%' : '—';

                  return Wrap(
                    spacing: FactorySpacing.lg,
                    runSpacing: FactorySpacing.md,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          title: 'Overall OEE',
                          value: oeeVal,
                          subtitle: 'Target: 85.0%',
                          icon: Icons.speed_rounded,
                          accentColor: FactoryColors.kpiOee,
                          trendText: '+2.4%',
                          isPositiveTrend: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          title: 'Machine Availability',
                          value: availVal,
                          subtitle: '${summary.running} of ${summary.total} lines active',
                          icon: Icons.check_circle_outline,
                          accentColor: FactoryColors.kpiAvailability,
                          trendText: '+0.8%',
                          isPositiveTrend: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          title: 'Throughput Performance',
                          value: perfVal,
                          subtitle: 'Design speed ratio',
                          icon: Icons.bolt_outlined,
                          accentColor: FactoryColors.kpiPerformance,
                          trendText: '+1.5%',
                          isPositiveTrend: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          title: 'Quality First Pass',
                          value: qualVal,
                          subtitle: 'Scrap: ${metrics?.scrapUnits ?? 0} units',
                          icon: Icons.verified_outlined,
                          accentColor: FactoryColors.kpiQuality,
                          trendText: '+0.2%',
                          isPositiveTrend: true,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: FactorySpacing.lg),

              // 3. Operational Overview Cards (Lines Status Distribution & Shift Progress)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Production Line Status Breakdown
                      Expanded(
                        flex: isWide ? 6 : 1,
                        child: Container(
                          padding: const EdgeInsets.all(FactorySpacing.xl),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(FactoryRadius.md),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PRODUCTION CELLS STATUS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${summary.total} TOTAL CELLS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FactorySpacing.lg),
                              // Progress bar breakdown
                              ClipRRect(
                                borderRadius: BorderRadius.circular(FactoryRadius.sm),
                                child: SizedBox(
                                  height: 12,
                                  child: Row(
                                    children: [
                                      if (summary.running > 0)
                                        Expanded(
                                          flex: summary.running,
                                          child: Container(color: FactoryColors.statusRunning),
                                        ),
                                      if (summary.idle > 0)
                                        Expanded(
                                          flex: summary.idle,
                                          child: Container(color: FactoryColors.statusIdle),
                                        ),
                                      if (summary.maintenance > 0)
                                        Expanded(
                                          flex: summary.maintenance,
                                          child: Container(color: FactoryColors.statusMaintenance),
                                        ),
                                      if (summary.offline > 0)
                                        Expanded(
                                          flex: summary.offline,
                                          child: Container(color: FactoryColors.statusOffline),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: FactorySpacing.lg),
                              // Legend Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _StatusLegendItem(
                                    color: FactoryColors.statusRunning,
                                    label: 'Running',
                                    count: summary.running,
                                    textPrimary: textPrimary,
                                  ),
                                  _StatusLegendItem(
                                    color: FactoryColors.statusIdle,
                                    label: 'Idle',
                                    count: summary.idle,
                                    textPrimary: textPrimary,
                                  ),
                                  _StatusLegendItem(
                                    color: FactoryColors.statusMaintenance,
                                    label: 'Maintenance',
                                    count: summary.maintenance,
                                    textPrimary: textPrimary,
                                  ),
                                  _StatusLegendItem(
                                    color: FactoryColors.statusOffline,
                                    label: 'Offline',
                                    count: summary.offline,
                                    textPrimary: textPrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: FactorySpacing.lg),
                      // Shift Target & Energy Telemetry Card
                      Expanded(
                        flex: isWide ? 4 : 1,
                        child: Container(
                          padding: const EdgeInsets.all(FactorySpacing.xl),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(FactoryRadius.md),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SHIFT PRODUCTION TARGET',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    shift.currentShift,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: FactoryColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FactorySpacing.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${NumberFormat('#,###').format(shift.actualUnits)} / ${NumberFormat('#,###').format(shift.plannedUnits)} units',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${shift.completionPercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: FactoryColors.statusRunning,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FactorySpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(FactoryRadius.pill),
                                child: LinearProgressIndicator(
                                  value: (shift.completionPercentage / 100).clamp(0.0, 1.0),
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(FactoryColors.primaryBlue),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: FactorySpacing.md),
                              // Sub-metrics: Energy & Alerts
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt, size: 14, color: FactoryColors.kpiEnergy),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${metrics?.energyConsumptionKwh.toStringAsFixed(1) ?? '—'} kWh',
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 14, color: FactoryColors.statusIdle),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${alerts.totalActive} Active Alerts',
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: FactorySpacing.xl),

              // 4. Live Production Lines Telemetry Data Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Production Cells Telemetry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Real-time automated line telemetry streamed directly from PostgreSQL database',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'Updated: ${state.lastUpdated != null ? DateFormat('HH:mm:ss').format(state.lastUpdated!) : '—'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FactorySpacing.md),
              FactoryDataTable(
                lines: lines,
                onLineTap: (line) {
                  _showLineDetailsDialog(context, line);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FactorySpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FactorySpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader(width: double.infinity, height: 84),
              const SizedBox(height: FactorySpacing.lg),
              Row(
                children: List.generate(
                  4,
                  (index) => const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SkeletonLoader(width: double.infinity, height: 110),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: FactorySpacing.lg),
              const SkeletonLoader(width: double.infinity, height: 140),
              const SizedBox(height: FactorySpacing.xl),
              const SkeletonLoader(width: double.infinity, height: 320),
            ],
          ),
        ),
      ),
    );
  }

  void _showFacilityDetailsDialog(BuildContext context, FactoryItem factory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    FactoryDialog.show(
      context: context,
      title: 'Facility Technical Specifications',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _specRow('Facility Name', factory.name, textSecondary),
          _specRow('Enterprise Code', factory.code, textSecondary),
          _specRow('Industry Domain', factory.industryTypeDisplay, textSecondary),
          _specRow('Location & Country', '${factory.location}, ${factory.country}', textSecondary),
          _specRow('Facility Timezone', factory.timezone, textSecondary),
          _specRow('Total Production Lines', '${factory.totalProductionLines} lines', textSecondary),
          _specRow('Active Operational Lines', '${factory.activeLines} lines', textSecondary),
          _specRow('Automation System', 'FactoryOS AI Platform v1.0', textSecondary),
        ],
      ),
    );
  }

  void _showLineDetailsDialog(BuildContext context, ProductionLineItem line) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    FactoryDialog.show(
      context: context,
      title: 'Cell Details — ${line.name}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _specRow('Cell Code', line.code, textSecondary),
          _specRow('Status', line.statusDisplay, textSecondary),
          _specRow('Active Product', line.currentProduct.isEmpty ? 'Idle' : line.currentProduct, textSecondary),
          _specRow('Efficiency Rate', '${line.efficiencyRate.toStringAsFixed(1)}%', textSecondary),
          _specRow('Hourly Target', '${line.targetHourlyUnits} units/hour', textSecondary),
          _specRow('Actual Output', '${line.actualHourlyUnits} units/hour', textSecondary),
          _specRow('Assigned Operators', '${line.operatorCount} personnel', textSecondary),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final Color textPrimary;

  const _StatusLegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
