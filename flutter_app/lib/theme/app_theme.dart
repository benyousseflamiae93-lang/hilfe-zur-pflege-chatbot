import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme configuration for the Hilfe zur Pflege application.
/// Uses a healthcare-inspired blue and white palette with Material 3.
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1A56DB);
  static const Color primaryBlueDark = Color(0xFF0F3D9E);
  static const Color primaryBlueLight = Color(0xFF4F83E8);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color backgroundBlue = Color(0xFFF0F6FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFDBEAFE);
  static const Color textPrimary = Color(0xFF0D1F3C);
  static const Color textSecondary = Color(0xFF4A6080);
  static const Color textHint = Color(0xFF8EA8C3);
  static const Color divider = Color(0xFFE5EEFF);
  static const Color success = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  // ─── Gradient Definitions ────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A56DB), Color(0xFF0F3D9E)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1A56DB)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
  );

  // ─── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFDBEAFE),
        onPrimaryContainer: primaryBlueDark,
        secondary: primaryBlueLight,
        onSecondary: Colors.white,
        surface: surfaceWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: backgroundBlue,
        outline: cardBorder,
        error: errorRed,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textHint,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      scaffoldBackgroundColor: backgroundBlue,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1.5),
        ),
        color: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 0,
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A1628);
  static const Color darkSurface = Color(0xFF0F2040);
  static const Color darkCard = Color(0xFF162850);
  static const Color darkBorder = Color(0xFF1E3A6E);
  static const Color darkTextPrimary = Color(0xFFE8F0FE);
  static const Color darkTextSecondary = Color(0xFF93B4D8);
  static const Color darkTextHint = Color(0xFF4A6A96);

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlueLight,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF162850),
        onPrimaryContainer: const Color(0xFF93C5FD),
        secondary: accentBlue,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkCard,
        outline: darkBorder,
        error: errorRed,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: darkTextPrimary, letterSpacing: -0.5),
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: darkTextPrimary, height: 1.6),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: darkTextSecondary, height: 1.5),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: darkTextHint),
        labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1.5),
        ),
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 0),
    );
  }
}
