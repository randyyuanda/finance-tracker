import 'package:intl/intl.dart';

final _idrFmt = NumberFormat('#,##0', 'id_ID');
final _defaultFmt = NumberFormat('#,##0', 'en_US');
final _dateFmt = DateFormat('MMM d, yyyy');
final _dateTimeFmt = DateFormat('MMM d, yyyy HH:mm');
final _monthFmt = DateFormat('MMM yyyy');

String formatCurrency(num amount, {String? currency}) {
  final code = currency ?? 'IDR';
  // IDR: id_ID locale (1.000.000), others: en_US locale (1,000,000)
  final fmt = code == 'IDR' ? _idrFmt : _defaultFmt;
  return '$code ${fmt.format(amount)}';
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
