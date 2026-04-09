// ignore_for_file: deprecated_member_use, unused_element, unused_field, curly_braces_in_flow_control_structures, unused_shown_name

import 'package:flutter/material.dart';
import 'package:habit_tracker/screens/goals_screen.dart' show Goal, GoalsStorageService;
import 'package:habit_tracker/screens/streaks_screen.dart' show Streak, StreaksStorageService;

// ─── Design Tokens ────────────────────────────────────────────────────────────
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
  static const double r8  = 8;
  static const double r12 = 12;
  static const double r16 = 16;
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

// ─── Data for display ─────────────────────────────────────────────────────────
class _HabitEntry {
  final String name;
  final Color color;
  final IconData icon;
  final int currentDays;
  final int targetDays;
  final int streak;
  final int totalCompletions;
  final List<DateTime> history;

  const _HabitEntry({
    required this.name,
    required this.color,
    required this.icon,
    required this.currentDays,
    required this.targetDays,
    required this.streak,
    required this.totalCompletions,
    required this.history,
  });

  double get progress => (currentDays / targetDays).clamp(0.0, 1.0);
  String get pct => '${(progress * 100).toStringAsFixed(0)}%';

  static _HabitEntry fromGoal(Goal g) => _HabitEntry(
    name: g.title,
    color: g.color,
    icon: g.icon,
    currentDays: g.currentDays,
    targetDays: g.targetDays,
    streak: g.currentStreak,
    totalCompletions: g.completionHistory.length,
    history: g.completionHistory,
  );

  static _HabitEntry fromStreak(Streak s) => _HabitEntry(
    name: s.title,
    color: s.color,
    icon: s.icon,
    currentDays: s.currentStreak,
    targetDays: 30,
    streak: s.currentStreak,
    totalCompletions: s.totalCompletions,
    history: s.completionHistory,
  );
}

// ─── Track Progress Screen ────────────────────────────────────────────────────
class TrackProgressScreen extends StatefulWidget {
  const TrackProgressScreen({super.key});

  @override
  State<TrackProgressScreen> createState() => _TrackProgressScreenState();
}

class _TrackProgressScreenState extends State<TrackProgressScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFilter = 0;
  late final TabController _tabCtrl;
List<Goal> _goals = [];      // Goal from goals_screen.dart
List<Streak> _streaks = [];  // Streak from streaks_screen.dart
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() => _selectedFilter = _tabCtrl.index));
    _loadData();
  }
