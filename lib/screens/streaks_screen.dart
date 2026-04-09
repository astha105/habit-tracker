// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

// ─── Data model ───────────────────────────────────────────────────────────────
class Streak {
  String title;
  String description;
  Color color;
  IconData icon;
  String category;
  int currentStreak;
  int longestStreak;
  int totalCompletions;
  DateTime? lastLoggedDate;
  List<DateTime> completionHistory;

  Streak({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.category,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    this.lastLoggedDate,
    List<DateTime>? completionHistory,
  }) : completionHistory = completionHistory ?? [];

  bool get loggedToday {
    if (lastLoggedDate == null) return false;
    final now = DateTime.now();
    return lastLoggedDate!.year == now.year &&
        lastLoggedDate!.month == now.month &&
        lastLoggedDate!.day == now.day;
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

  String get streakEmoji {
    if (currentStreak >= 30) return '🔥';
    if (currentStreak >= 14) return '⚡';
    if (currentStreak >= 7) return '✨';
    if (currentStreak >= 3) return '💪';
    return '🌱';
  }
}

// ─── Streaks Storage Service ───────────────────────────────────────────────────
class StreaksStorageService {
  static const String _key = 'streaks_data';

  static Future<void> saveStreaks(List<Streak> streaks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = streaks.map((s) => _streakToJson(s)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
      print('✓ Streaks saved (${streaks.length} streaks)');
    } catch (e) {
      print('✗ Error saving streaks: $e');
    }
  }

  static Future<List<Streak>> loadStreaks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return [];

      final jsonList = jsonDecode(jsonStr) as List;
      final streaks = jsonList.map((json) => _streakFromJson(json)).toList();
      print('✓ Streaks loaded (${streaks.length} streaks)');
      return streaks;
    } catch (e) {
      print('✗ Error loading streaks: $e');
      return [];
    }
  }

  static Map<String, dynamic> _streakToJson(Streak s) => {
    'title': s.title,
    'description': s.description,
    'colorValue': s.color.value,
    'iconCodePoint': s.icon.codePoint,
    'category': s.category,
    'currentStreak': s.currentStreak,
    'longestStreak': s.longestStreak,
    'totalCompletions': s.totalCompletions,
    'lastLoggedDate': s.lastLoggedDate?.toIso8601String(),
    'completionHistory': s.completionHistory.map((d) => d.toIso8601String()).toList(),
  };

  static Streak _streakFromJson(Map<String, dynamic> json) {
    final completionHistory = (json['completionHistory'] as List<dynamic>?)
        ?.map((d) => DateTime.parse(d as String))
        .toList() ?? [];

    return Streak(
      title: json['title'] as String,
      description: json['description'] as String? ?? 'No description',
      color: Color(json['colorValue'] as int? ?? 0xFFD85A30),
      icon: IconData(json['iconCodePoint'] as int? ?? 0xf57ca, fontFamily: 'MaterialIcons'),
      category: json['category'] as String? ?? 'General',
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCompletions: json['totalCompletions'] as int? ?? 0,
      lastLoggedDate: json['lastLoggedDate'] != null
          ? DateTime.parse(json['lastLoggedDate'] as String)
          : null,
      completionHistory: completionHistory,
    );
  }
}

