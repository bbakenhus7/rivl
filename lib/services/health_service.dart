// services/health_service.dart
// Real HealthKit / Health Connect integration via the `health` package

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import '../models/challenge_model.dart';
import '../models/health_metrics.dart';

/// Reason why a health data fetch failed or returned demo data.
enum HealthErrorReason {
  /// Device is locked — iOS requires unlock to read HealthKit.
  deviceLocked,

  /// User denied health permissions or hasn't granted them yet.
  /// NOTE: HealthKit cannot distinguish "denied" from "no data" for read
  /// access (Gotcha #2). This is set when authorization explicitly failed.
  unauthorized,

  /// Health Connect app is not installed (Android only).
  healthConnectMissing,

  /// Generic fetch error (network, timeout, unknown platform exception).
  fetchError,
}

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;

  /// The reason for the most recent failure, or null if the last operation succeeded.
  HealthErrorReason? _lastErrorReason;

  bool get isAuthorized => _isAuthorized;
  HealthErrorReason? get lastErrorReason => _lastErrorReason;

  /// Whether the current platform supports the health package.
  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android);

  // HealthKit / Health Connect data types we need to read.
  // Note: VO2 max is not yet supported by the health package.
  // DISTANCE_DELTA is Android-only; use DISTANCE_WALKING_RUNNING on iOS.
  static List<HealthDataType> get _readTypes => [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    if (defaultTargetPlatform == TargetPlatform.iOS)
      HealthDataType.DISTANCE_WALKING_RUNNING
    else
      HealthDataType.DISTANCE_DELTA,
    if (defaultTargetPlatform == TargetPlatform.iOS)
      HealthDataType.DISTANCE_CYCLING,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_AWAKE,
    if (defaultTargetPlatform == TargetPlatform.iOS)
      HealthDataType.SLEEP_IN_BED,
    if (defaultTargetPlatform == TargetPlatform.iOS)
      HealthDataType.EXERCISE_TIME,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.WORKOUT,
  ];

  // ============================================
  // AUTHORIZATION
  // ============================================

  Future<bool> requestAuthorization() async {
    if (!_isSupported) {
      _isAuthorized = false;
      return false;
    }

    try {
      // Configure the health plugin (required for Health Connect on Android).
      await _health.configure();

      final permissions = _readTypes.map((_) => HealthDataAccess.READ).toList();
      _isAuthorized = await _health.requestAuthorization(
        _readTypes,
        permissions: permissions,
      );
      if (!_isAuthorized) {
        _lastErrorReason = HealthErrorReason.unauthorized;
      } else {
        _lastErrorReason = null;
      }
      return _isAuthorized;
    } on PlatformException catch (e) {
      debugPrint('HealthService: PlatformException during auth: ${e.code} — ${e.message}');
      _isAuthorized = false;
      // Health Connect may not be installed on Android.
      if (e.message?.contains('Health Connect') == true ||
          e.code == 'HEALTH_CONNECT_NOT_AVAILABLE') {
        _lastErrorReason = HealthErrorReason.healthConnectMissing;
      } else {
        _lastErrorReason = HealthErrorReason.unauthorized;
      }
      return false;
    } catch (e) {
      debugPrint('HealthService: authorization error: $e');
      _isAuthorized = false;
      _lastErrorReason = HealthErrorReason.fetchError;
      return false;
    }
  }

  Future<bool> checkAuthorization() async {
    if (!_isSupported) return false;

    try {
      final hasPerms = await _health.hasPermissions(_readTypes);
      _isAuthorized = hasPerms ?? false;
      return _isAuthorized;
    } catch (e) {
      // checkAuthorization error — returning cached state
      return _isAuthorized;
    }
  }

  // ============================================
  // COMPREHENSIVE HEALTH DATA
  // ============================================

  Future<HealthMetrics> getHealthMetrics() async {
    if (!_isSupported || !_isAuthorized) {
      return HealthMetrics.demo();
    }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final yesterday = now.subtract(const Duration(hours: 24));

      // Point-in-time metrics only need most recent value (fetch from midnight).
      // Sleep needs 24h lookback for overnight coverage (fetch from yesterday).
      // Distance & calories use aggregate API to prevent double-counting.
      const pointInTimeTypes = [
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BLOOD_OXYGEN,
      ];
      const sleepTypes = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_AWAKE,
      ];

      // Fetch all data in parallel for best performance.
      // Filter out manually entered data to prevent cheating.
      const manualFilter = [RecordingMethod.manual, RecordingMethod.unknown];

      final results = await Future.wait([
        _health.getHealthDataFromTypes(
          types: pointInTimeTypes,
          startTime: midnight,
          endTime: now,
          recordingMethodsToFilter: manualFilter,
        ),                                                    // [0]
        _health.getHealthDataFromTypes(
          types: sleepTypes,
          startTime: yesterday,
          endTime: now,
          recordingMethodsToFilter: manualFilter,
        ),                                                    // [1]
        _fetchWeeklySteps(),                                  // [2]
        _fetchRecentWorkouts(),                               // [3]
        _getAggregateDistance(midnight, now),                  // [4]
        _getAggregateCalories(midnight, now),                 // [5]
        _health.getTotalStepsInInterval(midnight, now),       // [6]
        _getAggregateExerciseMinutes(midnight, now),          // [7]
        _getSleepInBedData(yesterday, now),                   // [8]
      ]);

      final pointInTimeData = Health().removeDuplicates(
        results[0] as List<HealthDataPoint>,
      );
      final sleepData = results[1] as List<HealthDataPoint>;
      final dataPoints = [...pointInTimeData, ...sleepData];
      final weeklySteps = results[2] as List<DailySteps>;
      final recentWorkouts = results[3] as List<WorkoutData>;
      final distanceMeters = results[4] as double;
      var activeCalories = results[5] as int;
      var steps = (results[6] as int?) ?? 0;
      final exerciseMinutes = results[7] as int;
      final inBedData = results[8] as List<HealthDataPoint>;
      var distanceMiles = distanceMeters * 0.000621371;

      // Plausibility checks: cap implausible values to prevent bad data
      // from corrupting the UI or health score calculations.
      if (!isStepsPlausible(steps)) {
        debugPrint('HealthService: implausible steps ($steps) — capping at 50,000');
        steps = steps.clamp(0, 50000);
      }
      if (!isCaloriesPlausible(activeCalories)) {
        debugPrint('HealthService: implausible calories ($activeCalories) — capping at 4,000');
        activeCalories = activeCalories.clamp(0, 4000);
      }
      if (!isDistancePlausible(distanceMiles)) {
        debugPrint('HealthService: implausible distance ($distanceMiles mi) — capping at 60');
        distanceMiles = distanceMiles.clamp(0, 60);
      }

      // Extract most recent values for point-in-time metrics
      final heartRate = _mostRecentValue(dataPoints, HealthDataType.HEART_RATE)?.toInt() ?? 0;
      final restingHeartRate = _mostRecentValue(dataPoints, HealthDataType.RESTING_HEART_RATE)?.toInt() ?? 0;
      final hrv = _mostRecentValue(dataPoints, HealthDataType.HEART_RATE_VARIABILITY_SDNN) ?? 0.0;
      // VO2 max is not yet supported by the health package — defaults to 0.
      const vo2Max = 0.0;
      final respiratoryRate = _mostRecentValue(dataPoints, HealthDataType.RESPIRATORY_RATE) ?? 0.0;
      final bloodOxygen = _mostRecentValue(dataPoints, HealthDataType.BLOOD_OXYGEN) ?? 0.0;

      // Granular sleep breakdown with per-stage interval merging
      final sleepBreakdown = _calculateSleepBreakdown(sleepData, yesterday, now);
      final timeInBed = _calculateTimeInBed(inBedData, yesterday, now);

      // Use stage breakdown sum if available, otherwise fall back to
      // merged total (covers devices that only report SLEEP_ASLEEP).
      final sleepFromStages = sleepBreakdown.deep + sleepBreakdown.rem + sleepBreakdown.light;
      var sleepHours = sleepFromStages > 0
          ? sleepFromStages
          : _calculateSleepHours(sleepData, yesterday, now);
      if (!isSleepPlausible(sleepHours)) {
        debugPrint('HealthService: implausible sleep ($sleepHours h) — capping at 24');
        sleepHours = sleepHours.clamp(0, 24);
      }

      _lastErrorReason = null; // Clear any previous error on success
      return HealthMetrics(
        steps: steps,
        heartRate: heartRate,
        restingHeartRate: restingHeartRate,
        hrv: hrv,
        activeCalories: activeCalories,
        distance: distanceMiles,
        sleepHours: sleepHours,
        deepSleepHours: sleepBreakdown.deep,
        remSleepHours: sleepBreakdown.rem,
        lightSleepHours: sleepBreakdown.light,
        awakeDuration: sleepBreakdown.awake,
        timeInBed: timeInBed,
        exerciseMinutes: exerciseMinutes,
        vo2Max: vo2Max,
        respiratoryRate: respiratoryRate,
        bloodOxygen: bloodOxygen,
        weeklySteps: weeklySteps,
        recentWorkouts: recentWorkouts,
        lastUpdated: now,
      );
    } on PlatformException catch (e) {
      debugPrint('HealthService: PlatformException in getHealthMetrics: ${e.code} — ${e.message}');
      // Gotcha #1: iOS requires device to be unlocked to read HealthKit.
      // The health package throws PlatformException when the device is locked.
      if (e.message?.toLowerCase().contains('locked') == true ||
          e.message?.toLowerCase().contains('protected') == true ||
          e.code == 'HEALTH_DATA_NOT_AVAILABLE') {
        _lastErrorReason = HealthErrorReason.deviceLocked;
      } else {
        _lastErrorReason = HealthErrorReason.fetchError;
      }
      return HealthMetrics.demo();
    } catch (e) {
      debugPrint('HealthService: getHealthMetrics error — returning demo data: $e');
      _lastErrorReason = HealthErrorReason.fetchError;
      return HealthMetrics.demo();
    }
  }

  // ============================================
  // CHALLENGE PROGRESS (multi-metric)
  // ============================================

  Future<({int total, List<DailySteps> history})> getProgressForChallenge({
    required GoalType goalType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isSupported || !_isAuthorized) {
      return _demoProgressForChallenge(goalType: goalType, startDate: startDate, endDate: endDate);
    }

    try {
      switch (goalType) {
        case GoalType.steps:
          return await _stepsProgressForRange(startDate, endDate);

        case GoalType.distance:
          return await _distanceProgressForRange(startDate, endDate);

        case GoalType.sleepDuration:
          return await _sleepProgressForRange(startDate, endDate);

        case GoalType.zone2Cardio:
          return await _zone2CardioProgressForRange(startDate, endDate);

        case GoalType.milePace:
          return await _bestPaceProgressForRange(startDate, endDate, maxDistanceMiles: 1.5);

        case GoalType.fiveKPace:
          return await _bestPaceProgressForRange(startDate, endDate, minDistanceMiles: 2.8, maxDistanceMiles: 4.0);

        case GoalType.tenKPace:
          return await _bestPaceProgressForRange(startDate, endDate, minDistanceMiles: 5.5, maxDistanceMiles: 7.5);

        case GoalType.rivlHealthScore:
          return await _rivlHealthScoreProgress(startDate, endDate);
      }
    } catch (e) {
      debugPrint('HealthService: getProgressForChallenge error for $goalType — returning demo data: $e');
      return _demoProgressForChallenge(goalType: goalType, startDate: startDate, endDate: endDate);
    }
  }

  // ============================================
  // LEGACY METHODS
  // ============================================

  Future<int> getTodaySteps() async {
    if (!_isSupported || !_isAuthorized) {
      return 5000 + Random().nextInt(5000);
    }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      return await _health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (e) {
      debugPrint('HealthService: getTodaySteps error: $e');
      return 0;
    }
  }

  Future<int> getStepsInRange(DateTime start, DateTime end) async {
    if (!_isSupported || !_isAuthorized) {
      final days = end.difference(start).inDays + 1;
      return days * 4000;
    }

    try {
      return await _health.getTotalStepsInInterval(start, end) ?? 0;
    } catch (e) {
      debugPrint('HealthService: getStepsInRange error: $e');
      return 0;
    }
  }

  Future<List<DailySteps>> getDailySteps(int days) async {
    if (!_isSupported || !_isAuthorized) {
      return _demoDailySteps(days);
    }

    try {
      return await _fetchDailyStepsForRange(days);
    } catch (e) {
      debugPrint('HealthService: getDailySteps error — returning demo data: $e');
      return _demoDailySteps(days);
    }
  }

  Future<List<DailySteps>> getStepsForChallenge(DateTime startDate, DateTime endDate) async {
    final days = endDate.difference(startDate).inDays + 1;
    if (!_isSupported || !_isAuthorized) {
      return _demoDailySteps(days);
    }

    try {
      final result = await _stepsProgressForRange(startDate, endDate);
      return result.history;
    } catch (e) {
      debugPrint('HealthService: getStepsForChallenge error — returning demo data: $e');
      return _demoDailySteps(days);
    }
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final days = await getDailySteps(7);
    final total = days.fold<int>(0, (s, d) => s + d.steps);
    return {
      'totalSteps': total,
      'averageSteps': days.isNotEmpty ? total ~/ days.length : 0,
      'bestDay': days.isNotEmpty ? days.map((d) => d.steps).reduce((a, b) => a > b ? a : b) : 0,
      'dailySteps': days,
    };
  }

  // ============================================
  // PRIVATE HELPERS — DATA EXTRACTION
  // ============================================

  /// Get the platform-appropriate source tag.
  String get _sourceTag {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'healthkit';
    if (defaultTargetPlatform == TargetPlatform.android) return 'health_connect';
    return 'demo';
  }

  /// Extract the numeric value from a HealthDataPoint.
  double _numericValue(HealthDataPoint point) {
    final val = point.value;
    if (val is NumericHealthValue) {
      return val.numericValue.toDouble();
    }
    return 0.0;
  }

  /// Find the most recent data point of a given type and return its value.
  double? _mostRecentValue(List<HealthDataPoint> points, HealthDataType type) {
    final matching = points.where((p) => p.type == type).toList();
    if (matching.isEmpty) return null;
    matching.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    return _numericValue(matching.first);
  }

  /// Calculate total sleep hours from sleep-stage data points.
  /// Merges overlapping intervals to prevent double-counting when
  /// both iPhone and Apple Watch record the same sleep session.
  double _calculateSleepHours(List<HealthDataPoint> points, DateTime from, DateTime to) {
    const sleepTypes = [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
    ];

    final intervals = <({DateTime start, DateTime end})>[];
    for (final point in points) {
      if (!sleepTypes.contains(point.type)) continue;
      if (point.dateFrom.isBefore(from) || point.dateTo.isAfter(to)) continue;
      intervals.add((start: point.dateFrom, end: point.dateTo));
    }
    return _mergedMinutes(intervals) / 60.0;
  }

  /// Merge overlapping time intervals and return total duration in minutes.
  /// Prevents double-counting when iPhone + Apple Watch both record data
  /// for the same time period.
  double _mergedMinutes(List<({DateTime start, DateTime end})> intervals) {
    if (intervals.isEmpty) return 0;
    intervals.sort((a, b) => a.start.compareTo(b.start));

    var totalMinutes = 0.0;
    var mergedStart = intervals.first.start;
    var mergedEnd = intervals.first.end;

    for (var i = 1; i < intervals.length; i++) {
      final interval = intervals[i];
      if (!interval.start.isAfter(mergedEnd)) {
        // Overlapping or adjacent — extend
        if (interval.end.isAfter(mergedEnd)) {
          mergedEnd = interval.end;
        }
      } else {
        // Gap — finalize previous, start new
        totalMinutes += mergedEnd.difference(mergedStart).inMinutes;
        mergedStart = interval.start;
        mergedEnd = interval.end;
      }
    }
    totalMinutes += mergedEnd.difference(mergedStart).inMinutes;

    return totalMinutes;
  }

  /// Fetch aggregate distance in meters via HKStatisticsCollectionQuery.
  /// Uses .cumulativeSum which correctly deduplicates overlapping samples
  /// from iPhone + Apple Watch — the same approach Strava uses.
  Future<double> _getAggregateDistance(DateTime start, DateTime end) async {
    final distanceType = defaultTargetPlatform == TargetPlatform.iOS
        ? HealthDataType.DISTANCE_WALKING_RUNNING
        : HealthDataType.DISTANCE_DELTA;
    final data = await _health.getHealthIntervalDataFromTypes(
      startDate: start,
      endDate: end,
      types: [distanceType],
      interval: 86400, // 1 day in seconds — single bucket covers the range
    );
    double meters = 0;
    for (final dp in data) {
      if (dp.value is NumericHealthValue) {
        meters += (dp.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    return meters;
  }

  /// Fetch aggregate active calories via HKStatisticsCollectionQuery.
  /// Uses .cumulativeSum which correctly deduplicates overlapping samples
  /// from iPhone + Apple Watch — the same approach Strava uses.
  Future<int> _getAggregateCalories(DateTime start, DateTime end) async {
    final data = await _health.getHealthIntervalDataFromTypes(
      startDate: start,
      endDate: end,
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      interval: 86400, // 1 day in seconds — single bucket covers the range
    );
    double calories = 0;
    for (final dp in data) {
      if (dp.value is NumericHealthValue) {
        calories += (dp.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    return calories.toInt();
  }

  /// Fetch aggregate exercise minutes via HKStatisticsCollectionQuery (iOS only).
  /// Maps to Apple's Exercise ring — minutes of activity above a brisk walk.
  Future<int> _getAggregateExerciseMinutes(DateTime start, DateTime end) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return 0;
    try {
      final data = await _health.getHealthIntervalDataFromTypes(
        startDate: start,
        endDate: end,
        types: [HealthDataType.EXERCISE_TIME],
        interval: 86400,
      );
      double minutes = 0;
      for (final dp in data) {
        if (dp.value is NumericHealthValue) {
          minutes += (dp.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return minutes.toInt();
    } catch (e) {
      debugPrint('HealthService: exercise minutes fetch failed: $e');
      return 0;
    }
  }

  /// Fetch SLEEP_IN_BED data points (iOS only). Returns raw data points
  /// for interval merging to compute total time in bed.
  Future<List<HealthDataPoint>> _getSleepInBedData(DateTime start, DateTime end) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return [];
    try {
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_IN_BED],
        startTime: start,
        endTime: end,
        recordingMethodsToFilter: const [RecordingMethod.manual, RecordingMethod.unknown],
      );
    } catch (e) {
      debugPrint('HealthService: sleep in-bed fetch failed: $e');
      return [];
    }
  }

  /// Calculate granular sleep breakdown from sleep-stage data points.
  /// Each stage uses interval merging independently to prevent
  /// double-counting from iPhone + Apple Watch.
  ({double deep, double rem, double light, double awake}) _calculateSleepBreakdown(
    List<HealthDataPoint> points, DateTime from, DateTime to,
  ) {
    double hoursForType(HealthDataType type) {
      final intervals = <({DateTime start, DateTime end})>[];
      for (final point in points) {
        if (point.type != type) continue;
        if (point.dateFrom.isBefore(from) || point.dateTo.isAfter(to)) continue;
        intervals.add((start: point.dateFrom, end: point.dateTo));
      }
      return _mergedMinutes(intervals) / 60.0;
    }

    return (
      deep: hoursForType(HealthDataType.SLEEP_DEEP),
      rem: hoursForType(HealthDataType.SLEEP_REM),
      light: hoursForType(HealthDataType.SLEEP_LIGHT),
      awake: hoursForType(HealthDataType.SLEEP_AWAKE),
    );
  }

  /// Calculate total time in bed from SLEEP_IN_BED data points.
  /// Uses interval merging for cross-device deduplication.
  double _calculateTimeInBed(List<HealthDataPoint> inBedData, DateTime from, DateTime to) {
    final intervals = <({DateTime start, DateTime end})>[];
    for (final point in inBedData) {
      if (point.dateFrom.isBefore(from) || point.dateTo.isAfter(to)) continue;
      intervals.add((start: point.dateFrom, end: point.dateTo));
    }
    return _mergedMinutes(intervals) / 60.0;
  }

  /// Fetch aggregate cycling distance in meters via HKStatisticsCollectionQuery (iOS only).
  Future<double> _getAggregateCyclingDistance(DateTime start, DateTime end) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return 0;
    try {
      final data = await _health.getHealthIntervalDataFromTypes(
        startDate: start,
        endDate: end,
        types: [HealthDataType.DISTANCE_CYCLING],
        interval: 86400,
      );
      double meters = 0;
      for (final dp in data) {
        if (dp.value is NumericHealthValue) {
          meters += (dp.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return meters;
    } catch (e) {
      debugPrint('HealthService: cycling distance fetch failed: $e');
      return 0;
    }
  }

  // ============================================
  // PRIVATE HELPERS — WEEKLY / RANGE QUERIES
  // ============================================

  /// Fetch step totals for each of the last 7 days.
  Future<List<DailySteps>> _fetchWeeklySteps() async {
    final now = DateTime.now();
    final results = <DailySteps>[];

    for (var i = 6; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEnd = i == 0
          ? now
          : dayStart.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;
      results.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: steps,
        source: _sourceTag,
        syncedAt: now,
        verified: true,
      ));
    }

    return results;
  }

  /// Fetch step totals for each day in a given range.
  Future<List<DailySteps>> _fetchDailyStepsForRange(int days) async {
    final now = DateTime.now();
    final results = <DailySteps>[];

    for (var i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEnd = i == 0
          ? now
          : dayStart.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;
      results.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: steps,
        source: _sourceTag,
        syncedAt: now,
        verified: true,
      ));
    }

    return results;
  }

  /// Fetch recent workouts from the last 7 days.
  Future<List<WorkoutData>> _fetchRecentWorkouts() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final dataPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: weekAgo,
        endTime: now,
        recordingMethodsToFilter: const [RecordingMethod.manual, RecordingMethod.unknown],
      );

      final workouts = <WorkoutData>[];
      for (final point in dataPoints) {
        if (point.value is WorkoutHealthValue) {
          final workout = point.value as WorkoutHealthValue;
          final duration = point.dateTo.difference(point.dateFrom);
          final distanceMiles =
              (workout.totalDistance ?? 0).toDouble() * 0.000621371;
          final durationMinutes = duration.inMinutes;

          // Derive pace from distance and duration (for distance-based workouts)
          Duration? avgPace;
          double? avgSpeed;
          if (distanceMiles > 0 && durationMinutes > 0) {
            final paceSeconds = (duration.inSeconds / distanceMiles).round();
            avgPace = Duration(seconds: paceSeconds);
            avgSpeed = distanceMiles / (duration.inSeconds / 3600);
          }

          workouts.add(WorkoutData(
            type: workout.workoutActivityType.name.toUpperCase(),
            duration: duration,
            calories: workout.totalEnergyBurned ?? 0,
            distance: distanceMiles,
            date: point.dateFrom,
            elapsedTime: duration,
            activeCalories: workout.totalEnergyBurned ?? 0,
            totalCalories: workout.totalEnergyBurned != null
                ? ((workout.totalEnergyBurned!) * 1.15).round()
                : null,
            avgPace: avgPace,
            avgSpeed: avgSpeed,
          ));
        }
      }

      // Sort newest first, limit to 5
      workouts.sort((a, b) => b.date.compareTo(a.date));
      return workouts.take(5).toList();
    } catch (e) {
      debugPrint('HealthService: _fetchRecentWorkouts error: $e');
      return [];
    }
  }

  // ============================================
  // PRIVATE HELPERS — CHALLENGE PROGRESS
  // ============================================

  Future<({int total, List<DailySteps> history})> _stepsProgressForRange(
    DateTime startDate, DateTime endDate,
  ) async {
    final now = DateTime.now();
    final days = endDate.difference(startDate).inDays + 1;
    final history = <DailySteps>[];

    for (var i = 0; i < days; i++) {
      final dayStart = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
      if (dayStart.isAfter(now)) break;
      final dayEnd = dayStart.add(const Duration(days: 1)).isAfter(now)
          ? now
          : dayStart.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;

      // Fetch cross-validation metrics for this day.
      // Use aggregate API for distance & calories to prevent double-counting.
      double? distanceMiles;
      int? activeCalories;
      int? avgHeartRate;
      try {
        final crossResults = await Future.wait([
          _getAggregateDistance(dayStart, dayEnd),
          _getAggregateCalories(dayStart, dayEnd),
          // HR uses interval API which returns platform-deduplicated
          // .discreteAverage — no manual averaging needed.
          _health.getHealthIntervalDataFromTypes(
            startDate: dayStart,
            endDate: dayEnd,
            types: [HealthDataType.HEART_RATE],
            interval: 86400,
          ),
        ]);

        final distanceMeters = crossResults[0] as double;
        if (distanceMeters > 0) {
          distanceMiles = distanceMeters * 0.000621371;
        }

        final calTotal = crossResults[1] as int;
        if (calTotal > 0) {
          activeCalories = calTotal;
        }

        final hrData = crossResults[2] as List<HealthDataPoint>;
        if (hrData.isNotEmpty && hrData.first.value is NumericHealthValue) {
          avgHeartRate = (hrData.first.value as NumericHealthValue)
              .numericValue.toDouble().round();
        }
      } catch (_) {
        // Cross-ref metrics are best-effort; steps are the primary data
      }

      // Mark as verified only if steps pass plausibility + cross-validation
      final plausible = isStepsPlausible(steps) &&
          (distanceMiles == null || isStepsDistanceConsistent(steps, distanceMiles));

      history.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: steps,
        source: _sourceTag,
        syncedAt: now,
        verified: plausible,
        distance: distanceMiles,
        activeCalories: activeCalories,
        avgHeartRate: avgHeartRate,
      ));
    }

    final total = history.fold<int>(0, (sum, d) => sum + d.steps);
    return (total: total, history: history);
  }

  Future<({int total, List<DailySteps> history})> _distanceProgressForRange(
    DateTime startDate, DateTime endDate,
  ) async {
    final now = DateTime.now();
    final days = endDate.difference(startDate).inDays + 1;
    final history = <DailySteps>[];

    for (var i = 0; i < days; i++) {
      final dayStart = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
      if (dayStart.isAfter(now)) break;
      final dayEnd = dayStart.add(const Duration(days: 1)).isAfter(now)
          ? now
          : dayStart.add(const Duration(days: 1));

      // Walking/running distance (deduplicated via aggregate API)
      final walkRunMeters = await _getAggregateDistance(dayStart, dayEnd);

      // Add cycling distance on iOS (separate HealthKit type)
      final cyclingMeters = await _getAggregateCyclingDistance(dayStart, dayEnd);

      final totalMeters = walkRunMeters + cyclingMeters;
      final miles = (totalMeters * 0.000621371).round();
      history.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: miles, // reusing steps field for miles (int)
        source: _sourceTag,
        syncedAt: now,
      ));
    }

    final total = history.fold<int>(0, (sum, d) => sum + d.steps);
    return (total: total, history: history);
  }

  Future<({int total, List<DailySteps> history})> _sleepProgressForRange(
    DateTime startDate, DateTime endDate,
  ) async {
    final now = DateTime.now();
    final days = endDate.difference(startDate).inDays + 1;
    final history = <DailySteps>[];
    const sleepTypes = [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_AWAKE,
    ];

    for (var i = 0; i < days; i++) {
      final dayStart = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
      if (dayStart.isAfter(now)) break;
      final dayEnd = dayStart.add(const Duration(days: 1)).isAfter(now)
          ? now
          : dayStart.add(const Duration(days: 1));

      final dataPointsRaw = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: dayStart,
        endTime: dayEnd,
        recordingMethodsToFilter: const [RecordingMethod.manual, RecordingMethod.unknown],
      );

      // Merge overlapping intervals to prevent double-counting from
      // iPhone + Apple Watch recording the same sleep session.
      final intervals = dataPointsRaw
          .map((p) => (start: p.dateFrom, end: p.dateTo))
          .toList();
      final totalMinutes = _mergedMinutes(intervals);
      final hours = (totalMinutes / 60).round();

      history.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: hours, // reusing steps field for sleep hours (int)
        source: _sourceTag,
        syncedAt: now,
      ));
    }

    final total = history.fold<int>(0, (sum, d) => sum + d.steps);
    return (total: total, history: history);
  }

  Future<({int total, List<DailySteps> history})> _latestMetricProgress(
    HealthDataType type, DateTime startDate, DateTime endDate,
  ) async {
    final now = DateTime.now();

    final dataPoints = await _health.getHealthDataFromTypes(
      types: [type],
      startTime: startDate,
      endTime: endDate.isAfter(now) ? now : endDate,
      recordingMethodsToFilter: const [RecordingMethod.manual, RecordingMethod.unknown],
    );

    if (dataPoints.isEmpty) {
      return (total: 0, history: <DailySteps>[]);
    }

    dataPoints.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    final latestValue = (_numericValue(dataPoints.first) * 10).round(); // store as x10 int

    final history = [
      DailySteps(
        date: DateTime.now().toIso8601String().split('T').first,
        steps: latestValue,
        source: _sourceTag,
        syncedAt: now,
      ),
    ];
    return (total: latestValue, history: history);
  }

  // ============================================
  // ZONE 2 CARDIO PROGRESS
  // ============================================

  /// Calculate daily time (in minutes) spent in heart rate zone 2 (60-70% of estimated max HR).
  /// Estimated max HR = 220 - age. Without age, we use a fixed zone of 108-132 bpm
  /// (approximation for a 30-year-old: max HR 190, zone 2 = 60-70% = 114-133).
  Future<({int total, List<DailySteps> history})> _zone2CardioProgressForRange(
    DateTime startDate, DateTime endDate,
  ) async {
    final now = DateTime.now();
    final days = endDate.difference(startDate).inDays + 1;
    final history = <DailySteps>[];

    // Use resting heart rate to estimate zone 2 boundaries.
    // Fallback: zone 2 is roughly 108-132 bpm for an average adult.
    const zone2Low = 108.0;
    const zone2High = 132.0;

    for (var i = 0; i < days; i++) {
      final dayStart = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
      if (dayStart.isAfter(now)) break;
      final dayEnd = dayStart.add(const Duration(days: 1)).isAfter(now)
          ? now
          : dayStart.add(const Duration(days: 1));

      var zone2Minutes = 0;
      try {
        final hrDataRaw = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: dayStart,
          endTime: dayEnd,
          recordingMethodsToFilter: const [RecordingMethod.manual, RecordingMethod.unknown],
        );

        // Use a minute-set to prevent double-counting when iPhone + Apple
        // Watch both record HR data for overlapping time periods.
        final zone2MinuteSet = <int>{};
        for (final point in hrDataRaw) {
          final bpm = _numericValue(point);
          if (bpm >= zone2Low && bpm <= zone2High) {
            final startMin = point.dateFrom.millisecondsSinceEpoch ~/ 60000;
            final endMin = point.dateTo.millisecondsSinceEpoch ~/ 60000;
            if (startMin == endMin) {
              zone2MinuteSet.add(startMin);
            } else {
              for (var m = startMin; m < endMin; m++) {
                zone2MinuteSet.add(m);
              }
            }
          }
        }
        zone2Minutes = zone2MinuteSet.length;
      } catch (e) {
        debugPrint('HealthService: zone 2 HR fetch failed for $dayStart: $e');
      }

      history.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: zone2Minutes,
        source: _sourceTag,
        syncedAt: now,
      ));
    }

    final total = history.fold<int>(0, (sum, d) => sum + d.steps);
    return (total: total, history: history);
  }

  // ============================================
  // PACE PROGRESS (RUNNING WORKOUTS)
  // ============================================

  /// Find the best (lowest) pace from running workouts in the given range.
  /// For mile pace, look for runs ~1 mile. For 5K/10K, filter by distance range.
  /// Returns pace in seconds as the total.
  Future<({int total, List<DailySteps> history})> _bestPaceProgressForRange(
    DateTime startDate, DateTime endDate, {
    double minDistanceMiles = 0.0,
    double maxDistanceMiles = double.infinity,
  }) async {
    final now = DateTime.now();
    final effectiveEnd = endDate.isAfter(now) ? now : endDate;

    try {
      final dataPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: effectiveEnd,
        recordingMethodsToFilter: const [RecordingMethod.manual, RecordingMethod.unknown],
      );

      int? bestPaceSeconds;

      for (final point in dataPoints) {
        if (point.value is! WorkoutHealthValue) continue;
        final workout = point.value as WorkoutHealthValue;

        // Only consider running workouts
        final activityName = workout.workoutActivityType.name.toUpperCase();
        if (!activityName.contains('RUNNING') && !activityName.contains('RUN')) continue;

        final distanceMiles = (workout.totalDistance ?? 0).toDouble() * 0.000621371;
        if (distanceMiles < minDistanceMiles || distanceMiles > maxDistanceMiles) continue;
        if (distanceMiles <= 0) continue;

        final durationSeconds = point.dateTo.difference(point.dateFrom).inSeconds;
        if (durationSeconds <= 0) continue;

        // Total time in seconds for the distance
        final paceSeconds = durationSeconds;

        if (bestPaceSeconds == null || paceSeconds < bestPaceSeconds) {
          bestPaceSeconds = paceSeconds;
        }
      }

      if (bestPaceSeconds == null) {
        return (total: 0, history: <DailySteps>[]);
      }

      final history = [
        DailySteps(
          date: now.toIso8601String().split('T').first,
          steps: bestPaceSeconds,
          source: _sourceTag,
          syncedAt: now,
        ),
      ];
      return (total: bestPaceSeconds, history: history);
    } catch (e) {
      debugPrint('HealthService: pace workout fetch failed: $e');
      return (total: 0, history: <DailySteps>[]);
    }
  }

  // ============================================
  // RIVL HEALTH SCORE PROGRESS
  // ============================================

  /// Compute the current RIVL Health Score by fetching a fresh HealthMetrics snapshot.
  Future<({int total, List<DailySteps> history})> _rivlHealthScoreProgress(
    DateTime startDate, DateTime endDate,
  ) async {
    try {
      final metrics = await getHealthMetrics();
      final score = metrics.rivlHealthScore;

      final history = [
        DailySteps(
          date: DateTime.now().toIso8601String().split('T').first,
          steps: score,
          source: _sourceTag,
          syncedAt: DateTime.now(),
        ),
      ];
      return (total: score, history: history);
    } catch (e) {
      debugPrint('HealthService: rivlHealthScore fetch failed: $e');
      return (total: 0, history: <DailySteps>[]);
    }
  }

  // ============================================
  // DEMO FALLBACKS
  // ============================================

  List<DailySteps> _demoDailySteps(int days) {
    final now = DateTime.now();
    final rnd = Random(42);
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      return DailySteps(
        date: date.toIso8601String().split('T').first,
        steps: 3000 + rnd.nextInt(7000),
        source: 'demo',
        syncedAt: now,
        verified: true,
      );
    });
  }

  Future<({int total, List<DailySteps> history})> _demoProgressForChallenge({
    required GoalType goalType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final days = endDate.difference(startDate).inDays + 1;
    final rnd = Random(42);

    switch (goalType) {
      case GoalType.steps:
        final history = List.generate(days, (i) {
          final date = startDate.add(Duration(days: i));
          return DailySteps(
            date: date.toIso8601String().split('T').first,
            steps: 3000 + rnd.nextInt(7000),
            source: 'demo',
            syncedAt: DateTime.now(),
          );
        });
        final total = history.fold<int>(0, (sum, d) => sum + d.steps);
        return (total: total, history: history);

      case GoalType.distance:
        final history = List.generate(days, (i) {
          final date = startDate.add(Duration(days: i));
          return DailySteps(
            date: date.toIso8601String().split('T').first,
            steps: 2 + rnd.nextInt(5),
            source: 'demo',
            syncedAt: DateTime.now(),
          );
        });
        final total = history.fold<int>(0, (sum, d) => sum + d.steps);
        return (total: total, history: history);

      case GoalType.sleepDuration:
        final history = List.generate(days, (i) {
          final date = startDate.add(Duration(days: i));
          return DailySteps(
            date: date.toIso8601String().split('T').first,
            steps: 6 + rnd.nextInt(3),
            source: 'demo',
            syncedAt: DateTime.now(),
          );
        });
        final total = history.fold<int>(0, (sum, d) => sum + d.steps);
        return (total: total, history: history);

      case GoalType.zone2Cardio:
        // Generate daily Zone 2 cardio minutes (15-45 min per day)
        final history = <DailySteps>[];
        for (int i = 0; i < days; i++) {
          final date = startDate.add(Duration(days: i));
          if (date.isAfter(DateTime.now())) break;
          history.add(DailySteps(
            date: date.toIso8601String().split('T').first,
            steps: 15 + rnd.nextInt(31), // 15-45 min of Zone 2 per day
            source: 'demo',
            syncedAt: DateTime.now(),
          ));
        }
        final total = history.fold<int>(0, (sum, d) => sum + d.steps);
        return (total: total, history: history);

      case GoalType.milePace:
        final best = 420 + rnd.nextInt(180);
        final history = [
          DailySteps(
            date: DateTime.now().toIso8601String().split('T').first,
            steps: best,
            source: 'demo',
            syncedAt: DateTime.now(),
          ),
        ];
        return (total: best, history: history);

      case GoalType.fiveKPace:
        final best = 1200 + rnd.nextInt(600);
        final history = [
          DailySteps(
            date: DateTime.now().toIso8601String().split('T').first,
            steps: best,
            source: 'demo',
            syncedAt: DateTime.now(),
          ),
        ];
        return (total: best, history: history);

      case GoalType.tenKPace:
        final best = 2400 + rnd.nextInt(1200);
        final history = [
          DailySteps(
            date: DateTime.now().toIso8601String().split('T').first,
            steps: best,
            source: 'demo',
            syncedAt: DateTime.now(),
          ),
        ];
        return (total: best, history: history);

      case GoalType.rivlHealthScore:
        final latest = 50 + rnd.nextInt(40);
        final history = [
          DailySteps(
            date: DateTime.now().toIso8601String().split('T').first,
            steps: latest,
            source: 'demo',
            syncedAt: DateTime.now(),
          ),
        ];
        return (total: latest, history: history);
    }
  }

  // ============================================
  // ANTI-CHEAT VALIDATION
  // ============================================

  /// Check if health data appears plausible. Returns true if the data
  /// passes basic sanity checks, false if it looks suspicious.
  /// Uses thresholds from sports science literature:
  ///   - Max ~50,000 steps/day (ultramarathon territory)
  ///   - Max ~4,000 active calories/day (extreme endurance event)
  ///   - Max 24h sleep (impossible but guards against bad data)
  bool isStepsPlausible(int steps) => steps >= 0 && steps <= 50000;

  bool isCaloriesPlausible(int calories) => calories >= 0 && calories <= 4000;

  bool isSleepPlausible(double hours) => hours >= 0 && hours <= 24;

  bool isDistancePlausible(double miles) => miles >= 0 && miles <= 60;

  /// Validate source legitimacy. Returns true if at least one trusted
  /// source contributed to the data.
  bool hasTrustedSource(List<String> sourceNames) {
    const trustedPatterns = [
      'com.apple.health',
      'com.apple.Health',
      'com.garmin.connect',
      'com.fitbit.',
      'com.google.android.apps.fitness',
      'com.samsung.shealth',
      'com.whoop.',
      'com.oura.',
    ];
    return sourceNames.any(
      (s) => trustedPatterns.any((t) => s.contains(t)),
    );
  }

  /// Cross-validate steps vs distance for plausibility.
  /// ~2,000 steps ≈ 1 mile for average stride. Allow wide tolerance.
  bool isStepsDistanceConsistent(int steps, double miles) {
    if (steps == 0 || miles <= 0) return true; // can't validate
    final expectedMiles = steps / 2000;
    final ratio = miles / expectedMiles;
    return ratio > 0.3 && ratio < 3.0; // within 3x tolerance
  }

  // ============================================
  // FORMATTING HELPERS (unchanged)
  // ============================================

  String formatSteps(int steps) {
    if (steps >= 1000000) return '${(steps / 1000000).toStringAsFixed(1)}M';
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}K';
    return steps.toString();
  }

  String formatDistance(double miles) {
    return '${miles.toStringAsFixed(2)} mi';
  }

  String formatCalories(int calories) {
    if (calories >= 1000) return '${(calories / 1000).toStringAsFixed(1)}K';
    return calories.toString();
  }

  String formatHeartRate(int bpm) {
    return '$bpm';
  }

  String formatHRV(double ms) {
    return '${ms.toStringAsFixed(0)}';
  }

  String formatSleep(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String formatVO2Max(double value) {
    return value.toStringAsFixed(1);
  }

  String formatBloodOxygen(double percent) {
    return '${percent.toStringAsFixed(0)}%';
  }

  String formatRespiratoryRate(double rate) {
    return '${rate.toStringAsFixed(0)}';
  }

  String formatPace(double minutesPerMile) {
    final minutes = minutesPerMile.floor();
    final seconds = ((minutesPerMile - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}/mi';
  }

  String formatTime(double minutes) {
    final mins = minutes.floor();
    final secs = ((minutes - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
