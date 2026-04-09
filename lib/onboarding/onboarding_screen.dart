// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ✅ IMPORTANT: keep this import
import 'package:habit_tracker/screens/landing_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loggingOut = false;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      emoji: '🎯',
      title: 'Build Better Habits',
      description:
          'Transform your life one habit at a time. Track your daily routines and watch yourself grow.',
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
      backgroundColor: const Color(0xFFF3F0FF),
    ),
    OnboardingSlide(
      emoji: '🔥',
      title: 'Track Your Streaks',
      description:
          'Stay motivated with streak tracking. Build momentum and never break the chain.',
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
      ),
      backgroundColor: const Color(0xFFFFEEE8),
    ),
    OnboardingSlide(
      emoji: '📊',
      title: 'Visualize Progress',
      description:
          'Beautiful insights and statistics help you understand your habits better.',
      gradient: const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      ),
      backgroundColor: const Color(0xFFE8F0FF),
    ),
    OnboardingSlide(
      emoji: '🏆',
      title: 'Achieve Your Goals',
      description:
          'Turn aspirations into achievements. Start your journey to a better you today.',
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
      backgroundColor: const Color(0xFFE8F7F0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      if (!kIsWeb) {
        try {
          final googleSignIn = GoogleSignIn();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }
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

  void _navigateToLanding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LandingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _slides[_currentPage].backgroundColor,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _loggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _logout,
                              child: const Text('Logout'),
                            ),
                      TextButton(
                        onPressed: _navigateToLanding,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _SlideContent(slide: _slides[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToLanding();
                        }
                      },
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────

class _SlideContent extends StatelessWidget {
  final OnboardingSlide slide;

  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 30),
          Text(slide.title, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String emoji;
  final String title;
  final String description;
  final LinearGradient gradient;
  final Color backgroundColor;

  OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
    required this.backgroundColor,
  });
}