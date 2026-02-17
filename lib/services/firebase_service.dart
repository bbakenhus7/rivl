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

  /// Create a Firestore user profile after social sign-in (Apple / Google).
  Future<void> createSocialUser({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final username = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    var finalUsername = username.isEmpty ? 'user_${uid.substring(0, 6)}' : username;
    final isAvailable = await isUsernameAvailable(finalUsername);
    if (!isAvailable) {
      finalUsername = '${finalUsername}_${Random().nextInt(9999)}';
    }

    final user = UserModel(
      id: uid,
      email: email,
      displayName: displayName,
      username: finalUsername,
      referralCode: _generateReferralCode(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(user.toFirestore());
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
    bool isFriendChallenge = false,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    final totalPot = stakeAmount * 2;
    final prizeAmount = _calculatePrize(totalPot, type, isFriendChallenge: isFriendChallenge);
    final now = DateTime.now();

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
      expiresAt: now.add(const Duration(days: 7)),
      createdAt: now,
      updatedAt: now,
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

  Future<String> createGroupChallenge({
    required List<GroupParticipant> invitedParticipants,
    required GoalType goalType,
    required int goalValue,
    required ChallengeDuration duration,
    required double stakeAmount,
    required int maxParticipants,
    required int minParticipants,
    required GroupPayoutStructure payoutStructure,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    // Creator is automatically accepted
    final allParticipants = [
      GroupParticipant(
        userId: currentUser!.uid,
        displayName: user.displayName,
        username: user.username,
        status: ParticipantStatus.accepted,
      ),
      ...invitedParticipants,
    ];

    final totalPot = stakeAmount * allParticipants.length;
    final prizeAmount = _calculatePrize(totalPot, ChallengeType.group);
    final now = DateTime.now();

    final challenge = ChallengeModel(
      id: '',
      creatorId: currentUser!.uid,
      creatorName: user.displayName,
      type: ChallengeType.group,
      status: ChallengeStatus.pending,
      stakeAmount: stakeAmount,
      totalPot: totalPot,
      prizeAmount: prizeAmount,
      goalType: goalType,
      goalValue: goalValue,
      duration: duration,
      participants: allParticipants,
      participantIds: allParticipants.map((p) => p.userId).toList(),
      maxParticipants: maxParticipants,
      minParticipants: minParticipants,
      payoutStructure: payoutStructure,
      expiresAt: now.add(const Duration(days: 7)),
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _db.collection('challenges').add(challenge.toFirestore());

    // Notify all invited participants
    for (final participant in invitedParticipants) {
      await _sendNotification(
        userId: participant.userId,
        type: 'challenge_invite',
        title: 'Group Challenge!',
        body: '${user.displayName} invited you to a group challenge!',
        data: {'challengeId': docRef.id},
      );
    }

    return docRef.id;
  }

  /// Create group challenge and deduct creator's stake atomically.
  /// Returns the new challenge document ID.
  Future<String> createGroupChallengeWithStake({
    required List<GroupParticipant> invitedParticipants,
    required GoalType goalType,
    required int goalValue,
    required ChallengeDuration duration,
    required double stakeAmount,
    required int maxParticipants,
    required int minParticipants,
    required GroupPayoutStructure payoutStructure,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    final allParticipants = [
      GroupParticipant(
        userId: currentUser!.uid,
        displayName: user.displayName,
        username: user.username,
        status: ParticipantStatus.accepted,
      ),
      ...invitedParticipants,
    ];

    final totalPot = stakeAmount * allParticipants.length;
    final prizeAmount = _calculatePrize(totalPot, ChallengeType.group);
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final challengeData = ChallengeModel(
      id: '',
      creatorId: currentUser!.uid,
      creatorName: user.displayName,
      type: ChallengeType.group,
      status: ChallengeStatus.pending,
      stakeAmount: stakeAmount,
      totalPot: totalPot,
      prizeAmount: prizeAmount,
      goalType: goalType,
      goalValue: goalValue,
      duration: duration,
      participants: allParticipants,
      participantIds: allParticipants.map((p) => p.userId).toList(),
      maxParticipants: maxParticipants,
      minParticipants: minParticipants,
      payoutStructure: payoutStructure,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    ).toFirestore();

    // For free group challenges, no transaction needed
    if (stakeAmount <= 0) {
      final docRef = await _db.collection('challenges').add(challengeData);
      for (final participant in invitedParticipants) {
        await _sendNotification(
          userId: participant.userId,
          type: 'challenge_invite',
          title: 'Group Challenge!',
          body: '${user.displayName} invited you to a group challenge!',
          data: {'challengeId': docRef.id},
        );
      }
      return docRef.id;
    }

    // Paid group challenge: atomic create + deduct
    final newChallengeRef = _db.collection('challenges').doc();

    await _db.runTransaction((txn) async {
      final walletRef = _db.collection('wallets').doc(currentUser!.uid);
      final walletDoc = await txn.get(walletRef);

      if (!walletDoc.exists) throw Exception('Wallet not found');

      final balance = (walletDoc.data()?['balance'] ?? 0).toDouble();
      if (balance < stakeAmount) {
        throw Exception('Insufficient balance');
      }

      // Create the group challenge
      txn.set(newChallengeRef, challengeData);

      // Deduct creator's stake
      txn.update(walletRef, {
        'balance': balance - stakeAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record wallet transaction
      final walletTxRef = walletRef.collection('transactions').doc();
      txn.set(walletTxRef, {
        'userId': currentUser!.uid,
        'type': 'stakeDebit',
        'status': 'completed',
        'amount': stakeAmount,
        'fee': 0.0,
        'netAmount': stakeAmount,
        'challengeId': newChallengeRef.id,
        'description': 'Group challenge entry fee',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    });

    // Send notifications outside transaction
    for (final participant in invitedParticipants) {
      await _sendNotification(
        userId: participant.userId,
        type: 'challenge_invite',
        title: 'Group Challenge!',
        body: '${user.displayName} invited you to a group challenge!',
        data: {'challengeId': newChallengeRef.id},
      );
    }

    return newChallengeRef.id;
  }

  /// Create a team vs team challenge with optional stake.
  /// teamAMembers: members of the creator's team (creator is auto-added).
  /// teamBMembers: members of the opposing team.
  Future<String> createTeamChallengeWithStake({
    required String teamAName,
    required String? teamALabel,
    required List<GroupParticipant> teamAMembers,
    required String teamBName,
    required String? teamBLabel,
    required List<GroupParticipant> teamBMembers,
    required GoalType goalType,
    required int goalValue,
    required ChallengeDuration duration,
    required double stakeAmount,
    required int teamSize,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    // Creator is always the first member of Team A
    final creatorParticipant = GroupParticipant(
      userId: currentUser!.uid,
      displayName: user.displayName,
      username: user.username,
      status: ParticipantStatus.accepted,
    );

    final allTeamAMembers = [creatorParticipant, ...teamAMembers];
    final teamA = ChallengeTeam(
      name: teamAName,
      label: teamALabel,
      members: allTeamAMembers,
    );
    final teamB = ChallengeTeam(
      name: teamBName,
      label: teamBLabel,
      members: teamBMembers,
    );

    final allParticipantIds = [
      ...allTeamAMembers.map((m) => m.userId),
      ...teamBMembers.map((m) => m.userId),
    ];

    final totalParticipants = allTeamAMembers.length + teamBMembers.length;
    final totalPot = stakeAmount * totalParticipants;
    final prizeAmount = _calculatePrize(totalPot, ChallengeType.teamVsTeam);
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final challengeData = ChallengeModel(
      id: '',
      creatorId: currentUser!.uid,
      creatorName: user.displayName,
      type: ChallengeType.teamVsTeam,
      status: ChallengeStatus.pending,
      stakeAmount: stakeAmount,
      totalPot: totalPot,
      prizeAmount: prizeAmount,
      goalType: goalType,
      goalValue: goalValue,
      duration: duration,
      participantIds: allParticipantIds,
      teamA: teamA,
      teamB: teamB,
      teamSize: teamSize,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    ).toFirestore();

    // For free challenges, no transaction needed
    if (stakeAmount <= 0) {
      final docRef = await _db.collection('challenges').add(challengeData);
      // Notify all invited members
      for (final member in [...teamAMembers, ...teamBMembers]) {
        await _sendNotification(
          userId: member.userId,
          type: 'challenge_invite',
          title: 'Squad Challenge!',
          body: '${user.displayName} invited you to $teamAName vs $teamBName!',
          data: {'challengeId': docRef.id},
        );
      }
      return docRef.id;
    }

    // Paid team challenge: atomic create + deduct creator's stake
    final newChallengeRef = _db.collection('challenges').doc();

    await _db.runTransaction((txn) async {
      final walletRef = _db.collection('wallets').doc(currentUser!.uid);
      final walletDoc = await txn.get(walletRef);

      if (!walletDoc.exists) throw Exception('Wallet not found');

      final balance = (walletDoc.data()?['balance'] ?? 0).toDouble();
      if (balance < stakeAmount) {
        throw Exception('Insufficient balance');
      }

      txn.set(newChallengeRef, challengeData);

      txn.update(walletRef, {
        'balance': balance - stakeAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final walletTxRef = walletRef.collection('transactions').doc();
      txn.set(walletTxRef, {
        'userId': currentUser!.uid,
        'type': 'stakeDebit',
        'status': 'completed',
        'amount': stakeAmount,
        'fee': 0.0,
        'netAmount': stakeAmount,
        'challengeId': newChallengeRef.id,
        'description': 'Team challenge entry fee',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    });

    // Send notifications outside transaction
    for (final member in [...teamAMembers, ...teamBMembers]) {
      await _sendNotification(
        userId: member.userId,
        type: 'challenge_invite',
        title: 'Squad Challenge!',
        body: '${user.displayName} invited you to $teamAName vs $teamBName!',
        data: {'challengeId': newChallengeRef.id},
      );
    }

    return newChallengeRef.id;
  }

  Stream<List<ChallengeModel>> userChallengesStream(String userId) {
    // All challenges where user is creator, opponent, or group participant
    return _db
        .collection('challenges')
        .where(Filter.or(
          Filter('creatorId', isEqualTo: userId),
          Filter('opponentId', isEqualTo: userId),
          Filter('participantIds', arrayContains: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList());
  }

  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final doc = await _db.collection('challenges').doc(challengeId).get();
    if (!doc.exists) return null;
    return ChallengeModel.fromFirestore(doc);
  }

  /// Update arbitrary fields on a challenge document.
  Future<void> updateChallenge(
      String challengeId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('challenges').doc(challengeId).update(data);
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

    // Prevent creator from accepting their own challenge
    if (challenge.creatorId == currentUser?.uid) {
      throw Exception('Cannot accept your own challenge');
    }

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

  /// Accept challenge and deduct stake atomically.
  /// Returns true if succeeded, false if insufficient balance.
  Future<bool> acceptChallengeWithStake({
    required String challengeId,
    required String userId,
    required double stakeAmount,
  }) async {
    return await _db.runTransaction<bool>((txn) async {
      // 1. Read challenge
      final challengeRef = _db.collection('challenges').doc(challengeId);
      final challengeDoc = await txn.get(challengeRef);
      if (!challengeDoc.exists) throw Exception('Challenge not found');

      final challengeData = challengeDoc.data();
      final status = challengeData?['status'];
      if (status != ChallengeStatus.pending.name) {
        throw Exception('Challenge is no longer available');
      }

      // Prevent creator from accepting their own challenge
      final creatorId = challengeData?['creatorId'];
      if (creatorId == userId) {
        throw Exception('Cannot accept your own challenge');
      }

      // 2. Read wallet & verify balance
      if (stakeAmount > 0) {
        final walletRef = _db.collection('wallets').doc(userId);
        final walletDoc = await txn.get(walletRef);
        if (!walletDoc.exists) throw Exception('Wallet not found');

        final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
        if (currentBalance < stakeAmount) return false;

        // Deduct stake (held funds, not a loss)
        txn.update(walletRef, {
          'balance': currentBalance - stakeAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Record transaction
        final txRef = walletRef.collection('transactions').doc();
        txn.set(txRef, {
          'userId': userId,
          'type': 'stakeDebit',
          'status': 'completed',
          'amount': stakeAmount,
          'fee': 0.0,
          'netAmount': stakeAmount,
          'challengeId': challengeId,
          'description': 'Challenge entry fee',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Accept the challenge
      final durationName = challengeDoc.data()?['duration'] ?? 'oneWeek';
      final duration = ChallengeDuration.values.firstWhere(
        (e) => e.name == durationName,
        orElse: () => ChallengeDuration.oneWeek,
      );
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: duration.days));

      txn.update(challengeRef, {
        'status': ChallengeStatus.active.name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  /// Create challenge and deduct stake atomically.
  /// Returns the new challenge document ID.
  Future<String> createChallengeWithStake({
    required String opponentId,
    required String opponentName,
    required ChallengeType type,
    required GoalType goalType,
    required int goalValue,
    required ChallengeDuration duration,
    required double stakeAmount,
    bool isFriendChallenge = false,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    final totalPot = stakeAmount * 2;
    final prizeAmount = _calculatePrize(totalPot, type, isFriendChallenge: isFriendChallenge);
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final challengeData = {
      'creatorId': currentUser!.uid,
      'opponentId': opponentId,
      'participantIds': [currentUser!.uid, opponentId],
      'creatorName': user.displayName,
      'opponentName': opponentName,
      'type': type.name,
      'status': ChallengeStatus.pending.name,
      'stakeAmount': stakeAmount,
      'totalPot': totalPot,
      'prizeAmount': prizeAmount,
      'goalType': goalType.name,
      'goalValue': goalValue,
      'duration': duration.name,
      'creatorProgress': 0,
      'opponentProgress': 0,
      'creatorStepHistory': [],
      'opponentStepHistory': [],
      'isFriendChallenge': isFriendChallenge,
      'creatorAntiCheatScore': 1.0,
      'opponentAntiCheatScore': 1.0,
      'flagged': false,
      'creatorPaymentStatus': PaymentStatus.pending.name,
      'opponentPaymentStatus': PaymentStatus.pending.name,
      'rewardStatus': RewardStatus.pending.name,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // For free challenges, no transaction needed
    if (stakeAmount <= 0) {
      final docRef = await _db.collection('challenges').add(challengeData);
      await _sendNotification(
        userId: opponentId,
        type: 'challenge_invite',
        title: 'New Challenge!',
        body: '${user.displayName} challenged you!',
        data: {'challengeId': docRef.id},
      );
      return docRef.id;
    }

    // Paid challenge: atomic create + deduct
    final newChallengeRef = _db.collection('challenges').doc();

    await _db.runTransaction((txn) async {
      final walletRef = _db.collection('wallets').doc(currentUser!.uid);
      final walletDoc = await txn.get(walletRef);

      if (!walletDoc.exists) throw Exception('Wallet not found');

      final balance = (walletDoc.data()?['balance'] ?? 0).toDouble();
      if (balance < stakeAmount) {
        throw Exception('Insufficient balance');
      }

      // Create the challenge
      txn.set(newChallengeRef, challengeData);

      // Deduct stake (held funds, not a loss)
      txn.update(walletRef, {
        'balance': balance - stakeAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record wallet transaction
      final walletTxRef = walletRef.collection('transactions').doc();
      txn.set(walletTxRef, {
        'userId': currentUser!.uid,
        'type': 'stakeDebit',
        'status': 'completed',
        'amount': stakeAmount,
        'fee': 0.0,
        'netAmount': stakeAmount,
        'challengeId': newChallengeRef.id,
        'description': 'Challenge entry fee',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    });

    // Send notification outside transaction
    await _sendNotification(
      userId: opponentId,
      type: 'challenge_invite',
      title: 'New Challenge!',
      body: '${user.displayName} challenged you!',
      data: {'challengeId': newChallengeRef.id},
    );

    return newChallengeRef.id;
  }

  /// Decline challenge and refund creator's stake atomically if paid.
  Future<void> declineChallenge(String challengeId) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null) throw Exception('Challenge not found');

    if (challenge.stakeAmount > 0) {
      // Atomic decline + refund
      await _db.runTransaction((txn) async {
        final challengeRef = _db.collection('challenges').doc(challengeId);
        txn.update(challengeRef, {
          'status': ChallengeStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Refund the creator's stake
        final walletRef = _db.collection('wallets').doc(challenge.creatorId);
        final walletDoc = await txn.get(walletRef);
        if (walletDoc.exists) {
          final currentBalance =
              (walletDoc.data()?['balance'] ?? 0).toDouble();
          txn.update(walletRef, {
            'balance': currentBalance + challenge.stakeAmount,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Record refund transaction
          final txRef = walletRef.collection('transactions').doc();
          txn.set(txRef, {
            'userId': challenge.creatorId,
            'type': 'refund',
            'status': 'completed',
            'amount': challenge.stakeAmount,
            'fee': 0.0,
            'netAmount': challenge.stakeAmount,
            'challengeId': challengeId,
            'description': 'Challenge declined - refund',
            'createdAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } else {
      await _db.collection('challenges').doc(challengeId).update({
        'status': ChallengeStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Notify the creator that their challenge was declined
    await _sendNotification(
      userId: challenge.creatorId,
      type: 'challenge_declined',
      title: 'Challenge Declined',
      body: '${challenge.opponentName ?? 'Your opponent'} declined your challenge',
      data: {'challengeId': challengeId},
    );
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
  // FRIENDS
  // ============================================

  /// Send a friend request to another user.
  Future<String> sendFriendRequest({
    required String receiverId,
    required String receiverName,
    required String receiverUsername,
  }) async {
    final user = await getUser(currentUser!.uid);
    if (user == null) throw Exception('User not found');

    // Check if already friends
    final existingFriend = await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .doc(receiverId)
        .get();
    if (existingFriend.exists) throw Exception('Already friends');

    // Check for existing pending request in either direction
    final existing = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUser!.uid)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) throw Exception('Request already sent');

    final docRef = await _db.collection('friendRequests').add({
      'senderId': currentUser!.uid,
      'senderName': user.displayName,
      'senderUsername': user.username,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify receiver
    await _sendNotification(
      userId: receiverId,
      type: 'friend_request',
      title: 'Friend Request',
      body: '${user.displayName} wants to be your friend!',
      data: {'friendRequestId': docRef.id},
    );

    return docRef.id;
  }

  /// Accept a friend request. Adds both users to each other's friends subcollection.
  Future<void> acceptFriendRequest(String requestId) async {
    final requestDoc = await _db.collection('friendRequests').doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Request not found');

    final data = requestDoc.data()!;
    if (data['receiverId'] != currentUser!.uid) {
      throw Exception('Not authorized');
    }

    final senderId = data['senderId'] as String;
    final senderName = data['senderName'] as String;
    final senderUsername = data['senderUsername'] as String;
    final receiverName = data['receiverName'] as String;
    final receiverUsername = data['receiverUsername'] as String;

    final batch = _db.batch();

    // Update request status
    batch.update(requestDoc.reference, {'status': 'accepted'});

    // Add to sender's friends
    batch.set(
      _db.collection('users').doc(senderId).collection('friends').doc(currentUser!.uid),
      {
        'userId': currentUser!.uid,
        'displayName': receiverName,
        'username': receiverUsername,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    // Add to receiver's friends
    batch.set(
      _db.collection('users').doc(currentUser!.uid).collection('friends').doc(senderId),
      {
        'userId': senderId,
        'displayName': senderName,
        'username': senderUsername,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    // Notify sender
    await _sendNotification(
      userId: senderId,
      type: 'friend_request_accepted',
      title: 'Friend Request Accepted',
      body: '$receiverName accepted your friend request!',
    );
  }

  /// Decline a friend request.
  Future<void> declineFriendRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).update({
      'status': 'declined',
    });
  }

  /// Remove a friend (mutual removal).
  Future<void> removeFriend(String friendId) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(currentUser!.uid).collection('friends').doc(friendId),
    );
    batch.delete(
      _db.collection('users').doc(friendId).collection('friends').doc(currentUser!.uid),
    );
    await batch.commit();
  }

  /// Check if a user is a friend.
  Future<bool> isFriend(String userId) async {
    final doc = await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .doc(userId)
        .get();
    return doc.exists;
  }

  /// Stream of current user's friends.
  Stream<List<Map<String, dynamic>>> friendsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Stream of pending friend requests received by the current user.
  Stream<List<Map<String, dynamic>>> pendingFriendRequestsStream(String userId) {
    return _db
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Get the set of friend user IDs for the current user (one-shot).
  Future<Set<String>> getFriendIds() async {
    final snapshot = await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
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

  double _calculatePrize(double totalPot, ChallengeType type, {bool isFriendChallenge = false}) {
    // No fee for 1v1 friend challenges
    if (type == ChallengeType.headToHead && isFriendChallenge) {
      return totalPot;
    }
    // AI Anti-Cheat Algorithm Referee fee: 3% for 1v1, 5% for groups/teams
    final feeRate = type == ChallengeType.headToHead ? 0.03 : 0.05;
    return (totalPot * (1 - feeRate) * 100).roundToDouble() / 100;
  }

  double getPlatformFee(double totalPot, ChallengeType type, {bool isFriendChallenge = false}) {
    if (type == ChallengeType.headToHead && isFriendChallenge) {
      return 0;
    }
    final feeRate = type == ChallengeType.headToHead ? 0.03 : 0.05;
    return (totalPot * feeRate * 100).roundToDouble() / 100;
  }
}
