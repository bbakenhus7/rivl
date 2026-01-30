// screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/challenge_model.dart';
import '../../utils/theme.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/steps_card.dart';
import '../challenges/challenge_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: RivlColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: RivlColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'RIVL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HealthProvider>().refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Text(
                    'Hey, ${auth.user?.displayName.split(' ').first ?? 'there'}',
                    style: RivlTextStyles.heading2,
                  );
                },
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's crush some goals today",
                style: RivlTextStyles.bodySecondary,
              ),
              const SizedBox(height: 24),

              // Today's Steps Card
              const StepsCard(),
              const SizedBox(height: 24),

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
                          const Text(
                            'Active Challenges',
                            style: RivlTextStyles.heading3,
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to challenges tab
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...provider.activeChallenges.take(3).map((challenge) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChallengeCard(
                            challenge: challenge,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChallengeDetailScreen(
                                    challengeId: challenge.id,
                                  ),
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

              // Pending Challenges
              Consumer<ChallengeProvider>(
                builder: (context, provider, _) {
                  if (provider.pendingChallenges.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Pending Invites',
                        style: RivlTextStyles.heading3,
                      ),
                      const SizedBox(height: 12),
                      ...provider.pendingChallenges.map((challenge) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PendingChallengeCard(challenge: challenge),
                        );
                      }),
                    ],
                  );
                },
              ),

              // Weekly Stats
              const SizedBox(height: 24),
              const Text(
                'This Week',
                style: RivlTextStyles.heading3,
              ),
              const SizedBox(height: 12),
              const _WeeklyStatsCard(),

              // Quick Actions
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: RivlTextStyles.heading3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.person_add,
                      title: 'Find Friends',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.card_giftcard,
                      title: 'My Rewards',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.bar_chart,
                      title: 'Stats',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _PendingChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${challenge.creatorName} challenged you!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${challenge.stakeAmount.toInt()} stake • ${challenge.duration.displayName}',
                        style: RivlTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${challenge.prizeAmount.toInt()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: RivlColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<ChallengeProvider>().declineChallenge(challenge.id);
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ChallengeProvider>().acceptChallenge(challenge.id);
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatsCard extends StatelessWidget {
  const _WeeklyStatsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total',
                  value: health.formatSteps(health.weeklyTotal),
                ),
                _StatItem(
                  label: 'Average',
                  value: health.formatSteps(health.weeklyAverage),
                ),
                _StatItem(
                  label: 'Best Day',
                  value: health.formatSteps(health.weeklyBest),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: RivlColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: RivlTextStyles.caption,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: RivlColors.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
