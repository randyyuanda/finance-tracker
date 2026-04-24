import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/formatters.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';

class KprScreen extends StatelessWidget {
  const KprScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return _LoanSimulator(
      title: s.simKprTitle,
      subtitle: s.simKprSub,
      icon: Icons.home_outlined,
      color: kPrimaryColor,
      defaultPrice: 500000000,
      defaultDpPct: 20,
      defaultTenorYears: 15,
      defaultRatePct: 9.0,
      maxTenorYears: 30,
    );
  }
}

class KreditMotorScreen extends StatelessWidget {
  const KreditMotorScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return _LoanSimulator(
      title: s.simMotorTitle,
      subtitle: s.simMotorSub,
      icon: Icons.two_wheeler_outlined,
      color: const Color(0xFF52C41A),
      defaultPrice: 25000000,
      defaultDpPct: 20,
      defaultTenorYears: 3,
      defaultRatePct: 12.0,
      maxTenorYears: 5,
    );
  }
}

class KreditMobilScreen extends StatelessWidget {
  const KreditMobilScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return _LoanSimulator(
      title: s.simMobilTitle,
      subtitle: s.simMobilSub,
      icon: Icons.directions_car_outlined,
      color: const Color(0xFFFFA940),
      defaultPrice: 200000000,
      defaultDpPct: 20,
      defaultTenorYears: 5,
      defaultRatePct: 10.0,
      maxTenorYears: 7,
    );
  }
}

// ─── Shared loan simulator ────────────────────────────────────────────────────

class _LoanSimulator extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double defaultPrice;
  final double defaultDpPct;
  final int defaultTenorYears;
  final double defaultRatePct;
  final int maxTenorYears;

  const _LoanSimulator({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.defaultPrice,
    required this.defaultDpPct,
    required this.defaultTenorYears,
    required this.defaultRatePct,
    required this.maxTenorYears,
  });

  @override
  State<_LoanSimulator> createState() => _LoanSimulatorState();
}

