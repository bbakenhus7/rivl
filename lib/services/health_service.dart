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

  // Distance tracking (in miles)
  Future<double> getTodayDistance() async {
    // Stub: return realistic distance (2-5 miles)
    return 3.2;
  }

  Future<double> getDistanceInRange(DateTime start, DateTime end) async {
    // Stub: rough estimate based on days
    final days = end.difference(start).inDays + 1;
    final rnd = Random(43);
    return days * (2.0 + rnd.nextDouble() * 3.0);
  }

  // Mile pace tracking (in minutes per mile)
  Future<double> getAverageMilePace() async {
    // Stub: return realistic pace (8-12 minutes/mile)
    return 9.5;
  }

  Future<double> getMilePaceInRange(DateTime start, DateTime end) async {
    // Stub: average pace over period
    final rnd = Random(44);
    return 8.0 + rnd.nextDouble() * 4.0;
  }

  // 5K pace tracking (in minutes)
  Future<double> getBest5KTime() async {
    // Stub: return realistic 5K time (25-35 minutes)
    return 28.5;
  }

  Future<double> get5KTimeInRange(DateTime start, DateTime end) async {
    // Stub: best 5K time in period
    final rnd = Random(45);
    return 25.0 + rnd.nextDouble() * 10.0;
  }

  // Sleep duration tracking (in hours)
  Future<double> getTodaySleep() async {
    // Stub: return realistic sleep (6-9 hours)
    return 7.5;
  }

  Future<double> getSleepInRange(DateTime start, DateTime end) async {
    // Stub: total sleep over period
    final days = end.difference(start).inDays + 1;
    final rnd = Random(46);
    return days * (6.0 + rnd.nextDouble() * 3.0);
  }

  // VO2 Max tracking (ml/kg/min)
  Future<double> getVO2Max() async {
    // Stub: return realistic VO2 max (35-55 ml/kg/min)
    return 42.0;
  }

  Future<double> getVO2MaxInRange(DateTime start, DateTime end) async {
    // Stub: average VO2 max over period
    final rnd = Random(47);
    return 35.0 + rnd.nextDouble() * 20.0;
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

  String formatDistance(double miles) {
    return '${miles.toStringAsFixed(1)} mi';
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

  String formatSleep(double hours) {
    return '${hours.toStringAsFixed(1)} hrs';
  }

  String formatVO2Max(double value) {
    return '${value.toStringAsFixed(1)} ml/kg/min';
  }
}
