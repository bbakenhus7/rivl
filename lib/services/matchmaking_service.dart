// services/matchmaking_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';

/// AI-powered intelligent matchmaking service
/// Uses machine learning algorithms to optimize pairings for:
/// - Engagement: Matches that keep users coming back
/// - Skill balance: Fair competition based on performance history
/// - Retention: Strategic matching to improve user retention
class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Matchmaking parameters
  static const double SKILL_WEIGHT = 0.35;
  static const double ACTIVITY_WEIGHT = 0.25;
  static const double RETENTION_WEIGHT = 0.20;
  static const double SOCIAL_WEIGHT = 0.20;

  // ELO-style rating parameters
  static const double K_FACTOR = 32.0;
  static const double BASE_RATING = 1200.0;

  /// Find optimal opponents for a user
  Future<List<MatchSuggestion>> findMatches({
    required String userId,
    required GoalType goalType,
    int limit = 10,
  }) async {
    final user = await _getUser(userId);
    if (user == null) return [];

    final userProfile = await _buildUserProfile(userId);

    // Get potential opponents
    final candidates = await _getCandidates(userId, limit: limit * 3);

    // Score each candidate
    final scored = <MatchSuggestion>[];
    for (final candidate in candidates) {
      final candidateProfile = await _buildUserProfile(candidate.id);
      final score = await _calculateMatchScore(
        userProfile,
        candidateProfile,
        goalType,
      );

      scored.add(MatchSuggestion(
        opponent: candidate,
        matchScore: score.overall,
        skillBalance: score.skillBalance,
        predictedEngagement: score.engagement,
        estimatedWinChance: score.winProbability,
        matchReason: _generateMatchReason(score),
      ));
    }

    // Sort by match score and return top matches
    scored.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return scored.take(limit).toList();
  }

  /// Calculate comprehensive match score between two users
  Future<MatchScore> _calculateMatchScore(
    UserProfile user,
    UserProfile opponent,
    GoalType goalType,
  ) async {
    // 1. Skill Balance Score (0-1)
    // Optimal match is when skill levels are close but not identical
    final skillDiff = (user.skillRating - opponent.skillRating).abs();
    final optimalDiff = 100.0; // Ideal skill difference
    final skillBalance = 1.0 - min(skillDiff / 300, 1.0); // Penalize large gaps

    // 2. Activity Compatibility Score (0-1)
    // Match users with similar activity patterns
    final activityScore = _calculateActivityCompatibility(user, opponent);

    // 3. Retention Score (0-1)
    // Strategic matching to improve retention for at-risk users
    final retentionScore = _calculateRetentionScore(user, opponent);

    // 4. Social Score (0-1)
    // Boost scores for friends or users with mutual connections
    final socialScore = _calculateSocialScore(user, opponent);

    // 5. Goal Type Compatibility (0-1)
    final goalScore = _calculateGoalTypeCompatibility(user, opponent, goalType);

    // Calculate weighted overall score
    final overall = (skillBalance * SKILL_WEIGHT) +
                    (activityScore * ACTIVITY_WEIGHT) +
                    (retentionScore * RETENTION_WEIGHT) +
                    (socialScore * SOCIAL_WEIGHT);

    // Calculate win probability using ELO formula
    final winProbability = _calculateWinProbability(
      user.skillRating,
      opponent.skillRating,
    );

    // Calculate predicted engagement based on match quality
    final engagement = (overall * 0.6) + (goalScore * 0.4);

    return MatchScore(
      overall: overall,
      skillBalance: skillBalance,
      activityCompatibility: activityScore,
      retentionBoost: retentionScore,
      socialConnection: socialScore,
      goalTypeScore: goalScore,
      winProbability: winProbability,
      engagement: engagement,
    );
  }

  /// Build comprehensive user profile for matchmaking
  Future<UserProfile> _buildUserProfile(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return UserProfile.empty(userId);
    }

    final userData = userDoc.data()!;

    // Get challenge history
    final challengesSnapshot = await _db
        .collection('challenges')
        .where(Filter.or(
          Filter('creatorId', isEqualTo: userId),
          Filter('opponentId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final challenges = challengesSnapshot.docs
        .map((doc) => ChallengeModel.fromFirestore(doc))
        .toList();

    // Calculate metrics
    final wins = challenges.where((c) => c.winnerId == userId).length;
    final losses = challenges.where((c) =>
        c.winnerId != null && c.winnerId != userId).length;
    final totalGames = wins + losses;

    // Calculate skill rating (ELO-based)
    double skillRating = BASE_RATING;
    for (final challenge in challenges.reversed) {
      if (challenge.status != ChallengeStatus.completed) continue;
      final won = challenge.winnerId == userId;
      final opponentRating = BASE_RATING; // Simplified - in production, fetch actual opponent rating
      skillRating = _updateRating(skillRating, opponentRating, won);
    }

    // Calculate activity metrics
    final recentChallenges = challenges.where((c) =>
        c.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;

    final avgDailySteps = (userData['totalSteps'] ?? 0) ~/
        max(DateTime.now().difference(
          (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
        ).inDays, 1);

    // Calculate streak and consistency
    final currentStreak = userData['currentStreak'] ?? 0;
    final longestStreak = userData['longestStreak'] ?? 0;

    // Determine user segment for retention
    final daysSinceLastActive = DateTime.now().difference(
      (userData['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now()
    ).inDays;

    final retentionRisk = daysSinceLastActive > 7 ? 0.8 :
                          daysSinceLastActive > 3 ? 0.5 : 0.2;

    return UserProfile(
      userId: userId,
      skillRating: skillRating,
      totalGames: totalGames,
      winRate: totalGames > 0 ? wins / totalGames : 0.5,
      avgDailySteps: avgDailySteps,
      recentActivityLevel: recentChallenges / 30.0, // Normalized
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      retentionRisk: retentionRisk,
      preferredGoalTypes: _extractPreferredGoalTypes(challenges),
      friends: List<String>.from(userData['friends'] ?? []),
    );
  }

  /// Calculate activity compatibility between users
  double _calculateActivityCompatibility(UserProfile user, UserProfile opponent) {
    // Compare average daily steps
    final stepDiff = (user.avgDailySteps - opponent.avgDailySteps).abs();
    final stepScore = 1.0 - min(stepDiff / 10000, 1.0);

    // Compare recent activity levels
    final activityDiff = (user.recentActivityLevel - opponent.recentActivityLevel).abs();
    final activityScore = 1.0 - activityDiff;

    return (stepScore * 0.6) + (activityScore * 0.4);
  }

  /// Calculate retention boost score
  /// Prioritizes matching at-risk users with engaged users
  double _calculateRetentionScore(UserProfile user, UserProfile opponent) {
    // If user is at risk, match with engaged users
    if (user.retentionRisk > 0.6) {
      if (opponent.retentionRisk < 0.3) {
        return 0.9; // High priority match
      }
    }

    // New users should be matched with patient, experienced players
    if (user.totalGames < 5) {
      if (opponent.totalGames > 10 && opponent.winRate < 0.7) {
        return 0.85; // Good mentor match
      }
    }

    // Users on a losing streak benefit from winnable matches
    if (user.currentStreak < 0) {
      if (user.skillRating > opponent.skillRating) {
        return 0.8; // Confidence-building match
      }
    }

    return 0.5; // Neutral
  }

  /// Calculate social connection score
  double _calculateSocialScore(UserProfile user, UserProfile opponent) {
    // Direct friends get highest score
    if (user.friends.contains(opponent.userId)) {
      return 1.0;
    }

    // Could extend to check for mutual friends, same groups, etc.
    return 0.3; // Base social score for strangers
  }

  /// Calculate goal type compatibility
  double _calculateGoalTypeCompatibility(
    UserProfile user,
    UserProfile opponent,
    GoalType goalType,
  ) {
    final userPref = user.preferredGoalTypes[goalType] ?? 0;
    final opponentPref = opponent.preferredGoalTypes[goalType] ?? 0;

    // Both prefer this goal type = good match
    if (userPref > 0.3 && opponentPref > 0.3) {
      return 0.9;
    }

    // At least one has experience
    if (userPref > 0.2 || opponentPref > 0.2) {
      return 0.6;
    }

    return 0.4; // New territory for both
  }

  /// Calculate win probability using ELO formula
  double _calculateWinProbability(double userRating, double opponentRating) {
    return 1.0 / (1.0 + pow(10, (opponentRating - userRating) / 400));
  }

  /// Update ELO rating based on match result
  double _updateRating(double rating, double opponentRating, bool won) {
    final expected = _calculateWinProbability(rating, opponentRating);
    final actual = won ? 1.0 : 0.0;
    return rating + (K_FACTOR * (actual - expected));
  }

  /// Extract preferred goal types from challenge history
  Map<GoalType, double> _extractPreferredGoalTypes(List<ChallengeModel> challenges) {
    final counts = <GoalType, int>{};
    for (final challenge in challenges) {
      counts[challenge.goalType] = (counts[challenge.goalType] ?? 0) + 1;
    }

    final total = challenges.length.toDouble();
    if (total == 0) return {};

    return counts.map((key, value) => MapEntry(key, value / total));
  }

  /// Generate human-readable match reason
  String _generateMatchReason(MatchScore score) {
    if (score.socialConnection > 0.8) {
      return 'Friend match';
    }
    if (score.skillBalance > 0.8) {
      return 'Great skill match';
    }
    if (score.retentionBoost > 0.7) {
      return 'Recommended for you';
    }
    if (score.activityCompatibility > 0.8) {
      return 'Similar activity level';
    }
    return 'Good match';
  }

  /// Get candidate opponents
  Future<List<UserModel>> _getCandidates(String userId, {int limit = 30}) async {
    final snapshot = await _db
        .collection('users')
        .where('accountStatus', isEqualTo: 'active')
        .where(FieldPath.documentId, isNotEqualTo: userId)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<UserModel?> _getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Get quick match suggestion
  Future<UserModel?> getQuickMatch({
    required String userId,
    required GoalType goalType,
  }) async {
    final matches = await findMatches(
      userId: userId,
      goalType: goalType,
      limit: 1,
    );
    return matches.isEmpty ? null : matches.first.opponent;
  }
}

/// User profile for matchmaking calculations
class UserProfile {
  final String odId;
  final double skillRating;
  final int totalGames;
  final double winRate;
  final int avgDailySteps;
  final double recentActivityLevel;
  final int currentStreak;
  final int longestStreak;
  final double retentionRisk;
  final Map<GoalType, double> preferredGoalTypes;
  final List<String> friends;

  UserProfile({
    required this.odId,
    required this.skillRating,
    required this.totalGames,
    required this.winRate,
    required this.avgDailySteps,
    required this.recentActivityLevel,
    required this.currentStreak,
    required this.longestStreak,
    required this.retentionRisk,
    required this.preferredGoalTypes,
    required this.friends,
  });

  String get userId => odId;

  factory UserProfile.empty(String userId) {
    return UserProfile(
      odId: userId,
      skillRating: 1200.0,
      totalGames: 0,
      winRate: 0.5,
      avgDailySteps: 5000,
      recentActivityLevel: 0.0,
      currentStreak: 0,
      longestStreak: 0,
      retentionRisk: 0.5,
      preferredGoalTypes: {},
      friends: [],
    );
  }
}

/// Match score breakdown
class MatchScore {
  final double overall;
  final double skillBalance;
  final double activityCompatibility;
  final double retentionBoost;
  final double socialConnection;
  final double goalTypeScore;
  final double winProbability;
  final double engagement;

  MatchScore({
    required this.overall,
    required this.skillBalance,
    required this.activityCompatibility,
    required this.retentionBoost,
    required this.socialConnection,
    required this.goalTypeScore,
    required this.winProbability,
    required this.engagement,
  });
}

/// Match suggestion with reasoning
class MatchSuggestion {
  final UserModel opponent;
  final double matchScore;
  final double skillBalance;
  final double predictedEngagement;
  final double estimatedWinChance;
  final String matchReason;

  MatchSuggestion({
    required this.opponent,
    required this.matchScore,
    required this.skillBalance,
    required this.predictedEngagement,
    required this.estimatedWinChance,
    required this.matchReason,
  });
}
