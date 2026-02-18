// services/predictive_analytics_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../models/user_model.dart';

/// Predictive Analytics Service
/// Uses ML models to forecast challenge outcomes and personalize user experience
class PredictiveAnalyticsService {
  static final PredictiveAnalyticsService _instance =
      PredictiveAnalyticsService._internal();
  factory PredictiveAnalyticsService() => _instance;
  PredictiveAnalyticsService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Model parameters (in production, these would be trained)
  static const double _BASE_STEP_RATE = 8000; // Average daily steps
  static const double _STEP_VARIANCE = 2500; // Standard deviation
  static const double _COMPETITION_BOOST = 1.15; // Users walk 15% more in competitions

  // ============================================
  // CHALLENGE OUTCOME PREDICTION
  // ============================================

  /// Predict the outcome of a challenge before it starts
  Future<ChallengePrediction> predictOutcome({
    required String userId,
    required String opponentId,
    required GoalType goalType,
    required ChallengeDuration duration,
  }) async {
    final userProfile = await _getUserActivityProfile(userId);
    final opponentProfile = await _getUserActivityProfile(opponentId);

    // Calculate expected performance
    final userExpected = _predictPerformance(
      userProfile,
      goalType,
      duration.days,
    );
    final opponentExpected = _predictPerformance(
      opponentProfile,
      goalType,
      duration.days,
    );

    // Calculate win probability using statistical model
    final winProbability = _calculateWinProbability(
      userExpected,
      opponentExpected,
    );

    // Predict final scores
    final predictedUserScore = _addVariance(userExpected.mean);
    final predictedOpponentScore = _addVariance(opponentExpected.mean);

    // Calculate confidence based on data quality
    final confidence = _calculateConfidence(userProfile, opponentProfile);

    return ChallengePrediction(
      winProbability: winProbability,
      predictedUserScore: predictedUserScore,
      predictedOpponentScore: predictedOpponentScore,
      confidence: confidence,
      userStrengths: _identifyStrengths(userProfile, opponentProfile),
      recommendations: _generateRecommendations(userProfile, goalType),
      closenessScore: _calculateCloseness(userExpected, opponentExpected),
    );
  }

  /// Predict remaining challenge outcome mid-challenge
  Future<MidChallengePrediction> predictMidChallenge({
    required ChallengeModel challenge,
    required String userId,
  }) async {
    if (challenge.startDate == null || challenge.endDate == null) {
      return MidChallengePrediction.empty();
    }

    final now = DateTime.now();
    final totalDays = challenge.endDate!.difference(challenge.startDate!).inDays;
    final daysElapsed = now.difference(challenge.startDate!).inDays;
    final daysRemaining = challenge.endDate!.difference(now).inDays;

    if (daysRemaining <= 0 || totalDays <= 0) {
      return MidChallengePrediction.empty();
    }

    final isCreator = challenge.creatorId == userId;
    final userProgress = isCreator ? challenge.creatorProgress : challenge.opponentProgress;
    final opponentProgress = isCreator ? challenge.opponentProgress : challenge.creatorProgress;

    // Calculate current pace
    final userDailyRate = daysElapsed > 0 ? userProgress / daysElapsed : 0.0;
    final opponentDailyRate = daysElapsed > 0 ? opponentProgress / daysElapsed : 0.0;

    // Project final scores
    final projectedUserFinal = userProgress + (userDailyRate * daysRemaining);
    final projectedOpponentFinal = opponentProgress + (opponentDailyRate * daysRemaining);

    // Calculate win probability
    final margin = projectedUserFinal - projectedOpponentFinal;
    final uncertainty = sqrt(daysRemaining.toDouble()) * _STEP_VARIANCE;
    final winProbability = uncertainty > 0
        ? _normalCDF(margin / uncertainty)
        : (margin > 0 ? 1.0 : 0.5);

    // Calculate required pace to win
    final requiredDailyPace = _calculateRequiredPace(
      currentProgress: userProgress,
      opponentProgress: opponentProgress,
      opponentDailyRate: opponentDailyRate,
      daysRemaining: daysRemaining,
    );

    // Trend analysis
    final trend = userDailyRate > opponentDailyRate ? 'gaining' :
                  userDailyRate < opponentDailyRate ? 'falling behind' : 'holding steady';

    return MidChallengePrediction(
      winProbability: winProbability.clamp(0.0, 1.0),
      projectedFinalScore: projectedUserFinal.round(),
      projectedOpponentScore: projectedOpponentFinal.round(),
      currentDailyRate: userDailyRate.round(),
      requiredDailyPace: requiredDailyPace.round(),
      trend: trend,
      daysRemaining: daysRemaining,
      comebackPossible: margin < 0 && requiredDailyPace < _BASE_STEP_RATE * 1.5,
    );
  }

