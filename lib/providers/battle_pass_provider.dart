// providers/battle_pass_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/battle_pass_model.dart';

class BattlePassProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BattlePassProgress? _progress;
  BattlePassSeason? _currentSeason;
  bool _isLoading = false;
  String? _error;

  BattlePassProgress? get progress => _progress;
  BattlePassSeason? get currentSeason => _currentSeason;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get currentLevel => _progress?.currentLevel ?? 1;
  int get currentXP => _progress?.currentXP ?? 0;
  bool get isPremiumUnlocked => _progress?.isPremiumUnlocked ?? false;

  /// Load user's battle pass progress
  Future<void> loadProgress(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load current season
      await _loadCurrentSeason();

      // Load user progress
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('battlePass')
          .doc('season_${_currentSeason?.season ?? 1}')
          .get();

      if (doc.exists) {
        _progress = BattlePassProgress.fromFirestore(doc);
      } else {
        // Create new progress for this season
        _progress = BattlePassProgress(
          userId: userId,
          season: _currentSeason?.season ?? 1,
          seasonStartDate: _currentSeason?.startDate ?? DateTime.now(),
          seasonEndDate: _currentSeason?.endDate ??
              DateTime.now().add(const Duration(days: 60)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveProgress(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fallback to demo data when Firestore is unavailable
      _loadDemoData(userId);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load demo battle pass data for preview
  void _loadDemoData(String userId) {
    _currentSeason = _generateQuarterlySeason();
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    final seasonStart = DateTime(now.year, ((quarter - 1) * 3) + 1, 1);
    final seasonEnd = DateTime(now.year, (quarter * 3) + 1, 1);

    _progress = BattlePassProgress(
      userId: userId,
      season: quarter,
      currentLevel: 4,
      currentXP: 320,
      totalXP: 1320,
      isPremiumUnlocked: false,
      claimedRewards: const [],
      seasonStartDate: seasonStart,
      seasonEndDate: seasonEnd,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Ensure demo data is loaded (call when no user is authenticated)
  void ensureDemoData() {
    if (_progress != null && _currentSeason != null) return;
    _loadDemoData('demo');
    notifyListeners();
  }

  /// Load current season configuration
  Future<void> _loadCurrentSeason() async {
    try {
      // Try to load active season from Firestore
      final snapshot = await _firestore
          .collection('seasons')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        _currentSeason = BattlePassSeason(
          season: data['season'] ?? 1,
          name: data['name'] ?? 'Season 1',
          theme: data['theme'] ?? 'fitness',
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(days: 60)),
          maxLevel: data['maxLevel'] ?? 10,
          rewards: BattlePassSeason.generateDefaultRewards(),
        );
      } else {
        _currentSeason = _generateQuarterlySeason();
      }
    } catch (e) {
      _currentSeason = _generateQuarterlySeason();
    }
  }

  /// Generate a quarterly season based on current date
  BattlePassSeason _generateQuarterlySeason() {
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1; // 1=Winter, 2=Spring, 3=Summer, 4=Fall
    final seasonStart = DateTime(now.year, ((quarter - 1) * 3) + 1, 1);
    final seasonEnd = DateTime(now.year, (quarter * 3) + 1, 1);

    return BattlePassSeason(
      season: quarter,
      name: _seasonName(quarter),
      theme: _seasonTheme(quarter),
      startDate: seasonStart,
      endDate: seasonEnd,
      maxLevel: 10,
      rewards: BattlePassSeason.generateDefaultRewards(),
    );
  }

  String _seasonName(int quarter) {
    switch (quarter) {
      case 1:
        return 'Winter Warriors';
      case 2:
        return 'Spring Sprint';
      case 3:
        return 'Summer Grind';
      case 4:
        return 'Fall Frenzy';
      default:
        return 'Season $quarter';
    }
  }

  String _seasonTheme(int quarter) {
    switch (quarter) {
      case 1:
        return 'winter';
      case 2:
        return 'spring';
      case 3:
        return 'summer';
      case 4:
        return 'fall';
      default:
        return 'fitness';
    }
  }

  /// Add XP to user's progress
  Future<bool> addXP(String userId, int xp, String source) async {
    if (_progress == null) return false;

    try {
      int newXP = _progress!.currentXP + xp;
      int newTotalXP = _progress!.totalXP + xp;
      int newLevel = _progress!.currentLevel;

      // Check for level ups
      while (newXP >= (100 + (newLevel * 50))) {
        newXP -= (100 + (newLevel * 50));
        newLevel++;
      }

      // Update local state
      _progress = BattlePassProgress(
        userId: userId,
        season: _progress!.season,
        currentLevel: newLevel,
        currentXP: newXP,
        totalXP: newTotalXP,
        isPremiumUnlocked: _progress!.isPremiumUnlocked,
        claimedRewards: _progress!.claimedRewards,
        seasonStartDate: _progress!.seasonStartDate,
        seasonEndDate: _progress!.seasonEndDate,
        createdAt: _progress!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _saveProgress(userId);

      final levelBefore = _progress!.currentLevel;

      // Record XP transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('xpHistory')
          .add({
        'amount': xp,
        'source': source,
        'levelBefore': levelBefore,
        'levelAfter': newLevel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user document with latest battle pass level
      await _firestore.collection('users').doc(userId).update({
        'battlePassLevel': newLevel,
        'currentXP': newXP,
        'totalXP': newTotalXP,
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Claim a reward at a specific level
  Future<bool> claimReward(String userId, int level, RewardTier tier) async {
    if (_progress == null || _currentSeason == null) return false;

    // Check if user has reached this level
    if (_progress!.currentLevel < level) {
      _error = 'You must reach level $level first';
      notifyListeners();
      return false;
    }

    // Check if premium tier requires premium pass
    if (tier == RewardTier.premium && !_progress!.isPremiumUnlocked) {
      _error = 'Premium pass required';
      notifyListeners();
      return false;
    }

    // Find the reward
    final reward = _currentSeason!.rewards.firstWhere(
      (r) => r.level == level && r.tier == tier,
      orElse: () => BattlePassReward(
        level: 0,
        tier: tier,
        type: RewardType.coins,
        name: '',
        description: '',
      ),
    );

    if (reward.level == 0) {
      _error = 'Reward not found';
      notifyListeners();
      return false;
    }

    // Check if already claimed
    if (_progress!.claimedRewards.any((r) => r.level == level && r.tier == tier)) {
      _error = 'Reward already claimed';
      notifyListeners();
      return false;
    }

    try {
      // Add to claimed rewards
      final updatedRewards = [..._progress!.claimedRewards, reward.copyWith(claimed: true)];

      _progress = BattlePassProgress(
        userId: userId,
        season: _progress!.season,
        currentLevel: _progress!.currentLevel,
        currentXP: _progress!.currentXP,
        totalXP: _progress!.totalXP,
        isPremiumUnlocked: _progress!.isPremiumUnlocked,
        claimedRewards: updatedRewards,
        seasonStartDate: _progress!.seasonStartDate,
        seasonEndDate: _progress!.seasonEndDate,
        createdAt: _progress!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _saveProgress(userId);

      // Apply reward to user account
      await _applyReward(userId, reward);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlock premium pass
  Future<bool> unlockPremium(String userId) async {
    if (_progress == null) return false;

    try {
      _progress = BattlePassProgress(
        userId: userId,
        season: _progress!.season,
        currentLevel: _progress!.currentLevel,
        currentXP: _progress!.currentXP,
        totalXP: _progress!.totalXP,
        isPremiumUnlocked: true,
        claimedRewards: _progress!.claimedRewards,
        seasonStartDate: _progress!.seasonStartDate,
        seasonEndDate: _progress!.seasonEndDate,
        createdAt: _progress!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _saveProgress(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get available rewards for current level
  List<BattlePassReward> getAvailableRewards() {
    if (_currentSeason == null || _progress == null) return [];

    return _currentSeason!.rewards
        .where((r) => r.level <= _progress!.currentLevel)
        .where((r) => !_progress!.claimedRewards.any(
            (claimed) => claimed.level == r.level && claimed.tier == r.tier))
        .toList();
  }

  /// Check if reward is claimed
  bool isRewardClaimed(int level, RewardTier tier) {
    if (_progress == null) return false;
    return _progress!.claimedRewards
        .any((r) => r.level == level && r.tier == tier);
  }

  Future<void> _saveProgress(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('battlePass')
        .doc('season_${_progress!.season}')
        .set(_progress!.toFirestore());
  }

  Future<void> _applyReward(String userId, BattlePassReward reward) async {
    final userRef = _firestore.collection('users').doc(userId);

    switch (reward.type) {
      case RewardType.coins:
        await userRef.update({
          'coins': FieldValue.increment(reward.value),
        });
        break;

      case RewardType.premium_days:
        // Extend premium subscription
        await userRef.update({
          'premiumExpiresAt': FieldValue.serverTimestamp(),
        });
        break;

      case RewardType.avatar:
      case RewardType.badge:
      case RewardType.unlock:
        // Add to user's unlocked items
        await userRef.update({
          'unlockedItems': FieldValue.arrayUnion([reward.name]),
        });
        break;

      case RewardType.product:
      case RewardType.giftcard:
        // Physical products / gift cards - record for fulfillment
        await userRef.collection('pendingRewards').add({
          'reward': reward.toMap(),
          'status': 'pending',
          'claimedAt': FieldValue.serverTimestamp(),
        });
        break;

      case RewardType.boost:
        // Add boost to user's inventory
        await userRef.update({
          'activeBoosts': FieldValue.arrayUnion([
            {
              'type': 'xp_boost',
              'multiplier': 2.0,
              'expiresAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(hours: 24)),
              ),
            }
          ]),
        });
        break;
    }

    // Record reward claim
    await userRef.collection('rewardHistory').add({
      'reward': reward.toMap(),
      'claimedAt': FieldValue.serverTimestamp(),
    });
  }
}
