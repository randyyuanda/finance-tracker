import 'package:flutter/material.dart';
import '../core/storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  String _language = 'en';

  ThemeMode get themeMode => _mode;
  String get language => _language;

  Future<void> initialize() async {
    final saved = await Storage.getTheme();
    _mode = _modeFromString(saved);
    _language = await Storage.getLanguage();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await Storage.saveTheme(_modeToString(mode));
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    await Storage.saveLanguage(lang);
  }

  ThemeMode _modeFromString(String s) {
    switch (s) {
      case 'light':  return ThemeMode.light;
      case 'dark':   return ThemeMode.dark;
      default:       return ThemeMode.system;
    }
  }

  String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'light';
      case ThemeMode.dark:   return 'dark';
      default:               return 'system';
    }
  }
}
