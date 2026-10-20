import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../controllers/factory_controller.dart';

class FacilityOverviewScreen extends ConsumerWidget {
  const FacilityOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(factoryControllerProvider);
    final factory = state.selectedFactory;
    final overview = state.overview;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    if (factory == null || overview == null) {
      return const EmptyStateView(
        title: 'No Facility Selected',
        message: 'Select a facility to inspect comprehensive infrastructure details.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FactorySpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FactorySpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facility Infrastructure & Governance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comprehensive technical profile and operational parameters for ${factory.name}',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: FactorySpacing.lg),

              // Grid of facility specifications
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary Specifications
                  Expanded(
                    flex: 6,
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
                          Text(
                            'FACILITY SPECIFICATIONS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: FactorySpacing.md),
                          _specRow('Facility Name', factory.name, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Enterprise Code', factory.code, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Industry Domain', factory.industryTypeDisplay, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Location', factory.location, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Country', factory.country, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Timezone', factory.timezone, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Operational Status', '', textPrimary, textSecondary,
                              customWidget: StatusBadge(
                                status: factory.configurationStatus,
                                label: factory.configurationStatusDisplay,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: FactorySpacing.lg),
                  // Automation & Holding
                  Expanded(
                    flex: 4,
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
                          Text(
                            'OPERATIONAL GOVERNANCE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: FactorySpacing.md),
                          _specRow('Enterprise Parent', 'Universal Global Corp', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Platform Engine', 'FactoryOS AI Core v1.0', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Database Tier', 'PostgreSQL 18 Enterprise', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Line Capacity', '${factory.totalProductionLines} automated cells', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Active Lines', '${factory.activeLines} operational', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _specRow('Active Shifts', '3 Rotating Daily Shifts', textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value, Color textPrimary, Color textSecondary, {Widget? customWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
        customWidget ??
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
      ],
    );
  }
}
