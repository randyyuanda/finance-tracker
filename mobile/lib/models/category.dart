class Category {
  final String id;
  final String name;
  final String type;
  final String color;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'expense',
        color: j['color'] ?? '#1890ff',
        icon: j['icon'] ?? 'tag',
      );
}
