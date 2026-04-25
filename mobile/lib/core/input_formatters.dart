import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldVal, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal;

    // Remove non-digits
    String digits = newVal.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final num val = int.parse(digits);
    final String formatted = _fmt.format(val);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
