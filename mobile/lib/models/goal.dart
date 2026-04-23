class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String color;
  final bool isCompleted;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.color,
    required this.isCompleted,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        targetAmount: (j['targetAmount'] as num?)?.toDouble() ?? 0,
        currentAmount: (j['currentAmount'] as num?)?.toDouble() ?? 0,
        deadline: j['deadline'] != null ? DateTime.tryParse(j['deadline']) : null,
        color: j['color'] ?? '#1890ff',
        isCompleted: j['isCompleted'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline?.toIso8601String(),
        'color': color,
        'isCompleted': isCompleted,
      };
}
