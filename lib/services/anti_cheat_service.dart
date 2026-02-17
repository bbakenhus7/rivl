// services/anti_cheat_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/challenge_model.dart';

/// Anti-cheat verification service for detecting fraudulent activity.
/// Uses multi-factor statistical analysis across step patterns, heart rate
/// correlation, device data, Benford's Law distribution, velocity limits,
/// time-series autocorrelation, and data freshness checks.
class AntiCheatService {
  static final AntiCheatService _instance = AntiCheatService._internal();
  factory AntiCheatService() => _instance;
  AntiCheatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Thresholds
  static const double ANOMALY_THRESHOLD = 0.7;
  static const double PATTERN_THRESHOLD = 0.6;
  static const double REPUTATION_THRESHOLD = 0.5;
  static const int MAX_DAILY_STEPS = 50000;
  static const int SUSPICIOUS_DAILY_STEPS = 30000;

  // Heart rate correlation thresholds
  static const double MIN_HR_CORRELATION = 0.65;
  static const int RESTING_HR_MAX = 100;
  static const int ACTIVE_HR_MIN = 90;
  static const int MAX_HR_SUSTAINED = 180;

  // Velocity thresholds (steps per hour)
  static const int MAX_STEPS_PER_HOUR = 12000; // ~200 steps/min sprint
  static const int SUSPICIOUS_STEPS_PER_HOUR = 8000;

  // Data freshness thresholds
  static const int MAX_SYNC_DELAY_HOURS = 48;
  static const int SUSPICIOUS_SYNC_DELAY_HOURS = 24;

  // Benford's Law expected distribution for leading digits 1-9
  static const List<double> _benfordExpected = [
    0.301, 0.176, 0.125, 0.097, 0.079, 0.067, 0.058, 0.051, 0.046,
  ];

  /// Cache for user baselines to avoid repeated Firestore reads within a session.
  final Map<String, _UserBaseline> _baselineCache = {};

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
            .map((s) => {'steps': s.steps, 'date': s.date})
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

    // 1. Pattern Analysis - detect bot-like behavior
    final patternScore = _analyzePatterns(stepHistory);
    scores['pattern'] = patternScore;
    if (patternScore < PATTERN_THRESHOLD) {
      flags.add('Suspicious step patterns detected');
    }

    // 2. Anomaly Detection - identify statistical outliers
    final anomalyScore = _detectAnomalies(stepHistory);
    scores['anomaly'] = anomalyScore;
    if (anomalyScore < ANOMALY_THRESHOLD) {
      flags.add('Statistical anomalies in activity data');
    }

    // 3. Historical Behavior - compare to user's actual baseline
    final behaviorScore = await _compareHistoricalBehavior(stepHistory, userId);
    scores['behavior'] = behaviorScore;
    if (behaviorScore < 0.6) {
      flags.add('Activity deviates significantly from user baseline');
    }

    // 4. Device & Sensor Validation
    final deviceScore = _validateDeviceData(stepHistory);
    scores['device'] = deviceScore;
    if (deviceScore < 0.7) {
      flags.add('Inconsistent device or sensor data');
    }

    // 5. Cross-Reference Heart Rate (if available)
    if (heartRateData != null && heartRateData.isNotEmpty) {
      final hrScore = _crossReferenceHeartRate(stepHistory, heartRateData);
      scores['heartRate'] = hrScore;
      if (hrScore < 0.6) {
        flags.add('Heart rate data inconsistent with step count');
      }
    }

    // 6. User Reputation Score (fetched from Firestore)
    final reputationScore = userReputation ??
        await calculateUserReputation(userId);
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

    // 8. Benford's Law Analysis - detect fabricated numbers
    final benfordScore = _analyzeBenfordsLaw(stepHistory);
    scores['benford'] = benfordScore;
    if (benfordScore < 0.5) {
      flags.add('Step count digit distribution appears fabricated');
    }

    // 9. Velocity Analysis - detect impossible step rates
    final velocityScore = _analyzeVelocity(stepHistory);
    scores['velocity'] = velocityScore;
    if (velocityScore < 0.6) {
      flags.add('Step accumulation rate exceeds human limits');
    }

