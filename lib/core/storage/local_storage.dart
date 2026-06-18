import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _onboardingDoneKey = 'onboarding_done';

  late SharedPreferences _prefs;

  Future<LocalStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // Thème
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'light';
  Future<void> setThemeMode(String mode) => _prefs.setString(_themeModeKey, mode);

  // Langue
  String get locale => _prefs.getString(_localeKey) ?? 'fr';
  Future<void> setLocale(String locale) => _prefs.setString(_localeKey, locale);

  // Onboarding
  bool get isOnboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingDoneKey, true);

  // Générique
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}
