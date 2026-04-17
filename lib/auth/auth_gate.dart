import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/firestore_service.dart';
import 'auth_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../screens/landing_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _onboardingComplete;

  Future<void> _checkOnboarding() async {
    // Create / update the Firestore user profile on every sign-in
    await FirestoreService().createOrUpdateProfile();

    // Sync premium status directly from Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final isPremium = doc.data()?['premium'] == true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConfig.keyPremiumUnlocked, isPremium);
      }
    } catch (_) {
      // Non-fatal — fall back to cached value
    }

    // Request notification permission (token saving handled when functions are deployed)
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {
      // Non-fatal
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = '${AppConfig.keyOnboardingComplete}_$uid';
    if (mounted) {
      setState(() {
        _onboardingComplete = prefs.getBool(key) ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        // Logged in — check onboarding status
        if (_onboardingComplete == null) {
          _checkOnboarding();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_onboardingComplete!) {
          return const LandingScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}