// models/battle_pass_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardType { coins, premium_days, avatar, badge, boost, unlock, product, giftcard }

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

  /// Generate fitness-themed demo rewards for a season
  static List<BattlePassReward> generateDefaultRewards() {
    return [
      // Tier 1 - 100 XP
      BattlePassReward(level: 1, tier: RewardTier.free, type: RewardType.giftcard, name: '15% Off Gymshark', description: 'Discount on workout apparel', value: 15),
      BattlePassReward(level: 1, tier: RewardTier.premium, type: RewardType.badge, name: 'Premium Competitor Badge', description: 'Exclusive badge for premium members', value: 1),
      // Tier 2 - 250 XP
      BattlePassReward(level: 2, tier: RewardTier.free, type: RewardType.badge, name: 'Early Bird Badge', description: 'Season starter badge', value: 1),
      BattlePassReward(level: 2, tier: RewardTier.premium, type: RewardType.product, name: 'LMNT Electrolytes Sample', description: 'Free 8-pack sampler', value: 1),
      // Tier 3 - 500 XP
      BattlePassReward(level: 3, tier: RewardTier.free, type: RewardType.giftcard, name: '25% Off MyProtein', description: 'Discount on supplements & gear', value: 25),
      BattlePassReward(level: 3, tier: RewardTier.premium, type: RewardType.product, name: 'Blender Bottle', description: 'RIVL branded shaker', value: 1),
      // Tier 4 - 1,000 XP
      BattlePassReward(level: 4, tier: RewardTier.free, type: RewardType.avatar, name: 'Flame Avatar Frame', description: 'Animated fire border', value: 1),
      BattlePassReward(level: 4, tier: RewardTier.premium, type: RewardType.product, name: 'AG1 Starter Kit', description: '5-day Athletic Greens supply', value: 1),
      // Tier 5 - 1,750 XP
      BattlePassReward(level: 5, tier: RewardTier.free, type: RewardType.boost, name: '3x XP Weekend', description: 'Triple XP for 48hrs', value: 1),
      BattlePassReward(level: 5, tier: RewardTier.premium, type: RewardType.giftcard, name: '\$5 Nike Gift Card', description: 'Nike.com credit', value: 5),
      // Tier 6 - 2,500 XP
      BattlePassReward(level: 6, tier: RewardTier.free, type: RewardType.giftcard, name: '50% Off Hydro Flask', description: 'Half off bottles & gear', value: 50),
      BattlePassReward(level: 6, tier: RewardTier.premium, type: RewardType.product, name: 'Whey Protein Tub', description: 'Optimum Nutrition 2lb', value: 1),
      // Tier 7 - 3,500 XP
      BattlePassReward(level: 7, tier: RewardTier.free, type: RewardType.badge, name: 'Grinder Badge', description: 'Halfway warrior badge', value: 1),
      BattlePassReward(level: 7, tier: RewardTier.premium, type: RewardType.product, name: 'Liquid IV 16-Pack', description: 'Hydration multiplier', value: 1),
      // Tier 8 - 5,000 XP
      BattlePassReward(level: 8, tier: RewardTier.free, type: RewardType.premium_days, name: '3 Days Premium', description: 'Free premium trial', value: 3),
      BattlePassReward(level: 8, tier: RewardTier.premium, type: RewardType.giftcard, name: '\$10 Lululemon Gift Card', description: 'Lululemon.com credit', value: 10),
      // Tier 9 - 7,000 XP
      BattlePassReward(level: 9, tier: RewardTier.free, type: RewardType.giftcard, name: '75% Off Vuori', description: 'Premium activewear discount', value: 75),
      BattlePassReward(level: 9, tier: RewardTier.premium, type: RewardType.product, name: 'Theragun Mini', description: 'Percussion massage device', value: 1),
      // Tier 10 - 10,000 XP
      BattlePassReward(level: 10, tier: RewardTier.free, type: RewardType.unlock, name: 'Legendary Status', description: 'Season champion badge + frame', value: 1),
      BattlePassReward(level: 10, tier: RewardTier.premium, type: RewardType.giftcard, name: '\$25 Amazon Gift Card', description: 'Fitness gear shopping spree', value: 25),
    ];
  }

  /// XP thresholds for each tier level (cumulative)
  static const List<int> tierXPThresholds = [
    0,     // Tier 1: 0 XP (start)
    100,   // Tier 1: 100 XP
    250,   // Tier 2: 250 XP
    500,   // Tier 3: 500 XP
    1000,  // Tier 4: 1,000 XP
    1750,  // Tier 5: 1,750 XP
    2500,  // Tier 6: 2,500 XP
    3500,  // Tier 7: 3,500 XP
    5000,  // Tier 8: 5,000 XP
    7000,  // Tier 9: 7,000 XP
    10000, // Tier 10: 10,000 XP
  ];

  /// Get the XP needed for a specific tier level
  static int xpForTier(int tier) {
    if (tier < 1 || tier > 10) return 0;
    return tierXPThresholds[tier];
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
