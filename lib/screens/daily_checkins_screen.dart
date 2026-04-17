// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import 'package:habit_tracker/screens/goals_screen.dart' show Goal;

// ─── Enums ───────────────────────────────────────────────────────────────────
enum TimeBlock { morning, afternoon, evening, anytime }

extension TimeBlockX on TimeBlock {
  String get label {
    switch (this) {
      case TimeBlock.morning:   return 'Morning';
      case TimeBlock.afternoon: return 'Afternoon';
      case TimeBlock.evening:   return 'Evening';
      case TimeBlock.anytime:   return 'Anytime';
    }
  }

  IconData get icon {
    switch (this) {
      case TimeBlock.morning:   return Icons.wb_sunny_outlined;
      case TimeBlock.afternoon: return Icons.wb_cloudy_outlined;
      case TimeBlock.evening:   return Icons.bedtime_outlined;
      case TimeBlock.anytime:   return Icons.all_inclusive_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TimeBlock.morning:   return const Color(0xFFFFB830); // amber
      case TimeBlock.afternoon: return const Color(0xFF4DA6FF); // blue
      case TimeBlock.evening:   return const Color(0xFF8B7FFF); // purple
      case TimeBlock.anytime:   return const Color(0xFF00D4A0); // teal
    }
  }
}

// ─── Design System ────────────────────────────────────────────────────────────
class _T {
  final bool isDark;
  const _T(this.isDark);
  static _T of(BuildContext ctx) =>
      _T(Theme.of(ctx).brightness == Brightness.dark);

  Color get bg    => isDark ? const Color(0xFF0C0C14) : const Color(0xFFFAFAF8);
  Color get bg2   => isDark ? const Color(0xFF13131E) : const Color(0xFFFFFFFF);
  Color get txt   => isDark ? const Color(0xFFF2F1F8) : const Color(0xFF0D0D0D);
  Color get txt2  => isDark ? const Color(0xFF8A8AA0) : const Color(0xFF5C5C5C);
  Color get txt3  => isDark ? const Color(0xFF7878A0) : const Color(0xFFA3A3A3);
  Color get border => isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE6E5E0);

  Color get amberBg     => isDark ? const Color(0xFF2E1F00) : const Color(0xFFFFF8E8);
  Color get amberBorder => _T.amber.withOpacity(isDark ? 0.3 : 0.4);

  static const Color amber  = Color(0xFFFFB830);
  static const Color purple = Color(0xFF8B7FFF);
  static const Color teal   = Color(0xFF00D4A0);
  static const Color blue   = Color(0xFF4DA6FF);
  static const Color coral  = Color(0xFFFF6B47);

  static const double s4  = 4;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double r8   = 8;
  static const double r12  = 10;
  static const double r16  = 10;
  static const double r100 = 100;

  TextStyle heading({double size = 24, double spacing = -1.0}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: txt,
          height: 1.1, letterSpacing: spacing);
  TextStyle body({double size = 14, Color? color}) =>
      TextStyle(fontSize: size, color: color ?? txt2, height: 1.6, letterSpacing: -0.1);
  TextStyle label({double size = 11, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500,
          color: color ?? txt3, letterSpacing: 0.06 * size);
}

// ─── Mood ─────────────────────────────────────────────────────────────────────
class _MoodOption {
  final int level;
  final String emoji;
  final String label;
  const _MoodOption(this.level, this.emoji, this.label);

  static const List<_MoodOption> all = [
    _MoodOption(1, '😴', 'Tired'),
    _MoodOption(2, '😕', 'Low'),
    _MoodOption(3, '🙂', 'Okay'),
    _MoodOption(4, '😊', 'Good'),
    _MoodOption(5, '🔥', 'Amazing'),
  ];

