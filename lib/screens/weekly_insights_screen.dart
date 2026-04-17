// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field, unnecessary_import, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps, library_private_types_in_public_api

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:habit_tracker/theme/app_tokens.dart';
import 'package:habit_tracker/screens/goals_screen.dart';
import 'package:habit_tracker/screens/streaks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/config/app_config.dart';
import 'package:habit_tracker/services/ai_review_service.dart';
import 'package:habit_tracker/services/cloud_functions_service.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import 'package:habit_tracker/screens/paywall_screen.dart';


// ─── Data models ──────────────────────────────────────────────────────────────

class WeeklyMetric {
  final String title, value, description, trend;
  final IconData icon;
  final Color color, bgColor;
  const WeeklyMetric({
    required this.title, required this.value, required this.description,
    required this.icon, required this.color, required this.bgColor,
    this.trend = '→',
  });
}

class _HabitRow {
  final String name;
  final Color color;
  final int completed, total;
  _HabitRow(this.name, this.color, this.completed, this.total);
  double get pct => total == 0 ? 0 : completed / total;
}

class _HeatmapRow {
  final String name;
  final List<bool> days; // length 7, Mon=0
  _HeatmapRow(this.name, this.days);
}

class _AIInsightItem {
  final IconData icon;
  final String title, body;
  final Color color, bg;
  const _AIInsightItem(this.icon, this.title, this.body, this.color, this.bg);
}

// ─── Computed insights data ───────────────────────────────────────────────────

class _InsightsData {
  final List<Goal> goals;
  final List<Streak> streaks;

  const _InsightsData(this.goals, this.streaks);

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _isoWeekNumber(DateTime date) {
    final doy = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((doy - date.weekday + 10) / 7).floor();
  }

  bool _doneOn(List<DateTime> history, DateTime day) =>
      history.any((d) => _sameDay(d, day));

  // Monday..Sunday of the current week.
  static List<DateTime> get weekDays {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    final base = DateTime(mon.year, mon.month, mon.day);
    return List.generate(7, (i) => base.add(Duration(days: i)));
  }

  // ── Aggregate properties ───────────────────────────────────────────────────

  int get weekNumber => _isoWeekNumber(DateTime.now());

  int get totalHabits => goals.length + streaks.length;

  /// Completions per day (index 0 = Mon, 6 = Sun).
  List<int> get dailyCompletions {
    final days = weekDays;
    return days.map((day) {
      int n = 0;
      for (final g in goals) if (_doneOn(g.completionHistory, day)) n++;
      for (final s in streaks) if (_doneOn(s.completionHistory, day)) n++;
      return n;
    }).toList();
  }

  int get totalLoggedThisWeek => dailyCompletions.fold(0, (a, b) => a + b);

  /// Completion % across all habit-days this week.
  int get weeklyCompletionPct {
    final possible = totalHabits * 7;
    if (possible == 0) return 0;
    return ((totalLoggedThisWeek / possible) * 100).clamp(0, 100).toInt();
  }

  /// Days where every single habit was completed.
  int get perfectDaysThisWeek {
    if (totalHabits == 0) return 0;
    return dailyCompletions.where((c) => c == totalHabits).length;
  }

  int get bestCurrentStreak {
    int best = 0;
    for (final g in goals) if (g.currentStreak > best) best = g.currentStreak;
    for (final s in streaks) if (s.currentStreak > best) best = s.currentStreak;
    return best;
  }

  // ── Key metric cards ───────────────────────────────────────────────────────

