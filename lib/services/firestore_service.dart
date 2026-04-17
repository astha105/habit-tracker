import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/screens/goals_screen.dart';

/// FirestoreService
/// ────────────────
/// Single entry point for all Firestore reads and writes.
///
/// Firestore collection structure:
///
///   users/
///     {uid}                        ← user profile document
///       habits/
///         {habitId}                ← one document per habit
///       stats/
///         summary                  ← aggregated stats (updated on every log)
///
/// Usage:
///   final fs = FirestoreService();
///   await fs.saveHabit(goal);
///   final goals = await fs.loadHabits();
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    return user.uid;
  }

  /// users/{uid}
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  /// users/{uid}/habits
  CollectionReference<Map<String, dynamic>> get _habitsCol =>
      _userDoc.collection('habits');

  /// users/{uid}/stats/summary
  DocumentReference<Map<String, dynamic>> get _statsDoc =>
      _userDoc.collection('stats').doc('summary');

  // ── User Profile ─────────────────────────────────────────────────────────────

  /// Creates (or updates) the user profile document.
  /// Call once after sign-in.
  Future<void> createOrUpdateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'premium': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'lastActiveAt': FieldValue.serverTimestamp()});
    }
  }

  // ── Habits ───────────────────────────────────────────────────────────────────

  /// Saves a single habit to Firestore.
  /// Uses the habit title as a stable document ID so updates overwrite
  /// the same document instead of creating duplicates.
  Future<void> saveHabit(Goal goal) async {
    final docId = _habitDocId(goal.title);
    await _habitsCol.doc(docId).set(_goalToMap(goal), SetOptions(merge: true));
  }

  /// Saves all habits in one batched write.
  Future<void> saveAllHabits(List<Goal> goals) async {
    final batch = _db.batch();
    for (final goal in goals) {
      final ref = _habitsCol.doc(_habitDocId(goal.title));
      batch.set(ref, _goalToMap(goal), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Loads all habits for the current user.
  Future<List<Goal>> loadHabits() async {
    try {
      final snap = await _habitsCol
          .where('archived', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .get();
      return snap.docs.map((d) => _goalFromMap(d.data())).toList();
    } catch (_) {
      // Fallback: fetch without ordering if index isn't ready yet
      final snap = await _habitsCol
          .where('archived', isEqualTo: false)
          .get();
      return snap.docs.map((d) => _goalFromMap(d.data())).toList();
    }
  }

  /// Real-time stream of habits — use in StreamBuilder for live updates.
  Stream<List<Goal>> habitsStream() {
    return _habitsCol
        .where('archived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _goalFromMap(d.data())).toList());
  }

  /// Deletes a habit document (hard delete).
  Future<void> deleteHabit(String title) async {
    await _habitsCol.doc(_habitDocId(title)).delete();
  }

  // ── Streak reset on app open ─────────────────────────────────────────────────

  /// Call this every time the app comes to the foreground.
  /// For each habit, if yesterday was not logged and the streak is > 0,
  /// it resets the streak to 0 in Firestore and returns the updated list.
  Future<List<Goal>> resetMissedStreaks(List<Goal> goals) async {
    final yesterday = _isoDate(DateTime.now().subtract(const Duration(days: 1)));
    final today = _isoDate(DateTime.now());
    final batch = _db.batch();
    bool anyChanged = false;

    for (final goal in goals) {
      if (goal.currentStreak == 0) continue;

      // If logged today already — streak is fine
      final loggedToday = goal.completionHistory.any((d) => _isoDate(d) == today);
      if (loggedToday) continue;

      // If not logged today AND not logged yesterday — streak is broken
      final loggedYesterday = goal.completionHistory.any((d) => _isoDate(d) == yesterday);
      if (!loggedYesterday) {
        final ref = _habitsCol.doc(_habitDocId(goal.title));
        batch.update(ref, {'currentStreak': 0});
        anyChanged = true;
      }
    }

    if (anyChanged) await batch.commit();
    return goals;
  }

  /// Soft-deletes a habit (archived=true, hidden from the app).
  Future<void> archiveHabit(String title) async {
    await _habitsCol
        .doc(_habitDocId(title))
        .update({'archived': true, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  /// Writes aggregated stats to users/{uid}/stats/summary.
  /// Called after every habit log so the stats doc is always fresh.
  Future<void> updateStats(List<Goal> goals) async {
    final completedToday = goals.where((g) => g.loggedToday).length;
    final completionPct = goals.isEmpty
        ? 0
        : ((completedToday / goals.length) * 100).round();

    final bestStreak = goals.fold(
        0, (best, g) => g.currentStreak > best ? g.currentStreak : best);

    // Week dates Mon–Sun
    final now = DateTime.now();
    final dow = (now.weekday - 1); // 0=Mon
    final weekDates = List.generate(7, (i) {
      return _isoDate(now.subtract(Duration(days: dow - i)));
    });

    final perfectDays = weekDates.where((d) {
      return goals.every((g) =>
          g.completionHistory.any((c) => _isoDate(c) == d));
    }).length;

    final totalEntries = goals.length * 7;
    final completedEntries = goals.fold(0, (acc, g) {
      return acc +
          weekDates
              .where((d) => g.completionHistory.any((c) => _isoDate(c) == d))
              .length;
    });
    final weeklyPct = totalEntries > 0
        ? ((completedEntries / totalEntries) * 100).round()
        : 0;

    await _statsDoc.set({
      'totalHabits': goals.length,
      'completedToday': completedToday,
      'completionPctToday': completionPct,
      'bestStreak': bestStreak,
      'perfectDaysThisWeek': perfectDays,
      'weeklyCompletionPct': weeklyPct,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Reads the stats summary document.
  Future<Map<String, dynamic>> loadStats() async {
    final snap = await _statsDoc.get();
    return snap.data() ?? {};
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  static String _habitDocId(String title) =>
      title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _goalToMap(Goal g) => {
        'title': g.title,
        'description': g.description,
        'targetDays': g.targetDays,
        'currentDays': g.currentDays,
        'category': g.category,
        'colorValue': g.color.toARGB32(),
        'iconCodePoint': g.icon.codePoint,
        'streakGoal': g.streakGoal,
        'lastLoggedDate': g.lastLoggedDate?.toIso8601String(),
        'completionHistory':
            g.completionHistory.map((d) => d.toIso8601String()).toList(),
        'useEmoji': g.useEmoji,
        'selectedEmoji': g.selectedEmoji,
        'trackingMode': g.trackingMode.toString(),
        'customValue': g.customValue,
        'completionsPerDayEnabled': g.completionsPerDayEnabled,
        'completionsPerDay': g.completionsPerDay,
        'completionsTodayCount': g.completionsTodayCount,
        'reminders':
            g.reminders.map((t) => '${t.hour}:${t.minute}').toList(),
        'stackedAfter': g.stackedAfter,
        'archived': false,
        'updatedAt': FieldValue.serverTimestamp(),
        // createdAt is only written on first save (merge: true preserves it)
        'createdAt': FieldValue.serverTimestamp(),
      };

  static Goal _goalFromMap(Map<String, dynamic> m) {
    final trackingMode = (m['trackingMode'] as String? ?? '').contains('customValue')
        ? CompletionTrackingMode.customValue
        : CompletionTrackingMode.stepByStep;

    final reminders = (m['reminders'] as List<dynamic>?)
            ?.map((r) {
              final parts = (r as String).split(':');
              return TimeOfDay(
                  hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            })
            .toList() ??
        [];

    final completionHistory = (m['completionHistory'] as List<dynamic>?)
            ?.map((d) => DateTime.parse(d as String))
            .toList() ??
        [];

    return Goal(
      title: m['title'] as String,
      description: m['description'] as String? ?? '',
      targetDays: m['targetDays'] as int? ?? 30,
      currentDays: m['currentDays'] as int? ?? 0,
      category: m['category'] as String? ?? 'General',
      color: Color(m['colorValue'] as int? ?? 0xFF7C6FD8),
      icon: IconData(m['iconCodePoint'] as int? ?? 0xe3c9,
          fontFamily: 'MaterialIcons'),
      streakGoal: m['streakGoal'] as int?,
      lastLoggedDate: m['lastLoggedDate'] != null
          ? DateTime.parse(m['lastLoggedDate'] as String)
          : null,
      completionHistory: completionHistory,
      useEmoji: m['useEmoji'] as bool? ?? false,
      selectedEmoji: m['selectedEmoji'] as String? ?? '🎯',
      trackingMode: trackingMode,
      customValue: m['customValue'] as int? ?? 1,
      completionsPerDayEnabled: m['completionsPerDayEnabled'] as bool? ?? false,
      completionsPerDay: m['completionsPerDay'] as int? ?? 1,
      completionsTodayCount: m['completionsTodayCount'] as int? ?? 0,
      reminders: reminders,
      stackedAfter: m['stackedAfter'] as String?,
    );
  }
}
