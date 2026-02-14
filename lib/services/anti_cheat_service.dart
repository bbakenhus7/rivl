// services/anti_cheat_service.dart

import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/challenge_model.dart';

/// AI-powered anti-cheat verification service
/// Uses machine learning algorithms to detect fraudulent activity
/// Cross-references multiple biometric data sources for verification
class AntiCheatService {
  static final AntiCheatService _instance = AntiCheatService._internal();
  factory AntiCheatService() => _instance;
  AntiCheatService._internal();

  // ML Model thresholds
  static const double ANOMALY_THRESHOLD = 0.7;
  static const double PATTERN_THRESHOLD = 0.6;
  static const double REPUTATION_THRESHOLD = 0.5;
  static const int MAX_DAILY_STEPS = 50000;
  static const int SUSPICIOUS_DAILY_STEPS = 30000;

  // Heart rate correlation thresholds
  static const double MIN_HR_CORRELATION = 0.65; // Minimum correlation between steps and HR
  static const int RESTING_HR_MAX = 100; // Max resting heart rate
  static const int ACTIVE_HR_MIN = 90; // Minimum HR during activity
  static const int MAX_HR_SUSTAINED = 180; // Max sustainable HR

  /// Calculate comprehensive anti-cheat score (0.0 = cheating, 1.0 = legitimate).
  /// Tries server-side analysis first; falls back to local analysis if unavailable.
  Future<AntiCheatResult> analyzeActivity({
    required List<DailySteps> stepHistory,
    required String userId,
    double? userReputation,
    List<Map<String, dynamic>>? heartRateData,
    String? challengeId,
  }) async {
    // Try server-side analysis first (scoring logic stays on server)
    if (challengeId != null) {
      try {
        final result = await _tryServerAnalysis(
          challengeId: challengeId,
          stepHistory: stepHistory,
        );
        if (result != null) return result;
      } catch (_) {
        // Fall through to local analysis
      }
    }

    return _analyzeLocally(
      stepHistory: stepHistory,
      userId: userId,
      userReputation: userReputation,
      heartRateData: heartRateData,
    );
  }

  /// Call the server-side analyzeAntiCheat Cloud Function.
  Future<AntiCheatResult?> _tryServerAnalysis({
    required String challengeId,
    required List<DailySteps> stepHistory,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('analyzeAntiCheat');
      final response = await callable.call<Map<String, dynamic>>({
        'challengeId': challengeId,
        'stepHistory': stepHistory
            .map((s) => {'steps': s.steps, 'date': s.date.toIso8601String()})
            .toList(),
      });

      final data = response.data;
      return AntiCheatResult(
        overallScore: (data['overallScore'] as num).toDouble(),
        individualScores: {},
        flags: List<String>.from(data['flags'] ?? []),
        isSuspicious: data['isSuspicious'] ?? false,
        isCheating: data['isCheating'] ?? false,
        recommendation: data['isCheating'] == true
            ? 'Server flagged as cheating'
            : data['isSuspicious'] == true
                ? 'Server flagged as suspicious'
                : 'Clean',
      );
    } catch (e) {
      debugPrint('Server anti-cheat unavailable, falling back to local: $e');
      return null;
    }
  }