  List<WeeklyMetric> get keyMetrics {
    final pct = weeklyCompletionPct;
    final trend = pct >= 70 ? '↑' : pct < 40 ? '↓' : '→';
    final dc = dailyCompletions;
    return [
      WeeklyMetric(
        title: 'Completion',
        value: '$pct%',
        description: 'This week',
        icon: Icons.show_chart_rounded,
        color: AppTokens.teal,
        bgColor: AppTokens.teal.withOpacity(0.12),
        trend: trend,
      ),
      WeeklyMetric(
        title: 'Streak',
        value: '${bestCurrentStreak}d',
        description: 'Current best',
        icon: Icons.local_fire_department_outlined,
        color: AppTokens.coral,
        bgColor: AppTokens.coral.withOpacity(0.12),
        trend: bestCurrentStreak > 0 ? '↑' : '→',
      ),
      WeeklyMetric(
        title: 'Perfect Days',
        value: '$perfectDaysThisWeek/7',
        description: '100% completion',
        icon: Icons.calendar_today_outlined,
        color: AppTokens.blue,
        bgColor: AppTokens.blue.withOpacity(0.12),
        trend: perfectDaysThisWeek >= 4 ? '↑' : perfectDaysThisWeek == 0 ? '↓' : '→',
      ),
      WeeklyMetric(
        title: 'Total Logged',
        value: '$totalLoggedThisWeek',
        description: 'Completions',
        icon: Icons.check_circle_outline,
        color: AppTokens.purple,
        bgColor: AppTokens.purple.withOpacity(0.12),
        trend: totalLoggedThisWeek > 0 ? '→' : '↓',
      ),
    ];
  }

  // ── Heatmap ────────────────────────────────────────────────────────────────

  List<_HeatmapRow> get heatmapRows {
    final days = weekDays;
    return [
      ...goals.map((g) => _HeatmapRow(
          g.title, days.map((d) => _doneOn(g.completionHistory, d)).toList())),
      ...streaks.map((s) => _HeatmapRow(
          s.title, days.map((d) => _doneOn(s.completionHistory, d)).toList())),
    ];
  }

  String get heatmapSummary {
    if (totalHabits == 0) return '0/0 (0%)';
    final total = totalHabits * 7;
    final done = totalLoggedThisWeek;
    final pct = (done / total * 100).toStringAsFixed(0);
    return '$done/$total ($pct%)';
  }

  // ── Top habits ─────────────────────────────────────────────────────────────

  List<_HabitRow> get topHabits {
    final days = weekDays;
    final rows = <_HabitRow>[
      ...goals.map((g) {
        final done = days.where((d) => _doneOn(g.completionHistory, d)).length;
        return _HabitRow(g.title, g.color, done, 7);
      }),
      ...streaks.map((s) {
        final done = days.where((d) => _doneOn(s.completionHistory, d)).length;
        return _HabitRow(s.title, s.color, done, 7);
      }),
    ];
    rows.sort((a, b) => b.pct.compareTo(a.pct));
    return rows.take(4).toList();
  }

  // ── AI insights ────────────────────────────────────────────────────────────

  List<_AIInsightItem> get aiInsights {
    final list = <_AIInsightItem>[];
    final dc = dailyCompletions;
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Best day
    if (dc.any((c) => c > 0)) {
      final maxVal = dc.reduce(max);
      final maxIdx = dc.indexOf(maxVal);
      list.add(_AIInsightItem(
        Icons.trending_up_rounded,
        '📈 Best Day This Week',
        '${dayNames[maxIdx]} was your strongest day with $maxVal completions.',
        AppTokens.teal, AppTokens.teal.withOpacity(0.12),
      ));
    }

    // Worst active day
    final nonZero = dc.where((c) => c > 0).toList();
    if (nonZero.length > 1) {
      final minVal = nonZero.reduce(min);
      final minIdx = dc.indexOf(minVal);
      list.add(_AIInsightItem(
        Icons.warning_rounded,
        '⚠️ Room to Improve',
        '${dayNames[minIdx]} had the fewest completions ($minVal). A small push there lifts your weekly average.',
        AppTokens.coral, AppTokens.coral.withOpacity(0.12),
      ));
    }

    // Near milestone (goal almost complete)
    final near = goals
        .where((g) => !g.isCompleted && g.currentDays > 0 && (g.targetDays - g.currentDays) <= 5)
        .toList();
    if (near.isNotEmpty) {
      near.sort((a, b) => (a.targetDays - a.currentDays).compareTo(b.targetDays - b.currentDays));
      final g = near.first;
      final left = g.targetDays - g.currentDays;
      list.add(_AIInsightItem(
        Icons.star_outline,
        '⭐ Almost There!',
        '"${g.title}" is just $left day${left == 1 ? '' : 's'} away from completion. Keep going!',
        AppTokens.amber, AppTokens.amber.withOpacity(0.12),
      ));
    }

    // Best streak callout
    if (bestCurrentStreak >= 3) {
      list.add(_AIInsightItem(
        Icons.local_fire_department_outlined,
        '🔥 ${bestCurrentStreak}-Day Streak',
        'You have a $bestCurrentStreak-day streak going. Consistency is building momentum!',
        AppTokens.blue, AppTokens.blue.withOpacity(0.12),
      ));
    }

    // Empty state
    if (list.isEmpty) {
      list.add(_AIInsightItem(
        Icons.lightbulb_outline,
        '💡 Get Started',
        'Complete habits this week to unlock personalised insights here.',
        AppTokens.purple, AppTokens.purple.withOpacity(0.12),
      ));
    }

    return list;
  }
}

