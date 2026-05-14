/// A suggested habit stack: do [habitTitle] after [anchor].
class StackSuggestion {
  final String anchor;
  final String anchorEmoji;
  final String habitTitle;
  final String reason;

  const StackSuggestion({
    required this.anchor,
    required this.anchorEmoji,
    required this.habitTitle,
    required this.reason,
  });
}

abstract final class HabitStackService {
  static const _anchors = [
    // ── Waking up ───────────────────────────────────────────────────────────────
    _Anchor('Waking up', '🌅', [
      'morning', 'wake', 'first thing', 'start my day', 'start the day',
      'no phone first', 'phone free morning', 'screen free morning',
      'cold shower', 'cold water face', 'sunlight', 'sun exposure',
      'push-up', 'pushup', 'push up', 'pull-up', 'pullup', 'pull up',
      'plank', 'squat', 'lunge', 'sit-up', 'situp', 'sit up', 'crunch', 'burpee',
      'morning stretch', 'morning yoga', 'morning run', 'morning walk',
      'morning workout', 'morning exercise',
      'morning meditat', 'morning journal', 'morning breath',
      'affirmation', 'visuali', 'intend',
      'glass of water', 'hydrat', 'lemon water',
      'make bed', 'make my bed',
    ]),

    // ── Getting into bed ────────────────────────────────────────────────────────
    _Anchor('Getting into bed', '🛏️', [
      'before bed', 'bedtime', 'sleep time', 'consistent sleep', 'sleep schedul',
      'no screen before', 'no phone before', 'no scroll', 'screen-free', 'phone-free',
      'wind-down', 'wind down', 'night routine', 'evening routine',
      'night journal', 'night meditat', 'sleep meditat', 'sleep story',
      'night read', 'read before bed', 'night gratitude', 'evening gratitude',
      'tomorrow list', 'plan tomorrow', 'tomorrow plan',
      'breath', 'progressive relaxat', 'body scan',
      'pray', 'reflect on day',
    ]),

    // ── Morning coffee / tea ─────────────────────────────────────────────────────
    _Anchor('Morning coffee', '☕', [
      'plan my day', 'plan the day', 'daily plan', 'top 3', 'priority',
      'journal', 'morning pages', 'free write',
      'read news', 'read article', 'newsletter', 'read nonfiction',
      'gratitude', 'gratitude list',
      'vocabulary', 'word of the day', 'language', 'duolingo', 'spanish', 'french',
      'german', 'mandarin', 'japanese', 'italian', 'korean',
      'learn', 'podcast', 'study session', 'audiobook', 'lecture',
      'review goals', 'review tasks',
    ]),

    // ── Breakfast ───────────────────────────────────────────────────────────────
    _Anchor('Breakfast', '🥣', [
      'vitamin', 'supplement', 'probiotic', 'omega', 'zinc', 'magnesium',
      'iron', 'collagen', 'ashwagandha', 'creatine',
      'medication', 'medicine', 'pill', 'tablet', 'capsule',
      'track water', 'drink water', 'glass of water',
      'protein breakfast', 'no sugar breakfast',
      'calorie', 'calori', 'food log', 'food diary', 'macro',
    ]),

    // ── Getting dressed ─────────────────────────────────────────────────────────
    _Anchor('Getting dressed', '👗', [
      'affirmation mirror', 'mirror affirmation', 'mantra', 'posture check',
      'set intention', 'daily intention',
    ]),

    // ── Commute ─────────────────────────────────────────────────────────────────
    _Anchor('Commute / transit', '🚌', [
      'commute', 'on the train', 'on the bus', 'on the subway',
      'podcast', 'audiobook',
      'language lesson', 'duolingo commute', 'learn commute',
      'study commute', 'lecture commute', 'course lesson',
      'calls commute', 'call someone commute',
    ]),

    // ── Lunch break ─────────────────────────────────────────────────────────────
    _Anchor('Lunch break', '🥗', [
      'lunch walk', 'midday walk', 'mid-day walk', 'lunchtime walk',
      'outside break', 'fresh air break', 'nature break',
      'power nap', 'midday nap',
      'lunch hydrat',
      'midday stretch', 'lunch stretch', 'midday meditat', 'lunch meditat',
      'no phone lunch', 'phone-free lunch',
    ]),

    // ── Finishing work ─────────────────────────────────────────────────────────
    _Anchor('Finishing work', '💼', [
      'after work', 'end of work', 'close laptop', 'log off', 'shutdown ritual',
      'workout', 'gym', 'weight', 'strength train', 'lift', 'cardio', 'hiit', 'circuit',
      'run', 'jog', 'swim', 'cycle', 'bike ride', 'basketball', 'tennis',
      'yoga class', 'pilates', 'martial art', 'boxing', 'climbing', 'bouldering',
      'evening walk', 'evening run',
      'decompres', 'unwind', 'transition',
      'review my day', 'daily review',
    ]),

    // ── After workout ──────────────────────────────────────────────────────────
    _Anchor('After workout', '🏋️', [
      'protein shake', 'post-workout shake', 'recovery shake',
      'foam roll', 'foam rolling', 'cool down', 'cool-down', 'stretch after',
      'post-workout', 'post workout', 'recovery routine',
      'track workout', 'log workout', 'log reps',
    ]),

    // ── Evening dinner ─────────────────────────────────────────────────────────
    _Anchor('Dinner', '🍽️', [
      'family dinner', 'no phone at dinner', 'phone free dinner',
      'cook dinner', 'meal prep', 'cook meal',
      'connect with partner', 'connect with family',
    ]),

    // ── After dinner ──────────────────────────────────────────────────────────
    _Anchor('After dinner', '🌙', [
      'digital detox', 'no screen after', 'no social after', 'unplug',
      'after-dinner walk', 'evening stroll',
      'guitar', 'piano', 'instrument practice', 'music practice',
      'draw', 'sketch', 'paint', 'creative writing', 'craft', 'knit',
      'code side project', 'personal project',
      'call friend', 'call family', 'connect call',
      'read fiction', 'read book', 'read chapter',
    ]),

    // ── After shower ──────────────────────────────────────────────────────────
    _Anchor('After shower', '🚿', [
      'skincare', 'skincare routine', 'moisturis', 'lotion', 'sunscreen', 'spf',
      'serum', 'face wash', 'toner', 'retinol',
      'cold shower', 'contrast shower',
      'tongue scrap', 'floss', 'oil pull',
      'hair care', 'hair mask',
    ]),

    // ── Brushing teeth ─────────────────────────────────────────────────────────
    _Anchor('Brushing teeth', '🪥', [
      'floss', 'flossing', 'mouthwash', 'tongue scrap', 'oil pull',
      'oral care', 'dental care',
    ]),

    // ── Lunch (for supplements mid-day) ─────────────────────────────────────────
    _Anchor('Afternoon snack', '🍎', [
      'afternoon vitamin', 'afternoon supplement', 'afternoon hydrat',
      'afternoon step', 'desk stand', 'stand up',
      'afternoon caffeine', 'no caffeine after', 'no coffee after',
    ]),

    // ── Weekend morning ────────────────────────────────────────────────────────
    _Anchor('Weekend morning', '☀️', [
      'weekend hike', 'weekend trail', 'weekend bike', 'weekend swim',
      'garden', 'deep clean', 'weekly review',
      'long run', 'long walk', 'outdoor workout',
      'saturday', 'sunday',
    ]),

    // ── Opening laptop ─────────────────────────────────────────────────────────
    _Anchor('Opening laptop for work', '💻', [
      'daily standup', 'daily scrum', 'open task manager', 'check trello',
      'check notion', 'review calendar', 'time block',
      'deep work', 'focus session', 'pomodoro',
    ]),

    // ── Before a meeting ──────────────────────────────────────────────────────
    _Anchor('Before a meeting', '🗓️', [
      'before meeting', 'pre-meeting breath', 'focus before call',
      'meditat before', 'center before',
    ]),
  ];

