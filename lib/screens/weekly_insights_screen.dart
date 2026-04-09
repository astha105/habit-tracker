// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field

import 'package:flutter/material.dart';
// ignore: unnecessary_import
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
class WeeklyMetric {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String trend;

  const WeeklyMetric({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.trend = '→',
  });
}

// ─── Weekly Insights Screen ───────────────────────────────────────────────────
class WeeklyInsightsScreen extends StatefulWidget {
  const WeeklyInsightsScreen({super.key});

  @override
  State<WeeklyInsightsScreen> createState() => _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends State<WeeklyInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

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
            Text('Weekly Insights',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Week Range Header ──
            Container(
              color: _T.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This Week',
                          style: _T.heading(size: 22, spacing: -0.9)),
                      const SizedBox(height: _T.s8),
                      Text(
                          '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
                          style: _T.body(size: 13, color: _T.ink3)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _T.purpleBg,
                      borderRadius: BorderRadius.circular(_T.r100),
                      border: Border.all(color: _T.purpleBorder),
                    ),
                    child: Text('Week 14',
                        style: _T.label(size: 11, color: _T.purple)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),

            // ── Key Metrics ──
            Container(
              color: _T.canvas,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'KEY METRICS'),
                  const SizedBox(height: _T.s20),
                  _MetricsGrid(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),

            // ── Completion Heatmap ──
            Container(
              color: _T.surface,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'COMPLETION HEATMAP'),
                  const SizedBox(height: _T.s20),
                  _CompletionHeatmap(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),

            // ── Daily Performance Chart ──
            Container(
              color: _T.canvas,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'DAILY PERFORMANCE'),
                  const SizedBox(height: _T.s20),
                  _DailyPerformanceChart(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),

            // ── Top Habits ──
            Container(
              color: _T.surface,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'TOP PERFORMING HABITS'),
                  const SizedBox(height: _T.s20),
                  _TopHabitsCard(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),

            // ── AI Insights ──
            Container(
              color: _T.canvas,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'AI INSIGHTS'),
                  const SizedBox(height: _T.s20),
                  _AIInsightsCards(),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ─── Metrics Grid ─────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    final metrics = [
      WeeklyMetric(
        title: 'Completion',
        value: '82%',
        description: 'Your consistency',
        icon: Icons.show_chart_rounded,
        color: _T.teal,
        bgColor: _T.tealBg,
        trend: '↑',
      ),
      WeeklyMetric(
        title: 'Streak',
        value: '12d',
        description: 'Current best',
        icon: Icons.local_fire_department_outlined,
        color: _T.coral,
        bgColor: _T.coralBg,
        trend: '↑',
      ),
      WeeklyMetric(
        title: 'Perfect Days',
        value: '4/7',
        description: '100% completion',
        icon: Icons.calendar_today_outlined,
        color: _T.blue,
        bgColor: _T.blueBg,
        trend: '↑',
      ),
      WeeklyMetric(
        title: 'Total Logged',
        value: '58',
        description: 'Completions',
        icon: Icons.check_circle_outline,
        color: _T.purple,
        bgColor: _T.purpleBg,
        trend: '→',
      ),
    ];

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF5F4F1) : _T.surface,
          borderRadius: BorderRadius.circular(_T.r12),
          border: Border.all(color: _T.border),
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
                    borderRadius: BorderRadius.circular(_T.r8),
                  ),
                  child: Icon(widget.metric.icon,
                      color: _hovered ? _T.surface : widget.metric.color,
                      size: 18),
                ),
                Text(widget.metric.trend,
                    style: TextStyle(
                        fontSize: 16,
                        color: widget.metric.trend == '↑'
                            ? _T.teal
                            : widget.metric.trend == '↓'
                                ? _T.coral
                                : _T.ink3,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Text(widget.metric.value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: widget.metric.color,
                    letterSpacing: -1.0)),
            const SizedBox(height: _T.s4),
            Text(widget.metric.title,
                style: _T.label(size: 11, color: _T.ink2)),
            const SizedBox(height: 2),
            Text(widget.metric.description,
                style: _T.body(size: 10),
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
  const _CompletionHeatmap();

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final habits = ['Morning Run', 'Meditation', 'Reading', 'Coding'];
    final completion = [
      [1, 1, 1, 1, 0, 1, 1],
      [1, 1, 1, 1, 1, 1, 0],
      [1, 0, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0, 1, 1],
    ];

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.r12),
        border: Border.all(color: _T.border),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with days
            Padding(
              padding: const EdgeInsets.only(left: 90),
              child: Row(
                children: days.map((d) => SizedBox(
                  width: 28,
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: _T.label(size: 9, color: _T.ink3)),
                )).toList(),
              ),
            ),
            const SizedBox(height: _T.s12),
            // Heatmap rows
            ...List.generate(habits.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(habits[i],
                          style: _T.body(size: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...List.generate(7, (j) {
                      final isCompleted = completion[i][j] == 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted ? _T.teal : _T.canvas,
                            borderRadius: BorderRadius.circular(_T.r8),
                            border: Border.all(color: _T.border, width: 0.5),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, color: _T.surface, size: 14)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: _T.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _T.canvas,
                    borderRadius: BorderRadius.circular(_T.r8),
                  ),
                  child: Text('26/28 (93%)',
                      style: _T.label(size: 9)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily Performance Chart ───────────────────────────────────────────────────
class _DailyPerformanceChart extends StatelessWidget {
  const _DailyPerformanceChart();

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final completions = [12, 11, 14, 10, 9, 13, 11];
    final maxValue = 14.0;

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.r12),
        border: Border.all(color: _T.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Completions',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _T.ink,
                      letterSpacing: -0.2)),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _T.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: _T.s4),
                  Text('Avg: 11.4',
                      style: _T.label(size: 11, color: _T.purple)),
                ],
              ),
            ],
          ),
          const SizedBox(height: _T.s20),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final pct = completions[i] / maxValue;
                final isToday = i == 6;
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
                                isToday ? _T.purple : _T.teal,
                                isToday
                                    ? _T.purple.withOpacity(0.6)
                                    : _T.teal.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(_T.r8),
                            boxShadow: [
                              BoxShadow(
                                color: (isToday ? _T.purple : _T.teal)
                                    .withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${completions[i]}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _T.surface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _T.s12),
                        Text(days[i],
                            style: _T.label(
                                size: 10,
                                color: isToday ? _T.purple : _T.ink3)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: _T.s20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.canvas,
              borderRadius: BorderRadius.circular(_T.r8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatSummary('Peak', 'Wed\n14', _T.coral),
                _StatSummary('Low', 'Fri\n9', _T.blue),
                _StatSummary('Avg', '11.4\nday', _T.purple),
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
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: _T.label(size: 10, color: _T.ink3)),
      const SizedBox(height: 4),
      Text(value,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.2)),
    ],
  );
}