Future<void> _loadData() async {
  try {
    final goals = await GoalsStorageService.loadGoals();
    final streaks = await StreaksStorageService.loadStreaks();
    if (mounted) {
      setState(() {
        _goals = goals;      // no cast needed
        _streaks = streaks;  // no cast needed
        _loading = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _T.canvas,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_T.purple),
          ),
        ),
      );
    }

    final allHabits = <_HabitEntry>[
      ..._goals.map(_HabitEntry.fromGoal),
      ..._streaks.map(_HabitEntry.fromStreak),
    ];

    final filteredHabits = _selectedFilter == 0
        ? allHabits
        : _selectedFilter == 1
            ? allHabits.where((h) => _goals.any((g) => g.title == h.name)).toList()
            : allHabits.where((h) => _streaks.any((s) => s.title == h.name)).toList();

    return Scaffold(
      backgroundColor: _T.canvas,
      appBar: _buildAppBar(),
      body: allHabits.isEmpty ? _buildEmpty() : _buildBody(filteredHabits, allHabits),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          const Text('Progress',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _T.ink,
                  letterSpacing: -0.4)),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _T.border),
      ),
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
              child: const Icon(Icons.show_chart_rounded, color: _T.teal, size: 32),
            ),
            const SizedBox(height: _T.s20),
            Text('No data yet', style: _T.heading(size: 22)),
            const SizedBox(height: _T.s8),
            Text(
              'Start logging your habits to see your progress charts here.',
              textAlign: TextAlign.center,
              style: _T.body(size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<_HabitEntry> filteredHabits, List<_HabitEntry> allHabits) {
    final totalDaysLogged = filteredHabits.fold(0, (s, h) => s + h.currentDays);
    final bestStreak = filteredHabits.isEmpty
        ? 0
        : filteredHabits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final avgProgress = filteredHabits.isEmpty
        ? 0.0
        : filteredHabits.map((h) => h.progress).reduce((a, b) => a + b) /
            filteredHabits.length;
    final completedHabits = filteredHabits.where((h) => h.progress >= 1.0).length;

    List<double> weeklyData() {
      final now = DateTime.now();
      return List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final logged = filteredHabits
            .where((h) => h.history.any((d) =>
                d.year == day.year &&
                d.month == day.month &&
                d.day == day.day))
            .length;
        return filteredHabits.isEmpty ? 0 : logged / filteredHabits.length;
      });
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsStrip(
            totalDays: totalDaysLogged,
            bestStreak: bestStreak,
            avgProgress: avgProgress,
            completed: completedHabits,
          ),
          const Divider(height: 1, thickness: 1, color: _T.border),
          const _SectionHeader(
            label: 'This Week',
            bg: _T.tealBg, border: _T.tealBorder,
            dot: _T.teal, text: _T.tealDark,
          ),
          _WeeklyChart(data: weeklyData(), habits: filteredHabits),
          const Divider(height: 1, thickness: 1, color: _T.border),
          const _SectionHeader(
            label: 'Habit Breakdown',
            bg: _T.purpleBg, border: _T.purpleBorder,
            dot: _T.purple, text: _T.purpleDark,
          ),
          _FilterTabs(controller: _tabCtrl),
          const SizedBox(height: _T.s8),
          ...filteredHabits.map((h) => _HabitProgressCard(habit: h)),
          const Divider(height: 1, thickness: 1, color: _T.border),
          const _SectionHeader(
            label: 'Activity Heatmap',
            bg: _T.coralBg, border: _T.coralBorder,
            dot: _T.coral, text: _T.coralDark,
          ),
          _ActivityHeatmap(habits: filteredHabits),
          const Divider(height: 1, thickness: 1, color: _T.border),
          if (filteredHabits.isNotEmpty) ...[
            const _SectionHeader(
              label: 'Top Performer',
              bg: _T.amberBg, border: _T.amberBorder,
              dot: _T.amber, text: _T.amber,
            ),
            _TopPerformerCard(
                habit: filteredHabits
                    .reduce((a, b) => a.progress > b.progress ? a : b)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Stats Strip ──────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int totalDays, bestStreak, completed;
  final double avgProgress;
  const _StatsStrip({
    required this.totalDays, required this.bestStreak,
    required this.avgProgress, required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 600;
    if (isPhone) {
      return Container(
        color: _T.surface,
        child: Column(children: [
          IntrinsicHeight(
            child: Row(children: [
              Expanded(child: _StatCell(icon: Icons.show_chart_rounded, value: '$totalDays', label: 'Days Logged', iconBg: _T.tealBg, iconColor: _T.teal, valueColor: _T.tealDark, labelColor: _T.teal)),
              const VerticalDivider(width: 1, thickness: 1, color: _T.border),
              Expanded(child: _StatCell(icon: Icons.local_fire_department_outlined, value: '${bestStreak}d', label: 'Best Streak', iconBg: _T.coralBg, iconColor: _T.coral, valueColor: _T.coralDark, labelColor: _T.coral)),
            ]),
          ),
          const Divider(height: 1, thickness: 1, color: _T.border),
          IntrinsicHeight(
            child: Row(children: [
              Expanded(child: _StatCell(icon: Icons.radio_button_checked_outlined, value: '${(avgProgress * 100).toStringAsFixed(0)}%', label: 'Avg Progress', iconBg: _T.purpleBg, iconColor: _T.purple, valueColor: _T.purpleDeep, labelColor: _T.purple)),
              const VerticalDivider(width: 1, thickness: 1, color: _T.border),
              Expanded(child: _StatCell(icon: Icons.emoji_events_outlined, value: '$completed', label: 'Completed', iconBg: _T.amberBg, iconColor: _T.amber, valueColor: _T.amber, labelColor: _T.amber)),
            ]),
          ),
        ]),
      );
    }
    return Container(
      color: _T.surface,
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(child: _StatCell(icon: Icons.show_chart_rounded, value: '$totalDays', label: 'Days Logged', iconBg: _T.tealBg, iconColor: _T.teal, valueColor: _T.tealDark, labelColor: _T.teal)),
          const VerticalDivider(width: 1, thickness: 1, color: _T.border),
          Expanded(child: _StatCell(icon: Icons.local_fire_department_outlined, value: '${bestStreak}d', label: 'Best Streak', iconBg: _T.coralBg, iconColor: _T.coral, valueColor: _T.coralDark, labelColor: _T.coral)),
          const VerticalDivider(width: 1, thickness: 1, color: _T.border),
          Expanded(child: _StatCell(icon: Icons.radio_button_checked_outlined, value: '${(avgProgress * 100).toStringAsFixed(0)}%', label: 'Avg Progress', iconBg: _T.purpleBg, iconColor: _T.purple, valueColor: _T.purpleDeep, labelColor: _T.purple)),
          const VerticalDivider(width: 1, thickness: 1, color: _T.border),
          Expanded(child: _StatCell(icon: Icons.emoji_events_outlined, value: '$completed', label: 'Completed', iconBg: _T.amberBg, iconColor: _T.amber, valueColor: _T.amber, labelColor: _T.amber)),
        ]),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color iconBg, iconColor, valueColor, labelColor;
  const _StatCell({required this.icon, required this.value, required this.label, required this.iconBg, required this.iconColor, required this.valueColor, required this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(_T.r8)), child: Icon(icon, size: 16, color: iconColor)),
          const SizedBox(height: _T.s12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: valueColor, letterSpacing: -1.2)),
          const SizedBox(height: 3),
          Text(label, style: _T.label(size: 10, color: labelColor)),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color bg, border, dot, text;
  const _SectionHeader({required this.label, required this.bg, required this.border, required this.dot, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        color: _T.canvas,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: _EyebrowPill(label: label.toUpperCase(), bg: bg, border: border, dot: dot, text: text),
      );
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<double> data;
  final List<_HabitEntry> habits;
  const _WeeklyChart({required this.data, required this.habits});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(_T.r16), border: Border.all(color: _T.border)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Completion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink, letterSpacing: -0.3)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _T.tealBg, borderRadius: BorderRadius.circular(_T.r100), border: Border.all(color: _T.tealBorder)),
                  child: Text('${habits.length} habit${habits.length == 1 ? '' : 's'}', style: _T.label(size: 10, color: _T.teal)),
                ),
              ],
            ),
            const SizedBox(height: _T.s20),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final pct = data[i];
                  final isToday = i == today;
                  final isFuture = i > today;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isFuture && pct > 0)
                            Text('${(pct * 100).toStringAsFixed(0)}%', style: _T.label(size: 9, color: isToday ? _T.purple : _T.teal)),
                          const SizedBox(height: 3),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(color: _T.canvas, borderRadius: BorderRadius.circular(_T.r8), border: Border.all(color: _T.border)),
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.hardEdge,
                            child: isFuture
                                ? const SizedBox()
                                : FractionallySizedBox(
                                    heightFactor: pct == 0 ? 0.04 : pct,
                                    child: Container(decoration: BoxDecoration(color: isToday ? _T.purple : _T.teal, borderRadius: BorderRadius.circular(_T.r8))),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: _T.s8),
            Row(
              children: List.generate(7, (i) {
                final isToday = i == today;
                return Expanded(child: Text(days[i].substring(0, 1), textAlign: TextAlign.center, style: _T.label(size: 10, color: isToday ? _T.purple : _T.ink3)));
              }),
            ),
            const SizedBox(height: _T.s16),
            Row(children: [
              _LegendDot(color: _T.teal, label: 'Past'),
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
  Widget build(BuildContext context) => Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: _T.label(size: 11)),
      ]);
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final TabController controller;
  const _FilterTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(color: _T.canvas, borderRadius: BorderRadius.circular(_T.r8), border: Border.all(color: _T.border)),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _T.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _T.ink),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _T.ink3),
          labelPadding: EdgeInsets.zero,
          tabs: const [Tab(text: 'All'), Tab(text: 'Goals'), Tab(text: 'Streaks')],
        ),
      ),
    );
  }
}

