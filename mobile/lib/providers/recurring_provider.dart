import 'package:flutter/material.dart';
import '../core/api.dart';
import '../models/recurring_transaction.dart';

class RecurringProvider extends ChangeNotifier {
  List<RecurringTransaction> _items = [];
  bool _loading = false;
  String? _error;

  List<RecurringTransaction> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/recurring');
      _items = (res.data as List).map((j) => RecurringTransaction.fromJson(j)).toList();
      _error = null;
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.dio.post('/recurring', data: data);
      _items.insert(0, RecurringTransaction.fromJson(res.data));
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    try {
      final res = await ApiClient.dio.patch('/recurring/$id', data: {'isActive': isActive});
      final idx = _items.indexWhere((r) => r.id == id);
      if (idx != -1) _items[idx] = RecurringTransaction.fromJson(res.data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ApiClient.dio.delete('/recurring/$id');
      _items.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }
}
