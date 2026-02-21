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

  // Granular sleep breakdown (hours)
  final double deepSleepHours;
  final double remSleepHours;
  final double lightSleepHours;
  final double awakeDuration; // time awake during sleep session
  final double timeInBed; // total time in bed (iOS only, 0 if unavailable)

  // Exercise
  final int exerciseMinutes; // Apple Exercise ring minutes (iOS)

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
    this.deepSleepHours = 0,
    this.remSleepHours = 0,
    this.lightSleepHours = 0,
    this.awakeDuration = 0,
    this.timeInBed = 0,
    this.exerciseMinutes = 0,
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

  // Sleep quality metrics
  double get sleepEfficiency {
    if (timeInBed <= 0) {
      // If no in-bed data, estimate from total sleep + awake time
      final totalSession = sleepHours + awakeDuration;
      return totalSession > 0 ? (sleepHours / totalSession * 100).clamp(0, 100) : 0;
    }
    return (sleepHours / timeInBed * 100).clamp(0, 100);
  }

  double get deepSleepPercent => sleepHours > 0 ? (deepSleepHours / sleepHours * 100) : 0;
  double get remSleepPercent => sleepHours > 0 ? (remSleepHours / sleepHours * 100) : 0;
  double get lightSleepPercent => sleepHours > 0 ? (lightSleepHours / sleepHours * 100) : 0;

  /// Composite sleep quality score (0-100) factoring in duration, efficiency,
  /// and stage composition. Deep + REM should be ~40-50% of total sleep.
  int get sleepQualityScore {
    if (sleepHours <= 0) return 0;

    // Duration score: 7-9h optimal
    double durationScore;
    if (sleepHours >= 7 && sleepHours <= 9) {
      durationScore = 100;
    } else if (sleepHours >= 6 && sleepHours < 7) {
      durationScore = 70 + (sleepHours - 6) * 30;
    } else if (sleepHours > 9 && sleepHours <= 10) {
      durationScore = 100 - (sleepHours - 9) * 20;
    } else {
      durationScore = (sleepHours / 7 * 60).clamp(0, 60);
    }

    // Efficiency score: 85%+ is good
    final effScore = (sleepEfficiency / 95 * 100).clamp(0.0, 100.0);

    // Deep + REM score: 40-50% of total is ideal
    final restorativePercent = deepSleepPercent + remSleepPercent;
    final restorativeScore = (restorativePercent / 45 * 100).clamp(0.0, 100.0);

    // Weighted: duration matters most, then efficiency, then composition
    final weighted = (durationScore * 0.45) + (effScore * 0.30) + (restorativeScore * 0.25);
    return weighted.round().clamp(0, 100);
  }

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

  // RIVL Health Score sub-scores (0-100 each), exposed for UI breakdown.
  double get scoreSteps => (steps / 10000 * 100).clamp(0.0, 100.0);
  double get scoreCalories => (activeCalories / 500 * 100).clamp(0.0, 100.0);
  double get scoreExercise => (exerciseMinutes / 30 * 100).clamp(0.0, 100.0);
  double get scoreSleep => sleepQualityScore.toDouble();
  double get scoreRhr => ((80 - restingHeartRate) / 30 * 100).clamp(0.0, 100.0);
  double get scoreHrv => ((hrv - 20) / 80 * 100).clamp(0.0, 100.0);

  // RIVL Health Score: composite of steps, active calories, exercise minutes,
  // sleep quality, resting HR, and HRV (0-100).
  int get rivlHealthScore {
    final weighted = (scoreSteps * 0.20) +
        (scoreCalories * 0.15) +
        (scoreExercise * 0.15) +
        (scoreSleep * 0.20) +
        (scoreRhr * 0.15) +
        (scoreHrv * 0.15);
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
    final demoSleep = 6.5 + rnd.nextDouble() * 2;
    final demoDeep = demoSleep * (0.15 + rnd.nextDouble() * 0.10);
    final demoRem = demoSleep * (0.18 + rnd.nextDouble() * 0.08);
    final demoLight = demoSleep - demoDeep - demoRem;
    final demoAwake = 0.2 + rnd.nextDouble() * 0.5;

    return HealthMetrics(
      steps: 6234 + rnd.nextInt(4000),
      heartRate: 68 + rnd.nextInt(20),
      restingHeartRate: 58 + rnd.nextInt(12),
      hrv: 45.0 + rnd.nextDouble() * 30,
      activeCalories: 320 + rnd.nextInt(300),
      distance: 2.5 + rnd.nextDouble() * 3,
      sleepHours: demoSleep,
      deepSleepHours: demoDeep,
      remSleepHours: demoRem,
      lightSleepHours: demoLight,
      awakeDuration: demoAwake,
      timeInBed: demoSleep + demoAwake + 0.1 + rnd.nextDouble() * 0.3,
      exerciseMinutes: 15 + rnd.nextInt(45),
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
          elapsedTime: Duration(minutes: 43 + rnd.nextInt(10)),
          activeCalories: 280 + rnd.nextInt(150),
          totalCalories: 350 + rnd.nextInt(150),
          elevationGain: 45 + rnd.nextDouble() * 80,
          avgPace: Duration(minutes: 8, seconds: 15 + rnd.nextInt(45)),
          avgHeartRate: 145 + rnd.nextInt(20),
          maxHeartRate: 172 + rnd.nextInt(15),
          avgCadence: 160 + rnd.nextInt(20),
        ),
        WorkoutData(
          type: 'STRENGTH_TRAINING',
          duration: Duration(minutes: 45 + rnd.nextInt(30)),
          calories: 200 + rnd.nextInt(100),
          distance: 0,
          date: now.subtract(const Duration(days: 2)),
          elapsedTime: Duration(hours: 1, minutes: 13 + rnd.nextInt(10)),
          activeCalories: 200 + rnd.nextInt(100),
          totalCalories: 248 + rnd.nextInt(80),
          avgHeartRate: 115 + rnd.nextInt(15),
          maxHeartRate: 148 + rnd.nextInt(15),
        ),
        WorkoutData(
          type: 'WALKING',
          duration: Duration(minutes: 25 + rnd.nextInt(20)),
          calories: 120 + rnd.nextInt(80),
          distance: 1.2 + rnd.nextDouble() * 1,
          date: now.subtract(const Duration(days: 3)),
          elapsedTime: Duration(minutes: 29 + rnd.nextInt(10)),
          activeCalories: 100 + rnd.nextInt(60),
          totalCalories: 131 + rnd.nextInt(40),
          avgPace: Duration(minutes: 17, seconds: 30 + rnd.nextInt(30)),
          avgHeartRate: 95 + rnd.nextInt(15),
          maxHeartRate: 118 + rnd.nextInt(20),
          avgCadence: 110 + rnd.nextInt(15),
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

  // Detailed stats (populated from Apple Health)
  final Duration? elapsedTime; // Total elapsed time including pauses
  final int? activeCalories;
  final int? totalCalories;
  final double? elevationGain; // in feet
  final double? avgPower; // in watts
  final int? avgCadence; // steps/min or rpm
  final Duration? avgPace; // per mile
  final int? avgHeartRate; // bpm
  final int? maxHeartRate; // bpm
  final double? avgSpeed; // mph
  final int? effortScore; // 1-10 Apple effort rating

  WorkoutData({
    required this.type,
    required this.duration,
    required this.calories,
    required this.distance,
    required this.date,
    this.elapsedTime,
    this.activeCalories,
    this.totalCalories,
    this.avgPower,
    this.avgCadence,
    this.avgPace,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgSpeed,
    this.elevationGain,
    this.effortScore,
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

  String get formattedElapsedTime {
    final d = elapsedTime ?? duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedPace {
    if (avgPace == null) return '--';
    final min = avgPace!.inMinutes;
    final sec = avgPace!.inSeconds % 60;
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  String get formattedDistance {
    if (distance <= 0) return '--';
    return '${distance.toStringAsFixed(2)} mi';
  }

  String get formattedSpeed {
    if (avgSpeed == null || avgSpeed! <= 0) return '--';
    return '${avgSpeed!.toStringAsFixed(1)} mph';
  }

  String get formattedElevation {
    if (elevationGain == null || elevationGain! <= 0) return '--';
    return '${elevationGain!.toStringAsFixed(0)} ft';
  }

  /// Whether this is a distance-based workout
  bool get isDistanceBased {
    final upper = type.toUpperCase();
    return upper == 'RUNNING' || upper == 'WALKING' || upper == 'CYCLING' ||
        upper == 'SWIMMING' || upper == 'HIKING' || upper == 'ELLIPTICAL' ||
        upper == 'ROWING';
  }

  /// Color associated with the workout type (Apple Fitness style)
  Color get accentColor {
    switch (type.toUpperCase()) {
      case 'RUNNING':
        return const Color(0xFF32D74B); // Green
      case 'WALKING':
        return const Color(0xFFFFD60A); // Yellow
      case 'CYCLING':
        return const Color(0xFF30D158); // Bright green
      case 'SWIMMING':
        return const Color(0xFF64D2FF); // Cyan
      case 'STRENGTH_TRAINING':
      case 'TRADITIONAL_STRENGTH_TRAINING':
      case 'FUNCTIONAL_STRENGTH_TRAINING':
        return const Color(0xFFFF9F0A); // Orange
      case 'HIIT':
      case 'HIGH_INTENSITY_INTERVAL_TRAINING':
        return const Color(0xFFFF453A); // Red
      case 'YOGA':
        return const Color(0xFFBF5AF2); // Purple
      default:
        return const Color(0xFF0A84FF); // Blue
    }
  }
}
