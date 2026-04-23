import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().fetch(),
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1677FF), Color(0xFF0958D9)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi, ${auth.user?.name.split(' ').first ?? ''}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Financial Overview',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  auth.user?.name.isNotEmpty == true ? auth.user!.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            dash.stats != null ? formatCurrency(dash.stats!.totalBalance) : '—',
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              backgroundColor: kPrimaryColor,
            ),

            if (dash.loading && dash.stats == null)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else ...[
              // ── Stats grid ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildListDelegate([
                    _StatCard(
                      label: 'Income',
                      value: formatCurrency(dash.stats?.monthlyIncome ?? 0),
                      icon: Icons.arrow_downward_rounded,
                      color: kIncomeColor,
                    ),
                    _StatCard(
                      label: 'Expense',
                      value: formatCurrency(dash.stats?.monthlyExpense ?? 0),
                      icon: Icons.arrow_upward_rounded,
                      color: kExpenseColor,
                    ),
                    _StatCard(
                      label: 'Net Savings',
                      value: formatCurrency(dash.stats?.monthlySavings ?? 0),
                      icon: Icons.savings_outlined,
                      color: kPrimaryColor,
                    ),
                    _StatCard(
                      label: 'Accounts',
                      value: '${dash.accounts.length}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF722ED1),
                    ),
                  ]),
                ),
              ),

              // ── Income vs Expense Chart ────────────────────────────
              if (dash.stats != null &&
                  (dash.stats!.monthlyIncome > 0 || dash.stats!.monthlyExpense > 0)) ...[
                _sectionHeader(context, 'This Month'),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _IncomeExpenseChart(
                      income: dash.stats!.monthlyIncome,
                      expense: dash.stats!.monthlyExpense,
                    ),
                  ),
                ),
              ],

              // ── Spending trend (last 7 days) ─────────────────────
              if (dash.recentTransactions.isNotEmpty) ...[
                _sectionHeader(context, 'Last 7 Days'),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SpendingBarChart(transactions: dash.recentTransactions),
                  ),
                ),
              ],

              // ── Accounts carousel ─────────────────────────────────
              if (dash.accounts.isNotEmpty) ...[
                _sectionHeader(context, 'Accounts'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dash.accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final acc = dash.accounts[i];
                        return Container(
                          width: 160,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [_hexColor(acc.color), _hexColor(acc.color).withValues(alpha: 0.7)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(acc.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(formatCurrency(acc.balance),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ── Recent transactions ───────────────────────────────
              if (dash.recentTransactions.isNotEmpty) ...[
                _sectionHeader(context, 'Recent Transactions'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TransactionTile(transaction: dash.recentTransactions[i]),
                    childCount: dash.recentTransactions.length.clamp(0, 5),
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return kPrimaryColor;
    }
  }
}

// ── Stat card widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Income vs Expense donut chart ───────────────────────────────────────────

class _IncomeExpenseChart extends StatelessWidget {
  final double income;
  final double expense;

  const _IncomeExpenseChart({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 130,
            width: 130,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: income,
                    color: kIncomeColor,
                    title: '',
                    radius: 40,
                  ),
                  PieChartSectionData(
                    value: expense,
                    color: kExpenseColor,
                    title: '',
                    radius: 40,
                  ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendRow(color: kIncomeColor, label: 'Income', value: formatCurrency(income),
                    pct: total > 0 ? (income / total * 100).round() : 0),
                const SizedBox(height: 12),
                _LegendRow(color: kExpenseColor, label: 'Expense', value: formatCurrency(expense),
                    pct: total > 0 ? (expense / total * 100).round() : 0),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Text('Net: ${formatCurrency(income - expense)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: income >= expense ? kIncomeColor : kExpenseColor,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final int pct;

  const _LegendRow({required this.color, required this.label, required this.value, required this.pct});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('$pct%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}

// ── Last 7 days spending bar chart ──────────────────────────────────────────

class _SpendingBarChart extends StatelessWidget {
  final List<Transaction> transactions;

  const _SpendingBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final incomeByDay = <int, double>{};
    final expenseByDay = <int, double>{};

    for (final t in transactions) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      final idx = days.indexWhere((day) => day.isAtSameMomentAs(d));
      if (idx == -1) continue;
      if (t.type == 'income') {
        incomeByDay[idx] = (incomeByDay[idx] ?? 0) + t.amount;
      } else {
        expenseByDay[idx] = (expenseByDay[idx] ?? 0) + t.amount;
      }
    }

    final maxY = [
      ...incomeByDay.values,
      ...expenseByDay.values,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dot(kIncomeColor), const SizedBox(width: 4),
              const Text('Income', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              _dot(kExpenseColor), const SizedBox(width: 4),
              const Text('Expense', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final weekday = days[i].weekday - 1;
                        return Text(labels[weekday], style: const TextStyle(fontSize: 10));
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: incomeByDay[i] ?? 0,
                        color: kIncomeColor.withValues(alpha: 0.85),
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: expenseByDay[i] ?? 0,
                        color: kExpenseColor.withValues(alpha: 0.85),
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                    barsSpace: 3,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