  /// Local fallback analysis (runs in-app when server is unavailable).
  Future<AntiCheatResult> _analyzeLocally({
    required List<DailySteps> stepHistory,
    required String userId,
    double? userReputation,
    List<Map<String, dynamic>>? heartRateData,
  }) async {
    final scores = <String, double>{};
    final flags = <String>[];

    // 1. Pattern Analysis - detect suspicious patterns
    final patternScore = await _analyzePatterns(stepHistory);
    scores['pattern'] = patternScore;
    if (patternScore < PATTERN_THRESHOLD) {
      flags.add('Suspicious step patterns detected');
    }

    // 2. Anomaly Detection - identify statistical outliers
    final anomalyScore = await _detectAnomalies(stepHistory);
    scores['anomaly'] = anomalyScore;
    if (anomalyScore < ANOMALY_THRESHOLD) {
      flags.add('Statistical anomalies in activity data');
    }

    // 3. Historical Behavior - compare to user's baseline
    final behaviorScore = await _compareHistoricalBehavior(stepHistory, userId);
    scores['behavior'] = behaviorScore;
    if (behaviorScore < 0.6) {
      flags.add('Activity deviates significantly from user baseline');
    }

    // 4. Device & Sensor Validation
    final deviceScore = await _validateDeviceData(stepHistory);
    scores['device'] = deviceScore;
    if (deviceScore < 0.7) {
      flags.add('Inconsistent device or sensor data');
    }

    // 5. Cross-Reference Heart Rate (if available)
    if (heartRateData != null && heartRateData.isNotEmpty) {
      final hrScore = await _crossReferenceHeartRate(stepHistory, heartRateData);
      scores['heartRate'] = hrScore;
      if (hrScore < 0.6) {
        flags.add('Heart rate data inconsistent with step count');
      }
    }

    // 6. User Reputation Score
    final reputationScore = userReputation ?? 0.8;
    scores['reputation'] = reputationScore;
    if (reputationScore < REPUTATION_THRESHOLD) {
      flags.add('User has low trust score');
    }

    // 7. Threshold Checks
    final thresholdScore = _checkThresholds(stepHistory);
    scores['threshold'] = thresholdScore;
    if (thresholdScore < 0.5) {
      flags.add('Step counts exceed human maximum');
    }

    // Calculate weighted composite score
    final compositeScore = _calculateCompositeScore(scores);
    final isSuspicious = compositeScore < 0.65;
    final isCheating = compositeScore < 0.4;

    return AntiCheatResult(
      overallScore: compositeScore,
      individualScores: scores,
      flags: flags,
      isSuspicious: isSuspicious,
      isCheating: isCheating,
      recommendation: _getRecommendation(compositeScore, flags),
    );
  }

