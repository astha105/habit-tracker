// ignore_for_file: deprecated_member_use, unused_element, unnecessary_underscores, avoid_print, unused_field, curly_braces_in_flow_control_structures, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habit_tracker/screens/goals_screen.dart';
import 'package:habit_tracker/screens/daily_checkins_screen.dart';
import 'package:habit_tracker/screens/weekly_insights_screen.dart';
import 'package:habit_tracker/screens/achievements_screen.dart';
import 'package:habit_tracker/screens/paywall_screen.dart';
import 'package:habit_tracker/screens/coach_screen.dart';
import 'package:habit_tracker/screens/partners_screen.dart';
import 'package:habit_tracker/theme/app_colors.dart';
import 'package:habit_tracker/theme/app_tokens.dart';
import 'package:habit_tracker/config/app_config.dart';
import 'package:habit_tracker/theme/theme_controller.dart';
import 'package:habit_tracker/services/ai_motivation_service.dart';
import 'package:habit_tracker/services/cloud_functions_service.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import 'package:habit_tracker/services/partnership_service.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Lime-green accent used throughout the home UI
const Color _kLime = Color(0xFFC5FF47);

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

  void computeFrom(List<Goal> goals) {
    _activeHabits = goals.where((g) => !g.isCompleted).length;

    int maxStreak = 0;
    for (final g in goals) {
      if (g.currentStreak > maxStreak) maxStreak = g.currentStreak;
    }
    _dayStreak = maxStreak;

    if (goals.isEmpty) {
      _successRate = 0;
    } else {
      double totalRate = 0;
      for (final g in goals) {
        totalRate += (g.currentDays / g.targetDays).clamp(0.0, 1.0);
      }
      _successRate = ((totalRate / goals.length) * 100).toInt();
    }

    _totalDays = goals.fold(0, (sum, g) => sum + g.currentDays);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pressable — scale-down feedback on every tappable surface
// ─────────────────────────────────────────────────────────────────────────────
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _Pressable({required this.child, required this.onTap, this.scale = 0.94});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 160));
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Landing Screen
// ─────────────────────────────────────────────────────────────────────────────
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  bool _loggingOut = false;
  late final StatsService _statsService;
  int _activeTabIndex = 0;

  List<Goal> _goals = [];
  bool _dataLoaded = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  StreamSubscription<List<Map<String, dynamic>>>? _nudgeSub;

  @override
  void initState() {
    super.initState();
    _statsService = StatsService();
    _loadAll();
    _entryCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
    _listenForNudges();
  }

  void _listenForNudges() {
    final service = PartnershipService();
    _nudgeSub = service.watchNudges().listen((nudges) {
      if (!mounted || nudges.isEmpty) return;
      final nudge = nudges.first;
      final nudgeId = nudge['id'] as String;
      final from = nudge['fromName'] as String? ?? 'Your partner';
      final habit = nudge['habitTitle'] as String? ?? 'a habit';
      service.markNudgeSeen(nudgeId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('👉 $from nudged you to complete "$habit"!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.coral,
      ));
    });
  }

  Future<void> _loadAll() async {
    try {
      final fs = FirestoreService();
      var goals = await fs.loadHabits();
      goals = await fs.resetMissedStreaks(goals);
      _statsService.computeFrom(goals);
      await NotificationService.scheduleDailyReminder();
      if (mounted) {
        setState(() {
          _goals = goals;
          _dataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('_loadAll error: $e');
      if (mounted) setState(() => _dataLoaded = true);
    }
  }

  @override
  void dispose() {
    _nudgeSub?.cancel();
    _entryCtrl.dispose();
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
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not sign out: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently deletes all your habits, streaks, and data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await CloudFunctionsService.deleteAccount();
    if (!mounted) return;

    if (success) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete account. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);
        final tokens = AppTokens(isDark);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F2),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 83),
                  child: _buildTabContent(tokens),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _NavBar(
                    activeIndex: _activeTabIndex,
                    isDark: isDark,
                    onTap: (index) {
                      final prev = _activeTabIndex;
                      setState(() => _activeTabIndex = index);
                      if (index == 0 && prev != 0) _loadAll();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(AppTokens tokens) {
    switch (_activeTabIndex) {
      case 0:
        return _HomeTab(
          goals: _goals,
          statsService: _statsService,
          dataLoaded: _dataLoaded,
          tokens: tokens,
          onGoToGoals: () => setState(() => _activeTabIndex = 2),
          onGoToInsights: () => setState(() => _activeTabIndex = 1),
          onTrack: () => _push(const PaywallScreen()),
          onDailyCheckins: () => setState(() => _activeTabIndex = 3),
          onAchievements: () => setState(() => _activeTabIndex = 4),
          onCoach: () => _push(const CoachScreen()),
          onPartners: () => _push(const PartnersScreen()),
        );
      case 1:
        return WeeklyInsightsScreen(onBack: () => setState(() => _activeTabIndex = 0));
      case 2:
        return GoalsScreen(onBack: () {
          setState(() => _activeTabIndex = 0);
          _loadAll();
        });
      case 3:
        return DailyCheckinsScreen(onBack: () => setState(() => _activeTabIndex = 0));
      case 4:
        return AchievementsScreen(
          goals: _goals,
          streaks: const [],
          onBack: () => setState(() => _activeTabIndex = 0),
        );
      case 5:
        return _ProfileTab(
          onLogout: _logout,
          loggingOut: _loggingOut,
          onDeleteAccount: _deleteAccount,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final List<Goal> goals;
  final StatsService statsService;
  final bool dataLoaded;
  final AppTokens tokens;
  final VoidCallback onGoToGoals, onGoToInsights;
  final VoidCallback onTrack, onDailyCheckins, onAchievements, onCoach, onPartners;

  const _HomeTab({
    required this.goals,
    required this.statsService,
    required this.dataLoaded,
    required this.tokens,
    required this.onGoToGoals,
    required this.onGoToInsights,
    required this.onTrack,
    required this.onDailyCheckins,
    required this.onAchievements,
    required this.onCoach,
    required this.onPartners,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;
  final _fades = <Animation<double>>[];
  final _slides = <Animation<Offset>>[];
  static const _sections = 3;

  String? _aiMotivation;
  bool _aiLoading = true;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    for (int i = 0; i < _sections; i++) {
      final start = (i * 0.22).clamp(0.0, 0.65);
      final end = (start + 0.38).clamp(0.0, 1.0);
      final iv = Interval(start, end, curve: Curves.easeOutCubic);
      _fades.add(Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: _stagger, curve: iv)));
      _slides.add(Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(CurvedAnimation(parent: _stagger, curve: iv)));
    }
    _stagger.forward();
    _loadMotivation();
  }

  Future<void> _loadMotivation() async {
    final cached = await AiMotivationService.getCached();
    if (cached != null) {
      if (mounted) setState(() { _aiMotivation = cached; _aiLoading = false; });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(AppConfig.keyPremiumUnlocked) ?? false;

    try {
      String? text;
      if (isPremium) {
        text = await CloudFunctionsService.getDailyMotivation()
            .timeout(const Duration(seconds: 6), onTimeout: () => null);
      }
      if (text == null) {
        final stats = widget.statsService;
        text = await AiMotivationService.generate(
          bestStreak: stats.dayStreak,
          activeHabits: stats.activeHabits,
          completionPct: stats.successRate.round(),
        );
      }
      if (mounted) setState(() { _aiMotivation = text; _aiLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = widget.tokens.isDark;
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'there';
    final todayItems = _buildTodayItems();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _s(0, Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Hi, $name!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0D0D0D),
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final currentMode = ThemeController.instance.value;
                    final newMode = currentMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                    await ThemeController.instance.setMode(newMode);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E3),
                      shape: BoxShape.circle,
                    ),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.instance,
                      builder: (context, mode, _) {
                        final dark = mode == ThemeMode.dark ||
                            (mode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness == Brightness.dark);
                        return Icon(
                          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 20),

          // ── Date strip ───────────────────────────────────────────────────────
          _s(0, _DateStrip(isDark: isDark)),

          const SizedBox(height: 16),

          // ── Motivation card ──────────────────────────────────────────────────
          _s(1, Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _MotivationCard(
              text: _aiMotivation ?? AppConfig.dailyQuote.text,
              loading: _aiLoading,
              isDark: isDark,
            ),
          )),

          const SizedBox(height: 28),

          // ── "Track your habits" heading ────────────────────────────────────────
          _s(2, Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Track your\nhabits',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0D0D0D),
                      height: 1.05,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onGoToGoals,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2E2DC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 20),

          // ── Habit list ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              child: _HabitContent(
                items: todayItems,
                dataLoaded: widget.dataLoaded,
                isDark: isDark,
                onEmpty: widget.onGoToGoals,
                onCoach: widget.onCoach,
                onPartners: widget.onPartners,
                onDailyCheckins: widget.onDailyCheckins,
                onAchievements: widget.onAchievements,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TodayItem> _buildTodayItems() {
    final items = <_TodayItem>[];
    for (final goal in widget.goals) {
      final parts = <String>[
        if (goal.targetDays > 0) '${goal.targetDays} day goal',
        if (goal.category.isNotEmpty && goal.category != 'General') goal.category,
      ];
      items.add(_TodayItem(
        name: goal.title,
        meta: parts.isEmpty ? 'Goal' : parts.join(' · '),
        streakDays: goal.currentStreak,
        isDone: goal.loggedToday,
        color: AppTokens.purple,
      ));
    }
    return items;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class _TodayItem {
  final String name, meta;
  final int streakDays;
  final bool isDone;
  final Color color;

  const _TodayItem({
    required this.name,
    required this.meta,
    required this.streakDays,
    required this.isDone,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Strip — horizontal scrollable week view
// ─────────────────────────────────────────────────────────────────────────────
class _DateStrip extends StatelessWidget {
  final bool isDark;
  const _DateStrip({required this.isDark});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = days[i];
          final isToday = i == 0;
          final dayName = _dayNames[d.weekday - 1];
          return Container(
            width: 46,
            decoration: BoxDecoration(
              color: isToday
                  ? _kLime
                  : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEAEAE5)),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? Colors.black
                        : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isToday
                        ? Colors.black54
                        : (isDark ? const Color(0xFF555555) : const Color(0xFF999999)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivation Card — small inline card with gradient icon
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationCard extends StatelessWidget {
  final String text;
  final bool loading;
  final bool isDark;

  const _MotivationCard({
    required this.text,
    required this.loading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: loading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B7FFF), Color(0xFF5544CC)],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? const Color(0xFFBBBBBB) : const Color(0xFF444444),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit Content — top 2 as grid cards, rest as list rows
// ─────────────────────────────────────────────────────────────────────────────
class _HabitContent extends StatelessWidget {
  final List<_TodayItem> items;
  final bool dataLoaded;
  final bool isDark;
  final VoidCallback onEmpty;
  final VoidCallback onCoach;
  final VoidCallback onPartners;
  final VoidCallback onDailyCheckins;
  final VoidCallback onAchievements;

  const _HabitContent({
    required this.items,
    required this.dataLoaded,
    required this.isDark,
    required this.onEmpty,
    required this.onCoach,
    required this.onPartners,
    required this.onDailyCheckins,
    required this.onAchievements,
  });

  @override
  Widget build(BuildContext context) {
    if (!dataLoaded) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 1.5, color: _kLime),
        ),
      );
    }
    final gridItems = items.take(2).toList();
    final listItems = items.skip(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty) ...[
          _EmptyHabits(isDark: isDark, onTap: onEmpty),
          const SizedBox(height: 20),
        ],
        if (items.isNotEmpty) Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _HabitGridCard(item: gridItems[0], isDark: isDark)),
            if (gridItems.length >= 2) ...[
              const SizedBox(width: 12),
              Expanded(child: _HabitGridCard(item: gridItems[1], isDark: isDark)),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
        if (listItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final item in listItems)
            _HabitListItem(item: item, isDark: isDark),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.psychology_outlined,
                label: 'AI Habit\nCoach',
                iconColor: const Color(0xFF9B7FFF),
                isDark: isDark,
                onTap: onCoach,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.people_outline_rounded,
                label: 'Accountability\nPartners',
                iconColor: AppTokens.coral,
                isDark: isDark,
                onTap: onPartners,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Card — coach / partners shortcut cards
// ─────────────────────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0D0D0D),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 11,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded, size: 10, color: iconColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit Grid Card — first two habits shown as side-by-side cards
// ─────────────────────────────────────────────────────────────────────────────
class _HabitGridCard extends StatelessWidget {
  final _TodayItem item;
  final bool isDark;

  const _HabitGridCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isDone = item.isDone;
    final mutedColor = isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF272727) : const Color(0xFFF0F0EC),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.emoji_flags_outlined, size: 14, color: item.color),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? _kLime : Colors.transparent,
                  border: isDone
                      ? null
                      : Border.all(
                          color: isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFD8D8D0),
                          width: 1.5,
                        ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDone
                  ? mutedColor
                  : (isDark ? Colors.white : const Color(0xFF0D0D0D)),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.directions_run_rounded, size: 11, color: mutedColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.streakDays > 0
                      ? '${item.streakDays}/30 days'
                      : item.meta,
                  style: TextStyle(fontSize: 11, color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit List Item — habits 3 and beyond, shown as list rows
// ─────────────────────────────────────────────────────────────────────────────
class _HabitListItem extends StatelessWidget {
  final _TodayItem item;
  final bool isDark;

  const _HabitListItem({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isDone = item.isDone;
    final mutedColor = isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? _kLime : Colors.transparent,
              border: isDone
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFCCCCC5),
                      width: 1.5,
                    ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? mutedColor
                        : (isDark ? Colors.white : const Color(0xFF0D0D0D)),
                  ),
                ),
                if (item.streakDays > 0 || item.meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.streakDays > 0
                        ? "You've kept this ${item.streakDays} ${item.streakDays == 1 ? 'day' : 'days'} in a row!"
                        : item.meta,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyHabits extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _EmptyHabits({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No habits yet.',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Add your first habit →',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kLime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Tab
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout, onDeleteAccount;
  final bool loggingOut;

  const _ProfileTab({
    required this.onLogout,
    required this.loggingOut,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.secondary, cs.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: cs.onSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(name,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(email,
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.55))),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: loggingOut ? null : onLogout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.error.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: loggingOut
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.error),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, size: 16, color: cs.error),
                              const SizedBox(width: 8),
                              Text(
                                'Sign out',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.error),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onDeleteAccount,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.error.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_forever_outlined,
                            size: 16, color: cs.error.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text(
                          'Delete account',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.error.withOpacity(0.6)),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Nav Bar — floating dark pill at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int activeIndex;
  final bool isDark;
  final Function(int) onTap;

  const _NavBar({
    required this.activeIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    (0, Icons.home_rounded),
    (1, Icons.show_chart_rounded),
    (2, Icons.add_rounded),
    (3, Icons.checklist_rounded),
    (4, Icons.emoji_events_outlined),
    (5, Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(31),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final item in _items)
                  _NavItem(
                    icon: item.$2,
                    isActive: activeIndex == item.$1,
                    isDark: isDark,
                    onTap: () => onTap(item.$1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _kLime : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive
              ? Colors.black
              : (isDark ? const Color(0xFF555555) : const Color(0xFF999999)),
        ),
      ),
    );
  }
}
