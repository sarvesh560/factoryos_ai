import 'package:flutter/material.dart';
import '../../../core/theme/factory_tokens.dart';
import '../../features/factories/data/models/factory_model.dart';
import 'status_badge.dart';

class FactoryDataTable extends StatelessWidget {
  final List<ProductionLineItem> lines;
  final Function(ProductionLineItem)? onLineTap;

  const FactoryDataTable({
    super.key,
    required this.lines,
    this.onLineTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final headerBg = isDark ? const Color(0xFF161E2E) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(FactorySpacing.xl),
        alignment: Alignment.center,
        child: Text(
          'No production lines configured for this facility.',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FactorySpacing.lg,
              vertical: FactorySpacing.md,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'PRODUCTION LINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CURRENT PRODUCT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'EFFICIENCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'OUTPUT RATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'CREW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lines.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final line = lines[index];
              return _TableRowItem(
                line: line,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
                onTap: onLineTap != null ? () => onLineTap!(line) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TableRowItem extends StatefulWidget {
  final ProductionLineItem line;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback? onTap;

  const _TableRowItem({
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_TableRowItem> createState() => _TableRowItemState();
}

class _TableRowItemState extends State<_TableRowItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final rowHoverBg = widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    Color effColor;
    if (line.efficiencyRate >= 90) {
      effColor = FactoryColors.statusRunning;
    } else if (line.efficiencyRate >= 75) {
      effColor = FactoryColors.statusIdle;
    } else {
      effColor = FactoryColors.statusOffline;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _isHovered ? rowHoverBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: FactorySpacing.lg,
            vertical: FactorySpacing.md,
          ),
          child: Row(
            children: [
              // Production Line Name & Code
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line.code,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Current Product
              Expanded(
                flex: 3,
                child: Text(
                  line.currentProduct.isEmpty ? '—' : line.currentProduct,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: line.status, label: line.statusDisplay),
                ),
              ),
              // Efficiency Rate with Mini Bar
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Text(
                      '${line.efficiencyRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (line.efficiencyRate / 100).clamp(0.0, 1.0),
                          backgroundColor: widget.isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(effColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              // Output Rate (Actual / Target)
              Expanded(
                flex: 2,
                child: Text(
                  '${line.actualHourlyUnits} / ${line.targetHourlyUnits} u/h',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.textSecondary,
                  ),
                ),
              ),
              // Operators Crew
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: widget.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${line.operatorCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
