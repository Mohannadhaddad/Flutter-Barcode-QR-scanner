import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF14212B);
  static const Color slate = Color(0xFF2C3E4A);
  static const Color mist = Color(0xFFE8EEF2);
  static const Color foam = Color(0xFFF4F7F9);
  static const Color accent = Color(0xFF0F8A6B);
  static const Color accentSoft = Color(0xFFB8E4D6);
  static const Color warn = Color(0xFFC45C26);
  static const Color scannerBg = Color(0xFF0B1218);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: slate,
        surface: foam,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: foam,
      textTheme: GoogleFonts.sourceSans3TextTheme(base.textTheme).copyWith(
        displaySmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: foam,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: accentSoft,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.sourceSans3(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : slate,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accentSoft : mist,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accentSoft,
        secondary: mist,
        surface: ink,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scannerBg,
      textTheme: GoogleFonts.sourceSans3TextTheme(base.textTheme).copyWith(
        displaySmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scannerBg,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ink,
        indicatorColor: accent.withValues(alpha: 0.35),
      ),
    );
  }
}
