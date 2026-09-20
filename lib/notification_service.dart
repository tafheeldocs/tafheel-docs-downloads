import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // ============================================================
  // CHECK ANDROID
  // ============================================================

  static bool get isAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    // Chrome/Web and non-Android platforms
    // do not initialize Android notifications.
    if (!isAndroid) {
      return;
    }

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ============================================================
  // TEST NOTIFICATION
  // ============================================================

  static Future<void> showTestNotification() async {
    if (!isAndroid) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'tafheel_docs_reminders',
      'TAFHEEL DOCS Reminders',
      channelDescription: 'Company and employee reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: 1000,
      title: 'TAFHEEL DOCS',
      body: 'Notification system is working!',
      notificationDetails: details,
    );
  }

  // ============================================================
  // MANUAL REMINDER
  // ============================================================

  static Future<void> scheduleManualReminder({
    required int id,
    required String title,
    required String body,
    required DateTime reminderDateTime,
  }) async {
    if (!isAndroid) {
      return;
    }

    final now = DateTime.now();

    if (reminderDateTime.isBefore(now)) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(
      reminderDateTime,
      tz.local,
    );

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'tafheel_docs_manual_reminders',
      'TAFHEEL DOCS Manual Reminders',
      channelDescription: 'Manual company and employee reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ============================================================
  // CANCEL REMINDER
  // ============================================================

  static Future<void> cancelReminder(int id) async {
    if (!isAndroid) {
      return;
    }

    await _notifications.cancel(id: id);
  }

  // ============================================================
  // CANCEL ALL REMINDERS
  // ============================================================

  static Future<void> cancelAllReminders() async {
    if (!isAndroid) {
      return;
    }

    await _notifications.cancelAll();
  }
}