import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for Krishi Vikas AI.
/// Earthy greens + warm amber palette. Optimised for rural users:
/// large touch targets, high contrast, clear typography.
class AppTheme {
  AppTheme._();

  // ── Brand Colors ──────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF1B4332);     // primary-container
  static const Color primaryLight = Color(0xFFA5D0B9);     // primary-fixed-dim
  static const Color primaryDark = Color(0xFF012D1D);      // primary
  static const Color accentAmber = Color(0xFFFFCA98);      // secondary-container
  static const Color accentOrange = Color(0xFF7D562D);     // secondary
  static const Color errorRed = Color(0xFFBA1A1A);         // error
  static const Color successGreen = Color(0xFF3F6653);     // surface-tint
  static const Color warningYellow = Color(0xFFF0BD8B);    // secondary-fixed-dim

  // ── Neutral Palette ───────────────────────────────────────────────
  static const Color surfaceWhite = Color(0xFFF8F9FA);     // surface
  static const Color cardWhite = Color(0xFFFFFFFF);        // surface-container-lowest
  static const Color dividerGray = Color(0xFFE1E3E4);      // surface-variant
  static const Color textPrimary = Color(0xFF191C1D);      // on-surface
  static const Color textSecondary = Color(0xFF414844);    // on-surface-variant
  static const Color textHint = Color(0xFF717973);         // outline

  // ── Dark Mode Palette ─────────────────────────────────────────────
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  // ── Border Radius ─────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // ── Spacing ───────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ── Light Theme ───────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentAmber,
        error: errorRed,
        surface: surfaceWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceWhite,
      textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: textTheme.headlineLarge?.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: textTheme.headlineMedium?.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bodyLarge: GoogleFonts.inter(
          textStyle: textTheme.bodyLarge?.copyWith(
            color: textPrimary,
            fontSize: 16,
          ),
        ),
        bodyMedium: GoogleFonts.inter(
          textStyle: textTheme.bodyMedium?.copyWith(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        labelLarge: GoogleFonts.inter(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dividerGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dividerGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryGreen.withOpacity(0.1),
        selectedColor: primaryGreen,
        labelStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerGray,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        primary: primaryLight,
        secondary: accentAmber,
        error: errorRed,
        surface: darkSurface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkSurface,
      textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: textTheme.headlineLarge?.copyWith(
            color: darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: textTheme.headlineMedium?.copyWith(
            color: darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
