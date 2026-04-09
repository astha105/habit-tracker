// ignore_for_file: deprecated_member_use, unused_element, unused_field, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─── Enums ────────────────────────────────────────────────────────────────────
enum CompletionTrackingMode { stepByStep, customValue }

// ─── Data model ───────────────────────────────────────────────────────────────
class Goal {
  String title;
  String description;
  int targetDays;
  int currentDays;
  String category;
  Color color;
  IconData icon;
  int? streakGoal;
  DateTime? lastLoggedDate;
  List<DateTime> completionHistory;
  bool useEmoji;
  String selectedEmoji;

  // ── Advanced options ──
  CompletionTrackingMode trackingMode;
  int customValue;
  bool completionsPerDayEnabled;
  int completionsPerDay;
  int completionsTodayCount;
  TimeOfDay? reminderTime;
  List<TimeOfDay> reminders;

  Goal({
    required this.title,
    required this.description,
    required this.targetDays,
    required this.currentDays,
    required this.category,
    required this.color,
    required this.icon,
    this.streakGoal,
    this.lastLoggedDate,
    List<DateTime>? completionHistory,
    this.useEmoji = false,
    this.selectedEmoji = '🎯',
    this.trackingMode = CompletionTrackingMode.stepByStep,
    this.customValue = 1,
    this.completionsPerDayEnabled = false,
    this.completionsPerDay = 1,
    this.completionsTodayCount = 0,
    this.reminderTime,
    List<TimeOfDay>? reminders,
  })  : completionHistory = completionHistory ?? [],
        reminders = reminders ?? [];

  bool get loggedToday {
    if (lastLoggedDate == null) return false;
    final now = DateTime.now();
    return lastLoggedDate!.year == now.year &&
        lastLoggedDate!.month == now.month &&
        lastLoggedDate!.day == now.day;
  }

  bool get isCompleted => currentDays >= targetDays;

  bool get dailyTargetMet {
    if (!completionsPerDayEnabled) return loggedToday;
    return loggedToday && completionsTodayCount >= completionsPerDay;
  }

  String get nextLogAvailable {
    if (lastLoggedDate == null) return '';
    final next = lastLoggedDate!.add(const Duration(hours: 24));
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return 'Available in ${h}h ${m}m';
    return 'Available in ${m}m';
  }