// ─── Weekly Insights Screen ───────────────────────────────────────────────────
class WeeklyInsightsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const WeeklyInsightsScreen({super.key, this.onBack});

  @override
  State<WeeklyInsightsScreen> createState() => _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends State<WeeklyInsightsScreen> {
  _InsightsData? _data;
  String? _aiReview;
  bool _aiLoading = false;
  String? _aiError;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await FirestoreService().loadHabits();
    final streaks = await StreaksStorageService.loadStreaks();
    if (!mounted) return;
    setState(() {
      _data = _InsightsData(goals, streaks);
      _isPremium = prefs.getBool(AppConfig.keyPremiumUnlocked) ?? false;
    });
    // Load cached review only for premium users
    if (_isPremium) {
      final cached = await AiReviewService.getCached();
      if (mounted && cached != null) setState(() => _aiReview = cached);
    }
  }

  Future<void> _generateReview() async {
    final data = _data;
    if (data == null || _aiLoading) return;
    setState(() { _aiLoading = true; _aiError = null; });
    try {
      String? review;

      if (_isPremium) {
        // Premium: Claude-generated narrative via Cloud Function (cached per week)
        review = await CloudFunctionsService.getWeeklyReview();
      }

      // Free users or Cloud Function failure: fall back to local rule-based engine
      if (review == null) {
        final breakdown = [
          ...data.goals.map((g) {
            final done = _InsightsData.weekDays
                .where((d) => g.completionHistory.any((dt) =>
                    dt.year == d.year && dt.month == d.month && dt.day == d.day))
                .length;
            return {'name': g.title, 'completed': done, 'total': 7, 'pct': (done / 7 * 100).round()};
          }),
          ...data.streaks.map((s) {
            final done = _InsightsData.weekDays
                .where((d) => s.completionHistory.any((dt) =>
                    dt.year == d.year && dt.month == d.month && dt.day == d.day))
                .length;
            return {'name': s.title, 'completed': done, 'total': 7, 'pct': (done / 7 * 100).round()};
          }),
        ];
        review = await AiReviewService.generate(
          weekNumber: data.weekNumber,
          totalHabits: data.totalHabits,
          completionPct: data.weeklyCompletionPct,
          perfectDays: data.perfectDaysThisWeek,
          bestStreak: data.bestCurrentStreak,
          habitBreakdown: breakdown,
        );
      }

      if (mounted) setState(() => _aiReview = review);
    } catch (e) {
      if (mounted) setState(() => _aiError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final data = _data;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
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
            const SizedBox(width: AppTokens.s8),
            Text('Weekly Insights',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.txt,
                    letterSpacing: -0.4)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: t.border),
        ),
      ),
      body: data == null
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(t.accent)))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Week Range Header ──
                    Container(
                      color: t.bg2,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This Week',
                                  style: t.heading(size: 22, spacing: -0.9)),
                              const SizedBox(height: AppTokens.s8),
                              Text(
                                  '${_fmt(weekStart)} – ${_fmt(weekEnd)}',
                                  style: t.body(size: 13, color: t.txt3)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTokens.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppTokens.r100),
                              border: Border.all(color: AppTokens.purple.withOpacity(0.25)),
                            ),
                            child: Text('Week ${data.weekNumber}',
                                style: t.label(size: 11, color: AppTokens.purple)),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: t.border),

                    // ── Key Metrics ──
                    Container(
                      color: t.bg,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'KEY METRICS'),
                          const SizedBox(height: AppTokens.s20),
                          _MetricsGrid(metrics: data.keyMetrics),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: t.border),

                    // ── Completion Heatmap ──
                    Container(
                      color: t.bg2,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'COMPLETION HEATMAP'),
                          const SizedBox(height: AppTokens.s20),
                          _CompletionHeatmap(
                            rows: data.heatmapRows,
                            summary: data.heatmapSummary,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: t.border),

                    // ── Daily Performance Chart ──
                    Container(
                      color: t.bg,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'DAILY PERFORMANCE'),
                          const SizedBox(height: AppTokens.s20),
                          _DailyPerformanceChart(completions: data.dailyCompletions),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: t.border),

                    // ── Top Habits ──
                    Container(
                      color: t.bg2,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'TOP PERFORMING HABITS'),
                          const SizedBox(height: AppTokens.s20),
                          data.topHabits.isEmpty
                              ? _EmptySection(
                                  icon: Icons.emoji_events_outlined,
                                  message: 'Log habits this week to see your top performers.',
                                )
                              : AppTokensopHabitsCard(habits: data.topHabits),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: t.border),

                    // ── AI Insights ──
                    Container(
                      color: t.bg,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'AI INSIGHTS'),
                          const SizedBox(height: AppTokens.s20),
                          _AIInsightsCards(insights: data.aiInsights),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: t.border),

                    // ── AI Weekly Review ──
                    Container(
                      color: t.bg2,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const _SectionLabel(label: 'AI WEEKLY REVIEW'),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s20),
                          _AIWeeklyReviewCard(
                            review: _aiReview,
                            loading: _aiLoading,
                            error: _aiError,
                            isPremium: _isPremium,
                            onGenerate: _generateReview,
                            onUnlocked: _load,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  static String _fmt(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ─── Metrics Grid ─────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final List<WeeklyMetric> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) => _MetricCard(metric: metrics[i]),
    );
  }
}

