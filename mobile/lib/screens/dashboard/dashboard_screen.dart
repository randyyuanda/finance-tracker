import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/formatters.dart';
import '../../core/l10n.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../currency/exchange_rate_screen.dart';
import '../goals/goals_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reports/reports_screen.dart';
import '../simulations/simulasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadLocalAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetch();
    });
  }

  Future<void> _loadLocalAvatar() async {
    final path = await Storage.getLocalAvatar();
    if (mounted) setState(() => _localAvatarPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().fetch(),
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1677FF), Color(0xFF0958D9)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      // kToolbarHeight pushes content below the pinned AppBar toolbar
                      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s.hi}, ${auth.user?.name.split(' ').first ?? ''}!',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      s.financialOverview,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                backgroundImage: _localAvatarPath != null
                                    ? FileImage(File(_localAvatarPath!)) as ImageProvider<Object>
                                    : (auth.user?.avatar != null && auth.user!.avatar!.isNotEmpty)
                                        ? NetworkImage(auth.user!.avatar!.startsWith('http') 
                                            ? auth.user!.avatar! 
                                            : '${ApiClient.dio.options.baseUrl}${auth.user!.avatar!}') as ImageProvider<Object>
                                        : null,
                                child: (_localAvatarPath == null && (auth.user?.avatar == null || auth.user!.avatar!.isEmpty))
                                    ? Text(
                                        auth.user?.name.isNotEmpty == true
                                            ? auth.user!.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(s.totalBalance,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 2),
                          if (dash.stats == null)
                            const Text('—', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))
                          else if (dash.stats!.balancesByCurrency.length <= 1)
                            Text(
                              formatCurrency(dash.stats!.totalBalance,
                                  currency: dash.stats!.balancesByCurrency.keys.firstOrNull ?? 'IDR'),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: dash.stats!.balancesByCurrency.entries.map((e) => Text(
                                formatCurrency(e.value, currency: e.key),
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              )).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(s.dashboardTitle, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
              backgroundColor: kPrimaryColor,
            ),

            if (dash.loading && dash.stats == null)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
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
                      label: s.income,
                      value: formatCurrency(dash.stats?.monthlyIncome ?? 0),
                      icon: Icons.arrow_downward_rounded,
                      color: kIncomeColor,
                    ),
                    _StatCard(
                      label: s.expense,
                      value: formatCurrency(dash.stats?.monthlyExpense ?? 0),
                      icon: Icons.arrow_upward_rounded,
                      color: kExpenseColor,
                    ),
                    _StatCard(
                      label: s.netSavings,
                      value: formatCurrency(dash.stats?.monthlySavings ?? 0),
                      icon: Icons.savings_outlined,
                      color: kPrimaryColor,
                    ),
                    _StatCard(
                      label: s.accounts,
                      value: '${dash.accounts.length}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF722ED1),
                    ),
                  ]),
                ),
              ),

              // ── Feature quick-access ──────────────────────────────
              _sectionHeader(context, s.features),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FeatureChip(
                        icon: Icons.track_changes,
                        label: s.goals,
                        color: const Color(0xFF52C41A),
                        onTap: () => Navigator.push(
                            context, slideRoute(const GoalsScreen())),
                      ),
                      _FeatureChip(
                        icon: Icons.notifications_outlined,
                        label: s.reminders,
                        color: const Color(0xFFFFA940),
                        onTap: () => Navigator.push(
                            context, slideRoute(const RemindersScreen())),
                      ),
                      _FeatureChip(
                        icon: Icons.home_outlined,
                        label: 'KPR',
                        color: kPrimaryColor,
                        onTap: () => Navigator.push(
                            context, slideRoute(const KprScreen())),
                      ),
                      _FeatureChip(
                        icon: Icons.two_wheeler_outlined,
                        label: s.simMotorTitle,
                        color: const Color(0xFF52C41A),
                        onTap: () => Navigator.push(
                            context, slideRoute(const KreditMotorScreen())),
                      ),
                      _FeatureChip(
                        icon: Icons.directions_car_outlined,
                        label: s.simMobilTitle,
                        color: const Color(0xFFFFA940),
                        onTap: () => Navigator.push(
                            context, slideRoute(const KreditMobilScreen())),
                      ),
                      _FeatureChip(
                        icon: Icons.bar_chart_outlined,
                        label: s.reportsTitle,
                        color: const Color(0xFF13C2C2),
                        onTap: () => Navigator.push(
                            context, slideRoute(const ReportsScreen())),
                      ),
                      _FeatureChip(
                        icon: Icons.currency_exchange,
                        label: 'Rates',
                        color: const Color(0xFFFAAD14),
                        onTap: () => Navigator.push(
                            context, slideRoute(const ExchangeRateScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Income vs Expense Chart ────────────────────────────
              if (dash.stats != null &&
                  (dash.stats!.monthlyIncome > 0 ||
                      dash.stats!.monthlyExpense > 0)) ...[
                _sectionHeader(context, s.thisMonth),
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
                _sectionHeader(context, s.last7Days),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SpendingBarChart(transactions: dash.recentTransactions),
                  ),
                ),
              ],

              // ── Accounts carousel ─────────────────────────────────
              if (dash.accounts.isNotEmpty) ...[
                _sectionHeader(context, s.accounts),
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
                              colors: [
                                _hexColor(acc.color),
                                _hexColor(acc.color).withValues(alpha: 0.7)
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(acc.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(formatCurrency(acc.balance, currency: acc.currency),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
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
                _sectionHeader(context, s.recentTransactions),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) =>
                        TransactionTile(transaction: dash.recentTransactions[i]),
                    childCount: dash.recentTransactions.length.clamp(0, 5),
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

// ── Feature chip ──────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card widget ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Income vs Expense donut chart ─────────────────────────────────────────────

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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                  PieChartSectionData(value: income, color: kIncomeColor, title: '', radius: 40),
                  PieChartSectionData(value: expense, color: kExpenseColor, title: '', radius: 40),
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
                _LegendRow(
                    color: kIncomeColor,
                    label: context.l10n.income,
                    value: formatCurrency(income),
                    pct: total > 0 ? (income / total * 100).round() : 0),
                const SizedBox(height: 12),
                _LegendRow(
                    color: kExpenseColor,
                    label: context.l10n.expense,
                    value: formatCurrency(expense),
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

  const _LegendRow(
      {required this.color,
      required this.label,
      required this.value,
      required this.pct});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                Text(value,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}

// ── Last 7 days spending bar chart ────────────────────────────────────────────

class _SpendingBarChart extends StatelessWidget {
  final List<Transaction> transactions;

  const _SpendingBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days =
        List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dot(kIncomeColor),
              const SizedBox(width: 4),
              Text(context.l10n.income, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              _dot(kExpenseColor),
              const SizedBox(width: 4),
              Text(context.l10n.expense, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey.withValues(alpha: 0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        formatCurrency(rod.toY),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        const labels = [
                          'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                        ];
                        final weekday = days[i].weekday - 1;
                        return Text(labels[weekday],
                            style: const TextStyle(fontSize: 10));
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
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
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: expenseByDay[i] ?? 0,
                        color: kExpenseColor.withValues(alpha: 0.85),
                        width: 10,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
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

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
