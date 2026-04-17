import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Local AI review engine — no API, no cost, works offline forever.
/// Generates a personalised weekly review from real habit data with varied phrasing.
abstract final class AiReviewService {
  static const _cacheKeyPrefix = 'ai_review_week_';

  static Future<String?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cacheKeyPrefix${_isoWeek(DateTime.now())}';
    return prefs.getString(key);
  }

  static Future<String> generate({
    required int weekNumber,
    required int totalHabits,
    required int completionPct,
    required int perfectDays,
    required int bestStreak,
    required List<Map<String, dynamic>> habitBreakdown,
  }) async {
    // Use weekNumber as seed so phrasing is consistent within a week but varies week-to-week
    final rng = Random(weekNumber * 31 + completionPct);

    final review = _buildReview(
      rng: rng,
      weekNumber: weekNumber,
      totalHabits: totalHabits,
      completionPct: completionPct,
      perfectDays: perfectDays,
      bestStreak: bestStreak,
      habitBreakdown: habitBreakdown,
    );

    final prefs = await SharedPreferences.getInstance();
    final key = '$_cacheKeyPrefix${_isoWeek(DateTime.now())}';
    await prefs.setString(key, review);
    return review;
  }

  static String _pick(Random rng, List<String> options) =>
      options[rng.nextInt(options.length)];

  static String _buildReview({
    required Random rng,
    required int weekNumber,
    required int totalHabits,
    required int completionPct,
    required int perfectDays,
    required int bestStreak,
    required List<Map<String, dynamic>> habitBreakdown,
  }) {
    final buf = StringBuffer();

    // ── Paragraph 1: Overall summary ─────────────────────────────────────────
    if (completionPct >= 90) {
      buf.write(_pick(rng, [
        'Week $weekNumber was outstanding. You completed $completionPct% of your habits across $totalHabits routines — that kind of consistency puts you in rare company. With $perfectDays perfect day${perfectDays == 1 ? '' : 's'}, you\'re building real momentum.',
        'What a week. $completionPct% completion across $totalHabits habits — that\'s not luck, that\'s a system working. $perfectDays day${perfectDays == 1 ? '' : 's'} with a perfect score this week alone.',
        'Week $weekNumber: $completionPct% across $totalHabits habits. That\'s elite territory. $perfectDays perfect day${perfectDays == 1 ? '' : 's'} this week is the kind of data that compounds over months.',
        'You showed up hard in week $weekNumber. $completionPct% completion, $perfectDays flawless day${perfectDays == 1 ? '' : 's'} — your habits are no longer something you do, they\'re who you are.',
      ]));
    } else if (completionPct >= 70) {
      buf.write(_pick(rng, [
        'Week $weekNumber was a solid effort. You hit $completionPct% completion across $totalHabits habits, which shows genuine commitment. $perfectDays day${perfectDays == 1 ? '' : 's'} were perfect — those are the ones that move the needle.',
        'Good week. $completionPct% across $totalHabits habits isn\'t just showing up — it\'s showing up consistently. $perfectDays perfect day${perfectDays == 1 ? '' : 's'} this week is something to build on.',
        'Week $weekNumber had more wins than losses. $completionPct% completion with $perfectDays perfect day${perfectDays == 1 ? '' : 's'} — you\'re in the zone where habits start to feel automatic.',
        '$completionPct% in week $weekNumber across $totalHabits habits. That\'s well above average. The $perfectDays perfect day${perfectDays == 1 ? '' : 's'} you hit prove you know exactly what full effort looks like.',
      ]));
    } else if (completionPct >= 50) {
      buf.write(_pick(rng, [
        'Week $weekNumber had its ups and downs. You finished at $completionPct% across $totalHabits habits — a decent base, and the $perfectDays perfect day${perfectDays == 1 ? '' : 's'} prove you\'re capable of more.',
        'Halfway there in week $weekNumber. $completionPct% completion across $totalHabits habits means more days hit than missed — now the goal is to close the gap.',
        'Week $weekNumber: $completionPct% across $totalHabits habits. Not your best, not your worst. The $perfectDays perfect day${perfectDays == 1 ? '' : 's'} are proof the standard is in there — it just needs to come out more often.',
        '$completionPct% is a foundation, not a ceiling. $totalHabits habits tracked in week $weekNumber with $perfectDays perfect day${perfectDays == 1 ? '' : 's'} — small gains this week set you up for a stronger next one.',
      ]));
    } else {
      buf.write(_pick(rng, [
        'Week $weekNumber was a tough one — $completionPct% completion across $totalHabits habits. That\'s okay. Even tracking is a step forward, and the $perfectDays perfect day${perfectDays == 1 ? '' : 's'} remind you what\'s possible.',
        'Not the week you wanted. $completionPct% across $totalHabits habits in week $weekNumber — but you\'re still here, still tracking. That counts for more than it seems.',
        'Week $weekNumber was rough: $completionPct%. But every streak started after a week like this one. The score isn\'t the story — what you do next is.',
        '$completionPct% in week $weekNumber. Low numbers don\'t define you — ignoring them would. You noticed. That\'s the first move.',
      ]));
    }

    buf.write('\n\n');

    // ── Paragraph 2: Best and worst habit ────────────────────────────────────
    if (habitBreakdown.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(habitBreakdown)
        ..sort((a, b) => (b['pct'] as int).compareTo(a['pct'] as int));

      final best = sorted.first;
      final worst = sorted.last;

      if (best['pct'] as int >= 80) {
        buf.write(_pick(rng, [
          '${best['name']} was your standout habit this week at ${best['pct']}% — ${best['completed']} out of ${best['total']} days. ',
          'Top performer: ${best['name']} at ${best['pct']}%, completing it ${best['completed']}/${best['total']} days. ',
          '${best['name']} led the week with ${best['pct']}% — ${best['completed']} days straight of doing what you said you\'d do. ',
          'Your most consistent habit was ${best['name']}: ${best['completed']} of ${best['total']} days (${best['pct']}%). ',
        ]));
      } else {
        buf.write(_pick(rng, [
          '${best['name']} led the pack at ${best['pct']}% this week. ',
          'Even at the top, ${best['name']} only hit ${best['pct']}% — there\'s headroom across the board. ',
          '${best['name']} was your best this week at ${best['pct']}%. ',
        ]));
      }

      if (sorted.length > 1 && (worst['pct'] as int) < 60) {
        buf.write(_pick(rng, [
          '${worst['name']} needs more attention — only ${worst['pct']}% this week. That\'s the one to focus on next.',
          'On the other end, ${worst['name']} struggled at ${worst['pct']}%. One habit to fix is better than ten to improve.',
          '${worst['name']} at ${worst['pct']}% is the clear gap. Narrow your focus there next week.',
          'The weak link was ${worst['name']} — ${worst['pct']}%. Identifying it is half the fix.',
        ]));
      } else if (sorted.length > 1) {
        buf.write(_pick(rng, [
          'Your habits were fairly balanced — ${worst['name']} at ${worst['pct']}% has the most room to grow.',
          'Solid consistency across the board, with ${worst['name']} (${worst['pct']}%) as the one to push higher.',
          'Even your lowest, ${worst['name']} at ${worst['pct']}%, isn\'t far off. A small push there would round out a great week.',
        ]));
      }
    }

    buf.write('\n\n');

    // ── Paragraph 3: Streak insight ──────────────────────────────────────────
    if (bestStreak >= 30) {
      buf.write(_pick(rng, [
        'A $bestStreak-day streak is a serious achievement — that\'s a habit becoming part of who you are. Protect it.',
        '$bestStreak consecutive days. At this point it\'s not a streak, it\'s a lifestyle. Don\'t let a bad day become two.',
        'Thirty-plus days in a row tells your brain this is non-negotiable. $bestStreak days and counting — keep the chain alive.',
        'A $bestStreak-day streak is hard to build and easy to lose. You\'ve earned it. Guard it.',
      ]));
    } else if (bestStreak >= 14) {
      buf.write(_pick(rng, [
        'Your best streak of $bestStreak days is building real neural pathways. Two weeks rewires the brain — keep going.',
        '$bestStreak days straight is where habits start to feel like identity. You\'re right at the threshold.',
        'A $bestStreak-day streak means you\'ve navigated at least two weeks of real life without breaking it. That\'s resilience.',
        '$bestStreak days in — you\'re past the hardest part. Most people quit in the first week. You didn\'t.',
      ]));
    } else if (bestStreak >= 7) {
      buf.write(_pick(rng, [
        'A $bestStreak-day streak shows you can string a full week together. Next target: 14 days.',
        '$bestStreak days straight — a full week of showing up. Now double it.',
        'One week solid at $bestStreak days. The second week is where it starts to stick for real.',
        'A $bestStreak-day streak is momentum. Don\'t stop — the compound effect kicks in around day 14.',
      ]));
    } else if (bestStreak >= 3) {
      buf.write(_pick(rng, [
        '$bestStreak days in a row — the chain is alive. Every day you add makes it harder to break.',
        'A $bestStreak-day streak is a start. Small chains compound fast — protect it through the weekend.',
        '$bestStreak consecutive days matters more than it sounds. That\'s your brain learning a new pattern.',
        'You\'ve got $bestStreak days going. Don\'t overthink it — just do it again tomorrow.',
      ]));
    } else {
      buf.write(_pick(rng, [
        'Focus on starting a 3-day streak this week. Three days in a row changes your relationship with a habit.',
        'No streak yet — that\'s this week\'s mission. Three days in a row, one habit. That\'s the whole goal.',
        'The most powerful move this week: pick one habit and don\'t miss it for 3 days straight. That\'s it.',
        'Streaks start with a single day. Tomorrow counts as day one — make it happen.',
      ]));
    }

    buf.write('\n\n');

    // ── Paragraph 4: Actionable tip ──────────────────────────────────────────
    buf.write(_actionableTip(
      rng: rng,
      completionPct: completionPct,
      perfectDays: perfectDays,
      habitBreakdown: habitBreakdown,
      bestStreak: bestStreak,
    ));

    return buf.toString();
  }

  static String _actionableTip({
    required Random rng,
    required int completionPct,
    required int perfectDays,
    required List<Map<String, dynamic>> habitBreakdown,
    required int bestStreak,
  }) {
    String? weakestHabit;
    int lowestPct = 101;
    for (final h in habitBreakdown) {
      if ((h['pct'] as int) < lowestPct) {
        lowestPct = h['pct'] as int;
        weakestHabit = h['name'] as String;
      }
    }

    if (completionPct < 50 && weakestHabit != null) {
      return _pick(rng, [
        'This week\'s tip: pick just one habit — "$weakestHabit" — and make it non-negotiable. Shrink it until it\'s trivially easy, then do it anyway.',
        'One move this week: do "$weakestHabit" every single day, no exceptions. One habit at 100% beats five habits at 40%.',
        'Tip: don\'t try to fix everything at once. Start with "$weakestHabit" — nail that one, and the rest gets easier.',
        'This week, treat "$weakestHabit" as the only habit that matters. Momentum from one win bleeds into all the others.',
      ]);
    } else if (perfectDays <= 1) {
      return _pick(rng, [
        'Tip: stack your habits back-to-back in a single daily block. One "habit hour" dramatically increases your chance of a perfect day.',
        'Try batching all your habits into one time slot. Fewer decisions = fewer skips.',
        'This week\'s tip: set a single daily alarm labelled "habit block." Do everything in one go — decision fatigue is your biggest enemy.',
        'Perfect days come from routines, not motivation. Lock in a fixed time for your habits and treat it like a meeting you can\'t cancel.',
      ]);
    } else if (completionPct >= 80 && bestStreak < 14) {
      return _pick(rng, [
        'Tip: you\'re consistent enough to push for a 14-day streak. Set a reminder for your least-reliable habit — proactive prompts beat willpower.',
        'You\'re performing well — now lock it in. Aim for 14 days on your best habit. That\'s where it becomes automatic.',
        'High completion + no long streak means you\'re still relying on motivation. This week: make one habit non-negotiable for 14 days straight.',
        'The gap between where you are and a 14-day streak is tiny. Close it this week — you clearly have the capacity.',
      ]);
    } else if (weakestHabit != null && lowestPct < 60) {
      return _pick(rng, [
        'Tip: schedule "$weakestHabit" right after a habit you never miss. Habit stacking removes the decision — you stop relying on motivation.',
        'Attach "$weakestHabit" to something you already do every day. Make it impossible to forget by linking it to an existing anchor.',
        'The simplest fix for "$weakestHabit": do it immediately after brushing your teeth or making coffee. Context triggers beat reminders.',
        '"$weakestHabit" keeps slipping because it doesn\'t have a trigger yet. Pair it with a daily anchor and watch the number climb.',
      ]);
    } else {
      return _pick(rng, [
        'Tip: review your habit list and ask if each one still excites you. Dropping one you no longer care about often boosts completion on the ones that do.',
        'You\'re in a good place — now raise the bar. Add one rep, one minute, or one extra day to your strongest habit.',
        'Tip: tell someone about your streak. Social accountability adds a layer of motivation that willpower alone can\'t match.',
        'Strong week. This is the moment most people coast — don\'t. Use this momentum to tackle the habit you\'ve been avoiding.',
      ]);
    }
  }

  static int _isoWeek(DateTime date) {
    final doy = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((doy - date.weekday + 10) / 7).floor();
  }
}
