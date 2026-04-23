import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'fintrack_reminders';
  static const _channelName = 'Reminders';

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final deviceTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTz));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    // Request POST_NOTIFICATIONS permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // Stable int ID derived from reminder string ID
  static int _notifId(String reminderId) => reminderId.hashCode.abs();

  /// Schedule an OS notification at [when]. No-ops if [when] is in the past.
  static Future<void> schedule({
    required String id,
    required String title,
    String? body,
    required DateTime when,
  }) async {
    if (!_initialized || when.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _notifId(id),
      '⏰ $title',
      body?.isNotEmpty == true ? body : 'Tap to view your reminder',
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'FinTrack reminder alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a previously scheduled notification.
  static Future<void> cancel(String id) => _plugin.cancel(_notifId(id));

  /// Re-schedule all active reminders (call this after login / app restart).
  static Future<void> rescheduleAll(List<Map<String, dynamic>> reminders) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final r in reminders) {
      if (r['isCompleted'] == true) continue;
      final when = DateTime.tryParse(r['reminderDate'] ?? '');
      if (when == null || when.isBefore(now)) continue;
      await schedule(
        id: r['id'] as String,
        title: r['title'] as String,
        body: r['note'] as String?,
        when: when,
      );
    }
  }
}