    // 10. Time-Series Autocorrelation - detect periodic fake patterns
    final autocorrelationScore = _analyzeAutocorrelation(stepHistory);
    scores['autocorrelation'] = autocorrelationScore;
    if (autocorrelationScore < 0.5) {
      flags.add('Suspicious periodic pattern in step data');
    }

    // 11. Data Freshness - check sync timestamps
    final freshnessScore = _analyzeDataFreshness(stepHistory);
    scores['freshness'] = freshnessScore;
    if (freshnessScore < 0.6) {
      flags.add('Data sync timestamps are suspicious');
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

  // ============================================
  // PATTERN ANALYSIS
  // ============================================

  /// Detect bot-like patterns: unrealistic consistency, night activity,
  /// sudden spikes, and round-number bias.
  double _analyzePatterns(List<DailySteps> history) {
    if (history.isEmpty) return 0.5;

    double score = 1.0;
    final steps = history.map((d) => d.steps).toList();

    // Check for unrealistic consistency (bots often have too-perfect patterns)
    final variance = _calculateVariance(steps);
    if (variance < 100) {
      score -= 0.3;
    }

    // Check for suspicious night syncs (synced between 1am-5am local time)
    final nightSyncs = history.where((d) {
      final hour = d.syncedAt.hour;
      return hour >= 1 && hour < 5;
    }).length;
    if (history.length > 2 && nightSyncs > history.length * 0.3) {
      score -= 0.15;
    }

    // Check for sudden spikes (3x day-over-day increase)
    for (int i = 1; i < history.length; i++) {
      final prevDay = history[i - 1].steps;
      final currDay = history[i].steps;
      if (prevDay > 0 && currDay > prevDay * 3) {
        score -= 0.15;
      }
    }

    // Round-number bias: fabricated data tends to end in 000 or 00
    if (steps.length >= 3) {
      final roundCount = steps.where((s) => s > 0 && s % 1000 == 0).length;
      final roundRate = roundCount / steps.length;
      if (roundRate > 0.5) {
        score -= 0.2;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================
  // ANOMALY DETECTION
  // ============================================

  /// Z-score based anomaly detection for statistical outliers.
  double _detectAnomalies(List<DailySteps> history) {
    if (history.isEmpty) return 0.5;

    final steps = history.map((d) => d.steps.toDouble()).toList();
    final mean = steps.reduce((a, b) => a + b) / steps.length;
    final stdDev = sqrt(_calculateVariance(steps.map((s) => s.toInt()).toList()));

    double score = 1.0;
    int outlierCount = 0;

    for (final step in steps) {
      final zScore = (step - mean).abs() / (stdDev + 1);
      if (zScore > 3) {
        outlierCount++;
      }
    }

    final outlierRate = outlierCount / steps.length;
    if (outlierRate > 0.2) {
      score -= outlierRate;
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================
  // HISTORICAL BEHAVIOR COMPARISON
  // ============================================

  /// Compare current activity to the user's actual historical baseline
  /// fetched from Firestore. Uses the user's past 30-day challenge history
  /// and profile stats to build a personalized baseline.
  Future<double> _compareHistoricalBehavior(
    List<DailySteps> currentHistory,
    String userId,
  ) async {
    if (currentHistory.isEmpty) return 0.5;

    final baseline = await _getUserBaseline(userId);
    final currentAvg = currentHistory.map((d) => d.steps).reduce((a, b) => a + b) /
        currentHistory.length;

    double score = 1.0;

    if (baseline.averageDailySteps > 0) {
      final deviationRatio =
          (currentAvg - baseline.averageDailySteps).abs() / baseline.averageDailySteps;
      if (deviationRatio > 2.0) {
        score -= 0.4;
      } else if (deviationRatio > 1.0) {
        score -= 0.2;
      }

      // Check if current max exceeds historical max by a large margin
      final currentMax = currentHistory.map((d) => d.steps).reduce(max);
      if (baseline.maxDailySteps > 0 && currentMax > baseline.maxDailySteps * 1.5) {
        score -= 0.15;
      }
    }

    // New accounts with no baseline get a slight uncertainty penalty
    if (baseline.challengeCount < 2) {
      score -= 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Fetch or retrieve cached baseline data for a user from Firestore.
  Future<_UserBaseline> _getUserBaseline(String userId) async {
    final cached = _baselineCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt).inMinutes < 30) {
      return cached;
    }

    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return _UserBaseline.empty();
      }

      final userData = userDoc.data()!;
      final totalSteps = (userData['totalSteps'] ?? 0) as int;
      final totalChallenges = (userData['totalChallenges'] ?? 0) as int;
      final createdAt = (userData['createdAt'] as Timestamp?)?.toDate();

      // Estimate daily average from total steps and account age
      int averageDailySteps = 7500; // fallback
      if (createdAt != null && totalSteps > 0) {
        final accountDays = DateTime.now().difference(createdAt).inDays;
        if (accountDays > 0) {
          averageDailySteps = totalSteps ~/ accountDays;
        }
      }

      // Fetch recent challenge history to get more accurate baseline
      int maxDailySteps = 0;
      final recentChallenges = await _db
          .collection('challenges')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('updatedAt', descending: true)
          .limit(5)
          .get();

      for (final doc in recentChallenges.docs) {
        final data = doc.data();
        final isCreator = data['creatorId'] == userId;
        final historyField =
            isCreator ? 'creatorStepHistory' : 'opponentStepHistory';
        final historyList = data[historyField] as List<dynamic>? ?? [];

        for (final entry in historyList) {
          final steps = (entry as Map<String, dynamic>)['steps'] as int? ?? 0;
          if (steps > maxDailySteps) maxDailySteps = steps;
        }
      }

      final baseline = _UserBaseline(
        averageDailySteps: averageDailySteps,
        maxDailySteps: maxDailySteps > 0 ? maxDailySteps : SUSPICIOUS_DAILY_STEPS,
        challengeCount: totalChallenges,
        fetchedAt: DateTime.now(),
      );
      _baselineCache[userId] = baseline;
      return baseline;
    } catch (_) {
      return _UserBaseline.empty();
    }
  }

  // ============================================
  // DEVICE & SENSOR VALIDATION
  // ============================================

  /// Validate device and sensor consistency.
  double _validateDeviceData(List<DailySteps> history) {
    if (history.isEmpty) return 0.5;

    double score = 1.0;

    // Multiple different sources is potentially suspicious
    final sources = history.map((d) => d.source).toSet();
    if (sources.length > 3) {
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

  // ============================================
  // HEART RATE CROSS-REFERENCE
  // ============================================

  /// Cross-reference step data with heart rate data.
  double _crossReferenceHeartRate(
    List<DailySteps> stepHistory,
    List<Map<String, dynamic>> heartRateData,
  ) {
    if (heartRateData.isEmpty) return 0.7;

    double score = 1.0;

    // 1. Check for HR data presence during high activity
    for (final day in stepHistory) {
      if (day.steps > 10000) {
        final dayHRData = heartRateData
            .where((hr) => hr['date']?.toString() == day.date)
            .toList();
        if (dayHRData.isEmpty) {
          score -= 0.1;
        }
      }
    }

    // 2. Analyze step-to-HR correlation
    final correlationScore =
        _calculateStepHRCorrelation(stepHistory, heartRateData);
    if (correlationScore < MIN_HR_CORRELATION) {
      score -= (MIN_HR_CORRELATION - correlationScore);
    }

    // 3. Check for physiologically impossible patterns
    final physiologyScore = _validateHeartRatePhysiology(heartRateData);
    if (physiologyScore < 0.7) {
      score -= (0.7 - physiologyScore);
    }

    // 4. Detect HR data manipulation patterns
    final manipulationScore = _detectHRManipulation(heartRateData);
    if (manipulationScore < 0.8) {
      score -= (0.8 - manipulationScore) * 0.5;
    }

    // 5. Verify HR response to step intensity
    final responseScore = _validateHRStepResponse(stepHistory, heartRateData);
    if (responseScore < 0.6) {
      score -= (0.6 - responseScore) * 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate Pearson correlation between step counts and average heart rate.
  double _calculateStepHRCorrelation(
    List<DailySteps> stepHistory,
    List<Map<String, dynamic>> heartRateData,
  ) {
    final matchedData = <Map<String, num>>[];

    for (final day in stepHistory) {
      final dayHR =
          heartRateData.where((hr) => hr['date'] == day.date).toList();
      if (dayHR.isNotEmpty) {
        final avgHR = dayHR
                .map((hr) => hr['value'] as num)
                .reduce((a, b) => a + b) /
            dayHR.length;
        matchedData.add({'steps': day.steps, 'hr': avgHR});
      }
    }

    if (matchedData.length < 3) return 0.7;

    final n = matchedData.length;
    final sumSteps =
        matchedData.map((d) => d['steps']!).reduce((a, b) => a + b);
    final sumHR = matchedData.map((d) => d['hr']!).reduce((a, b) => a + b);
    final sumStepsHR = matchedData
        .map((d) => d['steps']! * d['hr']!)
        .reduce((a, b) => a + b);
    final sumStepsSq = matchedData
        .map((d) => d['steps']! * d['steps']!)
        .reduce((a, b) => a + b);
    final sumHRSq = matchedData
        .map((d) => d['hr']! * d['hr']!)
        .reduce((a, b) => a + b);

    final numerator = (n * sumStepsHR) - (sumSteps * sumHR);
    final denominator = sqrt(((n * sumStepsSq) - (sumSteps * sumSteps)) *
        ((n * sumHRSq) - (sumHR * sumHR)));

    if (denominator == 0) return 0.5;

    final correlation = numerator / denominator;
    return ((correlation + 1) / 2).clamp(0.0, 1.0);
  }

  /// Validate that heart rate patterns are physiologically possible.
  double _validateHeartRatePhysiology(
      List<Map<String, dynamic>> heartRateData) {
    if (heartRateData.isEmpty) return 0.8;

    double score = 1.0;

    for (final hr in heartRateData) {
      final value = hr['value'] as int;
      if (value < 30 || value > 220) {
        return 0.0;
      }
      if (value > MAX_HR_SUSTAINED) {
        score -= 0.1;
      }
    }

    final hrValues = heartRateData.map((hr) => hr['value'] as int).toList();
    final hrVariance = _calculateVariance(hrValues);
    if (hrVariance < 10) {
      score -= 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Detect patterns that suggest HR data manipulation (copy-paste, linear).
  double _detectHRManipulation(List<Map<String, dynamic>> heartRateData) {
    if (heartRateData.length < 5) return 0.8;

    double score = 1.0;

    final hrValues = heartRateData.map((hr) => hr['value']).toList();
    final uniqueRatio = hrValues.toSet().length / hrValues.length;
    if (uniqueRatio < 0.3) {
      score -= 0.4;
    }

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
      score -= 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Validate that HR responds appropriately to step intensity.
  double _validateHRStepResponse(
    List<DailySteps> stepHistory,
    List<Map<String, dynamic>> heartRateData,
  ) {
    double score = 1.0;

    for (final day in stepHistory) {
      final dayHR =
          heartRateData.where((hr) => hr['date'] == day.date).toList();
      if (dayHR.isEmpty) continue;

      final maxHR = dayHR.map((hr) => hr['value'] as int).reduce(max);
      final avgHR = dayHR.map((hr) => hr['value'] as int).reduce((a, b) => a + b) /
          dayHR.length;

      if (day.steps > 15000 && maxHR < 110) {
        score -= 0.15;
      }
      if (day.steps > 25000 && avgHR < 90) {
        score -= 0.2;
      }
      if (day.steps < 3000 && avgHR > 120) {
        score -= 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================
  // THRESHOLD CHECKS
  // ============================================

  /// Basic threshold validation against human limits.
  double _checkThresholds(List<DailySteps> history) {
    if (history.isEmpty) return 0.5;

    double score = 1.0;

    for (final day in history) {
      if (day.steps > MAX_DAILY_STEPS) {
        return 0.0;
      } else if (day.steps > SUSPICIOUS_DAILY_STEPS) {
        score -= 0.2;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================
  // BENFORD'S LAW ANALYSIS
  // ============================================

  /// Benford's Law: the leading digit distribution of naturally occurring
  /// numbers follows a predictable logarithmic pattern. Fabricated data
  /// typically has a uniform leading-digit distribution.
  double _analyzeBenfordsLaw(List<DailySteps> history) {
    final significantSteps = history.where((d) => d.steps >= 10).toList();
    if (significantSteps.length < 7) return 0.8; // Not enough data

    // Count leading digits
    final digitCounts = List.filled(9, 0);
    for (final day in significantSteps) {
      final leading = int.parse(day.steps.toString()[0]);
      if (leading >= 1 && leading <= 9) {
        digitCounts[leading - 1]++;
      }
    }

    final total = significantSteps.length;

    // Chi-squared goodness-of-fit test against Benford's distribution
    double chiSquared = 0;
    for (int i = 0; i < 9; i++) {
      final observed = digitCounts[i] / total;
      final expected = _benfordExpected[i];
      chiSquared += pow(observed - expected, 2) / expected;
    }

    // Convert chi-squared to a 0-1 score. Chi-squared > 20 with 8 df
    // has p < 0.01 (strong evidence of non-Benford distribution).
    // Scale: 0 = perfect Benford, 20+ = clearly fabricated.
    final score = (1.0 - (chiSquared / 30.0)).clamp(0.0, 1.0);
    return score;
  }

  // ============================================
  // VELOCITY ANALYSIS
  // ============================================

  /// Check if the implied step-per-hour rate is physically possible.
  /// A person walking briskly takes ~120 steps/min = 7200/hr.
  /// Running is ~180 steps/min = 10800/hr. Sustained rates above
  /// ~12000 steps/hr are physiologically implausible.
  double _analyzeVelocity(List<DailySteps> history) {
    if (history.isEmpty) return 0.8;

    double score = 1.0;

    for (final day in history) {
      if (day.steps == 0) continue;

      // Assume a generous 16 waking hours per day
      final stepsPerHour = day.steps / 16.0;

      if (stepsPerHour > MAX_STEPS_PER_HOUR) {
        score -= 0.3;
      } else if (stepsPerHour > SUSPICIOUS_STEPS_PER_HOUR) {
        score -= 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================
  // TIME-SERIES AUTOCORRELATION
  // ============================================

  /// Detect suspicious periodic patterns in step data using lag-1
  /// autocorrelation. Legitimate step data has moderate autocorrelation
  /// (people are somewhat consistent day-to-day). Extremely high
  /// autocorrelation (>0.95) suggests copy-paste or generated data.
  /// Near-zero or negative autocorrelation in a long series is also unusual.
  double _analyzeAutocorrelation(List<DailySteps> history) {
    if (history.length < 5) return 0.8; // Not enough data

    final steps = history.map((d) => d.steps.toDouble()).toList();
    final n = steps.length;
    final mean = steps.reduce((a, b) => a + b) / n;

    // Lag-1 autocorrelation
    double numerator = 0;
    double denominator = 0;
    for (int i = 0; i < n; i++) {
      denominator += pow(steps[i] - mean, 2);
      if (i < n - 1) {
        numerator += (steps[i] - mean) * (steps[i + 1] - mean);
      }
    }

    if (denominator == 0) return 0.3; // All identical values

    final autocorrelation = numerator / denominator;

    // Suspiciously perfect autocorrelation (copy-paste data)
    if (autocorrelation > 0.95) {
      return 0.2;
    }

    // Very high autocorrelation (likely generated sequence)
    if (autocorrelation > 0.85) {
      return 0.5;
    }

    // Normal range: legitimate data usually falls between -0.3 and 0.8
    return 1.0;
  }

  // ============================================
  // DATA FRESHNESS ANALYSIS
  // ============================================

  /// Verify that data sync timestamps are reasonable. Legitimate health
  /// data is synced regularly; long delays between the data date and
  /// sync time may indicate retroactive fabrication.
  double _analyzeDataFreshness(List<DailySteps> history) {
    if (history.isEmpty) return 0.8;

    double score = 1.0;
    int staleCount = 0;

    for (final day in history) {
      try {
        final dataDate = DateTime.parse(day.date);
        final syncTime = day.syncedAt;
        final delayHours = syncTime.difference(dataDate).inHours;

        if (delayHours > MAX_SYNC_DELAY_HOURS) {
          staleCount++;
        } else if (delayHours > SUSPICIOUS_SYNC_DELAY_HOURS) {
          staleCount++;
        }

        // Data synced before the date it supposedly represents is very suspicious
        if (delayHours < -1) {
          return 0.1;
        }
      } catch (_) {
        // Skip unparseable dates
      }
    }

    if (history.isNotEmpty) {
      final staleRate = staleCount / history.length;
      if (staleRate > 0.5) {
        score -= 0.3;
      } else if (staleRate > 0.2) {
        score -= 0.15;
      }
    }

    // Check if all entries were synced at the exact same time (bulk fabrication)
    if (history.length >= 3) {
      final syncTimes = history.map((d) => d.syncedAt.millisecondsSinceEpoch).toSet();
      if (syncTimes.length == 1) {
        score -= 0.2; // All data synced at same instant is suspicious
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================
  // COMPOSITE SCORING
  // ============================================

  /// Calculate weighted composite score from all analysis factors.
  double _calculateCompositeScore(Map<String, double> scores) {
    final weights = {
      'pattern': 0.15,
      'anomaly': 0.15,
      'behavior': 0.12,
      'device': 0.10,
      'heartRate': 0.10,
      'reputation': 0.08,
      'threshold': 0.08,
      'benford': 0.07,
      'velocity': 0.07,
      'autocorrelation': 0.04,
      'freshness': 0.04,
    };

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    scores.forEach((key, value) {
      final weight = weights[key] ?? 0.05;
      weightedSum += value * weight;
      totalWeight += weight;
    });

    return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
  }

  /// Get action recommendation based on score.
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

  // ============================================
  // USER REPUTATION
  // ============================================

  /// Calculate user reputation score from Firestore profile data.
  /// Considers anti-cheat history, challenge count, account age,
  /// and verification status.
  Future<double> calculateUserReputation(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.5;

      final data = userDoc.data()!;
      final storedScore = (data['antiCheatScore'] as num?)?.toDouble();
      if (storedScore != null) return storedScore.clamp(0.0, 1.0);

      // Build reputation from profile signals
      double reputation = 0.7; // base

      final totalChallenges = (data['totalChallenges'] ?? 0) as int;
      if (totalChallenges > 10) {
        reputation += 0.1; // experienced user
      } else if (totalChallenges < 2) {
        reputation -= 0.1; // new user penalty
      }

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final accountAgeDays = DateTime.now().difference(createdAt).inDays;
        if (accountAgeDays > 90) {
          reputation += 0.05; // established account
        } else if (accountAgeDays < 7) {
          reputation -= 0.1; // brand new account
        }
      }

      final isVerified = (data['isVerified'] ?? false) as bool;
      if (isVerified) {
        reputation += 0.05;
      }

      return reputation.clamp(0.0, 1.0);
    } catch (_) {
      return 0.7; // Default on error
    }
  }

  // ============================================
  // UTILITY
  // ============================================

  /// Calculate statistical variance.
  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
}

/// Cached baseline data for a user.
class _UserBaseline {
  final int averageDailySteps;
  final int maxDailySteps;
  final int challengeCount;
  final DateTime fetchedAt;

  _UserBaseline({
    required this.averageDailySteps,
    required this.maxDailySteps,
    required this.challengeCount,
    required this.fetchedAt,
  });

  factory _UserBaseline.empty() => _UserBaseline(
        averageDailySteps: 7500,
        maxDailySteps: 30000,
        challengeCount: 0,
        fetchedAt: DateTime.now(),
      );
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
