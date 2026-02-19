// services/health_service.dart
// Real HealthKit / Health Connect integration via the `health` package

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/challenge_model.dart';
import '../models/health_metrics.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

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
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
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
      final permissions = _readTypes.map((_) => HealthDataAccess.READ).toList();
      _isAuthorized = await _health.requestAuthorization(
        _readTypes,
        permissions: permissions,
      );
      return _isAuthorized;
    } catch (e) {
      // authorization error — returning false
      _isAuthorized = false;
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

      // Fetch today's data points and weekly steps in parallel.
      final results = await Future.wait([
        _health.getHealthDataFromTypes(
          types: _readTypes.where((t) => t != HealthDataType.WORKOUT).toList(),
          startTime: yesterday,
          endTime: now,
        ),
        _fetchWeeklySteps(),
        _fetchRecentWorkouts(),
      ]);

      // Deduplicate data points — multiple sources (iPhone + Apple Watch)
      // can report the same distance/calorie/HR readings, causing over-counting.
      final dataPoints = Health().removeDuplicates(
        results[0] as List<HealthDataPoint>,
      );
      final weeklySteps = results[1] as List<DailySteps>;
      final recentWorkouts = results[2] as List<WorkoutData>;

      // Steps: use dedicated method for accurate total
      final steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;

      // Extract most recent values for point-in-time metrics
      final heartRate = _mostRecentValue(dataPoints, HealthDataType.HEART_RATE)?.toInt() ?? 0;
      final restingHeartRate = _mostRecentValue(dataPoints, HealthDataType.RESTING_HEART_RATE)?.toInt() ?? 0;
      final hrv = _mostRecentValue(dataPoints, HealthDataType.HEART_RATE_VARIABILITY_SDNN) ?? 0.0;
      // VO2 max is not yet supported by the health package — defaults to 0.
      const vo2Max = 0.0;
      final respiratoryRate = _mostRecentValue(dataPoints, HealthDataType.RESPIRATORY_RATE) ?? 0.0;
      final bloodOxygen = _mostRecentValue(dataPoints, HealthDataType.BLOOD_OXYGEN) ?? 0.0;

      // Calories: sum today's active energy burned
      final activeCalories = _sumValues(dataPoints, HealthDataType.ACTIVE_ENERGY_BURNED, midnight, now).toInt();

      // Distance: sum today's distance delta, convert meters to miles
      final distanceType = defaultTargetPlatform == TargetPlatform.iOS
          ? HealthDataType.DISTANCE_WALKING_RUNNING
          : HealthDataType.DISTANCE_DELTA;
      final distanceMeters = _sumValues(dataPoints, distanceType, midnight, now);
      final distanceMiles = distanceMeters * 0.000621371;

      // Sleep: sum all sleep stages from the past 24 hours
      final sleepHours = _calculateSleepHours(dataPoints, yesterday, now);

      return HealthMetrics(
        steps: steps,
        heartRate: heartRate,
        restingHeartRate: restingHeartRate,
        hrv: hrv,
        activeCalories: activeCalories,
        distance: distanceMiles,
        sleepHours: sleepHours,
        vo2Max: vo2Max,
        respiratoryRate: respiratoryRate,
        bloodOxygen: bloodOxygen,
        weeklySteps: weeklySteps,
        recentWorkouts: recentWorkouts,
        lastUpdated: now,
      );
    } catch (e) {
      debugPrint('HealthService: getHealthMetrics error — returning demo data: $e');
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

  /// Sum all values of a given type within a date range.
  double _sumValues(List<HealthDataPoint> points, HealthDataType type, DateTime from, DateTime to) {
    return points
        .where((p) => p.type == type && !p.dateFrom.isBefore(from) && !p.dateTo.isAfter(to))
        .fold(0.0, (sum, p) => sum + _numericValue(p));
  }

  /// Calculate total sleep hours from sleep-stage data points.
  double _calculateSleepHours(List<HealthDataPoint> points, DateTime from, DateTime to) {
    const sleepTypes = [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
    ];

    var totalMinutes = 0.0;
    for (final point in points) {
      if (!sleepTypes.contains(point.type)) continue;
      if (point.dateFrom.isBefore(from) || point.dateTo.isAfter(to)) continue;
      totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
    }
    return totalMinutes / 60.0;
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

    // Determine platform-specific types
    final distanceType = defaultTargetPlatform == TargetPlatform.iOS
        ? HealthDataType.DISTANCE_WALKING_RUNNING
        : HealthDataType.DISTANCE_DELTA;
    final crossRefTypes = [
      distanceType,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
    ];

    for (var i = 0; i < days; i++) {
      final dayStart = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
      if (dayStart.isAfter(now)) break;
      final dayEnd = dayStart.add(const Duration(days: 1)).isAfter(now)
          ? now
          : dayStart.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;

      // Fetch cross-validation metrics for this day
      double? distanceMiles;
      int? activeCalories;
      int? avgHeartRate;
      try {
        final crossRefDataRaw = await _health.getHealthDataFromTypes(
          types: crossRefTypes,
          startTime: dayStart,
          endTime: dayEnd,
        );
        final crossRefData = _health.removeDuplicates(crossRefDataRaw);

        // Distance (meters -> miles)
        final distanceMeters = crossRefData
            .where((p) => p.type == distanceType)
            .fold(0.0, (sum, p) => sum + _numericValue(p));
        if (distanceMeters > 0) {
          distanceMiles = distanceMeters * 0.000621371;
        }

        // Active calories
        final calTotal = crossRefData
            .where((p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED)
            .fold(0.0, (sum, p) => sum + _numericValue(p));
        if (calTotal > 0) {
          activeCalories = calTotal.toInt();
        }

        // Average heart rate
        final hrPoints = crossRefData
            .where((p) => p.type == HealthDataType.HEART_RATE)
            .toList();
        if (hrPoints.isNotEmpty) {
          final hrSum = hrPoints.fold(0.0, (sum, p) => sum + _numericValue(p));
          avgHeartRate = (hrSum / hrPoints.length).round();
        }
      } catch (_) {
        // Cross-ref metrics are best-effort; steps are the primary data
      }

      history.add(DailySteps(
        date: dayStart.toIso8601String().split('T').first,
        steps: steps,
        source: _sourceTag,
        syncedAt: now,
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

      final dataPointsRaw = await _health.getHealthDataFromTypes(
        types: [defaultTargetPlatform == TargetPlatform.iOS
            ? HealthDataType.DISTANCE_WALKING_RUNNING
            : HealthDataType.DISTANCE_DELTA],
        startTime: dayStart,
        endTime: dayEnd,
      );
      final dataPoints = _health.removeDuplicates(dataPointsRaw);

      final metersTotal = dataPoints.fold(0.0, (sum, p) => sum + _numericValue(p));
      final miles = (metersTotal * 0.000621371).round();
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
      );
      final dataPoints = _health.removeDuplicates(dataPointsRaw);

      var totalMinutes = 0.0;
      for (final point in dataPoints) {
        totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
      }
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
        );
        final hrData = _health.removeDuplicates(hrDataRaw);

        // Each HR data point represents a measurement interval.
        // Count points in zone 2 range; estimate ~1 minute per data point.
        for (final point in hrData) {
          final bpm = _numericValue(point);
          if (bpm >= zone2Low && bpm <= zone2High) {
            // Approximate duration from data point interval, min 1 minute
            final intervalMinutes = point.dateTo.difference(point.dateFrom).inMinutes;
            zone2Minutes += intervalMinutes > 0 ? intervalMinutes : 1;
          }
        }
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
