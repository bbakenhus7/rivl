// models/health_metrics.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'challenge_model.dart';

class HealthMetrics {
  final int steps;
  final int heartRate;
  final int restingHeartRate;
  final double hrv;
  final int activeCalories;
  final double distance;
  final double sleepHours;
  final double vo2Max;
  final double respiratoryRate;
  final double bloodOxygen;
  final List<DailySteps> weeklySteps;
  final List<WorkoutData> recentWorkouts;
  final DateTime lastUpdated;

  HealthMetrics({
    required this.steps,
    required this.heartRate,
    required this.restingHeartRate,
    required this.hrv,
    required this.activeCalories,
    required this.distance,
    required this.sleepHours,
    required this.vo2Max,
    required this.respiratoryRate,
    required this.bloodOxygen,
    required this.weeklySteps,
    required this.recentWorkouts,
    required this.lastUpdated,
  });

  // Daily goal calculations
  int get stepsGoal => 10000;
  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);
  bool get stepsGoalReached => steps >= stepsGoal;

  int get caloriesGoal => 500;
  double get caloriesProgress => (activeCalories / caloriesGoal).clamp(0.0, 1.0);
  bool get caloriesGoalReached => activeCalories >= caloriesGoal;

  double get distanceGoal => 5.0; // miles
  double get distanceProgress => (distance / distanceGoal).clamp(0.0, 1.0);
  bool get distanceGoalReached => distance >= distanceGoal;

  double get sleepGoal => 8.0; // hours
  double get sleepProgress => (sleepHours / sleepGoal).clamp(0.0, 1.0);
  bool get sleepGoalReached => sleepHours >= sleepGoal;

  // Weekly stats
  int get weeklyTotalSteps => weeklySteps.fold(0, (sum, day) => sum + day.steps);
  int get weeklyAverageSteps => weeklySteps.isNotEmpty 
      ? weeklyTotalSteps ~/ weeklySteps.length 
      : 0;
  int get weeklyBestDay => weeklySteps.isNotEmpty
      ? weeklySteps.map((d) => d.steps).reduce((a, b) => a > b ? a : b)
      : 0;

  // Recovery score (simplified calculation based on HRV and resting HR)
  int get recoveryScore {
    if (hrv == 0 && restingHeartRate == 0) return 75; // Default if no data
    
    // Higher HRV = better recovery (typical range 20-100ms)
    final hrvScore = ((hrv - 20) / 80 * 50).clamp(0, 50);
    
    // Lower resting HR = better recovery (typical range 50-80 bpm)
    final rhrScore = ((80 - restingHeartRate) / 30 * 50).clamp(0, 50);
    
    return (hrvScore + rhrScore).round().clamp(0, 100);
  }

  String get recoveryStatus {
    if (recoveryScore >= 80) return 'Excellent';
    if (recoveryScore >= 60) return 'Good';
    if (recoveryScore >= 40) return 'Fair';
    return 'Low';
  }

  // RIVL Health Score: combined metric from all 6 health dimensions (0-100)
  int get rivlHealthScore {
    // 1. Steps score (0-100): 10K steps = 100
    final stepsScore = (steps / 10000 * 100).clamp(0.0, 100.0);

    // 2. Distance score (0-100): 5 miles = 100
    final distanceScore = (distance / 5.0 * 100).clamp(0.0, 100.0);

    // 3. Sleep score (0-100): 7-9 hours is optimal
    double sleepScore;
    if (sleepHours >= 7 && sleepHours <= 9) {
      sleepScore = 100;
    } else if (sleepHours >= 6 && sleepHours < 7) {
      sleepScore = 70 + (sleepHours - 6) * 30;
    } else if (sleepHours > 9 && sleepHours <= 10) {
      sleepScore = 100 - (sleepHours - 9) * 20;
    } else {
      sleepScore = (sleepHours / 7 * 60).clamp(0, 60);
    }

    // 4. Resting heart rate score (0-100): lower is better, 50-80 range
    final rhrScore = ((80 - restingHeartRate) / 30 * 100).clamp(0.0, 100.0);

    // 5. HRV score (0-100): higher is better, 20-100ms range
    final hrvScoreVal = ((hrv - 20) / 80 * 100).clamp(0.0, 100.0);

    // 6. VO2 Max score (0-100): higher is better, 25-60 range
    final vo2Score = ((vo2Max - 25) / 35 * 100).clamp(0.0, 100.0);

    // Weighted average: steps & distance matter most for a fitness competition
    final weighted = (stepsScore * 0.25) +
        (distanceScore * 0.20) +
        (sleepScore * 0.15) +
        (rhrScore * 0.15) +
        (hrvScoreVal * 0.10) +
        (vo2Score * 0.15);

    return weighted.round().clamp(0, 100);
  }

  String get rivlHealthGrade {
    final score = rivlHealthScore;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  // Exertion score out of 100 (based on steps and calories)
  int get strainScore {
    final stepsExertion = (steps / 15000 * 100).clamp(0, 100);
    final caloriesExertion = (activeCalories / 800 * 100).clamp(0, 100);
    return ((stepsExertion + caloriesExertion) / 2).round().clamp(0, 100);
  }

  // Demo data factory
  factory HealthMetrics.demo() {
    final rnd = Random();
    final now = DateTime.now();
    
    return HealthMetrics(
      steps: 6234 + rnd.nextInt(4000),
      heartRate: 68 + rnd.nextInt(20),
      restingHeartRate: 58 + rnd.nextInt(12),
      hrv: 45.0 + rnd.nextDouble() * 30,
      activeCalories: 320 + rnd.nextInt(300),
      distance: 2.5 + rnd.nextDouble() * 3,
      sleepHours: 6.5 + rnd.nextDouble() * 2,
      vo2Max: 38.0 + rnd.nextDouble() * 15,
      respiratoryRate: 14.0 + rnd.nextDouble() * 4,
      bloodOxygen: 96.0 + rnd.nextDouble() * 3,
      weeklySteps: List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return DailySteps(
          date: date.toIso8601String().split('T').first,
          steps: 4000 + rnd.nextInt(8000),
          source: 'demo',
          syncedAt: now,
          verified: true,
        );
      }),
      recentWorkouts: [
        WorkoutData(
          type: 'RUNNING',
          duration: Duration(minutes: 32 + rnd.nextInt(20)),
          calories: 280 + rnd.nextInt(150),
          distance: 2.5 + rnd.nextDouble() * 2,
          date: now.subtract(const Duration(days: 1)),
        ),
        WorkoutData(
          type: 'STRENGTH_TRAINING',
          duration: Duration(minutes: 45 + rnd.nextInt(30)),
          calories: 200 + rnd.nextInt(100),
          distance: 0,
          date: now.subtract(const Duration(days: 2)),
        ),
        WorkoutData(
          type: 'WALKING',
          duration: Duration(minutes: 25 + rnd.nextInt(20)),
          calories: 120 + rnd.nextInt(80),
          distance: 1.2 + rnd.nextDouble() * 1,
          date: now.subtract(const Duration(days: 3)),
        ),
      ],
      lastUpdated: now,
    );
  }

  // Empty metrics
  factory HealthMetrics.empty() {
    return HealthMetrics(
      steps: 0,
      heartRate: 0,
      restingHeartRate: 0,
      hrv: 0,
      activeCalories: 0,
      distance: 0,
      sleepHours: 0,
      vo2Max: 0,
      respiratoryRate: 0,
      bloodOxygen: 0,
      weeklySteps: [],
      recentWorkouts: [],
      lastUpdated: DateTime.now(),
    );
  }
}