  // Fallback anchors ordered by how broadly applicable they are.
  // Used when no keyword matches — pick by rough habit category.
  static const _smartFallbacks = {
    'health': _Anchor('Breakfast', '🥣', []),
    'mind': _Anchor('Morning coffee', '☕', []),
    'physical': _Anchor('Finishing work', '💼', []),
    'night': _Anchor('Getting into bed', '🛏️', []),
    'skill': _Anchor('After dinner', '🌙', []),
    'default': _Anchor('Waking up', '🌅', []),
  };

  static const _healthKeywords = ['health', 'weight', 'calori', 'diet', 'eat', 'food', 'drink',
    'sleep', 'water', 'protein', 'fat', 'carb', 'vitamin', 'supplement', 'medication',
    'step', 'walk', 'run', 'jog', 'swim', 'gym', 'workout', 'exercise', 'stretch',
    'breath', 'meditat', 'stress', 'anxiet'];
  static const _skillKeywords = ['read', 'learn', 'study', 'practice', 'language', 'code',
    'write', 'journal', 'draw', 'paint', 'guitar', 'piano', 'instrument', 'course',
    'book', 'podcast', 'skill', 'craft', 'knit'];
  static const _nightKeywords = ['screen', 'social media', 'scroll', 'phone', 'relax',
    'unwind', 'calm', 'reflect', 'night', 'bed', 'sleep'];

