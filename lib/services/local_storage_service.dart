import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late final SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding Status
  Future<bool> setOnboardingComplete(bool complete) async {
    return await _prefs.setBool('onboarding_complete', complete);
  }

  bool get isOnboardingComplete {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  // Theme configuration
  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString('theme_mode', mode);
  }

  String get themeMode {
    return _prefs.getString('theme_mode') ?? 'dark';
  }

  // Generic helpers
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}