class _LoanSimulatorState extends State<_LoanSimulator> {
  late final TextEditingController _priceCtrl;
  double _dpPct = 20;
  double _ratePct = 9.0;
  late int _tenorYears;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
        text: _formatDots(widget.defaultPrice.toStringAsFixed(0)));
    _dpPct = widget.defaultDpPct;
    _ratePct = widget.defaultRatePct;
    _tenorYears = widget.defaultTenorYears;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  /// Format number string with dot thousands separators: "500000000" → "500.000.000"
  static String _formatDots(String digits) {
    final clean = digits.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return '';
    final result = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) result.write('.');
      result.write(clean[i]);
    }
    return result.toString();
  }

  static double _parseDots(String s) =>
      double.tryParse(s.replaceAll('.', '')) ?? 0;

  _CalcResult _calculate() {
    final price = _parseDots(_priceCtrl.text);
    final dp = price * _dpPct / 100;
    final principal = price - dp;
    final months = _tenorYears * 12;
    final monthlyRate = _ratePct / 12 / 100;

    double monthly = 0;
    if (monthlyRate > 0 && months > 0 && principal > 0) {
      final factor = pow(1 + monthlyRate, months);
      monthly = principal * (monthlyRate * factor) / (factor - 1);
    } else if (months > 0 && principal > 0) {
      monthly = principal / months;
    }

    return _CalcResult(
      dp: dp,
      principal: principal,
      monthly: monthly,
      total: monthly * months,
      totalInterest: (monthly * months) - principal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final result = _calculate();
    final price = _parseDots(_priceCtrl.text);
    final dpAmount = price * _dpPct / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Hero header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withValues(alpha: 0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(widget.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(widget.subtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Section label ─────────────────────────────────────────
          _SectionLabel(s.simLoanParam),
          const SizedBox(height: 10),

          // ── Price input card ──────────────────────────────────────
          _ParamCard(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                    icon: Icons.sell_outlined, label: s.simPrice, color: widget.color),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Rp',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                              fontSize: 15)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_DotsFormatter()],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                          isDense: true,
                          suffixIcon: _priceCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _priceCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── DP slider card ────────────────────────────────────────
          _ParamCard(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                    icon: Icons.savings_outlined,
                    label: s.simDpPct,
                    color: widget.color),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_dpPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: widget.color),
                    ),
                    if (price > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(s.simDpAmount,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                          Text(
                            formatCurrency(dpAmount),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.color),
                          ),
                        ],
                      ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.color,
                    thumbColor: widget.color,
                    inactiveTrackColor: widget.color.withValues(alpha: 0.2),
                    overlayColor: widget.color.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _dpPct,
                    min: 0,
                    max: 80,
                    divisions: 80,
                    label: '${_dpPct.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() => _dpPct = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text('80%',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Interest rate card ────────────────────────────────────
          _ParamCard(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                    icon: Icons.percent,
                    label: s.simRate,
                    color: widget.color),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_ratePct.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: widget.color),
                    ),
                    Text('/ ${s.simYears}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.color,
                    thumbColor: widget.color,
                    inactiveTrackColor: widget.color.withValues(alpha: 0.2),
                    overlayColor: widget.color.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _ratePct,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    label: '${_ratePct.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(
                        () => _ratePct = (v * 10).round() / 10),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1%',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text('30%',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Tenor card ────────────────────────────────────────────
          _ParamCard(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                    icon: Icons.calendar_month_outlined,
                    label: s.simTenor,
                    color: widget.color),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_tenorYears ${s.simYears}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: widget.color),
                    ),
                    Text(
                      '${_tenorYears * 12} ${s.simMonths}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.color,
                    thumbColor: widget.color,
                    inactiveTrackColor: widget.color.withValues(alpha: 0.2),
                    overlayColor: widget.color.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _tenorYears.toDouble(),
                    min: 1,
                    max: widget.maxTenorYears.toDouble(),
                    divisions: widget.maxTenorYears - 1,
                    label: '$_tenorYears ${s.simYears}',
                    onChanged: (v) =>
                        setState(() => _tenorYears = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 ${s.simYears}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text('${widget.maxTenorYears} ${s.simYears}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Result section ────────────────────────────────────────
          _SectionLabel(s.simResult),
          const SizedBox(height: 10),

          // Monthly highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withValues(alpha: 0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                Text(s.simMonthly,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(result.monthly),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.simFor} $_tenorYears ${s.simYears} (${_tenorYears * 12} ${s.simMonths})',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Detail rows
          _ParamCard(
            color: cardColor,
            child: Column(
              children: [
                _ResultRow(
                    label: s.simDp,
                    value: formatCurrency(result.dp),
                    valueColor: isDark ? Colors.white : Colors.black87),
                _Divider(),
                _ResultRow(
                    label: s.simPrincipal,
                    value: formatCurrency(result.principal),
                    valueColor: isDark ? Colors.white : Colors.black87),
                _Divider(),
                _ResultRow(
                    label: s.simTotal,
                    value: formatCurrency(result.total),
                    valueColor: isDark ? Colors.white : Colors.black87),
                _Divider(),
                _ResultRow(
                    label: s.simInterest,
                    value: formatCurrency(result.totalInterest),
                    valueColor: kExpenseColor,
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.simDisclaimer,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── Thousands-dot formatter ──────────────────────────────────────────────────

class _DotsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
          text: '', selection: const TextSelection.collapsed(offset: 0));
    }
    final formatted = _fmt(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _fmt(String digits) {
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

// ─── Calculation result ───────────────────────────────────────────────────────

class _CalcResult {
  final double dp;
  final double principal;
  final double monthly;
  final double total;
  final double totalInterest;
  const _CalcResult({
    required this.dp,
    required this.principal,
    required this.monthly,
    required this.total,
    required this.totalInterest,
  });
}

// ─── Small UI helpers ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.8),
        ),
      );
}

class _ParamCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _ParamCard({required this.child, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      );
}

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FieldLabel(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
        ],
      );
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  const _ResultRow(
      {required this.label,
      required this.value,
      required this.valueColor,
      this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor)),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100);
}
