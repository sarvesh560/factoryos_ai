import 'package:flutter/material.dart';

/// FactoryOS AI Design Tokens
/// Precision industrial enterprise design system.
class FactoryColors {
  // Brand Blue Accents (Restrained, precise, technical)
  static const Color primaryBlue = Color(0xFF1E40AF); // Blue-800
  static const Color primaryBlueHover = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryBlueActive = Color(0xFF2563EB); // Blue-600
  static const Color primaryBlueTint = Color(0xFFEFF6FF); // Blue-50
  static const Color primaryBlueBorder = Color(0xFFBFDBFE); // Blue-200

  // Light Mode Surfaces & Canvas
  static const Color lightCanvas = Color(0xFFF8FAFC); // Slate-50
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurfaceSubtle = Color(0xFFF1F5F9); // Slate-100
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate-200
  static const Color lightBorderStrong = Color(0xFFCBD5E1); // Slate-300

  // Light Mode Typography
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate-900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate-600
  static const Color lightTextMuted = Color(0xFF94A3B8); // Slate-400
  static const Color lightTextInverse = Color(0xFFFFFFFF);

  // Dark Mode Surfaces & Canvas (Sleek deep slate, high-tech industrial)
  static const Color darkCanvas = Color(0xFF0B0F19); // Deep Slate-950
  static const Color darkSurface = Color(0xFF111827); // Gray-900
  static const Color darkSurfaceSubtle = Color(0xFF1E293B); // Slate-800
  static const Color darkBorder = Color(0xFF1F2937); // Gray-800
  static const Color darkBorderStrong = Color(0xFF374151); // Gray-700

  // Dark Mode Typography
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color darkTextMuted = Color(0xFF64748B); // Slate-500
  static const Color darkTextInverse = Color(0xFF0F172A);

  // Industrial Status Semantics (Refined, non-garish)
  // Success / Running
  static const Color statusRunning = Color(0xFF10B981); // Emerald-500
  static const Color statusRunningBgLight = Color(0xFFECFDF5); // Emerald-50
  static const Color statusRunningBorderLight = Color(0xFFA7F3D0); // Emerald-200
  static const Color statusRunningBgDark = Color(0xFF064E3B);
  static const Color statusRunningBorderDark = Color(0xFF047857);

  // Warning / Maintenance / Idle
  static const Color statusIdle = Color(0xFFF59E0B); // Amber-500
  static const Color statusAmber = Color(0xFFF59E0B); // Amber-500
  static const Color statusIdleBgLight = Color(0xFFFFFBEB);
  static const Color statusIdleBorderLight = Color(0xFFFDE68A);
  static const Color statusIdleBgDark = Color(0xFF78350F);

  static const Color statusMaintenance = Color(0xFF8B5CF6); // Purple-500
  static const Color statusMaintenanceBgLight = Color(0xFFF5F3FF);
  static const Color statusMaintenanceBorderLight = Color(0xFFDDD6FE);

  // Danger / Offline / Critical
  static const Color statusOffline = Color(0xFFEF4444); // Red-500
  static const Color statusOfflineBgLight = Color(0xFFFEF2F2);
  static const Color statusOfflineBorderLight = Color(0xFFFECACA);
  static const Color statusOfflineBgDark = Color(0xFF7F1D1D);
  static const Color statusOfflineBorderDark = Color(0xFF991B1B);

  // KPI Specific Accents
  static const Color kpiOee = Color(0xFF2563EB); // Royal Blue
  static const Color kpiAvailability = Color(0xFF0D9488); // Teal-600
  static const Color kpiPerformance = Color(0xFF6366F1); // Indigo-500
  static const Color kpiQuality = Color(0xFF059669); // Emerald-600
  static const Color kpiEnergy = Color(0xFFD97706); // Amber-600

  // Semantic Design System Aliases
  static const Color accentGreen = statusRunning;
  static const Color accentAmber = statusIdle;
  static const Color accentRed = statusOffline;
  static const Color accentPurple = statusMaintenance;
  static const Color darkSurfaceVariant = darkSurfaceSubtle;
  static const Color lightSurfaceVariant = lightSurfaceSubtle;
}

class FactorySpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Layout Constants
  static const double sidebarExpandedWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double topNavHeight = 64.0;
  static const double maxContentWidth = 1600.0;
}

class FactoryRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double pill = 9999.0;
}

class FactoryShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
