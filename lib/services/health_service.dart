// services/health_service.dart

import 'dart:io';
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

  // Data types we want to read from Apple Health / Google Fit
  List<HealthDataType> get _dataTypes {
    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.WORKOUT,
    ];

    // iOS-only types
    if (!kIsWeb && Platform.isIOS) {
      types.addAll([
        HealthDataType.VO2MAX,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BLOOD_OXYGEN,
      ]);
    }

    return types;
  }

  // ============================================
  // AUTHORIZATION
  // ============================================

  Future<bool> requestAuthorization() async {
    if (kIsWeb) {
      _isAuthorized = true;
      return true;
    }

    try {
      // Configure the health plugin
      await _health.configure();

      // Request authorization
      _isAuthorized = await _health.requestAuthorization(
        _dataTypes,
        permissions: _dataTypes.map((_) => HealthDataAccess.READ).toList(),
      );

      return _isAuthorized;
    } catch (e) {
      debugPrint('Health authorization error: $e');
      _isAuthorized = false;
      return false;
    }
  }

  Future<bool> checkAuthorization() async {
    if (kIsWeb) return true;

    try {
      _isAuthorized = await _health.hasPermissions(_dataTypes) ?? false;
      return _isAuthorized;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // COMPREHENSIVE HEALTH DATA
  // ============================================

  Future<HealthMetrics> getHealthMetrics() async {
    if (kIsWeb) {
      return HealthMetrics.demo();
    }

    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return HealthMetrics.demo();
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));

    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _getTodaySteps(todayStart, now),
        _getHeartRate(todayStart, now),
        _getRestingHeartRate(todayStart, now),
        _getHRV(todayStart, now),
        _getActiveCalories(todayStart, now),
        _getDistance(todayStart, now),
        _getSleepData(todayStart.subtract(const Duration(days: 1)), todayStart),
        _getVO2Max(weekStart, now),
        _getRespiratoryRate(todayStart, now),
        _getBloodOxygen(todayStart, now),
        _getWeeklySteps(weekStart, now),
        _getWorkouts(weekStart, now),
      ]);

      return HealthMetrics(
        steps: results[0] as int,
        heartRate: results[1] as int,
        restingHeartRate: results[2] as int,
        hrv: results[3] as double,
        activeCalories: results[4] as int,
        distance: results[5] as double,
        sleepHours: results[6] as double,
        vo2Max: results[7] as double,
        respiratoryRate: results[8] as double,
        bloodOxygen: results[9] as double,
        weeklySteps: results[10] as List<DailySteps>,
        recentWorkouts: results[11] as List<WorkoutData>,
        lastUpdated: now,
      );
    } catch (e) {
      debugPrint('Error fetching health metrics: $e');
      return HealthMetrics.demo();
    }
  }

  // ============================================
  // INDIVIDUAL METRICS
  // ============================================

  Future<int> _getTodaySteps(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getHeartRate(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      // Get most recent heart rate
      final sorted = data..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = sorted.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getRestingHeartRate(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      final sorted = data..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = sorted.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getHRV(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      final sorted = data..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = sorted.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveCalories(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      double total = 0;
      for (final point in data) {
        if (point.value is NumericHealthValue) {
          total += (point.value as NumericHealthValue).numericValue;
        }
      }
      return total.toInt();
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getDistance(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      double total = 0;
      for (final point in data) {
        if (point.value is NumericHealthValue) {
          total += (point.value as NumericHealthValue).numericValue;
        }
      }
      // Convert meters to miles
      return total / 1609.34;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getSleepData(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      // Calculate total sleep duration
      double totalMinutes = 0;
      for (final point in data) {
        final duration = point.dateTo.difference(point.dateFrom);
        totalMinutes += duration.inMinutes;
      }
      return totalMinutes / 60; // Return hours
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getVO2Max(DateTime start, DateTime end) async {
    if (kIsWeb) return 0;
    if (!Platform.isIOS) return 0;

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.VO2MAX],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      final sorted = data..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = sorted.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getRespiratoryRate(DateTime start, DateTime end) async {
    if (kIsWeb) return 0;
    if (!Platform.isIOS) return 0;

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESPIRATORY_RATE],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      final sorted = data..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = sorted.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getBloodOxygen(DateTime start, DateTime end) async {
    if (kIsWeb) return 0;
    if (!Platform.isIOS) return 0;

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;

      final sorted = data..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = sorted.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble() * 100; // Convert to percentage
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<DailySteps>> _getWeeklySteps(DateTime start, DateTime end) async {
    final List<DailySteps> result = [];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      final dayStart = current;
      final dayEnd = DateTime(current.year, current.month, current.day, 23, 59, 59);
      final steps = await _getTodaySteps(dayStart, dayEnd);

      result.add(DailySteps(
        date: current.toIso8601String().split('T').first,
        steps: steps,
        source: kIsWeb ? 'web' : (Platform.isIOS ? 'apple_health' : 'google_fit'),
        syncedAt: DateTime.now(),
        verified: true,
      ));

      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  Future<List<WorkoutData>> _getWorkouts(DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );

      return data.map((point) {
        final workout = point.value as WorkoutHealthValue;
        return WorkoutData(
          type: workout.workoutActivityType.name,
          duration: point.dateTo.difference(point.dateFrom),
          calories: workout.totalEnergyBurned?.toInt() ?? 0,
          distance: (workout.totalDistance ?? 0) / 1609.34, // meters to miles
          date: point.dateFrom,
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // LEGACY METHODS (for backwards compatibility)
  // ============================================

  Future<int> getTodaySteps() async {
    if (kIsWeb || !_isAuthorized) return 5234;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return await _getTodaySteps(todayStart, now);
  }

  Future<int> getStepsInRange(DateTime start, DateTime end) async {
    if (kIsWeb || !_isAuthorized) {
      final days = end.difference(start).inDays + 1;
      return days * 4000;
    }

    return await _getTodaySteps(start, end);
  }

  Future<List<DailySteps>> getDailySteps(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    if (kIsWeb || !_isAuthorized) {
      final rnd = Random(42);
      return List.generate(days, (i) {
        final date = now.subtract(Duration(days: days - 1 - i));
        return DailySteps(
          date: date.toIso8601String().split('T').first,
          steps: 3000 + rnd.nextInt(7000),
          source: 'demo',
          syncedAt: DateTime.now(),
          verified: true,
        );
      });
    }

    return await _getWeeklySteps(start, now);
  }

  Future<List<DailySteps>> getStepsForChallenge(DateTime startDate, DateTime endDate) async {
    if (kIsWeb || !_isAuthorized) {
      return getDailySteps(endDate.difference(startDate).inDays + 1);
    }

    return await _getWeeklySteps(startDate, endDate);
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
  // FORMATTING HELPERS
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
