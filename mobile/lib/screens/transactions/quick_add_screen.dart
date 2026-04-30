import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/notifications.dart';
import '../../core/input_formatters.dart';
import '../../widgets/gradient_button.dart';

class QuickAddScreen extends StatefulWidget {
  final String type;
  final String? prefilledAmount;
  const QuickAddScreen({super.key, required this.type, this.prefilledAmount});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late String _type;
  String? _categoryId;
  String? _accountId;
  bool _loading = false;
  bool _defaultsLoaded = false;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    if (widget.prefilledAmount != null) {
      final amt = double.tryParse(widget.prefilledAmount!);
      if (amt != null && amt > 0) {
        _amountCtrl.text = NumberFormat('#,###', 'id_ID').format(amt.toInt());
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch providers if empty (cold-start from home-screen widget).
      final ap = context.read<AccountProvider>();
      final cp = context.read<CategoryProvider>();
      if (ap.accounts.isEmpty) ap.fetchAll();
      if (cp.categories.isEmpty) cp.fetchAll();
      _loadDefaults();
    });
  }

  // Called from didChangeDependencies when providers load after a cold-start,
  // and from _buildMiniTab when the user switches Income ↔ Expense.
  void _loadDefaults() {
    final accs = context.read<AccountProvider>().accounts;
    final cats = _type == 'income'
        ? context.read<CategoryProvider>().incomeCategories
        : context.read<CategoryProvider>().expenseCategories;
    if (accs.isEmpty && cats.isEmpty) return;
    setState(() {
      if (accs.isNotEmpty && _accountId == null) _accountId = accs.first.id;
      if (cats.isNotEmpty) _categoryId = cats.first.id; // always reset on type switch
      _defaultsLoaded = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set defaults once providers finish loading (handles widget cold-start race).
    if (!_defaultsLoaded) {
      final accs = context.read<AccountProvider>().accounts;
      final cats = _type == 'income'
          ? context.read<CategoryProvider>().incomeCategories
          : context.read<CategoryProvider>().expenseCategories;
      if (accs.isNotEmpty && _accountId == null) _accountId = accs.first.id;
      if (cats.isNotEmpty && _categoryId == null) _categoryId = cats.first.id;
      if (_accountId != null && _categoryId != null) _defaultsLoaded = true;
    }
  }

  String get _selectedCurrency {
    final accs = context.read<AccountProvider>().accounts;
    if (_accountId == null) return 'IDR';
    try {
      return accs.firstWhere((a) => a.id == _accountId).currency;
    } catch (_) {
      return accs.isNotEmpty ? accs.first.currency : 'IDR';
    }
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) return;
    if (_accountId == null || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account and category')),
      );
      return;
    }
    setState(() => _loading = true);
    final rawAmount = double.parse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final ok = await context.read<TransactionProvider>().create({
      'type': _type,
      'amount': rawAmount,
      'accountId': _accountId,
      'categoryId': _categoryId,
      'date': DateTime.now().toIso8601String(),
      'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    });

    if (mounted) {
      if (ok) {
        final typeLabel = _type == 'income' ? context.l10n.income : context.l10n.expense;
        await NotificationService.showImmediate(
          id: DateTime.now().hashCode.toString(),
          title: context.l10n.transactionLogged,
          body: context.l10n.transactionAddedBody(typeLabel, _amountCtrl.text, currency: _selectedCurrency),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          SystemNavigator.pop();
        }
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

    // Auto-set defaults once providers load (handles cold-start from widget tap).
    if (accounts.isNotEmpty && _accountId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _accountId == null) setState(() => _accountId = accounts.first.id);
      });
    }
    if (categories.isNotEmpty && _categoryId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _categoryId == null) {
          setState(() {
            _categoryId = categories.first.id;
            _defaultsLoaded = true;
          });
        }
      });
    }

    // Keep _categoryId valid when the type changes or categories reload.
    if (_categoryId != null && categories.isNotEmpty && !categories.any((c) => c.id == _categoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _categoryId = categories.first.id);
      });
    }

    final accentColor = _type == 'income' ? kIncomeColor : kExpenseColor;
    final bgGradient = _type == 'income'
        ? [const Color(0xFF1D976C), const Color(0xFF93F9B9)]
        : [const Color(0xFFEB3349), const Color(0xFFF45C43)];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardTheme.color ?? const Color(0xFF1E1E2E) : Colors.white;
    final cardBorder = isDark ? Colors.transparent : Colors.grey.shade100;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accentColor.withValues(alpha: 0.15), theme.scaffoldBackgroundColor],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          SystemNavigator.pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildMiniTab('expense', 'Expense', kExpenseColor, theme),
                          _buildMiniTab('income', 'Income', kIncomeColor, theme),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        autofocus: widget.prefilledAmount == null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [AmountInputFormatter()],
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: -1),
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixText: '$_selectedCurrency ',
                          prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: accentColor.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: accentColor.withValues(alpha: 0.1)),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _categoryId,
                              dropdownColor: cardColor,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined, color: hintColor),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                            DropdownButtonFormField<String>(
                              value: _accountId,
                              dropdownColor: cardColor,
                              decoration: InputDecoration(
                                labelText: 'Account',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: hintColor),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                              onChanged: (v) => setState(() => _accountId = v),
                            ),
                            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                            TextField(
                              controller: _noteCtrl,
                              decoration: InputDecoration(
                                labelText: 'Note (optional)',
                                prefixIcon: Icon(Icons.notes, color: hintColor),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
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

  Widget _buildMiniTab(String val, String label, Color color, ThemeData theme) {
    final selected = _type == val;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = val;
          _categoryId = null; // will be re-set by _loadDefaults
        });
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
            color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