class _MetricCard extends StatefulWidget {
  final WeeklyMetric metric;
  const _MetricCard({required this.metric});

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? t.bg3 : t.bg2,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: _hovered ? widget.metric.color.withOpacity(0.4) : t.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hovered ? widget.metric.color : widget.metric.bgColor,
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: Icon(widget.metric.icon,
                      color: _hovered ? Colors.white : widget.metric.color,
                      size: 18),
                ),
                Text(widget.metric.trend,
                    style: TextStyle(
                        fontSize: 16,
                        color: widget.metric.trend == '↑'
                            ? AppTokens.teal
                            : widget.metric.trend == '↓'
                                ? AppTokens.coral
                                : t.txt3,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const Spacer(),
            Text(widget.metric.value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: widget.metric.color,
                    letterSpacing: -1.0)),
            const SizedBox(height: AppTokens.s4),
            Text(widget.metric.title,
                style: t.label(size: 11, color: t.txt2)),
            const SizedBox(height: 2),
            Text(widget.metric.description,
                style: t.body(size: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Completion Heatmap ───────────────────────────────────────────────────────
class _CompletionHeatmap extends StatelessWidget {
  final List<_HeatmapRow> rows;
  final String summary;
  const _CompletionHeatmap({required this.rows, required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    if (rows.isEmpty) {
      return _EmptySection(
        icon: Icons.grid_view_rounded,
        message: 'Add habits to see your completion heatmap.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: t.bg3,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day headers
            Padding(
              padding: const EdgeInsets.only(left: 90),
              child: Row(
                children: dayLabels
                    .map((d) => SizedBox(
                          width: 28,
                          child: Text(d,
                              textAlign: TextAlign.center,
                              style: t.label(size: 9, color: t.txt3)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            // Habit rows
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(row.name,
                            style: t.body(size: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      ...List.generate(7, (j) {
                        final done = row.days[j];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: done ? AppTokens.teal : t.bg4,
                              borderRadius: BorderRadius.circular(AppTokens.r8),
                              border: Border.all(color: t.border, width: 0.5),
                            ),
                            child: done
                                ? Icon(Icons.check,
                                    color: t.bg, size: 14)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                )),
            const SizedBox(height: AppTokens.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.bg4,
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: Text(summary, style: t.label(size: 9)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily Performance Chart ──────────────────────────────────────────────────
class _DailyPerformanceChart extends StatelessWidget {
  final List<int> completions; // length 7, Mon=0
  const _DailyPerformanceChart({required this.completions});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = completions.isEmpty ? 1 : max(completions.reduce(max), 1);
    final total = completions.fold(0, (a, b) => a + b);
    final avg = total / 7;

    // Peak and low (ignore zero-only weeks gracefully)
    final nonZeroIdx = [
      for (int i = 0; i < completions.length; i++)
        if (completions[i] > 0) i
    ];
    final peakIdx = nonZeroIdx.isEmpty
        ? 0
        : nonZeroIdx.reduce((a, b) => completions[a] >= completions[b] ? a : b);
    final lowIdx = nonZeroIdx.isEmpty
        ? 0
        : nonZeroIdx.reduce((a, b) => completions[a] <= completions[b] ? a : b);

    final todayIdx = DateTime.now().weekday - 1; // 0=Mon

    return Container(
      decoration: BoxDecoration(
        color: t.bg3,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Completions',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t.txt,
                      letterSpacing: -0.2)),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppTokens.purple, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppTokens.s4),
                  Text('Avg: ${avg.toStringAsFixed(1)}',
                      style: t.label(size: 11, color: AppTokens.purple)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final pct = completions[i] / maxVal;
                final isToday = i == todayIdx;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 140 * pct,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                isToday ? AppTokens.purple : AppTokens.teal,
                                (isToday ? AppTokens.purple : AppTokens.teal)
                                    .withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTokens.r8),
                          ),
                          child: completions[i] > 0
                              ? Center(
                                  child: Text(
                                    '${completions[i]}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: t.bg,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Text(dayLabels[i],
                            style: t.label(
                                size: 10,
                                color: isToday ? AppTokens.purple : t.txt3)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.bg4,
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (nonZeroIdx.isNotEmpty)
                  _StatSummary('Peak',
                      '${dayLabels[peakIdx]}\n${completions[peakIdx]}', AppTokens.coral),
                _StatSummary('Total', '$total\nweek', AppTokens.blue),
                _StatSummary('Avg', '${avg.toStringAsFixed(1)}\nday', AppTokens.purple),
                if (nonZeroIdx.length > 1 && lowIdx != peakIdx)
                  _StatSummary('Low',
                      '${dayLabels[lowIdx]}\n${completions[lowIdx]}', t.txt3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSummary extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatSummary(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
      final t = AppTokens.of(context);
      return Column(
    children: [
      Text(label, style: t.label(size: 10, color: t.txt3)),
      const SizedBox(height: 4),
      Text(value,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2)),
    ],
  );
  }
}

// ─── Top Habits Card ───────────────────────────────────────────────────────────
class AppTokensopHabitsCard extends StatelessWidget {
  final List<_HabitRow> habits;
  const AppTokensopHabitsCard({required this.habits});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.bg3,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: List.generate(habits.length, (i) {
          final h = habits[i];
          final pct = (h.pct * 100).toStringAsFixed(0);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(h.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: t.txt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: h.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppTokens.r100),
                          ),
                          child: Text('$pct%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: h.color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.r100),
                      child: LinearProgressIndicator(
                        value: h.pct,
                        minHeight: 6,
                        backgroundColor: t.bg4,
                        valueColor: AlwaysStoppedAnimation(h.color),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text('${h.completed}/${h.total} days',
                        style: t.label(size: 10)),
                  ],
                ),
              ),
              if (i < habits.length - 1)
                Divider(height: 1, thickness: 1, color: t.border),
            ],
          );
        }),
      ),
    );
  }
}

// ─── AI Insights Cards ────────────────────────────────────────────────────────
class _AIInsightsCards extends StatelessWidget {
  final List<_AIInsightItem> insights;
  const _AIInsightsCards({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < insights.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _InsightCard(
            icon: insights[i].icon,
            title: insights[i].title,
            body: insights[i].body,
            color: insights[i].color,
            bg: insights[i].bg,
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatefulWidget {
  final IconData icon;
  final String title, body;
  final Color color, bg;

  const _InsightCard({
    required this.icon, required this.title, required this.body,
    required this.color, required this.bg,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? t.bg3 : t.bg2,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: _hovered ? widget.color.withOpacity(0.4) : t.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _hovered ? widget.color : widget.bg,
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(widget.icon,
                  color: _hovered ? Colors.white : widget.color, size: 20),
            ),
            const SizedBox(width: AppTokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.txt,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(widget.body,
                      style: t.body(size: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI Weekly Review Card ────────────────────────────────────────────────────
class _AIWeeklyReviewCard extends StatelessWidget {
  final String? review;
  final bool loading;
  final String? error;
  final bool isPremium;
  final VoidCallback onGenerate;
  final VoidCallback? onUnlocked;
  const _AIWeeklyReviewCard({
    required this.review,
    required this.loading,
    required this.error,
    required this.isPremium,
    required this.onGenerate,
    this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);

    if (!isPremium) {
      return GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AIWeeklyReviewSheet(
            isPremium: false,
            review: null,
            loading: false,
            error: null,
            onGenerate: onGenerate,
            onUnlocked: onUnlocked,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.bg3,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.amber.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTokens.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: const Icon(Icons.lock_rounded, color: AppTokens.amber, size: 22),
              ),
              const SizedBox(height: 12),
              Text('AI Weekly Review',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: t.txt, letterSpacing: -0.2)),
              const SizedBox(height: 6),
              Text(
                'Tap to unlock a personalised AI-generated\nanalysis of your week with actionable tips.',
                textAlign: TextAlign.center,
                style: t.body(size: 12, color: t.txt3),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTokens.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTokens.r100),
                  border: Border.all(color: AppTokens.amber.withOpacity(0.3)),
                ),
                child: const Text('Pro Feature',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTokens.amber)),
              ),
            ],
          ),
        ),
      );
    }

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.bg3,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: t.border),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTokens.purple),
              ),
            ),
            const SizedBox(height: 12),
            Text('Generating your review…',
                style: t.body(size: 13, color: t.txt3)),
          ],
        ),
      );
    }

    if (review != null) {
      final paragraphs = review!
          .split('\n\n')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: AppTokens.purple.withOpacity(0.20)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTokens.purple.withOpacity(t.isDark ? 0.45 : 0.18),
                    AppTokens.purple.withOpacity(t.isDark ? 0.20 : 0.06),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppTokens.purple.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: AppTokens.purple, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Week in Review',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.txt,
                              letterSpacing: -0.3)),
                      Text('Week ${() { final d = DateTime.now(); final doy = d.difference(DateTime(d.year,1,1)).inDays+1; return ((doy-d.weekday+10)/7).floor(); }()}',
                          style: TextStyle(
                              fontSize: 11,
                              color: t.txt3,
                              letterSpacing: -0.1)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onGenerate,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTokens.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          color: AppTokens.purple, size: 15),
                    ),
                  ),
                ],
              ),
            ),
            // ── Paragraphs ───────────────────────────────────────────────
            Container(
              color: t.bg3,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < paragraphs.length; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(height: 10),
                      Divider(height: 1, color: t.border),
                      const SizedBox(height: 10),
                    ],
                    _ReviewParagraph(
                      index: i,
                      text: paragraphs[i],
                      isDark: t.isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Not yet generated
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.bg3,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTokens.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTokens.purple, size: 22),
          ),
          const SizedBox(height: 12),
          Text('Get your AI-generated review',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.txt,
                  letterSpacing: -0.2)),
          const SizedBox(height: 6),
          Text(
            'Get a personalised AI-generated\ninsight with one actionable tip.',
            textAlign: TextAlign.center,
            style: t.body(size: 12, color: t.txt3),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!,
                textAlign: TextAlign.center,
                style: t.body(size: 11, color: AppTokens.coral)),
          ],
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onGenerate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTokens.purple,
                borderRadius: BorderRadius.circular(AppTokens.r100),
              ),
              child: const Text('Generate Review',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.1)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review paragraph with leading icon ──────────────────────────────────────