  int get currentStreak {
    if (completionHistory.isEmpty) return 0;
    final sorted = completionHistory.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (final d in sorted) {
      if (d == check || d == check.subtract(const Duration(days: 1))) {
        streak++;
        check = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

// ─── Goals Storage Service ────────────────────────────────────────────────────
class GoalsStorageService {
  static const String _key = 'goals_data';
  
  static Future<void> saveGoals(List<Goal> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = goals.map((g) => _goalToJson(g)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
      print('✓ Goals saved (${goals.length} goals)');
    } catch (e) {
      print('✗ Error saving goals: $e');
    }
  }

  static Future<List<Goal>> loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return [];
      
      final jsonList = jsonDecode(jsonStr) as List;
      final goals = jsonList.map((json) => _goalFromJson(json)).toList();
      print('✓ Goals loaded (${goals.length} goals)');
      return goals;
    } catch (e) {
      print('✗ Error loading goals: $e');
      return [];
    }
  }

  static Map<String, dynamic> _goalToJson(Goal g) => {
    'title': g.title,
    'description': g.description,
    'targetDays': g.targetDays,
    'currentDays': g.currentDays,
    'category': g.category,
    'colorValue': g.color.value,
    'iconCodePoint': g.icon.codePoint,
    'streakGoal': g.streakGoal,
    'lastLoggedDate': g.lastLoggedDate?.toIso8601String(),
    'completionHistory': g.completionHistory.map((d) => d.toIso8601String()).toList(),
    'useEmoji': g.useEmoji,
    'selectedEmoji': g.selectedEmoji,
    'trackingMode': g.trackingMode.toString(),
    'customValue': g.customValue,
    'completionsPerDayEnabled': g.completionsPerDayEnabled,
    'completionsPerDay': g.completionsPerDay,
    'completionsTodayCount': g.completionsTodayCount,
    'reminders': g.reminders.map((t) => '${t.hour}:${t.minute}').toList(),
  };

  static Goal _goalFromJson(Map<String, dynamic> json) {
    final trackingModeStr = json['trackingMode'] as String? ?? 'CompletionTrackingMode.stepByStep';
    final trackingMode = trackingModeStr.contains('customValue')
        ? CompletionTrackingMode.customValue
        : CompletionTrackingMode.stepByStep;

    final reminders = (json['reminders'] as List<dynamic>?)
        ?.map((r) {
          final parts = (r as String).split(':');
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        })
        .toList() ?? [];

    final completionHistory = (json['completionHistory'] as List<dynamic>?)
        ?.map((d) => DateTime.parse(d as String))
        .toList() ?? [];

    return Goal(
      title: json['title'] as String,
      description: json['description'] as String? ?? 'No description',
      targetDays: json['targetDays'] as int? ?? 30,
      currentDays: json['currentDays'] as int? ?? 0,
      category: json['category'] as String? ?? 'General',
      color: Color(json['colorValue'] as int? ?? 0xFF3B82F6),
      icon: IconData(json['iconCodePoint'] as int? ?? 0xf0818, fontFamily: 'MaterialIcons'),
      streakGoal: json['streakGoal'] as int?,
      lastLoggedDate: json['lastLoggedDate'] != null
          ? DateTime.parse(json['lastLoggedDate'] as String)
          : null,
      completionHistory: completionHistory,
      useEmoji: json['useEmoji'] as bool? ?? false,
      selectedEmoji: json['selectedEmoji'] as String? ?? '🎯',
      trackingMode: trackingMode,
      customValue: json['customValue'] as int? ?? 1,
      completionsPerDayEnabled: json['completionsPerDayEnabled'] as bool? ?? false,
      completionsPerDay: json['completionsPerDay'] as int? ?? 1,
      completionsTodayCount: json['completionsTodayCount'] as int? ?? 0,
      reminders: reminders,
    );
  }
}

// ─── Design Tokens (mirrors landing screen _T) ────────────────────────────────
class _T {
  _T._();
  static const Color ink      = Color(0xFF0D0D0D);
  static const Color ink2     = Color(0xFF5C5C5C);
  static const Color ink3     = Color(0xFFA3A3A3);
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color canvas   = Color(0xFFFAFAF8);
  static const Color border   = Color(0xFFE6E5E0);

  static const Color purple       = Color(0xFF7C6FD8);
  static const Color purpleDark   = Color(0xFF534AB7);
  static const Color purpleDeep   = Color(0xFF3C3489);
  static const Color purpleBg     = Color(0xFFF0EDFE);
  static const Color purpleBorder = Color(0xFFC8C0F8);

  static const Color coral       = Color(0xFFD85A30);
  static const Color coralDark   = Color(0xFF993C1D);
  static const Color coralBg     = Color(0xFFFEF0E8);
  static const Color coralBorder = Color(0xFFF5C4B3);

  static const Color teal       = Color(0xFF1D9E75);
  static const Color tealDark   = Color(0xFF0F6E56);
  static const Color tealBg     = Color(0xFFEBF8F2);
  static const Color tealBorder = Color(0xFF9FE1CB);

  static const Color blue       = Color(0xFF378ADD);
  static const Color blueDark   = Color(0xFF185FA5);
  static const Color blueBg     = Color(0xFFEBF3FD);
  static const Color blueBorder = Color(0xFFB5D4F4);

  static const Color amber       = Color(0xFFBA7517);
  static const Color amberBg     = Color(0xFFFEF5E7);
  static const Color amberBorder = Color(0xFFFAC775);

  static const double s4  = 4;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s64 = 64;

  static const double r8   = 8;
  static const double r12  = 12;
  static const double r16  = 16;
  static const double r100 = 100;

  static TextStyle heading({double size = 24, double spacing = -1.0}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: ink,
          height: 1.1, letterSpacing: spacing);

  static TextStyle body({double size = 14, Color? color}) =>
      TextStyle(fontSize: size, color: color ?? ink2, height: 1.6, letterSpacing: -0.1);

  static TextStyle label({double size = 11, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500,
          color: color ?? ink3, letterSpacing: 0.06 * size);
}

// ─── Goals Screen ─────────────────────────────────────────────────────────────
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final loaded = await GoalsStorageService.loadGoals();
      if (mounted) {
        setState(() {
          _goals.addAll(loaded);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading goals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveGoals() async {
    await GoalsStorageService.saveGoals(_goals);
  }

  void _deleteGoal(Goal goal) {
    final index = _goals.indexOf(goal);
    setState(() => _goals.remove(goal));
    _saveGoals();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text('"${goal.title}" deleted',
              style: _T.body(color: Colors.white)),
          backgroundColor: _T.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r8)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: _T.purple,
            onPressed: () {
              setState(() => _goals.insert(index, goal));
              _saveGoals();
            },
          ),
        ),
      );
    });
  }

  void _confirmDelete(Goal goal) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteGoal(goal);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdd() async {
    final newGoal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GoalSheet(),
    );
    if (newGoal != null) {
      setState(() => _goals.add(newGoal));
      _saveGoals();
    }
  }

  Future<void> _openEdit(Goal goal) async {
    final updated = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalSheet(existing: goal),
    );
    if (updated != null) {
      setState(() {
        goal.title = updated.title;
        goal.description = updated.description;
        goal.color = updated.color;
        goal.icon = updated.icon;
        goal.category = updated.category;
        goal.targetDays = updated.targetDays;
        goal.streakGoal = updated.streakGoal;
        goal.trackingMode = updated.trackingMode;
        goal.customValue = updated.customValue;
        goal.completionsPerDayEnabled = updated.completionsPerDayEnabled;
        goal.completionsPerDay = updated.completionsPerDay;
        goal.reminders = updated.reminders;
        goal.useEmoji = updated.useEmoji;
        goal.selectedEmoji = updated.selectedEmoji;
      });
      _saveGoals();
    }
  }

  void _showContextMenu(BuildContext context, Goal goal) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(goal.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _openEdit(goal); },
            child: const Text('Edit Goal'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () { Navigator.pop(context); _confirmDelete(goal); },
            child: const Text('Delete Goal'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _logDay(Goal g) {
    setState(() {
      final now = DateTime.now();
      final wasLoggedToday = g.loggedToday;
      if (g.completionsPerDayEnabled) {
        if (!wasLoggedToday) {
          g.completionsTodayCount = 1;
        } else {
          g.completionsTodayCount++;
        }
        if (g.completionsTodayCount == g.completionsPerDay) {
          g.currentDays++;
          g.completionHistory.add(now);
        }
      } else {
        g.currentDays++;
        g.completionHistory.add(now);
      }
      g.lastLoggedDate = now;
    });
    _saveGoals();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _T.canvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _T.purpleBg,
                  borderRadius: BorderRadius.circular(_T.r16),
                  border: Border.all(color: _T.purpleBorder),
                ),
                child: const Icon(Icons.flag_outlined, color: _T.purple, size: 28),
              ),
              const SizedBox(height: _T.s16),
              Text('Loading goals...', style: _T.body(size: 14)),
            ],
          ),
        ),
      );
    }

    final active    = _goals.where((g) => !g.isCompleted).toList();
    final completed = _goals.where((g) => g.isCompleted).toList();

    return Scaffold(
      backgroundColor: _T.canvas,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _T.ink, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LogoMark(size: 22),
            const SizedBox(width: _T.s8),
            Text('Goals',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _T.ink,
                    letterSpacing: -0.4)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _T.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AddBtn(onTap: _openAdd),
          ),
        ],
      ),
      body: _goals.isEmpty ? _buildEmpty() : _buildList(active, completed),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _T.purpleBg,
                borderRadius: BorderRadius.circular(_T.r16),
                border: Border.all(color: _T.purpleBorder),
              ),
              child: const Icon(Icons.flag_outlined, color: _T.purple, size: 32),
            ),
            const SizedBox(height: _T.s20),
            Text('No goals yet', style: _T.heading(size: 22)),
            const SizedBox(height: _T.s8),
            Text(
              'Tap "Add" to create your first goal and start making progress.',
              textAlign: TextAlign.center,
              style: _T.body(size: 14),
            ),
            const SizedBox(height: _T.s32),
            _PrimaryBtn(label: 'Add your first goal', onTap: _openAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Goal> active, List<Goal> completed) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryStrip(active: active.length, completed: completed.length),
          Divider(height: 1, thickness: 1, color: _T.border),

          if (active.isNotEmpty) ...[
            _SectionHeader(label: 'In Progress', pill: true),
            if (active.isNotEmpty)
              _TopGoalCard(
                goal: active.first,
                onEdit: () => _openEdit(active.first),
                onDelete: () => _confirmDelete(active.first),
                onLongPress: () => _showContextMenu(context, active.first),
                onLogDay: active.first.dailyTargetMet ? null : () => _logDay(active.first),
              ),
            if (active.length > 1) ...[
              ...active.skip(1).map((g) => _SwipeCard(
                key: ValueKey(g.hashCode),
                goal: g,
                onEdit: () => _openEdit(g),
                onDelete: () => _confirmDelete(g),
                onLongPress: () => _showContextMenu(context, g),
                onLogDay: g.dailyTargetMet ? null : () => _logDay(g),
              )),
            ],
          ],

          if (completed.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: _T.border),
            _SectionHeader(label: 'Completed', pill: false, completed: true),
            ...completed.map((g) => _SwipeCard(
              key: ValueKey(g.hashCode),
              goal: g,
              onEdit: () => _openEdit(g),
              onDelete: () => _confirmDelete(g),
              onLongPress: () => _showContextMenu(context, g),
              onLogDay: null,
            )),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Summary Strip (mirrors landing _StatsStrip) ──────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int active, completed;
  const _SummaryStrip({required this.active, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _SummaryCell(
              icon: Icons.radio_button_checked_outlined,
              value: '$active',
              label: 'Active',
              iconBg: _T.purpleBg,
              iconColor: _T.purple,
              valueColor: _T.purpleDeep,
              labelColor: _T.purple,
            )),
            VerticalDivider(width: 1, thickness: 1, color: _T.border),
            Expanded(child: _SummaryCell(
              icon: Icons.emoji_events_outlined,
              value: '$completed',
              label: 'Completed',
              iconBg: _T.tealBg,
              iconColor: _T.teal,
              valueColor: _T.tealDark,
              labelColor: _T.teal,
            )),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color iconBg, iconColor, valueColor, labelColor;
  const _SummaryCell({
    required this.icon, required this.value, required this.label,
    required this.iconBg, required this.iconColor,
    required this.valueColor, required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(_T.r8)),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: _T.s12),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                  letterSpacing: -1.2)),
          const SizedBox(height: 3),
          Text(label, style: _T.label(size: 11, color: labelColor)),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool pill;
  final bool completed;
  const _SectionHeader({required this.label, this.pill = false, this.completed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.canvas,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: pill
          ? _EyebrowPill(
              label: label.toUpperCase(),
              bg: _T.purpleBg,
              border: _T.purpleBorder,
              dot: _T.purple,
              text: _T.purpleDark,
            )
          : _EyebrowPill(
              label: label.toUpperCase(),
              bg: _T.tealBg,
              border: _T.tealBorder,
              dot: _T.teal,
              text: _T.tealDark,
            ),
    );
  }
}

