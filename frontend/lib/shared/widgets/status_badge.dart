import 'package:flutter/material.dart';
import '../../../core/theme/factory_tokens.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.toUpperCase();

    Color dotColor;
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (normalized) {
      case 'RUNNING':
      case 'ACTIVE':
      case 'HEALTHY':
      case 'CONFIGURED':
        dotColor = FactoryColors.statusRunning;
        bgColor = isDark ? FactoryColors.statusRunningBgDark : FactoryColors.statusRunningBgLight;
        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
        borderColor = isDark ? FactoryColors.statusRunningBorderDark : FactoryColors.statusRunningBorderLight;
        break;
      case 'IDLE':
      case 'IN_PROGRESS':
      case 'WARNING':
        dotColor = FactoryColors.statusIdle;
        bgColor = isDark ? FactoryColors.statusIdleBgDark : FactoryColors.statusIdleBgLight;
        textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
        borderColor = isDark ? const Color(0xFF92400E) : FactoryColors.statusIdleBorderLight;
        break;
      case 'MAINTENANCE':
        dotColor = FactoryColors.statusMaintenance;
        bgColor = isDark ? const Color(0xFF4C1D95) : FactoryColors.statusMaintenanceBgLight;
        textColor = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF5B21B6);
        borderColor = isDark ? const Color(0xFF6D28D9) : FactoryColors.statusMaintenanceBorderLight;
        break;
      case 'OFFLINE':
      case 'DEGRADED':
      case 'CRITICAL':
      case 'PENDING':
      default:
        dotColor = FactoryColors.statusOffline;
        bgColor = isDark ? FactoryColors.statusOfflineBgDark : FactoryColors.statusOfflineBgLight;
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        borderColor = isDark ? const Color(0xFF991B1B) : FactoryColors.statusOfflineBorderLight;
        break;
    }

    final displayText = label ?? (status.isEmpty ? 'Unknown' : status.replaceAll('_', ' '));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(FactoryRadius.pill),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: normalized == 'RUNNING' || normalized == 'HEALTHY'
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
