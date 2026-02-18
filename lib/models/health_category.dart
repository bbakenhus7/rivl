// models/health_category.dart

import 'package:flutter/material.dart';
import '../screens/home/health_metric_detail_screen.dart';

/// Represents a grouping of health metrics into a dashboard category.
enum HealthCategory {
  heartHealth,
  activityPerformance,
  sleepRecovery,
  overall,
}

/// Static configuration for each health category.
class HealthCategoryConfig {
  final String name;
  final IconData icon;
  final Color accentColor;
  final List<HealthMetricType> metrics;

  const HealthCategoryConfig({
    required this.name,
    required this.icon,
    required this.accentColor,
    required this.metrics,
  });

  static HealthCategoryConfig of(HealthCategory category) {
    switch (category) {
      case HealthCategory.heartHealth:
        return const HealthCategoryConfig(
          name: 'Heart Health',
          icon: Icons.favorite_rounded,
          accentColor: Color(0xFFE91E63),
          metrics: [
            HealthMetricType.heartRate,
            HealthMetricType.restingHeartRate,
            HealthMetricType.hrv,
          ],
        );
      case HealthCategory.activityPerformance:
        return const HealthCategoryConfig(
          name: 'Activity',
          icon: Icons.fitness_center_rounded,
          accentColor: Color(0xFF5C6BC0),
          metrics: [
            HealthMetricType.exertion,
            HealthMetricType.vo2Max,
          ],
        );
      case HealthCategory.sleepRecovery:
        return const HealthCategoryConfig(
          name: 'Sleep & Recovery',
          icon: Icons.bedtime_rounded,
          accentColor: Color(0xFF3949AB),
          metrics: [
            HealthMetricType.sleep,
            HealthMetricType.recovery,
            HealthMetricType.bloodOxygen,
          ],
        );
      case HealthCategory.overall:
        return const HealthCategoryConfig(
          name: 'Overall',
          icon: Icons.insights_rounded,
          accentColor: Color(0xFF6C5CE7),
          metrics: [
            HealthMetricType.healthScore,
          ],
        );
    }
  }
}