  // ============================================
  // USER PERSONALIZATION
  // ============================================

  /// Generate personalized challenge recommendations
  Future<List<ChallengeRecommendation>> getPersonalizedRecommendations({
    required String userId,
    int limit = 5,
  }) async {
    final profile = await _getUserActivityProfile(userId);
    final history = await _getChallengeHistory(userId);

    final recommendations = <ChallengeRecommendation>[];

    // Recommend based on activity patterns
    if (profile.avgDailySteps > 10000) {
      recommendations.add(ChallengeRecommendation(
        type: 'high_performer',
        goalType: GoalType.steps,
        suggestedDuration: ChallengeDuration.oneWeek,
        suggestedStake: 50.0,
        reason: 'Your high daily step count makes you competitive in step challenges',
        expectedWinRate: 0.65,
      ));
    }

    // Recommend based on consistency
    if (profile.consistency > 0.8) {
      recommendations.add(ChallengeRecommendation(
        type: 'consistent',
        goalType: GoalType.steps,
        suggestedDuration: ChallengeDuration.twoWeeks,
        suggestedStake: 25.0,
        reason: 'Your consistent activity pattern is ideal for longer challenges',
        expectedWinRate: 0.60,
      ));
    }

    // Recommend based on sleep data if available
    if (profile.avgSleepHours != null && profile.avgSleepHours! >= 7) {
      recommendations.add(ChallengeRecommendation(
        type: 'good_sleeper',
        goalType: GoalType.sleepDuration,
        suggestedDuration: ChallengeDuration.oneWeek,
        suggestedStake: 20.0,
        reason: 'Your excellent sleep habits give you an edge in sleep challenges',
        expectedWinRate: 0.58,
      ));
    }

    // Recommend based on recent performance
    final recentWinRate = _calculateRecentWinRate(history, userId);
    if (recentWinRate > 0.6) {
      recommendations.add(ChallengeRecommendation(
        type: 'hot_streak',
        goalType: GoalType.steps,
        suggestedDuration: ChallengeDuration.oneWeek,
        suggestedStake: 75.0,
        reason: 'You\'re on a winning streak! Consider a higher stakes challenge',
        expectedWinRate: recentWinRate,
      ));
    } else if (recentWinRate < 0.4 && history.length > 3) {
      recommendations.add(ChallengeRecommendation(
        type: 'comeback',
        goalType: GoalType.steps,
        suggestedDuration: ChallengeDuration.threeDays,
        suggestedStake: 10.0,
        reason: 'A shorter, lower-stakes challenge could help rebuild momentum',
        expectedWinRate: 0.50,
      ));
    }

    // Add variety recommendation
    final leastPlayedType = _getLeastPlayedGoalType(history);
    if (leastPlayedType != null) {
      recommendations.add(ChallengeRecommendation(
        type: 'try_something_new',
        goalType: leastPlayedType,
        suggestedDuration: ChallengeDuration.oneWeek,
        suggestedStake: 20.0,
        reason: 'Try a ${leastPlayedType.displayName} challenge for variety!',
        expectedWinRate: 0.50,
      ));
    }

    return recommendations.take(limit).toList();
  }

