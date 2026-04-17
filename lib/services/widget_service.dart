// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:home_widget/home_widget.dart';

/// Pushes today's habit summary to the home screen widget.
/// Call this after every goals save.
abstract final class WidgetService {
  static const String _appGroupId = 'group.com.example.habitTracker';
  static const String _iOSWidgetName = 'HabitWidget';
  static const String _androidWidgetName = 'HabitWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> update(List<dynamic> goals) async {
    try {
      final now = DateTime.now();
      final todayGoals = goals.map((g) {
        return {
          'name': g.title as String,
          'done': g.loggedToday as bool,
        };
      }).toList();

      final completed = todayGoals.where((h) => h['done'] == true).length;
      final total = todayGoals.length;

      await HomeWidget.saveWidgetData('habits_total', total);
      await HomeWidget.saveWidgetData('habits_completed', completed);
      await HomeWidget.saveWidgetData('habits_today', jsonEncode(todayGoals));
      await HomeWidget.saveWidgetData(
        'habits_updated',
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
      print('✓ Home widget updated ($completed/$total done)');
    } catch (e) {
      print('⚠️ Home widget update failed: $e');
    }
  }
}
