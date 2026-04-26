import 'package:dio/dio.dart';

class CurrencyService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const _supportedCurrencies = ['idr', 'usd', 'eur', 'sgd', 'jpy', 'gbp', 'aud', 'myr'];

  static const _baseUrl =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';

  /// Fetch all rates relative to [baseCurrency] (e.g. 'usd').
  static Future<Map<String, double>> getRates(String baseCurrency) async {
    final base = baseCurrency.toLowerCase();
    try {
      final res = await _dio.get('$_baseUrl/$base.min.json');
      final data = res.data as Map<String, dynamic>;
      final rates = data[base] as Map<String, dynamic>;
      final result = <String, double>{};
      for (final cur in _supportedCurrencies) {
        if (rates[cur] != null) {
          result[cur.toUpperCase()] = (rates[cur] as num).toDouble();
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Fetch exchange rates between all account currencies.
  /// Returns a map of currency pairs and their rates, e.g. {"USD_IDR": 16000}.
  static Future<Map<String, Map<String, double>>> getRatesForCurrencies(
      List<String> currencies) async {
    final unique = currencies.map((c) => c.toLowerCase()).toSet().toList();
    final result = <String, Map<String, double>>{};
    for (final base in unique) {
      result[base.toUpperCase()] = await getRates(base);
    }
    return result;
  }
}
