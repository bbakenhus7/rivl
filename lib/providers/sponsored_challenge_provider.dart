// providers/sponsored_challenge_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sponsored_challenge_model.dart';

class SponsoredChallengeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SponsoredChallengeModel> _challenges = [];
  bool _isLoading = false;
  String? _error;

  List<SponsoredChallengeModel> get challenges => _challenges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SponsoredChallengeModel> get activeChallenge => _challenges
      .where((c) => c.isActive && c.canRegister)
      .toList();

  /// Load all sponsored challenges
  Future<void> loadChallenges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('sponsoredChallenges')
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .get();

      _challenges = snapshot.docs
          .map((doc) => SponsoredChallengeModel.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Join a sponsored challenge
  Future<bool> joinChallenge(String challengeId, String userId) async {
    try {
      final challengeRef = _firestore
          .collection('sponsoredChallenges')
          .doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(challengeRef);
        if (!doc.exists) throw Exception('Challenge not found');

        final challenge = SponsoredChallengeModel.fromFirestore(doc);
        if (!challenge.canRegister) {
          throw Exception('Challenge registration is closed');
        }

        transaction.update(challengeRef, {
          'currentParticipants': FieldValue.increment(1),
        });

        // Create participant record
        transaction.set(
          _firestore
              .collection('sponsoredChallenges')
              .doc(challengeId)
              .collection('participants')
              .doc(userId),
          {
            'userId': userId,
            'joinedAt': FieldValue.serverTimestamp(),
            'progress': 0,
            'status': 'active',
          },
        );
      });

      await loadChallenges();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Track view (analytics)
  Future<void> trackView(String challengeId) async {
    try {
      await _firestore
          .collection('sponsoredChallenges')
          .doc(challengeId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      // Silent fail for analytics
    }
  }
}