  static Color colorFor(int level) {
    switch (level) {
      case 1: return const Color(0xFF6B7280);
      case 2: return const Color(0xFF4DA6FF);
      case 3: return const Color(0xFF00D4A0);
      case 4: return const Color(0xFFFFB830);
      case 5: return const Color(0xFFFF6B47);
      default: return const Color(0xFFFFB830);
    }
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────
class DailyHabit {
  String title;
  String note;
  Color color;
  IconData icon;
  String category;
  TimeBlock timeBlock;
  bool completedToday;
  DateTime? lastCompletedDate;
  List<DateTime> completionHistory;

  DailyHabit({
    required this.title,
    this.note = '',
    required this.color,
    required this.icon,
    this.category = 'General',
    this.timeBlock = TimeBlock.anytime,
    this.completedToday = false,
    this.lastCompletedDate,
    List<DateTime>? completionHistory,
  }) : completionHistory = completionHistory ?? [];

  int get totalDays => completionHistory.length;

  int get currentStreak {
    if (completionHistory.isEmpty) return 0;
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final has = completionHistory.any((c) =>
          c.year == d.year && c.month == d.month && c.day == d.day);
      if (has) {
        count++;
      } else if (i > 0) {
        break;
      }
    }
    return count;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class DailyCheckinsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const DailyCheckinsScreen({super.key, this.onBack});

  @override
  State<DailyCheckinsScreen> createState() => _DailyCheckinsScreenState();
}

class _DailyCheckinsScreenState extends State<DailyCheckinsScreen> {
  final List<DailyHabit> _habits = [];
  // Parallel list of Goal objects used for Firestore persistence.
  // Kept in sync with _habits by index via _goalForHabit().
  final List<Goal> _goals = [];
  final _fs = FirestoreService();
  bool _loadingHabits = true;
  int? _todayMood;

  static const _moodKey     = 'daily_mood';
  static const _moodDateKey = 'daily_mood_date';

  @override
  void initState() {
    super.initState();
    _loadMood();
    _loadHabitsFromFirestore();
  }

  /// Loads persisted habits from Firestore and converts them to DailyHabit
  /// view-models for display. Existing DailyHabit entries created locally
  /// in this session are not overwritten.
  Future<void> _loadHabitsFromFirestore() async {
    try {
      final goals = await _fs.loadHabits();
      if (!mounted) return;
      final today = DateTime.now();
      setState(() {
        _goals.clear();
        _habits.clear();
        for (final g in goals) {
          _goals.add(g);
          _habits.add(DailyHabit(
            title: g.title,
            color: g.color,
            icon: g.icon,
            category: g.category,
            completedToday: g.completionHistory.any((d) =>
                d.year == today.year &&
                d.month == today.month &&
                d.day == today.day),
            lastCompletedDate: g.lastLoggedDate,
            completionHistory: List.of(g.completionHistory),
          ));
        }
        _loadingHabits = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHabits = false);
    }
  }

  /// Returns the Goal that backs the given DailyHabit, looked up by title.
  Goal? _goalForHabit(DailyHabit h) {
    try {
      return _goals.firstWhere((g) => g.title == h.title);
    } catch (_) {
      return null;
    }
  }

  /// Persists a toggled completion back to Firestore.
  Future<void> _persistCompletion(DailyHabit h) async {
    final goal = _goalForHabit(h);
    if (goal == null) return;

    // Mirror the DailyHabit state onto the Goal
    goal.completionHistory
      ..clear()
      ..addAll(h.completionHistory);
    goal.lastLoggedDate = h.lastCompletedDate;

    // Recompute currentDays from total unique logged days
    goal.currentDays = goal.completionHistory
        .map((d) => '${d.year}-${d.month}-${d.day}')
        .toSet()
        .length;

    try {
      await _fs.saveHabit(goal);
      await _fs.updateStats(_goals);
    } catch (_) {
      // Non-fatal: local state already reflects the toggle
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadMood() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_moodDateKey);
    if (saved == _dateKey(DateTime.now())) {
      final mood = prefs.getInt(_moodKey);
      if (mounted && mood != null) setState(() => _todayMood = mood);
    }
  }

  Future<void> _persistMood(int mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_moodKey, mood);
    await prefs.setString(_moodDateKey, _dateKey(DateTime.now()));
  }

  void _setMood(int mood) {
    setState(() => _todayMood = mood);
    _persistMood(mood);
  }

  void _toggleComplete(DailyHabit h) {
    setState(() {
      h.completedToday = !h.completedToday;
      if (h.completedToday) {
        h.lastCompletedDate = DateTime.now();
        h.completionHistory.add(DateTime.now());
      } else {
        final now = DateTime.now();
        h.completionHistory.removeWhere((d) =>
            d.year == now.year && d.month == now.month && d.day == now.day);
        h.lastCompletedDate = null;
      }
    });
    _persistCompletion(h);
  }

  void _deleteHabit(DailyHabit h) => setState(() => _habits.remove(h));

  void _confirmDelete(DailyHabit h) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${h.title}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () { Navigator.pop(context); _deleteHabit(h); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdd() async {
    final result = await showModalBottomSheet<DailyHabit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewHabitSheet(),
    );
    if (result != null) setState(() => _habits.add(result));
  }

  Future<void> _openEdit(DailyHabit h) async {
    final updated = await showModalBottomSheet<DailyHabit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewHabitSheet(existing: h),
    );
    if (updated != null) {
      setState(() {
        h.title     = updated.title;
        h.note      = updated.note;
        h.color     = updated.color;
        h.icon      = updated.icon;
        h.category  = updated.category;
        h.timeBlock = updated.timeBlock;
      });
    }
  }

  void _showMenu(DailyHabit h) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(h.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _openEdit(h); },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () { Navigator.pop(context); _confirmDelete(h); },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final completed = _habits.where((h) => h.completedToday).length;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg2,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t.txt, size: 18),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LogoMark(size: 22),
            const SizedBox(width: _T.s8),
            Text('Daily Check-in',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                    color: t.txt, letterSpacing: -0.4)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: t.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AddBtn(onTap: _openAdd),
          ),
        ],
      ),
      body: _loadingHabits
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? _buildEmpty()
              : _buildBody(completed),
    );
  }

  Widget _buildEmpty() {
    final t = _T.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: t.amberBg,
                borderRadius: BorderRadius.circular(_T.r16),
                border: Border.all(color: t.amberBorder),
              ),
              child: const Icon(Icons.wb_sunny_outlined, color: _T.amber, size: 32),
            ),
            const SizedBox(height: _T.s20),
            Text('Build your daily ritual', style: t.heading(size: 22)),
            const SizedBox(height: _T.s8),
            Text(
              'Organize habits by Morning, Afternoon, and Evening to create a consistent daily rhythm.',
              textAlign: TextAlign.center,
              style: t.body(size: 14),
            ),
            const SizedBox(height: _T.s32),
            _PrimaryBtn(label: 'Add first habit', onTap: _openAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(int completed) {
    final t = _T.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date + progress ring ──
          _TodayBanner(total: _habits.length, completed: completed),
          Divider(height: 1, thickness: 1, color: t.border),

          // ── Mood selector ──
          _MoodSelector(selectedMood: _todayMood, onSelect: _setMood),
          Divider(height: 1, thickness: 1, color: t.border),

          // ── Time-block sections ──
          ...TimeBlock.values.map((block) {
            final blockHabits = _habits.where((h) => h.timeBlock == block).toList();
            if (blockHabits.isEmpty) return const SizedBox.shrink();
            return _TimeBlockSection(
              block: block,
              habits: blockHabits,
              onToggle: _toggleComplete,
              onEdit: _openEdit,
              onLongPress: _showMenu,
            );
          }),

          // ── 28-day heatmap ──
          Divider(height: 1, thickness: 1, color: t.border),
          _HeatmapSection(habits: _habits),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Today Banner ─────────────────────────────────────────────────────────────
class _TodayBanner extends StatelessWidget {
  final int total, completed;
  const _TodayBanner({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final now = DateTime.now();
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months   = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final remaining = total - completed;
    final subtitle = total == 0
        ? 'Add your first habit below'
        : completed == total
            ? 'All done — great work today!'
            : '$remaining habit${remaining == 1 ? '' : 's'} remaining';

    return Container(
      color: t.bg2,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weekdays[now.weekday - 1].toUpperCase(),
                    style: t.label(size: 11, color: _T.amber)),
                const SizedBox(height: 4),
                Text('${months[now.month - 1]} ${now.day}', style: t.heading(size: 30)),
                const SizedBox(height: 6),
                Text(subtitle, style: t.body(size: 13)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _ProgressRing(
            progress: total == 0 ? 0.0 : completed / total,
            completed: completed,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final int completed, total;
  const _ProgressRing({required this.progress, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return SizedBox(
      width: 72, height: 72,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(progress: progress, trackColor: t.border, fillColor: _T.amber),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$completed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                        color: _T.amber, letterSpacing: -0.8, height: 1)),
                Text('/ $total', style: t.label(size: 10, color: t.txt3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor, fillColor;
  const _RingPainter({required this.progress, required this.trackColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    canvas.drawCircle(center, radius,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = 5);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5707963, progress * 6.2831853, false,
        Paint()
          ..color = fillColor..style = PaintingStyle.stroke
          ..strokeWidth = 5..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.trackColor != trackColor || old.fillColor != fillColor;
}

// ─── Mood Selector ────────────────────────────────────────────────────────────
class _MoodSelector extends StatelessWidget {
  final int? selectedMood;
  final void Function(int) onSelect;
  const _MoodSelector({required this.selectedMood, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Container(
      color: t.bg2,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today?',
              style: t.label(size: 11, color: t.txt2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _MoodOption.all.map((m) {
              final sel = selectedMood == m.level;
              final col = _MoodOption.colorFor(m.level);
              return GestureDetector(
                onTap: () => onSelect(m.level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? col.withOpacity(0.13) : Colors.transparent,
                    borderRadius: BorderRadius.circular(_T.r8),
                    border: Border.all(
                      color: sel ? col : t.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(m.label,
                          style: t.label(size: 9, color: sel ? col : t.txt3)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Time Block Section ───────────────────────────────────────────────────────
class _TimeBlockSection extends StatefulWidget {
  final TimeBlock block;
  final List<DailyHabit> habits;
  final void Function(DailyHabit) onToggle;
  final void Function(DailyHabit) onEdit;
  final void Function(DailyHabit) onLongPress;

  const _TimeBlockSection({
    required this.block,
    required this.habits,
    required this.onToggle,
    required this.onEdit,
    required this.onLongPress,
  });

  @override
  State<_TimeBlockSection> createState() => _TimeBlockSectionState();
}

class _TimeBlockSectionState extends State<_TimeBlockSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final block = widget.block;
    final color = block.color;
    final done  = widget.habits.where((h) => h.completedToday).length;
    final total = widget.habits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Block header ──
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            color: t.bg,
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(_T.r8),
                  ),
                  child: Icon(block.icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(block.label,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: t.txt, letterSpacing: -0.2)),
                      Text('$done / $total done',
                          style: t.label(size: 10, color: color)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 4,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: t.txt3, size: 20),
                ),
              ],
            ),
          ),
        ),
        // ── Habit cards ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: widget.habits.map((h) => _CheckinCard(
              key: ValueKey(h.hashCode),
              habit: h,
              blockColor: block.color,
              onToggle: () => widget.onToggle(h),
              onEdit: () => widget.onEdit(h),
              onLongPress: () => widget.onLongPress(h),
            )).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        Divider(height: 1, thickness: 1, color: t.border),
      ],
    );
  }
}

// ─── Checkin Card ─────────────────────────────────────────────────────────────
class _CheckinCard extends StatefulWidget {
  final DailyHabit habit;
  final Color blockColor;
  final VoidCallback onToggle, onEdit, onLongPress;

  const _CheckinCard({
    super.key,
    required this.habit,
    required this.blockColor,
    required this.onToggle,
    required this.onEdit,
    required this.onLongPress,
  });

  @override
  State<_CheckinCard> createState() => _CheckinCardState();
}

class _CheckinCardState extends State<_CheckinCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final h    = widget.habit;
    final done = h.completedToday;
    final streak = h.currentStreak;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: done ? widget.blockColor.withOpacity(0.06) : t.bg2,
          borderRadius: BorderRadius.circular(_T.r12),
          border: Border.all(
              color: done ? widget.blockColor.withOpacity(0.3) : t.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Animated circular checkbox ──
            GestureDetector(
              onTap: _tap,
              child: ScaleTransition(
                scale: _scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? h.color : Colors.transparent,
                    border: Border.all(
                      color: done ? h.color : t.txt3,
                      width: done ? 0 : 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Habit icon ──
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: h.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(_T.r8),
              ),
              child: Icon(h.icon, color: h.color, size: 17),
            ),
            const SizedBox(width: 12),
            // ── Title + note ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: done ? t.txt2 : t.txt,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: t.txt3,
                          letterSpacing: -0.3)),
                  if (h.note.isNotEmpty)
                    Text(h.note,
                        style: t.body(size: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // ── Streak badge ──
            if (streak > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: h.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(_T.r100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 12, color: h.color),
                    const SizedBox(width: 3),
                    Text('$streak',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: h.color)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 28-Day Heatmap ───────────────────────────────────────────────────────────
class _HeatmapSection extends StatelessWidget {
  final List<DailyHabit> habits;
  const _HeatmapSection({required this.habits});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 27));

    return Container(
      color: t.bg2,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('28-Day Consistency',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: t.txt, letterSpacing: -0.2)),
              Text('last 4 weeks', style: t.label(size: 10)),
            ],
          ),
          const SizedBox(height: 14),
          // Day-of-week labels
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) =>
              Expanded(child: Center(child: Text(d, style: t.label(size: 9))))).toList(),
          ),
          const SizedBox(height: 6),
          // 4 weeks × 7 days
          ...List.generate(4, (week) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (dow) {
                final date    = start.add(Duration(days: week * 7 + dow));
                final isFuture = date.isAfter(today);
                final isToday  = date == today;

                double ratio = 0;
                if (!isFuture && habits.isNotEmpty) {
                  final count = habits.where((h) =>
                    h.completionHistory.any((d) =>
                      d.year == date.year && d.month == date.month && d.day == date.day)
                  ).length;
                  ratio = count / habits.length;
                }

                final Color cell;
                if (isFuture) {
                  cell = Colors.transparent;
                } else if (ratio == 0) {
                  cell = t.border;
                } else if (ratio < 0.34) {
                  cell = _T.amber.withOpacity(0.25);
                } else if (ratio < 0.67) {
                  cell = _T.amber.withOpacity(0.55);
                } else {
                  cell = _T.amber;
                }

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 24,
                    decoration: BoxDecoration(
                      color: cell,
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                          ? Border.all(color: _T.amber, width: 1.5)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          )),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              Text('Less', style: t.label(size: 9)),
              const SizedBox(width: 6),
              ...[0.0, 0.25, 0.55, 1.0].map((op) => Container(
                width: 14, height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: op == 0 ? t.border : _T.amber.withOpacity(op),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
              Text('More', style: t.label(size: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Primitives ───────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          color: t.txt, borderRadius: BorderRadius.circular(size * 0.22)),
      child: Center(
        child: Container(
          width: size * 0.30, height: size * 0.30,
          decoration: BoxDecoration(color: t.bg2, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _AddBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});

  @override
  State<_AddBtn> createState() => _AddBtnState();
}

class _AddBtnState extends State<_AddBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: t.txt, borderRadius: BorderRadius.circular(_T.r8)),
          child: Text('Add', style: t.label(size: 12, color: t.bg2)),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(color: t.txt, borderRadius: BorderRadius.circular(_T.r8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: t.bg2, letterSpacing: -0.3)),
              const SizedBox(width: _T.s8),
              Icon(Icons.arrow_forward, size: 13, color: t.bg2),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── New / Edit Habit Sheet ───────────────────────────────────────────────────
class NewHabitSheet extends StatefulWidget {
  final DailyHabit? existing;
  const NewHabitSheet({super.key, this.existing});

  @override
  State<NewHabitSheet> createState() => _NewHabitSheetState();
}

class _NewHabitSheetState extends State<NewHabitSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _noteCtrl;
  late int _colorIdx;
  late int _iconIdx;
  late String _category;
  late TimeBlock _timeBlock;

  bool get _isEdit => widget.existing != null;

  static const List<Color> _colors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B),
    Color(0xFF22C55E), Color(0xFF10B981), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFEC4899),
    Color(0xFF06B6D4), Color(0xFF14B8A6), Color(0xFF64748B),
  ];

  static const List<IconData> _icons = [
    Icons.wb_sunny_outlined,     Icons.fitness_center_outlined,
    Icons.directions_run_outlined, Icons.directions_bike_outlined,
    Icons.pool_outlined,          Icons.sports_martial_arts_outlined,
    Icons.self_improvement_outlined, Icons.monitor_heart_outlined,
    Icons.medication_outlined,    Icons.restaurant_outlined,
    Icons.water_drop_outlined,    Icons.coffee_outlined,
    Icons.no_food_outlined,       Icons.apple_outlined,
    Icons.menu_book_outlined,     Icons.psychology_outlined,
    Icons.school_outlined,        Icons.lightbulb_outline,
    Icons.edit_note_outlined,     Icons.wb_sunny_outlined,
    Icons.bedtime_outlined,       Icons.alarm_outlined,
    Icons.shower_outlined,        Icons.cleaning_services_outlined,
    Icons.brush_outlined,         Icons.music_note_outlined,
    Icons.camera_alt_outlined,    Icons.palette_outlined,
    Icons.code_outlined,          Icons.laptop_outlined,
    Icons.work_outline,           Icons.savings_outlined,
    Icons.favorite_outline,       Icons.people_outline,
    Icons.volunteer_activism_outlined, Icons.eco_outlined,
    Icons.star_outline,           Icons.emoji_events_outlined,
    Icons.local_fire_department_rounded, Icons.bolt_outlined,
  ];

  static const List<String> _categories = [
    'None', 'Health', 'Fitness', 'Learning',
    'Finance', 'Mindfulness', 'Creativity', 'Social', 'Productivity', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl  = TextEditingController(text: e?.title ?? '');
    _noteCtrl  = TextEditingController(text: e?.note  ?? '');
    _category  = e?.category ?? 'None';
    _timeBlock = e?.timeBlock ?? TimeBlock.morning;
    _colorIdx  = e != null
        ? (_colors.indexWhere((c) => c.value == e.color.value).let((i) => i < 0 ? 0 : i))
        : 0;
    _iconIdx   = e != null
        ? (_icons.indexOf(e.icon).let((i) => i < 0 ? 0 : i))
        : 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      final t = _T.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a name', style: t.body(color: Colors.white)),
        backgroundColor: t.txt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r8)),
      ));
      return;
    }
    Navigator.pop(context, DailyHabit(
      title:     name,
      note:      _noteCtrl.text.trim(),
      color:     _colors[_colorIdx],
      icon:      _icons[_iconIdx],
      category:  _category == 'None' ? 'General' : _category,
      timeBlock: _timeBlock,
      completedToday:    widget.existing?.completedToday    ?? false,
      lastCompletedDate: widget.existing?.lastCompletedDate,
      completionHistory: widget.existing?.completionHistory ?? [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = _colors[_colorIdx];

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              color: t.bg2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(_T.r8)),
                    child: Text('Cancel', style: t.body(size: 13)),
                  ),
                ),
                Expanded(
                  child: Text(_isEdit ? 'Edit Habit' : 'New Habit',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                          color: t.txt, letterSpacing: -0.3)),
                ),
                const SizedBox(width: 70),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Live preview ──
                  Container(
                    color: t.bg2,
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                    child: Center(
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_T.r16),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Icon(_icons[_iconIdx], color: accent, size: 32),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: t.border),
                  const SizedBox(height: _T.s16),

                  // ── Name ──
                  _FormSection(label: 'Name', child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('e.g. Morning Meditation'),
                  )),
                  const SizedBox(height: _T.s16),

                  // ── Note ──
                  _FormSection(label: 'Note (optional)', child: TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('A quick reminder or intention...'),
                  )),
                  const SizedBox(height: _T.s16),

                  // ── Time Block ──
                  Container(
                    color: t.bg2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time of Day',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.txt)),
                        const SizedBox(height: 12),
                        Row(
                          children: TimeBlock.values.map((block) {
                            final sel = _timeBlock == block;
                            final col = block.color;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _timeBlock = block),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? col.withOpacity(0.13) : t.bg,
                                    borderRadius: BorderRadius.circular(_T.r8),
                                    border: Border.all(
                                      color: sel ? col : t.border,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(block.icon, size: 18,
                                          color: sel ? col : t.txt3),
                                      const SizedBox(height: 4),
                                      Text(block.label,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: sel ? col : t.txt3)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _T.s16),

                  // ── Icon picker ──
                  Container(
                    color: t.bg2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Icon',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.txt)),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                          itemCount: _icons.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setState(() => _iconIdx = i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == _iconIdx ? accent.withOpacity(0.12) : t.bg,
                                borderRadius: BorderRadius.circular(_T.r8),
                                border: i == _iconIdx
                                    ? Border.all(color: accent, width: 1.5)
                                    : Border.all(color: t.border),
                              ),
                              child: Icon(_icons[i],
                                  color: i == _iconIdx ? accent : t.txt3, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _T.s16),

                  // ── Color picker ──
                  Container(
                    color: t.bg2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Color',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.txt)),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                          itemCount: _colors.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setState(() => _colorIdx = i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _colors[i],
                                borderRadius: BorderRadius.circular(_T.r8),
                                border: i == _colorIdx
                                    ? Border.all(color: t.txt, width: 2) : null,
                              ),
                              child: i == _colorIdx
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _T.s32),
                ],
              ),
            ),
          ),

          // ── Save button ──
          Container(
            decoration: BoxDecoration(
              color: t.bg2,
              border: Border(top: BorderSide(color: t.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: t.txt, borderRadius: BorderRadius.circular(_T.r8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isEdit ? 'Save Changes' : 'Create Habit',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                                color: t.bg2, letterSpacing: -0.3)),
                        const SizedBox(width: _T.s8),
                        Icon(Icons.arrow_forward, size: 13, color: t.bg2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    final t = _T.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: t.body(size: 14, color: t.txt3),
      filled: true,
      fillColor: t.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r8),
          borderSide: BorderSide(color: t.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r8),
          borderSide: BorderSide(color: t.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r8),
          borderSide: BorderSide(color: t.txt, width: 1.5)),
    );
  }
}

// ─── Form Section ─────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Container(
      color: t.bg2,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: t.txt2, fontWeight: FontWeight.w400)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ─── Extension helper ─────────────────────────────────────────────────────────
extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
