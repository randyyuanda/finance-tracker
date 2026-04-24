import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../main.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/empty_state.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      context.read<AccountProvider>().fetchAll();
      context.read<CategoryProvider>().fetchAll();
    });
  }

  void _load() => context.read<TransactionProvider>().fetchAll(reset: true, type: _filterType);

  Future<void> _addTransaction() async {
    final result = await Navigator.push<bool>(context, slideRoute(const AddTransactionScreen()));
    if (result == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.transactions),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (v) {
              setState(() => _filterType = v);
              _load();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Row(children: [
                  Icon(Icons.list, size: 18, color: _filterType == null ? Theme.of(context).colorScheme.primary : null),
                  const SizedBox(width: 8),
                  const Text('All'),
                ]),
              ),
              PopupMenuItem(
                value: 'income',
                child: Row(children: [
                  Icon(Icons.arrow_downward_rounded, size: 18, color: _filterType == 'income' ? Colors.green : null),
                  const SizedBox(width: 8),
                  const Text('Income'),
                ]),
              ),
              PopupMenuItem(
                value: 'expense',
                child: Row(children: [
                  Icon(Icons.arrow_upward_rounded, size: 18, color: _filterType == 'expense' ? Colors.red : null),
                  const SizedBox(width: 8),
                  const Text('Expense'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: provider.loading && provider.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.transactions.isEmpty
              ? EmptyState(
                  icon: Icons.swap_horiz,
                  title: 'No transactions yet',
                  subtitle: 'Tap + to add your first transaction',
                  actionLabel: 'Add Transaction',
                  onAction: _addTransaction,
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.transactions.length,
                    itemBuilder: (_, i) {
                      final tx = provider.transactions[i];
                      return TransactionTile(
                        transaction: tx,
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete transaction?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await context.read<TransactionProvider>().delete(tx.id);
                          }
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
