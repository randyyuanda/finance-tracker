import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../core/storage.dart';
import 'auth_provider.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  String _language = 'en';
  String _currency = 'IDR';

  ThemeMode get themeMode => _mode;
  String get language => _language;
  String get currency => _currency;

  Future<void> initialize() async {
    final saved = await Storage.getTheme();
    _mode = _modeFromString(saved);
    _language = await Storage.getLanguage();
    _currency = await Storage.getCurrency();
    
    // Sync to Widgets
    _syncWidgets();
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await Storage.saveTheme(_modeToString(mode));
  }

  Future<void> setLanguage(String lang, {BuildContext? context}) async {
    _language = lang;
    notifyListeners();
    await Storage.saveLanguage(lang);
    _syncWidgets();

    if (context != null) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        await auth.updateProfile(language: lang);
      }
    }
  }

  Future<void> setCurrency(String cur, {BuildContext? context}) async {
    _currency = cur;
    notifyListeners();
    await Storage.saveCurrency(cur);
    _syncWidgets();

    if (context != null) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        await auth.updateProfile(currency: cur);
      }
    }
  }

  Future<void> _syncWidgets() async {
    try {
      await HomeWidget.saveWidgetData('language', _language);
      await HomeWidget.saveWidgetData('currency', _currency);
      await HomeWidget.updateWidget(name: 'BuxBuxWidgetProvider');
      await HomeWidget.updateWidget(name: 'BuxBuxQuickListWidgetProvider');
    } catch (_) {}
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
