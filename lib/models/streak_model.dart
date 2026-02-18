// models/streak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StreakModel {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastLoginDate;
  final int totalLogins;
  final int totalCoinsEarned;
  final List<LoginReward> rewardHistory;

  StreakModel({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastLoginDate,
    this.totalLogins = 0,
    this.totalCoinsEarned = 0,
    this.rewardHistory = const [],
  });

  bool get canClaimToday {
    final now = DateTime.now();
    final lastLogin = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(lastLogin);
  }

  bool get isStreakAlive {
    final now = DateTime.now();
    final lastLogin = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(lastLogin).inDays;
    return diff <= 1;
  }

  int get nextRewardCoins => LoginReward.coinsForDay(isStreakAlive ? currentStreak + 1 : 1);

  double get streakMultiplier {
    if (currentStreak >= 30) return 5.0;
    if (currentStreak >= 14) return 3.0;
    if (currentStreak >= 7) return 2.0;
    if (currentStreak >= 3) return 1.5;
    return 1.0;
  }

  String get streakMultiplierLabel {
    final m = streakMultiplier;
    if (m == 1.0) return '';
    return '${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)}x';
  }

  factory StreakModel.fresh(String userId) {
    return StreakModel(
      userId: userId,
      lastLoginDate: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  factory StreakModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StreakModel(
      userId: data['userId'] ?? '',
      currentStreak: (data['currentStreak'] as num? ?? 0).toInt(),
      longestStreak: (data['longestStreak'] as num? ?? 0).toInt(),
      lastLoginDate: (data['lastLoginDate'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 2)),
      totalLogins: (data['totalLogins'] as num? ?? 0).toInt(),
      totalCoinsEarned: (data['totalCoinsEarned'] as num? ?? 0).toInt(),
      rewardHistory: (data['rewardHistory'] as List<dynamic>?)
              ?.map((e) => LoginReward.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'totalLogins': totalLogins,
      'totalCoinsEarned': totalCoinsEarned,
      'rewardHistory': rewardHistory.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class LoginReward {
  final int day;
  final int coins;
  final int xp;
  final DateTime claimedAt;

  LoginReward({
    required this.day,
    required this.coins,
    required this.xp,
    required this.claimedAt,
  });

  static int coinsForDay(int streakDay) {
    // Escalating rewards
    if (streakDay >= 30) return 100;
    if (streakDay >= 14) return 50;
    if (streakDay >= 7) return 25;
    if (streakDay >= 3) return 15;
    return 10;
  }

  static int xpForDay(int streakDay) {
    if (streakDay >= 30) return 50;
    if (streakDay >= 14) return 30;
    if (streakDay >= 7) return 20;
    return 10;
  }

  // Milestone bonuses
  static bool isMilestone(int day) {
    return day == 7 || day == 14 || day == 30 || day == 60 || day == 100;
  }

  static int milestoneBonus(int day) {
    switch (day) {
      case 7:
        return 50;
      case 14:
        return 100;
      case 30:
        return 250;
      case 60:
        return 500;
      case 100:
        return 1000;
      default:
        return 0;
    }
  }

  factory LoginReward.fromMap(Map<String, dynamic> map) {
    return LoginReward(
      day: (map['day'] as num? ?? 0).toInt(),
      coins: (map['coins'] as num? ?? 0).toInt(),
      xp: (map['xp'] as num? ?? 0).toInt(),
      claimedAt: (map['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'coins': coins,
      'xp': xp,
      'claimedAt': Timestamp.fromDate(claimedAt),
    };
  }
}
