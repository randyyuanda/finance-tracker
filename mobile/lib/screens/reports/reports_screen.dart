import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/formatters.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedAccountId; // null = all accounts
  String _selectedType = 'all'; // 'all' | 'income' | 'expense'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    context.read<TransactionProvider>().fetchAll(reset: true, limit: 1000);
  }

  List<Transaction> get _filtered {
    return context.read<TransactionProvider>().transactions.where((t) {
      if (t.date.month != _selectedMonth || t.date.year != _selectedYear) return false;
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) return false;
      if (_selectedType != 'all' && t.type != _selectedType) return false;
      return true;
    }).toList();
  }

  double get _totalIncome => _filtered.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
  double get _totalExpense => _filtered.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);

  Map<String, double> get _categoryBreakdown {
    final source = _selectedType == 'income'
        ? _filtered.where((t) => t.type == 'income')
        : _filtered.where((t) => t.type == 'expense');
    final map = <String, double>{};
    for (final t in source) {
      final cat = t.categoryName ?? context.l10n.other;
      map[cat] = (map[cat] ?? 0) + t.amount;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(6));
  }

  Future<void> _exportCsv() async {
    final txns = _filtered;
    final s = context.l10n;
    final accounts = context.read<AccountProvider>().accounts;
    final currencyMap = {for (final a in accounts) a.id: a.currency};
    final accountName = _selectedAccountId != null
        ? accounts.where((a) => a.id == _selectedAccountId).map((a) => a.name).firstOrNull ?? 'Account'
        : 'All Accounts';
    final typeLabel = _selectedType == 'all' ? 'All' : _selectedType[0].toUpperCase() + _selectedType.substring(1);

    final buf = StringBuffer();
    buf.writeln('# Report: $accountName | $typeLabel | ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}');
    buf.writeln('${s.date},${s.accountType},${s.category},${s.account},Amount,Currency,${s.note}');
    for (final t in txns) {
      final note = (t.note ?? '').replaceAll(',', ';');
      final currency = currencyMap[t.accountId] ?? 'IDR';
      buf.writeln('${formatDate(t.date)},${t.type},${t.categoryName ?? ''},${t.accountName ?? ''},${t.amount.toStringAsFixed(2)},$currency,$note');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/buxbux_report_${_selectedYear}_$_selectedMonth.csv');
    await file.writeAsString(buf.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: s.csvExportSubject,
      text: s.csvExportText,
    );
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) { _selectedMonth = 12; _selectedYear--; }
      else { _selectedMonth--; }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) return;
    setState(() {
      if (_selectedMonth == 12) { _selectedMonth = 1; _selectedYear++; }
      else { _selectedMonth++; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final accounts = context.watch<AccountProvider>().accounts;
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
        title: Text(context.l10n.reportsTitle),
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
                // ── Month selector ──
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
                        onPressed: (_selectedYear == DateTime.now().year && _selectedMonth == DateTime.now().month) ? null : _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Account filter ──
                if (accounts.isNotEmpty) ...[
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All Accounts',
                          selected: _selectedAccountId == null,
                          onTap: () => setState(() => _selectedAccountId = null),
                        ),
                        ...accounts.map((a) => _FilterChip(
                          label: a.name,
                          selected: _selectedAccountId == a.id,
                          onTap: () => setState(() => _selectedAccountId = a.id),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Type filter ──
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedType == 'all',
                      onTap: () => setState(() => _selectedType = 'all'),
                      color: kPrimaryColor,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Income',
                      selected: _selectedType == 'income',
                      onTap: () => setState(() => _selectedType = 'income'),
                      color: kIncomeColor,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Expense',
                      selected: _selectedType == 'expense',
                      onTap: () => setState(() => _selectedType = 'expense'),
                      color: kExpenseColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Summary cards ──
                if (_selectedType != 'expense')
                  Row(children: [
                    Expanded(child: _SummaryCard(label: context.l10n.income, value: income, color: kIncomeColor, icon: Icons.arrow_downward_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(label: context.l10n.expense, value: expense, color: kExpenseColor, icon: Icons.arrow_upward_rounded)),
                  ])
                else
                  _SummaryCard(label: context.l10n.expense, value: expense, color: kExpenseColor, icon: Icons.arrow_upward_rounded, wide: true),

                if (_selectedType == 'all') ...[
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: context.l10n.netSavings,
                    value: income - expense,
                    color: income >= expense ? kIncomeColor : kExpenseColor,
                    icon: Icons.savings_outlined,
                    wide: true,
                  ),
                ],
                const SizedBox(height: 20),

                // ── Category breakdown ──
                if (breakdown.isNotEmpty) ...[
                  Text(
                    _selectedType == 'income' ? 'Income by Category' : context.l10n.spendingByCategory,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
                                final total = breakdown.values.fold(0.0, (s, v) => s + v);
                                final pct = total > 0 ? (e.value / total * 100).round() : 0;
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

                // ── Transaction list ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.transactions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(context.l10n.totalCount(_filtered.length), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(context.l10n.noTransactionsIn(monthLabel),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : c.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c,
          ),
        ),
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
          ? Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text(formatCurrency(value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
              ]),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16)),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(formatCurrency(value),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction t;
  const _TxRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final color = isIncome ? kIncomeColor : (isTransfer ? kPrimaryColor : kExpenseColor);
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
              child: Icon(
                isTransfer ? Icons.swap_horiz : (isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                color: color, size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isTransfer ? 'Transfer' : (t.categoryName ?? context.l10n.uncategorized),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  isTransfer
                      ? '${t.accountName ?? ''} → ${t.toAccountName ?? ''}'
                      : '${t.accountName ?? ''} · ${formatDate(t.date)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            Text(
              '${isIncome ? '+' : isTransfer ? '' : '-'}${formatCurrency(t.amount)}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

extension _MapIndexed<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(int index, MapEntry<K, V> entry) fn) sync* {
    var i = 0;
    for (final e in this) { yield fn(i++, e); }
  }
}
