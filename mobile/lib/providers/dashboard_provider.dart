import 'package:flutter/material.dart';
import '../core/api.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class DashboardStats {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySavings;

  DashboardStats({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        totalBalance: (j['totalBalance'] as num?)?.toDouble() ?? 0,
        monthlyIncome: (j['monthlyIncome'] as num?)?.toDouble() ?? 0,
        monthlyExpense: (j['monthlyExpense'] as num?)?.toDouble() ?? 0,
        monthlySavings: (j['monthlySavings'] as num?)?.toDouble() ?? 0,
      );
}

class DashboardProvider extends ChangeNotifier {
  DashboardStats? _stats;
  List<Transaction> _recentTransactions = [];
  List<Account> _accounts = [];
  bool _loading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<Transaction> get recentTransactions => _recentTransactions;
  List<Account> get accounts => _accounts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/dashboard');
      final data = res.data;
      _stats = DashboardStats.fromJson(data['stats'] ?? data);
      _recentTransactions = ((data['recentTransactions'] ?? []) as List)
          .map((j) => Transaction.fromJson(j))
          .toList();
      _accounts = ((data['accounts'] ?? []) as List)
          .map((j) => Account.fromJson(j))
          .toList();
      _error = null;
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }
}
