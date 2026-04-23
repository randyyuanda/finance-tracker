import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    context.read<TransactionProvider>().fetchAll(reset: true);
  }

  List<Transaction> get _filtered {
    return context.read<TransactionProvider>().transactions.where((t) {
      return t.date.month == _selectedMonth && t.date.year == _selectedYear;
    }).toList();
  }

  double get _totalIncome => _filtered.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
  double get _totalExpense => _filtered.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);

  Map<String, double> get _categoryBreakdown {
    final map = <String, double>{};
    for (final t in _filtered.where((t) => t.type == 'expense')) {
      final cat = t.categoryName ?? 'Other';
      map[cat] = (map[cat] ?? 0) + t.amount;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(6));
  }

  Future<void> _exportCsv() async {
    final all = context.read<TransactionProvider>().transactions;
    final buf = StringBuffer();
    buf.writeln('Date,Type,Category,Account,Amount (IDR),Note');
    for (final t in all) {
      final note = (t.note ?? '').replaceAll(',', ';');
      buf.writeln('${formatDate(t.date)},${t.type},${t.categoryName ?? ''},${t.accountName ?? ''},${t.amount.toStringAsFixed(0)},$note');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/fintrack_transactions.csv');
    await file.writeAsString(buf.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'FinTrack Transactions',
      text: 'Here are my transactions exported from FinTrack.',
    );
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) return;
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));
    final breakdown = _categoryBreakdown;
    final income = _totalIncome;
    final expense = _totalExpense;

    final catColors = [
      const Color(0xFF1677FF), const Color(0xFFFF4D4F), const Color(0xFF52C41A),
      const Color(0xFFFAAD14), const Color(0xFF722ED1), const Color(0xFF13C2C2),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: provider.loading ? null : _exportCsv,
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Month selector ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                      Text(monthLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(
                        onPressed: (_selectedYear == DateTime.now().year && _selectedMonth == DateTime.now().month)
                            ? null
                            : _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Summary cards ───────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _SummaryCard(label: 'Income', value: income, color: kIncomeColor, icon: Icons.arrow_downward_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(label: 'Expense', value: expense, color: kExpenseColor, icon: Icons.arrow_upward_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  label: 'Net Savings',
                  value: income - expense,
                  color: income >= expense ? kIncomeColor : kExpenseColor,
                  icon: Icons.savings_outlined,
                  wide: true,
                ),
                const SizedBox(height: 20),

                // ── Category breakdown ──────────────────────────────
                if (breakdown.isNotEmpty) ...[
                  const Text('Spending by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: breakdown.entries.mapIndexed((i, e) {
                                final pct = expense > 0 ? (e.value / expense * 100).round() : 0;
                                return PieChartSectionData(
                                  value: e.value,
                                  color: catColors[i % catColors.length],
                                  title: '$pct%',
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                  radius: 70,
                                );
                              }).toList(),
                              sectionsSpace: 3,
                              centerSpaceRadius: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...breakdown.entries.mapIndexed((i, e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10,
                                      decoration: BoxDecoration(color: catColors[i % catColors.length], shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                                  Text(formatCurrency(e.value), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Transaction list ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${_filtered.length} total', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text('No transactions in $monthLabel',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  )
                else
                  ..._filtered.map((t) => _TxRow(t: t)),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool wide;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: wide
          ? Row(
              children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, color: color, size: 18)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  Text(formatCurrency(value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
                ]),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 16)),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(formatCurrency(value),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction t;
  const _TxRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == 'income';
    final color = isIncome ? kIncomeColor : kExpenseColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.categoryName ?? 'Uncategorized', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${t.accountName ?? ''} · ${formatDate(t.date)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Text('${isIncome ? '+' : '-'}${formatCurrency(t.amount)}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }
}

extension _MapIndexed<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(int index, MapEntry<K, V> entry) fn) sync* {
    var i = 0;
    for (final e in this) {
      yield fn(i++, e);
    }
  }
}
