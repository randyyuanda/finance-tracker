class RecurringTransaction {
  final String id;
  final String accountId;
  final String categoryId;
  final String type;
  final double amount;
  final String? note;
  final String frequency;
  final DateTime nextDue;
  final bool isActive;
  final String? categoryName;
  final String? categoryColor;
  final String? accountName;

  RecurringTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.frequency,
    required this.nextDue,
    required this.isActive,
    this.categoryName,
    this.categoryColor,
    this.accountName,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> j) => RecurringTransaction(
        id: j['id'] ?? '',
        accountId: j['accountId'] ?? '',
        categoryId: j['categoryId'] ?? '',
        type: j['type'] ?? 'expense',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        note: j['note'],
        frequency: j['frequency'] ?? 'monthly',
        nextDue: DateTime.tryParse(j['nextDue'] ?? '') ?? DateTime.now(),
        isActive: j['isActive'] ?? true,
        categoryName: j['category']?['name'],
        categoryColor: j['category']?['color'],
        accountName: j['account']?['name'],
      );
}
