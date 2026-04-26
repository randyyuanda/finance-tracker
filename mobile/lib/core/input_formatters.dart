import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldVal, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal;

    // Remove non-digits but keep negative sign
    bool isNegative = newVal.text.startsWith('-');
    String digits = newVal.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return isNegative ? const TextEditingValue(text: '-', selection: TextSelection.collapsed(offset: 1)) : const TextEditingValue(text: '');

    final num val = int.parse(digits);
    final String formatted = (isNegative ? '-' : '') + _fmt.format(val);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
