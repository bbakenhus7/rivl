// screens/stats/stats_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../utils/theme.dart';
import '../../models/achievement_model.dart';

class StatsDashboardScreen extends StatelessWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
      ),
      body: Consumer<StatsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.stats == null) {
            return const Center(child: Text('No stats available'));
          }

          final stats = provider.stats!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Win/Loss Record Card
                _StatsCard(
                  title: 'Record',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Wins',
                        value: '${stats.wins}',
                        color: Colors.green,
                        icon: Icons.trending_up,
                      ),
                      _StatItem(
                        label: 'Losses',
                        value: '${stats.losses}',
                        color: Colors.red,
                        icon: Icons.trending_down,
                      ),
                      _StatItem(
                        label: 'Win Rate',
                        value: stats.winRateDisplay,
                        color: RivlColors.primary,
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Earnings Card
                _StatsCard(
                  title: 'Earnings',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'Total Earned',
                            value: '\$${stats.totalEarnings.toInt()}',
                            color: Colors.green,
                            icon: Icons.attach_money,
                          ),
                          _StatItem(
                            label: 'Total Spent',
                            value: '\$${stats.totalSpent.toInt()}',
                            color: Colors.orange,
                            icon: Icons.money_off,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: stats.netProfit >= 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              stats.netProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              color: stats.netProfit >= 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Net Profit: \$${stats.netProfit.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: stats.netProfit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Streaks Card
                _StatsCard(
                  title: 'Streaks',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Current',
                        value: '${stats.currentStreak}',
                        color: Colors.orange,
                        icon: Icons.local_fire_department,
                      ),
                      _StatItem(
                        label: 'Longest',
                        value: '${stats.longestStreak}',
                        color: Colors.deepOrange,
                        icon: Icons.military_tech,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Activity Card
                _StatsCard(
                  title: 'Activity',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Total Challenges',
                        value: '${stats.totalChallenges}',
                        color: RivlColors.primary,
                        icon: Icons.sports_score,
                      ),
                      _StatItem(
                        label: 'Active Now',
                        value: '${stats.activeChallenges}',
                        color: Colors.blue,
                        icon: Icons.play_circle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Achievements Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Achievements', style: RivlTextStyles.heading3),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/achievements');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AchievementsPreview(
                  unlockedIds: stats.achievementIds,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: RivlTextStyles.heading3),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: RivlTextStyles.caption),
      ],
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  final List<String> unlockedIds;

  const _AchievementsPreview({required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    final allAchievements = AchievementModel.getAllAchievements();
    final unlockedAchievements = allAchievements
        .where((a) => unlockedIds.contains(a.id))
        .take(6)
        .toList();

    if (unlockedAchievements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No achievements yet',
                  style: RivlTextStyles.bodySecondary,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Win challenges to unlock achievements!',
                  style: RivlTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: unlockedAchievements.map((achievement) {
        return Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: achievement.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: achievement.color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
