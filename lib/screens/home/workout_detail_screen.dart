// screens/home/workout_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/health_metrics.dart';
import '../../utils/theme.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutData workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header with workout type and date
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      workout.accentColor.withOpacity(0.2),
                      isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: workout.accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                workout.iconData,
                                color: workout.accentColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workout.displayName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatFullDate(workout.date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Primary stats row
                  _StatsGrid(workout: workout),

                  const SizedBox(height: 20),

                  // Workout summary card
                  _SummaryCard(workout: workout),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$weekday, $month ${date.day} at $hour:$minute $amPm';
  }
}

// =============================================================================
// STATS GRID (Apple Fitness style 2-column grid)
// =============================================================================

class _StatsGrid extends StatelessWidget {
  final WorkoutData workout;

  const _StatsGrid({required this.workout});

  @override
  Widget build(BuildContext context) {
    final stats = _buildStatsList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _StatTile(
          label: stat.label,
          value: stat.value,
          unit: stat.unit,
          accentColor: workout.accentColor,
        );
      },
    );
  }

  List<_StatItem> _buildStatsList() {
    final stats = <_StatItem>[];

    // Workout Time (always shown)
    stats.add(_StatItem(
      label: 'Workout Time',
      value: workout.formattedElapsedTime,
      unit: '',
    ));

    // Distance (for distance-based workouts)
    if (workout.isDistanceBased && workout.distance > 0) {
      stats.add(_StatItem(
        label: 'Distance',
        value: workout.distance.toStringAsFixed(2),
        unit: 'mi',
      ));
    }

    // Active Calories
    stats.add(_StatItem(
      label: 'Active Calories',
      value: '${workout.activeCalories ?? workout.calories}',
      unit: 'cal',
    ));

    // Total Calories
    if (workout.totalCalories != null) {
      stats.add(_StatItem(
        label: 'Total Calories',
        value: '${workout.totalCalories}',
        unit: 'cal',
      ));
    }

    // Avg Pace
    if (workout.avgPace != null && workout.isDistanceBased) {
      stats.add(_StatItem(
        label: 'Avg. Pace',
        value: workout.formattedPace,
        unit: '/mi',
      ));
    }

    // Avg Heart Rate
    if (workout.avgHeartRate != null) {
      stats.add(_StatItem(
        label: 'Avg. Heart Rate',
        value: '${workout.avgHeartRate}',
        unit: 'BPM',
      ));
    }

    // Max Heart Rate
    if (workout.maxHeartRate != null) {
      stats.add(_StatItem(
        label: 'Max Heart Rate',
        value: '${workout.maxHeartRate}',
        unit: 'BPM',
      ));
    }

    // Elevation Gain
    if (workout.elevationGain != null && workout.elevationGain! > 0) {
      stats.add(_StatItem(
        label: 'Elevation Gain',
        value: workout.formattedElevation,
        unit: '',
      ));
    }

    // Avg Cadence
    if (workout.avgCadence != null) {
      stats.add(_StatItem(
        label: 'Avg. Cadence',
        value: '${workout.avgCadence}',
        unit: 'SPM',
      ));
    }

    // Avg Speed (for cycling)
    if (workout.avgSpeed != null &&
        workout.type.toUpperCase() == 'CYCLING') {
      stats.add(_StatItem(
        label: 'Avg. Speed',
        value: workout.formattedSpeed,
        unit: '',
      ));
    }

    // Effort
    if (workout.effortScore != null) {
      stats.add(_StatItem(
        label: 'Effort',
        value: '${workout.effortScore}',
        unit: '/ 10',
      ));
    }

    return stats;
  }
}

class _StatItem {
  final String label;
  final String value;
  final String unit;

  _StatItem({required this.label, required this.value, required this.unit});
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color accentColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUMMARY CARD
// =============================================================================

class _SummaryCard extends StatelessWidget {
  final WorkoutData workout;

  const _SummaryCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: workout.formattedDuration,
            color: workout.accentColor,
          ),
          if (workout.isDistanceBased && workout.distance > 0)
            _SummaryRow(
              icon: Icons.straighten,
              label: 'Distance',
              value: workout.formattedDistance,
              color: workout.accentColor,
            ),
          _SummaryRow(
            icon: Icons.local_fire_department,
            label: 'Calories',
            value: '${workout.totalCalories ?? workout.calories} cal',
            color: Colors.orange,
          ),
          if (workout.avgHeartRate != null)
            _SummaryRow(
              icon: Icons.favorite,
              label: 'Heart Rate',
              value: '${workout.avgHeartRate} avg / ${workout.maxHeartRate ?? "--"} max BPM',
              color: Colors.red,
            ),
          if (workout.avgPace != null && workout.isDistanceBased)
            _SummaryRow(
              icon: Icons.speed,
              label: 'Pace',
              value: '${workout.formattedPace} /mi',
              color: workout.accentColor,
              isLast: workout.avgCadence == null && workout.elevationGain == null,
            ),
          if (workout.avgCadence != null)
            _SummaryRow(
              icon: Icons.directions_walk,
              label: 'Cadence',
              value: '${workout.avgCadence} SPM',
              color: workout.accentColor,
              isLast: workout.elevationGain == null,
            ),
          if (workout.elevationGain != null && workout.elevationGain! > 0)
            _SummaryRow(
              icon: Icons.terrain,
              label: 'Elevation',
              value: workout.formattedElevation,
              color: workout.accentColor,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey[200],
          ),
      ],
    );
  }
}
