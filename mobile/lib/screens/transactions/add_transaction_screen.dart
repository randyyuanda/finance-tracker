import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/account.dart';
import '../../models/category.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  String? _accountId;
  String? _categoryId;
  DateTime _date = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select account and category')),
      );
      return;
    }
    final ok = await context.read<TransactionProvider>().create({
      'type': _type,
      'amount': double.parse(_amountCtrl.text.replaceAll(',', '')),
      'accountId': _accountId,
      'categoryId': _categoryId,
      'date': _date.toIso8601String(),
      'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context, true);
    else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<TransactionProvider>().error ?? 'Failed'), backgroundColor: kExpenseColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final categories = _type == 'income'
        ? context.watch<CategoryProvider>().incomeCategories
        : context.watch<CategoryProvider>().expenseCategories;

    if (_categoryId != null && !categories.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addTransaction)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: ['expense', 'income'].map((t) {
                  final selected = _type == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _type = t; _categoryId = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? (t == 'income' ? kIncomeColor : kExpenseColor)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t == 'income' ? 'Income' : 'Expense',
                          style: TextStyle(
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              decoration: const InputDecoration(labelText: 'Amount (IDR)', prefixIcon: Icon(Icons.payments_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
            ),
            const SizedBox(height: 16),

            // Account
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: const InputDecoration(labelText: 'Account', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
              items: accounts.map((Account a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
              onChanged: (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Select account' : null,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
              items: categories.map((Category c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Select category' : null,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('Date: ${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
              tileColor: Theme.of(context).inputDecorationTheme.fillColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes)),
              maxLines: 2,
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: context.watch<TransactionProvider>().loading ? null : _submit,
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