// ─── Habit Progress Card ──────────────────────────────────────────────────────
class _HabitProgressCard extends StatefulWidget {
  final _HabitEntry habit;
  const _HabitProgressCard({required this.habit});
  @override
  State<_HabitProgressCard> createState() => _HabitProgressCardState();
}

class _HabitProgressCardState extends State<_HabitProgressCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: _hovered ? const Color(0xFFF5F4F1) : _T.surface, borderRadius: BorderRadius.circular(_T.r12), border: Border.all(color: _T.border)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38, height: 38,
                decoration: BoxDecoration(color: _hovered ? h.color : h.color.withOpacity(0.12), borderRadius: BorderRadius.circular(_T.r8)),
                child: Icon(h.icon, color: _hovered ? Colors.white : h.color, size: 18),
              ),
              const SizedBox(width: _T.s12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text('${h.currentDays} / ${h.targetDays} days', style: _T.label(size: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(h.pct, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: h.color, letterSpacing: -0.8)),
                Text('complete', style: _T.label(size: 9)),
              ]),
            ]),
            const SizedBox(height: _T.s12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: h.progress, minHeight: 5, backgroundColor: _T.border, valueColor: AlwaysStoppedAnimation(h.color)),
            ),
            const SizedBox(height: _T.s12),
            _MiniWeekDots(habit: h),
            const SizedBox(height: _T.s8),
            Row(children: [
              _StatPill(icon: Icons.local_fire_department_outlined, label: '${h.streak}d streak', color: _T.coral),
              const SizedBox(width: _T.s8),
              _StatPill(icon: Icons.check_circle_outline, label: '${h.totalCompletions} total', color: _T.teal),
              const Spacer(),
              if (h.progress >= 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _T.tealBg, borderRadius: BorderRadius.circular(_T.r100), border: Border.all(color: _T.tealBorder)),
                  child: Text('✓ Done', style: _T.label(size: 10, color: _T.teal)),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(_T.r100), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: _T.label(size: 10, color: color)),
        ]),
      );
}

