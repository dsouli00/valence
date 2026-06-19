import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// On-device daily reminders. No Firebase / FCM / Blaze — purely local, so it
/// works on the free Spark plan. Scheduling preferences live in
/// `shared_preferences` (device-local, which matches how local notifications
/// behave). Coach at-risk PUSH is a separate, deferred FCM feature.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _tzReady = false;

  static const String _kEnabled = 'reminders_enabled';
  static const String _kHour = 'reminder_hour';
  static const String _kMinute = 'reminder_minute';

  static const int _reminderId = 1001;
  static const int defaultHour = 20;
  static const int defaultMinute = 0;

  Future<void> init() async {
    if (_initialized) return;
    await _ensureTimeZone();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      // We request explicitly when the user enables reminders.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  Future<void> _ensureTimeZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to UTC; reminders still fire, just on UTC wall-clock.
    }
    _tzReady = true;
  }

  /// Asks the OS for permission to post notifications. Returns whether granted.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? true;
    }
    return false;
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  Future<({int hour, int minute})> reminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_kHour) ?? defaultHour,
      minute: prefs.getInt(_kMinute) ?? defaultMinute,
    );
  }

  /// Schedules (or reschedules) the daily reminder and persists the prefs.
  Future<void> enableDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setInt(_kHour, hour);
    await prefs.setInt(_kMinute, minute);
    await _schedule(hour: hour, minute: minute, title: title, body: body);
  }

  Future<void> disableDailyReminder() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, false);
    await _plugin.cancel(_reminderId);
  }

  Future<void> _schedule({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      _reminderId,
      title,
      body,
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminders',
          channelDescription: 'Reminders to log your day in Valence',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeat every day at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
