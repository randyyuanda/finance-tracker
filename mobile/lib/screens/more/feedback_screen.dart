import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/gradient_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'general';
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _sending = false);
    final s = context.l10n;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF52C41A), Color(0xFF237804)]),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(s.feedbackSentTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(s.feedbackSentMsg,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(s.feedback)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13C2C2), Color(0xFF006D75)],
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
                  child: const Icon(Icons.feedback_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share Your Thoughts',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 3),
                      Text('Your feedback helps us improve BuxBux',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                Text('Category',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _CategoryChip(
                      label: 'General',
                      value: 'general',
                      selected: _category == 'general',
                      onTap: () => setState(() => _category = 'general'),
                    ),
                    _CategoryChip(
                      label: 'Bug Report',
                      value: 'bug',
                      selected: _category == 'bug',
                      onTap: () => setState(() => _category = 'bug'),
                    ),
                    _CategoryChip(
                      label: 'Feature Request',
                      value: 'feature',
                      selected: _category == 'feature',
                      onTap: () => setState(() => _category = 'feature'),
                    ),
                    _CategoryChip(
                      label: 'Other',
                      value: 'other',
                      selected: _category == 'other',
                      onTap: () => setState(() => _category = 'other'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subject
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(
                    labelText: s.feedbackSubject,
                    prefixIcon: const Icon(Icons.subject_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a subject' : null,
                ),
                const SizedBox(height: 14),

                // Message
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: s.feedbackMessageHint,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.notes_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 10 ? 'Please write at least 10 characters' : null,
                ),
                const SizedBox(height: 28),

                GradientButton(
                  onTap: _sending ? null : _send,
                  label: s.sendFeedback,
                  loading: _sending,
                  colors: const [Color(0xFF13C2C2), Color(0xFF006D75)],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor : kPrimaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : kPrimaryColor,
          ),
        ),
      ),
    );
  }
}
