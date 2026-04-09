// ignore_for_file: deprecated_member_use, unused_element, unnecessary_underscores, unused_field, curly_braces_in_flow_control_structures, avoid_print

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habit_tracker/screens/goals_screen.dart';
import 'package:habit_tracker/screens/streaks_screen.dart';
import 'package:habit_tracker/screens/track_progress_screen.dart';
import 'package:habit_tracker/screens/daily_checkins_screen.dart';
import 'package:habit_tracker/screens/weekly_insights_screen.dart';
import 'package:habit_tracker/screens/achievements_screen.dart';
import 'package:habit_tracker/screens/paywall_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stats Service (Singleton for global data)
// ─────────────────────────────────────────────────────────────────────────────
class StatsService {
  static StatsService? _instance;

  factory StatsService() {
    _instance ??= StatsService._internal();
    return _instance!;
  }

  StatsService._internal();

  int _activeHabits = 0;
  int _dayStreak = 0;
  int _successRate = 0;
  int _totalDays = 0;

  int get activeHabits => _activeHabits;
  int get dayStreak => _dayStreak;
  int get successRate => _successRate;
  int get totalDays => _totalDays;

  void updateActiveHabits(int count) => _activeHabits = count;
  void updateDayStreak(int days) => _dayStreak = days;
  void updateSuccessRate(int rate) => _successRate = rate;
  void updateTotalDays(int days) => _totalDays = days;

  void updateStats({int? habits, int? streak, int? rate, int? days}) {
    if (habits != null) _activeHabits = habits;
    if (streak != null) _dayStreak = streak;
    if (rate != null) _successRate = rate;
    if (days != null) _totalDays = days;
  }

  // Load and calculate stats from goals and streaks
  Future<void> loadFromGoalsAndStreaks() async {
    try {
      final goals = await GoalsStorageService.loadGoals();
      final streaks = await StreaksStorageService.loadStreaks();
      
      // Active habits = goals not completed + streaks with currentStreak > 0
      final activeGoals = goals.where((g) => !g.isCompleted).length;
      final activeStreaks = streaks.where((s) => s.currentStreak > 0).length;
      _activeHabits = activeGoals + activeStreaks;
      
      // Calculate longest streak from both goals and streaks
      int maxStreak = 0;
      for (final goal in goals) {
        if (goal.currentStreak > maxStreak) maxStreak = goal.currentStreak;
      }
      for (final streak in streaks) {
        if (streak.currentStreak > maxStreak) maxStreak = streak.currentStreak;
      }
      _dayStreak = maxStreak;
      
      // Success rate = average completion % from goals
      if (goals.isEmpty && streaks.isEmpty) {
        _successRate = 0;
      } else {
        double totalRate = 0;
        int count = 0;
        
        for (final goal in goals) {
          totalRate += (goal.currentDays / goal.targetDays).clamp(0.0, 1.0);
          count++;
        }
        
        for (final streak in streaks) {
          if (streak.longestStreak > 0) {
            totalRate += (streak.currentStreak / streak.longestStreak).clamp(0.0, 1.0);
            count++;
          }
        }
        
        _successRate = count > 0 ? ((totalRate / count) * 100).toInt() : 0;
      }
      
      // Total days = sum of all logged days from goals + completions from streaks
      _totalDays = goals.fold(0, (sum, g) => sum + g.currentDays) +
          streaks.fold(0, (sum, s) => sum + s.totalCompletions);
      
      print('✓ Stats loaded: habits=$_activeHabits, streak=$_dayStreak, rate=$_successRate%, days=$_totalDays');
    } catch (e) {
      print('✗ Error loading stats: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
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
  static const double s72 = 72;
  static const double s80 = 80;

  static const double r8  = 8;
  static const double r16 = 16;
  static const double r100 = 100;

  static TextStyle display({double size = 56, double spacing = -2.6}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: ink,
          height: 1.04, letterSpacing: spacing);

  static TextStyle heading({double size = 32, double spacing = -1.2}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: ink,
          height: 1.1, letterSpacing: spacing);

  static TextStyle body({double size = 15, Color? color}) =>
      TextStyle(fontSize: size, color: color ?? ink2,
          height: 1.6, letterSpacing: -0.1);

  static TextStyle label({double size = 12, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500,
          color: color ?? ink3, letterSpacing: 0.06 * size);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────
class _StatData {
  final IconData icon;
  final String value, label;
  final Color iconBg, iconColor, valueColor, labelColor;
  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
    required this.labelColor,
  });
}

class _FeatureData {
  final IconData icon;
  final String title, body;
  final Color iconBg, iconColor, borderColor;
  final VoidCallback? onTap;
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.body,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
    this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Landing Screen
// ─────────────────────────────────────────────────────────────────────────────
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  bool _loggingOut = false;
  late final StatsService _statsService;

  late final AnimationController _entryCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _statsService = StatsService();
    _loadStats();

    _entryCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _staggerCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _staggerCtrl.forward();
    });
  }

