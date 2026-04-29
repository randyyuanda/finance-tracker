class Transaction {
  final String id;
  final String accountId;
  final String categoryId;
  final double amount;
  final String type;
  final DateTime date;
  final String? note;
  final String? toAccountId;
  final String? categoryName;
  final String? categoryColor;
  final String? accountName;
  final String? accountCurrency;
  final String? toAccountName;
  final String? toAccountCurrency;

  Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.toAccountId,
    this.categoryName,
    this.categoryColor,
    this.accountName,
    this.accountCurrency,
    this.toAccountName,
    this.toAccountCurrency,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) {
    // Backend's fmtTransaction embeds the account/category OBJECT inside
    // the accountId/categoryId fields instead of a plain string ID.
    final acct = j['accountId'] is Map ? j['accountId'] as Map<String, dynamic> : null;
    final cat  = j['categoryId'] is Map ? j['categoryId'] as Map<String, dynamic> : null;
    final toAcct = j['toAccountId'] is Map ? j['toAccountId'] as Map<String, dynamic> : null;

    return Transaction(
      id: j['id'] ?? '',
      accountId: acct?['id'] ?? (j['accountId'] is String ? j['accountId'] as String : ''),
      categoryId: cat?['id'] ?? (j['categoryId'] is String ? j['categoryId'] as String : ''),
      toAccountId: toAcct?['id'] ?? (j['toAccountId'] is String ? j['toAccountId'] as String : null),
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      type: j['type'] ?? 'expense',
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      note: j['note'],
      categoryName: cat?['name'] ?? j['category']?['name'],
      categoryColor: cat?['color'] ?? j['category']?['color'],
      accountName: acct?['name'] ?? j['account']?['name'],
      accountCurrency: acct?['currency'] ?? j['account']?['currency'],
      toAccountName: toAcct?['name'] ?? j['toAccount']?['name'],
      toAccountCurrency: toAcct?['currency'] ?? j['toAccount']?['currency'],
    );
  }
}