  /// Predict user churn risk
  Future<ChurnPrediction> predictChurnRisk(String userId) async {
    final profile = await _getUserActivityProfile(userId);
    final history = await _getChallengeHistory(userId);

    double riskScore = 0.0;
    final riskFactors = <String>[];

    // Factor 1: Days since last activity
    if (profile.daysSinceActive > 14) {
      riskScore += 0.4;
      riskFactors.add('Inactive for ${profile.daysSinceActive} days');
    } else if (profile.daysSinceActive > 7) {
      riskScore += 0.2;
      riskFactors.add('Activity declining');
    }

    // Factor 2: Recent losses
    final recentLosses = history.where((c) =>
        c.winnerId != null &&
        c.winnerId != userId &&
        c.resultDeclaredAt != null &&
        c.resultDeclaredAt!.isAfter(DateTime.now().subtract(const Duration(days: 14)))
    ).length;

    if (recentLosses >= 3) {
      riskScore += 0.3;
      riskFactors.add('Multiple recent losses');
    }

    // Factor 3: Decreasing challenge participation
    final recentChallenges = history.where((c) =>
        c.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;
    final olderChallenges = history.where((c) =>
        c.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 60))) &&
        c.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 30)))
    ).length;

    if (olderChallenges > 0 && recentChallenges < olderChallenges * 0.5) {
      riskScore += 0.2;
      riskFactors.add('Declining engagement');
    }

    // Factor 4: Win rate trend
    final recentWinRate = _calculateRecentWinRate(history, userId);
    if (recentWinRate < 0.3 && history.length > 5) {
      riskScore += 0.15;
      riskFactors.add('Low win rate');
    }

    // Generate retention recommendations
    final retentionActions = <String>[];
    if (riskScore > 0.5) {
      retentionActions.add('Send personalized re-engagement notification');
      retentionActions.add('Offer bonus challenge with higher win probability');
    }
    if (recentLosses >= 3) {
      retentionActions.add('Match with lower-skill opponents');
      retentionActions.add('Suggest easier challenge types');
    }
    if (profile.daysSinceActive > 7) {
      retentionActions.add('Send "We miss you" campaign');
      retentionActions.add('Offer welcome-back bonus');
    }

    return ChurnPrediction(
      riskScore: riskScore.clamp(0.0, 1.0),
      riskLevel: riskScore > 0.6 ? 'high' : riskScore > 0.3 ? 'medium' : 'low',
      riskFactors: riskFactors,
      retentionActions: retentionActions,
      predictedChurnDate: riskScore > 0.5
          ? DateTime.now().add(Duration(days: (30 * (1 - riskScore)).round()))
          : null,
    );
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  Future<UserActivityProfile> _getUserActivityProfile(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) return UserActivityProfile.empty();

    final userData = userDoc.data()!;

    // Get recent health data (simplified - in production, fetch from health collection)
    final avgSteps = userData['totalSteps'] ?? 0;
    final totalDays = max(
      DateTime.now().difference(
        (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ).inDays,
      1
    );

    return UserActivityProfile(
      avgDailySteps: avgSteps ~/ totalDays,
      consistency: 0.75, // Simplified - would calculate from actual data
      avgSleepHours: 7.5, // Simplified
      daysSinceActive: DateTime.now().difference(
        (userData['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ).inDays,
      totalChallenges: userData['totalChallenges'] ?? 0,
      winRate: (userData['winRate'] ?? 0.5).toDouble(),
    );
  }

  Future<List<ChallengeModel>> _getChallengeHistory(String userId) async {
    final snapshot = await _db
        .collection('challenges')
        .where(Filter.or(
          Filter('creatorId', isEqualTo: userId),
          Filter('opponentId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => ChallengeModel.fromFirestore(doc))
        .toList();
  }

  PerformanceEstimate _predictPerformance(
    UserActivityProfile profile,
    GoalType goalType,
    int days,
  ) {
    double mean;
    double stdDev;

    switch (goalType) {
      case GoalType.steps:
        mean = profile.avgDailySteps * days * _COMPETITION_BOOST;
        stdDev = _STEP_VARIANCE * sqrt(days.toDouble());
        break;
      case GoalType.distance:
        mean = (profile.avgDailySteps / 2000) * days * _COMPETITION_BOOST; // Approx miles
        stdDev = 1.5 * sqrt(days.toDouble());
        break;
      case GoalType.sleepDuration:
        mean = (profile.avgSleepHours ?? 7) * days;
        stdDev = 0.5 * sqrt(days.toDouble());
        break;
      default:
        mean = 100.0 * days;
        stdDev = 20 * sqrt(days.toDouble());
    }

    return PerformanceEstimate(mean: mean, stdDev: stdDev);
  }

  double _calculateWinProbability(
    PerformanceEstimate user,
    PerformanceEstimate opponent,
  ) {
    final meanDiff = user.mean - opponent.mean;
    final combinedStdDev = sqrt(user.stdDev * user.stdDev + opponent.stdDev * opponent.stdDev);

    if (combinedStdDev == 0) return meanDiff > 0 ? 1.0 : 0.0;

    return _normalCDF(meanDiff / combinedStdDev);
  }

  double _normalCDF(double x) {
    // Approximation of standard normal CDF
    const a1 =  0.254829592;
    const a2 = -0.284496736;
    const a3 =  1.421413741;
    const a4 = -1.453152027;
    const a5 =  1.061405429;
    const p  =  0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs() / sqrt(2);

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x);

    return 0.5 * (1.0 + sign * y);
  }

  double _addVariance(double mean) {
    final random = Random();
    // Clamp u1 to avoid log(0) which produces -Infinity/NaN
    final u1 = random.nextDouble().clamp(1e-10, 1.0);
    final u2 = random.nextDouble();
    final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    return mean + z * mean * 0.1; // 10% standard deviation
  }

  double _calculateConfidence(
    UserActivityProfile user,
    UserActivityProfile opponent,
  ) {
    // More data = higher confidence
    final dataScore = min((user.totalChallenges + opponent.totalChallenges) / 20, 1.0);
    // Recent activity = higher confidence
    final activityScore = 1.0 - min((user.daysSinceActive + opponent.daysSinceActive) / 30, 1.0);

    return (dataScore * 0.6 + activityScore * 0.4).clamp(0.3, 0.95);
  }

  List<String> _identifyStrengths(
    UserActivityProfile user,
    UserActivityProfile opponent,
  ) {
    final strengths = <String>[];

    if (user.avgDailySteps > opponent.avgDailySteps * 1.1) {
      strengths.add('Higher average daily steps');
    }
    if (user.consistency > opponent.consistency) {
      strengths.add('More consistent activity pattern');
    }
    if (user.winRate > opponent.winRate) {
      strengths.add('Higher historical win rate');
    }

    return strengths;
  }

  List<String> _generateRecommendations(
    UserActivityProfile profile,
    GoalType goalType,
  ) {
    final recommendations = <String>[];

    if (goalType == GoalType.steps && profile.avgDailySteps < 8000) {
      recommendations.add('Try to increase daily steps by 10-15% during the challenge');
    }
    if (profile.consistency < 0.7) {
      recommendations.add('Focus on consistent daily activity rather than big single days');
    }

    return recommendations;
  }

  double _calculateCloseness(
    PerformanceEstimate user,
    PerformanceEstimate opponent,
  ) {
    final diff = (user.mean - opponent.mean).abs();
    final avgPerformance = (user.mean + opponent.mean) / 2;
    if (avgPerformance <= 0) return 0.0; // Avoid division by zero
    return (1.0 - diff / avgPerformance).clamp(0.0, 1.0);
  }

  double _calculateRequiredPace(
    {required int currentProgress,
    required int opponentProgress,
    required double opponentDailyRate,
    required int daysRemaining,}
  ) {
    if (daysRemaining <= 0) return 0; // Avoid division by zero
    final projectedOpponentFinal = opponentProgress + (opponentDailyRate * daysRemaining);
    final needed = projectedOpponentFinal - currentProgress + 1; // +1 to win
    return max(needed / daysRemaining, 0);
  }

  double _calculateRecentWinRate(List<ChallengeModel> history, String userId) {
    final recent = history.where((c) =>
        c.status == ChallengeStatus.completed &&
        c.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).toList();

    if (recent.isEmpty) return 0.5;

    final wins = recent.where((c) => c.winnerId == userId).length;

    return wins / recent.length;
  }

  GoalType? _getLeastPlayedGoalType(List<ChallengeModel> history) {
    final counts = <GoalType, int>{};
    for (final goalType in GoalType.values) {
      counts[goalType] = history.where((c) => c.goalType == goalType).length;
    }

    if (counts.isEmpty) return null;

    return counts.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }
}

// ============================================
// DATA CLASSES
// ============================================

class UserActivityProfile {
  final int avgDailySteps;
  final double consistency;
  final double? avgSleepHours;
  final int daysSinceActive;
  final int totalChallenges;
  final double winRate;

  UserActivityProfile({
    required this.avgDailySteps,
    required this.consistency,
    this.avgSleepHours,
    required this.daysSinceActive,
    required this.totalChallenges,
    required this.winRate,
  });

  factory UserActivityProfile.empty() {
    return UserActivityProfile(
      avgDailySteps: 5000,
      consistency: 0.5,
      daysSinceActive: 0,
      totalChallenges: 0,
      winRate: 0.5,
    );
  }
}

class PerformanceEstimate {
  final double mean;
  final double stdDev;

  PerformanceEstimate({required this.mean, required this.stdDev});
}

class ChallengePrediction {
  final double winProbability;
  final double predictedUserScore;
  final double predictedOpponentScore;
  final double confidence;
  final List<String> userStrengths;
  final List<String> recommendations;
  final double closenessScore;

  ChallengePrediction({
    required this.winProbability,
    required this.predictedUserScore,
    required this.predictedOpponentScore,
    required this.confidence,
    required this.userStrengths,
    required this.recommendations,
    required this.closenessScore,
  });

  String get winChanceDisplay => '${(winProbability * 100).round()}%';

  String get matchupDescription {
    if (closenessScore > 0.9) return 'Very close matchup';
    if (closenessScore > 0.7) return 'Competitive matchup';
    if (winProbability > 0.65) return 'Favorable matchup';
    if (winProbability < 0.35) return 'Challenging matchup';
    return 'Fair matchup';
  }
}

class MidChallengePrediction {
  final double winProbability;
  final int projectedFinalScore;
  final int projectedOpponentScore;
  final int currentDailyRate;
  final int requiredDailyPace;
  final String trend;
  final int daysRemaining;
  final bool comebackPossible;

  MidChallengePrediction({
    required this.winProbability,
    required this.projectedFinalScore,
    required this.projectedOpponentScore,
    required this.currentDailyRate,
    required this.requiredDailyPace,
    required this.trend,
    required this.daysRemaining,
    required this.comebackPossible,
  });

  factory MidChallengePrediction.empty() {
    return MidChallengePrediction(
      winProbability: 0.5,
      projectedFinalScore: 0,
      projectedOpponentScore: 0,
      currentDailyRate: 0,
      requiredDailyPace: 0,
      trend: 'unknown',
      daysRemaining: 0,
      comebackPossible: false,
    );
  }
}

class ChallengeRecommendation {
  final String type;
  final GoalType goalType;
  final ChallengeDuration suggestedDuration;
  final double suggestedStake;
  final String reason;
  final double expectedWinRate;

  ChallengeRecommendation({
    required this.type,
    required this.goalType,
    required this.suggestedDuration,
    required this.suggestedStake,
    required this.reason,
    required this.expectedWinRate,
  });
}

class ChurnPrediction {
  final double riskScore;
  final String riskLevel;
  final List<String> riskFactors;
  final List<String> retentionActions;
  final DateTime? predictedChurnDate;

  ChurnPrediction({
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.retentionActions,
    this.predictedChurnDate,
  });
}

// Note: ChallengeDuration.days is provided by ChallengeDurationExtension in challenge_model.dart
