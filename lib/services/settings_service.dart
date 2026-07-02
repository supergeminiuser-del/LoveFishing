import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

enum AppThemeMode { dark, light, system }

/// Локальные настройки приложения (SharedPreferences).
/// Никогда не отправляются за пределы устройства.
class SettingsService {
  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.prefThemeMode);
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      case 'dark':
      default:
        return AppThemeMode.dark;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, mode.name);
  }

  Future<bool> isFirstRunDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefFirstRunDone) ?? false;
  }

  Future<void> markFirstRunDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefFirstRunDone, true);
  }

  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.prefLastBackupAt);
    return value != null ? DateTime.tryParse(value) : null;
  }

  Future<void> setLastBackupAt(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLastBackupAt, date.toIso8601String());
  }
}
