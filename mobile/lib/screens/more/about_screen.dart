import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1677FF), Color(0xFF003BB8)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset('assets/logo.png', width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      const Text('BuxBux',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(s.appTagline,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: kPrimaryColor,
            title: Text(s.aboutUs, style: const TextStyle(color: Colors.white)),
            foregroundColor: Colors.white,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoCard(
                  cardColor: cardColor,
                  children: [
                    _InfoRow(label: s.versionLabel, value: '1.0.0'),
                    _InfoRow(label: 'Platform', value: 'Android'),
                    _InfoRow(label: 'Build', value: '2026'),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel('Description'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'BuxBux is a personal finance management app that helps you track income, expenses, set savings goals, manage accounts, and plan major purchases with built-in loan simulators. Take control of your financial future.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Features'),
                const SizedBox(height: 8),
                _InfoCard(
                  cardColor: cardColor,
                  children: [
                    _FeatureRow(icon: Icons.swap_horiz, label: 'Income & Expense Tracking'),
                    _FeatureRow(icon: Icons.track_changes, label: 'Savings Goals'),
                    _FeatureRow(icon: Icons.notifications_outlined, label: 'Smart Reminders'),
                    _FeatureRow(icon: Icons.home_outlined, label: 'Loan Simulators (KPR, Motor, Mobil)'),
                    _FeatureRow(icon: Icons.bar_chart_outlined, label: 'Financial Reports & CSV Export'),
                    _FeatureRow(icon: Icons.autorenew, label: 'Recurring Transactions'),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel('Legal'),
                const SizedBox(height: 8),
                _InfoCard(
                  cardColor: cardColor,
                  children: [
                    _InfoRow(label: 'Developer', value: 'BuxBux Team'),
                    _InfoRow(label: 'Contact', value: 'support@buxbux.app'),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© 2026 BuxBux. All rights reserved.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8),
      );
}

class _InfoCard extends StatelessWidget {
  final Color cardColor;
  final List<Widget> children;
  const _InfoCard({required this.cardColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(children.length, (i) => Column(children: [
          children[i],
          if (i < children.length - 1)
            Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
        ])),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: kPrimaryColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
