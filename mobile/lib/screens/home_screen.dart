import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'goals/goals_screen.dart';
import 'reminders/reminders_screen.dart';
import 'more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _adminPollTimer;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    GoalsScreen(),
    RemindersScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<ReminderProvider>();
      rp.fetchAll();
      rp.checkAdminNotifications();
      // Poll admin notifications every 3 minutes so broadcasts created while
      // the app is open are picked up and scheduled before their fire time.
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

  @override
  Widget build(BuildContext context) {
    final overdueCount = context.watch<ReminderProvider>().overdueCount;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: 'Transactions',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.track_changes_outlined),
              activeIcon: Icon(Icons.track_changes),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: overdueCount > 0,
                label: Text('$overdueCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: overdueCount > 0,
                label: Text('$overdueCount'),
                child: const Icon(Icons.notifications),
              ),
              label: 'Reminders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
