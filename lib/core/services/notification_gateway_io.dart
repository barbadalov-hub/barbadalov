import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Native backend for OS-level notifications.
///
/// Real system notifications fire on the platforms the plugin actually
/// supports — Android, iOS, macOS and Linux. On Windows (no plugin backend) it
/// stays a no-op, so the plugin-free desktop build keeps working and the
/// in-app unread badge is the "something arrived" signal instead.
class NotificationGateway {
  static const _channelId = 'lifeos_default';
  static const _channelName = 'LifeOS';
  static const _channelDescription =
      'Finance alerts, budget warnings, habits and AI insights.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// True on platforms where the plugin has a real implementation.
  bool get _supported =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isLinux;

  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const linux =
          LinuxInitializationSettings(defaultActionName: 'Open LifeOS');
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      );
      await _plugin.initialize(settings);

      // Timezone database, so daily reminders land at the right wall-clock time.
      tzdata.initializeTimeZones();
      tz.setLocalLocation(_deviceLocation());

      // Android 13+ and iOS both gate notifications behind a runtime grant.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (_) {
      // Never let notification setup crash app start-up.
      _ready = false;
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.show(id, title, body, _details);
    } catch (_) {
      // A failed notification must never surface as an app error.
    }
  }

  /// Repeating reminder at [hour]:[minute] every day, delivered by the OS even
  /// while the app is closed. Inexact scheduling avoids the exact-alarm
  /// permission and is battery-friendly (a few minutes' drift is fine here).
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_supported) return;
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Scheduling failures must stay silent.
    }
  }

  Future<void> cancel(int id) async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  /// Picks a fixed-offset `Etc/GMT` zone matching the device's current UTC
  /// offset — plugin-free (no native timezone lookup). DST shifts are corrected
  /// the next time the app runs, which is when reminders are rescheduled.
  tz.Location _deviceLocation() {
    final minutes = DateTime.now().timeZoneOffset.inMinutes;
    if (minutes != 0 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      // Etc/GMT zones invert the sign: UTC+3 is "Etc/GMT-3".
      final name = 'Etc/GMT${hours >= 0 ? '-' : '+'}${hours.abs()}';
      try {
        return tz.getLocation(name);
      } catch (_) {}
    }
    return tz.UTC;
  }
}

/// Single shared instance, mirrored by the no-op backend.
final NotificationGateway notificationGateway = NotificationGateway();
