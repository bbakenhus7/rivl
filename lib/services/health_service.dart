// services/health_service.dart
// Stub implementation - returns demo data until HealthKit integration is set up

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/challenge_model.dart';
import '../models/health_metrics.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  // ============================================
  // AUTHORIZATION (stub - always succeeds)
  // ============================================

  Future<bool> requestAuthorization() async {
    // TODO: Implement real HealthKit/Google Fit authorization
    // For now, return true and use demo data
    _isAuthorized = true;
    return true;
  }

  Future<bool> checkAuthorization() async {
    return _isAuthorized;
  }

  // ============================================
  // COMPREHENSIVE HEALTH DATA (demo)
  // ============================================

  Future<HealthMetrics> getHealthMetrics() async {
    // TODO: Implement real health data fetching from Apple Health / Google Fit
    // For now, return realistic demo data
    return HealthMetrics.demo();
  }

  // ============================================
  // CHALLENGE PROGRESS (multi-metric)
  // ============================================

  /// Fetch cumulative progress for a challenge based on its goal type.
  /// Returns (totalProgress, dailyHistory) as demo data for now.
  Future<({int total, List<DailySteps> history})> getProgressForChallenge({
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
        // Distance in miles (stored as whole int, e.g. 22 = 22 mi)
        final history = List.generate(days, (i) {
          final date = startDate.add(Duration(days: i));
          return DailySteps(
            date: date.toIso8601String().split('T').first,
            steps: 2 + rnd.nextInt(5), // 2-6 miles/day
            source: 'demo',
            syncedAt: DateTime.now(),
          );
        });
        final total = history.fold<int>(0, (sum, d) => sum + d.steps);
        return (total: total, history: history);

      case GoalType.sleepDuration:
        // Sleep stored as total hours (int), e.g. 56 = 56 hrs over challenge
        final history = List.generate(days, (i) {
          final date = startDate.add(Duration(days: i));
          return DailySteps(
            date: date.toIso8601String().split('T').first,
            steps: 6 + rnd.nextInt(3), // 6-8 hours/night
            source: 'demo',
            syncedAt: DateTime.now(),
          );
        });
        final total = history.fold<int>(0, (sum, d) => sum + d.steps);
        return (total: total, history: history);

      case GoalType.vo2Max:
        // VO2 Max stored as x10 int (e.g. 425 = 42.5 mL/kg/min)
        // For VO2 Max we track the latest reading, not cumulative
        final latest = 350 + rnd.nextInt(150); // 35.0 - 50.0
        final history = [
          DailySteps(
            date: DateTime.now().toIso8601String().split('T').first,
            steps: latest,
            source: 'demo',
            syncedAt: DateTime.now(),
          ),
        ];
        return (total: latest, history: history);

      case GoalType.milePace:
        // Pace stored in seconds (e.g. 480 = 8:00 min/mi)
        // Lower is better — track best (lowest) pace
        final best = 420 + rnd.nextInt(180); // 7:00 - 10:00
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
        // 5K time stored in seconds (e.g. 1500 = 25:00)
        final best = 1200 + rnd.nextInt(600); // 20:00 - 30:00
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
        // 10K time stored in seconds (e.g. 3000 = 50:00)
        final best = 2400 + rnd.nextInt(1200); // 40:00 - 60:00
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
        // RIVL Health Score 0-100, track latest
        final latest = 50 + rnd.nextInt(40); // 50-90
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
  // LEGACY METHODS (for backwards compatibility)
  // ============================================

  Future<int> getTodaySteps() async {
    // Return demo steps
    final rnd = Random();
    return 5000 + rnd.nextInt(5000);
  }

  Future<int> getStepsInRange(DateTime start, DateTime end) async {
    final days = end.difference(start).inDays + 1;
    return days * 4000;
  }

  Future<List<DailySteps>> getDailySteps(int days) async {
    final now = DateTime.now();
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

  Future<List<DailySteps>> getStepsForChallenge(DateTime startDate, DateTime endDate) async {
    return getDailySteps(endDate.difference(startDate).inDays + 1);
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
