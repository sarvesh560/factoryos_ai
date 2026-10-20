/// FactoryOS AI — Manufacturing Process Library Screen
/// Phase 3: Process Workflow Catalog, Template Instantiation, Duplication & Safe Archival
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../factories/data/models/factory_model.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';
import '../controllers/process_library_controller.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class ProcessLibraryScreen extends ConsumerStatefulWidget {
  const ProcessLibraryScreen({super.key});

  @override
  ConsumerState<ProcessLibraryScreen> createState() => _ProcessLibraryScreenState();
}

class _ProcessLibraryScreenState extends ConsumerState<ProcessLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(processLibraryControllerProvider);
    final notifier = ref.read(processLibraryControllerProvider.notifier);
    final currentFactory = ref.watch(factoryControllerProvider).selectedFactory;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final filtered = state.filteredDefinitions;

    // Derive industry and category options from existing definitions and templates
    final industries = <String>{};
    final categories = <String>{};
    for (final def in state.definitions) {
      if (def.industryType.isNotEmpty) industries.add(def.industryType);
      if (def.category.isNotEmpty) categories.add(def.category);
    }
    for (final t in state.templates) {
      if (t.industryType.isNotEmpty) industries.add(t.industryType);
      if (t.category.isNotEmpty) categories.add(t.category);
    }

    final hasActiveFilters = state.searchQuery.isNotEmpty ||
        state.selectedIndustry != null ||
        state.selectedCategory != null ||
        state.selectedStatus != 'ALL';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FactorySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Actions
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FactorySpacing.md,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        Text(
                          'Universal Process Workflows',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FactoryColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(FactoryRadius.sm),
                            border: Border.all(color: FactoryColors.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${filtered.length} Workflows',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: FactoryColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Design, instantiate industry templates, version, and manage manufacturing routing graphs.',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: FactorySpacing.md),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('start_from_template_button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FactoryColors.primaryBlue,
                        side: const BorderSide(color: FactoryColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Start from Industry Template', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => _showTemplatePickerDialog(context, ref, currentFactory),
                    ),
                    ElevatedButton.icon(
                      key: const Key('new_process_workflow_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FactoryColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Process Workflow', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => _showCreateDialog(context, ref, currentFactory?.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Notification Banners
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
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: FactoryColors.statusOffline, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: FactoryColors.statusOffline),
                      onPressed: () => notifier.clearFilters(),
                    ),
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
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(color: FactoryColors.statusRunning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Search & Comprehensive Filter Controls
            Container(
              padding: const EdgeInsets.all(FactorySpacing.md),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(FactoryRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Search Box & Clear
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('process_search_field'),
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: 'Search workflows by name or code (e.g., CNC, EV, PROC-01)...',
                            hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) => notifier.setSearchQuery(val),
                        ),
                      ),
                      if (state.searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            notifier.setSearchQuery('');
                          },
                        ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Row 2: Status chips, Industry & Category dropdowns, Reset button
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Status Segmented Filter Chips
                      Wrap(
                        spacing: 6,
                        children: ['ALL', 'PUBLISHED', 'DRAFT', 'ARCHIVED'].map((status) {
                          final isSelected = state.selectedStatus == status;
                          return ChoiceChip(
                            key: Key('filter_status_$status'),
                            label: Text(
                              status == 'ALL' ? 'All Status' : status[0] + status.substring(1).toLowerCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: FactoryColors.primaryBlue,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            onSelected: (selected) {
                              if (selected) notifier.setStatusFilter(status);
                            },
                          );
                        }).toList(),
                      ),

                      // Industry Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161B22) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(FactoryRadius.sm),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            key: const Key('filter_industry_dropdown'),
                            value: state.selectedIndustry,
                            hint: Text('Industry: All', style: TextStyle(fontSize: 12, color: textSecondary)),
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            isDense: true,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Industries', style: TextStyle(fontSize: 12)),
                              ),
                              ...industries.map((ind) => DropdownMenuItem<String?>(
                                    value: ind,
                                    child: Text(ind.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                            onChanged: (val) => notifier.setIndustryFilter(val),
                          ),
                        ),
                      ),

                      // Category Filter Dropdown
                      if (categories.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161B22) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(FactoryRadius.sm),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              key: const Key('filter_category_dropdown'),
                              value: state.selectedCategory,
                              hint: Text('Category: All', style: TextStyle(fontSize: 12, color: textSecondary)),
                              icon: const Icon(Icons.arrow_drop_down, size: 18),
                              isDense: true,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Categories', style: TextStyle(fontSize: 12)),
                                ),
                                ...categories.map((cat) => DropdownMenuItem<String?>(
                                      value: cat,
                                      child: Text(cat, style: const TextStyle(fontSize: 12)),
                                    )),
                              ],
                              onChanged: (val) => notifier.setCategoryFilter(val),
                            ),
                          ),
                        ),

                      // Reset Filters Button
                      if (hasActiveFilters)
                        TextButton.icon(
                          key: const Key('reset_filters_button'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: FactoryColors.statusOffline,
                          ),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            _searchCtrl.clear();
                            notifier.clearFilters();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Workflows Grid or States
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(
                      hasActiveFilters ? Icons.filter_alt_off_outlined : Icons.account_tree_outlined,
                      size: 48,
                      color: textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasActiveFilters ? 'No Matching Process Workflows' : 'No Process Workflows Found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasActiveFilters
                          ? 'No workflows match your active search and filter criteria. Try resetting filters.'
                          : 'Create your first universal manufacturing workflow or pick from code-defined industry templates.',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    if (hasActiveFilters)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Clear All Filters'),
                        onPressed: () {
                          _searchCtrl.clear();
                          notifier.clearFilters();
                        },
                      )
                    else
                      Wrap(
                        spacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FactoryColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Start from Industry Template'),
                            onPressed: () => _showTemplatePickerDialog(context, ref, currentFactory),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Process Workflow'),
                            onPressed: () => _showCreateDialog(context, ref, currentFactory?.id),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 480,
                  mainAxisExtent: 320,
                  crossAxisSpacing: FactorySpacing.lg,
                  mainAxisSpacing: FactorySpacing.lg,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final proc = filtered[idx];
                  return _buildProcessCard(context, ref, proc, isDark, textPrimary, textSecondary, cardBg, borderColor);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessCard(
    BuildContext context,
    WidgetRef ref,
    ProcessDefinitionItem proc,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    final isArchived = !proc.isActive;
    final hasPublished = proc.publishedVersionTag != null && !isArchived;

    // Archived styling: muted colors, clear inactive status
    final effectiveCardBg = isArchived
        ? (isDark ? const Color(0xFF161B22).withValues(alpha: 0.6) : const Color(0xFFF1F5F9))
        : cardBg;
    final effectiveBorderColor = isArchived
        ? (isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1))
        : borderColor;
    final effectiveTitleColor = isArchived
        ? textSecondary
        : textPrimary;

    return Container(
      padding: const EdgeInsets.all(FactorySpacing.lg),
      decoration: BoxDecoration(
        color: effectiveCardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: effectiveBorderColor, width: isArchived ? 1.0 : 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status Badge & Actions Overflow Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proc.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: effectiveTitleColor,
                        decoration: isArchived ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          proc.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isArchived ? textSecondary : FactoryColors.primaryBlue,
                          ),
                        ),
                        if (proc.industryType.isNotEmpty) ...[
                          Text(' • ', style: TextStyle(fontSize: 11, color: textSecondary)),
                          Text(
                            proc.industryType.replaceAll('_', ' '),
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isArchived
                      ? const Color(0xFF6B7280).withValues(alpha: 0.15)
                      : (hasPublished ? FactoryColors.statusRunningBgLight : FactoryColors.statusIdleBgLight),
                  borderRadius: BorderRadius.circular(FactoryRadius.sm),
                  border: Border.all(
                    color: isArchived
                        ? const Color(0xFF6B7280).withValues(alpha: 0.4)
                        : (hasPublished ? FactoryColors.statusRunningBorderLight : FactoryColors.statusIdleBorderLight),
                  ),
                ),
                child: Text(
                  isArchived
                      ? 'Archived'
                      : (hasPublished ? proc.publishedVersionTag! : 'Draft'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isArchived
                        ? const Color(0xFF6B7280)
                        : (hasPublished ? FactoryColors.statusRunning : FactoryColors.statusIdle),
                  ),
                ),
              ),

              // Card Context Menu (Duplicate, Archive)
              PopupMenuButton<String>(
                key: Key('process_card_menu_${proc.id}'),
                icon: Icon(Icons.more_vert, size: 18, color: textSecondary),
                tooltip: 'Process Options',
                onSelected: (value) {
                  if (value == 'duplicate') {
                    _showDuplicateDialog(context, ref, proc);
                  } else if (value == 'archive') {
                    _showArchiveDialog(context, ref, proc);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined, size: 16, color: FactoryColors.primaryBlue),
                        SizedBox(width: 8),
                        Text('Duplicate Workflow', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!isArchived)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 16, color: FactoryColors.statusOffline),
                          SizedBox(width: 8),
                          Text('Archive Workflow', style: TextStyle(fontSize: 12, color: FactoryColors.statusOffline)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            proc.description.isNotEmpty ? proc.description : 'Universal manufacturing routing workflow.',
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Metadata row
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text('${proc.targetCycleTimeSeconds}s nominal', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text('${proc.versionCount} versions', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    proc.category,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Versions preview pills
          if (proc.versions.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: proc.versions.take(3).map((v) {
                final isPub = v.isPublished;
                return InkWell(
                  onTap: () => context.go('/processes/${v.id}/builder'),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPub ? FactoryColors.statusRunningBgLight : FactoryColors.statusIdleBgLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isPub ? FactoryColors.statusRunningBorderLight : FactoryColors.statusIdleBorderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${v.versionTag} (${v.status.toLowerCase()})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isPub ? FactoryColors.statusRunning : FactoryColors.statusIdle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          isPub ? Icons.visibility_outlined : Icons.edit_outlined,
                          size: 11,
                          color: isPub ? FactoryColors.statusRunning : FactoryColors.statusIdle,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const Spacer(),

          // Card Footer Action
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (isArchived)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Read-Only Archived Process',
                      style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              OutlinedButton.icon(
                key: Key('open_canvas_button_${proc.id}'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.edit_road_outlined, size: 14),
                label: Text(
                  isArchived ? 'View Graph Canvas' : 'Open Visual Canvas',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  String? versionId = proc.latestVersionId ?? (proc.versions.isNotEmpty ? proc.versions.first.id : null);
                  if (versionId == null) {
                    try {
                      final detail = await ref.read(processRepositoryProvider).getProcessDefinition(proc.id);
                      versionId = detail.latestVersionId ?? (detail.versions.isNotEmpty ? detail.versions.first.id : null);
                    } catch (_) {}
                  }
                  if (versionId != null && context.mounted) {
                    context.go('/processes/$versionId/builder');
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No version available for ${proc.name}')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. PROCESS TEMPLATE PICKER & BROWSER DIALOG
  // ===========================================================================

  void _showTemplatePickerDialog(BuildContext context, WidgetRef ref, FactoryItem? currentFactory) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dlgCtx) => _TemplateBrowserDialog(
        currentFactory: currentFactory,
        onTemplateSelected: (template) {
          Navigator.pop(dlgCtx);
          _showInstantiateDialog(context, ref, template, currentFactory);
        },
      ),
    );
  }

  // ===========================================================================
  // 2. TEMPLATE INSTANTIATION FORM DIALOG
  // ===========================================================================

  void _showInstantiateDialog(
    BuildContext context,
    WidgetRef ref,
    ProcessTemplateItem template,
    FactoryItem? currentFactory,
  ) {
    if (currentFactory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Please select an active authorized factory before instantiating templates.')),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: template.name);
    final codeCtrl = TextEditingController(
      text: 'PRC-${template.key.substring(0, 3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final descCtrl = TextEditingController(text: template.description);
    final cycleCtrl = TextEditingController(text: template.nominalCycleTimeSeconds.toString());
    bool isSubmitting = false;
    String? validationError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (instCtx) => StatefulBuilder(
        builder: (instCtx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: FactoryColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Instantiate Process Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Header Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FactoryColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                        border: Border.all(color: FactoryColors.primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                template.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FactoryColors.primaryBlue),
                              ),
                              Text(
                                template.industryType.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FactoryColors.primaryBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target Factory: ${currentFactory.name} [${currentFactory.code}]',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (validationError != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: FactoryColors.statusOfflineBgLight,
                          borderRadius: BorderRadius.circular(FactoryRadius.sm),
                          border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: FactoryColors.statusOffline),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(fontSize: 12, color: FactoryColors.statusOffline),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      key: const Key('template_instantiate_name'),
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Process Definition Name *',
                        hintText: 'e.g. 5-Axis Precision Machining Cell',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('template_instantiate_code'),
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Process Code *',
                        hintText: 'e.g. PRC-CNC-01',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('template_instantiate_cycle'),
                      controller: cycleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Nominal Cycle Time (seconds) *',
                        hintText: '60.0',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('template_instantiate_desc'),
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Operational routing instructions...',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(instCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                key: const Key('template_instantiate_submit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactoryColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 16),
                label: Text(isSubmitting ? 'Instantiating...' : 'Instantiate Process'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim();
                        final cycle = double.tryParse(cycleCtrl.text.trim());

                        if (name.isEmpty) {
                          setDialogState(() => validationError = 'Process name is required.');
                          return;
                        }
                        if (code.isEmpty) {
                          setDialogState(() => validationError = 'Process code is required.');
                          return;
                        }
                        if (cycle == null || cycle <= 0) {
                          setDialogState(() => validationError = 'Valid cycle time in seconds is required.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          validationError = null;
                        });

                        try {
                          final newProc = await ref.read(processLibraryControllerProvider.notifier).instantiateTemplate(
                                templateKey: template.key,
                                factoryId: currentFactory.id,
                                name: name,
                                code: code,
                                description: descCtrl.text.trim(),
                                targetCycleTimeSeconds: cycle,
                              );

                          if (context.mounted) {
                            Navigator.pop(instCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Process '${newProc?.name ?? name}' instantiated successfully.")),
                            );
                            final versionId = newProc?.latestVersionId ??
                                (newProc?.versions.isNotEmpty == true ? newProc!.versions.first.id : null);
                            if (versionId != null) {
                              context.go('/processes/$versionId/builder');
                            }
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            validationError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. DUPLICATE PROCESS DIALOG
  // ===========================================================================

  void _showDuplicateDialog(BuildContext context, WidgetRef ref, ProcessDefinitionItem sourceProc) {
    final nameCtrl = TextEditingController(text: '${sourceProc.name} (Copy)');
    final codeCtrl = TextEditingController(text: '${sourceProc.code}-COPY');
    final descCtrl = TextEditingController(text: sourceProc.description);
    bool isSubmitting = false;
    String? duplicateError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dupCtx) => StatefulBuilder(
        builder: (dupCtx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.copy_outlined, color: FactoryColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text('Duplicate Process Workflow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duplicating creates a separate, independent process definition with a new editable Draft v1.0.0 graph copied from the source.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 14),

                  if (duplicateError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: FactoryColors.statusOfflineBgLight,
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                        border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                      ),
                      child: Text(
                        duplicateError!,
                        style: const TextStyle(fontSize: 12, color: FactoryColors.statusOffline),
                      ),
                    ),

                  TextField(
                    key: const Key('duplicate_process_name'),
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'New Process Name *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('duplicate_process_code'),
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'New Process Code *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('duplicate_process_desc'),
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', isDense: true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dupCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                key: const Key('duplicate_process_submit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactoryColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 16),
                label: Text(isSubmitting ? 'Duplicating...' : 'Duplicate Workflow'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim();
                        if (name.isEmpty || code.isEmpty) {
                          setDialogState(() => duplicateError = 'Name and code are required.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          duplicateError = null;
                        });

                        try {
                          final currentFactory = ref.read(factoryControllerProvider).selectedFactory;
                          final duplicated = await ref.read(processLibraryControllerProvider.notifier).duplicateDefinition(
                                id: sourceProc.id,
                                name: name,
                                code: code,
                                description: descCtrl.text.trim(),
                                factoryId: currentFactory?.id,
                              );

                          if (context.mounted) {
                            Navigator.pop(dupCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Process '${duplicated?.name ?? name}' duplicated.")),
                            );
                            final versionId = duplicated?.latestVersionId ??
                                (duplicated?.versions.isNotEmpty == true ? duplicated!.versions.first.id : null);
                            if (versionId != null) {
                              context.go('/processes/$versionId/builder');
                            }
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            duplicateError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. ARCHIVE PROCESS CONFIRMATION DIALOG
  // ===========================================================================

  void _showArchiveDialog(BuildContext context, WidgetRef ref, ProcessDefinitionItem proc) {
    bool isArchiving = false;
    String? archiveError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (arcCtx) => StatefulBuilder(
        builder: (arcCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.archive_outlined, color: FactoryColors.statusOffline, size: 22),
                SizedBox(width: 8),
                Text('Archive Process Definition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Are you sure you want to archive '${proc.name}' [${proc.code}]?",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• The process definition and its draft versions will become inactive.\n'
                    '• Active work orders cannot be created against an archived process.\n'
                    '• Historical work order data and logs are permanently preserved.\n'
                    '• This operation does NOT delete any database records.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),

                  if (archiveError != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FactoryColors.statusOfflineBgLight,
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                        border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.block, size: 16, color: FactoryColors.statusOffline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              archiveError!,
                              style: const TextStyle(fontSize: 12, color: FactoryColors.statusOffline, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isArchiving ? null : () => Navigator.pop(arcCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                key: const Key('confirm_archive_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactoryColors.statusOffline,
                  foregroundColor: Colors.white,
                ),
                icon: isArchiving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.archive, size: 16),
                label: Text(isArchiving ? 'Archiving...' : 'Archive Process'),
                onPressed: isArchiving
                    ? null
                    : () async {
                        setDialogState(() {
                          isArchiving = true;
                          archiveError = null;
                        });

                        try {
                          final currentFactory = ref.read(factoryControllerProvider).selectedFactory;
                          await ref.read(processLibraryControllerProvider.notifier).archiveDefinition(
                                proc.id,
                                factoryId: currentFactory?.id,
                              );

                          if (context.mounted) {
                            Navigator.pop(arcCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Process '${proc.name}' safely archived.")),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isArchiving = false;
                            archiveError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5. CREATE CUSTOM DEFINITION DIALOG
  // ===========================================================================

  void _showCreateDialog(BuildContext context, WidgetRef ref, String? defaultFactoryId) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'PROC-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final descCtrl = TextEditingController();
    final cycleCtrl = TextEditingController(text: '60.0');
    String category = 'General Manufacturing';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: const Text('Create Manufacturing Process Workflow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('create_process_name_field'),
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Workflow Name *', hintText: 'e.g. EV Battery Pack Assembly'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('create_process_code_field'),
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Process Code *', hintText: 'e.g. PROC-BATT-01'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Industrial Category'),
                      items: const [
                        DropdownMenuItem(value: 'General Manufacturing', child: Text('General Manufacturing')),
                        DropdownMenuItem(value: 'Automotive & EV', child: Text('Automotive & EV')),
                        DropdownMenuItem(value: 'CNC Precision Machining', child: Text('CNC Precision Machining')),
                        DropdownMenuItem(value: 'Textile & Apparel', child: Text('Textile & Apparel')),
                        DropdownMenuItem(value: 'Food & Beverage', child: Text('Food & Beverage')),
                        DropdownMenuItem(value: 'Electronics & SMT', child: Text('Electronics & SMT')),
                        DropdownMenuItem(value: 'Pharmaceutical & Cleanroom', child: Text('Pharmaceutical & Cleanroom')),
                      ],
                      onChanged: (val) => setDlgState(() => category = val ?? category),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cycleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target Cycle Time (seconds)', hintText: '60.0'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Process Description', hintText: 'Operational overview...'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                key: const Key('create_process_submit_button'),
                style: ElevatedButton.styleFrom(backgroundColor: FactoryColors.primaryBlue, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final factoryId = defaultFactoryId ?? '';
                  final newId = await ref.read(processLibraryControllerProvider.notifier).createDefinition(
                    factoryId: factoryId,
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: category,
                    targetCycleTimeSeconds: double.tryParse(cycleCtrl.text.trim()) ?? 60.0,
                  );
                  if (newId != null && context.mounted) {
                    ref.read(processLibraryControllerProvider.notifier).loadDefinitions(factoryId: factoryId);
                  }
                },
                child: const Text('Create & Initialize Graph'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// TEMPLATE BROWSER DIALOG WIDGET
// =============================================================================

class _TemplateBrowserDialog extends ConsumerStatefulWidget {
  final FactoryItem? currentFactory;
  final void Function(ProcessTemplateItem template) onTemplateSelected;

  const _TemplateBrowserDialog({
    required this.currentFactory,
    required this.onTemplateSelected,
  });

  @override
  ConsumerState<_TemplateBrowserDialog> createState() => _TemplateBrowserDialogState();
}

class _TemplateBrowserDialogState extends ConsumerState<_TemplateBrowserDialog> {
  String? _selectedIndustry;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(processLibraryControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final templates = state.templates.where((t) {
      if (_selectedIndustry != null && t.industryType != _selectedIndustry) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!t.name.toLowerCase().contains(q) &&
            !t.description.toLowerCase().contains(q) &&
            !t.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.md)),
      child: Container(
        width: 900,
        height: 650,
        padding: const EdgeInsets.all(FactorySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: FactoryColors.primaryBlue, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Universal Manufacturing Process Templates',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a code-defined production topology with validated nodes, DAG routing, and stage sequences.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Filter bar: Search & Industry Dropdown
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('template_search_input'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: 'Search templates by name or keyword...',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    onChanged: (val) => setState(() => _search = val.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FactoryRadius.sm),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      key: const Key('template_industry_filter'),
                      value: _selectedIndustry,
                      hint: Text('All Industries', style: TextStyle(fontSize: 12, color: textSecondary)),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Industries', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'CNC_ENGINEERING', child: Text('CNC Engineering', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'AUTOMOTIVE', child: Text('Automotive & EV', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'ELECTRONICS', child: Text('Electronics & SMT', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'PHARMACEUTICALS', child: Text('Pharmaceuticals', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'FOOD_PROCESSING', child: Text('Food & Beverage', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'TEXTILE', child: Text('Textiles & Yarn', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'CHEMICALS', child: Text('Chemical Processing', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'CUSTOM', child: Text('Discrete Manufacturing', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) => setState(() => _selectedIndustry = val),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Templates Grid
            Expanded(
              child: state.isLoadingTemplates
                  ? const Center(child: CircularProgressIndicator())
                  : templates.isEmpty
                      ? Center(
                          child: Text(
                            'No templates match the selected filter.',
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        )
                      : GridView.builder(
                          key: const Key('templates_grid_view'),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: templates.length,
                          itemBuilder: (ctx, idx) {
                            final t = templates[idx];
                            return _buildTemplateCard(ctx, t, isDark, cardBg, borderColor, textPrimary, textSecondary);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    ProcessTemplateItem t,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Industry badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  t.industryType.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: FactoryColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            t.description,
            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.25),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Stats: Node count, edge count, cycle time
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 12, color: textSecondary),
              const SizedBox(width: 3),
              Text('${t.nodeCount} nodes', style: TextStyle(fontSize: 10, color: textSecondary)),
              const SizedBox(width: 8),
              Icon(Icons.timeline_outlined, size: 12, color: textSecondary),
              const SizedBox(width: 3),
              Text('${t.edgeCount} edges', style: TextStyle(fontSize: 10, color: textSecondary)),
              const SizedBox(width: 8),
              Icon(Icons.timer_outlined, size: 12, color: textSecondary),
              const SizedBox(width: 3),
              Text('${t.nominalCycleTimeSeconds.toInt()}s cycle', style: TextStyle(fontSize: 10, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 8),

          // Concise ordered stage preview
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(FactoryRadius.sm),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < t.stages.length; i++) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: borderColor, width: 0.6),
                        ),
                        child: Text(
                          '${i + 1}. ${t.stages[i]}',
                          style: TextStyle(fontSize: 9, color: textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (i < t.stages.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(Icons.arrow_forward, size: 9, color: textSecondary),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              key: Key('use_template_button_${t.key}'),
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: FactoryColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.check, size: 13),
              label: const Text('Use Template', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: () => widget.onTemplateSelected(t),
            ),
          ),
        ],
      ),
    );
  }
}
