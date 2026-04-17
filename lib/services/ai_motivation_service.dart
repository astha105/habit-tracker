import 'package:shared_preferences/shared_preferences.dart';

/// Local motivation engine — no API, no cost, works offline forever.
/// Generates a personalised daily message from real habit stats.
abstract final class AiMotivationService {
  static const _cacheKeyPrefix = 'ai_motivation_date_';

  static String _todayKey() {
    final now = DateTime.now();
    return '$_cacheKeyPrefix${now.year}-${now.month}-${now.day}';
  }

  static Future<String?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_todayKey());
  }

  static Future<String> generate({
    required int bestStreak,
    required int activeHabits,
    required int completionPct,
    String? nearMilestone,
  }) async {
    final message = _buildMessage(
      bestStreak: bestStreak,
      activeHabits: activeHabits,
      completionPct: completionPct,
      nearMilestone: nearMilestone,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayKey(), message);
    return message;
  }

  static String _buildMessage({
    required int bestStreak,
    required int activeHabits,
    required int completionPct,
    String? nearMilestone,
  }) {
    if (nearMilestone != null) {
      return nearMilestone;
    }

    if (bestStreak >= 30) {
      return '$bestStreak days straight — you\'ve made this a part of who you are.';
    }
    if (bestStreak >= 14) {
      return 'Two weeks of consistency. Your future self is already thanking you.';
    }
    if (bestStreak >= 7) {
      return 'A full week on your best streak. Now make it two.';
    }
    if (bestStreak >= 3) {
      return '$bestStreak days in a row — the chain is alive. Don\'t break it today.';
    }
    if (completionPct >= 80) {
      return 'You\'re completing $completionPct% of your habits. That\'s not luck — that\'s discipline.';
    }
    if (completionPct >= 50) {
      return 'Halfway there on $activeHabits habits. Today\'s the day to tip the balance.';
    }
    if (activeHabits >= 5) {
      return '$activeHabits habits in motion. Small steps, every day — that\'s the whole game.';
    }

    return 'Every expert was once a beginner. Show up today.';
  }
}
