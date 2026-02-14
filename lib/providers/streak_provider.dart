// providers/streak_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';

class StreakProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Callback invoked when user hits a streak milestone (7, 14, 30, etc.)
  void Function(int streakDays)? onStreakMilestone;

  StreakModel? _streak;
  bool _isLoading = false;
  bool _isClaiming = false;
  String? _error;
  bool _showRewardPopup = false;
  LoginReward? _lastReward;

  StreakModel? get streak => _streak;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showRewardPopup => _showRewardPopup;
  LoginReward? get lastReward => _lastReward;

  int get currentStreak => _streak?.currentStreak ?? 0;
  int get longestStreak => _streak?.longestStreak ?? 0;
  bool get canClaimToday => _streak?.canClaimToday ?? false;
  double get streakMultiplier => _streak?.streakMultiplier ?? 1.0;
  String get streakMultiplierLabel => _streak?.streakMultiplierLabel ?? '';
  int get nextRewardCoins => _streak?.nextRewardCoins ?? 10;

  /// Load streak data and auto-check login
  Future<void> loadStreak(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('streak')
          .doc('current')
          .get();

      if (doc.exists) {
        _streak = StreakModel.fromFirestore(doc);
      } else {
        _streak = StreakModel.fresh(userId);
        await _saveStreak(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Claim daily login reward
  Future<bool> claimDailyReward(String userId) async {
    if (_streak == null || !_streak!.canClaimToday) return false;
    if (_isClaiming) return false; // Guard against double-claim

    _isClaiming = true;

    try {
      final wasAlive = _streak!.isStreakAlive;
      final newStreak = wasAlive ? _streak!.currentStreak + 1 : 1;
      final coins = LoginReward.coinsForDay(newStreak);
      final xp = LoginReward.xpForDay(newStreak);

      // Add milestone bonus
      int totalCoins = coins;
      if (LoginReward.isMilestone(newStreak)) {
        totalCoins += LoginReward.milestoneBonus(newStreak);
      }

      final reward = LoginReward(
        day: newStreak,
        coins: totalCoins,
        xp: xp,
        claimedAt: DateTime.now(),
      );

      // Keep last 7 rewards in history
      final rewardHistory = [..._streak!.rewardHistory, reward];
      if (rewardHistory.length > 7) {
        rewardHistory.removeRange(0, rewardHistory.length - 7);
      }

      final newLongest =
          newStreak > _streak!.longestStreak ? newStreak : _streak!.longestStreak;

      _streak = StreakModel(
        userId: userId,
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastLoginDate: DateTime.now(),
        totalLogins: _streak!.totalLogins + 1,
        totalCoinsEarned: _streak!.totalCoinsEarned + totalCoins,
        rewardHistory: rewardHistory,
      );

      await _saveStreak(userId);

      // Credit coins to user
      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(totalCoins),
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // Post streak milestone to activity feed (7, 14, 30, 60, 100, ...)
      if (LoginReward.isMilestone(newStreak)) {
        onStreakMilestone?.call(newStreak);
      }

      // Show reward popup
      _lastReward = reward;
      _showRewardPopup = true;
      _isClaiming = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isClaiming = false;
      notifyListeners();
      return false;
    }
  }

  void dismissRewardPopup() {
    _showRewardPopup = false;
    notifyListeners();
  }

  Future<void> _saveStreak(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('streak')
        .doc('current')
        .set(_streak!.toFirestore());
  }
}