  static List<StackSuggestion> suggest({
    required List<String> habitTitles,
    Map<String, String?> existingStacks = const {},
    int maxSuggestions = 30,
    int maxPerHabit = 3,
    int seed = 0,
  }) {
    final candidates = <_ScoredSuggestion>[];

    for (final title in habitTitles) {
      if (existingStacks[title] != null) continue;

      final lower = title.toLowerCase();

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
        // Smart fallback: pick an anchor based on what category the habit looks like
        final fallbackAnchor = _categorizeFallback(lower);
        candidates.add(_ScoredSuggestion(score: 0, anchor: fallbackAnchor, title: title));
        // Add one secondary anchor (waking up or bedtime) for variety
        final secondary = lower.contains('night') || lower.contains('bed') || lower.contains('sleep')
            ? _anchors.firstWhere((a) => a.name.contains('Waking'))
            : _anchors.firstWhere((a) => a.name.contains('bed'));
        candidates.add(_ScoredSuggestion(score: 0, anchor: secondary, title: title));
      } else {
        final matched = scored.where((s) => s.score > 0).take(maxPerHabit).toList();
        candidates.addAll(matched);
        if (matched.length < 2) {
          // Add smart fallback instead of random
          final fallbackAnchor = _categorizeFallback(lower);
          if (matched.every((m) => m.anchor.name != fallbackAnchor.name)) {
            candidates.add(_ScoredSuggestion(score: 0, anchor: fallbackAnchor, title: title));
          }
        }
      }
    }

