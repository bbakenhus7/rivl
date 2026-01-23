// models/user_stats_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatsModel {
  final String userId;
  final int totalChallenges;
  final int wins;
  final int losses;
  final int activeChallenges;
  final double totalEarnings;
  final double totalSpent;
  final double currentBalance;
  final int currentStreak;
  final int longestStreak;
  final List<String> achievementIds;
  final DateTime lastActiveAt;
  final DateTime createdAt;

  UserStatsModel({
    required this.userId,
    this.totalChallenges = 0,
    this.wins = 0,
    this.losses = 0,
    this.activeChallenges = 0,
    this.totalEarnings = 0.0,
    this.totalSpent = 0.0,
    this.currentBalance = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.achievementIds = const [],
    required this.lastActiveAt,
    required this.createdAt,
  });

  double get winRate {
    if (totalChallenges == 0) return 0.0;
    return (wins / totalChallenges) * 100;
  }

  double get netProfit => totalEarnings - totalSpent;

  String get winRateDisplay => '${winRate.toStringAsFixed(1)}%';
  String get winLossRecord => '$wins-$losses';

  factory UserStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserStatsModel(
      userId: doc.id,
      totalChallenges: data['totalChallenges'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      activeChallenges: data['activeChallenges'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      currentBalance: (data['currentBalance'] ?? 0).toDouble(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      achievementIds: List<String>.from(data['achievementIds'] ?? []),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalChallenges': totalChallenges,
      'wins': wins,
      'losses': losses,
      'activeChallenges': activeChallenges,
      'totalEarnings': totalEarnings,
      'totalSpent': totalSpent,
      'currentBalance': currentBalance,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'achievementIds': achievementIds,
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
