// models/leaderboard_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaderboardPeriod {
  allTime,
  monthly,
  weekly,
}

enum LeaderboardCategory {
  wins,
  earnings,
  winRate,
  streak,
}

class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String displayName;
  final String username;
  final int wins;
  final int totalChallenges;
  final double earnings;
  final double winRate;
  final int currentStreak;

  LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.username,
    required this.wins,
    required this.totalChallenges,
    required this.earnings,
    required this.winRate,
    required this.currentStreak,
  });

  String get rankDisplay {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  factory LeaderboardEntryModel.fromFirestore(DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>;

    return LeaderboardEntryModel(
      rank: rank,
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      wins: data['wins'] ?? 0,
      totalChallenges: data['totalChallenges'] ?? 0,
      earnings: (data['totalEarnings'] ?? 0).toDouble(),
      winRate: data['totalChallenges'] > 0
          ? (data['wins'] / data['totalChallenges'] * 100)
          : 0.0,
      currentStreak: data['currentStreak'] ?? 0,
    );
  }
}
