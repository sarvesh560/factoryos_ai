/// FactoryOS AI — Company & Factory Directory Screen
/// Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/factory_button.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../controllers/company_controller.dart';
import '../controllers/factory_controller.dart';
import '../../data/models/factory_model.dart';

class CompanyManagementScreen extends ConsumerWidget {
  const CompanyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(companyControllerProvider);
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

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
                        'Enterprise Companies & Factories',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage organizational holdings, multi-facility structures, and operational states.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                Row(
                  children: [
                    // Include Archived Switch
                    Row(
                      children: [
                        Text(
                          'Show Archived',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Switch(
                          value: state.includeArchived,
                          onChanged: (_) => ref.read(companyControllerProvider.notifier).toggleIncludeArchived(),
                        ),
                      ],
                    ),
                    const SizedBox(width: FactorySpacing.md),
                    // Add Company Button
                    FactoryButton(
                      text: 'Register Company',
                      icon: Icons.add_business_rounded,
                      variant: ButtonVariant.primary,
                      onPressed: () => _showCompanyDialog(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Notification Messages
            if (state.errorMessage != null)
              Container(
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
                    Expanded(child: Text(state.errorMessage!, style: const TextStyle(color: FactoryColors.statusOffline, fontSize: 13))),
                  ],
                ),
              ),

            if (state.successMessage != null)
              Container(
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
                    Expanded(child: Text(state.successMessage!, style: const TextStyle(color: FactoryColors.statusRunning, fontSize: 13))),
                  ],
                ),
              ),

            // Companies List
            if (state.isLoading)
              const Column(
                children: [
                  SkeletonLoader(width: double.infinity, height: 160, borderRadius: FactoryRadius.md),
                  SizedBox(height: FactorySpacing.md),
                  SkeletonLoader(width: double.infinity, height: 160, borderRadius: FactoryRadius.md),
                ],
              )
            else if (state.companies.isEmpty)
              EmptyStateView(
                title: 'No Companies Registered',
                message: 'Add your first enterprise company to group manufacturing facilities.',
                actionText: 'Register Company',
                onAction: () => _showCompanyDialog(context, ref),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.companies.length,
                separatorBuilder: (context, _) => const SizedBox(height: FactorySpacing.lg),
                itemBuilder: (context, index) {
                  final company = state.companies[index];
                  return _CompanyCard(company: company);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCompanyDialog(BuildContext context, WidgetRef ref, [CompanyItem? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final webCtrl = TextEditingController(text: existing?.website ?? '');
    final emailCtrl = TextEditingController(text: existing?.contactEmail ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Register Enterprise Company' : 'Edit Company Details'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Name *', hintText: 'e.g. Apex Global Industries'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Mission and scope of holding'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: webCtrl,
                decoration: const InputDecoration(labelText: 'Website', hintText: 'https://example.com'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Operations Email', hintText: 'ops@example.com'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              if (existing == null) {
                await ref.read(companyControllerProvider.notifier).createCompany(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      website: webCtrl.text.trim(),
                      contactEmail: emailCtrl.text.trim(),
                    );
              } else {
                await ref.read(companyControllerProvider.notifier).updateCompany(
                  existing.id,
                  {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'website': webCtrl.text.trim(),
                    'contact_email': emailCtrl.text.trim(),
                  },
                );
              }
            },
            child: Text(existing == null ? 'Create Company' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}

class _CompanyCard extends ConsumerStatefulWidget {
  final CompanyItem company;

  const _CompanyCard({required this.company});

  @override
  ConsumerState<_CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends ConsumerState<_CompanyCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    final company = widget.company;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(FactorySpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FactoryColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FactoryRadius.md),
                  ),
                  child: const Icon(Icons.business_rounded, color: FactoryColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: FactorySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            company.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            status: company.isActive ? 'RUNNING' : 'OFFLINE',
                            label: company.isActive ? 'Active Holding' : 'Archived Holding',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        company.description.isNotEmpty ? company.description : 'Multi-facility manufacturing corporation',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Factory Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? FactoryColors.darkSurfaceVariant : FactoryColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(FactoryRadius.sm),
                  ),
                  child: Text(
                    '${company.factories.length} ${company.factories.length == 1 ? "Factory" : "Factories"}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                // Archive Toggle Button
                IconButton(
                  tooltip: company.isActive ? 'Archive Company' : 'Unarchive Company',
                  icon: Icon(
                    company.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                    size: 18,
                    color: textSecondary,
                  ),
                  onPressed: () {
                    ref.read(companyControllerProvider.notifier).toggleArchiveCompany(company.id);
                  },
                ),
                // Expand/Collapse
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),

          // Child Factories List (if expanded)
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (company.factories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(FactorySpacing.lg),
                child: Center(
                  child: Text(
                    'No factories onboarded under this company yet. Click "Onboard Factory" to add one.',
                    style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: company.factories.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, fIdx) {
                  final f = company.factories[fIdx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: FactorySpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.factory_outlined, size: 20, color: FactoryColors.primaryBlue),
                        const SizedBox(width: FactorySpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    f.name,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('[${f.code}]', style: TextStyle(fontSize: 12, color: textSecondary)),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    status: f.isActive ? 'RUNNING' : 'OFFLINE',
                                    label: f.isActive ? 'Active' : 'Archived',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${f.industryTypeDisplay}  •  ${f.location}, ${f.country}  •  ${f.totalProductionLines} lines  •  Operating: ${f.operatingHours}',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                              if (f.capabilities.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: f.capabilities.take(3).map((cap) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: FactoryColors.primaryBlue.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(cap, style: const TextStyle(fontSize: 9, color: FactoryColors.primaryBlue)),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Quick switch to this factory
                        TextButton.icon(
                          icon: const Icon(Icons.dashboard_outlined, size: 14),
                          label: const Text('Open in Command Center', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            ref.read(factoryControllerProvider.notifier).selectFactory(f);
                            context.go('/command-center');
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: f.isActive ? 'Archive Factory' : 'Unarchive Factory',
                          icon: Icon(
                            f.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                            size: 16,
                            color: textSecondary,
                          ),
                          onPressed: () {
                            ref.read(companyControllerProvider.notifier).toggleArchiveFactory(f.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
