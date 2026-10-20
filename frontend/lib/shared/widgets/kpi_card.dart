import 'package:flutter/material.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/factory_tokens.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final String? trendText;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.trendText,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.responsiveDuration(context, AppAnimations.fast),
          curve: AppAnimations.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          padding: const EdgeInsets.all(FactorySpacing.lg),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(
              color: _isHovered ? widget.accentColor.withValues(alpha: 0.5) : borderColor,
              width: 1,
            ),
            boxShadow: _isHovered
                ? (isDark ? FactoryShadows.darkCard : FactoryShadows.card)
                : FactoryShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Title & Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(FactoryRadius.sm),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FactorySpacing.md),
              // Main Value
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: FactorySpacing.xs),
              // Footer: Trend / Subtitle
              Row(
                children: [
                  if (widget.trendText != null) ...[
                    Icon(
                      widget.isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: widget.isPositiveTrend
                          ? FactoryColors.statusRunning
                          : FactoryColors.statusOffline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.trendText!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isPositiveTrend
                            ? FactoryColors.statusRunning
                            : FactoryColors.statusOffline,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.subtitle != null)
                    Expanded(
                      child: Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
}
