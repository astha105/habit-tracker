// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field

import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:habit_tracker/theme/app_tokens.dart';
import 'goals_screen.dart';
import 'streaks_screen.dart';


// ─── Achievement Model ────────────────────────────────────────────────────────
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final DateTime? unlockedDate;

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    this.unlockedDate,
  });
}

// ─── Achievements Screen ──────────────────────────────────────────────────────
class AchievementsScreen extends StatelessWidget {
  final List<Goal> goals;
  final List<Streak> streaks;
  final VoidCallback? onBack;

  const AchievementsScreen({
    super.key,
    required this.goals,
    required this.streaks,
    this.onBack,
  });

  List<Achievement> _getAchievements() {
    final allHabits = goals.length + streaks.length;
    final bestStreak = [
      ...goals.map((g) => g.currentStreak),
      ...streaks.map((s) => s.currentStreak),
    ].fold(0, (a, b) => a > b ? a : b);
    final totalCompletions = goals.fold(0, (s, g) => s + g.currentDays) +
        streaks.fold(0, (s, st) => s + st.totalCompletions);

    // Earliest date any habit was created (proxy for "first habit" date)
    final allHistoryDates = [
      ...goals.expand((g) => g.completionHistory),
      ...streaks.expand((s) => s.completionHistory),
    ]..sort();
    final firstActivityDate =
        allHistoryDates.isNotEmpty ? allHistoryDates.first : null;

    // Perfect day: any calendar date where ALL habits were completed
    DateTime? perfectDayDate;
    if (allHabits > 0) {
      final Map<String, int> completionsPerDay = {};
      for (final d in allHistoryDates) {
        final key = '${d.year}-${d.month}-${d.day}';
        completionsPerDay[key] = (completionsPerDay[key] ?? 0) + 1;
      }
      final perfectKey = completionsPerDay.entries
          .where((e) => e.value >= allHabits)
          .map((e) => e.key)
          .toList()
        ..sort();
      if (perfectKey.isNotEmpty) {
        final parts = perfectKey.first.split('-').map(int.parse).toList();
        perfectDayDate = DateTime(parts[0], parts[1], parts[2]);
      }
    }

    // Consistency: current best streak >= 14
    final consistencyDate = bestStreak >= 14 ? DateTime.now() : null;

    final achievements = [
      Achievement(
        title: 'First Step',
        description: 'Create your first habit',
        icon: Icons.directions_walk,
        color: AppTokens.teal,
        unlocked: allHabits >= 1,
        unlockedDate: firstActivityDate,
      ),
      Achievement(
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        color: AppTokens.coral,
        unlocked: bestStreak >= 7,
        unlockedDate: bestStreak >= 7 ? DateTime.now() : null,
      ),
      Achievement(
        title: 'Month Master',
        description: 'Maintain a 30-day streak',
        icon: Icons.star,
        color: AppTokens.amber,
        unlocked: bestStreak >= 30,
        unlockedDate: bestStreak >= 30 ? DateTime.now() : null,
      ),
      Achievement(
        title: 'Century',
        description: 'Reach a 100-day streak',
        icon: Icons.diamond,
        color: AppTokens.purple,
        unlocked: bestStreak >= 100,
        unlockedDate: bestStreak >= 100 ? DateTime.now() : null,
      ),
      Achievement(
        title: 'Triple Threat',
        description: 'Complete 3 habits in one day',
        icon: Icons.grid_3x3,
        color: AppTokens.blue,
        unlocked: allHabits >= 3,
        unlockedDate: allHabits >= 3 ? firstActivityDate : null,
      ),
      Achievement(
        title: 'Habit Master',
        description: 'Create 5 different habits',
        icon: Icons.dashboard,
        color: AppTokens.coral,
        unlocked: allHabits >= 5,
        unlockedDate: allHabits >= 5 ? firstActivityDate : null,
      ),
      Achievement(
        title: 'Perfect Day',
        description: 'Complete all habits in a single day',
        icon: Icons.check_circle,
        color: AppTokens.teal,
        unlocked: perfectDayDate != null,
        unlockedDate: perfectDayDate,
      ),
      Achievement(
        title: 'Consistency',
        description: 'Never miss a day for 2 weeks straight',
        icon: Icons.trending_up,
        color: AppTokens.purple,
        unlocked: consistencyDate != null,
        unlockedDate: consistencyDate,
      ),
      Achievement(
        title: 'Century Club',
        description: 'Log 100 total habit completions',
        icon: Icons.emoji_events,
        color: AppTokens.amber,
        unlocked: totalCompletions >= 100,
        unlockedDate: totalCompletions >= 100 ? DateTime.now() : null,
      ),
    ];

    final allUnlocked = achievements.every((a) => a.unlocked);
    achievements.add(Achievement(
      title: 'Legendary',
      description: 'Unlock all other achievements',
      icon: Icons.star_half,
      color: AppTokens.coral,
      unlocked: allUnlocked,
      unlockedDate: allUnlocked ? DateTime.now() : null,
    ));

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final achievements = _getAchievements();
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final total = achievements.length;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg2,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t.txt, size: 18),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        centerTitle: true,
        title: Text('Achievements',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: t.txt,
                letterSpacing: -0.4)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: t.border),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              color: t.bg2,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Achievements',
                              style: t.heading(size: 20, spacing: -0.8)),
                          const SizedBox(height: AppTokens.s4),
                          Text('$unlockedCount / $total unlocked',
                              style: t.body(size: 12, color: t.txt3)),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: t.border, width: 1.5),
                        ),
                        child: Center(
                          child: Text('${((unlockedCount / total) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.purple)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.r100),
                    child: LinearProgressIndicator(
                      value: unlockedCount / total,
                      minHeight: 5,
                      backgroundColor: t.bg,
                      valueColor: const AlwaysStoppedAnimation(AppTokens.purple),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: t.border),

            // ── Grid ──
            Container(
              color: t.bg,
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                itemCount: achievements.length,
                itemBuilder: (_, i) => _AchievementTile(achievement: achievements[i]),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Achievement Tile ─────────────────────────────────────────────────────────
class _AchievementTile extends StatefulWidget {
  final Achievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  State<_AchievementTile> createState() => _AchievementTileState();
}

class _AchievementTileState extends State<_AchievementTile> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _unlockAnimCtrl;

  @override
  void initState() {
    super.initState();
    _unlockAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    if (widget.achievement.unlocked) {
      _unlockAnimCtrl.forward();
    }
  }

  @override
  void dispose() {
    _unlockAnimCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: _unlockAnimCtrl,
        builder: (context, child) {
          final t = AppTokens.of(context);
          final scaleVal = widget.achievement.unlocked 
            ? 0.95 + (_unlockAnimCtrl.value * 0.05)
            : 1.0;
          final opacityVal = widget.achievement.unlocked
            ? _unlockAnimCtrl.value
            : 0.5;

          return Transform.scale(
            scale: scaleVal,
            child: Opacity(
              opacity: widget.achievement.unlocked ? 1.0 : 0.5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: _hovered && widget.achievement.unlocked
                      ? const Color(0xFFF8F8F6)
                      : t.bg2,
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(
                    color: _hovered && widget.achievement.unlocked
                        ? widget.achievement.color.withOpacity(0.3)
                        : t.border,
                    width: _hovered && widget.achievement.unlocked ? 1.5 : 1,
                  ),
                  boxShadow: _hovered && widget.achievement.unlocked
                      ? [
                          BoxShadow(
                            color: widget.achievement.color.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.achievement.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: widget.achievement.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Text(
                      widget.achievement.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.txt,
                          letterSpacing: -0.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.achievement.description,
                      textAlign: TextAlign.center,
                      style: t.body(size: 10, color: t.txt3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.s8),
                    if (widget.achievement.unlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.achievement.color,
                          borderRadius: BorderRadius.circular(AppTokens.r100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(widget.achievement.unlockedDate!),
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.txt3.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTokens.r100),
                        ),
                        child: Text('Locked',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: t.txt3)),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}