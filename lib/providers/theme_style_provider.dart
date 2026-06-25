import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeStyle { glass, brutalist, gradient, darkGold }

class ThemeStyleNotifier extends StateNotifier<ThemeStyle> {
  ThemeStyleNotifier() : super(ThemeStyle.glass) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('theme_style') ?? 'glass';
    state = ThemeStyle.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ThemeStyle.glass,
    );
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_style', style.name);
  }
}

final themeStyleProvider =
    StateNotifierProvider<ThemeStyleNotifier, ThemeStyle>((ref) {
  return ThemeStyleNotifier();
});