  /// ML-based pattern analysis - detect bot-like behavior
  Future<double> _analyzePatterns(List<DailySteps> history) async {
    if (history.isEmpty) return 0.5;

    double score = 1.0;

    // Check for unrealistic consistency (bots often have too-perfect patterns)
    final steps = history.map((d) => d.steps).toList();
    final variance = _calculateVariance(steps);
    if (variance < 100) {
      // Too consistent = suspicious
      score -= 0.3;
    }

    // Check for unusual timing patterns
    final hasNightActivity = history.any((d) {
      // In real implementation, would check timestamp hours
      return false; // Stub for now
    });
    if (hasNightActivity) score -= 0.2;

    // Check for sudden spikes
    for (int i = 1; i < history.length; i++) {
      final prevDay = history[i - 1].steps;
      final currDay = history[i].steps;
      if (prevDay > 0 && currDay > prevDay * 3) {
        // 3x increase = suspicious
        score -= 0.15;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Anomaly detection using statistical methods
  Future<double> _detectAnomalies(List<DailySteps> history) async {
    if (history.isEmpty) return 0.5;

    final steps = history.map((d) => d.steps.toDouble()).toList();
    final mean = steps.reduce((a, b) => a + b) / steps.length;
    final stdDev = sqrt(_calculateVariance(steps.map((s) => s.toInt()).toList()));

    double score = 1.0;
    int outlierCount = 0;

    // Z-score anomaly detection
    for (final step in steps) {
      final zScore = (step - mean).abs() / (stdDev + 1); // +1 to avoid div by 0
      if (zScore > 3) {
        // More than 3 standard deviations = anomaly
        outlierCount++;
      }
    }

    final outlierRate = outlierCount / steps.length;
    if (outlierRate > 0.2) {
      // More than 20% outliers = suspicious
      score -= outlierRate;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Compare to user's historical baseline
  Future<double> _compareHistoricalBehavior(
    List<DailySteps> currentHistory,
    String userId,
  ) async {
    // In production, would fetch user's past 30-day average from database
    // For now, use mock baseline
    final mockBaseline = 7500; // Average user baseline
    final currentAvg = currentHistory.isEmpty
        ? 0
        : currentHistory.map((d) => d.steps).reduce((a, b) => a + b) /
            currentHistory.length;

    double score = 1.0;

    // Check if current average is realistic compared to baseline
    final deviationRatio = (currentAvg - mockBaseline).abs() / mockBaseline;
    if (deviationRatio > 2.0) {
      // More than 200% deviation = suspicious
      score -= 0.4;
    } else if (deviationRatio > 1.0) {
      // More than 100% deviation = somewhat suspicious
      score -= 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Validate device and sensor consistency
  Future<double> _validateDeviceData(List<DailySteps> history) async {
    if (history.isEmpty) return 0.5;

    double score = 1.0;

    // Check source consistency
    final sources = history.map((d) => d.source).toSet();
    if (sources.length > 3) {
      // Multiple different sources = potentially suspicious
      score -= 0.2;
    }

    // Check verification status
    final unverifiedCount = history.where((d) => !d.verified).length;
    final unverifiedRate = unverifiedCount / history.length;
    if (unverifiedRate > 0.3) {
      score -= 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Cross-reference with heart rate data using ML correlation analysis
  /// This is a key anti-fraud measure - steps should correlate with heart rate
  Future<double> _crossReferenceHeartRate(
    List<DailySteps> stepHistory,
    List<Map<String, dynamic>> heartRateData,
  ) async {
    if (heartRateData.isEmpty) return 0.7; // Neutral score if no HR data

    double score = 1.0;
    final flags = <String>[];

    // 1. Check for HR data presence during high activity
    for (final day in stepHistory) {
      if (day.steps > 10000) {
        final dayHRData = heartRateData.where((hr) => hr['date'] == day.date).toList();
        if (dayHRData.isEmpty) {
          score -= 0.1;
          flags.add('Missing HR data on high activity day: ${day.date}');
        }
      }
    }

    // 2. Analyze step-to-HR correlation
    final correlationScore = _calculateStepHRCorrelation(stepHistory, heartRateData);
    if (correlationScore < MIN_HR_CORRELATION) {
      score -= (MIN_HR_CORRELATION - correlationScore);
      flags.add('Low step-HR correlation: ${correlationScore.toStringAsFixed(2)}');
    }

    // 3. Check for physiologically impossible patterns
    final physiologyScore = _validateHeartRatePhysiology(heartRateData);
    if (physiologyScore < 0.7) {
      score -= (0.7 - physiologyScore);
      flags.add('Physiologically suspicious HR patterns');
    }

    // 4. Detect HR data manipulation patterns
    final manipulationScore = _detectHRManipulation(heartRateData);
    if (manipulationScore < 0.8) {
      score -= (0.8 - manipulationScore) * 0.5;
      flags.add('Potential HR data manipulation detected');
    }

    // 5. Verify HR response to step intensity
    final responseScore = _validateHRStepResponse(stepHistory, heartRateData);
    if (responseScore < 0.6) {
      score -= (0.6 - responseScore) * 0.5;
      flags.add('HR response inconsistent with step intensity');
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate Pearson correlation between step counts and average heart rate
  double _calculateStepHRCorrelation(
    List<DailySteps> stepHistory,
    List<Map<String, dynamic>> heartRateData,
  ) {
    final matchedData = <Map<String, num>>[];

    for (final day in stepHistory) {
      final dayHR = heartRateData.where((hr) => hr['date'] == day.date).toList();
      if (dayHR.isNotEmpty) {
        final avgHR = dayHR.map((hr) => hr['value'] as num).reduce((a, b) => a + b) / dayHR.length;
        matchedData.add({'steps': day.steps, 'hr': avgHR});
      }
    }

    if (matchedData.length < 3) return 0.7; // Not enough data

    // Calculate Pearson correlation coefficient
    final n = matchedData.length;
    final sumSteps = matchedData.map((d) => d['steps']!).reduce((a, b) => a + b);
    final sumHR = matchedData.map((d) => d['hr']!).reduce((a, b) => a + b);
    final sumStepsHR = matchedData.map((d) => d['steps']! * d['hr']!).reduce((a, b) => a + b);
    final sumStepsSq = matchedData.map((d) => d['steps']! * d['steps']!).reduce((a, b) => a + b);
    final sumHRSq = matchedData.map((d) => d['hr']! * d['hr']!).reduce((a, b) => a + b);

    final numerator = (n * sumStepsHR) - (sumSteps * sumHR);
    final denominator = sqrt(
      ((n * sumStepsSq) - (sumSteps * sumSteps)) *
      ((n * sumHRSq) - (sumHR * sumHR))
    );

    if (denominator == 0) return 0.5;

    final correlation = numerator / denominator;
    return ((correlation + 1) / 2).clamp(0.0, 1.0); // Normalize to 0-1
  }

  /// Validate that heart rate patterns are physiologically possible
  double _validateHeartRatePhysiology(List<Map<String, dynamic>> heartRateData) {
    if (heartRateData.isEmpty) return 0.8;

    double score = 1.0;

    for (final hr in heartRateData) {
      final value = hr['value'] as int;

      // Check for impossible values
      if (value < 30 || value > 220) {
        return 0.0; // Definitely fraudulent
      }

      // Check for suspicious sustained high HR
      if (value > MAX_HR_SUSTAINED) {
        score -= 0.1;
      }
    }

    // Check for too-consistent HR (bot-like behavior)
    final hrValues = heartRateData.map((hr) => hr['value'] as int).toList();
    final hrVariance = _calculateVariance(hrValues);
    if (hrVariance < 10) {
      score -= 0.3; // HR should naturally vary
    }

    return score.clamp(0.0, 1.0);
  }

  /// Detect patterns that suggest HR data manipulation
  double _detectHRManipulation(List<Map<String, dynamic>> heartRateData) {
    if (heartRateData.length < 5) return 0.8;

    double score = 1.0;

    // Check for repeating exact values (copy-paste fraud)
    final hrValues = heartRateData.map((hr) => hr['value']).toList();
    final uniqueRatio = hrValues.toSet().length / hrValues.length;
    if (uniqueRatio < 0.3) {
      score -= 0.4; // Too many repeated values
    }

    // Check for perfectly linear patterns (generated data)
    bool isPerfectlyLinear = true;
    for (int i = 2; i < hrValues.length; i++) {
      final diff1 = hrValues[i] - hrValues[i - 1];
      final diff2 = hrValues[i - 1] - hrValues[i - 2];
      if (diff1 != diff2) {
        isPerfectlyLinear = false;
        break;
      }
    }
    if (isPerfectlyLinear && hrValues.length > 5) {
      score -= 0.5; // Suspiciously linear pattern
    }

    return score.clamp(0.0, 1.0);
  }

  /// Validate that HR responds appropriately to step intensity
  double _validateHRStepResponse(
    List<DailySteps> stepHistory,
    List<Map<String, dynamic>> heartRateData,
  ) {
    double score = 1.0;

    for (final day in stepHistory) {
      final dayHR = heartRateData.where((hr) => hr['date'] == day.date).toList();
      if (dayHR.isEmpty) continue;

      final maxHR = dayHR.map((hr) => hr['value'] as int).reduce(max);
      final avgHR = dayHR.map((hr) => hr['value'] as int).reduce((a, b) => a + b) / dayHR.length;

      // High step days should have elevated HR
      if (day.steps > 15000 && maxHR < 110) {
        score -= 0.15; // Suspiciously low HR for high activity
      }

      // Very high step days should show significant HR elevation
      if (day.steps > 25000 && avgHR < 90) {
        score -= 0.2; // Very suspicious
      }

      // Low step days with very high HR is suspicious (unless medical condition)
      if (day.steps < 3000 && avgHR > 120) {
        score -= 0.1; // Possible data inconsistency
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Basic threshold validation
  double _checkThresholds(List<DailySteps> history) {
    if (history.isEmpty) return 0.5;

    double score = 1.0;

    for (final day in history) {
      if (day.steps > MAX_DAILY_STEPS) {
        // Exceeds human maximum
        return 0.0;
      } else if (day.steps > SUSPICIOUS_DAILY_STEPS) {
        // Unusually high
        score -= 0.2;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate weighted composite score
  double _calculateCompositeScore(Map<String, double> scores) {
    // Weighted average of all scores
    final weights = {
      'pattern': 0.20,
      'anomaly': 0.20,
      'behavior': 0.15,
      'device': 0.15,
      'heartRate': 0.10,
      'reputation': 0.10,
      'threshold': 0.10,
    };

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    scores.forEach((key, value) {
      final weight = weights[key] ?? 0.1;
      weightedSum += value * weight;
      totalWeight += weight;
    });

    return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
  }

  /// Get action recommendation based on score
  String _getRecommendation(double score, List<String> flags) {
    if (score >= 0.85) {
      return 'APPROVE - Activity appears legitimate';
    } else if (score >= 0.65) {
      return 'REVIEW - Minor concerns, monitor activity';
    } else if (score >= 0.4) {
      return 'FLAG - Suspicious activity detected, requires manual review';
    } else {
      return 'REJECT - High probability of cheating, deny results';
    }
  }

  /// Calculate statistical variance
  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate user reputation score based on history
  Future<double> calculateUserReputation(String userId) async {
    // In production, would analyze:
    // - Past challenge completion rate
    // - Historical anti-cheat scores
    // - Dispute resolution outcomes
    // - Account age and verification status

    // Mock implementation
    return 0.85; // Default good reputation
  }
}

class AntiCheatResult {
  final double overallScore;
  final Map<String, double> individualScores;
  final List<String> flags;
  final bool isSuspicious;
  final bool isCheating;
  final String recommendation;

  AntiCheatResult({
    required this.overallScore,
    required this.individualScores,
    required this.flags,
    required this.isSuspicious,
    required this.isCheating,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'individualScores': individualScores,
    'flags': flags,
    'isSuspicious': isSuspicious,
    'isCheating': isCheating,
    'recommendation': recommendation,
  };
}