// ─── Streaks Screen ───────────────────────────────────────────────────────────
class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  final List<Streak> _streaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreaks();
  }

  Future<void> _loadStreaks() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final loaded = await StreaksStorageService.loadStreaks();
      if (mounted) {
        setState(() {
          _streaks.addAll(loaded);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading streaks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveStreaks() async {
    await StreaksStorageService.saveStreaks(_streaks);
  }

  void _deleteStreak(Streak streak) {
    final index = _streaks.indexOf(streak);
    setState(() => _streaks.remove(streak));
    _saveStreaks();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text('"${streak.title}" deleted',
              style: _T.body(color: Colors.white)),
          backgroundColor: _T.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r8)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: _T.coral,
            onPressed: () {
              setState(() => _streaks.insert(index, streak));
              _saveStreaks();
            },
          ),
        ),
      );
    });
  }

  void _confirmDelete(Streak streak) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Streak'),
        content: Text('Are you sure you want to delete "${streak.title}"? This cannot be undone.'),
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
              _deleteStreak(streak);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdd() async {
    final newStreak = await showModalBottomSheet<Streak>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewStreakSheet(),
    );
    if (newStreak != null) {
      setState(() => _streaks.add(newStreak));
      _saveStreaks();
    }
  }

  Future<void> _openEdit(Streak streak) async {
    final updated = await showModalBottomSheet<Streak>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewStreakSheet(existing: streak),
    );
    if (updated != null) {
      setState(() {
        streak.title = updated.title;
        streak.description = updated.description;
        streak.color = updated.color;
        streak.icon = updated.icon;
        streak.category = updated.category;
      });
      _saveStreaks();
    }
  }

  void _showContextMenu(BuildContext context, Streak streak) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(streak.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _openEdit(streak); },
            child: const Text('Edit Streak'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () { Navigator.pop(context); _confirmDelete(streak); },
            child: const Text('Delete Streak'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _logDay(Streak s) {
  setState(() {
    final now = DateTime.now();
    if (!s.loggedToday) {
      if (s.currentStreak == 0) {
        // First time logging - initialize streak to 1
        s.currentStreak = 1;
        s.longestStreak = 1;
      } else {
        s.currentStreak++;
        if (s.currentStreak > s.longestStreak) {
          s.longestStreak = s.currentStreak;
        }
      }
      s.totalCompletions++;
      s.lastLoggedDate = now;
      s.completionHistory.add(now);
    }
  });
  _saveStreaks();
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
                  color: _T.coralBg,
                  borderRadius: BorderRadius.circular(_T.r16),
                  border: Border.all(color: _T.coralBorder),
                ),
                child: const Icon(Icons.local_fire_department_outlined, color: _T.coral, size: 28),
              ),
              const SizedBox(height: _T.s16),
              Text('Loading streaks...', style: _T.body(size: 14)),
            ],
          ),
        ),
      );
    }

    final active = _streaks.where((s) => s.currentStreak > 0).toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    final notStarted = _streaks.where((s) => s.currentStreak == 0).toList();

    final bestStreak = _streaks.isEmpty
        ? 0
        : _streaks.map((s) => s.longestStreak).reduce((a, b) => a > b ? a : b);

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
            Text('Streaks',
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
      body: _streaks.isEmpty
          ? _buildEmpty()
          : _buildList(active, notStarted, bestStreak),
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
                color: _T.coralBg,
                borderRadius: BorderRadius.circular(_T.r16),
                border: Border.all(color: _T.coralBorder),
              ),
              child: const Icon(Icons.local_fire_department_outlined,
                  color: _T.coral, size: 32),
            ),
            const SizedBox(height: _T.s20),
            Text('No streaks yet', style: _T.heading(size: 22)),
            const SizedBox(height: _T.s8),
            Text(
              'Tap "Add" to create your first streak and start building consistency.',
              textAlign: TextAlign.center,
              style: _T.body(size: 14),
            ),
            const SizedBox(height: _T.s32),
            _PrimaryBtn(label: 'Add your first streak', onTap: _openAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Streak> active, List<Streak> notStarted, int bestStreak) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryStrip(active: active.length, bestStreak: bestStreak),
          Divider(height: 1, thickness: 1, color: _T.border),

          if (active.isNotEmpty) ...[
            _SectionHeader(label: 'On Fire', accent: _T.coral, bg: _T.coralBg, border: _T.coralBorder, dot: _T.coral),
            _TopStreakCard(
              streak: active.first,
              onEdit: () => _openEdit(active.first),
              onDelete: () => _confirmDelete(active.first),
              onLongPress: () => _showContextMenu(context, active.first),
              onLogDay: active.first.loggedToday ? null : () => _logDay(active.first),
            ),
          ],

          if (active.length > 1) ...[
            _SectionHeader(label: 'Active Streaks', accent: _T.coral, bg: _T.coralBg, border: _T.coralBorder, dot: _T.coral),
            ...active.skip(1).map((s) => _SwipeCard(
              key: ValueKey(s.hashCode),
              streak: s,
              onEdit: () => _openEdit(s),
              onDelete: () => _confirmDelete(s),
              onLongPress: () => _showContextMenu(context, s),
              onLogDay: s.loggedToday ? null : () => _logDay(s),
            )),
          ],

          if (_streaks.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: _T.border),
            _SectionHeader(label: 'This Week', accent: _T.purple, bg: _T.purpleBg, border: _T.purpleBorder, dot: _T.purple),
            _WeeklyOverview(streaks: _streaks),
          ],

          if (notStarted.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: _T.border),
            _SectionHeader(label: 'Not Started', accent: _T.ink3, bg: _T.canvas, border: _T.border, dot: _T.ink3),
            ...notStarted.map((s) => _SwipeCard(
              key: ValueKey(s.hashCode),
              streak: s,
              onEdit: () => _openEdit(s),
              onDelete: () => _confirmDelete(s),
              onLongPress: () => _showContextMenu(context, s),
              onLogDay: s.loggedToday ? null : () => _logDay(s),
            )),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int active, bestStreak;
  const _SummaryStrip({required this.active, required this.bestStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _SummaryCell(
              icon: Icons.local_fire_department_outlined,
              value: '$active',
              label: 'Active',
              iconBg: _T.coralBg,
              iconColor: _T.coral,
              valueColor: _T.coralDark,
              labelColor: _T.coral,
            )),
            VerticalDivider(width: 1, thickness: 1, color: _T.border),
            Expanded(child: _SummaryCell(
              icon: Icons.emoji_events_outlined,
              value: '${bestStreak}d',
              label: 'Best Streak',
              iconBg: _T.purpleBg,
              iconColor: _T.purple,
              valueColor: _T.purpleDeep,
              labelColor: _T.purple,
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
  final Color accent, bg, border, dot;
  const _SectionHeader({
    required this.label,
    required this.accent,
    required this.bg,
    required this.border,
    required this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.canvas,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: _EyebrowPill(
        label: label.toUpperCase(),
        bg: bg,
        border: border,
        dot: dot,
        text: accent,
      ),
    );
  }
}

// ─── Swipeable card wrapper ────────────────────────────────────────────────────
class _SwipeCard extends StatelessWidget {
  final Streak streak;
  final VoidCallback? onLogDay;
  final VoidCallback onEdit, onDelete, onLongPress;

  const _SwipeCard({
    super.key,
    required this.streak,
    required this.onLogDay,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${streak.hashCode}'),
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
        child: _StreakCard(streak: streak, onLogDay: onLogDay),
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

// ─── Top Streak Hero Card ──────────────────────────────────────────────────────
class _TopStreakCard extends StatelessWidget {
  final Streak streak;
  final VoidCallback? onLogDay;
  final VoidCallback onEdit, onDelete, onLongPress;

  const _TopStreakCard({
    required this.streak,
    required this.onLogDay,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
                        color: streak.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_T.r8),
                        border: Border.all(color: streak.color.withOpacity(0.4))),
                    child: Icon(streak.icon, color: streak.color, size: 22),
                  ),
                  const SizedBox(width: _T.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(streak.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _T.surface,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 3),
                        Text(streak.category,
                            style: _T.label(size: 11, color: const Color(0xFF888888))),
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
                _HeroBadge(value: '${streak.currentStreak}d', sub: 'current'),
                const SizedBox(width: _T.s8),
                _HeroBadge(value: '${streak.longestStreak}d', sub: 'best'),
                const SizedBox(width: _T.s8),
                _HeroBadge(value: '${streak.totalCompletions}', sub: 'total'),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(streak.streakEmoji, style: const TextStyle(fontSize: 24)),
                    Text('${streak.currentStreak}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: streak.color,
                            letterSpacing: -1.2)),
                    Text('days',
                        style: _T.label(size: 10, color: const Color(0xFF888888))),
                  ],
                ),
              ]),

              const SizedBox(height: _T.s16),

              GestureDetector(
                onTap: onLogDay,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: streak.loggedToday
                        ? const Color(0xFF2A2A2A)
                        : streak.color,
                    borderRadius: BorderRadius.circular(_T.r8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        streak.loggedToday
                            ? (streak.nextLogAvailable.isEmpty ? '✓ Logged Today' : streak.nextLogAvailable)
                            : '+ Log Today',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: streak.loggedToday
                              ? const Color(0xFF555555)
                              : Colors.white,
                        ),
                      ),
                      if (!streak.loggedToday) ...[
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

// ─── Regular Streak Card ───────────────────────────────────────────────────────
class _StreakCard extends StatefulWidget {
  final Streak streak;
  final VoidCallback? onLogDay;
  const _StreakCard({required this.streak, required this.onLogDay});

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final streak = widget.streak;

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
                color: _hovered ? streak.color : streak.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(_T.r8),
              ),
              child: Icon(streak.icon,
                  color: _hovered ? Colors.white : streak.color, size: 20),
            ),
            const SizedBox(width: _T.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(streak.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _T.ink,
                              letterSpacing: -0.3)),
                    ),
                    Text('${streak.streakEmoji} ${streak.currentStreak}d',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: streak.color,
                            letterSpacing: -0.2)),
                  ]),
                  const SizedBox(height: 3),
                  Text(streak.description, style: _T.body(size: 12)),
                  const SizedBox(height: _T.s12),
                  _WeekDots(streak: streak),
                  const SizedBox(height: _T.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Best: ${streak.longestStreak}d · Total: ${streak.totalCompletions}',
                          style: _T.label(size: 11)),
                      GestureDetector(
                        onTap: streak.loggedToday ? null : widget.onLogDay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: streak.loggedToday
                                ? _T.canvas
                                : streak.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(_T.r100),
                            border: Border.all(
                              color: streak.loggedToday
                                  ? _T.border
                                  : streak.color.withOpacity(0.3),
                            ),
                          ),
                          child: streak.loggedToday
                              ? Text(
                                  streak.nextLogAvailable.isEmpty ? 'Logged ✓' : streak.nextLogAvailable,
                                  style: _T.label(size: 10, color: _T.ink3))
                              : Text(
                                  streak.currentStreak == 0 ? '🔄 Start' : '+ Log Day',
                                  style: _T.label(size: 10, color: streak.color)),
                        ),
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

