import 'package:flutter/material.dart';
import '../../../core/theme/factory_tokens.dart';
import 'factory_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.precision_manufacturing_outlined,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FactorySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: FactorySpacing.lg),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: FactorySpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: FactorySpacing.lg),
              FactoryButton(
                text: actionText!,
                onPressed: onAction,
                variant: ButtonVariant.secondary,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
