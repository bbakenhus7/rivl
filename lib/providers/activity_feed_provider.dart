// providers/activity_feed_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_feed_model.dart';
import 'dart:async';

class ActivityFeedProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ActivityFeedItem> _feedItems = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _feedSubscription;

  List<ActivityFeedItem> get feedItems => _feedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start listening to global activity feed
  void startListening() {
    _isLoading = true;
    notifyListeners();

    _feedSubscription?.cancel();
    _feedSubscription = _firestore
        .collection('activityFeed')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _feedItems = snapshot.docs
          .map((doc) => ActivityFeedItem.fromFirestore(doc))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Post a new activity to the feed
  Future<void> postActivity({
    required String userId,
    required String username,
    required String displayName,
    required ActivityType type,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final item = ActivityFeedItem(
        id: '',
        userId: userId,
        username: username,
        displayName: displayName,
        type: type,
        message: message,
        data: data ?? {},
        createdAt: DateTime.now(),
      );

      await _firestore.collection('activityFeed').add(item.toFirestore());
    } catch (e) {
      debugPrint('Post activity error: $e');
    }
  }

  /// Post challenge won activity
  Future<void> postChallengeWon({
    required String userId,
    required String username,
    required String displayName,
    required String challengeId,
    required String opponentName,
    required double amount,
  }) async {
    await postActivity(
      userId: userId,
      username: username,
      displayName: displayName,
      type: ActivityType.challengeWon,
      message: '$displayName won \$${amount.toStringAsFixed(0)} against $opponentName',
      data: {
        'challengeId': challengeId,
        'opponentName': opponentName,
        'amount': amount,
      },
    );
  }

  /// Post challenge accepted activity
  Future<void> postChallengeAccepted({
    required String userId,
    required String username,
    required String displayName,
    required String opponentName,
    required double stakeAmount,
  }) async {
    await postActivity(
      userId: userId,
      username: username,
      displayName: displayName,
      type: ActivityType.challengeAccepted,
      message: '$displayName accepted a \$${stakeAmount.toStringAsFixed(0)} challenge from $opponentName',
      data: {
        'opponentName': opponentName,
        'amount': stakeAmount,
      },
    );
  }

  /// Post streak milestone
  Future<void> postStreakMilestone({
    required String userId,
    required String username,
    required String displayName,
    required int streakDays,
  }) async {
    await postActivity(
      userId: userId,
      username: username,
      displayName: displayName,
      type: ActivityType.streakMilestone,
      message: '$displayName hit a $streakDays-day streak!',
      data: {'streakDays': streakDays},
    );
  }

  /// Post level up
  Future<void> postLevelUp({
    required String userId,
    required String username,
    required String displayName,
    required int level,
  }) async {
    await postActivity(
      userId: userId,
      username: username,
      displayName: displayName,
      type: ActivityType.levelUp,
      message: '$displayName reached Level $level!',
      data: {'level': level},
    );
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }
}
