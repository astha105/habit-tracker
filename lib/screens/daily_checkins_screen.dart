// ignore_for_file: deprecated_member_use, unused_field, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
class DailyHabit {
  String title;
  String description;
  Color color;
  IconData icon;
  String category;
  bool completedToday;
  DateTime? lastCompletedDate;
  List<DateTime> completionHistory;

  DailyHabit({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.category,
    this.completedToday = false,
    this.lastCompletedDate,
    List<DateTime>? completionHistory,
  }) : completionHistory = completionHistory ?? [];

  int get totalDays => completionHistory.length;

  String get streak {
    if (completionHistory.isEmpty) return '0 days';
    
    final now = DateTime.now();
    int count = 0;
    
    for (int i = 0; i < 365; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasCompletion = completionHistory.any((d) =>
          d.year == checkDate.year &&
          d.month == checkDate.month &&
          d.day == checkDate.day);
      
      if (hasCompletion) {
        count++;
      } else if (i > 0) {
        break;
      }
    }
    
    return '$count day${count == 1 ? '' : 's'}';
  }

  String get completionPercentage {
    if (completionHistory.isEmpty) return '0%';
    final now = DateTime.now();
    final daysTracked = now.difference(completionHistory.first).inDays + 1;
    final pct = ((completionHistory.length / daysTracked) * 100).toStringAsFixed(0);
    return '$pct%';
  }
}

// ─── Daily Check-ins Screen ───────────────────────────────────────────────────
class DailyCheckinsScreen extends StatefulWidget {
  const DailyCheckinsScreen({super.key});

  @override
  State<DailyCheckinsScreen> createState() => _DailyCheckinsScreenState();
}

class _DailyCheckinsScreenState extends State<DailyCheckinsScreen> {
  final List<DailyHabit> _habits = [];

  void _deleteHabit(DailyHabit habit) {
    setState(() => _habits.remove(habit));
  }

