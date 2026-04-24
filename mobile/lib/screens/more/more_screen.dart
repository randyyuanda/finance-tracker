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
import 'about_screen.dart';
import 'feedback_screen.dart';
import 'privacy_screen.dart';

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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Gradient profile header ────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1677FF), Color(0xFF003BB8)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Text(s.accountTab,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                          onPressed: () async {
                            await Navigator.push(context, slideRoute(const SettingsScreen()));
                            _loadAvatar();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Profile row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, slideRoute(const SettingsScreen()));
                            _loadAvatar();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white24,
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
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.name ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17)),
                              const SizedBox(height: 3),
                              Text(user?.email ?? '',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () async {
                            await Navigator.push(context, slideRoute(const SettingsScreen()));
                            _loadAvatar();
                          },
                          child: Text(s.edit, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Goals & Reminders ─────────────────────────────────
                _Section(title: s.goalsReminders, items: [
                  _MenuItem(
                    icon: Icons.track_changes_outlined,
                    label: s.goals,
                    color: const Color(0xFF52C41A),
                    onTap: () => Navigator.push(context, slideRoute(const GoalsScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: s.reminders,
                    color: const Color(0xFFFFA940),
                    onTap: () => Navigator.push(context, slideRoute(const RemindersScreen())),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Finance ───────────────────────────────────────────
                _Section(title: s.finance, items: [
                  _MenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: s.accounts,
                    color: kPrimaryColor,
                    onTap: () => Navigator.push(context, slideRoute(const AccountsScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.autorenew,
                    label: s.recurringShort,
                    color: const Color(0xFF722ED1),
                    onTap: () => Navigator.push(context, slideRoute(const RecurringScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.bar_chart_outlined,
                    label: s.reportsExport,
                    color: const Color(0xFF13C2C2),
                    onTap: () => Navigator.push(context, slideRoute(const ReportsScreen())),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Simulators ────────────────────────────────────────
                _Section(title: s.simulasiKredit, items: [
                  _MenuItem(
                    icon: Icons.home_outlined,
                    label: s.simulasiKprMenu,
                    color: kPrimaryColor,
                    onTap: () => Navigator.push(context, slideRoute(const KprScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.two_wheeler_outlined,
                    label: s.simulasiMotorMenu,
                    color: const Color(0xFF52C41A),
                    onTap: () => Navigator.push(context, slideRoute(const KreditMotorScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.directions_car_outlined,
                    label: s.simulasiMobilMenu,
                    color: const Color(0xFFFFA940),
                    onTap: () => Navigator.push(context, slideRoute(const KreditMobilScreen())),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Support ───────────────────────────────────────────
                _Section(title: s.supportSection, items: [
                  _MenuItem(
                    icon: Icons.info_outline,
                    label: s.aboutUs,
                    color: kPrimaryColor,
                    onTap: () => Navigator.push(context, slideRoute(const AboutScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.feedback_outlined,
                    label: s.feedback,
                    color: const Color(0xFF13C2C2),
                    onTap: () => Navigator.push(context, slideRoute(const FeedbackScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: s.privacyPolicy,
                    color: const Color(0xFF722ED1),
                    onTap: () => Navigator.push(context, slideRoute(const PrivacyPolicyScreen())),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── App ───────────────────────────────────────────────
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
                const SizedBox(height: 100),
              ],
            ),
          ),
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
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5)),
          ),
          Card(
            margin: EdgeInsets.zero,
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
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        onTap: onTap,
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      );
}
