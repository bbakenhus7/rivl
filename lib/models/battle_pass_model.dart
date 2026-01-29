// models/battle_pass_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardType { coins, premium_days, avatar, badge, boost, unlock }

enum RewardTier { free, premium }

/// Individual reward item at a specific tier level
class BattlePassReward {
  final int level;
  final RewardTier tier;
  final RewardType type;
  final String name;
  final String description;
  final String iconUrl;
  final int value; // Coins, days, etc.
  final bool claimed;

  BattlePassReward({
    required this.level,
    required this.tier,
    required this.type,
    required this.name,
    required this.description,
    this.iconUrl = '',
    this.value = 0,
    this.claimed = false,
  });

  factory BattlePassReward.fromMap(Map<String, dynamic> map) {
    return BattlePassReward(
      level: map['level'] ?? 0,
      tier: RewardTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => RewardTier.free,
      ),
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.coins,
      ),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      value: map['value'] ?? 0,
      claimed: map['claimed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'tier': tier.name,
      'type': type.name,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'value': value,
      'claimed': claimed,
    };
  }

  BattlePassReward copyWith({bool? claimed}) {
    return BattlePassReward(
      level: level,
      tier: tier,
      type: type,
      name: name,
      description: description,
      iconUrl: iconUrl,
      value: value,
      claimed: claimed ?? this.claimed,
    );
  }
}

/// User's battle pass progress
class BattlePassProgress {
  final String userId;
  final int season;
  final int currentLevel;
  final int currentXP;
  final int totalXP;
  final bool isPremiumUnlocked;
  final List<BattlePassReward> claimedRewards;
  final DateTime seasonStartDate;
  final DateTime seasonEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BattlePassProgress({
    required this.userId,
    required this.season,
    this.currentLevel = 1,
    this.currentXP = 0,
    this.totalXP = 0,
    this.isPremiumUnlocked = false,
    this.claimedRewards = const [],
    required this.seasonStartDate,
    required this.seasonEndDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // XP required to reach next level (increases exponentially)
  int get xpForNextLevel => 100 + (currentLevel * 50);

  // XP progress percentage for current level
  double get levelProgress => currentXP / xpForNextLevel;

  // Days remaining in season
  int get daysRemaining => seasonEndDate.difference(DateTime.now()).inDays;

  // Is season active
  bool get isActive => DateTime.now().isBefore(seasonEndDate) &&
                       DateTime.now().isAfter(seasonStartDate);

  factory BattlePassProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BattlePassProgress(
      userId: data['userId'] ?? '',
      season: data['season'] ?? 1,
      currentLevel: data['currentLevel'] ?? 1,
      currentXP: data['currentXP'] ?? 0,
      totalXP: data['totalXP'] ?? 0,
      isPremiumUnlocked: data['isPremiumUnlocked'] ?? false,
      claimedRewards: (data['claimedRewards'] as List<dynamic>?)
          ?.map((e) => BattlePassReward.fromMap(e))
          .toList() ?? [],
      seasonStartDate: (data['seasonStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seasonEndDate: (data['seasonEndDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 60)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'season': season,
      'currentLevel': currentLevel,
      'currentXP': currentXP,
      'totalXP': totalXP,
      'isPremiumUnlocked': isPremiumUnlocked,
      'claimedRewards': claimedRewards.map((r) => r.toMap()).toList(),
      'seasonStartDate': Timestamp.fromDate(seasonStartDate),
      'seasonEndDate': Timestamp.fromDate(seasonEndDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Battle Pass configuration for a season
class BattlePassSeason {
  final int season;
  final String name;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final int maxLevel;
  final List<BattlePassReward> rewards;

  BattlePassSeason({
    required this.season,
    required this.name,
    required this.theme,
    required this.startDate,
    required this.endDate,
    this.maxLevel = 100,
    this.rewards = const [],
  });

  /// Generate default rewards for a season
  static List<BattlePassReward> generateDefaultRewards() {
    final rewards = <BattlePassReward>[];

    for (int level = 1; level <= 100; level++) {
      // Free tier rewards every 5 levels
      if (level % 5 == 0) {
        rewards.add(BattlePassReward(
          level: level,
          tier: RewardTier.free,
          type: RewardType.coins,
          name: '${level * 10} Coins',
          description: 'Use for in-app purchases',
          value: level * 10,
        ));
      }

      // Premium tier rewards every level
      if (level % 10 == 0) {
        // Every 10 levels: premium avatar
        rewards.add(BattlePassReward(
          level: level,
          tier: RewardTier.premium,
          type: RewardType.avatar,
          name: 'Elite Avatar Frame',
          description: 'Exclusive avatar frame',
          value: 1,
        ));
      } else if (level % 5 == 0) {
        // Every 5 levels: badge
        rewards.add(BattlePassReward(
          level: level,
          tier: RewardTier.premium,
          type: RewardType.badge,
          name: 'Level $level Badge',
          description: 'Show off your achievement',
          value: 1,
        ));
      } else {
        // Other levels: coins or boosts
        rewards.add(BattlePassReward(
          level: level,
          tier: RewardTier.premium,
          type: level % 3 == 0 ? RewardType.boost : RewardType.coins,
          name: level % 3 == 0 ? 'XP Boost' : '${level * 20} Coins',
          description: level % 3 == 0 ? '2x XP for next challenge' : 'Premium currency',
          value: level % 3 == 0 ? 1 : level * 20,
        ));
      }
    }

    // Special rewards at milestones
    rewards.add(BattlePassReward(
      level: 25,
      tier: RewardTier.premium,
      type: RewardType.unlock,
      name: 'Custom Challenge Creator',
      description: 'Create custom challenge types',
      value: 1,
    ));

    rewards.add(BattlePassReward(
      level: 50,
      tier: RewardTier.premium,
      type: RewardType.premium_days,
      name: '7 Days Premium',
      description: 'Free premium subscription',
      value: 7,
    ));

    rewards.add(BattlePassReward(
      level: 100,
      tier: RewardTier.premium,
      type: RewardType.unlock,
      name: 'Legendary Status',
      description: 'Exclusive legendary badge and avatar',
      value: 1,
    ));

    return rewards;
  }
}

/// XP sources and amounts
class XPSource {
  static const int CHALLENGE_WIN = 100;
  static const int CHALLENGE_COMPLETE = 50;
  static const int CHALLENGE_PARTICIPATION = 25;
  static const int DAILY_LOGIN = 10;
  static const int STREAK_BONUS = 20; // Per streak day
  static const int REFERRAL = 75;
  static const int ACHIEVEMENT_UNLOCK = 50;
  static const int SPONSORED_CHALLENGE_WIN = 150;

  static int calculateChallengeXP({
    required bool won,
    required double stakeAmount,
    required int challengeDuration,
  }) {
    int baseXP = won ? CHALLENGE_WIN : CHALLENGE_PARTICIPATION;

    // Bonus for higher stakes
    if (stakeAmount >= 50) baseXP += 25;
    else if (stakeAmount >= 25) baseXP += 15;

    // Bonus for longer challenges
    if (challengeDuration >= 14) baseXP += 30;
    else if (challengeDuration >= 7) baseXP += 15;

    return baseXP;
  }
}
