import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  // Tracks admin notification IDs already fired this session to prevent re-firing on every poll.
  static final _firedAdminIds = <String>{};

  static const _channelId = 'fintrack_reminders';
  static const _channelName = 'Reminders';
  static const _adminChannelId = 'fintrack_admin';
  static const _adminChannelName = 'Announcements';

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      const tzChannel = MethodChannel('com.fintrack/timezone');
      final String deviceTz = await tzChannel.invokeMethod('getLocalTimezone');
      tz.setLocalLocation(tz.getLocation(deviceTz));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Request POST_NOTIFICATIONS permission (Android 13+)
    await androidImpl?.requestNotificationsPermission();
    // Request exact alarm permission for repeating notifications (Android 12+)
    await androidImpl?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // Stable int ID derived from reminder string ID
  static int _notifId(String reminderId) => reminderId.hashCode.abs();

  /// Schedule an OS notification at [when]. No-ops if [when] is in the past.
  /// Uses alarmClock mode — fires at exact time with no special permission needed.
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
          channelDescription: 'BuxBux reminder alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static int _adminNotifId(String id) => ('admin_$id').hashCode.abs();

  static DateTimeComponents? _repeatComponents(String repeatType) {
    switch (repeatType) {
      case 'daily':   return DateTimeComponents.time;
      case 'weekly':  return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly': return DateTimeComponents.dayOfMonthAndTime;
      default:        return null;
    }
  }

  /// Schedule an admin broadcast notification.
  /// One-time: alarmClock mode (exact, no permission needed).
  /// Repeating: exactAllowWhileIdle (requires SCHEDULE_EXACT_ALARM permission).
  static Future<void> scheduleAdmin({
    required String id,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String repeatType = 'none',
  }) async {
    if (!_initialized) return;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime when = tz.TZDateTime.from(scheduledAt, tz.local);

    if (repeatType == 'none') {
      if (when.isBefore(now)) {
        // Skip if already fired this session or older than 24 hours
        if (_firedAdminIds.contains(id)) return;
        if (now.difference(when).inHours >= 24) return;
        when = now.add(const Duration(seconds: 5));
        _firedAdminIds.add(id);
      }
      // alarmClock fires at exact time without SCHEDULE_EXACT_ALARM permission
      await _plugin.zonedSchedule(
        _adminNotifId(id),
        '📢 $title',
        body?.isNotEmpty == true ? body : 'Message from BuxBux',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _adminChannelId,
            _adminChannelName,
            channelDescription: 'Announcements from BuxBux',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // Repeating: exactAllowWhileIdle + requires SCHEDULE_EXACT_ALARM (requested at init)
      await _plugin.zonedSchedule(
        _adminNotifId(id),
        '📢 $title',
        body?.isNotEmpty == true ? body : 'Message from BuxBux',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _adminChannelId,
            _adminChannelName,
            channelDescription: 'Announcements from BuxBux',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _repeatComponents(repeatType),
      );
    }
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
