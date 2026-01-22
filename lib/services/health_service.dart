// services/health_service.dart

// Lightweight cross-platform HealthService stub used for desktop/web builds
// This avoids depending on platform-only `health` plugin during analysis
// and provides sensible fake values so the UI can run.

import 'dart:math';
import '../models/challenge_model.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  Future<bool> requestAuthorization() async {
    // For desktop/web, assume authorization succeeds (stub)
    _isAuthorized = true;
    return _isAuthorized;
  }

  Future<bool> checkAuthorization() async {
    return _isAuthorized;
  }

  Future<int> getTodaySteps() async {
    // Return a pseudo-random but stable-looking value
    return 5234;
  }

  Future<int> getStepsInRange(DateTime start, DateTime end) async {
    // Rough estimate based on days
    final days = end.difference(start).inDays + 1;
    return days * 4000;
  }

  Future<List<DailySteps>> getDailySteps(int days) async {
    final now = DateTime.now();
    final List<DailySteps> list = [];
    final rnd = Random(42);
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final steps = 3000 + rnd.nextInt(7000);
      list.add(DailySteps(
        date: date.toIso8601String().split('T').first,
        steps: steps,
        source: 'stub',
        syncedAt: DateTime.now(),
        verified: true,
      ));
    }
    return list.reversed.toList();
  }

  Future<List<DailySteps>> getStepsForChallenge(DateTime startDate, DateTime endDate) async {
    final List<DailySteps> result = [];
    var current = startDate;
    final rnd = Random(7);
    while (!current.isAfter(endDate)) {
      result.add(DailySteps(
        date: current.toIso8601String().split('T').first,
        steps: 2000 + rnd.nextInt(8000),
        source: 'stub',
        syncedAt: DateTime.now(),
        verified: true,
      ));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final days = await getDailySteps(7);
    final total = days.fold<int>(0, (s, d) => s + d.steps);
    return {
      'totalSteps': total,
      'averageSteps': total ~/ days.length,
      'bestDay': days.map((d) => d.steps).reduce((a, b) => a > b ? a : b),
      'dailySteps': days,
    };
  }

  Future<double> validateSteps(List<DailySteps> stepHistory) async {
    if (stepHistory.isEmpty) return 0.5;
    return 0.9;
  }

  String formatSteps(int steps) {
    if (steps >= 1000000) return '${(steps / 1000000).toStringAsFixed(1)}M';
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}K';
    return steps.toString();
  }
}
