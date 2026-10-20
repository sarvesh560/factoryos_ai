import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/factory_data_table.dart';
import '../controllers/factory_controller.dart';

class ProductionLinesScreen extends ConsumerStatefulWidget {
  const ProductionLinesScreen({super.key});

  @override
  ConsumerState<ProductionLinesScreen> createState() => _ProductionLinesScreenState();
}

class _ProductionLinesScreenState extends ConsumerState<ProductionLinesScreen> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(factoryControllerProvider);
    final overview = state.overview;
    final selectedFactory = state.selectedFactory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    if (overview == null || selectedFactory == null) {
      return EmptyStateView(
        title: 'No Lines Available',
        message: 'Select a factory from the top navigation to view its production lines.',
        actionText: 'Refresh',
        onAction: () => ref.read(factoryControllerProvider.notifier).loadFactories(),
      );
    }

    // Filter lines
    final filteredLines = overview.productionLines.where((l) {
      final matchesStatus = _selectedStatus == 'ALL' || l.status.toUpperCase() == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.currentProduct.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FactorySpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FactorySpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Production Cells & Assembly Lines',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discrete automated cells running under ${selectedFactory.name} (${selectedFactory.code})',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: FactorySpacing.lg),

              // Filter & Search Toolbar
              Container(
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(FactoryRadius.sm),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 16, color: textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Search by line name, code, or active product...',
                                  hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: FactorySpacing.md),
                    // Status Filter Buttons
                    _filterButton('ALL', 'All (${overview.productionLines.length})', isDark),
                    const SizedBox(width: 6),
                    _filterButton('RUNNING', 'Running (${overview.linesSummary.running})', isDark),
                    const SizedBox(width: 6),
                    _filterButton('IDLE', 'Idle (${overview.linesSummary.idle})', isDark),
                    const SizedBox(width: 6),
                    _filterButton('MAINTENANCE', 'Maintenance (${overview.linesSummary.maintenance})', isDark),
                  ],
                ),
              ),

              const SizedBox(height: FactorySpacing.lg),

              // Table
              FactoryDataTable(lines: filteredLines),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String status, String label, bool isDark) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(FactoryRadius.sm),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FactoryColors.primaryBlue
              : (isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle),
          borderRadius: BorderRadius.circular(FactoryRadius.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}
