import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/recurring_provider.dart';
import '../../models/recurring_transaction.dart';
import '../../widgets/empty_state.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<RecurringProvider>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? const EmptyState(icon: Icons.autorenew, title: 'No recurring transactions', subtitle: 'Set up recurring transactions in the web app')
              : RefreshIndicator(
                  onRefresh: () => context.read<RecurringProvider>().fetchAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.items.length,
                    itemBuilder: (_, i) => _RecurringTile(item: provider.items[i]),
                  ),
                ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransaction item;
  const _RecurringTile({required this.item});

  Color get _color => item.type == 'income' ? kIncomeColor : kExpenseColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.autorenew, color: _color, size: 20),
        ),
        title: Text(item.categoryName ?? item.note ?? 'Recurring',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.accountName ?? ''} · ${item.frequency}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text('Next: ${formatDate(item.nextDue)}',
                style: TextStyle(fontSize: 12, color: item.nextDue.isBefore(DateTime.now()) ? kExpenseColor : Colors.grey.shade600)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.type == 'income' ? '+' : '-'}${formatCurrency(item.amount)}',
              style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.isActive ? kIncomeColor.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.isActive ? 'Active' : 'Paused',
                style: TextStyle(
                  fontSize: 10,
                  color: item.isActive ? kIncomeColor : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onLongPress: () {
          context.read<RecurringProvider>().toggleActive(item.id, !item.isActive);
        },
      ),
    );
  }
}
