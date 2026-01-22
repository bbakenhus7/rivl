// providers/health_provider.dart

import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../models/challenge_model.dart';

class HealthProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();

  bool _isAuthorized = false;
  bool _isLoading = false;
  int _todaySteps = 0;
  List<DailySteps> _weeklySteps = [];
  Map<String, dynamic> _weeklySummary = {};
  String? _errorMessage;

  // Getters
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  int get todaySteps => _todaySteps;
  List<DailySteps> get weeklySteps => _weeklySteps;
  Map<String, dynamic> get weeklySummary => _weeklySummary;
  String? get errorMessage => _errorMessage;

  // Goal tracking
  int get dailyGoal => 10000;
  double get goalProgress => (_todaySteps / dailyGoal).clamp(0.0, 1.0);
  bool get goalReached => _todaySteps >= dailyGoal;

  // ============================================
  // AUTHORIZATION
  // ============================================

  Future<bool> requestAuthorization() async {
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
      if (!_isAuthorized) return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch today's steps
      _todaySteps = await _healthService.getTodaySteps();

      // Fetch weekly steps
      _weeklySteps = await _healthService.getDailySteps(7);

      // Get weekly summary
      _weeklySummary = await _healthService.getWeeklySummary();
    } catch (e) {
      _errorMessage = 'Failed to fetch health data';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int> getTodaySteps() async {
    if (!_isAuthorized) return 0;
    
    try {
      _todaySteps = await _healthService.getTodaySteps();
      notifyListeners();
      return _todaySteps;
    } catch (e) {
      return _todaySteps;
    }
  }

  Future<List<DailySteps>> getStepsForChallenge(DateTime start, DateTime end) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return [];
    }

    return await _healthService.getStepsForChallenge(start, end);
  }

  // ============================================
  // HELPERS
  // ============================================

  String formatSteps(int steps) {
    return _healthService.formatSteps(steps);
  }

  String get todayStepsFormatted => formatSteps(_todaySteps);

  int get weeklyTotal => _weeklySummary['totalSteps'] ?? 0;
  int get weeklyAverage => _weeklySummary['averageSteps'] ?? 0;
  int get weeklyBest => _weeklySummary['bestDay'] ?? 0;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