  void _confirmDelete(DailyHabit habit) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.title}"? This cannot be undone.'),
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
              _deleteHabit(habit);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdd() async {
    final newHabit = await showModalBottomSheet<DailyHabit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewHabitSheet(),
    );
    if (newHabit != null) setState(() => _habits.add(newHabit));
  }

  Future<void> _openEdit(DailyHabit habit) async {
    final updated = await showModalBottomSheet<DailyHabit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewHabitSheet(existing: habit),
    );
    if (updated != null) {
      setState(() {
        habit.title = updated.title;
        habit.description = updated.description;
        habit.color = updated.color;
        habit.icon = updated.icon;
        habit.category = updated.category;
      });
    }
  }

  void _toggleComplete(DailyHabit habit) {
    setState(() {
      habit.completedToday = !habit.completedToday;
      if (habit.completedToday) {
        habit.lastCompletedDate = DateTime.now();
        habit.completionHistory.add(DateTime.now());
      } else {
        habit.completionHistory.removeWhere((d) =>
            d.year == DateTime.now().year &&
            d.month == DateTime.now().month &&
            d.day == DateTime.now().day);
      }
    });
  }

  void _showContextMenu(BuildContext context, DailyHabit habit) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(habit.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _openEdit(habit); },
            child: const Text('Edit Habit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () { Navigator.pop(context); _confirmDelete(habit); },
            child: const Text('Delete Habit'),
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
    final completed = _habits.where((h) => h.completedToday).toList();
    final pending = _habits.where((h) => !h.completedToday).toList();
    final String completionRate = _habits.isEmpty
        ? '0%'
        : '${((completed.length / _habits.length) * 100).toStringAsFixed(0)}%';

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
            Text('Daily Check-ins',
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
      body: _habits.isEmpty
          ? _buildEmpty()
          : _buildList(completed, pending, completionRate),
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
                color: _T.tealBg,
                borderRadius: BorderRadius.circular(_T.r16),
                border: Border.all(color: _T.tealBorder),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: _T.teal, size: 32),
            ),
            const SizedBox(height: _T.s20),
            Text('No habits yet', style: _T.heading(size: 22)),
            const SizedBox(height: _T.s8),
            Text(
              'Tap "Add" to create your first daily habit and start tracking.',
              textAlign: TextAlign.center,
              style: _T.body(size: 14),
            ),
            const SizedBox(height: _T.s32),
            _PrimaryBtn(label: 'Add your first habit', onTap: _openAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<DailyHabit> completed, List<DailyHabit> pending, String completionRate) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary strip ──
          _SummaryStrip(total: _habits.length, completed: completed.length, rate: completionRate),
          Divider(height: 1, thickness: 1, color: _T.border),

          // ── Today's focus ──
          if (pending.isNotEmpty) ...[
            _SectionHeader(label: 'Today', accent: _T.teal, bg: _T.tealBg, border: _T.tealBorder, dot: _T.teal),
            ...pending.map((h) => _HabitCard(
                  key: ValueKey(h.hashCode),
                  habit: h,
                  onToggle: () => _toggleComplete(h),
                  onEdit: () => _openEdit(h),
                  onDelete: () => _confirmDelete(h),
                  onLongPress: () => _showContextMenu(context, h),
                )),
          ],

          // ── Completed ──
          if (completed.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: _T.border),
            _SectionHeader(label: 'Completed Today', accent: _T.purple, bg: _T.purpleBg, border: _T.purpleBorder, dot: _T.purple),
            ...completed.map((h) => _HabitCard(
                  key: ValueKey(h.hashCode),
                  habit: h,
                  onToggle: () => _toggleComplete(h),
                  onEdit: () => _openEdit(h),
                  onDelete: () => _confirmDelete(h),
                  onLongPress: () => _showContextMenu(context, h),
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
  final int total, completed;
  final String rate;
  const _SummaryStrip({required this.total, required this.completed, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _SummaryCell(
              icon: Icons.calendar_today_outlined,
              value: '$total',
              label: 'Total Habits',
              iconBg: _T.tealBg,
              iconColor: _T.teal,
              valueColor: _T.tealDark,
              labelColor: _T.teal,
            )),
            VerticalDivider(width: 1, thickness: 1, color: _T.border),
            Expanded(child: _SummaryCell(
              icon: Icons.check_circle_outline,
              value: '$completed',
              label: 'Completed',
              iconBg: _T.purpleBg,
              iconColor: _T.purple,
              valueColor: _T.purpleDeep,
              labelColor: _T.purple,
            )),
            VerticalDivider(width: 1, thickness: 1, color: _T.border),
            Expanded(child: _SummaryCell(
              icon: Icons.show_chart_rounded,
              value: rate,
              label: 'Completion rate',
              iconBg: _T.blueBg,
              iconColor: _T.blue,
              valueColor: _T.blueDark,
              labelColor: _T.blue,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

// ─── Habit Card ────────────────────────────────────────────────────────────────
class _HabitCard extends StatefulWidget {
  final DailyHabit habit;
  final VoidCallback onToggle, onEdit, onDelete, onLongPress;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: widget.onLongPress,
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
              // Icon
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: habit.completedToday
                        ? habit.color
                        : habit.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(_T.r8),
                  ),
                  child: Icon(habit.icon,
                      color: habit.completedToday ? Colors.white : habit.color,
                      size: 20),
                ),
              ),
              const SizedBox(width: _T.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(habit.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _T.ink,
                                letterSpacing: -0.3)),
                      ),
                      if (habit.completedToday) ...[
                        const Icon(Icons.check_circle, color: _T.teal, size: 16),
                        const SizedBox(width: _T.s4),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(habit.description, style: _T.body(size: 12)),
                    const SizedBox(height: _T.s12),
                    _WeekDots(habit: habit),
                    const SizedBox(height: _T.s8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Streak: ${habit.streak} · Total: ${habit.totalDays}',
                            style: _T.label(size: 11)),
                        GestureDetector(
                          onTap: widget.onToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: habit.completedToday
                                  ? _T.canvas
                                  : habit.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(_T.r100),
                              border: Border.all(
                                color: habit.completedToday
                                    ? _T.border
                                    : habit.color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              habit.completedToday ? '✓ Done' : '○ Pending',
                              style: _T.label(size: 10, color: habit.completedToday ? _T.ink3 : habit.color),
                            ),
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
      ));
  }
}