// ─── Swipeable card wrapper ────────────────────────────────────────────────────
class _SwipeCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onLogDay;
  final VoidCallback onEdit, onDelete, onLongPress;

  const _SwipeCard({
    super.key,
    required this.goal,
    required this.onLogDay,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${goal.hashCode}'),
      background: _SwipeBg(
          color: _T.blue, icon: Icons.edit_outlined,
          label: 'Edit', alignment: Alignment.centerLeft),
      secondaryBackground: _SwipeBg(
          color: _T.coral, icon: Icons.delete_outline,
          label: 'Delete', alignment: Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onEdit();
        } else {
          onDelete();
        }
        return false;
      },
      child: GestureDetector(
        onLongPress: onLongPress,
        child: _GoalCard(goal: goal, onLogDay: onLogDay),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;
  const _SwipeBg({required this.color, required this.icon, required this.label, required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(_T.r12)),
      alignment: alignment,
      padding: EdgeInsets.only(left: isLeft ? 20 : 0, right: isLeft ? 0 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(label, style: _T.label(size: 11, color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Top Goal Hero Card ────────────────────────────────────────────────────────
class _TopGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onLogDay;
  final VoidCallback onEdit, onDelete, onLongPress;

  const _TopGoalCard({
    required this.goal,
    required this.onLogDay,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal.currentDays / goal.targetDays).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    String logLabel;
    if (goal.completionsPerDayEnabled && goal.loggedToday && !goal.dailyTargetMet) {
      logLabel = '${goal.completionsTodayCount}/${goal.completionsPerDay} today — Log More';
    } else if (goal.dailyTargetMet) {
      logLabel = goal.nextLogAvailable.isEmpty ? '✓ Logged Today' : goal.nextLogAvailable;
    } else {
      logLabel = '+ Log Day';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: _T.ink,
            borderRadius: BorderRadius.circular(_T.r16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: goal.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_T.r8),
                        border: Border.all(color: goal.color.withOpacity(0.4))),
                    child: goal.useEmoji
                        ? Center(child: Text(goal.selectedEmoji, style: const TextStyle(fontSize: 24)))
                        : Icon(goal.icon, color: goal.color, size: 22),
                  ),
                  const SizedBox(width: _T.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _T.surface,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(goal.category,
                              style: _T.label(size: 11, color: const Color(0xFF888888))),
                          if (goal.streakGoal != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: _T.coralBg.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: _T.coral.withOpacity(0.3))),
                              child: Text('🔥 ${goal.currentStreak}d',
                                  style: _T.label(size: 10, color: _T.coral)),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  _IconActionBtn(icon: Icons.edit_outlined, onTap: onEdit),
                  const SizedBox(width: _T.s8),
                  _IconActionBtn(icon: Icons.delete_outline, onTap: onDelete),
                ],
              ),

              const SizedBox(height: _T.s24),

              Row(children: [
                _HeroBadge(value: '${goal.currentDays}d', sub: 'done'),
                const SizedBox(width: _T.s8),
                _HeroBadge(value: '${goal.targetDays}d', sub: 'target'),
                const SizedBox(width: _T.s8),
                _HeroBadge(value: '${goal.targetDays - goal.currentDays}d', sub: 'left'),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            color: goal.color,
                            letterSpacing: -1.5)),
                    Text('complete',
                        style: _T.label(size: 10, color: const Color(0xFF888888))),
                  ],
                ),
              ]),

              const SizedBox(height: _T.s16),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: AlwaysStoppedAnimation(goal.color),
                ),
              ),

              if (goal.completionsPerDayEnabled && goal.loggedToday && !goal.dailyTargetMet) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (goal.completionsTodayCount / goal.completionsPerDay).clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: const Color(0xFF2A2A2A),
                    valueColor: AlwaysStoppedAnimation(goal.color.withOpacity(0.6)),
                  ),
                ),
              ],

              const SizedBox(height: _T.s16),

              GestureDetector(
                onTap: onLogDay,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: goal.dailyTargetMet
                        ? const Color(0xFF2A2A2A)
                        : goal.color,
                    borderRadius: BorderRadius.circular(_T.r8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        logLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: goal.dailyTargetMet
                              ? const Color(0xFF555555)
                              : Colors.white,
                        ),
                      ),
                      if (!goal.dailyTargetMet) ...[
                        const SizedBox(width: _T.s8),
                        const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String value, sub;
  const _HeroBadge({required this.value, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(_T.r8)),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _T.surface)),
          const SizedBox(height: 2),
          Text(sub, style: _T.label(size: 9, color: const Color(0xFF666666))),
        ]),
      );
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(_T.r8)),
          child: Icon(icon, color: const Color(0xFF888888), size: 15),
        ),
      );
}

