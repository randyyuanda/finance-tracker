import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(s.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF003BB8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.privacyPolicy,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      const Text('Last updated: April 2026',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._sections.map((sec) => _PolicySection(title: sec.$1, body: sec.$2)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static const _sections = [
    (
      'Information We Collect',
      'BuxBux collects information you provide directly, such as your name, email address, and financial transaction data you enter into the app. We do not collect sensitive personal or banking credentials.',
    ),
    (
      'How We Use Your Information',
      'We use the information you provide solely to power the features of BuxBux — including transaction tracking, goal monitoring, and report generation. We do not sell or share your personal data with third parties for marketing purposes.',
    ),
    (
      'Data Storage',
      'Your financial data is stored securely on our servers. We use industry-standard encryption to protect your information in transit and at rest. Transaction data is stored only for as long as your account remains active.',
    ),
    (
      'Third-Party Services',
      'BuxBux uses Firebase for push notifications. Firebase may collect device-level information in accordance with Google\'s privacy policy. We do not use any advertising SDKs.',
    ),
    (
      'Data Deletion',
      'You may request deletion of your account and all associated data at any time by contacting us at support@buxbux.app. Deletion will be processed within 30 days.',
    ),
    (
      'Security',
      'We take the security of your data seriously and implement appropriate technical and organizational measures to protect it against unauthorized access, alteration, disclosure, or destruction.',
    ),
    (
      'Changes to This Policy',
      'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app. Continued use of BuxBux after changes constitutes acceptance of the updated policy.',
    ),
    (
      'Contact Us',
      'If you have any questions about this Privacy Policy or our data practices, please contact us at support@buxbux.app.',
    ),
  ];
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.6)),
        ],
      ),
    );
  }
}