    candidates.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : a.title.compareTo(b.title);
    });

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
        reason: _reason(c.title, c.anchor.name),
      ));
      if (suggestions.length >= maxSuggestions) break;
    }

    return suggestions;
  }

  static _Anchor _categorizeFallback(String lower) {
    for (final k in _nightKeywords) {
      if (lower.contains(k)) return _smartFallbacks['night']!;
    }
    for (final k in _healthKeywords) {
      if (lower.contains(k)) return _smartFallbacks['health']!;
    }
    for (final k in _skillKeywords) {
      if (lower.contains(k)) return _smartFallbacks['skill']!;
    }
    return _smartFallbacks['default']!;
  }

  static String _reason(String habitTitle, String anchor) {
    final h = habitTitle.toLowerCase();

    if (anchor.contains('Waking')) {
      if (_isPhysical(h)) return 'Morning is the one time the day can\'t interrupt you yet — best window for physical habits.';
      if (_isMind(h)) return 'Doing this first thing means it happens before decision fatigue sets in.';
      return 'Attaching this to waking up makes it the first win of the day, every day.';
    }

    if (anchor.contains('bed')) {
      if (_isMind(h)) return 'The last thing before sleep sticks — your brain processes it overnight.';
      if (h.contains('read') || h.contains('book')) return 'Reading before bed beats scrolling and actually helps you fall asleep faster.';
      if (h.contains('journal') || h.contains('reflect')) return 'Dumping thoughts before sleep clears your head and makes tomorrow easier to start.';
      return 'A bedtime anchor fires 365 times a year — you can\'t skip going to bed.';
    }

    if (anchor.contains('coffee') || anchor.contains('tea')) {
      if (h.contains('plan') || h.contains('priorit')) return 'Planning during coffee means you enter work knowing what matters — not figuring it out mid-morning.';
      if (h.contains('read') || h.contains('learn') || h.contains('study')) return 'The slow pace of a morning drink is naturally good for absorbing information.';
      if (h.contains('journal') || h.contains('write')) return 'Coffee time is quiet and unrushed — ideal for reflective writing.';
      return 'You never skip your morning drink, so this habit inherits that same reliability.';
    }

    if (anchor.contains('Breakfast')) {
      if (h.contains('vitamin') || h.contains('supplement') || h.contains('medication') || h.contains('pill')) {
        return 'Taking supplements with food improves absorption and means you\'ll never do it on an empty stomach.';
      }
      if (h.contains('water') || h.contains('hydrat')) return 'A glass of water with breakfast rehydrates you after 8 hours of sleep — easiest habit there is.';
      if (h.contains('calori') || h.contains('food log') || h.contains('macro')) return 'Logging breakfast while you eat it is the only time food tracking is actually accurate.';
      return 'Breakfast is a fixed daily anchor with a clear start and end — perfect timing.';
    }

    if (anchor.contains('Commute')) {
      if (h.contains('podcast') || h.contains('audiobook') || h.contains('learn')) return 'Commute time is already blocked off — you\'re not trading it for anything else.';
      if (h.contains('language') || h.contains('duolingo') || h.contains('spanish') || h.contains('french')) {
        return '15–30 minutes of language input daily adds up to 100+ hours a year with zero extra time cost.';
      }
      return 'The commute is dead time you\'re already spending — this makes it count.';
    }

    if (anchor.contains('Finishing work')) {
      if (_isPhysical(h)) return 'Post-work energy is a real thing. Using it for exercise means you don\'t need extra willpower later.';
      if (h.contains('review') || h.contains('reflect')) return 'A work shutdown ritual creates a hard boundary between work and personal time — most people never have one.';
      return 'Closing the laptop is a reliable daily cue with a consistent emotional state attached to it.';
    }

    if (anchor.contains('After workout')) {
      if (h.contains('protein') || h.contains('shake') || h.contains('recover')) return 'The 30-minute post-workout window is when your muscles actually need the nutrition.';
      if (h.contains('stretch') || h.contains('foam') || h.contains('cool')) return 'Skipping cooldowns is how people get injured. After the workout is the only moment this will actually happen.';
      if (h.contains('log') || h.contains('track')) return 'Logging immediately after means you remember exact weights and reps — not a fuzzy estimate later.';
      return 'You just did the hard part — tack this on while you\'re already in action mode.';
    }

    if (anchor.contains('Dinner') && !anchor.contains('After')) {
      if (h.contains('family') || h.contains('connect') || h.contains('partner')) return 'Protecting dinner for real conversation is one of the highest-leverage relationship habits there is.';
      if (h.contains('cook') || h.contains('meal prep')) return 'Cooking dinner is already happening — this just makes it more intentional.';
      return 'Dinner happens at the same time every day — it\'s one of the most reliable anchors in your schedule.';
    }

    if (anchor.contains('After dinner')) {
      if (h.contains('read') || h.contains('book')) return 'Post-dinner is when most people scroll instead. Replacing that with reading is an easy win.';
      if (h.contains('guitar') || h.contains('piano') || h.contains('instrument') || h.contains('music')) {
        return 'Skill practice after dinner means no work guilt and you\'re relaxed enough to actually enjoy it.';
      }
      if (h.contains('draw') || h.contains('paint') || h.contains('creative') || h.contains('write')) {
        return 'Creative work after dinner gets the focused time it deserves without competing with the workday.';
      }
      if (h.contains('call') || h.contains('friend') || h.contains('family')) return 'Evening calls are more relaxed and less likely to get cut short than midday ones.';
      return 'The evening is the one part of the day you actually control — use a slice of it for this.';
    }

    if (anchor.contains('shower')) {
      if (h.contains('skincare') || h.contains('moisturi') || h.contains('lotion') || h.contains('serum')) {
        return 'Skincare right after showering works better — pores are open and skin is primed for absorption.';
      }
      if (h.contains('floss') || h.contains('mouthwash') || h.contains('tongue')) return 'Oral care takes 60 seconds and is easiest when you\'re already in front of the mirror.';
      return 'The shower is the most consistent private ritual in your day — a perfect place to bolt something on.';
    }

    if (anchor.contains('teeth')) {
      if (h.contains('floss')) return 'Flossing right after brushing removes the "I\'ll do it later" excuse entirely.';
      return 'Brushing teeth is automatic — adding something here means zero extra willpower.';
    }

    if (anchor.contains('Lunch')) {
      if (h.contains('walk') || h.contains('outside') || h.contains('fresh air')) {
        return 'A 10-minute outdoor walk at lunch significantly reduces afternoon mental fatigue. Most people skip it and regret it.';
      }
      if (h.contains('nap') || h.contains('rest')) return 'A 10–20 minute nap at lunch can recover 2–3 hours of afternoon focus. Longer than that and you\'ll feel worse.';
      return 'Lunch is a natural mid-day reset — the best moment for a habit that breaks up the workday.';
    }

    if (anchor.contains('Weekend')) {
      if (h.contains('hike') || h.contains('outdoor') || h.contains('trail')) return 'Weekend mornings are the only time you have the hours for something like this without rushing.';
      if (h.contains('review') || h.contains('plan')) return 'A weekly review on Sunday morning means Monday morning starts clear instead of reactive.';
      return 'Weekday habits get disrupted — weekend-specific anchors give these habits their own reliable slot.';
    }

    if (anchor.contains('laptop') || anchor.contains('Opening')) {
      if (h.contains('plan') || h.contains('task') || h.contains('priorit')) return 'Planning before checking messages means you set the agenda instead of reacting to everyone else\'s.';
      if (h.contains('focus') || h.contains('deep work') || h.contains('pomodoro')) return 'The first 30 minutes of a workday set the tone — use them for focus, not email.';
      return 'Pairing this with opening your laptop makes it the first thing you do before distraction kicks in.';
    }

    if (anchor.contains('meeting')) {
      if (h.contains('breath') || h.contains('meditat') || h.contains('center')) {
        return 'Two minutes of breathing before a call visibly changes how you show up in it.';
      }
      return 'The pre-meeting pause is a guaranteed daily moment that most people waste on anxious email-checking.';
    }

    // Generic fallback — specific to the habit title when possible
    if (_isPhysical(h)) return 'Physical habits are hardest to start cold. Anchoring to an existing routine removes that barrier.';
    if (_isMind(h)) return 'Mental habits need a consistent trigger. An existing routine gives them one automatically.';
    if (_isSkill(h)) return 'Skills compound — but only if practiced regularly. An anchor guarantees the session happens.';
    return 'The best habits aren\'t motivated — they\'re triggered. This anchor gives yours a reliable cue.';
  }

  static bool _isPhysical(String h) => h.contains('workout') || h.contains('exercise') ||
      h.contains('run') || h.contains('walk') || h.contains('gym') || h.contains('stretch') ||
      h.contains('yoga') || h.contains('swim') || h.contains('push') || h.contains('squat') ||
      h.contains('lift') || h.contains('sport') || h.contains('step') || h.contains('hike');

  static bool _isMind(String h) => h.contains('meditat') || h.contains('breath') ||
      h.contains('journal') || h.contains('reflect') || h.contains('gratitude') ||
      h.contains('mindful') || h.contains('calm') || h.contains('stress') ||
      h.contains('anxiet') || h.contains('therapy') || h.contains('affirm');

  static bool _isSkill(String h) => h.contains('read') || h.contains('study') ||
      h.contains('practice') || h.contains('learn') || h.contains('code') ||
      h.contains('write') || h.contains('language') || h.contains('instrument') ||
      h.contains('draw') || h.contains('paint') || h.contains('course');
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
