class QuickAddConfig {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String? accountId;
  final String? accountName;
  final String? currency; // from the selected account; used in widget label
  final String? categoryId;
  final String? categoryName;
  final String? note;
  final String? label;

  QuickAddConfig({
    required this.id,
    required this.type,
    required this.amount,
    this.accountId,
    this.accountName,
    this.currency,
    this.categoryId,
    this.categoryName,
    this.note,
    this.label,
  });

  factory QuickAddConfig.fromJson(Map<String, dynamic> j) => QuickAddConfig(
        id: j['id'] ?? '',
        type: j['type'] ?? 'expense',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        accountId: j['accountId'],
        accountName: j['accountName'],
        currency: j['currency'],
        categoryId: j['categoryId'],
        categoryName: j['categoryName'],
        note: j['note'],
        label: j['label'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'accountId': accountId,
        'accountName': accountName,
        'currency': currency,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'note': note,
        'label': label,
      };

  static List<QuickAddConfig> get defaults => [
        QuickAddConfig(id: 'q1', type: 'expense', amount: 10000, label: '-10k'),
        QuickAddConfig(id: 'q2', type: 'expense', amount: 50000, label: '-50k'),
        QuickAddConfig(id: 'q3', type: 'income', amount: 10000, label: '+10k'),
        QuickAddConfig(id: 'q4', type: 'income', amount: 50000, label: '+50k'),
      ];
}