class _ReviewParagraph extends StatelessWidget {
  final int index;
  final String text;
  final bool isDark;
  const _ReviewParagraph({required this.index, required this.text, required this.isDark});

  static const _icons = [
    Icons.bar_chart_rounded,
    Icons.local_fire_department_outlined,
    Icons.insights_rounded,
    Icons.emoji_objects_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final icon = _icons[index.clamp(0, _icons.length - 1)];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(top: 1, right: 10),
          decoration: BoxDecoration(
            color: AppTokens.purple.withOpacity(isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTokens.purple),
        ),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: t.txt,
                  height: 1.65,
                  letterSpacing: -0.1)),
        ),
      ],
    );
  }
}

// ─── AI Weekly Review Bottom Sheet ───────────────────────────────────────────
class _AIWeeklyReviewSheet extends StatefulWidget {
  final bool isPremium;
  final String? review;
  final bool loading;
  final String? error;
  final VoidCallback onGenerate;
  final VoidCallback? onUnlocked;
  const _AIWeeklyReviewSheet({
    required this.isPremium,
    required this.review,
    required this.loading,
    required this.error,
    required this.onGenerate,
    this.onUnlocked,
  });

  @override
  State<_AIWeeklyReviewSheet> createState() => _AIWeeklyReviewSheetState();
}

