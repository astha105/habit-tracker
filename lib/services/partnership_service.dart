// ignore_for_file: avoid_print

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles accountability-partner logic directly via Firestore.
/// No Cloud Functions required — works on the free Spark plan.
class PartnershipService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String? get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email?.split('@').first;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Create invite ──────────────────────────────────────────────────────────

  /// Creates a pending partnership and returns the invite code + doc id.
  Future<Map<String, String>?> createPartnership({
    required List<String> habitIds,
    required List<String> habitTitles,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final code = _generateCode();
      final ref = await _db.collection('partnerships').add({
        'ownerUid': uid,
        'ownerName': _displayName ?? 'Your friend',
        'partnerUid': null,
        'partnerName': null,
        'habitIds': habitIds,
        'habitTitles': habitTitles,
        'status': 'pending',
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {'inviteCode': code, 'partnershipId': ref.id};
    } catch (e) {
      print('⚠️ createPartnership failed: $e');
      return null;
    }
  }

  // ── Accept invite ──────────────────────────────────────────────────────────

  /// Accepts a pending invite code. Returns the owner's name on success.
  /// Throws a user-readable message on failure.
  Future<String?> acceptPartnership(String inviteCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in.');

    final query = await _db
        .collection('partnerships')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid or already-used invite code.');
    }

    final doc = query.docs.first;
    final data = doc.data();

    if (data['ownerUid'] == uid) {
      throw Exception("You can't join your own partnership.");
    }

    await doc.reference.update({
      'partnerUid': uid,
      'partnerName': _displayName ?? 'Your friend',
      'status': 'active',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    return data['ownerName'] as String?;
  }

  // ── List partnerships ──────────────────────────────────────────────────────

  /// Returns all active partnerships for the current user.
  /// Each map contains: partnershipId, partnerName, habitIds, habitTitles.
  Future<List<Map<String, dynamic>>> getPartnerships() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final owned = await _db
          .collection('partnerships')
          .where('ownerUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .get();

      final partnered = await _db
          .collection('partnerships')
          .where('partnerUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .get();

      final all = [...owned.docs, ...partnered.docs];
      return all.map((doc) {
        final d = doc.data();
        final isOwner = d['ownerUid'] == uid;
        return {
          'partnershipId': doc.id,
          'partnerName':
              (isOwner ? d['partnerName'] : d['ownerName']) as String? ??
                  'Partner',
          'habitIds': List<String>.from(d['habitIds'] ?? []),
          'habitTitles': List<String>.from(d['habitTitles'] ?? []),
        };
      }).toList();
    } catch (e) {
      print('⚠️ getPartnerships failed: $e');
      return [];
    }
  }

  // ── Nudge ──────────────────────────────────────────────────────────────────

  /// Writes a nudge document that the partner's app picks up in real-time.
  Future<bool> nudgePartner(String partnershipId, String habitTitle) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final doc =
          await _db.collection('partnerships').doc(partnershipId).get();
      if (!doc.exists) return false;
      final d = doc.data()!;
      final toUid =
          d['ownerUid'] == uid ? d['partnerUid'] : d['ownerUid'];
      if (toUid == null) return false;

      await _db.collection('nudges').add({
        'fromUid': uid,
        'fromName': _displayName ?? 'Your partner',
        'toUid': toUid,
        'partnershipId': partnershipId,
        'habitTitle': habitTitle,
        'seen': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('⚠️ nudgePartner failed: $e');
      return false;
    }
  }

  // ── Real-time nudge stream ─────────────────────────────────────────────────

  /// Stream of unseen nudges sent to the current user.
  Stream<List<Map<String, dynamic>>> watchNudges() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('nudges')
        .where('toUid', isEqualTo: uid)
        .where('seen', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList());
  }

  /// Marks a nudge as seen so it won't fire again.
  Future<void> markNudgeSeen(String nudgeId) async {
    try {
      await _db.collection('nudges').doc(nudgeId).update({'seen': true});
    } catch (_) {}
  }
}