// ─── Top Habits Card ───────────────────────────────────────────────────────────
class _TopHabitsCard extends StatelessWidget {
  const _TopHabitsCard();

  @override
  Widget build(BuildContext context) {
    final topHabits = [
      ('Morning Run', 6, 7, _T.coral),
      ('Meditation', 6, 7, _T.purple),
      ('Reading', 6, 7, _T.blue),
      ('Coding', 5, 7, _T.amber),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.r12),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: List.generate(topHabits.length, (i) {
          final name = topHabits[i].$1;
          final completed = topHabits[i].$2;
          final total = topHabits[i].$3;
          final color = topHabits[i].$4;
          final pct = (completed / total * 100).toStringAsFixed(0);
          
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
                        Text(name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _T.ink)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(_T.r100),
                          ),
                          child: Text('$pct%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: _T.s12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_T.r100),
                      child: LinearProgressIndicator(
                        value: completed / total,
                        minHeight: 6,
                        backgroundColor: _T.canvas,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(height: _T.s8),
                    Text('$completed/$total days',
                        style: _T.label(size: 10)),
                  ],
                ),
              ),
              if (i < topHabits.length - 1)
                Divider(height: 1, thickness: 1, color: _T.border),
            ],
          );
        }),
      ),
    );
  }
}

// ─── AI Insights Cards ─────────────────────────────────────────────────────────
class _AIInsightsCards extends StatelessWidget {
  const _AIInsightsCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InsightCard(
          icon: Icons.trending_up_rounded,
          title: '📈 Momentum Building',
          body: 'Your completion rate improved 14% from last week. Wednesday was your best day!',
          color: _T.teal,
          bg: _T.tealBg,
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.warning_rounded,
          title: '⚠️ Friday Slump',
          body: 'You logged the least habits on Fridays. Try scheduling important habits earlier.',
          color: _T.coral,
          bg: _T.coralBg,
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.lightbulb_outline,
          title: '💡 Pro Tip',
          body: 'Your morning habits have 95% consistency. Stack them together for better results.',
          color: _T.amber,
          bg: _T.amberBg,
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.star_outline,
          title: '⭐ Milestone Alert',
          body: 'You\'re 2 days away from a 14-day streak on "Morning Run". Keep it going!',
          color: _T.blue,
          bg: _T.blueBg,
        ),
      ],
    );
  }
}

class _InsightCard extends StatefulWidget {
  final IconData icon;
  final String title, body;
  final Color color, bg;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.bg,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF5F4F1) : _T.surface,
          borderRadius: BorderRadius.circular(_T.r12),
          border: Border.all(color: _T.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hovered ? widget.color : widget.bg,
                borderRadius: BorderRadius.circular(_T.r8),
              ),
              child: Icon(widget.icon,
                  color: _hovered ? _T.surface : widget.color,
                  size: 20),
            ),
            const SizedBox(width: _T.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _T.ink,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(widget.body,
                      style: _T.body(size: 12),
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

// ─── Primitives ───────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: _T.ink,
            borderRadius: BorderRadius.circular(size * 0.22)),
        child: Center(
          child: Container(
            width: size * 0.30,
            height: size * 0.30,
            decoration:
                const BoxDecoration(color: _T.surface, shape: BoxShape.circle),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: _T.purpleBg,
            border: Border.all(color: _T.purpleBorder),
            borderRadius: BorderRadius.circular(_T.r100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: _T.purple, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _T.purple,
                  letterSpacing: 0.6)),
        ]),
      );
}