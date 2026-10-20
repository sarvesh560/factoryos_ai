import 'package:flutter/material.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/factory_tokens.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

class FactoryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const FactoryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 38.0,
  });

  @override
  State<FactoryButton> createState() => _FactoryButtonState();
}

class _FactoryButtonState extends State<FactoryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.variant) {
      case ButtonVariant.primary:
        bgColor = isDisabled
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
            : (_isHovered ? FactoryColors.primaryBlueHover : FactoryColors.primaryBlue);
        fgColor = isDisabled ? const Color(0xFF94A3B8) : Colors.white;
        border = null;
        break;
      case ButtonVariant.secondary:
        bgColor = isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle;
        fgColor = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
        border = Border.all(
          color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder,
          width: 1,
        );
        break;
      case ButtonVariant.outline:
        bgColor = _isHovered
            ? (isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.primaryBlueTint)
            : Colors.transparent;
        fgColor = isDark ? FactoryColors.darkTextPrimary : FactoryColors.primaryBlue;
        border = Border.all(
          color: _isHovered ? FactoryColors.primaryBlue : (isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder),
          width: 1,
        );
        break;
      case ButtonVariant.ghost:
        bgColor = _isHovered
            ? (isDark ? FactoryColors.darkSurfaceSubtle : const Color(0xFFF1F5F9))
            : Colors.transparent;
        fgColor = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
        border = null;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 16, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fgColor,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) {
        if (!isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!isDisabled) setState(() => _isHovered = false);
      },
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: AppAnimations.responsiveDuration(context, AppAnimations.fast),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(FactoryRadius.sm),
            border: border,
          ),
          child: content,
        ),
      ),
    );
  }
}