// ─── Regular Goal Card (matches landing _FeatureCard feel) ────────────────────
class _GoalCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback? onLogDay;
  const _GoalCard({required this.goal, required this.onLogDay});

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = (goal.currentDays / goal.targetDays).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    String logLabel;
    bool tappable = widget.onLogDay != null;
    if (goal.completionsPerDayEnabled && goal.loggedToday && !goal.dailyTargetMet) {
      logLabel = '${goal.completionsTodayCount}/${goal.completionsPerDay} Log More';
    } else if (goal.dailyTargetMet) {
      logLabel = goal.nextLogAvailable.isEmpty ? 'Logged ✓' : goal.nextLogAvailable;
    } else {
      logLabel = '+ Log Day';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF5F4F1) : _T.surface,
          borderRadius: BorderRadius.circular(_T.r12),
          border: Border.all(color: _T.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _hovered ? goal.color : goal.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(_T.r8),
              ),
              child: goal.useEmoji
                  ? Center(child: Text(goal.selectedEmoji, style: const TextStyle(fontSize: 20)))
                  : Icon(goal.icon,
                      color: _hovered ? Colors.white : goal.color, size: 20),
            ),
            const SizedBox(width: _T.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(goal.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _T.ink,
                              letterSpacing: -0.3)),
                    ),
                    if (goal.streakGoal != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('🔥 ${goal.currentStreak}',
                            style: _T.label(size: 11, color: _T.coral)),
                      ),
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: goal.color,
                            letterSpacing: -0.2)),
                  ]),
                  const SizedBox(height: 3),
                  Text(goal.description, style: _T.body(size: 12)),
                  const SizedBox(height: _T.s12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: _T.border,
                      valueColor: AlwaysStoppedAnimation(goal.color),
                    ),
                  ),
                  const SizedBox(height: _T.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${goal.currentDays} / ${goal.targetDays} days',
                          style: _T.label(size: 11)),
                      if (tappable)
                        GestureDetector(
                          onTap: goal.dailyTargetMet ? null : widget.onLogDay,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: goal.dailyTargetMet
                                  ? _T.canvas
                                  : goal.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(_T.r100),
                              border: Border.all(
                                color: goal.dailyTargetMet ? _T.border : goal.color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(logLabel,
                                style: _T.label(
                                    size: 10,
                                    color: goal.dailyTargetMet ? _T.ink3 : goal.color)),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _T.tealBg,
                            borderRadius: BorderRadius.circular(_T.r100),
                            border: Border.all(color: _T.tealBorder),
                          ),
                          child: Text('✓ Done',
                              style: _T.label(size: 10, color: _T.teal)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Primitives (matching landing screen) ─────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: _T.ink,
            borderRadius: BorderRadius.circular(size * 0.22)),
        child: Center(
          child: Container(
            width: size * 0.30, height: size * 0.30,
            decoration: const BoxDecoration(color: _T.surface, shape: BoxShape.circle),
          ),
        ),
      );
}

