// providers/health_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../models/challenge_model.dart';
import '../models/health_metrics.dart';

class HealthProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  Timer? _autoRefreshTimer;

  /// Callback invoked when the user earns XP from health activity.
  void Function(int xp, String source)? onXPEarned;
  DateTime? _lastHealthXPDate; // Track daily health sync XP

  bool _isAuthorized = false;
  bool _isLoading = false;
  HealthMetrics _metrics = HealthMetrics.demo();
  String? _errorMessage;

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

  /// True when displayed health data is demo/placeholder (not from HealthKit/Google Fit).
  bool get isDemoData => !_isAuthorized;

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

  // Recovery and strain
  int get recoveryScore => _metrics.recoveryScore;
  String get recoveryStatus => _metrics.recoveryStatus;
  int get strainScore => _metrics.strainScore;

  // RIVL Health Score
  int get rivlHealthScore => _metrics.rivlHealthScore;
  String get rivlHealthGrade => _metrics.rivlHealthGrade;

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
      _metrics = HealthMetrics.demo();
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _isAuthorized = await _healthService.requestAuthorization();
      if (_isAuthorized) {
        await refreshData();
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to health services';
      _isAuthorized = false;
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthorized;
  }

  Future<void> checkAuthorization() async {
    _isAuthorized = await _healthService.checkAuthorization();
    notifyListeners();
  }

  // ============================================
  // DATA FETCHING
  // ============================================

  Future<void> refreshData() async {
    if (!_isAuthorized) {
      await checkAuthorization();
      if (!_isAuthorized) {
        // Use demo data if not authorized
        _metrics = HealthMetrics.demo();
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metrics = await _healthService.getHealthMetrics();

      // Award daily health sync XP (once per day)
      final today = DateTime.now();
      if (_lastHealthXPDate == null ||
          _lastHealthXPDate!.day != today.day ||
          _lastHealthXPDate!.month != today.month) {
        _lastHealthXPDate = today;
        onXPEarned?.call(5, 'health_sync');

        // Award bonus XP if daily steps goal reached
        if (_metrics.stepsGoalReached) {
          onXPEarned?.call(15, 'steps_goal');
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch health data';
      _metrics = HealthMetrics.demo();
    }

    _isLoading = false;
    notifyListeners();
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
      notifyListeners();
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
      debugPrint('HealthProvider: getStepsForChallenge error: $e');
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
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ============================================
  // FORMATTING HELPERS
  // ============================================

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
    notifyListeners();
  }
}
