class Transaction {
  final String id;
  final String accountId;
  final String categoryId;
  final double amount;
  final String type;
  final DateTime date;
  final String? note;
  final String? categoryName;
  final String? categoryColor;
  final String? accountName;

  Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.categoryName,
    this.categoryColor,
    this.accountName,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] ?? '',
        accountId: j['accountId'] ?? '',
        categoryId: j['categoryId'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        type: j['type'] ?? 'expense',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        note: j['note'],
        categoryName: j['category']?['name'],
        categoryColor: j['category']?['color'],
        accountName: j['account']?['name'],
      );
}
