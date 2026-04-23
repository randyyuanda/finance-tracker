import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/stat_card.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().fetch(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
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
                          const SizedBox(height: 16),
                          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            dash.stats != null ? formatCurrency(dash.stats!.totalBalance) : '—',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
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
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildListDelegate([
                    StatCard(
                      label: 'Monthly Income',
                      value: formatCurrency(dash.stats?.monthlyIncome ?? 0),
                      icon: Icons.arrow_downward_rounded,
                      color: kIncomeColor,
                    ),
                    StatCard(
                      label: 'Monthly Expense',
                      value: formatCurrency(dash.stats?.monthlyExpense ?? 0),
                      icon: Icons.arrow_upward_rounded,
                      color: kExpenseColor,
                    ),
                    StatCard(
                      label: 'Net Savings',
                      value: formatCurrency(dash.stats?.monthlySavings ?? 0),
                      icon: Icons.savings_outlined,
                      color: kPrimaryColor,
                    ),
                    StatCard(
                      label: 'Accounts',
                      value: '${dash.accounts.length}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF722ED1),
                    ),
                  ]),
                ),
              ),

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
                              colors: [
                                _hexColor(acc.color),
                                _hexColor(acc.color).withOpacity(0.7),
                              ],
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

              if (dash.recentTransactions.isNotEmpty) ...[
                _sectionHeader(context, 'Recent Transactions'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TransactionTile(transaction: dash.recentTransactions[i]),
                    childCount: dash.recentTransactions.length,
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
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
