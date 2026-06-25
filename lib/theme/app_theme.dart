import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  // ── Glass-morphism (default, liquid glass) ──
  static ThemeData glassLight(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: const Color(0xFFF1F5F9),
        onSecondary: const Color(0xFF0F172A),
        error: AppColors.error,
        onError: Colors.white,
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF0F172A),
        outline: const Color(0xFFE2E8F0),
        onSurfaceVariant: const Color(0xFF64748B),
      ),
      textTheme: _baseTextTheme(const Color(0xFF0F172A), const Color(0xFF64748B)),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.72),
        elevation: 6,
        shadowColor: const Color(0xFF0F172A).withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
      ),
      chipTheme: _chipTheme(accentColor, Brightness.light),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.8),
        selectedItemColor: accentColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: _inputTheme(accentColor, Brightness.light),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData glassDark(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        onPrimary: const Color(0xFF0F172A),
        secondary: const Color(0xFF334155),
        onSecondary: const Color(0xFFF1F5F9),
        error: AppColors.error,
        onError: const Color(0xFFF1F5F9),
        surface: const Color(0xFF1E293B),
        onSurface: const Color(0xFFF1F5F9),
        outline: const Color(0xFF475569),
        onSurfaceVariant: const Color(0xFF94A3B8),
      ),
      textTheme: _baseTextTheme(const Color(0xFFF1F5F9), const Color(0xFF94A3B8)),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.06),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
      chipTheme: _chipTheme(accentColor, Brightness.dark),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B).withOpacity(0.9),
        selectedItemColor: accentColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: _inputTheme(accentColor, Brightness.dark),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Neo-Brutalist ──
  static ThemeData brutalistTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: ColorScheme.light(
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: const Color(0xFFF5F5F5),
        onSecondary: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        outline: Colors.black,
        onSurfaceVariant: const Color(0xFF525252),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.jetBrainsMono(color: Colors.black, fontSize: 15, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF525252), fontSize: 13, fontWeight: FontWeight.normal),
        labelLarge: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black, width: 2.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: accentColor, width: 3),
        ),
      ),
    );
  }

  // ── Soft Minimal with Gradient ──
  static ThemeData gradientTheme(Color accentColor) {
    const teal = Color(0xFF14B8A6);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: teal,
        onPrimary: Colors.white,
        secondary: const Color(0xFFECFDF5),
        onSecondary: const Color(0xFF0F172A),
        error: AppColors.error,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
        outline: const Color(0xFFD1FAE5),
        onSurfaceVariant: const Color(0xFF64748B),
      ),
      textTheme: _baseTextTheme(const Color(0xFF0F172A), const Color(0xFF64748B)),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.9),
        elevation: 1,
        shadowColor: teal.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: teal.withOpacity(0.15), width: 1),
        ),
      ),
      chipTheme: _chipTheme(teal, Brightness.light),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.95),
        selectedItemColor: teal,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: _inputTheme(teal, Brightness.light),
    );
  }

  // ── Rich Dark Mode with Gold Accents ──
  static ThemeData darkGoldTheme(Color _) {
    const gld = Color(0xFFFFD700);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      colorScheme: ColorScheme.dark(
        primary: gld,
        onPrimary: const Color(0xFF0A0E1A),
        secondary: const Color(0xFF1E293B),
        onSecondary: const Color(0xFFF1F5F9),
        error: AppColors.error,
        onError: const Color(0xFFF1F5F9),
        surface: const Color(0xFF141B2D),
        onSurface: const Color(0xFFF1F5F9),
        outline: const Color(0xFF2D3748),
        onSurfaceVariant: const Color(0xFF94A3B8),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(color: gld, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.playfairDisplay(color: gld, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.playfairDisplay(color: const Color(0xFFF1F5F9), fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.playfairDisplay(color: const Color(0xFFF1F5F9), fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.playfairDisplay(color: const Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFFF1F5F9), fontSize: 16),
        bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
        labelLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFFF1F5F9), fontSize: 14, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141B2D),
        elevation: 2,
        shadowColor: gld.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: gld.withOpacity(0.2), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: gld.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFF1F5F9), fontSize: 12, fontWeight: FontWeight.w500),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: gld.withOpacity(0.2)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0E1A),
        selectedItemColor: gld,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF141B2D),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gld.withOpacity(0.2), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gld.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gld, width: 2),
        ),
      ),
    );
  }

  // ── Backward-compatible factories (used in app.dart) ──
  static ThemeData lightTheme(Color accentColor) => glassLight(accentColor);
  static ThemeData darkTheme(Color accentColor) => glassDark(accentColor);

  // ── Shared helpers ──
  static TextTheme _baseTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(color: primary, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.playfairDisplay(color: primary, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.playfairDisplay(color: primary, fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.playfairDisplay(color: primary, fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.playfairDisplay(color: primary, fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.plusJakartaSans(color: primary, fontSize: 16),
      bodyMedium: GoogleFonts.plusJakartaSans(color: secondary, fontSize: 14),
      labelLarge: GoogleFonts.plusJakartaSans(color: primary, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  static ChipThemeData _chipTheme(Color accent, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ChipThemeData(
      backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
      selectedColor: accent.withOpacity(isLight ? 0.12 : 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      brightness: brightness,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: isLight
            ? const BorderSide(color: Color(0xFFE2E8F0), width: 1)
            : BorderSide.none,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Color accent, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final fill = isLight ? Colors.white : const Color(0xFF1E293B);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
    final hintColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.plusJakartaSans(color: hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    );
  }
}
