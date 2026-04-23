class Reminder {
  final String id;
  final String title;
  final String? note;
  final DateTime reminderDate;
  final String type;
  final String repeatType;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.reminderDate,
    required this.type,
    required this.repeatType,
    required this.isCompleted,
  });

  bool get isOverdue => !isCompleted && reminderDate.isBefore(DateTime.now());

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        note: j['note'],
        reminderDate: DateTime.tryParse(j['reminderDate'] ?? '') ?? DateTime.now(),
        type: j['type'] ?? 'custom',
        repeatType: j['repeatType'] ?? 'none',
        isCompleted: j['isCompleted'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'note': note,
        'reminderDate': reminderDate.toIso8601String(),
        'type': type,
        'repeatType': repeatType,
        'isCompleted': isCompleted,
      };
}