class _EyebrowPill extends StatelessWidget {
  final String label;
  final Color bg, border, dot, text;
  const _EyebrowPill({
    required this.label,
    required this.bg,
    required this.border,
    required this.dot,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(_T.r100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: text,
                  letterSpacing: 0.6)),
        ]),
      );
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
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                color: _T.ink,
                borderRadius: BorderRadius.circular(_T.r8)),
            child: Text('Add',
                style: _T.label(size: 12, color: _T.surface)),
          ),
        ),
      );
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
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
                color: _T.ink, borderRadius: BorderRadius.circular(_T.r8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _T.surface,
                        letterSpacing: -0.3)),
                const SizedBox(width: _T.s8),
                const Icon(Icons.arrow_forward, size: 13, color: _T.surface),
              ],
            ),
          ),
        ),
      );
}

// ─── New / Edit Goal Bottom Sheet ─────────────────────────────────────────────
class GoalSheet extends StatefulWidget {
  final Goal? existing;
  const GoalSheet({super.key, this.existing});

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late int _selectedColorIndex;
  late int _selectedIconIndex;
  late String _category;
  late int _targetDays;

  bool _useEmoji = false;
  String _selectedEmoji = '🎯';

  bool _showAdvanced = false;
  int? _streakGoal;
  List<TimeOfDay> _reminders = [];
  CompletionTrackingMode _trackingMode = CompletionTrackingMode.stepByStep;
  int _customValue = 1;
  bool _completionsPerDayEnabled = false;
  int _completionsPerDay = 1;

  bool get _isEdit => widget.existing != null;

