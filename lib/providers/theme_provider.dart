import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_mode_provider.dart';

class ThemeColor extends Color {
  final String urgencyLabel;
  final Color urgencyBadgeColor;

  const ThemeColor(
    super.value, {
    required this.urgencyLabel,
    required this.urgencyBadgeColor,
  });
}

// Persisted accent choice provider (defaults to 'emerald')
class AccentChoiceNotifier extends StateNotifier<String> {
  AccentChoiceNotifier() : super('emerald') {
    _loadAccentChoice();
  }

  Future<void> _loadAccentChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final choice = prefs.getString('user_accent_choice') ?? 'emerald';
    state = choice;
  }

  Future<void> setAccentChoice(String choice) async {
    state = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_accent_choice', choice);
  }
}

final accentChoiceProvider = StateNotifierProvider<AccentChoiceNotifier, String>((ref) {
  return AccentChoiceNotifier();
});

class ThemeNotifier extends StateNotifier<Color> {
  final Ref _ref;
  String _urgency = 'calm';

  ThemeNotifier(this._ref)
      : super(const ThemeColor(
          0xFF10B981, // Default emerald light mode color
          urgencyLabel: 'ON TRACK',
          urgencyBadgeColor: Color(0xFF10B981),
        )) {
    loadThemeFromPrefs();
  }

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _urgency = prefs.getString('user_urgency') ?? 'calm';
    _updateState();
  }

  void updateUrgency(String urgency) {
    _urgency = urgency;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_urgency', urgency);
    });
    _updateState();
  }

  void refreshColors() {
    _updateState();
  }

  void _updateState() {
    final themeMode = _ref.read(themeModeProvider);
    final accentChoice = _ref.read(accentChoiceProvider);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && brightness == Brightness.dark);

    int colorValue;
    Color badgeColor;
    String label;

    switch (_urgency) {
      case 'critical':
        colorValue = 0xFFEF4444; // Dynamic urgency Red
        label = 'CRITICAL MODE';
        badgeColor = const Color(0xFFEF4444);
        break;
      case 'high':
        colorValue = 0xFFF59E0B; // Dynamic urgency Amber
        label = 'HIGH FOCUS';
        badgeColor = const Color(0xFFF59E0B);
        break;
      case 'calm':
      default:
        switch (accentChoice) {
          case 'sapphire':
            colorValue = isDark ? 0xFF60A5FA : 0xFF3B82F6;
            break;
          case 'ruby':
            colorValue = isDark ? 0xFFF87171 : 0xFFEF4444;
            break;
          case 'amethyst':
            colorValue = isDark ? 0xFFA78BFA : 0xFF8B5CF6;
            break;
          case 'amber':
            colorValue = isDark ? 0xFFFBBF24 : 0xFFF59E0B;
            break;
          case 'emerald':
          default:
            colorValue = isDark ? 0xFF34D399 : 0xFF10B981;
            break;
        }
        label = 'ON TRACK';
        badgeColor = Color(colorValue);
        break;
    }

    state = ThemeColor(
      colorValue,
      urgencyLabel: label,
      urgencyBadgeColor: badgeColor,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, Color>((ref) {
  final notifier = ThemeNotifier(ref);

  // Re-evaluate the dynamic accent color whenever theme mode or accent choice changes
  ref.listen<ThemeMode>(themeModeProvider, (prev, next) {
    notifier.refreshColors();
  });
  ref.listen<String>(accentChoiceProvider, (prev, next) {
    notifier.refreshColors();
  });

  return notifier;
});
