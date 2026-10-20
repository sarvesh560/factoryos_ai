import 'package:flutter/material.dart';
import '../../../core/theme/factory_tokens.dart';
import 'factory_button.dart';

class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    this.title = 'Backend Connection Error',
    required this.message,
    this.technicalDetails,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FactorySpacing.xxl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(FactorySpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(
              color: isDark ? FactoryColors.statusOfflineBorderDark : FactoryColors.statusOfflineBorderLight,
            ),
            boxShadow: isDark ? FactoryShadows.darkCard : FactoryShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? FactoryColors.statusOfflineBgDark : FactoryColors.statusOfflineBgLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 24,
                  color: FactoryColors.statusOffline,
                ),
              ),
              const SizedBox(height: FactorySpacing.md),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: FactorySpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              if (technicalDetails != null) ...[
                const SizedBox(height: FactorySpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(FactorySpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(FactoryRadius.sm),
                  ),
                  child: Text(
                    technicalDetails!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: FactoryColors.statusOffline,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: FactorySpacing.lg),
                FactoryButton(
                  text: 'Retry Connection',
                  onPressed: onRetry,
                  icon: Icons.refresh,
                  variant: ButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
