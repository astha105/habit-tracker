// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/config/app_config.dart';
import 'package:habit_tracker/theme/app_colors.dart';
import 'package:habit_tracker/screens/landing_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loggingOut = false;
  bool _showHabitStep = false;

  // Per-slide animation controllers
  late final List<AnimationController> _slideCtrl;
  late final List<Animation<double>> _slideFade;
  late final List<Animation<Offset>> _slideOffset;

  static const _slides = [
    _SlideData(
      emoji: '🎯',
      title: 'Build Better\nHabits',
      description:
          'Transform your life one habit at a time. Track daily routines and watch yourself grow.',
      accentColor: AppColors.purple,
    ),
    _SlideData(
      emoji: '🔥',
      title: 'Track Your\nStreaks',
      description:
          'Stay motivated with streak tracking. Build momentum and never break the chain.',
      accentColor: AppColors.coral,
    ),
    _SlideData(
      emoji: '📊',
      title: 'Visualize\nProgress',
      description:
          'Beautiful insights and stats help you understand your habits better.',
      accentColor: AppColors.blue,
    ),
    _SlideData(
      emoji: '🏆',
      title: 'Achieve Your\nGoals',
      description:
          'Turn aspirations into achievements. Start your journey to a better you today.',
      accentColor: AppColors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideCtrl = List.generate(
      _slides.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _slideFade = _slideCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slideOffset = _slideCtrl
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.07),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _slideCtrl[0].forward();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
        _slideCtrl[page].forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _slideCtrl) {
      c.dispose();
    }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _navigateToLanding() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = '${AppConfig.keyOnboardingComplete}_$uid';
    await prefs.setBool(key, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LandingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showHabitStep) {
      return _HabitGuideStep(onDone: _navigateToLanding);
    }

    final accent = _slides[_currentPage].accentColor;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _loggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textMuted,
                          ),
                        )
                      : GestureDetector(
                          onTap: _logout,
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                  GestureDetector(
                    onTap: _navigateToLanding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _slideFade[index],
                    child: SlideTransition(
                      position: _slideOffset[index],
                      child: _SlideContent(slide: _slides[index]),
                    ),
                  );
                },
              ),
            ),

            // ── Dots ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => _buildDot(i, accent),
                ),
              ),
            ),

            // ── CTA button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        setState(() => _showHabitStep = true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.bg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.bg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, Color accent) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? AppColors.lime : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide data model
// ─────────────────────────────────────────────────────────────────────────────
class _SlideData {
  final String emoji;
  final String title;
  final String description;
  final Color accentColor;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide content
// ─────────────────────────────────────────────────────────────────────────────
class _SlideContent extends StatelessWidget {
  final _SlideData slide;
  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: slide.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: slide.accentColor.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Text(slide.emoji,
                  style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 44),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit category picker (last step)
// ─────────────────────────────────────────────────────────────────────────────
class _HabitGuideStep extends StatefulWidget {
  final VoidCallback onDone;
  const _HabitGuideStep({required this.onDone});

  @override
  State<_HabitGuideStep> createState() => _HabitGuideStepState();
}

class _HabitGuideStepState extends State<_HabitGuideStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _starters = [
    _StarterCategory(
      name: 'Health',
      emoji: '❤️',
      suggestion: 'Drink 8 glasses of water',
      color: AppColors.coral,
    ),
    _StarterCategory(
      name: 'Productivity',
      emoji: '🚀',
      suggestion: 'Plan my day every morning',
      color: AppColors.purple,
    ),
    _StarterCategory(
      name: 'Mindfulness',
      emoji: '🧘',
      suggestion: 'Meditate for 10 minutes',
      color: AppColors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Lime accent line
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Pick your first\nhabit category',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "We'll set up your first habit in seconds.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  ..._starters.map((s) => _StarterCard(
                        starter: s,
                        onTap: widget.onDone,
                      )),

                  const Spacer(),

                  Center(
                    child: GestureDetector(
                      onTap: widget.onDone,
                      child: const Text(
                        'Set up later',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  final _StarterCategory starter;
  final VoidCallback onTap;
  const _StarterCard({required this.starter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: starter.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: starter.color.withOpacity(0.25)),
              ),
              child: Center(
                child: Text(starter.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    starter.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '"${starter.suggestion}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: starter.color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterCategory {
  final String name;
  final String emoji;
  final String suggestion;
  final Color color;

  const _StarterCategory({
    required this.name,
    required this.emoji,
    required this.suggestion,
    required this.color,
  });
}
