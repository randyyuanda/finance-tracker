import 'package:flutter/material.dart';
import '../core/api.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _loading = false;
  String? _error;
  int _total = 0;
  int _page = 1;
  static const int _limit = 20;

  List<Transaction> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _transactions.length < _total;

  Future<void> fetchAll({bool reset = true, String? type, String? accountId}) async {
    if (reset) {
      _page = 1;
      _transactions = [];
    }
    _loading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{'page': _page, 'limit': _limit};
      if (type != null) params['type'] = type;
      if (accountId != null) params['accountId'] = accountId;

      final res = await ApiClient.dio.get('/transactions', queryParameters: params);
      final data = res.data;
      final list = (data['transactions'] ?? data as List)
          .map((j) => Transaction.fromJson(j))
          .toList();

      if (reset) {
        _transactions = list;
      } else {
        _transactions.addAll(list);
      }
      _total = data['total'] ?? list.length;
      _page++;
      _error = null;
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.post('/transactions', data: data);
      await fetchAll(reset: true);
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ApiClient.dio.delete('/transactions/$id');
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }
}