  static const List<Color> _colors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B),
    Color(0xFF22C55E), Color(0xFF10B981), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFEC4899),
    Color(0xFF06B6D4), Color(0xFF14B8A6), Color(0xFF64748B),
  ];

  static final List<IconData> _icons = [
    Icons.flag_outlined, Icons.flag, Icons.emoji_events_outlined, Icons.emoji_events,
    Icons.star_outline, Icons.star, Icons.military_tech_outlined, Icons.workspace_premium_outlined,
    Icons.diamond_outlined, Icons.local_fire_department, Icons.bolt_outlined, Icons.rocket_launch_outlined,
    Icons.whatshot_outlined, Icons.auto_awesome_outlined, Icons.grade_outlined, Icons.new_releases_outlined,
    Icons.fitness_center_outlined, Icons.fitness_center, Icons.directions_run_outlined, Icons.directions_run,
    Icons.directions_walk_outlined, Icons.directions_bike_outlined, Icons.pool_outlined, Icons.hiking_outlined,
    Icons.self_improvement_outlined, Icons.spa_outlined, Icons.favorite_outline, Icons.favorite,
    Icons.monitor_heart_outlined, Icons.health_and_safety_outlined, Icons.accessibility_new_outlined,
    Icons.sports_outlined, Icons.sports_gymnastics, Icons.sports_martial_arts_outlined,
    Icons.sports_basketball_outlined, Icons.sports_soccer_outlined, Icons.sports_tennis_outlined,
    Icons.menu_book_outlined, Icons.menu_book, Icons.book_outlined, Icons.auto_stories_outlined,
    Icons.school_outlined, Icons.school, Icons.psychology_outlined, Icons.psychology,
    Icons.lightbulb_outline, Icons.lightbulb, Icons.science_outlined, Icons.biotech_outlined,
    Icons.brush_outlined, Icons.brush, Icons.palette_outlined, Icons.palette,
    Icons.draw_outlined, Icons.edit_outlined, Icons.create_outlined, Icons.camera_alt_outlined,
    Icons.music_note_outlined, Icons.music_note, Icons.library_music_outlined, Icons.headphones_outlined,
    Icons.code_outlined, Icons.code, Icons.terminal_outlined, Icons.laptop_outlined,
    Icons.work_outline, Icons.work, Icons.trending_up_outlined, Icons.bar_chart_outlined,
    Icons.analytics_outlined, Icons.insights_outlined, Icons.task_alt_outlined,
    Icons.savings_outlined, Icons.savings, Icons.account_balance_outlined, Icons.payments_outlined,
    Icons.people_outline, Icons.people, Icons.person_outline, Icons.group_outlined,
    Icons.eco_outlined, Icons.eco, Icons.park_outlined, Icons.nature_outlined,
    Icons.travel_explore_outlined, Icons.flight_outlined, Icons.home_outlined,
    Icons.bedtime_outlined, Icons.alarm_outlined, Icons.schedule_outlined, Icons.coffee_outlined,
    Icons.mood_outlined, Icons.mood, Icons.sentiment_satisfied_outlined, Icons.theater_comedy_outlined,
    Icons.event_outlined, Icons.event_note_outlined, Icons.videogame_asset_outlined, Icons.sports_esports_outlined,
    Icons.casino_outlined, Icons.card_giftcard_outlined, Icons.card_travel_outlined,
    Icons.card_membership_outlined, Icons.card_membership, Icons.confirmation_number_outlined,
    Icons.style_outlined, Icons.style, Icons.shopping_bag_outlined, Icons.shopping_basket_outlined,
    Icons.storefront_outlined, Icons.inventory_outlined, Icons.warehouse_outlined, Icons.kitchen_outlined,
    Icons.restaurant_outlined, Icons.restaurant_menu_outlined, Icons.local_cafe_outlined, Icons.local_bar_outlined,
    Icons.local_pizza_outlined, Icons.local_dining_outlined, Icons.cake_outlined, Icons.icecream_outlined,
    Icons.fastfood_outlined, Icons.ramen_dining_outlined, Icons.lunch_dining_outlined, Icons.dinner_dining_outlined,
  ];

  static const List<String> _emojis = [
    '🎯','🏆','⭐','🔥','💪','🧠','📚','💡','🎨','🎵','💻','🌱',
    '🏃','🧘','🤸','⚽','🏀','🎾','🚴','🏊','🌟','✨','💫','🎉',
    '🥇','🥈','🥉','🏅','🎖️','🏵️','🎗️','🎀','🎁','🎊','🎭','🎬',
    '📝','📖','🔬','🔭','⚗️','🧪','🧬','🔮','💎','👑','🦁','🦅',
    '🌈','🌊','🌙','☀️','⚡','❄️','🌺','🌸','🌻','🌹','🍀','🌿',
    '😀','😊','🙌','👏','✊','🤝','💖','❤️','🧡','💛','💚','💙',
    '🍎','🥑','🥦','💧','🫀','🦷','👁️','💊','🩺','🏥','🩹','🧴',
  ];

  static const List<String> _categories = [
    'None', 'Health', 'Fitness', 'Learning',
    'Finance', 'Mindfulness', 'Creativity', 'Social', 'Productivity', 'Other',
  ];

  static const List<int> _targetOptions = [7, 14, 21, 30, 60, 90, 180, 365];
  static const List<int?> _streakOptions = [null, 3, 5, 7, 10, 14, 21, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(
        text: e?.description == 'No description' ? '' : e?.description ?? '');
    _category = e?.category ?? 'None';
    _targetDays = e?.targetDays ?? 30;

    if (e != null) {
      _selectedColorIndex = _colors.indexWhere((c) => c.value == e.color.value);
      if (_selectedColorIndex < 0) _selectedColorIndex = 0;
      _selectedIconIndex = _icons.indexOf(e.icon);
      if (_selectedIconIndex < 0) _selectedIconIndex = 0;
      _streakGoal = e.streakGoal;
      _reminders = List.from(e.reminders);
      _trackingMode = e.trackingMode;
      _customValue = e.customValue;
      _completionsPerDayEnabled = e.completionsPerDayEnabled;
      _completionsPerDay = e.completionsPerDay;
      _useEmoji = e.useEmoji;
      _selectedEmoji = e.selectedEmoji;
    } else {
      _selectedColorIndex = 5;
      _selectedIconIndex = 0;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickCategory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Category',
        children: _categories.map((cat) => _PickerItem(
          label: cat,
          selected: _category == cat,
          onTap: () { setState(() => _category = cat); Navigator.pop(context); },
        )).toList(),
      ),
    );
  }

  void _pickTargetDays() {
    int tempVal = _targetDays;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CupertinoPickerSheet(
        title: 'Target Days',
        onDone: () { setState(() => _targetDays = tempVal); Navigator.pop(ctx); },
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
              initialItem: _targetOptions.indexOf(_targetDays).clamp(0, _targetOptions.length - 1)),
          itemExtent: 44,
          onSelectedItemChanged: (i) => tempVal = _targetOptions[i],
          children: _targetOptions
              .map((d) => Center(child: Text('$d days',
                  style: const TextStyle(fontSize: 18, color: Color(0xFF1C1C1E)))))
              .toList(),
        ),
      ),
    );
  }

  void _pickStreakGoal() {
    int? tempVal = _streakGoal;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CupertinoPickerSheet(
        title: 'Streak Goal',
        onDone: () { setState(() => _streakGoal = tempVal); Navigator.pop(ctx); },
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
              initialItem: _streakOptions.indexOf(_streakGoal).clamp(0, _streakOptions.length - 1)),
          itemExtent: 44,
          onSelectedItemChanged: (i) => tempVal = _streakOptions[i],
          children: _streakOptions
              .map((v) => Center(child: Text(v == null ? 'None' : '$v days',
                  style: const TextStyle(fontSize: 18, color: Color(0xFF1C1C1E)))))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _addReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminders.add(picked));
  }

  void _removeReminder(int index) => setState(() => _reminders.removeAt(index));

  void _pickCustomValue() {
    int tempVal = _customValue;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CupertinoPickerSheet(
        title: 'Custom Increment',
        onDone: () { setState(() => _customValue = tempVal); Navigator.pop(ctx); },
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: tempVal - 1),
          itemExtent: 44,
          onSelectedItemChanged: (i) => tempVal = i + 1,
          children: List.generate(100, (i) => Center(
            child: Text('${i + 1}', style: const TextStyle(fontSize: 18, color: Color(0xFF1C1C1E))),
          )),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a name', style: _T.body(color: Colors.white)),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r8)),
      ));
      return;
    }
    Navigator.pop(context, Goal(
      title: name,
      description: _descCtrl.text.trim().isEmpty ? 'No description' : _descCtrl.text.trim(),
      color: _colors[_selectedColorIndex],
      icon: _icons[_selectedIconIndex],
      category: _category == 'None' ? 'General' : _category,
      targetDays: _targetDays,
      currentDays: widget.existing?.currentDays ?? 0,
      lastLoggedDate: widget.existing?.lastLoggedDate,
      completionHistory: widget.existing?.completionHistory ?? [],
      streakGoal: _streakGoal,
      reminders: _reminders,
      trackingMode: _trackingMode,
      customValue: _customValue,
      completionsPerDayEnabled: _completionsPerDayEnabled,
      completionsPerDay: _completionsPerDay,
      useEmoji: _useEmoji,
      selectedEmoji: _selectedEmoji,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = _colors[_selectedColorIndex];

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: _T.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: _T.border, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        border: Border.all(color: _T.border),
                        borderRadius: BorderRadius.circular(_T.r8)),
                    child: Text('Cancel', style: _T.body(size: 13)),
                  ),
                ),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Goal' : 'New Goal',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500,
                        color: _T.ink, letterSpacing: -0.3),
                  ),
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
                  Container(
                    color: _T.surface,
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                    child: Center(
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: _useEmoji ? _T.canvas : accent,
                          borderRadius: BorderRadius.circular(_T.r16),
                          border: Border.all(color: _T.border),
                        ),
                        child: _useEmoji
                            ? Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 34)))
                            : Icon(_icons[_selectedIconIndex], color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: _T.border),
                  const SizedBox(height: _T.s16),

                  _FormSection(label: 'Name', child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('e.g. Read Every Day'),
                  )),
                  const SizedBox(height: _T.s16),

                  _FormSection(label: 'Description', child: TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('What does this goal involve?'),
                  )),
                  const SizedBox(height: _T.s16),

                  _TapRow(label: 'Target Days', value: '$_targetDays days', onTap: _pickTargetDays),
                  const SizedBox(height: _T.s16),

                  _TapRow(label: 'Category', value: _category, onTap: _pickCategory),
                  const SizedBox(height: _T.s16),

                  Container(
                    color: _T.surface,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_useEmoji ? 'Emoji' : 'Icon',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink)),
                            Container(
                              height: 32, width: 180,
                              decoration: BoxDecoration(
                                  color: _T.canvas,
                                  borderRadius: BorderRadius.circular(_T.r8),
                                  border: Border.all(color: _T.border)),
                              child: Row(children: [
                                _SegmentButton(
                                    label: '⚡ Icons',
                                    selected: !_useEmoji,
                                    accent: accent,
                                    onTap: () => setState(() => _useEmoji = false)),
                                _SegmentButton(
                                    label: '😀 Emoji',
                                    selected: _useEmoji,
                                    accent: accent,
                                    onTap: () => setState(() => _useEmoji = true)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 260,
                          child: _useEmoji
                              ? GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 8, mainAxisSpacing: 6, crossAxisSpacing: 6),
                                  itemCount: _emojis.length,
                                  itemBuilder: (_, i) => GestureDetector(
                                    onTap: () => setState(() => _selectedEmoji = _emojis[i]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedEmoji == _emojis[i]
                                            ? accent.withOpacity(0.12)
                                            : _T.canvas,
                                        borderRadius: BorderRadius.circular(_T.r8),
                                        border: _selectedEmoji == _emojis[i]
                                            ? Border.all(color: accent, width: 1.5)
                                            : Border.all(color: _T.border),
                                      ),
                                      child: Center(child: Text(_emojis[i],
                                          style: const TextStyle(fontSize: 19))),
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                                  itemCount: _icons.length,
                                  itemBuilder: (_, i) => GestureDetector(
                                    onTap: () => setState(() => _selectedIconIndex = i),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: i == _selectedIconIndex
                                            ? accent.withOpacity(0.12)
                                            : _T.canvas,
                                        borderRadius: BorderRadius.circular(_T.r8),
                                        border: i == _selectedIconIndex
                                            ? Border.all(color: accent, width: 1.5)
                                            : Border.all(color: _T.border),
                                      ),
                                      child: Icon(_icons[i],
                                          color: i == _selectedIconIndex ? accent : _T.ink3,
                                          size: 20),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: _T.s16),

                  Container(
                    color: _T.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Color',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink)),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 160,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                            itemCount: _colors.length,
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => setState(() => _selectedColorIndex = i),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: _colors[i],
                                    borderRadius: BorderRadius.circular(_T.r8),
                                    border: i == _selectedColorIndex
                                        ? Border.all(color: _T.ink, width: 2)
                                        : null),
                                child: i == _selectedColorIndex
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _T.s16),

                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Container(
                      color: _T.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Advanced Options',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: accent,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2)),
                          const SizedBox(width: 6),
                          Icon(
                              _showAdvanced
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: accent, size: 18),
                        ],
                      ),
                    ),
                  ),

                  if (_showAdvanced) ...[
                    const SizedBox(height: _T.s16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: _pickStreakGoal,
                          child: _AdvancedTile(
                            label: 'Streak Goal',
                            value: _streakGoal == null ? 'None' : '$_streakGoal days',
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: GestureDetector(
                          onTap: _addReminder,
                          child: _AdvancedTile(
                            label: 'Reminder',
                            value: _reminders.isEmpty ? '0 Active' : '${_reminders.length} Active',
                          ),
                        )),
                      ]),
                    ),

                    if (_reminders.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                              color: _T.surface,
                              borderRadius: BorderRadius.circular(_T.r12),
                              border: Border.all(color: _T.border)),
                          child: Column(
                            children: _reminders.asMap().entries.map((entry) {
                              final i = entry.key;
                              final t = entry.value;
                              return Column(children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(children: [
                                    Icon(Icons.alarm_outlined, color: accent, size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(t.format(context),
                                        style: _T.body(size: 14, color: _T.ink))),
                                    GestureDetector(
                                      onTap: () => _removeReminder(i),
                                      child: const Icon(Icons.close, color: _T.ink3, size: 16),
                                    ),
                                  ]),
                                ),
                                if (i < _reminders.length - 1)
                                  Divider(height: 1, color: _T.border),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: _T.s16),

                    Container(
                      color: _T.surface,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How should completions be tracked?',
                              style: TextStyle(
                                  fontSize: 14, color: _T.ink, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                                color: _T.canvas,
                                borderRadius: BorderRadius.circular(_T.r8),
                                border: Border.all(color: _T.border)),
                            child: Row(children: [
                              _SegmentButton(
                                label: 'Step By Step',
                                selected: _trackingMode == CompletionTrackingMode.stepByStep,
                                accent: accent,
                                onTap: () => setState(() => _trackingMode = CompletionTrackingMode.stepByStep),
                              ),
                              _SegmentButton(
                                label: 'Custom Value',
                                selected: _trackingMode == CompletionTrackingMode.customValue,
                                accent: accent,
                                onTap: () => setState(() => _trackingMode = CompletionTrackingMode.customValue),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          if (_trackingMode == CompletionTrackingMode.stepByStep)
                            Text('Increment by 1 with each completion',
                                style: _T.body(size: 12))
                          else
                            GestureDetector(
                              onTap: _pickCustomValue,
                              child: Row(children: [
                                Text('Increment by $_customValue with each completion',
                                    style: _T.body(size: 12, color: accent)),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined, size: 12, color: accent),
                              ]),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: _T.s16),

                    Container(
                      color: _T.surface,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Completions Per Day',
                                  style: TextStyle(
                                      fontSize: 14, color: _T.ink, fontWeight: FontWeight.w500)),
                              CupertinoSwitch(
                                value: _completionsPerDayEnabled,
                                activeColor: accent,
                                onChanged: (v) => setState(() => _completionsPerDayEnabled = v),
                              ),
                            ],
                          ),
                          if (_completionsPerDayEnabled) ...[
                            const SizedBox(height: 14),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: _T.canvas,
                                    borderRadius: BorderRadius.circular(_T.r8),
                                    border: Border.all(color: _T.border)),
                                child: Text('$_completionsPerDay / Day',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink)),
                              ),
                              const SizedBox(width: 10),
                              _CounterBtn(
                                icon: Icons.remove,
                                onTap: _completionsPerDay > 1
                                    ? () => setState(() => _completionsPerDay--)
                                    : null,
                                accent: accent,
                              ),
                              const SizedBox(width: 8),
                              _CounterBtn(
                                icon: Icons.add,
                                onTap: () => setState(() => _completionsPerDay++),
                                accent: accent,
                              ),
                              const SizedBox(width: 8),
                              _CounterBtn(
                                icon: Icons.edit_outlined,
                                onTap: () => _pickCompletionsPerDay(),
                                accent: accent,
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text('The day will count when this number is met',
                                style: _T.body(size: 12)),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: _T.s32),
                ],
              ),
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: _T.surface,
              border: Border(top: BorderSide(color: _T.border, width: 1)),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: _T.ink,
                        borderRadius: BorderRadius.circular(_T.r8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isEdit ? 'Save Changes' : 'Create Goal',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _T.surface,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(width: _T.s8),
                        const Icon(Icons.arrow_forward, size: 13, color: _T.surface),
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

  void _pickCompletionsPerDay() {
    int tempVal = _completionsPerDay;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CupertinoPickerSheet(
        title: 'Completions Per Day',
        onDone: () { setState(() => _completionsPerDay = tempVal); Navigator.pop(ctx); },
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: tempVal - 1),
          itemExtent: 44,
          onSelectedItemChanged: (i) => tempVal = i + 1,
          children: List.generate(50, (i) => Center(
            child: Text('${i + 1}',
                style: const TextStyle(fontSize: 18, color: Color(0xFF1C1C1E))),
          )),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: _T.body(size: 14, color: _T.ink3),
        filled: true,
        fillColor: _T.canvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r8),
            borderSide: const BorderSide(color: _T.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r8),
            borderSide: const BorderSide(color: _T.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r8),
            borderSide: const BorderSide(color: _T.ink, width: 1.5)),
      );
}

