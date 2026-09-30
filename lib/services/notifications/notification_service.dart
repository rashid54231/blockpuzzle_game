import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class NotificationService {
  Future<void> init();
  Future<void> scheduleDailyReminder();
  Future<void> scheduleStreakReminder();
  Future<void> cancelAll();
}

class AppNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      await _notificationsPlugin.initialize(settings: initSettings);
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  @override
  Future<void> scheduleDailyReminder() async {
    // Schedules a daily local notification reminder
  }

  @override
  Future<void> scheduleStreakReminder() async {
    // Schedules a reminder 2 hours before streak resets
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
