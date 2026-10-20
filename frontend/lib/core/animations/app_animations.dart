import 'package:flutter/material.dart';

/// FactoryOS Animation Curves and Durations
/// Strict guideline: Keep most transitions between 120 and 300 ms, respecting reduced-motion.
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 280);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Returns true if the device or user has requested reduced motion.
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Scale duration down to zero if user prefers reduced motion.
  static Duration responsiveDuration(BuildContext context, Duration standardDuration) {
    if (prefersReducedMotion(context)) {
      return Duration.zero;
    }
    return standardDuration;
  }
}
