// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field, avoid_print, use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:habit_tracker/theme/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;


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

  // ── Streak Freeze ──────────────────────────────────────────────────────────
  int freezesRemaining;
  bool frozenThisWeek;
  DateTime? lastFreezeReset;

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
    this.freezesRemaining = 1,
    this.frozenThisWeek = false,
    this.lastFreezeReset,
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

// ─── XP Service ──────────────────────────────────────────────────────────────
class _XpService {
  static const _xpKey = 'user_xp';

  static Future<int> getXp() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_xpKey) ?? 0;
  }

  static Future<int> addXp(int amount) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_xpKey) ?? 0;
    final next = current + amount;
    await p.setInt(_xpKey, next);
    return next;
  }

  static int levelFromXp(int xp) => (xp ~/ 100) + 1;
  static double levelProgress(int xp) => (xp % 100) / 100.0;
  static int xpToNextLevel(int xp) => 100 - (xp % 100);

  static int xpForStreak(int streakDays) {
    if (streakDays >= 100) return 110;
    if (streakDays >= 30) return 60;
    if (streakDays >= 14) return 35;
    if (streakDays >= 7) return 25;
    if (streakDays >= 3) return 15;
    return 10;
  }
}

// ─── Confetti Particle ────────────────────────────────────────────────────────
class _Particle {
  final double startX;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double initialRotation;
  final double rotationSpeed;
  final bool isRect;

  const _Particle({
    required this.startX,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.initialRotation,
    required this.rotationSpeed,
    required this.isRect,
  });
}

List<_Particle> _generateParticles(Color primaryColor) {
  final rng = math.Random();
  final colors = [
    primaryColor,
    const Color(0xFFC8F135),
    const Color(0xFFFF6B47),
    const Color(0xFF4DA6FF),
    const Color(0xFFFFB830),
    Colors.white,
    const Color(0xFF8B7FFF),
    const Color(0xFF00D4A0),
  ];
  return List.generate(80, (_) => _Particle(
    startX: rng.nextDouble(),
    vx: (rng.nextDouble() - 0.5) * 0.5,
    vy: rng.nextDouble() * 1.4 + 0.4,
    size: rng.nextDouble() * 10 + 5,
    color: colors[rng.nextInt(colors.length)],
    initialRotation: rng.nextDouble() * math.pi * 2,
    rotationSpeed: (rng.nextDouble() - 0.5) * 12,
    isRect: rng.nextBool(),
  ));
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  const _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = -0.05 + p.vy * progress;
      final x = p.startX + p.vx * progress;
      final opacity = progress > 0.65
          ? (1.0 - (progress - 0.65) / 0.35).clamp(0.0, 1.0)
          : 1.0;
      if (y > 1.15 || x < -0.1 || x > 1.1) continue;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      final cx = x * size.width;
      final cy = y * size.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.initialRotation + p.rotationSpeed * progress);
      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─── Celebration Overlay ──────────────────────────────────────────────────────
class _CelebrationOverlay extends StatefulWidget {
  final Streak streak;
  final int xpEarned;
  final int totalXp;

