import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // Mutable theme-driven color tokens (non-const)
  static Color background = const Color(0xFFF8FAFC);
  static Color surface = const Color(0xFFFFFFFF);
  static Color surface2 = const Color(0xFFF1F5F9);
  static Color textPrimary = const Color(0xFF0F172A);
  static Color textSecondary = const Color(0xFF64748B);
  static Color border = const Color(0xFFE2E8F0);
  static Color accentDefault = const Color(0xFF10B981);

  // Accent palette constants
  static const Color emerald = Color(0xFF10B981);
  static const Color sapphire = Color(0xFF3B82F6);
  static const Color ruby = Color(0xFFEF4444);
  static const Color amethyst = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color gold = Color(0xFFFFD700);

  // Brand functional colors
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color success = Color(0xFF22C55E);

  // Glass-morphism helpers
  static Color glassBackground(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.65);
  static Color glassBorder(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.45);
  static double glassBlurSigma = 24.0;

  // Vayu orb color per theme style
  static Color vayuOrbColor(String themeStyle, String accentChoice) {
    switch (themeStyle) {
      case 'darkGold':
        return gold;
      case 'brutalist':
        return _accentFor(accentChoice, false);
      case 'gradient':
        return const Color(0xFF06B6D4); // cyan/teal family
      case 'glass':
      default:
        return _accentFor(accentChoice, false);
    }
  }

  static Color _accentFor(String choice, bool isDark) {
    switch (choice) {
      case 'sapphire':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      case 'ruby':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      case 'amethyst':
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      case 'amber':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      case 'emerald':
      default:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    }
  }

  // Updates design tokens dynamically at runtime based on active theme settings
  static void updateColors(
      ThemeMode mode, Brightness systemBrightness, String accentChoice,
      {String themeStyle = 'glass'}) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            systemBrightness == Brightness.dark) ||
        themeStyle == 'darkGold';

    if (isDark) {
      if (themeStyle == 'darkGold') {
        background = const Color(0xFF0A0E1A);
        surface = const Color(0xFF141B2D);
        surface2 = const Color(0xFF1E293B);
      } else {
        background = themeStyle == 'glass' ? Colors.transparent : const Color(0xFF0F172A);
        surface = const Color(0xFF1E293B);
        surface2 = const Color(0xFF334155);
      }
      textPrimary = const Color(0xFFF1F5F9);
      textSecondary = const Color(0xFF94A3B8);
      border = const Color(0xFF475569);
    } else {
      if (themeStyle == 'gradient') {
        background = Colors.transparent;
        surface = const Color(0xFFFFFFFF);
        surface2 = const Color(0xFFECFDF5);
      } else if (themeStyle == 'brutalist') {
        background = const Color(0xFFFAFAFA);
        surface = const Color(0xFFFFFFFF);
        surface2 = const Color(0xFFF5F5F5);
      } else {
        background = themeStyle == 'glass' ? Colors.transparent : const Color(0xFFF8FAFC);
        surface = const Color(0xFFFFFFFF);
        surface2 = const Color(0xFFF1F5F9);
      }
      textPrimary = const Color(0xFF0F172A);
      textSecondary = const Color(0xFF64748B);
      border = const Color(0xFFE2E8F0);
    }

    // Resolve accent color
    if (themeStyle == 'darkGold') {
      accentDefault = gold;
    } else {
      accentDefault = _accentFor(accentChoice, isDark);
    }
  }
}
