import 'dart:math';

/// A suggested habit stack: do [habitTitle] after [anchor].
class StackSuggestion {
  final String anchor;       // e.g. "Morning coffee"
  final String anchorEmoji;  // e.g. "☕"
  final String habitTitle;   // existing habit name
  final String reason;       // one-line explanation

  const StackSuggestion({
    required this.anchor,
    required this.anchorEmoji,
    required this.habitTitle,
    required this.reason,
  });
}

/// Local AI engine that generates habit stack suggestions from the user's habits.
///
/// Matching strategy: keywords are substrings likely to appear IN habit titles,
/// not just conceptual tags. Each anchor also carries a [priority] so that when
/// two anchors tie on score the more specific one wins.
abstract final class HabitStackService {
  // Keywords are words/fragments that commonly appear in real habit titles.
  // Higher-specificity anchors are listed first AND carry more keywords so they
  // beat generic anchors on score ties.
  static const _anchors = [
    // ── Sleep / night ──────────────────────────────────────────────────────────
    _Anchor('Getting into bed', '🛏️', [
      'before bed', 'bedtime', 'sleep time', 'consistent sleep', 'sleep schedul',
      'no screen', 'no phone', 'no scroll', 'screen-free', 'phone-free',
      'wind-down', 'wind down', 'night routine', 'evening routine',
      'night journal', 'night meditat', 'sleep meditat',
      'read', 'journal', 'gratitude', 'meditat', 'breath', 'relax', 'sleep',
      'pray', 'visuali', 'reflect',
    ]),

    // ── Waking up ──────────────────────────────────────────────────────────────
    _Anchor('Waking up', '🌅', [
      'morning', 'wake', 'first thing', 'start my day', 'start the day',
      'no phone first', 'phone free', 'screen free',
      'cold shower', 'cold water', 'sunlight', 'sun exposure',
      'push-up', 'push up', 'pull-up', 'pull up', 'plank', 'squat', 'lunge',
      'sit-up', 'sit up', 'crunch', 'burpee',
      'morning stretch', 'morning yoga', 'morning run', 'morning walk',
      'morning meditat', 'morning journal', 'morning breath',
      'affirmation', 'visuali', 'intend', 'prayer', 'gratitude',
      'glass of water', 'hydrat', 'lemon water',
    ]),

    // ── Morning coffee / quiet time ─────────────────────────────────────────────
    _Anchor('Morning coffee', '☕', [
      'plan my day', 'plan the day', 'daily plan', 'top 3', 'priority',
      'journal', 'morning pages', 'free write', 'write',
      'read', 'news', 'article', 'newsletter',
      'gratitude', 'reflect',
      'vocabular', 'word of the day', 'language', 'duolingo', 'spanish', 'french',
      'learn', 'podcast', 'study', 'audiobook', 'lecture',
    ]),

    // ── Breakfast / supplements ─────────────────────────────────────────────────
    _Anchor('Breakfast', '🥣', [
      'vitamin', 'supplement', 'probiotic', 'omega', 'zinc', 'magnesium',
      'medication', 'medicine', 'pill', 'tablet', 'capsule',
      'track water', 'drink water', 'glass of water', 'hydrat',
      'healthy breakfast', 'no sugar', 'protein breakfast',
    ]),

    // ── Getting dressed ─────────────────────────────────────────────────────────
    _Anchor('Getting dressed', '👗', [
      'affirmation', 'mantra', 'mirror', 'posture', 'smile',
      'intend', 'set intention', 'visuali',
    ]),

    // ── Commute ─────────────────────────────────────────────────────────────────
    _Anchor('Commute / transit', '🚌', [
      'commute', 'transit', 'podcast', 'audiobook', 'language lesson',
      'duolingo', 'spanish', 'french', 'german', 'japanese', 'mandarin',
      'vocabular', 'word', 'learn', 'study', 'lecture', 'course',
    ]),

    // ── Lunch break ─────────────────────────────────────────────────────────────
    _Anchor('Lunch break', '🥗', [
      'lunch', 'midday', 'mid-day',
      'outside', 'fresh air', 'sunlight', 'nature walk', 'step',
      'nap', 'power nap',
      'water intake', 'hydrat',
      'walk', 'stretch', 'breath', 'meditat',
    ]),

    // ── Afternoon slump ─────────────────────────────────────────────────────────
    _Anchor('Afternoon slump', '⚡', [
      'caffeine', 'no caffeine', 'coffee after', 'no coffee after',
      'sugar', 'no sugar after', 'energy',
      'step', 'stand', 'desk stretch', '10k step', 'step count',
      'afternoon walk', 'afternoon stretch',
    ]),

    // ── Finishing work ─────────────────────────────────────────────────────────
    _Anchor('Finishing work', '💼', [
      'after work', 'end of work', 'close laptop', 'log off',
      'workout', 'gym', 'weight', 'strength', 'cardio', 'hiit', 'circuit',
      'run', 'jog', 'swim', 'cycle', 'bike', 'sport', 'basketball', 'tennis',
      'yoga', 'pilates', 'martial art', 'boxing', 'climb',
      'daily walk', 'evening walk', 'evening run',
      'decompres', 'unwind', 'decompress',
    ]),

    // ── After workout ──────────────────────────────────────────────────────────
    _Anchor('After workout', '🏋️', [
      'protein', 'shake', 'recovery', 'foam roll', 'cool down', 'cool-down',
      'post-workout', 'post workout',
    ]),

    // ── Evening dinner ─────────────────────────────────────────────────────────
    _Anchor('Evening dinner', '🍽️', [
      'dinner', 'evening meal', 'family time', 'family dinner',
      'cook', 'meal prep', 'no phone at dinner',
      'connect', 'talk', 'conversation',
    ]),

    // ── After dinner ──────────────────────────────────────────────────────────
    _Anchor('After dinner', '🌙', [
      'digital detox', 'detox hour', 'screen time', 'limit screen',
      'no screen after', 'social media', 'no social', 'unplug',
      'evening walk', 'after-dinner walk',
      'practice', 'skill', 'instrument', 'guitar', 'piano', 'draw', 'paint',
      'creative', 'craft', 'knit', 'code', 'write',
      'call', 'family call', 'friend call',
      'read', 'book',
    ]),

    // ── After shower ──────────────────────────────────────────────────────────
    _Anchor('After shower', '🚿', [
      'skincare', 'moisturis', 'lotion', 'sunscreen', 'spf',
      'cold shower', 'contrast shower', 'tongue scrap',
    ]),

    // ── Weekend morning ────────────────────────────────────────────────────────
    _Anchor('Weekend morning', '☀️', [
      'weekend', 'saturday', 'sunday',
      'hike', 'trail', 'bike ride', 'swim', 'garden', 'clean', 'deep clean',
      'long run', 'long walk', 'outdoor', 'nature',
    ]),

    // ── Opening phone ──────────────────────────────────────────────────────────
    _Anchor('Opening phone', '📱', [
      'screen time limit', 'app limit', 'no scroll', 'intentional',
      'check email', 'check news', 'no social media first',
    ]),

    // ── Before a meeting ──────────────────────────────────────────────────────
    _Anchor('Before a meeting', '🗓️', [
      'before meeting', 'pre-meeting', 'focus session', 'deep work',
      'breath before', 'meditat before',
    ]),
  ];