// ─── Advanced tile ─────────────────────────────────────────────────────────────
class _AdvancedTile extends StatelessWidget {
  final String label, value;
  const _AdvancedTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(_T.r12),
            border: Border.all(color: _T.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _T.label(size: 11)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: _T.ink, fontWeight: FontWeight.w500))),
              const Icon(Icons.chevron_right, color: _T.ink3, size: 16),
            ]),
          ],
        ),
      );
}

// ─── Reusable sheet widgets ────────────────────────────────────────────────────
class _TapRow extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _TapRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          color: _T.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: _T.ink, fontWeight: FontWeight.w400)),
              Row(children: [
                Text(value, style: _T.body(size: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: _T.ink3, size: 18),
              ]),
            ],
          ),
        ),
      );
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PickerSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _T.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: _T.ink)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(
                            color: _T.purple, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: SingleChildScrollView(child: Column(children: children)),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      );
}

class _PickerItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PickerItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: _T.body(size: 15, color: _T.ink)),
                  if (selected) const Icon(Icons.check, color: _T.purple, size: 18),
                ],
              ),
            ),
            Divider(height: 1, indent: 16, thickness: 1, color: _T.border),
          ]),
        ),
      );
}

class _CupertinoPickerSheet extends StatelessWidget {
  final String title;
  final VoidCallback onDone;
  final Widget child;
  const _CupertinoPickerSheet({required this.title, required this.onDone, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _T.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: _T.ink)),
                  TextButton(
                    onPressed: onDone,
                    child: Text('Done',
                        style: TextStyle(
                            color: _T.purple, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),
            SizedBox(height: 200, child: child),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      );
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _SegmentButton(
      {required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected ? _T.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: selected ? Border.all(color: _T.border) : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected ? _T.ink : _T.ink3)),
          ),
        ),
      );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;
  const _CounterBtn({required this.icon, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _T.canvas,
            borderRadius: BorderRadius.circular(_T.r8),
            border: Border.all(color: _T.border),
          ),
          child: Icon(icon,
              color: onTap != null ? _T.ink : _T.ink3, size: 16),
        ),
      );
}

class _FormSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        color: _T.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: _T.ink2, fontWeight: FontWeight.w400)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}