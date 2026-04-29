import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/quick_add_config.dart';
import '../../core/input_formatters.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/quick_add_provider.dart';

class QuickAddSettingsScreen extends StatelessWidget {
  const QuickAddSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final configs = context.watch<QuickAddProvider>().configs;

    return Scaffold(
      appBar: AppBar(title: Text(s.quickAddSettings)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: configs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final config = configs[index];
          return _ConfigCard(index: index, config: config);
        },
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final int index;
  final QuickAddConfig config;

  const _ConfigCard({required this.index, required this.config});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final color = config.type == 'income' ? kIncomeColor : kExpenseColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            config.type == 'income' ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: color,
          ),
        ),
        title: Text(config.label ?? (config.type == 'income' ? '+ ${config.amount}' : '- ${config.amount}'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${config.categoryName ?? s.uncategorized} • ${config.accountName ?? s.account}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 20),
        onTap: () => _editConfig(context),
      ),
    );
  }

  void _editConfig(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditConfigSheet(index: index, config: config),
    );
  }
}

class _EditConfigSheet extends StatefulWidget {
  final int index;
  final QuickAddConfig config;

  const _EditConfigSheet({required this.index, required this.config});

  @override
  State<_EditConfigSheet> createState() => _EditConfigSheetState();
}

class _EditConfigSheetState extends State<_EditConfigSheet> {
  late String _type;
  late TextEditingController _labelCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  String? _accountId;
  String? _accountName;
  String? _currency;
  String? _categoryId;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _type = widget.config.type;
    _labelCtrl = TextEditingController(text: widget.config.label);
    _amountCtrl = TextEditingController(text: widget.config.amount.toStringAsFixed(0));
    _noteCtrl = TextEditingController(text: widget.config.note);
    _accountId = widget.config.accountId;
    _accountName = widget.config.accountName;
    _currency = widget.config.currency;
    _categoryId = widget.config.categoryId;
    _categoryName = widget.config.categoryName;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final accounts = context.watch<AccountProvider>().accounts;
    final categories = context.watch<CategoryProvider>().categories.where((c) => c.type == _type).toList();
    final displayCurrency = _currency ?? (_accountId != null
        ? (accounts.where((a) => a.id == _accountId).firstOrNull?.currency ?? 'IDR')
        : 'IDR');

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.editQuickAdd, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'expense', label: Text(s.expense), icon: const Icon(Icons.remove_circle_outline)),
              ButtonSegment(value: 'income', label: Text(s.income), icon: const Icon(Icons.add_circle_outline)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(labelText: s.label, hintText: 'e.g. Lunch, Coffee'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [AmountInputFormatter()],
            decoration: InputDecoration(
              labelText: s.amount,
              prefixText: '$displayCurrency ',
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _accountId,
            decoration: InputDecoration(labelText: s.account),
            items: accounts.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text('${a.name} (${a.currency})'),
            )).toList(),
            onChanged: (v) {
              if (v == null) return;
              final acct = accounts.firstWhere((a) => a.id == v);
              setState(() {
                _accountId = v;
                _accountName = acct.name;
                _currency = acct.currency;
              });
            },
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _categoryId,
            decoration: InputDecoration(labelText: s.category),
            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) {
              setState(() {
                _categoryId = v;
                _categoryName = categories.firstWhere((c) => c.id == v).name;
              });
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(labelText: s.note),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              final amountStr = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              final config = QuickAddConfig(
                id: widget.config.id,
                type: _type,
                amount: double.tryParse(amountStr) ?? 0,
                label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
                accountId: _accountId,
                accountName: _accountName,
                currency: _currency,
                categoryId: _categoryId,
                categoryName: _categoryName,
                note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              );
              context.read<QuickAddProvider>().updateConfig(widget.index, config);
              Navigator.pop(context);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }
}
