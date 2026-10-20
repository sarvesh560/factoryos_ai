import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'factory_tokens.dart';

/// FactoryOS AI Enterprise Application Theme
class AppTheme {
  static ThemeData get lightTheme {
    final interFamily = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: interFamily,
      scaffoldBackgroundColor: FactoryColors.lightCanvas,
      primaryColor: FactoryColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: FactoryColors.primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: FactoryColors.primaryBlueTint,
        onPrimaryContainer: FactoryColors.primaryBlue,
        surface: FactoryColors.lightSurface,
        onSurface: FactoryColors.lightTextPrimary,
        outline: FactoryColors.lightBorder,
        outlineVariant: FactoryColors.lightBorderStrong,
        surfaceContainerHighest: FactoryColors.lightSurfaceSubtle,
      ),
      cardTheme: CardThemeData(
        color: FactoryColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FactoryRadius.md),
          side: const BorderSide(color: FactoryColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: FactoryColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: FactoryColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: FactoryColors.lightTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: FactoryColors.lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FactoryColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: FactoryColors.lightTextSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: FactoryColors.lightTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FactoryColors.lightTextMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final interFamily = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: interFamily,
      scaffoldBackgroundColor: FactoryColors.darkCanvas,
      primaryColor: FactoryColors.primaryBlueActive,
      colorScheme: const ColorScheme.dark(
        primary: FactoryColors.primaryBlueActive,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1E293B),
        onPrimaryContainer: Colors.white,
        surface: FactoryColors.darkSurface,
        onSurface: FactoryColors.darkTextPrimary,
        outline: FactoryColors.darkBorder,
        outlineVariant: FactoryColors.darkBorderStrong,
        surfaceContainerHighest: FactoryColors.darkSurfaceSubtle,
      ),
      cardTheme: CardThemeData(
        color: FactoryColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FactoryRadius.md),
          side: const BorderSide(color: FactoryColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: FactoryColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: FactoryColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: FactoryColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: FactoryColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FactoryColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: FactoryColors.darkTextSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: FactoryColors.darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FactoryColors.darkTextMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
