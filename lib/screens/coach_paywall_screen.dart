// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/config/app_config.dart';
import 'package:habit_tracker/services/payment_service.dart';
import 'package:habit_tracker/theme/app_colors.dart';

class CoachPaywallScreen extends StatefulWidget {
  const CoachPaywallScreen({super.key});

  @override
  State<CoachPaywallScreen> createState() => _CoachPaywallScreenState();
}

class _CoachPaywallScreenState extends State<CoachPaywallScreen> {
  final _paymentService = PaymentService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _paymentService.init();

    _paymentService.onSuccess = (res) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConfig.keyCoachUnlocked, true);
      if (!mounted) return;
      // Return true so CoachScreen can re-check and open the chat
      Navigator.of(context).pop(true);
    };

    _paymentService.onFailure = (res) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${res.message}'),
          backgroundColor: const Color(0xFFD85A30),
          behavior: SnackBarBehavior.floating,
        ),
      );
    };
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _pay() {
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      // Debug — bypass payment
      SharedPreferences.getInstance()
          .then((p) => p.setBool(AppConfig.keyCoachUnlocked, true));
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    _paymentService.openCheckout(
      userPhone: user?.phoneNumber ?? '',
      userEmail: user?.email ?? '',
      userName: user?.displayName ?? '',
    );
  }

  static const _features = [
    (Icons.chat_bubble_outline_rounded, 'Real-time AI habit coaching'),
    (Icons.psychology_outlined, 'Personalised advice from your data'),
    (Icons.auto_awesome_rounded, 'Streaming Jarvis-style responses'),
    (Icons.trending_up_rounded, 'Habit-aware streak strategies'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg : const Color(0xFFFAFAF8);
    final ink = isDark ? AppColors.textPrimary : const Color(0xFF0D0D0D);
    final ink2 = isDark ? AppColors.textSecondary : const Color(0xFF5C5C5C);
    final accent = isDark ? AppColors.lime : const Color(0xFF7C6FD8);
    final accentBg = isDark ? AppColors.lime.withOpacity(0.12) : const Color(0xFFF0EDFE);
    final accentBorder = isDark ? AppColors.lime.withOpacity(0.3) : const Color(0xFFC8C0F8);
    final barBg = isDark ? AppColors.bg2 : Colors.white;
    final divider = isDark ? AppColors.borderDark : const Color(0xFFE6E5E0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: barBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ink, size: 18),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        centerTitle: true,
        title: Text(
          'AI Habit Coach',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ink,
            letterSpacing: -0.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentBorder),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: accent, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Habit Coach',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: ink,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your personal coach that knows your habits,\nstreaks, and what you actually need to hear.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: ink2,
                  height: 1.6,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 32),
              for (final f in _features)
                _FeatureRow(icon: f.$1, label: f.$2, accent: accent, accentBg: accentBg),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: accentBorder),
                ),
                child: Text(
                  'One-time purchase · No subscription',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accentBorder,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Unlock Coach for ${AppConfig.priceDisplay}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Secure payment via Razorpay',
                style: TextStyle(fontSize: 11, color: ink2.withOpacity(0.6)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent, accentBg;
  const _FeatureRow(
      {required this.icon,
      required this.label,
      required this.accent,
      required this.accentBg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimary : const Color(0xFF0D0D0D);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                fontSize: 14, color: ink, letterSpacing: -0.2),
          ),
          const Spacer(),
          Icon(Icons.check_circle_rounded,
              size: 16, color: const Color(0xFF1D9E75)),
        ],
      ),
    );
  }
}
