import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'fintrack_reminders';
  static const _channelName = 'Reminders';
  static const _adminChannelId = 'fintrack_admin';
  static const _adminChannelName = 'Announcements';

  static const _adminDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _adminChannelId,
      _adminChannelName,
      channelDescription: 'Announcements from BuxBux',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    ),
  );

  static Future<void> initialize({bool fromBackground = false}) async {
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

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Request POST_NOTIFICATIONS permission (Android 13+) - SKIP IN BACKGROUND
    if (!fromBackground) {
      await androidImpl?.requestNotificationsPermission();
    }

    // Create channels immediately so FCM can show notifications even when the
    // app is killed — Android needs the channel to exist before FCM fires.
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'fintrack_reminders',
      'Reminders',
      description: 'BuxBux reminder alerts',
      importance: Importance.high,
    ));
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'fintrack_admin',
      'Announcements',
      description: 'Announcements from BuxBux',
      importance: Importance.max,
    ));

    _initialized = true;
  }

  static int _notifId(String id) => id.hashCode.abs();
  static int _adminNotifId(String id) => ('admin_$id').hashCode.abs();

  /// Show a notification immediately (used for FCM foreground messages).
  static Future<void> showImmediate({
    required String id,
    required String title,
    String? body,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _adminNotifId(id),
      title,
      body?.isNotEmpty == true ? body : 'Message from BuxBux',
      _adminDetails,
    );
  }

  /// Schedule a user reminder at [when]. No-ops if [when] is in the past.
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

  static DateTimeComponents? _repeatComponents(String repeatType) {
    switch (repeatType) {
      case 'daily':   return DateTimeComponents.time;
      case 'weekly':  return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly': return DateTimeComponents.dayOfMonthAndTime;
      default:        return null;
    }
  }

  /// Deliver an admin broadcast.
  /// - Past / current: show immediately via _plugin.show() (no AlarmManager, no permissions).
  /// - Future one-time: schedule with alarmClock mode (exact, no SCHEDULE_EXACT_ALARM needed).
  /// - Repeating: schedule with exactAllowWhileIdle (requires SCHEDULE_EXACT_ALARM permission).
  static Future<void> scheduleAdmin({
    required String id,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String repeatType = 'none',
  }) async {
    if (!_initialized) return;

    final bodyText = (body != null && body.isNotEmpty) ? body : 'Message from BuxBux';
    final now = DateTime.now();

    if (repeatType == 'none') {
      if (!scheduledAt.isAfter(now)) {
        // Already due — show immediately, bypass AlarmManager entirely
        await _plugin.show(
          _adminNotifId(id),
          '📢 $title',
          bodyText,
          _adminDetails,
        );
      } else {
        // Future one-time — alarmClock fires at exact time, no special permission needed
        await _plugin.zonedSchedule(
          _adminNotifId(id),
          '📢 $title',
          bodyText,
          tz.TZDateTime.from(scheduledAt, tz.local),
          _adminDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } else {
      // Repeating — requires SCHEDULE_EXACT_ALARM (user granted via system settings)
      final tzWhen = tz.TZDateTime.from(scheduledAt, tz.local);
      await _plugin.zonedSchedule(
        _adminNotifId(id),
        '📢 $title',
        bodyText,
        tzWhen,
        _adminDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _repeatComponents(repeatType),
      );
    }
  }

  /// Cancel a previously scheduled user reminder.
  static Future<void> cancel(String id) => _plugin.cancel(_notifId(id));

  /// Re-schedule all active user reminders (call after login / app restart).
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