  const _CelebrationOverlay({
    required this.streak,
    required this.xpEarned,
    required this.totalXp,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles(widget.streak.color);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardCtrl.forward();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  String get _headline {
    final s = widget.streak.currentStreak;
    if (s >= 100) return '🏆 LEGENDARY';
    if (s >= 30)  return '🔥 MONTH MASTER';
    if (s >= 14)  return '⚡ UNSTOPPABLE';
    if (s >= 7)   return '✨ WEEK WARRIOR';
    if (s >= 3)   return '💪 ON A ROLL';
    if (s == 1)   return '🌱 FIRST FLAME';
    return '🎯 LOGGED';
  }

  String get _subtitle {
    final s = widget.streak.currentStreak;
    if (s >= 100) return 'A hundred days. You\'re truly legendary.';
    if (s >= 30)  return 'A full month of showing up. Incredible.';
    if (s >= 14)  return 'Two solid weeks. This is a real habit now.';
    if (s >= 7)   return 'A whole week! Your streak is on fire.';
    if (s >= 3)   return 'Three days strong. The habit is forming.';
    if (s == 1)   return 'Every legend starts with day one.';
    return 'Keep showing up every single day.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.black.withOpacity(0.75),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (ctx2, child) => CustomPaint(
                painter: _ConfettiPainter(
                  progress: _confettiCtrl.value,
                  particles: _particles,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    final level = _XpService.levelFromXp(widget.totalXp);
    final progress = _XpService.levelProgress(widget.totalXp);
    final toNext = _XpService.xpToNextLevel(widget.totalXp);
    final color = widget.streak.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 36),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Big streak circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.streak.currentStreak}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                Text(
                  'days',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headline
          Text(
            _headline,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),

          // XP earned badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFC8F135).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFC8F135).withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  '+${widget.xpEarned} XP',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC8F135),
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 14,
                  color: Colors.white12,
                ),
                Text(
                  'Level $level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Level progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFC8F135)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$toNext XP to Level ${level + 1}',
            style: const TextStyle(fontSize: 10, color: Colors.white30),
          ),
          const SizedBox(height: 24),

          // CTA button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'KEEP GOING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

      // Auto-advance any streak that hasn't been logged today
      bool changed = false;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final streak in streaks) {
        // Weekly freeze reset
        if (streak.lastFreezeReset == null ||
            today.difference(DateTime(streak.lastFreezeReset!.year,
                streak.lastFreezeReset!.month, streak.lastFreezeReset!.day)).inDays >= 7) {
          streak.freezesRemaining = 1;
          streak.frozenThisWeek = false;
          streak.lastFreezeReset = now;
          changed = true;
        }

        // Only break/freeze streaks that were missed — never auto-complete them.
        // A streak is "missed" if lastLoggedDate was 2+ days ago AND it wasn't
        // logged today. Opening the app does NOT count as completing the streak.
        if (!streak.loggedToday && streak.lastLoggedDate != null) {
          final lastDay = DateTime(streak.lastLoggedDate!.year,
              streak.lastLoggedDate!.month, streak.lastLoggedDate!.day);
          final gap = today.difference(lastDay).inDays;
          if (gap >= 2) {
            // Missed at least one full day — try freeze first
            if (streak.freezesRemaining > 0 && !streak.frozenThisWeek) {
              streak.freezesRemaining--;
              streak.frozenThisWeek = true;
              // Streak preserved by freeze — do NOT reset
            } else {
              streak.currentStreak = 0;
            }
            changed = true;
          }
          // gap == 1 means last logged yesterday — streak is intact, waiting for
          // today's log. Do nothing — user hasn't had their chance yet.
        }
      }
      if (changed) await saveStreaks(streaks);

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
    'freezesRemaining': s.freezesRemaining,
    'frozenThisWeek': s.frozenThisWeek,
    'lastFreezeReset': s.lastFreezeReset?.toIso8601String(),
  };

  static Streak _streakFromJson(Map<String, dynamic> json) {
    final completionHistory = (json['completionHistory'] as List<dynamic>?)
        ?.map((d) => DateTime.parse(d as String))
        .toList() ?? [];

    return Streak(
      title: json['title'] as String,
      description: json['description'] as String? ?? 'No description',
      color: Color(json['colorValue'] as int? ?? 0xFFFF6B47),
      icon: IconData(json['iconCodePoint'] as int? ?? 0xf57ca, fontFamily: 'MaterialIcons'),
      category: json['category'] as String? ?? 'General',
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCompletions: json['totalCompletions'] as int? ?? 0,
      lastLoggedDate: json['lastLoggedDate'] != null
          ? DateTime.parse(json['lastLoggedDate'] as String)
          : null,
      completionHistory: completionHistory,
      freezesRemaining: json['freezesRemaining'] as int? ?? 1,
      frozenThisWeek: json['frozenThisWeek'] as bool? ?? false,
      lastFreezeReset: json['lastFreezeReset'] != null
          ? DateTime.parse(json['lastFreezeReset'] as String)
          : null,
    );
  }
}

