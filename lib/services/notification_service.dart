// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    print('✓ NotificationService initialized');
  }

  /// Schedule a daily notification for a habit at a given [TimeOfDay].
  /// [id] must be unique per habit+reminder combination.
  static Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required TimeOfDay time,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      time.hour, time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'Time for: $habitName',
      'Keep your streak alive — log your habit now!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders to log your habits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print('✓ Scheduled reminder: "$habitName" at ${time.hour}:${time.minute.toString().padLeft(2, '0')} (id $id)');
  }

  /// Cancel all reminders for a given habit (up to 10 reminder slots).
  static Future<void> cancelHabitReminders(int baseId) async {
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(baseId * 10 + i);
    }
    print('✓ Cancelled reminders for habit id $baseId');
  }

  /// Schedules a single daily reminder at 8:00 PM to log habits.
  /// Safe to call repeatedly — cancels the old one before scheduling.
  static Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    if (!_initialized) await init();
    await _plugin.cancel(9999); // fixed ID for the global daily reminder

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      9999,
      'Don\'t break your streak! 🔥',
      'Log your habits for today before the day ends.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily nudge to log your habits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print('✓ Daily reminder scheduled at $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Reschedule all reminders based on current goals list.
  /// Call this after any goals save.
  static Future<void> rescheduleAll(List<dynamic> goals) async {
    if (!_initialized) await init();
    // Cancel all existing reminders (IDs 0..9999)
    await _plugin.cancelAll();

    for (int gi = 0; gi < goals.length; gi++) {
      final goal = goals[gi];
      final reminders = goal.reminders as List;
      for (int ri = 0; ri < reminders.length; ri++) {
        final time = reminders[ri] as TimeOfDay;
        await scheduleHabitReminder(
          id: gi * 10 + ri,
          habitName: goal.title as String,
          time: time,
        );
      }
    }
    print('✓ Rescheduled all habit reminders');
  }
}
