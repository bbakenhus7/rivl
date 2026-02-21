// providers/health_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../models/challenge_model.dart';
import '../models/health_metrics.dart';

export 'package:rivl/services/health_service.dart' show HealthErrorReason;

class HealthProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  Timer? _autoRefreshTimer;
  bool _disposed = false;

  /// Callback invoked when the user earns XP from health activity.
  void Function(int xp, String source)? onXPEarned;
  DateTime? _lastHealthXPDate; // Track daily health sync XP

  bool _isAuthorized = false;
  bool _isLoading = false;
  HealthMetrics _metrics = HealthMetrics.demo();
  String? _errorMessage;

  /// True when the most recent health metrics fetch fell back to demo data,
  /// either because the platform is unsupported, authorization failed, or a
  /// catch block returned HealthMetrics.demo().
  bool _isUsingDemoData = true;

  /// True when the platform supports health data (iOS / Android, not web).
  bool get isHealthSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android);

  // Getters
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  HealthMetrics get metrics => _metrics;
  String? get errorMessage => _errorMessage;

  /// The reason for the most recent health data failure, or null on success.
  HealthErrorReason? get errorReason => _healthService.lastErrorReason;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// True when displayed health data is demo/placeholder (not from HealthKit/Google Fit).
  /// Covers both "not authorized" and "authorized but fetch failed" cases.
  bool get isUsingDemoData => _isUsingDemoData;

  /// Keep the old getter for backward compat with existing UI code.
  bool get isDemoData => _isUsingDemoData;

  // Quick access to common metrics
  int get todaySteps => _metrics.steps;
  int get heartRate => _metrics.heartRate;
  int get restingHeartRate => _metrics.restingHeartRate;
  double get hrv => _metrics.hrv;
  int get activeCalories => _metrics.activeCalories;
  double get distance => _metrics.distance;
  double get sleepHours => _metrics.sleepHours;
  double get vo2Max => _metrics.vo2Max;
  double get respiratoryRate => _metrics.respiratoryRate;
  double get bloodOxygen => _metrics.bloodOxygen;
  List<DailySteps> get weeklySteps => _metrics.weeklySteps;
  List<WorkoutData> get recentWorkouts => _metrics.recentWorkouts;

  // Granular sleep
  double get deepSleepHours => _metrics.deepSleepHours;
  double get remSleepHours => _metrics.remSleepHours;
  double get lightSleepHours => _metrics.lightSleepHours;
  double get awakeDuration => _metrics.awakeDuration;
  double get timeInBed => _metrics.timeInBed;
  int get sleepQualityScore => _metrics.sleepQualityScore;
  double get sleepEfficiency => _metrics.sleepEfficiency;

  // Exercise
  int get exerciseMinutes => _metrics.exerciseMinutes;

  // Recovery and strain
  int get recoveryScore => _metrics.recoveryScore;
  String get recoveryStatus => _metrics.recoveryStatus;
  int get strainScore => _metrics.strainScore;

  // RIVL Health Score
  int get rivlHealthScore => _metrics.rivlHealthScore;
  String get rivlHealthGrade => _metrics.rivlHealthGrade;

  // Health score sub-scores (0-100 each)
  double get scoreSteps => _metrics.scoreSteps;
  double get scoreCalories => _metrics.scoreCalories;
  double get scoreExercise => _metrics.scoreExercise;
  double get scoreSleep => _metrics.scoreSleep;
  double get scoreRhr => _metrics.scoreRhr;
  double get scoreHrv => _metrics.scoreHrv;

  // Goal tracking
  int get dailyGoal => _metrics.stepsGoal;
  double get goalProgress => _metrics.stepsProgress;
  bool get goalReached => _metrics.stepsGoalReached;

  // Weekly stats
  int get weeklyTotal => _metrics.weeklyTotalSteps;
  int get weeklyAverage => _metrics.weeklyAverageSteps;
  int get weeklyBest => _metrics.weeklyBestDay;

  // ============================================
  // AUTHORIZATION
  // ============================================

  Future<bool> requestAuthorization() async {
    if (!isHealthSupported) {
      // On unsupported platforms, stay on demo data without error.
      _isAuthorized = false;
      _isUsingDemoData = true;
      _metrics = HealthMetrics.demo();
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _safeNotify();

    try {
      _isAuthorized = await _healthService.requestAuthorization();
      if (_isAuthorized) {
        await refreshData();
      }
    } catch (e) {
      _isAuthorized = false;
      _isUsingDemoData = true;
      switch (_healthService.lastErrorReason) {
        case HealthErrorReason.healthConnectMissing:
          _errorMessage = 'Health Connect app is required. Please install it from the Play Store.';
          break;
        case HealthErrorReason.deviceLocked:
          _errorMessage = 'Unlock your device to access health data.';
          break;
        default:
          _errorMessage = 'Failed to connect to health services';
      }
    }

    _isLoading = false;
    _safeNotify();
    return _isAuthorized;
  }

  Future<void> checkAuthorization() async {
    _isAuthorized = await _healthService.checkAuthorization();
    _safeNotify();
  }

  // ============================================
  // DATA FETCHING
  // ============================================

  bool _isRefreshing = false;

  Future<void> refreshData() async {
    if (_isRefreshing) return;
    if (!_isAuthorized) {
      await checkAuthorization();
      if (!_isAuthorized) {
        // Use demo data if not authorized
        _isUsingDemoData = true;
        _metrics = HealthMetrics.demo();
        _safeNotify();
        return;
      }
    }

    _isRefreshing = true;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      _metrics = await _healthService.getHealthMetrics();
      _isUsingDemoData = false;

      // Award daily health sync XP (once per day)
      final today = DateTime.now();
      if (_lastHealthXPDate == null ||
          _lastHealthXPDate!.year != today.year ||
          _lastHealthXPDate!.month != today.month ||
          _lastHealthXPDate!.day != today.day) {
        _lastHealthXPDate = today;
        onXPEarned?.call(5, 'health_sync');

        // Award bonus XP if daily steps goal reached
        if (_metrics.stepsGoalReached) {
          onXPEarned?.call(15, 'steps_goal');
        }
      }
    } catch (e) {
      _isUsingDemoData = true;
      _metrics = HealthMetrics.demo();
      switch (_healthService.lastErrorReason) {
        case HealthErrorReason.deviceLocked:
          _errorMessage = 'Unlock your device to access health data.';
          break;
        default:
          _errorMessage = 'Failed to fetch health data';
      }
    }

    _isRefreshing = false;
    _isLoading = false;
    _safeNotify();
  }

  Future<int> getTodaySteps() async {
    if (!_isAuthorized) return _metrics.steps;

    try {
      final steps = await _healthService.getTodaySteps();
      // Update the cached metrics so the UI reflects the latest value
      _metrics = HealthMetrics(
        steps: steps,
        heartRate: _metrics.heartRate,
        restingHeartRate: _metrics.restingHeartRate,
        hrv: _metrics.hrv,
        activeCalories: _metrics.activeCalories,
        distance: _metrics.distance,
        sleepHours: _metrics.sleepHours,
        vo2Max: _metrics.vo2Max,
        respiratoryRate: _metrics.respiratoryRate,
        bloodOxygen: _metrics.bloodOxygen,
        weeklySteps: _metrics.weeklySteps,
        recentWorkouts: _metrics.recentWorkouts,
        lastUpdated: DateTime.now(),
      );
      _safeNotify();
      return steps;
    } catch (e) {
      return _metrics.steps;
    }
  }

  Future<List<DailySteps>> getStepsForChallenge(DateTime start, DateTime end) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return [];
    }

    try {
      return await _healthService.getStepsForChallenge(start, end);
    } catch (e) {
      // getStepsForChallenge failed — returning empty list
      return [];
    }
  }

  /// Start periodic background refresh (call once from MainScreen).
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isAuthorized) {
        refreshData();
      }
    });
  }

  /// Stop periodic background refresh.
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ============================================
  // DEMO DATA DETECTION FOR CHALLENGES
  // ============================================

  /// Whether challenge progress for the given [goalType] would use demo data.
  /// Returns true when the platform is not authorized OR the goal type has no
  /// real health-data implementation yet (zone2Cardio, pace goals, rivlHealthScore).
  bool isChallengeUsingDemoData(GoalType goalType) {
    if (_isUsingDemoData) return true;

    // All goal types now have real health data implementations.
    // Demo data is only used when the platform is not authorized.
    return false;
  }

  // ============================================
  // FORMATTING HELPERS
  // ============================================

  /// Fetch daily step totals for the given number of days.
  Future<List<DailySteps>> getDailySteps(int days) async {
    try {
      return await _healthService.getDailySteps(days);
    } catch (e) {
      // getDailySteps failed — returning empty list
      return [];
    }
  }

  String formatSteps(int steps) => _healthService.formatSteps(steps);
  String formatDistance(double miles) => _healthService.formatDistance(miles);
  String formatCalories(int calories) => _healthService.formatCalories(calories);
  String formatHeartRate(int bpm) => _healthService.formatHeartRate(bpm);
  String formatHRV(double ms) => _healthService.formatHRV(ms);
  String formatSleep(double hours) => _healthService.formatSleep(hours);
  String formatVO2Max(double value) => _healthService.formatVO2Max(value);
  String formatBloodOxygen(double percent) => _healthService.formatBloodOxygen(percent);
  String formatRespiratoryRate(double rate) => _healthService.formatRespiratoryRate(rate);

  String get todayStepsFormatted => formatSteps(_metrics.steps);

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }
}
