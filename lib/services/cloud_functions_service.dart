// ignore_for_file: avoid_print

import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/config/app_config.dart';

/// Wrapper around Firebase Cloud Functions callable endpoints.
///
/// All methods are static and swallow network errors gracefully so callers
/// do not need to catch — they receive null / false on failure.
abstract final class CloudFunctionsService {
  static final _functions = FirebaseFunctions.instance;

  // ── Premium ─────────────────────────────────────────────────────────────────

  /// Fetches the authoritative premium status from Firestore via Cloud Function
  /// and persists it to SharedPreferences so the rest of the app can read it
  /// synchronously via [AppConfig.keyPremiumUnlocked].
  ///
  /// Returns true if the user is premium, false otherwise.
  static Future<bool> checkAndSyncPremium() async {
    try {
      final result = await _functions
          .httpsCallable('checkPremiumStatus')
          .call<Map<String, dynamic>>();
      final isPremium = result.data['premium'] == true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConfig.keyPremiumUnlocked, isPremium);
      return isPremium;
    } catch (e) {
      print('⚠️ checkPremiumStatus failed: $e');
      // Fall back to locally cached value
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConfig.keyPremiumUnlocked) ?? false;
    }
  }

  // ── FCM ─────────────────────────────────────────────────────────────────────

  /// Saves the FCM device token to Firestore so the backend can send
  /// push notifications (weekly digest, streaks, etc.).
  static Future<void> saveFcmToken(String token) async {
    try {
      await _functions
          .httpsCallable('saveFcmToken')
          .call<Map<String, dynamic>>({'token': token});
      print('✓ FCM token saved');
    } catch (e) {
      print('⚠️ saveFcmToken failed: $e');
    }
  }

  // ── AI — Daily Motivation ────────────────────────────────────────────────────

  /// Returns a personalised daily motivation message.
  ///
  /// - Free users: rule-based message generated server-side.
  /// - Premium users: Claude-generated, cached per day in Firestore.
  ///
  /// Returns null on error so the caller can fall back to the local service.
  static Future<String?> getDailyMotivation() async {
    try {
      final result = await _functions
          .httpsCallable('getDailyMotivation')
          .call<Map<String, dynamic>>();
      final message = result.data['message'] as String?;
      return message;
    } catch (e) {
      print('⚠️ getDailyMotivation failed: $e');
      return null;
    }
  }

  // ── AI — Weekly Review ───────────────────────────────────────────────────────

  /// Returns a personalised weekly review narrative.
  ///
  /// - Free users: rule-based review generated server-side.
  /// - Premium users: Claude-generated, cached per ISO week in Firestore.
  ///
  /// Returns null on error so the caller can fall back to the local service.
  static Future<String?> getWeeklyReview() async {
    try {
      final result = await _functions
          .httpsCallable('getWeeklyReview')
          .call<Map<String, dynamic>>();
      final review = result.data['review'] as String?;
      return review;
    } catch (e) {
      print('⚠️ getWeeklyReview failed: $e');
      return null;
    }
  }

  // ── AI — Habit Coach ─────────────────────────────────────────────────────────

  /// Sends a conversation turn to the AI Habit Coach (premium only).
  ///
  /// [messages] is the full conversation history in the format:
  ///   `[{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}, ...]`
  ///
  /// Returns the assistant reply string, or null on error.
  static Future<String?> chatWithCoach(
      List<Map<String, String>> messages) async {
    try {
      final result = await _functions
          .httpsCallable('chatWithCoach')
          .call<Map<String, dynamic>>({'messages': messages});
      return result.data['reply'] as String?;
    } catch (e) {
      print('⚠️ chatWithCoach failed: $e');
      return null;
    }
  }

  // ── Accountability Partners ───────────────────────────────────────────────────

  /// Creates a pending partnership for [habitIds] and returns a 6-char invite code.
  static Future<Map<String, String>?> createPartnership(
      List<String> habitIds) async {
    try {
      final result = await _functions
          .httpsCallable('createPartnership')
          .call<Map<String, dynamic>>({'habitIds': habitIds});
      return {
        'inviteCode': result.data['inviteCode'] as String,
        'partnershipId': result.data['partnershipId'] as String,
      };
    } catch (e) {
      print('⚠️ createPartnership failed: $e');
      return null;
    }
  }

  /// Accepts a partnership invite with [inviteCode].
  /// Returns the owner's display name on success, null on failure.
  static Future<String?> acceptPartnership(String inviteCode) async {
    try {
      final result = await _functions
          .httpsCallable('acceptPartnership')
          .call<Map<String, dynamic>>({'inviteCode': inviteCode});
      return result.data['ownerName'] as String?;
    } catch (e) {
      print('⚠️ acceptPartnership failed: $e');
      rethrow; // caller needs the error message
    }
  }

  /// Returns all active partnerships for the current user.
  static Future<List<Map<String, dynamic>>> getPartnerships() async {
    try {
      final result = await _functions
          .httpsCallable('getPartnerships')
          .call<Map<String, dynamic>>();
      final list = result.data['partnerships'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      print('⚠️ getPartnerships failed: $e');
      return [];
    }
  }

  /// Sends a nudge push notification to the partner.
  /// Returns true if the FCM message was sent.
  static Future<bool> nudgePartner(
      String partnershipId, String habitId) async {
    try {
      final result = await _functions
          .httpsCallable('nudgePartner')
          .call<Map<String, dynamic>>({
        'partnershipId': partnershipId,
        'habitId': habitId,
      });
      return result.data['sent'] == true;
    } catch (e) {
      print('⚠️ nudgePartner failed: $e');
      return false;
    }
  }

  // ── Account ──────────────────────────────────────────────────────────────────

  /// Permanently deletes the current user's account and all associated data
  /// (habits, stats, coach history) from Firestore and Firebase Auth.
  ///
  /// Returns true on success, false on failure.
  static Future<bool> deleteAccount() async {
    try {
      await _functions.httpsCallable('deleteAccount').call<Map<String, dynamic>>();
      return true;
    } catch (e) {
      print('⚠️ deleteAccount failed: $e');
      return false;
    }
  }
}
