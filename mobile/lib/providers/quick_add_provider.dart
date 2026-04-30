import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../core/api.dart';
import '../core/storage.dart';
import '../models/quick_add_config.dart';

class QuickAddProvider extends ChangeNotifier {
  List<QuickAddConfig> _configs = [];

  List<QuickAddConfig> get configs => _configs.isEmpty ? QuickAddConfig.defaults : _configs;

  Future<void> initialize() async {
    await _loadFromLocal();
    await _fetchFromDB();
    _syncToWidget();
  }

  Future<void> _loadFromLocal() async {
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
  }

  Future<void> _fetchFromDB() async {
    try {
      final token = await Storage.getToken();
      if (token == null) return;
      final res = await ApiClient.dio.get('/quickadd');
      final list = res.data as List;
      _configs = list.map((e) => QuickAddConfig.fromJson(e as Map<String, dynamic>)).toList();
      await Storage.saveQuickAdds(jsonEncode(_configs.map((e) => e.toJson()).toList()));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateConfig(int index, QuickAddConfig config) async {
    if (index >= 0 && index < configs.length) {
      final list = List<QuickAddConfig>.from(configs);
      list[index] = config;
      _configs = list;
      notifyListeners();
      await Storage.saveQuickAdds(jsonEncode(_configs.map((e) => e.toJson()).toList()));
      await _saveToDB();
      _syncToWidget();
    }
  }

  Future<void> _saveToDB() async {
    try {
      await ApiClient.dio.put('/quickadd', data: _configs.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  Future<void> _syncToWidget() async {
    try {
      final list = configs;
      for (int i = 0; i < list.length; i++) {
        final c = list[i];
        final prefix = c.type == 'income' ? '+' : '-';
        final cur = c.currency ?? '';
        final amtFmt = _formatAmount(c.amount);
        final defaultLabel = cur.isNotEmpty ? '$prefix$cur $amtFmt' : '$prefix$amtFmt';

        await HomeWidget.saveWidgetData('q${i + 1}_type', c.type);
        // Save as String to avoid Long/Float ClassCastException in the Android widget.
        await HomeWidget.saveWidgetData('q${i + 1}_amount', c.amount.toString());
        await HomeWidget.saveWidgetData('q${i + 1}_label', c.label ?? defaultLabel);
        await HomeWidget.saveWidgetData('q${i + 1}_categoryName', c.categoryName);
        await HomeWidget.saveWidgetData('q${i + 1}_accountId', c.accountId);
        await HomeWidget.saveWidgetData('q${i + 1}_categoryId', c.categoryId);
        await HomeWidget.saveWidgetData('q${i + 1}_note', c.note);
      }
      await HomeWidget.updateWidget(name: 'BuxBuxQuickListWidgetProvider');
    } catch (_) {}
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    return amount.toStringAsFixed(amount == amount.toInt() ? 0 : 2);
  }
}
