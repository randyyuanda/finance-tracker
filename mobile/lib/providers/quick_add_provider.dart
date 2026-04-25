import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../core/storage.dart';
import '../models/quick_add_config.dart';

class QuickAddProvider extends ChangeNotifier {
  List<QuickAddConfig> _configs = [];

  List<QuickAddConfig> get configs => _configs.isEmpty ? QuickAddConfig.defaults : _configs;

  Future<void> initialize() async {
    final prefs = await Storage.getQuickAdds();
    if (prefs != null) {
      try {
        final List<dynamic> decoded = jsonDecode(prefs);
        _configs = decoded.map((e) => QuickAddConfig.fromJson(e)).toList();
      } catch (_) {
        _configs = QuickAddConfig.defaults;
      }
    } else {
      _configs = QuickAddConfig.defaults;
    }
    notifyListeners();
    _syncToWidget();
  }

  Future<void> updateConfig(int index, QuickAddConfig config) async {
    if (index >= 0 && index < configs.length) {
      final list = List<QuickAddConfig>.from(configs);
      list[index] = config;
      _configs = list;
      notifyListeners();
      await Storage.saveQuickAdds(jsonEncode(_configs.map((e) => e.toJson()).toList()));
      _syncToWidget();
    }
  }

  Future<void> _syncToWidget() async {
    try {
      final list = configs;
      for (int i = 0; i < list.length; i++) {
        final c = list[i];
        await HomeWidget.saveWidgetData('q${i + 1}_type', c.type);
        await HomeWidget.saveWidgetData('q${i + 1}_amount', c.amount);
        await HomeWidget.saveWidgetData('q${i + 1}_label', c.label ?? (c.type == 'income' ? '+ ${c.amount}' : '- ${c.amount}'));
        await HomeWidget.saveWidgetData('q${i + 1}_accountId', c.accountId);
        await HomeWidget.saveWidgetData('q${i + 1}_categoryId', c.categoryId);
        await HomeWidget.saveWidgetData('q${i + 1}_note', c.note);
      }
      await HomeWidget.updateWidget(name: 'BuxBuxQuickListWidgetProvider');
    } catch (_) {}
  }
}
