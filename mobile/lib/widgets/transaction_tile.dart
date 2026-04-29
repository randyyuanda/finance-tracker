import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionTile({super.key, required this.transaction, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final color = isIncome ? kIncomeColor : (isTransfer ? kPrimaryColor : kExpenseColor);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isTransfer ? Icons.swap_horiz : (isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          isTransfer
              ? 'Transfer'
              : (transaction.categoryName ?? 'Uncategorized'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          isTransfer
              ? '${transaction.accountName ?? ''} → ${transaction.toAccountName ?? ''} · ${formatDate(transaction.date)}'
              : '${transaction.note ?? transaction.accountName ?? ''} · ${formatDate(transaction.date)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : isTransfer ? '' : '-'}${formatCurrency(transaction.amount, currency: transaction.accountCurrency)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
