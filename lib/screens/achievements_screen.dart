// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field, unused_element

import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';

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
  static const Color coral       = Color(0xFFD85A30);
  static const Color teal       = Color(0xFF1D9E75);
  static const Color blue       = Color(0xFF378ADD);
  static const Color amber       = Color(0xFFBA7517);

  static const double s4  = 4;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;

  static const double r8   = 8;
  static const double r12  = 12;
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
  const AchievementsScreen({super.key});

  List<Achievement> _getAchievements() {
    final now = DateTime.now();
    return [
      Achievement(
        title: 'First Step',
        description: 'Create your first habit',
        icon: Icons.directions_walk,
        color: _T.teal,
        unlocked: true,
        unlockedDate: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        color: _T.coral,
        unlocked: true,
        unlockedDate: now.subtract(const Duration(days: 20)),
      ),
      Achievement(
        title: 'Month Master',
        description: 'Maintain a 30-day streak',
        icon: Icons.star,
        color: _T.amber,
        unlocked: false,
      ),
      Achievement(
        title: 'Century',
        description: 'Reach a 100-day streak',
        icon: Icons.diamond,
        color: _T.purple,
        unlocked: false,
      ),
      Achievement(
        title: 'Triple Threat',
        description: 'Complete 3 habits in one day',
        icon: Icons.grid_3x3,
        color: _T.blue,
        unlocked: true,
        unlockedDate: now.subtract(const Duration(days: 15)),
      ),
      Achievement(
        title: 'Habit Master',
        description: 'Create 5 different habits',
        icon: Icons.dashboard,
        color: _T.coral,
        unlocked: true,
        unlockedDate: now.subtract(const Duration(days: 10)),
      ),
      Achievement(
        title: 'Perfect Day',
        description: 'Complete all habits in a single day',
        icon: Icons.check_circle,
        color: _T.teal,
        unlocked: true,
        unlockedDate: now.subtract(const Duration(days: 5)),
      ),
      Achievement(
        title: 'Consistency',
        description: 'Never miss a day for 2 weeks straight',
        icon: Icons.trending_up,
        color: _T.purple,
        unlocked: false,
      ),
      Achievement(
        title: 'Century Club',
        description: 'Log 100 total habit completions',
        icon: Icons.emoji_events,
        color: _T.amber,
        unlocked: true,
        unlockedDate: now.subtract(const Duration(days: 3)),
      ),
      Achievement(
        title: 'Legendary',
        description: 'Unlock all other achievements',
        icon: Icons.star_half,
        color: _T.coral,
        unlocked: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _getAchievements();
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final total = achievements.length;

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
        title: const Text('Achievements',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _T.ink,
                letterSpacing: -0.4)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _T.border),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              color: _T.surface,
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
                              style: _T.heading(size: 20, spacing: -0.8)),
                          const SizedBox(height: _T.s4),
                          Text('$unlockedCount / $total unlocked',
                              style: _T.body(size: 12, color: _T.ink3)),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _T.border, width: 1.5),
                        ),
                        child: Center(
                          child: Text('${((unlockedCount / total) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _T.purple)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _T.s16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_T.r100),
                    child: LinearProgressIndicator(
                      value: unlockedCount / total,
                      minHeight: 5,
                      backgroundColor: _T.canvas,
                      valueColor: const AlwaysStoppedAnimation(_T.purple),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.border),

            // ── Grid ──
            Container(
              color: _T.canvas,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: _unlockAnimCtrl,
        builder: (context, child) {
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
                      : _T.surface,
                  borderRadius: BorderRadius.circular(_T.r12),
                  border: Border.all(
                    color: _hovered && widget.achievement.unlocked
                        ? widget.achievement.color.withOpacity(0.3)
                        : _T.border,
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
                        borderRadius: BorderRadius.circular(_T.r12),
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: widget.achievement.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: _T.s12),
                    Text(
                      widget.achievement.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _T.ink,
                          letterSpacing: -0.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.achievement.description,
                      textAlign: TextAlign.center,
                      style: _T.body(size: 10, color: _T.ink3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: _T.s8),
                    if (widget.achievement.unlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.achievement.color,
                          borderRadius: BorderRadius.circular(_T.r100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, color: _T.surface, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(widget.achievement.unlockedDate!),
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _T.surface),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _T.ink3.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(_T.r100),
                        ),
                        child: const Text('Locked',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _T.ink3)),
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