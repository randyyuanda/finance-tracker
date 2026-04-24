import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/notifications.dart';
import '../models/reminder.dart';

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];
  bool _loading = false;
  String? _error;

  List<Reminder> get reminders => _reminders;
  bool get loading => _loading;
  String? get error => _error;
  int get overdueCount => _reminders.where((r) => r.isOverdue).length;

  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/reminders');
      _reminders = (res.data as List).map((j) => Reminder.fromJson(j)).toList();
      _error = null;
      // Reschedule all upcoming reminders every time we sync from server
      await NotificationService.rescheduleAll(
        (res.data as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      _error = parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.dio.post('/reminders', data: data);
      final reminder = Reminder.fromJson(res.data);
      _reminders.insert(0, reminder);
      // Schedule OS notification
      await NotificationService.schedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.note,
        when: reminder.reminderDate,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.dio.patch('/reminders/$id', data: data);
      final updated = Reminder.fromJson(res.data);
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx != -1) _reminders[idx] = updated;
      // Cancel old, reschedule with new date
      await NotificationService.cancel(id);
      if (!updated.isCompleted) {
        await NotificationService.schedule(
          id: updated.id,
          title: updated.title,
          body: updated.note,
          when: updated.reminderDate,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleComplete(String id) async {
    try {
      final res = await ApiClient.dio.patch('/reminders/$id/complete');
      final updated = Reminder.fromJson(res.data);
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx != -1) _reminders[idx] = updated;
      // Cancel notification when marked done; reschedule when unchecked
      if (updated.isCompleted) {
        await NotificationService.cancel(id);
      } else {
        await NotificationService.schedule(
          id: updated.id,
          title: updated.title,
          body: updated.note,
          when: updated.reminderDate,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAdminNotifications() async {
    try {
      final res = await ApiClient.dio.get('/notifications/admin');
      final raw = res.data;
      if (raw is! List) return;
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'] as String? ?? '';
        final title = item['title'] as String? ?? '';
        final body = item['note'] as String?;
        final scheduledStr = item['scheduledAt'] as String?;
        final repeatType = item['repeatType'] as String? ?? 'none';
        if (id.isEmpty || title.isEmpty || scheduledStr == null) continue;
        final scheduledAt = DateTime.tryParse(scheduledStr);
        if (scheduledAt == null) continue;
        await NotificationService.scheduleAdmin(
          id: id,
          title: title,
          body: body,
          scheduledAt: scheduledAt,
          repeatType: repeatType,
        );
      }
    } catch (e) {
      // Silently fail — notification delivery is best-effort
      assert(() { print('[BuxBux] checkAdminNotifications error: $e'); return true; }());
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ApiClient.dio.delete('/reminders/$id');
      _reminders.removeWhere((r) => r.id == id);
      await NotificationService.cancel(id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }
}