// ─── Week Dots ────────────────────────────────────────────────────────────────
class _WeekDots extends StatelessWidget {
  final Streak streak;
  const _WeekDots({required this.streak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekday = now.weekday;

    return Row(
      children: List.generate(7, (i) {
        final dayOffset = i + 1 - weekday;
        final date = now.add(Duration(days: dayOffset));
        final isFuture = date.isAfter(now);
        final isCompleted = streak.completionHistory.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day &&
            streak.loggedToday;

        Color dotColor;
        if (isFuture) {
          dotColor = _T.canvas;
        } else if (isCompleted || isToday) {
          dotColor = streak.color;
        } else {
          dotColor = _T.border;
        }

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 4),
              Text(days[i],
                  style: _T.label(
                      size: 9,
                      color: isFuture ? _T.canvas : _T.ink3)),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Weekly Overview Card ──────────────────────────────────────────────────────
class _WeeklyOverview extends StatelessWidget {
  final List<Streak> streaks;
  const _WeeklyOverview({required this.streaks});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(_T.r16),
            border: Border.all(color: _T.border)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Progress',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _T.ink,
                        letterSpacing: -0.3)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _T.purpleBg,
                      borderRadius: BorderRadius.circular(_T.r100),
                      border: Border.all(color: _T.purpleBorder)),
                  child: Text(
                      '${streaks.length} habit${streaks.length == 1 ? '' : 's'}',
                      style: _T.label(size: 10, color: _T.purple)),
                ),
              ],
            ),
            const SizedBox(height: _T.s20),
            Row(
              children: List.generate(7, (i) {
                final dayOffset = i + 1 - weekday;
                final date = now.add(Duration(days: dayOffset));
                final isFuture = date.isAfter(now);
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                final logged = streaks
                    .where((s) =>
                        (s.loggedToday && isToday) ||
                        s.completionHistory.any((d) =>
                            d.year == date.year &&
                            d.month == date.month &&
                            d.day == date.day))
                    .length;

                final pct = streaks.isEmpty ? 0.0 : logged / streaks.length;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                              color: _T.canvas,
                              borderRadius: BorderRadius.circular(_T.r8),
                              border: Border.all(color: _T.border)),
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.hardEdge,
                          child: isFuture
                              ? const SizedBox()
                              : FractionallySizedBox(
                                  heightFactor: pct == 0 ? 0.04 : pct,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: isToday ? _T.purple : _T.coral,
                                        borderRadius: BorderRadius.circular(_T.r8)),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i].substring(0, 1),
                            style: _T.label(
                                size: 10,
                                color: isToday ? _T.purple : _T.ink3)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: _T.s16),
            Row(children: [
              _LegendDot(color: _T.coral, label: 'Past days'),
              const SizedBox(width: _T.s16),
              _LegendDot(color: _T.purple, label: 'Today'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: _T.label(size: 11)),
        ],
      );
}

