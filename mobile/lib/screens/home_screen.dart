import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../main.dart';
import '../providers/reminder_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'transactions/add_transaction_screen.dart';
import 'reports/reports_screen.dart';
import 'more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _adminPollTimer;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<ReminderProvider>();
      rp.fetchAll();
      rp.checkAdminNotifications();
      _adminPollTimer = Timer.periodic(const Duration(minutes: 3), (_) {
        if (mounted) context.read<ReminderProvider>().checkAdminNotifications();
      });
    });
  }

  @override
  void dispose() {
    _adminPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openAddTransaction() async {
    await Navigator.push(context, slideRoute(const AddTransactionScreen()));
    if (mounted) {
      context.read<TransactionProvider>().fetchAll();
      context.read<DashboardProvider>().fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _GradientFAB(onTap: _openAddTransaction),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: _NavButton(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: s.navDashboard,
                    selected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _NavButton(
                    icon: Icons.swap_horiz_outlined,
                    activeIcon: Icons.swap_horiz,
                    label: s.navTransactions,
                    selected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                // Space for center FAB
                const SizedBox(width: 72),
                Expanded(
                  child: _NavButton(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: s.navReports,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Expanded(
                  child: _NavButton(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: s.navAccount,
                    selected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1677FF), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: selected
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1677FF), Color(0xFF0050CC)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  )
                : null,
            child: Icon(
              selected ? activeIcon : icon,
              color: selected ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? kPrimaryColor : Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
