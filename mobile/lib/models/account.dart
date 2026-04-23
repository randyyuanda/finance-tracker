class Account {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final String color;
  final String icon;
  final bool isActive;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.color,
    required this.icon,
    required this.isActive,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'cash',
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] ?? 'IDR',
        color: j['color'] ?? '#1890ff',
        icon: j['icon'] ?? 'wallet',
        isActive: j['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'balance': balance,
        'currency': currency,
        'color': color,
        'icon': icon,
      };
}
