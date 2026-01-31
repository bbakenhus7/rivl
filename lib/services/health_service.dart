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