// ─── Primitives ───────────────────────────────────────────────────────────────
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
            child: Text('Add', style: _T.label(size: 12, color: _T.surface)),
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

// ─── New / Edit Streak Bottom Sheet ──────────────────────────────────────────
class NewStreakSheet extends StatefulWidget {
  final Streak? existing;
  const NewStreakSheet({super.key, this.existing});

  @override
  State<NewStreakSheet> createState() => _NewStreakSheetState();
}

class _NewStreakSheetState extends State<NewStreakSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late int _selectedColorIndex;
  late int _selectedIconIndex;
  late String _category;

  bool get _isEdit => widget.existing != null;

  static const List<Color> _colors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B),
    Color(0xFF22C55E), Color(0xFF10B981), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFEC4899),
    Color(0xFF06B6D4), Color(0xFF14B8A6), Color(0xFF64748B),
  ];

  static const List<IconData> _icons = [
    Icons.local_fire_department, Icons.fitness_center_outlined,
    Icons.directions_run_outlined, Icons.directions_bike_outlined,
    Icons.pool_outlined, Icons.sports_martial_arts_outlined,
    Icons.sports_basketball_outlined, Icons.sports_soccer_outlined,
    Icons.hiking_outlined, Icons.self_improvement_outlined,
    Icons.monitor_heart_outlined, Icons.medication_outlined,
    Icons.restaurant_outlined, Icons.water_drop_outlined,
    Icons.coffee_outlined, Icons.no_food_outlined,
    Icons.lunch_dining_outlined, Icons.apple_outlined,
    Icons.menu_book_outlined, Icons.psychology_outlined,
    Icons.school_outlined, Icons.lightbulb_outline,
    Icons.edit_note_outlined, Icons.quiz_outlined,
    Icons.wb_sunny_outlined, Icons.bedtime_outlined,
    Icons.alarm_outlined, Icons.weekend_outlined,
    Icons.cleaning_services_outlined, Icons.shower_outlined,
    Icons.brush_outlined, Icons.music_note_outlined,
    Icons.camera_alt_outlined, Icons.palette_outlined,
    Icons.piano_outlined, Icons.theater_comedy_outlined,
    Icons.code_outlined, Icons.laptop_outlined,
    Icons.work_outline, Icons.bar_chart_outlined,
    Icons.savings_outlined, Icons.attach_money_outlined,
    Icons.favorite_outline, Icons.people_outline,
    Icons.volunteer_activism_outlined, Icons.eco_outlined,
    Icons.star_outline, Icons.emoji_events_outlined,
  ];

  static const List<String> _categories = [
    'None', 'Health', 'Fitness', 'Learning',
    'Finance', 'Mindfulness', 'Creativity', 'Social', 'Productivity', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(
        text: e?.description == 'No description' ? '' : e?.description ?? '');
    _category = e?.category ?? 'None';

    if (e != null) {
      _selectedColorIndex = _colors.indexWhere((c) => c.value == e.color.value);
      if (_selectedColorIndex < 0) _selectedColorIndex = 0;
      _selectedIconIndex = _icons.indexOf(e.icon);
      if (_selectedIconIndex < 0) _selectedIconIndex = 0;
    } else {
      _selectedColorIndex = 0;
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
      builder: (_) => Container(
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
                  Text('Category',
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
              child: SingleChildScrollView(
                child: Column(
                  children: _categories.map((cat) => GestureDetector(
                    onTap: () { setState(() => _category = cat); Navigator.pop(context); },
                    child: Container(
                      color: Colors.transparent,
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat, style: _T.body(size: 15, color: _T.ink)),
                              if (_category == cat) const Icon(Icons.check, color: _T.purple, size: 18),
                            ],
                          ),
                        ),
                        if (cat != _categories.last) Divider(height: 1, indent: 16, thickness: 1, color: _T.border),
                      ]),
                    ),
                  )).toList(),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
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

    Navigator.pop(context, Streak(
      title: name,
      description: _descCtrl.text.trim().isEmpty ? 'No description' : _descCtrl.text.trim(),
      color: _colors[_selectedColorIndex],
      icon: _icons[_selectedIconIndex],
      category: _category == 'None' ? 'General' : _category,
      currentStreak: widget.existing?.currentStreak ?? 0,
      longestStreak: widget.existing?.longestStreak ?? 0,
      totalCompletions: widget.existing?.totalCompletions ?? 0,
      lastLoggedDate: widget.existing?.lastLoggedDate,
      completionHistory: widget.existing?.completionHistory ?? [],
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
                    _isEdit ? 'Edit Streak' : 'New Streak',
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
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_T.r16),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Icon(_icons[_selectedIconIndex], color: accent, size: 32),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: _T.border),
                  const SizedBox(height: _T.s16),

                  _FormSection(label: 'Name', child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('e.g. Morning Run'),
                  )),
                  const SizedBox(height: _T.s16),

                  _FormSection(label: 'Description', child: TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('What does this habit involve?'),
                  )),
                  const SizedBox(height: _T.s16),

                  GestureDetector(
                    onTap: _pickCategory,
                    child: Container(
                      color: _T.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Category',
                              style: const TextStyle(
                                  fontSize: 14, color: _T.ink, fontWeight: FontWeight.w400)),
                          Row(children: [
                            Text(_category, style: _T.body(size: 14)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: _T.ink3, size: 18),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: _T.s16),

                  Container(
                    color: _T.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Icon',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink)),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
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
                                  size: 22),
                            ),
                          ),
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
                        const Text('Color',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink)),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
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
                      ],
                    ),
                  ),

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
                        color: _T.ink,
                        borderRadius: BorderRadius.circular(_T.r8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isEdit ? 'Save Changes' : 'Create Streak',
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