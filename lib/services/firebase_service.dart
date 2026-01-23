// services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';
import 'dart:math';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================
  // AUTHENTICATION
  // ============================================

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String displayName,
    String username, {
    String? referralCode,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user profile
    final user = UserModel(
      id: credential.user!.uid,
      email: email,
      displayName: displayName,
      username: username.toLowerCase(),
      referralCode: _generateReferralCode(),
      referredBy: referralCode?.toUpperCase(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    await _db.collection('users').doc(credential.user!.uid).set(user.toFirestore());

    // Credit referrer if applicable
    if (referralCode != null && referralCode.isNotEmpty) {
      await _creditReferral(referralCode.toUpperCase(), credential.user!.uid);
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ============================================
  // USER MANAGEMENT
  // ============================================

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).update(data);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // ============================================
  // CHALLENGES
  // ============================================

  Future<String> createChallenge({
    required String opponentId,
    required String opponentName,
    required ChallengeType type,
    required GoalType goalType,
    required int goalValue,
    required ChallengeDuration duration,
    required double stakeAmount,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    final totalPot = stakeAmount * 2;
    final prizeAmount = _calculatePrize(totalPot);

    final challenge = ChallengeModel(
      id: '',
      creatorId: currentUser!.uid,
      opponentId: opponentId,
      creatorName: user.displayName,
      opponentName: opponentName,
      type: type,
      status: ChallengeStatus.pending,
      stakeAmount: stakeAmount,
      totalPot: totalPot,
      prizeAmount: prizeAmount,
      goalType: goalType,
      goalValue: goalValue,
      duration: duration,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _db.collection('challenges').add(challenge.toFirestore());

    // Send notification to opponent
    await _sendNotification(
      userId: opponentId,
      type: 'challenge_invite',
      title: 'New Challenge!',
      body: '${user.displayName} challenged you!',
      data: {'challengeId': docRef.id},
    );

    return docRef.id;
  }

  Stream<List<ChallengeModel>> userChallengesStream(String userId) {
    return _db
        .collection('challenges')
        .where(Filter.or(
          Filter('creatorId', isEqualTo: userId),
          Filter('opponentId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
    });
  }

  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final doc = await _db.collection('challenges').doc(challengeId).get();
    if (!doc.exists) return null;
    return ChallengeModel.fromFirestore(doc);
  }

  Stream<ChallengeModel?> challengeStream(String challengeId) {
    return _db.collection('challenges').doc(challengeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChallengeModel.fromFirestore(doc);
    });
  }

  Future<void> acceptChallenge(String challengeId) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null) throw Exception('Challenge not found');

    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: challenge.duration.days));

    await _db.collection('challenges').doc(challengeId).update({
      'status': ChallengeStatus.active.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify creator
    await _sendNotification(
      userId: challenge.creatorId,
      type: 'challenge_accepted',
      title: 'Challenge Accepted!',
      body: '${challenge.opponentName} accepted your challenge!',
      data: {'challengeId': challengeId},
    );
  }

  Future<void> declineChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': ChallengeStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncSteps({
    required String challengeId,
    required int steps,
    required List<DailySteps> stepHistory,
  }) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null) throw Exception('Challenge not found');

    final isCreator = challenge.creatorId == currentUser!.uid;
    final progressField = isCreator ? 'creatorProgress' : 'opponentProgress';
    final historyField = isCreator ? 'creatorStepHistory' : 'opponentStepHistory';

    await _db.collection('challenges').doc(challengeId).update({
      progressField: steps,
      historyField: stepHistory.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // LEADERBOARD
  // ============================================

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    final snapshot = await _db
        .collection('users')
        .where('accountStatus', isEqualTo: 'active')
        .orderBy('wins', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.asMap().entries.map((entry) {
      final user = UserModel.fromFirestore(entry.value);
      return {
        'rank': entry.key + 1,
        'userId': user.id,
        'displayName': user.displayName,
        'username': user.username,
        'wins': user.wins,
        'profileImageUrl': user.profileImageUrl,
      };
    }).toList();
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<void> _sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> notificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  // ============================================
  // REFERRALS
  // ============================================

  Future<void> _creditReferral(String code, String newUserId) async {
    final snapshot = await _db
        .collection('users')
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({
      'referralCount': FieldValue.increment(1),
      'referralEarnings': FieldValue.increment(2.0),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // HELPERS
  // ============================================

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  double _calculatePrize(double totalPot) {
    // ~15% fee
    return (totalPot * 0.85).roundToDouble();
  }

  // ============================================
  // USER STATS
  // ============================================

  Future<dynamic> getUserStats(String userId) async {
    final doc = await _db.collection('user_stats').doc(userId).get();
    if (!doc.exists) {
      // Return mock stats for now
      return _createMockStats(userId);
    }
    return doc;
  }

  dynamic _createMockStats(String userId) {
    return {
      'userId': userId,
      'totalChallenges': 0,
      'wins': 0,
      'losses': 0,
      'activeChallenges': 0,
      'totalEarnings': 0.0,
      'totalSpent': 0.0,
      'currentBalance': 0.0,
      'currentStreak': 0,
      'longestStreak': 0,
      'achievementIds': [],
      'lastActiveAt': DateTime.now(),
      'createdAt': DateTime.now(),
    };
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Future<List<dynamic>> getUserTransactions(String userId) async {
    final snapshot = await _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs;
  }

  // ============================================
  // FRIENDS
  // ============================================

  Future<void> sendFriendRequest(String friendId) async {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return;

    await _db.collection('friends').add({
      'userId': currentUserId,
      'friendId': friendId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> friendsStream(String userId) {
    return _db
        .collection('friends')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
