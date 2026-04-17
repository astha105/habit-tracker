import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppConfig — single source of truth for all configurable values
// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppConfig {
  // ── App identity ────────────────────────────────────────────────────────────
  static const String appName = 'Habitron';

  // ── Gemini API ───────────────────────────────────────────────────────────────
  /// Set via lib/config/secrets.dart (see secrets.dart.example)
  static const String geminiApiKey = '';

  // ── Google Sign-In ───────────────────────────────────────────────────────────
  static const String googleServerClientId =
      '760177477560-a8uihu7lsou342va4c2lopq1d4flc3vd.apps.googleusercontent.com';

  // ── Storage keys ─────────────────────────────────────────────────────────────
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyPremiumUnlocked = 'premium_unlocked';
  static const String keyCoachUnlocked = 'coach_unlocked';

  // ── Pricing ─────────────────────────────────────────────────────────────────
  /// Amount in paise (1 INR = 100 paise). Must match Razorpay `amount` field.
  static const int priceInPaise = 19900; // ₹199
  static String get priceDisplay => '₹${priceInPaise ~/ 100}';

  // ── Paywall features ────────────────────────────────────────────────────────
  static const List<PaywallFeature> paywallFeatures = [
    PaywallFeature(icon: Icons.bar_chart_rounded,               label: 'Weekly completion charts'),
    PaywallFeature(icon: Icons.local_fire_department_outlined,  label: 'Streak tracking'),
    PaywallFeature(icon: Icons.grid_view_rounded,               label: 'Activity heatmap'),
    PaywallFeature(icon: Icons.emoji_events_outlined,           label: 'Top performer insights'),
  ];

  // ── Daily quotes ────────────────────────────────────────────────────────────
  static const List<AppQuote> quotes = [
    AppQuote(
      text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      author: 'Aristotle',
    ),
    AppQuote(
      text: 'Motivation is what gets you started. Habit is what keeps you going.',
      author: 'Jim Ryun',
    ),
    AppQuote(
      text: 'Small daily improvements are the key to staggering long-term results.',
      author: 'Robin Sharma',
    ),
    AppQuote(
      text: 'Success is the sum of small efforts repeated day in and day out.',
      author: 'Robert Collier',
    ),
    AppQuote(
      text: 'First forget inspiration. Habit is more dependable.',
      author: 'Octavia Butler',
    ),
    AppQuote(
      text: 'The secret of your future is hidden in your daily routine.',
      author: 'Mike Murdock',
    ),
    AppQuote(
      text: 'You do not rise to the level of your goals. You fall to the level of your systems.',
      author: 'James Clear',
    ),
  ];

  /// Returns a quote that rotates daily.
  static AppQuote get dailyQuote {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  // ── Onboarding slides ───────────────────────────────────────────────────────
  static const List<OnboardingSlideData> onboardingSlides = [
    OnboardingSlideData(
      emoji: '🎯',
      title: 'Build Better Habits',
      description: 'Transform your life one habit at a time. Track your daily routines and watch yourself grow.',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      backgroundColor: Color(0xFFF3F0FF),
    ),
    OnboardingSlideData(
      emoji: '🔥',
      title: 'Track Your Streaks',
      description: 'Stay motivated with streak tracking. Build momentum and never break the chain.',
      gradientColors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
      backgroundColor: Color(0xFFFFEEE8),
    ),
    OnboardingSlideData(
      emoji: '📊',
      title: 'Visualize Progress',
      description: 'Beautiful insights and statistics help you understand your habits better.',
      gradientColors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      backgroundColor: Color(0xFFE8F0FF),
    ),
    OnboardingSlideData(
      emoji: '🏆',
      title: 'Achieve Your Goals',
      description: 'Turn aspirations into achievements. Start your journey to a better you today.',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      backgroundColor: Color(0xFFE8F7F0),
    ),
  ];
}

// ─── Value types ──────────────────────────────────────────────────────────────
class PaywallFeature {
  final IconData icon;
  final String label;
  const PaywallFeature({required this.icon, required this.label});
}

class AppQuote {
  final String text;
  final String author;
  const AppQuote({required this.text, required this.author});
}

class OnboardingSlideData {
  final String emoji;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final Color backgroundColor;
  const OnboardingSlideData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.backgroundColor,
  });
}