// ─── Streaks Screen ───────────────────────────────────────────────────────────
class StreaksScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const StreaksScreen({super.key, this.onBack});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  final List<Streak> _streaks = [];
  bool _isLoading = true;
  int _totalXp = 0;

  @override
  void initState() {
    super.initState();
    _loadStreaks();
    _loadXp();
  }

  Future<void> _loadXp() async {
    final xp = await _XpService.getXp();
    if (mounted) setState(() => _totalXp = xp);
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
    final t = AppTokens.of(context);
    final index = _streaks.indexOf(streak);
    setState(() => _streaks.remove(streak));
    _saveStreaks();
    Future.delayed(const Duration(milliseconds: 300), () {
      final t = AppTokens.of(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text('"${streak.title}" deleted',
              style: t.body(color: Colors.white)),
          backgroundColor: t.bg2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r8)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: t.accent,
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
    if (s.loggedToday) return;
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool continuing = false;
      if (s.lastLoggedDate != null) {
        final lastDay = DateTime(s.lastLoggedDate!.year,
            s.lastLoggedDate!.month, s.lastLoggedDate!.day);
        final gap = today.difference(lastDay).inDays;
        continuing = gap <= 1 && s.currentStreak > 0;
      }
      if (continuing) {
        s.currentStreak++;
      } else {
        s.currentStreak = 1;
      }
      if (s.currentStreak > s.longestStreak) {
        s.longestStreak = s.currentStreak;
      }
      s.totalCompletions++;
      s.lastLoggedDate = now;
      s.completionHistory.add(now);
    });
    _saveStreaks();
    _showCelebration(s);
  }

  Future<void> _showCelebration(Streak s) async {
    final xpEarned = _XpService.xpForStreak(s.currentStreak);
    final totalXp = await _XpService.addXp(xpEarned);
    if (mounted) setState(() => _totalXp = totalXp);
    if (!mounted) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'celebration',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, a1, a2) => _CelebrationOverlay(
        streak: s,
        xpEarned: xpEarned,
        totalXp: totalXp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppTokens.coral.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTokens.r16),
                  border: Border.all(color: t.border),
                ),
                child: const Icon(Icons.local_fire_department_outlined, color: AppTokens.coral, size: 28),
              ),
              const SizedBox(height: AppTokens.s16),
              Text('Loading streaks...', style: t.body(size: 14)),
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
            Text('Streaks',
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
    final t = AppTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTokens.coral.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(color: t.border),
              ),
              child: const Icon(Icons.local_fire_department_outlined,
                  color: AppTokens.coral, size: 32),
            ),
            const SizedBox(height: AppTokens.s20),
            Text('No streaks yet', style: t.heading(size: 22)),
            const SizedBox(height: AppTokens.s8),
            Text(
              'Tap "Add" to create your first streak and start building consistency.',
              textAlign: TextAlign.center,
              style: t.body(size: 14),
            ),
            const SizedBox(height: AppTokens.s32),
            _PrimaryBtn(label: 'Add your first streak', onTap: _openAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Streak> active, List<Streak> notStarted, int bestStreak) {
    final t = AppTokens.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryStrip(active: active.length, bestStreak: bestStreak, totalXp: _totalXp),
          Divider(height: 1, thickness: 1, color: t.border),

          if (active.isNotEmpty) ...[
            _SectionHeader(label: 'On Fire', accent: AppTokens.coral),
            AppTokensopStreakCard(
              streak: active.first,
              onEdit: () => _openEdit(active.first),
              onDelete: () => _confirmDelete(active.first),
              onLongPress: () => _showContextMenu(context, active.first),
              onLogDay: active.first.loggedToday ? null : () => _logDay(active.first),
            ),
          ],

          if (active.length > 1) ...[
            _SectionHeader(label: 'Active Streaks', accent: AppTokens.coral),
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
            Divider(height: 1, thickness: 1, color: t.border),
            _SectionHeader(label: 'This Week', accent: AppTokens.purple),
            _WeeklyOverview(streaks: _streaks),
          ],

          if (notStarted.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: t.border),
            _SectionHeader(label: 'Not Started', accent: t.txt3),
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
  final int active, bestStreak, totalXp;
  const _SummaryStrip({required this.active, required this.bestStreak, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final level = _XpService.levelFromXp(totalXp);
    final progress = _XpService.levelProgress(totalXp);

    return Container(
      color: t.bg2,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _SummaryCell(
                  icon: Icons.local_fire_department_outlined,
                  value: '$active',
                  label: 'Active',
                  iconColor: AppTokens.coral,
                )),
                VerticalDivider(width: 1, thickness: 1, color: t.border),
                Expanded(child: _SummaryCell(
                  icon: Icons.emoji_events_outlined,
                  value: '${bestStreak}d',
                  label: 'Best Streak',
                  iconColor: AppTokens.purple,
                )),
                VerticalDivider(width: 1, thickness: 1, color: t.border),
                Expanded(child: _SummaryCell(
                  icon: Icons.bolt_outlined,
                  value: 'Lv $level',
                  label: '$totalXp XP',
                  iconColor: const Color(0xFFC8F135),
                )),
              ],
            ),
          ),
          // XP progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: t.bg3,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFC8F135)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_XpService.xpToNextLevel(totalXp)} XP to Level ${level + 1}',
                  style: t.label(size: 10, color: t.txt3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color iconColor;
  const _SummaryCell({
    required this.icon, required this.value, required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTokens.r8),
                border: Border.all(color: iconColor.withOpacity(0.25))),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: t.txt,
                  letterSpacing: -1.2)),
          const SizedBox(height: 3),
          Text(label, style: t.label(size: 11, color: iconColor)),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color accent;
  const _SectionHeader({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      color: t.bg,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: _EyebrowPill(
        label: label.toUpperCase(),
        bg: accent.withOpacity(0.1),
        border: accent.withOpacity(0.25),
        dot: accent,
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
          color: AppTokens.blue, icon: Icons.edit_outlined,
          label: 'Edit', alignment: Alignment.centerLeft),
      secondaryBackground: _SwipeBg(
          color: AppTokens.coral, icon: Icons.delete_outline,
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
    final t = AppTokens.of(context);
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppTokens.r12)),
      alignment: alignment,
      padding: EdgeInsets.only(left: isLeft ? 20 : 0, right: isLeft ? 0 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(label, style: t.label(size: 11, color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Top Streak Hero Card ──────────────────────────────────────────────────────
class AppTokensopStreakCard extends StatelessWidget {
  final Streak streak;
  final VoidCallback? onLogDay;
  final VoidCallback onEdit, onDelete, onLongPress;

  const AppTokensopStreakCard({
    required this.streak,
    required this.onLogDay,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [streak.color.withOpacity(0.15), t.bg2],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(color: streak.color.withOpacity(0.25)),
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
                        color: streak.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTokens.r8),
                        border: Border.all(color: streak.color.withOpacity(0.4))),
                    child: Icon(streak.icon, color: streak.color, size: 22),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(streak.title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: t.txt,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 3),
                        Text(streak.category,
                            style: t.label(size: 11, color: t.txt3)),
                      ],
                    ),
                  ),
                  _IconActionBtn(icon: Icons.edit_outlined, onTap: onEdit),
                  const SizedBox(width: AppTokens.s8),
                  _IconActionBtn(icon: Icons.delete_outline, onTap: onDelete),
                ],
              ),

              const SizedBox(height: AppTokens.s24),

              Row(children: [
                _HeroBadge(value: '${streak.currentStreak}d', sub: 'current'),
                const SizedBox(width: AppTokens.s8),
                _HeroBadge(value: '${streak.longestStreak}d', sub: 'best'),
                const SizedBox(width: AppTokens.s8),
                _HeroBadge(value: '${streak.totalCompletions}', sub: 'total'),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(streak.streakEmoji, style: const TextStyle(fontSize: 24)),
                    Text('${streak.currentStreak}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: streak.color,
                            letterSpacing: -1.2)),
                    Text('days',
                        style: t.label(size: 10, color: t.txt3)),
                  ],
                ),
              ]),

              const SizedBox(height: AppTokens.s16),

              GestureDetector(
                onTap: onLogDay,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: streak.loggedToday
                        ? t.bg3
                        : streak.color,
                    borderRadius: BorderRadius.circular(AppTokens.r8),
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
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: streak.loggedToday
                              ? t.txt3
                              : Colors.black,
                        ),
                      ),
                      if (!streak.loggedToday) ...[
                        const SizedBox(width: AppTokens.s8),
                        const Icon(Icons.arrow_forward, size: 12, color: Colors.black),
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
  Widget build(BuildContext context) {
      final t = AppTokens.of(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: t.bg3,
            borderRadius: BorderRadius.circular(AppTokens.r8),
            border: Border.all(color: t.border)),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: t.txt)),
          const SizedBox(height: 2),
          Text(sub, style: t.label(size: 9, color: t.txt3)),
        ]),
      );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
      final t = AppTokens.of(context);
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: t.bg3,
              borderRadius: BorderRadius.circular(AppTokens.r8),
              border: Border.all(color: t.border)),
          child: Icon(icon, color: t.txt2, size: 15),
        ),
      );
  }
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
    final t = AppTokens.of(context);
    final streak = widget.streak;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _hovered ? t.bg3 : t.bg2,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: _hovered ? streak.color.withOpacity(0.4) : t.border),
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
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(streak.icon,
                  color: _hovered ? Colors.white : streak.color, size: 20),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(streak.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.txt,
                              letterSpacing: -0.3)),
                    ),
                    if (streak.frozenThisWeek)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DA6FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF4DA6FF).withOpacity(0.3)),
                        ),
                        child: const Text('❄️ Frozen',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                                color: Color(0xFF4DA6FF))),
                      )
                    else if (streak.freezesRemaining > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DA6FF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF4DA6FF).withOpacity(0.2)),
                        ),
                        child: const Text('❄️ 1 freeze',
                            style: TextStyle(fontSize: 10, color: Color(0xFF4DA6FF))),
                      ),
                    Text('${streak.streakEmoji} ${streak.currentStreak}d',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: streak.color,
                            letterSpacing: -0.2)),
                  ]),
                  const SizedBox(height: 3),
                  Text(streak.description, style: t.body(size: 12)),
                  const SizedBox(height: AppTokens.s12),
                  _WeekDots(streak: streak),
                  const SizedBox(height: AppTokens.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Best: ${streak.longestStreak}d · Total: ${streak.totalCompletions}',
                          style: t.label(size: 11)),
                      GestureDetector(
                        onTap: streak.loggedToday ? null : widget.onLogDay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: streak.loggedToday
                                ? t.bg3
                                : streak.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTokens.r100),
                            border: Border.all(
                              color: streak.loggedToday
                                  ? t.border
                                  : streak.color.withOpacity(0.3),
                            ),
                          ),
                          child: streak.loggedToday
                              ? Text(
                                  streak.nextLogAvailable.isEmpty ? 'Logged ✓' : streak.nextLogAvailable,
                                  style: t.label(size: 10, color: t.txt3))
                              : Text(
                                  streak.currentStreak == 0 ? '🔄 Start' : '+ Log Day',
                                  style: t.label(size: 10, color: streak.color)),
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
    final t = AppTokens.of(context);
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
          dotColor = t.bg3;
        } else if (isCompleted || isToday) {
          dotColor = streak.color;
        } else {
          dotColor = t.border;
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
                  style: t.label(
                      size: 9,
                      color: isFuture ? t.txt3 : t.txt2)),
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
    final t = AppTokens.of(context);
    final now = DateTime.now();
    final weekday = now.weekday;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
            color: t.bg2,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(color: t.border)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Progress',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.txt,
                        letterSpacing: -0.3)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTokens.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTokens.r100),
                      border: Border.all(color: AppTokens.purple.withOpacity(0.25))),
                  child: Text(
                      '${streaks.length} habit${streaks.length == 1 ? '' : 's'}',
                      style: t.label(size: 10, color: AppTokens.purple)),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s20),
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
                              color: t.bg3,
                              borderRadius: BorderRadius.circular(AppTokens.r8),
                              border: Border.all(color: t.border)),
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.hardEdge,
                          child: isFuture
                              ? const SizedBox()
                              : FractionallySizedBox(
                                  heightFactor: pct == 0 ? 0.04 : pct,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: isToday ? AppTokens.purple : AppTokens.coral,
                                        borderRadius: BorderRadius.circular(AppTokens.r8)),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i].substring(0, 1),
                            style: t.label(
                                size: 10,
                                color: isToday ? AppTokens.purple : t.txt3)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppTokens.s16),
            Row(children: [
              _LegendDot(color: AppTokens.coral, label: 'Past days'),
              const SizedBox(width: AppTokens.s16),
              _LegendDot(color: AppTokens.purple, label: 'Today'),
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
  Widget build(BuildContext context) {
      final t = AppTokens.of(context);
      return Row(
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: t.label(size: 11)),
        ],
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
            decoration: BoxDecoration(color: t.bg, shape: BoxShape.circle),
          ),
        ),
      );
  }
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
            borderRadius: BorderRadius.circular(AppTokens.r100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) {
      final t = AppTokens.of(context);
      return GestureDetector(
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
                color: t.accent,
                borderRadius: BorderRadius.circular(AppTokens.r8)),
            child: Text('Add', style: t.label(size: 12, color: t.bg)),
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
      final t = AppTokens.of(context);
      return GestureDetector(
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
                color: t.accent, borderRadius: BorderRadius.circular(AppTokens.r8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.bg,
                        letterSpacing: -0.3)),
                const SizedBox(width: AppTokens.s8),
                Icon(Icons.arrow_forward, size: 13, color: t.bg),
              ],
            ),
          ),
        ),
      );
  }
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
    Color(0xFF8B7FFF), // Purple
    Color(0xFFFF6B47), // Coral
    Color(0xFF00D4A0), // Teal
    Color(0xFF4DA6FF), // Blue
    Color(0xFFFFB830), // Amber
    Color(0xFFC8F135), // Lime
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
    final t = AppTokens.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: t.bg2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: t.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  Text('Category',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: t.txt)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(
                            color: t.accent, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: t.border),
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
                              Text(cat, style: t.body(size: 15, color: t.txt)),
                              if (_category == cat) Icon(Icons.check, color: t.accent, size: 18),
                            ],
                          ),
                        ),
                        if (cat != _categories.last) Divider(height: 1, indent: 16, thickness: 1, color: t.border),
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
    final t = AppTokens.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      final t = AppTokens.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a name', style: t.body(color: Colors.white)),
        backgroundColor: t.bg2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r8)),
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
    final t = AppTokens.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = _colors[_selectedColorIndex];

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: t.bg2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: t.border, width: 1)),
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
                        borderRadius: BorderRadius.circular(AppTokens.r8)),
                    child: Text('Cancel', style: t.body(size: 13)),
                  ),
                ),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Streak' : 'New Streak',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: t.txt, letterSpacing: -0.3),
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
                    color: t.bg2,
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                    child: Center(
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTokens.r16),
                          border: Border.all(color: accent.withOpacity(0.25)),
                        ),
                        child: Icon(_icons[_selectedIconIndex], color: accent, size: 32),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: t.border),
                  const SizedBox(height: AppTokens.s16),

                  _FormSection(label: 'Name', child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: t.body(color: t.txt),
                    decoration: _inputDeco('e.g. Morning Run'),
                  )),
                  const SizedBox(height: AppTokens.s16),

                  _FormSection(label: 'Description', child: TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: t.body(color: t.txt),
                    decoration: _inputDeco('What does this habit involve?'),
                  )),
                  const SizedBox(height: AppTokens.s16),

                  GestureDetector(
                    onTap: _pickCategory,
                    child: Container(
                      color: t.bg2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Category',
                              style: TextStyle(
                                  fontSize: 14, color: t.txt, fontWeight: FontWeight.w400)),
                          Row(children: [
                            Text(_category, style: t.body(size: 14)),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: t.txt3, size: 18),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),

                  Container(
                    color: t.bg2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Icon',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: t.txt)),
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
                                    : t.bg3,
                                borderRadius: BorderRadius.circular(AppTokens.r8),
                                border: i == _selectedIconIndex
                                    ? Border.all(color: accent, width: 1.5)
                                    : Border.all(color: t.border),
                              ),
                              child: Icon(_icons[i],
                                  color: i == _selectedIconIndex ? accent : t.txt3,
                                  size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),

                  Container(
                    color: t.bg2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Color',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: t.txt)),
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
                                  borderRadius: BorderRadius.circular(AppTokens.r8),
                                  border: i == _selectedColorIndex
                                      ? Border.all(color: t.txt, width: 2)
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

                  const SizedBox(height: AppTokens.s32),
                ],
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: t.bg2,
              border: Border(top: BorderSide(color: t.border, width: 1)),
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
                        color: t.accent,
                        borderRadius: BorderRadius.circular(AppTokens.r8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isEdit ? 'Save Changes' : 'Create Streak',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.bg,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Icon(Icons.arrow_forward, size: 13, color: t.bg),
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
    final t = AppTokens.of(context);
    return InputDecoration(
        hintText: hint,
        hintStyle: t.body(size: 14, color: t.txt3),
        filled: true,
        fillColor: t.bg3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r8),
            borderSide: BorderSide(color: t.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r8),
            borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r8),
            borderSide: BorderSide(color: t.txt, width: 1.5)),
      );
  }
}

class _FormSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
      final t = AppTokens.of(context);
      return Container(
        color: t.bg2,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: t.txt2, fontWeight: FontWeight.w400)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
  }
}