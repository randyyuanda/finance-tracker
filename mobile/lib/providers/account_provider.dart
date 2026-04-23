import 'package:flutter/material.dart';
import '../core/api.dart';
import '../models/account.dart';

class AccountProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  bool _loading = false;
  String? _error;

  List<Account> get accounts => _accounts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/accounts');
      _accounts = (res.data as List).map((j) => Account.fromJson(j)).toList();
      _error = null;
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.dio.post('/accounts', data: data);
      _accounts.insert(0, Account.fromJson(res.data));
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
      final res = await ApiClient.dio.put('/accounts/$id', data: data);
      final idx = _accounts.indexWhere((a) => a.id == id);
      if (idx != -1) _accounts[idx] = Account.fromJson(res.data);
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
      await ApiClient.dio.delete('/accounts/$id');
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }
}
