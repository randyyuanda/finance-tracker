import 'package:flutter/material.dart';
import '../core/api.dart';
import '../models/goal.dart';

class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  bool _loading = false;
  String? _error;

  List<Goal> get goals => _goals;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/goals');
      _goals = (res.data as List).map((j) => Goal.fromJson(j)).toList();
      _error = null;
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.dio.post('/goals', data: data);
      _goals.insert(0, Goal.fromJson(res.data));
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.dio.patch('/goals/$id', data: data);
      final idx = _goals.indexWhere((g) => g.id == id);
      if (idx != -1) _goals[idx] = Goal.fromJson(res.data);
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
      await ApiClient.dio.delete('/goals/$id');
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }
}
