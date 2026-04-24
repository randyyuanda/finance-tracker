import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../accounts/accounts_screen.dart';
import '../goals/goals_screen.dart';
import '../recurring/recurring_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../simulations/simulasi_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final path = await Storage.getLocalAvatar();
    if (mounted) setState(() => _localAvatarPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: Text(s.accountTab)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile card ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, slideRoute(const SettingsScreen()));
                      _loadAvatar();
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: kPrimaryColor,
                      backgroundImage: _localAvatarPath != null
                          ? FileImage(File(_localAvatarPath!))
                          : null,
                      child: _localAvatarPath == null
                          ? Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(user?.email ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await Navigator.push(
                          context, slideRoute(const SettingsScreen()));
                      _loadAvatar();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Goals & Reminders ─────────────────────────────────────
          _Section(title: s.goalsReminders, items: [
            _MenuItem(
              icon: Icons.track_changes_outlined,
              label: s.goals,
              color: const Color(0xFF52C41A),
              onTap: () =>
                  Navigator.push(context, slideRoute(const GoalsScreen())),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: s.reminders,
              color: const Color(0xFFFFA940),
              onTap: () =>
                  Navigator.push(context, slideRoute(const RemindersScreen())),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Finance ───────────────────────────────────────────────
          _Section(title: s.finance, items: [
            _MenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: s.accounts,
              color: kPrimaryColor,
              onTap: () =>
                  Navigator.push(context, slideRoute(const AccountsScreen())),
            ),
            _MenuItem(
              icon: Icons.autorenew,
              label: s.recurringShort,
              color: const Color(0xFF722ED1),
              onTap: () =>
                  Navigator.push(context, slideRoute(const RecurringScreen())),
            ),
            _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: s.reportsExport,
              color: const Color(0xFF13C2C2),
              onTap: () =>
                  Navigator.push(context, slideRoute(const ReportsScreen())),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Simulators ────────────────────────────────────────────
          _Section(title: s.simulasiKredit, items: [
            _MenuItem(
              icon: Icons.home_outlined,
              label: s.simulasiKprMenu,
              color: kPrimaryColor,
              onTap: () =>
                  Navigator.push(context, slideRoute(const KprScreen())),
            ),
            _MenuItem(
              icon: Icons.two_wheeler_outlined,
              label: s.simulasiMotorMenu,
              color: const Color(0xFF52C41A),
              onTap: () =>
                  Navigator.push(context, slideRoute(const KreditMotorScreen())),
            ),
            _MenuItem(
              icon: Icons.directions_car_outlined,
              label: s.simulasiMobilMenu,
              color: const Color(0xFFFFA940),
              onTap: () =>
                  Navigator.push(context, slideRoute(const KreditMobilScreen())),
            ),
          ]),
          const SizedBox(height: 8),

          // ── App ───────────────────────────────────────────────────
          _Section(title: s.appSection, items: [
            _MenuItem(
              icon: Icons.settings_outlined,
              label: s.settings,
              color: Colors.grey.shade600,
              onTap: () async {
                await Navigator.push(context, slideRoute(const SettingsScreen()));
                _loadAvatar();
              },
            ),
            _MenuItem(
              icon: Icons.logout,
              label: s.signOut,
              color: kExpenseColor,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(s.signOutTitle),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(s.cancel)),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(s.signOut,
                              style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<AuthProvider>().logout();
                }
              },
            ),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
          ),
          Card(
            child: Column(
              children: List.generate(
                items.length,
                (i) => Column(children: [
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: Colors.grey.shade100),
                ]),
              ),
            ),
          ),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      );
}