  Future<void> _loadStats() async {
    await _statsService.loadFromGoalsAndStreaks();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      if (!kIsWeb) {
        try {
          final g = GoogleSignIn();
          if (await g.isSignedIn()) await g.signOut();
        } catch (_) {}
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not sign out: $e'),
          backgroundColor: _T.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_T.r8)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

Future<void> _go(Widget screen) async {
  await Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    ),
  );
  await _loadStats();
}

Future<void> _goToProgress() async {
  await Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const PaywallScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    ),
  );
  await _loadStats();
}

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 600;
    final isDesktop = w >= 1024;
    final hPad = isDesktop ? 64.0 : isPhone ? 20.0 : 40.0;

    return Scaffold(
      backgroundColor: _T.canvas,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavBar(
                      hPad: hPad,
                      isPhone: isPhone,
                      loggingOut: _loggingOut,
                      onLogout: _logout),
                  const _Rule(),
                  if (isPhone)
                    _PhoneBody(
                      hPad: hPad,
                      stagger: _staggerCtrl,
                      onGoals: () => _go(const GoalsScreen()),
                      onStreaks: () => _go(const StreaksScreen()),
                      onTrack: () => _goToProgress(),
                      onDailyCheckins: () => _go(const DailyCheckinsScreen()),
                      onWeekly: () => _go(const WeeklyInsightsScreen()),
                      onAchievements: () => _go(const AchievementsScreen()),
                    )
                  else
                    _DesktopBody(
                      hPad: hPad,
                      stagger: _staggerCtrl,
                      isDesktop: isDesktop,
                      onGoals: () => _go(const GoalsScreen()),
                      onStreaks: () => _go(const StreaksScreen()),
                      onTrack: () => _go(const TrackProgressScreen()),
                      onDailyCheckins: () => _go(const DailyCheckinsScreen()),
                      onWeekly: () => _go(const WeeklyInsightsScreen()),
                      onAchievements: () => _go(const AchievementsScreen()),
                    ),
                  const _Rule(),
                  _Footer(hPad: hPad, isPhone: isPhone),
                  const SizedBox(height: _T.s32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Bar
// ─────────────────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final double hPad;
  final bool isPhone, loggingOut;
  final VoidCallback onLogout;

  const _NavBar({
    required this.hPad,
    required this.isPhone,
    required this.loggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _LogoMark(size: isPhone ? 26 : 30),
            const SizedBox(width: _T.s8),
            Text('HabitFlow',
                style: TextStyle(
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: _T.ink,
                    letterSpacing: -0.4)),
          ]),
          loggingOut
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(_T.ink3)))
              : _Tappable(
                  onTap: onLogout,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        border: Border.all(color: _T.border),
                        borderRadius: BorderRadius.circular(_T.r8)),
                    child: Text('Sign out',
                        style: TextStyle(
                            fontSize: isPhone ? 12 : 13,
                            color: _T.ink2)),
                  )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone Body
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneBody extends StatelessWidget {
  final double hPad;
  final AnimationController stagger;
  final VoidCallback onGoals, onStreaks, onTrack, onDailyCheckins, onWeekly, onAchievements;

  const _PhoneBody({
    required this.hPad,
    required this.stagger,
    required this.onGoals,
    required this.onStreaks,
    required this.onTrack,
    required this.onDailyCheckins,
    required this.onWeekly,
    required this.onAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _T.surface,
          padding: EdgeInsets.fromLTRB(hPad, _T.s64, hPad, _T.s64),
          child: Column(
            children: [
              _EyebrowPill(
                  label: 'HABIT TRACKING, SIMPLIFIED',
                  bg: _T.purpleBg,
                  border: _T.purpleBorder,
                  dot: _T.purple,
                  text: _T.purpleDark),
              const SizedBox(height: _T.s20),
              Text('Build habits\nthat stick.',
                  textAlign: TextAlign.center,
                  style: _T.display(size: 38, spacing: -1.8)),
              const SizedBox(height: _T.s12),
              Text(
                'Track your daily habits, build streaks, and see your progress unfold.',
                textAlign: TextAlign.center,
                style: _T.body(size: 15),
              ),
              const SizedBox(height: _T.s24),
              _PrimaryBtn(label: 'Start tracking', onTap: onGoals),
            ],
          ),
        ),
        _StatsStrip(stagger: stagger),
        const _Rule(),
        Container(
          color: _T.canvas,
          padding: EdgeInsets.fromLTRB(hPad, _T.s64, hPad, _T.s64),
          child: Column(
            children: [
              _EyebrowPill(
                  label: 'FEATURES',
                  bg: _T.purpleBg,
                  border: _T.purpleBorder,
                  dot: _T.purple,
                  text: _T.purpleDark),
              const SizedBox(height: _T.s16),
              Text('Everything you need',
                  textAlign: TextAlign.center,
                  style: _T.heading(size: 26, spacing: -1.0)),
              const SizedBox(height: _T.s8),
              Text('Designed to be simple, without sacrificing depth.',
                  textAlign: TextAlign.center,
                  style: _T.body(size: 14)),
              const SizedBox(height: _T.s32),
              _FeaturesGrid(
                  onGoals: onGoals,
                  onStreaks: onStreaks,
                  onTrack: onTrack,
                  onDailyCheckins: onDailyCheckins,
                  onWeekly: onWeekly,
                  onAchievements: onAchievements,
                  columns: 2),
            ],
          ),
        ),
        const _Rule(),
        Container(
          color: _T.canvas,
          padding: EdgeInsets.all(hPad),
          child: Column(children: [
            const SizedBox(height: _T.s32),
            _CTABlock(onTap: onGoals),
            const SizedBox(height: _T.s32),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Body
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopBody extends StatelessWidget {
  final double hPad;
  final AnimationController stagger;
  final bool isDesktop;
  final VoidCallback onGoals, onStreaks, onTrack, onDailyCheckins, onWeekly, onAchievements;

  const _DesktopBody({
    required this.hPad,
    required this.stagger,
    required this.isDesktop,
    required this.onGoals,
    required this.onStreaks,
    required this.onTrack,
    required this.onDailyCheckins,
    required this.onWeekly,
    required this.onAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final heroSize = isDesktop ? 60.0 : 48.0;
    final heroSpacing = isDesktop ? -3.0 : -2.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _T.surface,
          padding: EdgeInsets.fromLTRB(hPad, _T.s80, hPad, _T.s80),
          child: Column(children: [
            _EyebrowPill(
                label: 'HABIT TRACKING, SIMPLIFIED',
                bg: _T.purpleBg,
                border: _T.purpleBorder,
                dot: _T.purple,
                text: _T.purpleDark),
            const SizedBox(height: _T.s24),
            Text('Build habits that stick.',
                textAlign: TextAlign.center,
                style: _T.display(size: heroSize, spacing: heroSpacing)),
            const SizedBox(height: _T.s20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Text(
                'Track your daily habits, visualize your progress, and build streaks that keep you going.',
                textAlign: TextAlign.center,
                style: _T.body(size: 17),
              ),
            ),
            const SizedBox(height: _T.s32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _PrimaryBtn(label: 'Start tracking', onTap: onGoals),
            ]),
          ]),
        ),
        _StatsStrip(stagger: stagger),
        const _Rule(),
        Container(
          color: _T.canvas,
          padding: EdgeInsets.fromLTRB(hPad, _T.s72, hPad, _T.s72),
          child: Column(children: [
            _EyebrowPill(
                label: 'FEATURES',
                bg: _T.purpleBg,
                border: _T.purpleBorder,
                dot: _T.purple,
                text: _T.purpleDark),
            const SizedBox(height: _T.s16),
            Text('Everything you need',
                textAlign: TextAlign.center,
                style: _T.heading(size: 34, spacing: -1.4)),
            const SizedBox(height: _T.s8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text('Designed to be simple, without sacrificing depth.',
                  textAlign: TextAlign.center,
                  style: _T.body(size: 15)),
            ),
            const SizedBox(height: _T.s40),
            _FeaturesGrid(
                onGoals: onGoals,
                onStreaks: onStreaks,
                onTrack: onTrack,
                onDailyCheckins: onDailyCheckins,
                onWeekly: onWeekly,
                onAchievements: onAchievements,
                columns: 3),
          ]),
        ),
        const _Rule(),
        Container(
          color: _T.canvas,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: _T.s72),
          child: _CTABlock(onTap: onGoals),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Strip (Dynamic)
// ─────────────────────────────────────────────────────────────────────────────
class _StatsStrip extends StatefulWidget {
  final AnimationController stagger;
  const _StatsStrip({required this.stagger});

  @override
  State<_StatsStrip> createState() => _StatsStripState();
}

class _StatsStripState extends State<_StatsStrip> {
  late final StatsService _statsService = StatsService();

  List<_StatData> get _stats => [
    _StatData(
      icon: Icons.radio_button_checked_outlined,
      value: '${_statsService.activeHabits}',
      label: 'Active habits',
      iconBg: _T.purpleBg,
      iconColor: _T.purple,
      valueColor: _T.purpleDeep,
      labelColor: _T.purple,
    ),
    _StatData(
      icon: Icons.local_fire_department_outlined,
      value: '${_statsService.dayStreak}d',
      label: 'Best streak',
      iconBg: _T.coralBg,
      iconColor: _T.coral,
      valueColor: _T.coralDark,
      labelColor: _T.coral,
    ),
    _StatData(
      icon: Icons.show_chart_rounded,
      value: '${_statsService.successRate}%',
      label: 'Success rate',
      iconBg: _T.tealBg,
      iconColor: _T.teal,
      valueColor: _T.tealDark,
      labelColor: _T.teal,
    ),
    _StatData(
      icon: Icons.calendar_today_outlined,
      value: '${_statsService.totalDays}',
      label: 'Total days',
      iconBg: _T.blueBg,
      iconColor: _T.blue,
      valueColor: _T.blueDark,
      labelColor: _T.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 600;

    final cells = List.generate(_stats.length, (i) {
      final s = _stats[i];
      final delay = i * 0.1;
      return AnimatedBuilder(
        animation: widget.stagger,
        builder: (_, child) {
          final raw = (widget.stagger.value - delay) / (1.0 - delay);
          final t = Curves.easeOut.transform(raw.clamp(0.0, 1.0));
          return Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 10 * (1 - t)), child: child),
          );
        },
        child: _StatCell(data: s, isPhone: isPhone),
      );
    });

    if (isPhone) {
      return Container(
        color: _T.surface,
        child: Column(children: [
          IntrinsicHeight(
            child: Row(children: [
              Expanded(child: cells[0]),
              VerticalDivider(width: 1, thickness: 1, color: _T.border),
              Expanded(child: cells[1]),
            ]),
          ),
          Divider(height: 1, thickness: 1, color: _T.border),
          IntrinsicHeight(
            child: Row(children: [
              Expanded(child: cells[2]),
              VerticalDivider(width: 1, thickness: 1, color: _T.border),
              Expanded(child: cells[3]),
            ]),
          ),
        ]),
      );
    }

    return Container(
      color: _T.surface,
      child: IntrinsicHeight(
        child: Row(children: [
          for (int i = 0; i < cells.length; i++) ...[
            Expanded(child: cells[i]),
            if (i < cells.length - 1)
              VerticalDivider(width: 1, thickness: 1, color: _T.border),
          ],
        ]),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final _StatData data;
  final bool isPhone;
  const _StatCell({required this.data, required this.isPhone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 20 : 28, vertical: isPhone ? 24 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPhone ? 36 : 40,
            height: isPhone ? 36 : 40,
            decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(_T.r8)),
            child: Icon(data.icon,
                size: isPhone ? 16 : 18, color: data.iconColor),
          ),
          const SizedBox(height: _T.s12),
          Text(data.value,
              style: TextStyle(
                  fontSize: isPhone ? 26 : 30,
                  fontWeight: FontWeight.w500,
                  color: data.valueColor,
                  letterSpacing: -1.2)),
          const SizedBox(height: 3),
          Text(data.label,
              style: _T.label(size: isPhone ? 10 : 11, color: data.labelColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Features Grid
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesGrid extends StatelessWidget {
  final VoidCallback onGoals, onStreaks, onTrack, onDailyCheckins, onWeekly, onAchievements;
  final int columns;

  const _FeaturesGrid({
    required this.onGoals,
    required this.onStreaks,
    required this.onTrack,
    required this.onDailyCheckins,
    required this.onWeekly,
    required this.onAchievements,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    final defs = [
      _FeatureData(
        icon: Icons.radio_button_checked_outlined,
        title: 'Set your goals',
        body: 'Custom habits with categories, icons, and reminders.',
        iconBg: _T.purpleBg,
        iconColor: _T.purple,
        borderColor: _T.purpleBorder,
        onTap: onGoals,
      ),
      _FeatureData(
        icon: Icons.local_fire_department_outlined,
        title: 'Build streaks',
        body: 'Daily streak tracking with visual momentum indicators.',
        iconBg: _T.coralBg,
        iconColor: _T.coral,
        borderColor: _T.coralBorder,
        onTap: onStreaks,
      ),
      _FeatureData(
        icon: Icons.show_chart_rounded,
        title: 'Track progress',
        body: 'Clean charts that show your journey at a glance.',
        iconBg: _T.blueBg,
        iconColor: _T.blue,
        borderColor: _T.blueBorder,
        onTap: onTrack,
      ),
      _FeatureData(
        icon: Icons.calendar_today_outlined,
        title: 'Daily check-ins',
        body: 'One-tap completions — nothing in the way.',
        iconBg: _T.tealBg,
        iconColor: _T.teal,
        borderColor: _T.tealBorder,
        onTap: onDailyCheckins,
      ),
      _FeatureData(
        icon: Icons.bar_chart_rounded,
        title: 'Weekly insights',
        body: 'Understand your patterns with weekly summaries.',
        iconBg: _T.amberBg,
        iconColor: _T.amber,
        borderColor: _T.amberBorder,
        onTap: onWeekly,
      ),
      _FeatureData(
        icon: Icons.diamond_outlined,
        title: 'Achievements',
        body: 'Celebrate milestones as momentum compounds.',
        iconBg: _T.coralBg,
        iconColor: _T.coralDark,
        borderColor: _T.coralBorder,
        onTap: onAchievements,
      ),
    ];

    final rows = <Widget>[];
    for (int i = 0; i < defs.length; i += columns) {
      final chunk = defs.sublist(i, math.min(i + columns, defs.length));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int j = 0; j < chunk.length; j++) ...[
              Expanded(child: _FeatureCard(data: chunk[j])),
              if (j < chunk.length - 1)
                VerticalDivider(width: 1, thickness: 1, color: _T.border),
            ],
          ],
        ),
      ));
      if (i + columns < defs.length) {
        rows.add(Divider(height: 1, thickness: 1, color: _T.border));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border.all(color: _T.border),
        borderRadius: BorderRadius.circular(_T.r16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor:
          d.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: d.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(24),
          color: _hovered ? const Color(0xFFF5F4F1) : _T.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hovered ? d.iconColor : d.iconBg,
                  borderRadius: BorderRadius.circular(_T.r8),
                  border: Border.all(
                      color: _hovered ? d.iconColor : d.borderColor),
                ),
                child: Icon(d.icon,
                    size: 16,
                    color: _hovered ? _T.surface : d.iconColor),
              ),
              const SizedBox(height: _T.s16),
              Row(children: [
                Text(d.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _T.ink,
                        letterSpacing: -0.3)),
                if (d.onTap != null) ...[
                  const SizedBox(width: _T.s4),
                  AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.arrow_forward,
                        size: 12, color: d.iconColor),
                  ),
                ],
              ]),
              const SizedBox(height: 5),
              Text(d.body, style: _T.body(size: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA Block
// ─────────────────────────────────────────────────────────────────────────────
class _CTABlock extends StatelessWidget {
  final VoidCallback onTap;
  const _CTABlock({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
      decoration: BoxDecoration(
        color: _T.ink,
        borderRadius: BorderRadius.circular(_T.r16),
      ),
      child: Column(children: [
        const Text('Ready to begin?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w500,
                color: _T.surface,
                letterSpacing: -1.8,
                height: 1.05)),
        const SizedBox(height: _T.s12),
        Text("One small habit, every day. That's all it takes.",
            textAlign: TextAlign.center,
            style: _T.body(size: 15, color: const Color(0xFF888888))),
        const SizedBox(height: _T.s32),
        _Tappable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(_T.r8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Text('Get started',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _T.ink,
                      letterSpacing: -0.3)),
              SizedBox(width: _T.s8),
              Icon(Icons.arrow_forward, size: 14, color: _T.ink),
            ]),
          ),
        ),
        const SizedBox(height: _T.s24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: _T.s8,
          children: const [
            _CTAChip('Unlimited habits'),
            _CTAChip('Daily streaks'),
            _CTAChip('Progress charts'),
          ],
        ),
      ]),
    );
  }
}

class _CTAChip extends StatelessWidget {
  final String label;
  const _CTAChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2E2E2E)),
          borderRadius: BorderRadius.circular(_T.r100)),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12, color: Color(0xFF7A7A7A), letterSpacing: -0.1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final double hPad;
  final bool isPhone;
  const _Footer({required this.hPad, required this.isPhone});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: isPhone ? 16 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _LogoMark(size: isPhone ? 22 : 26),
            const SizedBox(width: _T.s8),
            Text('HabitFlow',
                style: TextStyle(
                    fontSize: isPhone ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: _T.ink,
                    letterSpacing: -0.3)),
          ]),
          Text('© 2026 HabitFlow · Astha Agarwal',
              style: _T.label(size: isPhone ? 11 : 12, color: _T.ink3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primitives
// ─────────────────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(_T.r100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: text,
                letterSpacing: 0.06 * 11)),
      ]),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: _T.border);
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
              color: _T.ink,
              borderRadius: BorderRadius.circular(_T.r8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
}

class _Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tappable({required this.child, this.onTap});

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
        child: widget.child,
      ),
    );
  }
}