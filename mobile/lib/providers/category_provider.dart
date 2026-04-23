import 'package:flutter/material.dart';
import '../core/api.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _loading = false;

  List<Category> get categories => _categories;
  List<Category> get incomeCategories => _categories.where((c) => c.type == 'income').toList();
  List<Category> get expenseCategories => _categories.where((c) => c.type == 'expense').toList();
  bool get loading => _loading;

  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/categories');
      _categories = (res.data as List).map((j) => Category.fromJson(j)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}
