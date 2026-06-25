import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    // Default fallback timezone is UTC
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {}

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    try {
      await _notificationsPlugin.initialize(settings);
    } catch (_) {
      // Fail silently if not running on supported platform or during test
    }
  }

  static Future<void> requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (_) {
      // Safe fallback
    }
  }

  static Future<void> scheduleDailyReminder(String name, String examName, int daysLeft, {TimeOfDay? customTime}) async {
    final now = DateTime.now();
    final targetHour = customTime?.hour ?? 19;
    final targetMinute = customTime?.minute ?? 0;
    
    var localScheduled = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
    if (localScheduled.isBefore(now)) {
      localScheduled = localScheduled.add(const Duration(days: 1));
    }
    final difference = localScheduled.difference(now);
    final scheduledDate = tz.TZDateTime.now(tz.UTC).add(difference);

    try {
      await _notificationsPlugin.zonedSchedule(
        101, // unique ID for daily reminders
        'Time to grind, $name',
        '$daysLeft days left to $examName. Keep pushing.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders',
            'Study Reminders',
            channelDescription: 'Daily study reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback show immediate if scheduling fails
    }
  }

  static Future<void> scheduleExamAlerts(DateTime examDate, String examName) async {
    final now = DateTime.now();

    try {
      // Cancel previous exam alerts first to prevent duplicates
      await cancelExamAlerts();

      // 7 days before
      final sevenDaysBefore = examDate.subtract(const Duration(days: 7));
      if (sevenDaysBefore.isAfter(now)) {
        final difference = sevenDaysBefore.difference(now);
        final scheduledDate = tz.TZDateTime.now(tz.UTC).add(difference);
        await _notificationsPlugin.zonedSchedule(
          207,
          'Exam Approaching! 📅',
          'Only 7 days left for $examName. Time to double down on your study.',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'exam_alerts',
              'Exam Alerts',
              channelDescription: 'Countdown notifications before exams',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // 3 days before
      final threeDaysBefore = examDate.subtract(const Duration(days: 3));
      if (threeDaysBefore.isAfter(now)) {
        final difference = threeDaysBefore.difference(now);
        final scheduledDate = tz.TZDateTime.now(tz.UTC).add(difference);
        await _notificationsPlugin.zonedSchedule(
          203,
          'Final Revision Time! 🧠',
          '3 days left for $examName. Review your key formulas and flashcards.',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'exam_alerts',
              'Exam Alerts',
              channelDescription: 'Countdown notifications before exams',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // 1 day before
      final oneDayBefore = examDate.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(now)) {
        final difference = oneDayBefore.difference(now);
        final scheduledDate = tz.TZDateTime.now(tz.UTC).add(difference);
        await _notificationsPlugin.zonedSchedule(
          201,
          'Tomorrow is the Day! ⚡',
          'Only 24 hours left for $examName. Make sure to sleep well and stay calm.',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'exam_alerts',
              'Exam Alerts',
              channelDescription: 'Countdown notifications before exams',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  static Future<void> checkStreakAndNotify(int streak, DateTime lastActive) async {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    // If no activity logged today AND lastActive > 48hrs ago:
    if (difference.inHours > 48) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_warnings',
        'Streak Warnings',
        channelDescription: 'Notifications warning about potential streak loss',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);
      try {
        await _notificationsPlugin.show(
          301,
          'Streak at Risk 🔥',
          'Your $streak-day streak is at risk 🔥',
          details,
        );
      } catch (_) {}
    }
  }

  static Future<void> showTimerComplete(dynamic phase) async {
    String message = 'Focus session complete! Take a break.';
    final phaseStr = phase.toString().toLowerCase();
    if (phaseStr.contains('break') || phaseStr.contains('shortbreak') || phaseStr.contains('longbreak')) {
      message = 'Break over! Time to focus.';
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(
        0,
        'VidyaVerse Timer',
        message,
        details,
      );
    } catch (_) {}
  }

  static Future<void> cancelDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(101);
    } catch (_) {}
  }

  static Future<void> cancelExamAlerts() async {
    try {
      await _notificationsPlugin.cancel(207);
      await _notificationsPlugin.cancel(203);
      await _notificationsPlugin.cancel(201);
    } catch (_) {}
  }
}
