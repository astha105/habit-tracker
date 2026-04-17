// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habit_tracker/config/app_config.dart';
import 'package:habit_tracker/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _isSignUp = false;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
        debugPrint('✅ Web sign-in successful');
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: AppConfig.googleServerClientId,
        );

        try {
          await googleSignIn.signOut();
        } catch (e) {
          debugPrint('⚠️ Sign out error (can ignore): $e');
        }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('⚠️ User cancelled sign-in');
          setState(() => _loading = false);
          return;
        }

        debugPrint('✅ Google user signed in: ${googleUser.email}');

        GoogleSignInAuthentication? googleAuth;
        try {
          googleAuth = await googleUser.authentication;
        } catch (e) {
          debugPrint('❌ Error getting auth: $e');
          await Future.delayed(const Duration(milliseconds: 500));
          googleAuth = await googleUser.authentication;
        }

        debugPrint(
            '🔑 Access Token: ${googleAuth.accessToken != null ? "✓" : "✗"}');
        debugPrint(
            '🔑 ID Token: ${googleAuth.idToken != null ? "✓" : "✗"}');

        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          throw Exception(
            'Authentication failed. Please ensure:\n'
            '1. SHA-1 is configured in Firebase Console (already done ✓)\n'
            '2. google-services.json is up to date\n'
            '3. Google Sign-In is enabled in Firebase Authentication\n'
            '4. Try: flutter clean && flutter pub get',
          );
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint('✅ Firebase sign-in successful');
      }
    } catch (e) {
      debugPrint('❌ Google Sign-In Error: $e');
      if (mounted) {
        String errorMessage = 'Sign-in failed. Please try again.';
        if (e.toString().contains('network_error')) {
          errorMessage = 'Network error. Check your connection.';
        } else if (e.toString().contains('sign_in_failed')) {
          errorMessage =
              'Sign-in failed. Please check your Google Play Services.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _signInWithGoogle,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive color tokens ──────────────────────────────────────────────
    final bg        = isDark ? AppColors.bg        : const Color(0xFFF7F5FF);
    final cardBg    = isDark ? AppColors.bg2       : Colors.white;
    final inputBg   = isDark ? AppColors.bg3       : const Color(0xFFF0EEF8);
    final txtPrimary   = isDark ? AppColors.textPrimary  : const Color(0xFF0D0D1A);
    final txtSecondary = isDark ? AppColors.textSecondary: const Color(0xFF5C5870);
    final txtMuted     = isDark ? AppColors.textMuted    : const Color(0xFF9B97AA);
    final accent    = isDark ? AppColors.lime       : AppColors.purpleLight;
    final borderColor  = isDark ? Colors.white.withOpacity(0.07) : AppColors.borderLight;
    final dividerColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

                    // ── App icon ──────────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, Color(0xFF6B5FD8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(isDark ? 0.35 : 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── App name ──────────────────────────────────────────
                    Text(
                      'Welcome To ${AppConfig.appName}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: txtPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isSignUp
                            ? 'Start your journey to better habits'
                            : 'Build the best version of yourself\nby perfecting your habits',
                        key: ValueKey('subtitle_$_isSignUp'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: txtSecondary,
                          height: 1.55,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Auth card ─────────────────────────────────────────
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isSignUp ? 'Create account' : 'Welcome back',
                              key: ValueKey('title_$_isSignUp'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: txtPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isSignUp
                                  ? 'Sign up to start tracking your habits'
                                  : 'Sign in to continue your streak',
                              key: ValueKey('sub_$_isSignUp'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: txtMuted,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildGoogleButton(isDark: isDark, inputBg: inputBg, txtPrimary: txtPrimary, accent: accent, borderColor: borderColor),

                          if (_isSignUp) ...[
                            const SizedBox(height: 14),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: txtMuted,
                                ),
                                children: [
                                  const TextSpan(
                                      text:
                                          'By signing up, you agree to our '),
                                  TextSpan(
                                    text: 'Terms',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          Divider(height: 1, color: dividerColor),
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () =>
                                setState(() => _isSignUp = !_isSignUp),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: txtSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isSignUp
                                        ? 'Already have an account? '
                                        : "Don't have an account? ",
                                  ),
                                  TextSpan(
                                    text: _isSignUp ? 'Log in' : 'Sign up',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Feature pills ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeaturePill(Icons.show_chart_rounded, 'Track Progress',
                            isDark: isDark, cardBg: cardBg, accent: accent, txtSecondary: txtSecondary, borderColor: borderColor),
                        const SizedBox(width: 10),
                        _buildFeaturePill(Icons.local_fire_department_rounded, 'Build Streaks',
                            isDark: isDark, cardBg: cardBg, accent: accent, txtSecondary: txtSecondary, borderColor: borderColor),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton({
    required bool isDark,
    required Color inputBg,
    required Color txtPrimary,
    required Color accent,
    required Color borderColor,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: inputBg,
          foregroundColor: txtPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
        ),
        child: _loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                    width: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: txtPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, {
    required bool isDark,
    required Color cardBg,
    required Color accent,
    required Color txtSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: txtSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