class _AIWeeklyReviewSheetState extends State<_AIWeeklyReviewSheet> {
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (!widget.isPremium) ...[
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTokens.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_rounded, color: AppTokens.amber, size: 26),
            ),
            const SizedBox(height: 16),
            Text('AI Weekly Review',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: t.txt, letterSpacing: -0.6)),
            const SizedBox(height: 8),
            Text(
              'Get a personalised AI-generated analysis of your\nweek with patterns and one actionable tip.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.txt3, height: 1.5),
            ),
            const SizedBox(height: 24),
            _SheetFeatureRow(icon: Icons.insights_rounded,      label: 'Weekly habit pattern analysis'),
            _SheetFeatureRow(icon: Icons.emoji_objects_outlined, label: 'One actionable improvement tip'),
            _SheetFeatureRow(icon: Icons.trending_up_rounded,   label: 'Streak & consistency highlights'),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                  onUnlocked?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6FD8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Unlock Pro',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: Colors.white, letterSpacing: -0.2)),
              ),
            ),
            const SizedBox(height: 10),
            Text('One-time purchase · No subscription',
                style: TextStyle(fontSize: 11, color: t.txt3)),
          ] else ...[
            // Premium: show generate / review UI
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTokens.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTokens.purple, size: 26),
            ),
            const SizedBox(height: 16),
            Text('AI Weekly Review',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: t.txt, letterSpacing: -0.6)),
            const SizedBox(height: 8),
            if (widget.loading) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTokens.purple),
                ),
              ),
              const SizedBox(height: 12),
              Text('Generating your review…',
                  style: TextStyle(fontSize: 13, color: t.txt3)),
            ] else if (widget.review != null) ...[
              const SizedBox(height: 16),
              Text(widget.review!,
                  style: TextStyle(fontSize: 14, color: t.txt, height: 1.6)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () { widget.onGenerate(); Navigator.of(context).pop(); },
                child: Text('Regenerate',
                    style: TextStyle(fontSize: 13, color: AppTokens.purple,
                        fontWeight: FontWeight.w600)),
              ),
            ] else ...[
              Text('Get a personalised AI-generated\ninsight with one actionable tip.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: t.txt3, height: 1.5)),
              if (widget.error != null) ...[
                const SizedBox(height: 10),
                Text(widget.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTokens.coral)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () { widget.onGenerate(); Navigator.of(context).pop(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Generate Review',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: Colors.white, letterSpacing: -0.2)),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  VoidCallback? get onUnlocked => widget.onUnlocked;
}

class _SheetFeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SheetFeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTokens.purple.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTokens.purple),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: t.txt, letterSpacing: -0.1)),
        const Spacer(),
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1D9E75)),
      ]),
    );
  }
}

// ─── Empty section placeholder ────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: t.bg3,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: t.txt3),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: t.body(size: 13, color: t.txt3)),
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
      final t = AppTokens.of(context);
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(size * 0.22)),
        child: Center(
          child: Container(
            width: size * 0.30, height: size * 0.30,
            decoration:
                BoxDecoration(color: t.bg, shape: BoxShape.circle),
          ),
        ),
      );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: AppTokens.purple.withOpacity(0.12),
            border: Border.all(color: AppTokens.purple.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(AppTokens.r100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6, height: 6,
              decoration:
                  BoxDecoration(color: AppTokens.purple, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.purple,
                  letterSpacing: 0.6)),
        ]),
      );
}