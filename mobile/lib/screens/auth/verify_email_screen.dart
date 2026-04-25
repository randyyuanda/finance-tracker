import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../core/theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(_otpCtrl.text.trim());
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Verification failed'), backgroundColor: kExpenseColor),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Verification code resent' : (auth.error ?? 'Failed to resend code')),
          backgroundColor: ok ? kIncomeColor : kExpenseColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Scaffold();

    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1677FF), Color(0xFF003BB8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 54),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Verify Email',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 180 - MediaQuery.of(context).padding.top,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Check your inbox', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text('We\'ve sent a 6-digit verification code to:', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                        const SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 24, letterSpacing: 8),
                            ),
                            validator: (v) => (v == null || v.length != 6) ? 'Enter 6 digits' : null,
                          ),
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          onTap: auth.loading ? null : _submit,
                          label: 'Verify Now',
                          loading: auth.loading,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: auth.loading ? null : _resend,
                            child: const Text('Didn\'t receive code? Resend', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
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
