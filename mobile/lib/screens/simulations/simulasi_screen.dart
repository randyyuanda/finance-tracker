import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';

class KprScreen extends StatelessWidget {
  const KprScreen({super.key});
  @override
  Widget build(BuildContext context) => _LoanSimulator(
        title: 'Simulasi KPR',
        subtitle: 'Kredit Pemilikan Rumah',
        icon: Icons.home_outlined,
        color: kPrimaryColor,
        defaultPrice: 500000000,
        defaultDpPct: 20,
        defaultTenorYears: 15,
        defaultRatePct: 9.0,
        maxTenorYears: 30,
      );
}

class KreditMotorScreen extends StatelessWidget {
  const KreditMotorScreen({super.key});
  @override
  Widget build(BuildContext context) => _LoanSimulator(
        title: 'Simulasi Kredit Motor',
        subtitle: 'Kredit Sepeda Motor',
        icon: Icons.two_wheeler_outlined,
        color: const Color(0xFF52C41A),
        defaultPrice: 25000000,
        defaultDpPct: 20,
        defaultTenorYears: 3,
        defaultRatePct: 12.0,
        maxTenorYears: 5,
      );
}

class KreditMobilScreen extends StatelessWidget {
  const KreditMobilScreen({super.key});
  @override
  Widget build(BuildContext context) => _LoanSimulator(
        title: 'Simulasi Kredit Mobil',
        subtitle: 'Kredit Kendaraan Bermotor',
        icon: Icons.directions_car_outlined,
        color: const Color(0xFFFFA940),
        defaultPrice: 200000000,
        defaultDpPct: 20,
        defaultTenorYears: 5,
        defaultRatePct: 10.0,
        maxTenorYears: 7,
      );
}

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
  late final TextEditingController _dpCtrl;
  late final TextEditingController _rateCtrl;
  late int _tenorYears;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.defaultPrice.toStringAsFixed(0));
    _dpCtrl = TextEditingController(text: widget.defaultDpPct.toStringAsFixed(0));
    _rateCtrl = TextEditingController(text: widget.defaultRatePct.toStringAsFixed(1));
    _tenorYears = widget.defaultTenorYears;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _dpCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  _CalcResult _calculate() {
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;
    final dpPct = double.tryParse(_dpCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;

    final dp = price * dpPct / 100;
    final principal = price - dp;
    final months = _tenorYears * 12;
    final monthlyRate = rate / 12 / 100;

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
    final result = _calculate();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(widget.subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Input fields ──────────────────────────────────────────
          _SectionTitle('Parameter Pinjaman'),
          const SizedBox(height: 10),
          _InputCard(
            children: [
              _InputField(
                controller: _priceCtrl,
                label: 'Harga / Nilai Barang (Rp)',
                hint: 'Contoh: 500000000',
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 1),
              _InputField(
                controller: _dpCtrl,
                label: 'Uang Muka / DP (%)',
                hint: 'Contoh: 20',
                suffix: '%',
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 1),
              _InputField(
                controller: _rateCtrl,
                label: 'Suku Bunga Tahunan (%)',
                hint: 'Contoh: 9.0',
                suffix: '% / tahun',
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tenor: $_tenorYears tahun',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Slider(
                      value: _tenorYears.toDouble(),
                      min: 1,
                      max: widget.maxTenorYears.toDouble(),
                      divisions: widget.maxTenorYears - 1,
                      activeColor: widget.color,
                      label: '$_tenorYears thn',
                      onChanged: (v) => setState(() => _tenorYears = v.round()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 thn', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text('${widget.maxTenorYears} thn',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Result card ────────────────────────────────────────────
          _SectionTitle('Hasil Simulasi'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text('Cicilan Per Bulan',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(result.monthly),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: widget.color),
                ),
                const SizedBox(height: 4),
                Text('selama $_tenorYears tahun (${_tenorYears * 12} bulan)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InputCard(
            children: [
              _ResultRow(
                label: 'Uang Muka (DP)',
                value: formatCurrency(result.dp),
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const Divider(height: 1),
              _ResultRow(
                label: 'Pokok Pinjaman',
                value: formatCurrency(result.principal),
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const Divider(height: 1),
              _ResultRow(
                label: 'Total Pembayaran',
                value: formatCurrency(result.total),
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const Divider(height: 1),
              _ResultRow(
                label: 'Total Bunga',
                value: formatCurrency(result.totalInterest),
                color: kExpenseColor,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '* Simulasi ini bersifat estimasi. Suku bunga aktual dapat berbeda tergantung kebijakan lembaga keuangan.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CalcResult {
  final double dp;
  final double principal;
  final double monthly;
  final double total;
  final double totalInterest;
  const _CalcResult(
      {required this.dp,
      required this.principal,
      required this.monthly,
      required this.total,
      required this.totalInterest});
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
      );
}

class _InputCard extends StatelessWidget {
  final List<Widget> children;
  const _InputCard({required this.children});
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Column(children: children),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixText: suffix,
            border: InputBorder.none,
            labelStyle: const TextStyle(fontSize: 13),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _ResultRow(
      {required this.label,
      required this.value,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: color)),
          ],
        ),
      );
}