// ─── Mini Week Dots ───────────────────────────────────────────────────────────
class _MiniWeekDots extends StatelessWidget {
  final _HabitEntry habit;
  const _MiniWeekDots({required this.habit});
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
        final isLogged = habit.history.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
        Color dotColor;
        if (isFuture) dotColor = _T.canvas;
        else if (isLogged) dotColor = habit.color;
        else dotColor = _T.border;
        return Expanded(
          child: Column(children: [
            Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 3),
            Text(days[i], style: _T.label(size: 9, color: isFuture ? _T.canvas : _T.ink3)),
          ]),
        );
      }),
    );
  }
}

// ─── Activity Heatmap ─────────────────────────────────────────────────────────
class _ActivityHeatmap extends StatelessWidget {
  final List<_HabitEntry> habits;
  const _ActivityHeatmap({required this.habits});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const totalDays = 70;
    final startDate = now.subtract(const Duration(days: totalDays - 1));
    final Map<String, int> dayCount = {};
    for (final h in habits) {
      for (final d in h.history) {
        final key = '${d.year}-${d.month}-${d.day}';
        dayCount[key] = (dayCount[key] ?? 0) + 1;
      }
    }
    final maxCount = habits.isEmpty ? 1 : habits.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(_T.r16), border: Border.all(color: _T.border)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last 10 Weeks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _T.ink, letterSpacing: -0.3)),
                _EyebrowPill(label: '${habits.fold(0, (s, h) => s + h.totalCompletions)} logs', bg: _T.coralBg, border: _T.coralBorder, dot: _T.coral, text: _T.coralDark),
              ],
            ),
            const SizedBox(height: _T.s16),
            Row(children: [
              const SizedBox(width: 24),
              ...List.generate(7, (i) {
                const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Expanded(child: Text(dayNames[i], textAlign: TextAlign.center, style: _T.label(size: 9)));
              }),
            ]),
            const SizedBox(height: _T.s4),
            ...List.generate(10, (week) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  SizedBox(width: 24, child: week % 2 == 0 ? Text('W${10 - week}', style: _T.label(size: 8), textAlign: TextAlign.left) : const SizedBox()),
                  ...List.generate(7, (day) {
                    final dayIndex = week * 7 + day;
                    final date = startDate.add(Duration(days: dayIndex));
                    final key = '${date.year}-${date.month}-${date.day}';
                    final count = dayCount[key] ?? 0;
                    final isFuture = date.isAfter(now);
                    final intensity = isFuture ? 0.0 : (count / maxCount);
                    Color cellColor;
                    if (isFuture || count == 0) cellColor = _T.canvas;
                    else cellColor = _T.coral.withOpacity(0.2 + intensity * 0.8);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 14,
                        decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(3), border: Border.all(color: isFuture || count == 0 ? _T.border : Colors.transparent)),
                      ),
                    );
                  }),
                ]),
              );
            }),
            const SizedBox(height: _T.s12),
            Row(children: [
              Text('Less', style: _T.label(size: 10)),
              const SizedBox(width: _T.s8),
              ...List.generate(5, (i) => Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: _T.coral.withOpacity(0.1 + i * 0.2), borderRadius: BorderRadius.circular(3)))),
              const SizedBox(width: _T.s8),
              Text('More', style: _T.label(size: 10)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Top Performer Card ───────────────────────────────────────────────────────
class _TopPerformerCard extends StatelessWidget {
  final _HabitEntry habit;
  const _TopPerformerCard({required this.habit});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(color: _T.ink, borderRadius: BorderRadius.circular(_T.r16)),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: habit.color.withOpacity(0.2), borderRadius: BorderRadius.circular(_T.r8), border: Border.all(color: habit.color.withOpacity(0.4))), child: Icon(habit.icon, color: habit.color, size: 22)),
              const SizedBox(width: _T.s12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _T.surface, letterSpacing: -0.4)),
                const SizedBox(height: 3),
                Text('Your best habit this period', style: _T.label(size: 11, color: const Color(0xFF888888))),
              ])),
              Text(habit.pct, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: habit.color, letterSpacing: -1.2)),
            ]),
            const SizedBox(height: _T.s20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: habit.progress, minHeight: 4, backgroundColor: const Color(0xFF2A2A2A), valueColor: AlwaysStoppedAnimation(habit.color)),
            ),
            const SizedBox(height: _T.s16),
            Row(children: [
              _DarkBadge(value: '${habit.currentDays}d', sub: 'logged'),
              const SizedBox(width: _T.s8),
              _DarkBadge(value: '${habit.streak}d', sub: 'streak'),
              const SizedBox(width: _T.s8),
              _DarkBadge(value: '${habit.totalCompletions}', sub: 'total'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  final String value, sub;
  const _DarkBadge({required this.value, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(_T.r8)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _T.surface)),
          const SizedBox(height: 2),
          Text(sub, style: _T.label(size: 9, color: const Color(0xFF666666))),
        ]),
      );
}

// ─── Primitives ───────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: _T.ink, borderRadius: BorderRadius.circular(size * 0.22)),
        child: Center(child: Container(width: size * 0.30, height: size * 0.30, decoration: const BoxDecoration(color: _T.surface, shape: BoxShape.circle))),
      );
}

class _EyebrowPill extends StatelessWidget {
  final String label;
  final Color bg, border, dot, text;
  const _EyebrowPill({required this.label, required this.bg, required this.border, required this.dot, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(_T.r100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: text, letterSpacing: 0.6)),
        ]),
      );
}