class WorkoutData {
  final String type;
  final Duration duration;
  final int calories;
  final double distance;
  final DateTime date;

  WorkoutData({
    required this.type,
    required this.duration,
    required this.calories,
    required this.distance,
    required this.date,
  });

  String get displayName {
    switch (type.toUpperCase()) {
      case 'RUNNING':
        return 'Running';
      case 'WALKING':
        return 'Walking';
      case 'CYCLING':
        return 'Cycling';
      case 'SWIMMING':
        return 'Swimming';
      case 'STRENGTH_TRAINING':
      case 'TRADITIONAL_STRENGTH_TRAINING':
        return 'Strength';
      case 'HIIT':
      case 'HIGH_INTENSITY_INTERVAL_TRAINING':
        return 'HIIT';
      case 'YOGA':
        return 'Yoga';
      case 'PILATES':
        return 'Pilates';
      case 'ELLIPTICAL':
        return 'Elliptical';
      case 'ROWING':
        return 'Rowing';
      case 'STAIR_CLIMBING':
        return 'Stairs';
      case 'HIKING':
        return 'Hiking';
      case 'DANCE':
        return 'Dance';
      case 'COOLDOWN':
        return 'Cooldown';
      case 'CORE_TRAINING':
        return 'Core';
      case 'FLEXIBILITY':
        return 'Flexibility';
      case 'FUNCTIONAL_STRENGTH_TRAINING':
        return 'Functional';
      default:
        return type.replaceAll('_', ' ').toLowerCase().split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  IconData get iconData {
    switch (type.toUpperCase()) {
      case 'RUNNING':
        return Icons.directions_run;
      case 'WALKING':
        return Icons.directions_walk;
      case 'CYCLING':
        return Icons.directions_bike;
      case 'SWIMMING':
        return Icons.pool;
      case 'STRENGTH_TRAINING':
      case 'TRADITIONAL_STRENGTH_TRAINING':
      case 'FUNCTIONAL_STRENGTH_TRAINING':
        return Icons.fitness_center;
      case 'HIIT':
      case 'HIGH_INTENSITY_INTERVAL_TRAINING':
        return Icons.local_fire_department;
      case 'YOGA':
        return Icons.self_improvement;
      case 'PILATES':
        return Icons.accessibility_new;
      case 'ELLIPTICAL':
        return Icons.fitness_center;
      case 'ROWING':
        return Icons.rowing;
      case 'STAIR_CLIMBING':
        return Icons.stairs;
      case 'HIKING':
        return Icons.terrain;
      case 'DANCE':
        return Icons.music_note;
      case 'COOLDOWN':
        return Icons.ac_unit;
      case 'CORE_TRAINING':
        return Icons.sports_martial_arts;
      case 'FLEXIBILITY':
        return Icons.sports_gymnastics;
      default:
        return Icons.fitness_center;
    }
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
