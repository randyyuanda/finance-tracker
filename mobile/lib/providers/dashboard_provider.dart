import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/widget_service.dart';
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
      final data = res.data as Map<String, dynamic>;

      // Backend returns: { totalBalance, thisMonth: {income,expense,savings}, accounts, recentTransactions }
      final thisMonth = data['thisMonth'] as Map<String, dynamic>? ?? {};
      _stats = DashboardStats(
        totalBalance: (data['totalBalance'] as num?)?.toDouble() ?? 0,
        monthlyIncome: (thisMonth['income'] as num?)?.toDouble() ?? 0,
        monthlyExpense: (thisMonth['expense'] as num?)?.toDouble() ?? 0,
        monthlySavings: (thisMonth['savings'] as num?)?.toDouble() ?? 0,
      );

      _accounts = ((data['accounts'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map((j) => Account.fromJson(j))
          .toList();

      _recentTransactions = ((data['recentTransactions'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map((j) => Transaction.fromJson(j))
          .toList();

      _error = null;
      WidgetService.updateBalance(_stats!.totalBalance);
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }
}