// ─── Week Dots ────────────────────────────────────────────────────────────────
class _WeekDots extends StatelessWidget {
  final DailyHabit habit;
  const _WeekDots({required this.habit});

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
        final isCompleted = habit.completionHistory.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day &&
            habit.completedToday;

        Color dotColor;
        if (isFuture) {
          dotColor = _T.canvas;
        } else if (isCompleted || isToday) {
          dotColor = habit.color;
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

// ─── New / Edit Habit Bottom Sheet ──────────────────────────────────────────
class NewHabitSheet extends StatefulWidget {
  final DailyHabit? existing;
  const NewHabitSheet({super.key, this.existing});

  @override
  State<NewHabitSheet> createState() => _NewHabitSheetState();
}

class _NewHabitSheetState extends State<NewHabitSheet> {
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
    Icons.calendar_today_outlined,
    Icons.fitness_center_outlined,
    Icons.directions_run_outlined,
    Icons.directions_bike_outlined,
    Icons.pool_outlined,
    Icons.sports_martial_arts_outlined,
    Icons.sports_basketball_outlined,
    Icons.sports_soccer_outlined,
    Icons.hiking_outlined,
    Icons.self_improvement_outlined,
    Icons.monitor_heart_outlined,
    Icons.medication_outlined,
    Icons.restaurant_outlined,
    Icons.water_drop_outlined,
    Icons.coffee_outlined,
    Icons.no_food_outlined,
    Icons.lunch_dining_outlined,
    Icons.apple_outlined,
    Icons.menu_book_outlined,
    Icons.psychology_outlined,
    Icons.school_outlined,
    Icons.lightbulb_outline,
    Icons.edit_note_outlined,
    Icons.quiz_outlined,
    Icons.wb_sunny_outlined,
    Icons.bedtime_outlined,
    Icons.alarm_outlined,
    Icons.weekend_outlined,
    Icons.cleaning_services_outlined,
    Icons.shower_outlined,
    Icons.brush_outlined,
    Icons.music_note_outlined,
    Icons.camera_alt_outlined,
    Icons.palette_outlined,
    Icons.piano_outlined,
    Icons.theater_comedy_outlined,
    Icons.code_outlined,
    Icons.laptop_outlined,
    Icons.work_outline,
    Icons.bar_chart_outlined,
    Icons.savings_outlined,
    Icons.attach_money_outlined,
    Icons.favorite_outline,
    Icons.people_outline,
    Icons.volunteer_activism_outlined,
    Icons.eco_outlined,
    Icons.star_outline,
    Icons.emoji_events_outlined,
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
    _descCtrl = TextEditingController(text: e?.description ?? '');
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

    Navigator.pop(context, DailyHabit(
      title: name,
      description: _descCtrl.text.trim(),
      color: _colors[_selectedColorIndex],
      icon: _icons[_selectedIconIndex],
      category: _category == 'None' ? 'General' : _category,
      completedToday: widget.existing?.completedToday ?? false,
      lastCompletedDate: widget.existing?.lastCompletedDate,
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
          // ── Header ──
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
                    _isEdit ? 'Edit Habit' : 'New Habit',
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
                  // ── Live preview ──
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

                  // Name
                  _FormSection(label: 'Name', child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('e.g. Morning Meditation'),
                  )),
                  const SizedBox(height: _T.s16),

                  // Description
                  _FormSection(label: 'Description', child: TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('What does this habit involve?'),
                  )),
                  const SizedBox(height: _T.s16),

                  // Category
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

                  // Icon picker
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

                  // Color picker
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

          // ── Save button ──
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
                          _isEdit ? 'Save Changes' : 'Create Habit',
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

// ─── Form section ─────────────────────────────────────────────────────────────
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