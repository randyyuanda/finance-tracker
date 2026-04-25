import 'package:intl/intl.dart';

final _currencyFmt = NumberFormat('#,##0', 'id_ID');
final _dateFmt = DateFormat('MMM d, yyyy');
final _dateTimeFmt = DateFormat('MMM d, yyyy HH:mm');
final _monthFmt = DateFormat('MMM yyyy');

String formatCurrency(num amount, {String? currency}) {
  final code = currency ?? 'IDR';
  return '$code ${_currencyFmt.format(amount)}';
}

String formatDate(DateTime date) => _dateFmt.format(date);

String formatDateTime(DateTime date) => _dateTimeFmt.format(date);

String formatMonth(DateTime date) => _monthFmt.format(date);

String formatRelative(DateTime date) {
  final now = DateTime.now();
  final diff = date.difference(now);
  final absDays = diff.inDays.abs();

  if (diff.inDays == 0) {
    if (diff.inHours == 0) return 'just now';
    return diff.isNegative ? '${diff.inHours.abs()}h ago' : 'in ${diff.inHours}h';
  }
  if (absDays == 1) return diff.isNegative ? 'yesterday' : 'tomorrow';
  if (absDays < 7) return diff.isNegative ? '${absDays}d ago' : 'in ${absDays}d';
  return formatDate(date);
}
