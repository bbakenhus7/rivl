// screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/health_metrics.dart';
import '../../utils/theme.dart';
import '../../widgets/challenge_card.dart';
import '../challenges/challenge_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HealthProvider>().refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: RivlColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: RivlColors.primaryGradient,
                  ),
                ),
                title: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = auth.user?.displayName.split(' ').first ?? 'there';
                    return Text(
                      'Hey, $name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  },
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Recovery & Strain Cards
                  const _RecoveryStrainRow(),
                  const SizedBox(height: 16),

                  // Main Activity Ring Card
                  const _ActivityRingsCard(),
                  const SizedBox(height: 16),

                  // Health Metrics Grid
                  const _HealthMetricsGrid(),
                  const SizedBox(height: 16),

                  // Weekly Steps Chart
                  const _WeeklyStepsCard(),
                  const SizedBox(height: 16),

                  // Recent Workouts
                  const _RecentWorkoutsCard(),
                  const SizedBox(height: 16),

                  // Active Challenges
                  Consumer<ChallengeProvider>(
                    builder: (context, provider, _) {
                      if (provider.activeChallenges.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Active Challenges', style: RivlTextStyles.heading3),
                              TextButton(onPressed: () {}, child: const Text('See All')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...provider.activeChallenges.take(2).map((challenge) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ChallengeCard(
                                challenge: challenge,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChallengeDetailScreen(challengeId: challenge.id),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recovery & Strain Row
class _RecoveryStrainRow extends StatelessWidget {
  const _RecoveryStrainRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return Row(
          children: [
            Expanded(
              child: _ScoreCard(
                title: 'Recovery',
                score: health.recoveryScore,
                status: health.recoveryStatus,
                color: _getRecoveryColor(health.recoveryScore),
                icon: Icons.battery_charging_full,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScoreCard(
                title: 'Strain',
                score: health.strainScore,
                status: _getStrainStatus(health.strainScore),
                color: _getStrainColor(health.strainScore),
                icon: Icons.local_fire_department,
                maxScore: 21,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getRecoveryColor(int score) {
    if (score >= 80) return RivlColors.success;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return RivlColors.error;
  }

  Color _getStrainColor(int score) {
    if (score >= 18) return RivlColors.error;
    if (score >= 14) return Colors.orange;
    if (score >= 10) return Colors.lightGreen;
    return RivlColors.info;
  }

  String _getStrainStatus(int score) {
    if (score >= 18) return 'Overreaching';
    if (score >= 14) return 'High';
    if (score >= 10) return 'Moderate';
    return 'Light';
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final String status;
  final Color color;
  final IconData icon;
  final int maxScore;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.status,
    required this.color,
    required this.icon,
    this.maxScore = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (maxScore != 100)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 2),
                  child: Text('/$maxScore', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Activity Rings Card (like Apple Watch)
class _ActivityRingsCard extends StatelessWidget {
  const _ActivityRingsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Activity Rings
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Steps ring (outer)
                    _ActivityRing(
                      progress: health.metrics.stepsProgress,
                      color: RivlColors.primary,
                      size: 140,
                      strokeWidth: 14,
                    ),
                    // Calories ring (middle)
                    _ActivityRing(
                      progress: health.metrics.caloriesProgress,
                      color: Colors.green,
                      size: 110,
                      strokeWidth: 14,
                    ),
                    // Distance ring (inner)
                    _ActivityRing(
                      progress: health.metrics.distanceProgress,
                      color: Colors.cyan,
                      size: 80,
                      strokeWidth: 14,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RingStat(
                      label: 'Steps',
                      value: health.formatSteps(health.todaySteps),
                      goal: '${health.dailyGoal ~/ 1000}K',
                      color: RivlColors.primary,
                    ),
                    const SizedBox(height: 16),
                    _RingStat(
                      label: 'Calories',
                      value: health.formatCalories(health.activeCalories),
                      goal: '${health.metrics.caloriesGoal}',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _RingStat(
                      label: 'Distance',
                      value: health.formatDistance(health.distance),
                      goal: '${health.metrics.distanceGoal.toInt()} mi',
                      color: Colors.cyan,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;

  const _ActivityRing({
    required this.progress,
    required this.color,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background ring
          CircularProgressIndicator(
            value: 1,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(color.withOpacity(0.2)),
          ),
          // Progress ring
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
        ],
      ),
    );
  }
}

class _RingStat extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final Color color;

  const _RingStat({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Row(
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(' / $goal', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Health Metrics Grid
class _HealthMetricsGrid extends StatelessWidget {
  const _HealthMetricsGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Health Metrics', style: RivlTextStyles.heading3),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _MetricTile(
                  icon: Icons.favorite,
                  label: 'Heart Rate',
                  value: health.heartRate > 0 ? '${health.heartRate}' : '--',
                  unit: 'bpm',
                  color: Colors.red,
                ),
                _MetricTile(
                  icon: Icons.bedtime,
                  label: 'Sleep',
                  value: health.sleepHours > 0 ? health.formatSleep(health.sleepHours) : '--',
                  unit: '',
                  color: Colors.indigo,
                ),
                _MetricTile(
                  icon: Icons.show_chart,
                  label: 'HRV',
                  value: health.hrv > 0 ? health.formatHRV(health.hrv) : '--',
                  unit: 'ms',
                  color: Colors.purple,
                ),
                _MetricTile(
                  icon: Icons.monitor_heart,
                  label: 'Resting HR',
                  value: health.restingHeartRate > 0 ? '${health.restingHeartRate}' : '--',
                  unit: 'bpm',
                  color: Colors.pink,
                ),
                _MetricTile(
                  icon: Icons.air,
                  label: 'Blood Oxygen',
                  value: health.bloodOxygen > 0 ? health.formatBloodOxygen(health.bloodOxygen) : '--',
                  unit: '',
                  color: Colors.teal,
                ),
                _MetricTile(
                  icon: Icons.speed,
                  label: 'VO2 Max',
                  value: health.vo2Max > 0 ? health.formatVO2Max(health.vo2Max) : '--',
                  unit: 'ml/kg/min',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Weekly Steps Chart
class _WeeklyStepsCard extends StatelessWidget {
  const _WeeklyStepsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final steps = health.weeklySteps;
        final maxSteps = steps.isNotEmpty
            ? steps.map((d) => d.steps).reduce((a, b) => a > b ? a : b)
            : 10000;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('This Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${health.formatSteps(health.weeklyTotal)} total',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final daySteps = index < steps.length ? steps[index].steps : 0;
                    final height = maxSteps > 0 ? (daySteps / maxSteps * 80).clamp(8.0, 80.0) : 8.0;
                    final isToday = index == steps.length - 1;
                    final dayName = _getDayName(index, steps.length);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 32,
                          height: height,
                          decoration: BoxDecoration(
                            color: isToday ? RivlColors.primary : RivlColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isToday ? RivlColors.primary : Colors.grey[600],
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeeklyStat(label: 'Average', value: health.formatSteps(health.weeklyAverage)),
                  _WeeklyStat(label: 'Best Day', value: health.formatSteps(health.weeklyBest)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int index, int totalDays) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: totalDays - 1 - index));
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return days[date.weekday % 7];
  }
}

class _WeeklyStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeeklyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

// Recent Workouts Card
class _RecentWorkoutsCard extends StatelessWidget {
  const _RecentWorkoutsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final workouts = health.recentWorkouts;
        if (workouts.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Workouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ...workouts.take(3).map((workout) => _WorkoutTile(workout: workout)),
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutData workout;

  const _WorkoutTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RivlColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(workout.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${workout.formattedDuration} • ${workout.calories} cal',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(workout.date),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${diff}d ago';
  }
}