  static const _fallbackReasons = [
    'Pairing this with a daily anchor makes it automatic.',
    'Anchoring to an existing routine removes the need to decide.',
    'This trigger creates a reliable cue every single day.',
    'Habit stacking works because the anchor is already effortless.',
    'Linking to this moment means you never need to remember.',
    'Attaching to something you always do makes skipping feel unnatural.',
    'The anchor fires your brain\'s "what comes next?" instinct — use it.',
    'Consistent anchors turn intentions into identity.',
    'The easiest habits are the ones that follow something you\'d do anyway.',
    'Location and timing cues are more powerful than reminders — this gives you both.',
  ];

  /// Generates smart stack suggestions for the given habit titles.
  /// Returns multiple anchor options per habit so the list is always long.
  /// [existingStacks] maps habitTitle → its current anchor (to avoid duplicates).
  /// [maxPerHabit] controls how many anchor pairings to suggest per habit.
  static List<StackSuggestion> suggest({
    required List<String> habitTitles,
    Map<String, String?> existingStacks = const {},
    int maxSuggestions = 30,
    int maxPerHabit = 3,
    int seed = 0,
  }) {
    final rng = Random(seed);
    final candidates = <_ScoredSuggestion>[];

    for (final title in habitTitles) {
      if (existingStacks[title] != null) continue;

      final lower = title.toLowerCase();

      // Score every anchor for this habit
      final scored = <_ScoredSuggestion>[];
      for (final anchor in _anchors) {
        int score = 0;
        for (final k in anchor.keywords) {
          if (lower.contains(k)) {
            score += k.length > 6 ? 2 : 1;
          }
        }
        scored.add(_ScoredSuggestion(score: score, anchor: anchor, title: title));
      }
      scored.sort((a, b) => b.score.compareTo(a.score));

      final bestScore = scored.first.score;

      if (bestScore == 0) {
        // No keyword hit — pick 2 random anchors
        scored.shuffle(rng);
        for (final item in scored.take(2)) {
          candidates.add(item);
        }
      } else {
        // Add all keyword-matched anchors (score > 0), up to maxPerHabit
        final matched = scored.where((s) => s.score > 0).take(maxPerHabit).toList();
        candidates.addAll(matched);
        // Pad to at least 2 per habit with a random extra if only 1 matched
        if (matched.length < 2) {
          final extra = scored.where((s) => s.score == 0).toList()..shuffle(rng);
          if (extra.isNotEmpty) candidates.add(extra.first);
        }
      }
    }

    // Sort: higher-score first, then stable by title
    candidates.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : a.title.compareTo(b.title);
    });

    // Deduplicate (title + anchor) pairs
    final seen = <String>{};
    final suggestions = <StackSuggestion>[];
    for (final c in candidates) {
      final key = '${c.title}|||${c.anchor.name}';
      if (seen.contains(key)) continue;
      seen.add(key);
      suggestions.add(StackSuggestion(
        anchor: c.anchor.name,
        anchorEmoji: c.anchor.emoji,
        habitTitle: c.title,
        reason: _reason(c.title.toLowerCase(), c.anchor.name, rng),
      ));
      if (suggestions.length >= maxSuggestions) break;
    }

    return suggestions;
  }

  static String _reason(String habit, String anchor, Random rng) {
    if (anchor.contains('Waking')) {
      return _pick(rng, [
        'Morning willpower is at its peak — lock this in before distractions arrive.',
        'Starting the day with this signals your brain it\'s non-negotiable.',
        'Morning energy is high — do it before the day takes over.',
        'First thing in the morning means zero excuses, zero decision fatigue.',
      ]);
    }
    if (anchor.contains('coffee') || anchor.contains('tea')) {
      return _pick(rng, [
        'You already make this drink every day — just add one small habit to it.',
        'The ritual of a warm drink naturally slows you down. Use that window.',
        'Coffee time is mentally "free" — you\'re already pausing anyway.',
        'Pair this with a drink you never skip and it becomes automatic within a week.',
      ]);
    }
    if (anchor.contains('teeth') || anchor.contains('shower')) {
      return _pick(rng, [
        'You\'re already in the routine — zero extra effort to bolt this on.',
        'The bathroom is a private, consistent environment. Perfect low-friction anchor.',
        'You never miss brushing or showering, so you\'ll never miss this either.',
        'Bathroom routines are the most reliable anchors — they happen every single day.',
      ]);
    }
    if (anchor.contains('dressed') || anchor.contains('Breakfast')) {
      return _pick(rng, [
        'Morning prep time is underused — this fills it with intentional action.',
        'You\'re already in motion — tack this on before you leave the house.',
        'The morning transition is a natural checkpoint. Use it.',
        'A fixed morning ritual means this happens before the day can derail it.',
      ]);
    }
    if (anchor.contains('Commute')) {
      return _pick(rng, [
        'Dead time becomes growth time — your commute is the perfect slot.',
        'You\'re physically constrained on transit anyway. Put that time to work.',
        'Commutes are consistent and unavoidable — ideal for habit anchoring.',
        'Turn the commute from passive to intentional with one small add-on.',
      ]);
    }
    if (anchor.contains('Finishing work')) {
      return _pick(rng, [
        'The transition out of work mode is a natural reset — use it.',
        'Closing the laptop is a powerful cue. Follow it immediately with this.',
        'End-of-work is one of the strongest daily anchors — it happens at a fixed emotion.',
        'Work → habit flow prevents the "I\'ll do it later" trap that kills streaks.',
      ]);
    }
    if (anchor.contains('After workout')) {
      return _pick(rng, [
        'Post-workout discipline is already high — capitalise on it.',
        'You\'re already in action mode. One more minute here is nearly effortless.',
        'The cooldown window after a workout is ideal for recovery habits.',
        'You showed up for the hard part — this is the easy finish.',
      ]);
    }
    if (anchor.contains('bed')) {
      return _pick(rng, [
        'A consistent wind-down cue trains your brain to expect and follow through.',
        'Bedtime is your last chance every day — and you can\'t skip going to bed.',
        'The final 5 minutes before sleep have outsized psychological impact.',
        'Anchoring to bed means this happens 365 times a year, minimum.',
      ]);
    }
    if (anchor.contains('Lunch')) {
      return _pick(rng, [
        'Mid-day breaks are often wasted — this gives yours a purpose.',
        'A lunch anchor splits the day: morning is done, afternoon gets a boost.',
        'You step away from work anyway. Redirect 5 minutes of that toward this.',
        'Mid-day is an underrated anchor — energy resets, habit resets too.',
      ]);
    }
    if (anchor.contains('slump')) {
      return _pick(rng, [
        '3 PM drag is real. Use this habit as a pattern-interrupt and energy reset.',
        'Afternoon slump = reliable trigger. Same time, same feeling, same habit.',
        'Breaking the slump with a productive habit beats scrolling every time.',
        'This is a natural antidote to the afternoon energy dip — pair them.',
      ]);
    }
    if (anchor.contains('After dinner')) {
      return _pick(rng, [
        'Post-dinner calm is perfect for creative or winding-down habits.',
        'The evening\'s obligations are mostly done — use the quiet time.',
        'Attach this to dinner and it never competes with the rest of your day.',
        'Evening anchors are powerful because you\'re relaxed and present.',
      ]);
    }
    if (anchor.contains('dinner')) {
      return _pick(rng, [
        'You sit down every evening — attach this to the meal and it never gets forgotten.',
        'Dinner is a social anchor: consistent time, consistent location.',
        'Evening habits anchored to a meal stick because the meal never moves.',
        'The dinner table is one of the most consistent moments in any day.',
      ]);
    }
    if (anchor.contains('meeting')) {
      return _pick(rng, [
        'The moment before a meeting is a guaranteed daily pause. Use it.',
        'Pre-meeting prep time is often wasted on scrolling — reclaim it.',
        'A consistent pre-meeting habit builds focus and calm before high-stakes moments.',
        'You always wait for meetings to start — that 2-minute window is yours.',
      ]);
    }
    if (anchor.contains('phone')) {
      return _pick(rng, [
        'The phone-grab reflex is one of the most reliable cues of the day.',
        'Intercept the mindless phone check with something intentional instead.',
        'You open your phone dozens of times a day — tie one of those to this.',
        'Phone as trigger means this habit fires more reliably than any reminder.',
      ]);
    }
    if (anchor.contains('Weekend')) {
      return _pick(rng, [
        'Weekend mornings are the best window for habits that need more time.',
        'No commute, no rushed schedule — weekend mornings are habit gold.',
        'The relaxed pace of a weekend morning makes deeper habits stick faster.',
        'You have more time and less pressure on weekends. This fits perfectly.',
      ]);
    }
    // fallback
    return _fallbackReasons[rng.nextInt(_fallbackReasons.length)];
  }

  static String _pick(Random rng, List<String> options) =>
      options[rng.nextInt(options.length)];
}

class _Anchor {
  final String name;
  final String emoji;
  final List<String> keywords;
  const _Anchor(this.name, this.emoji, this.keywords);
}

class _ScoredSuggestion {
  final int score;
  final _Anchor anchor;
  final String title;
  const _ScoredSuggestion({required this.score, required this.anchor, required this.title});
}
