import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settings = SettingsService();
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;

  ThemeMode get flutterThemeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Future<void> load() async {
    _mode = await _settings.getThemeMode();
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _settings.setThemeMode(mode);
  }
}
