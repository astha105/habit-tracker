import 'package:flutter/material.dart';

/// Analyses a habit's completion history and suggests an optimal reminder time.
abstract final class SmartReminderService {
  /// Returns a suggested [TimeOfDay] based on when the user typically completes
  /// the habit, or null if there isn't enough data (< 3 completions).
  ///
  /// Strategy: take the median completion hour from history, then subtract
  /// 30 minutes so the reminder fires just before the habitual time.
  static TimeOfDay? suggestTime(List<DateTime> completionHistory) {
    if (completionHistory.length < 3) return null;

    // Collect minutes-since-midnight for each completion
    final minutesList = completionHistory
        .map((d) => d.hour * 60 + d.minute)
        .toList()
      ..sort();

    // Use median to be robust against outliers
    final mid = minutesList.length ~/ 2;
    final medianMinutes = minutesList.length.isOdd
        ? minutesList[mid]
        : (minutesList[mid - 1] + minutesList[mid]) ~/ 2;

    // Remind 30 minutes before the habitual time (min 5 min into the day)
    final reminderMinutes = (medianMinutes - 30).clamp(5, 23 * 60 + 55);

    return TimeOfDay(
      hour: reminderMinutes ~/ 60,
      minute: reminderMinutes % 60,
    );
  }

  /// Human-readable explanation of the suggestion.
  static String? explain(List<DateTime> completionHistory) {
    if (completionHistory.length < 3) return null;
    final minutesList = completionHistory
        .map((d) => d.hour * 60 + d.minute)
        .toList()
      ..sort();
    final mid = minutesList.length ~/ 2;
    final medianMinutes = minutesList.length.isOdd
        ? minutesList[mid]
        : (minutesList[mid - 1] + minutesList[mid]) ~/ 2;
    final h = medianMinutes ~/ 60;
    final m = medianMinutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return 'You usually complete this around $h12:${m.toString().padLeft(2, '0')} $period '
        '(based on ${completionHistory.length} completions)';
  }
}
