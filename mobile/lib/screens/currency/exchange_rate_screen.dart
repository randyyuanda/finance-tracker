import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../services/currency_service.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  static const _allCurrencies = ['IDR', 'USD', 'EUR', 'SGD', 'JPY', 'GBP', 'AUD', 'MYR'];

  String _baseCurrency = 'USD';
  Map<String, double> _rates = {};
  bool _loading = false;
  String? _lastUpdated;
  final _amountCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Default base to first account currency
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) {
        _baseCurrency = accounts.first.currency;
      }
      _fetchRates();
    });
  }

  Future<void> _fetchRates() async {
    setState(() => _loading = true);
    final rates = await CurrencyService.getRates(_baseCurrency);
    if (mounted) {
      setState(() {
        _rates = rates;
        _loading = false;
        _lastUpdated = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final accountCurrencies = accounts.map((a) => a.currency).toSet().toList();
    final theme = Theme.of(context);
    final inputAmount = double.tryParse(_amountCtrl.text) ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Rates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchRates,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Base currency selector + amount input ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Convert from', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _baseCurrency,
                        dropdownColor: theme.cardTheme.color,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        items: _allCurrencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(children: [
                                    Text(_currencyFlag(c), style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ]),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _baseCurrency = v);
                            _fetchRates();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (_lastUpdated != null) ...[
                  const SizedBox(height: 8),
                  Text('Updated: $_lastUpdated', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_rates.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('Could not load rates', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _fetchRates, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Your account currencies (highlighted) ──
                  if (accountCurrencies.isNotEmpty) ...[
                    _sectionLabel('Your Account Currencies'),
                    ...accountCurrencies
                        .where((c) => c != _baseCurrency && _rates[c] != null)
                        .map((c) => _RateCard(
                              currency: c,
                              rate: _rates[c]! * inputAmount,
                              baseAmount: inputAmount,
                              baseCurrency: _baseCurrency,
                              highlight: true,
                            )),
                    const SizedBox(height: 8),
                    _sectionLabel('All Rates'),
                  ],
                  ..._rates.entries
                      .where((e) => e.key != _baseCurrency)
                      .map((e) => _RateCard(
                            currency: e.key,
                            rate: e.value * inputAmount,
                            baseAmount: inputAmount,
                            baseCurrency: _baseCurrency,
                            highlight: false,
                          )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
      );

  String _currencyFlag(String currency) {
    const flags = {
      'IDR': '🇮🇩', 'USD': '🇺🇸', 'EUR': '🇪🇺', 'SGD': '🇸🇬',
      'JPY': '🇯🇵', 'GBP': '🇬🇧', 'AUD': '🇦🇺', 'MYR': '🇲🇾',
    };
    return flags[currency] ?? '💱';
  }
}

class _RateCard extends StatelessWidget {
  final String currency;
  final double rate;
  final double baseAmount;
  final String baseCurrency;
  final bool highlight;

  const _RateCard({
    required this.currency,
    required this.rate,
    required this.baseAmount,
    required this.baseCurrency,
    required this.highlight,
  });

  String _flag(String c) {
    const flags = {
      'IDR': '🇮🇩', 'USD': '🇺🇸', 'EUR': '🇪🇺', 'SGD': '🇸🇬',
      'JPY': '🇯🇵', 'GBP': '🇬🇧', 'AUD': '🇦🇺', 'MYR': '🇲🇾',
    };
    return flags[c] ?? '💱';
  }

  String _formatRate(double r) {
    if (r >= 1000) return NumberFormat('#,##0.00').format(r);
    if (r >= 1) return r.toStringAsFixed(4);
    return r.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? kPrimaryColor.withValues(alpha: 0.07) : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: kPrimaryColor.withValues(alpha: 0.25)) : null,
      ),
      child: Row(
        children: [
          Text(_flag(currency), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currency, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: highlight ? kPrimaryColor : null)),
                Text('1 $baseCurrency = ${_formatRate(rate / baseAmount)} $currency',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            _formatRate(rate),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: highlight ? kPrimaryColor : null),
          ),
        ],
      ),
    );
  }
}
