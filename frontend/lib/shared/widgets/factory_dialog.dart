import 'package:flutter/material.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/factory_tokens.dart';
import 'factory_button.dart';

class FactoryDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final double maxWidth;

  const FactoryDialog({
    super.key,
    required this.title,
    required this.content,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText = 'Close',
    this.onSecondaryAction,
    this.maxWidth = 520,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String secondaryActionText = 'Close',
    VoidCallback? onSecondaryAction,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dialog',
      transitionDuration: AppAnimations.responsiveDuration(context, AppAnimations.fast),
      pageBuilder: (context, anim1, anim2) {
        return FactoryDialog(
          title: title,
          content: content,
          primaryActionText: primaryActionText,
          onPrimaryAction: onPrimaryAction,
          secondaryActionText: secondaryActionText,
          onSecondaryAction: onSecondaryAction,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: AppAnimations.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: maxWidth,
          margin: const EdgeInsets.all(FactorySpacing.lg),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(FactoryRadius.lg),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: FactoryShadows.floating,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FactorySpacing.xl,
                  vertical: FactorySpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 16,
                      color: isDark ? FactoryColors.darkTextMuted : FactoryColors.lightTextMuted,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content Body
              Padding(
                padding: const EdgeInsets.all(FactorySpacing.xl),
                child: content,
              ),
              const Divider(height: 1),
              // Footer Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FactorySpacing.xl,
                  vertical: FactorySpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FactoryButton(
                      text: secondaryActionText,
                      variant: ButtonVariant.ghost,
                      onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
                    ),
                    if (primaryActionText != null && onPrimaryAction != null) ...[
                      const SizedBox(width: FactorySpacing.sm),
                      FactoryButton(
                        text: primaryActionText!,
                        variant: ButtonVariant.primary,
                        onPressed: onPrimaryAction,
                      ),
                    ],
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
