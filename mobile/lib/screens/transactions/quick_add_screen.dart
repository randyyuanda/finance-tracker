import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/notifications.dart';
import '../../widgets/gradient_button.dart';

class QuickAddScreen extends StatefulWidget {
  final String type;
  const QuickAddScreen({super.key, required this.type});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _amountCtrl = TextEditingController();
  late String _type;
  String? _categoryId;
  String? _accountId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaults();
    });
  }

  void _loadDefaults() {
    final accs = context.read<AccountProvider>().accounts;
    final cats = _type == 'income'
        ? context.read<CategoryProvider>().incomeCategories
        : context.read<CategoryProvider>().expenseCategories;
    
    setState(() {
      if (accs.isNotEmpty) _accountId = accs.first.id;
      if (cats.isNotEmpty) {
        _categoryId = cats.first.id;
      } else {
        _categoryId = null;
      }
    });
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty || _accountId == null || _categoryId == null) return;
    
    setState(() => _loading = true);
    final ok = await context.read<TransactionProvider>().create({
      'type': _type,
      'amount': double.parse(_amountCtrl.text.replaceAll(',', '')),
      'accountId': _accountId,
      'categoryId': _categoryId,
      'date': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      if (ok) {
        // Show confirmation popup/notification
        final typeLabel = _type == 'income' ? context.l10n.income : context.l10n.expense;
        await NotificationService.showImmediate(
          id: DateTime.now().hashCode.toString(),
          title: context.l10n.transactionLogged,
          body: context.l10n.transactionAddedBody(typeLabel, _amountCtrl.text),
        );
        SystemNavigator.pop();
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<TransactionProvider>().error ?? 'Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'income'
        ? context.watch<CategoryProvider>().incomeCategories
        : context.watch<CategoryProvider>().expenseCategories;
    final accounts = context.watch<AccountProvider>().accounts;

    if (_categoryId != null && !categories.any((c) => c.id == _categoryId)) {
      _categoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    final accentColor = _type == 'income' ? kIncomeColor : kExpenseColor;
    final bgGradient = _type == 'income' 
        ? [const Color(0xFF1D976C), const Color(0xFF93F9B9)]
        : [const Color(0xFFEB3349), const Color(0xFFF45C43)];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: 0.15),
              Colors.white,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildMiniTab('expense', 'Expense', kExpenseColor),
                          _buildMiniTab('income', 'Income', kIncomeColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: -1,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: accentColor.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: accentColor.withValues(alpha: 0.1)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Input Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                            const Divider(height: 1),
                            DropdownButtonFormField<String>(
                              value: _accountId,
                              decoration: const InputDecoration(
                                labelText: 'Account',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                              onChanged: (v) => setState(() => _accountId = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      GradientButton(
                        onTap: _loading ? null : _save,
                        label: 'Save ${_type[0].toUpperCase()}${_type.substring(1)}',
                        loading: _loading,
                        colors: bgGradient,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTab(String val, String label, Color color) {
    final selected = _type == val;
    return GestureDetector(
      onTap: () {
        setState(() => _type = val);
        _loadDefaults();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
