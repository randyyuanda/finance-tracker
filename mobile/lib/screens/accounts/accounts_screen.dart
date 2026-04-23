import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/account_provider.dart';
import '../../models/account.dart';
import '../../widgets/empty_state.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AccountProvider>().fetchAll());
  }

  static const _iconOptions = [
    ('wallet', Icons.account_balance_wallet_outlined, 'Wallet'),
    ('bank', Icons.account_balance_outlined, 'Bank'),
    ('money', Icons.attach_money, 'Money'),
    ('credit_card', Icons.credit_card_outlined, 'Card'),
    ('savings', Icons.savings_outlined, 'Savings'),
    ('investment', Icons.trending_up, 'Invest'),
  ];

  static IconData _iconData(String icon) {
    return _iconOptions.firstWhere((e) => e.$1 == icon, orElse: () => _iconOptions.first).$2;
  }

  void _showForm({Account? account}) {
    final nameCtrl = TextEditingController(text: account?.name);
    final balanceCtrl = TextEditingController(text: account?.balance.toStringAsFixed(0));
    String type = account?.type ?? 'cash';
    String selectedIcon = account?.icon ?? 'wallet';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account == null ? 'New Account' : 'Edit Account',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                  validator: (v) => v?.isEmpty == true ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'e-wallet', child: Text('E-Wallet')),
                    DropdownMenuItem(value: 'investment', child: Text('Investment')),
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                  ],
                  onChanged: (v) => setLocal(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
                  decoration: const InputDecoration(
                    labelText: 'Balance (IDR)',
                    helperText: 'Use negative value for debt/overdraft',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _iconOptions.map((opt) {
                    final isSelected = selectedIcon == opt.$1;
                    return GestureDetector(
                      onTap: () => setLocal(() => selectedIcon = opt.$1),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? kPrimaryColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: kPrimaryColor, width: 2) : null,
                            ),
                            child: Icon(opt.$2, color: isSelected ? kPrimaryColor : Colors.grey.shade500, size: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(opt.$3, style: TextStyle(fontSize: 10, color: isSelected ? kPrimaryColor : Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'type': type,
                        'balance': double.tryParse(balanceCtrl.text) ?? 0,
                        'icon': selectedIcon,
                      };
                      final provider = context.read<AccountProvider>();
                      if (account == null) {
                        await provider.create(data);
                      } else {
                        await provider.update(account.id, data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(account == null ? 'Add Account' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return kPrimaryColor; }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.accounts.isEmpty
              ? EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No accounts',
                  actionLabel: 'Add Account',
                  onAction: () => _showForm(),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AccountProvider>().fetchAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.accounts.length,
                    itemBuilder: (_, i) {
                      final acc = provider.accounts[i];
                      final color = _hexColor(acc.color);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_iconData(acc.icon), color: color),
                          ),
                          title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(acc.type, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formatCurrency(acc.balance),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                              PopupMenuButton(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                                onSelected: (v) {
                                  if (v == 'edit') _showForm(account: acc);
                                  else context.read<AccountProvider>().delete(acc.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
    );
  }
}
