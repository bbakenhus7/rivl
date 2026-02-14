// screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/health_metrics.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/challenge_card.dart';
import '../challenges/challenge_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import 'health_metric_detail_screen.dart';

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

  void _showAppInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: RivlColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('What is RIVL?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'RIVL is an AI-powered fitness competition app that turns your health data into real stakes. '
                'Challenge friends to step counts, distance, sleep, and more — with real money on the line.',
                style: TextStyle(fontSize: 15, color: ctx.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'How it works:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ctx.textSecondary),
              ),
              const SizedBox(height: 8),
              _InfoBullet(text: 'Connect your wearable (Apple Watch, Fitbit, Garmin, etc.)'),
              _InfoBullet(text: 'Challenge a friend and set a stake amount'),
              _InfoBullet(text: 'Compete on steps, distance, sleep, VO2 max, and more'),
              _InfoBullet(text: 'Winner takes the pot — AI anti-cheat keeps it fair'),
              _InfoBullet(text: 'Earn XP and unlock rewards through the Season Pass'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HealthProvider>().refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar with RIVL Logo
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: RivlColors.primaryDark,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/images/rivl_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RIVL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: RivlColors.primaryDeepGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // RIVL Logo
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              'assets/images/rivl_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RIVL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return Text(
                                    'AI-Powered Fitness Competition',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Streak badge
                Consumer<StreakProvider>(
                  builder: (context, streak, _) {
                    if (streak.currentStreak <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Chip(
                        avatar: const Icon(Icons.whatshot, color: Colors.orange, size: 18),
                        label: Text(
                          '${streak.currentStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),
                // Notification bell with badge
                Consumer<NotificationProvider>(
                  builder: (context, notif, _) {
                    return IconButton(
                      icon: Badge(
                        isLabelVisible: notif.hasUnread,
                        label: Text('${notif.unreadCount}'),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    );
                  },
                ),
                // Info button
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () => _showAppInfo(context),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Glance: Earnings + Active Pot + Win Streak
                  StaggeredListAnimation(
                    index: 0,
                    child: const _QuickGlanceRow(),
                  ),
                  const SizedBox(height: 16),

                  // Pending challenges banner (action required)
                  Consumer<ChallengeProvider>(
                    builder: (context, provider, _) {
                      final pending = provider.pendingChallenges;
                      if (pending.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeIn(
                            child: Row(
                              children: [
                                Icon(Icons.notifications_active, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Action Required',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pending.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...pending.take(2).map((challenge) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FadeIn(
                                delay: const Duration(milliseconds: 100),
                                child: ChallengeCard(
                                  challenge: challenge,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChallengeDetailScreen(challengeId: challenge.id),
                                      ),
                                    );
                                  },
                                  onAccept: () => provider.acceptChallenge(challenge.id),
                                  onDecline: () => provider.declineChallenge(challenge.id),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),

                  // Recovery & Strain Cards
                  StaggeredListAnimation(
                    index: 1,
                    child: const _RecoveryStrainRow(),
                  ),
                  const SizedBox(height: 16),

                  // Hero Activity Rings Card
                  StaggeredListAnimation(
                    index: 2,
                    child: const _ActivityBarsCard(),
                  ),
                  const SizedBox(height: 16),

                  // Health Metrics Grid
                  StaggeredListAnimation(
                    index: 3,
                    child: const _HealthMetricsGrid(),
                  ),
                  const SizedBox(height: 16),

                  // Weekly Steps Chart
                  StaggeredListAnimation(
                    index: 4,
                    child: const _WeeklyStepsCard(),
                  ),
                  const SizedBox(height: 16),

                  // Recent Workouts
                  StaggeredListAnimation(
                    index: 5,
                    child: const _RecentWorkoutsCard(),
                  ),
                  const SizedBox(height: 16),

                  // Active Challenges
                  FadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: Consumer<ChallengeProvider>(
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
                                const Text('Active Challenges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                title: 'Exertion',
                score: health.strainScore,
                status: _getStrainStatus(health.strainScore),
                color: _getStrainColor(health.strainScore),
                icon: Icons.local_fire_department,
                maxScore: 100,
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
    if (score >= 85) return RivlColors.error;
    if (score >= 65) return Colors.orange;
    if (score >= 40) return Colors.lightGreen;
    return RivlColors.info;
  }

  String _getStrainStatus(int score) {
    if (score >= 85) return 'Overreaching';
    if (score >= 65) return 'High';
    if (score >= 40) return 'Moderate';
    return 'Light';
  }
}

// Robinhood-style bold score card with AnimatedCounter
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.surface, color.withOpacity(0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCounter(
            value: score,
            duration: const Duration(milliseconds: 800),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// Hero Activity Rings Card (circular rings replacing linear bars)
class _ActivityBarsCard extends StatelessWidget {
  const _ActivityBarsCard();

  String _getMotivationalMessage(double stepsProgress) {
    if (stepsProgress >= 1.0) return 'Goal smashed!';
    if (stepsProgress >= 0.75) return 'Almost there!';
    if (stepsProgress >= 0.5) return 'Crushing it!';
    if (stepsProgress >= 0.25) return 'Great start!';
    return "Let's get moving!";
  }

  Color _getMotivationalColor(double stepsProgress) {
    if (stepsProgress >= 1.0) return RivlColors.success;
    if (stepsProgress >= 0.75) return Colors.orange;
    if (stepsProgress >= 0.5) return RivlColors.primary;
    if (stepsProgress >= 0.25) return Colors.lightGreen;
    return Colors.grey;
  }

  IconData _getMotivationalIcon(double stepsProgress) {
    if (stepsProgress >= 1.0) return Icons.emoji_events;
    if (stepsProgress >= 0.75) return Icons.trending_up;
    if (stepsProgress >= 0.5) return Icons.bolt;
    if (stepsProgress >= 0.25) return Icons.thumb_up_alt_outlined;
    return Icons.directions_walk;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final stepsProgress = health.metrics.stepsProgress;
        final caloriesProgress = health.metrics.caloriesProgress;
        final distanceProgress = health.metrics.distanceProgress;
        final motivationalMsg = _getMotivationalMessage(stepsProgress);
        final motivationalColor = _getMotivationalColor(stepsProgress);
        final motivationalIcon = _getMotivationalIcon(stepsProgress);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.surface, RivlColors.primary.withOpacity(0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: RivlColors.primary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title row with motivational badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Activity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  FadeIn(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: motivationalColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(motivationalIcon, color: motivationalColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            motivationalMsg,
                            style: TextStyle(
                              color: motivationalColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Concentric Activity Rings
              SizedBox(
                width: 190,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring - Steps (blue)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: stepsProgress.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 190,
                          height: 190,
                          child: CustomPaint(
                            painter: _ActivityRingPainter(
                              progress: value,
                              color: RivlColors.primary,
                              strokeWidth: 14,
                            ),
                          ),
                        );
                      },
                    ),
                    // Middle ring - Calories (green)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: caloriesProgress.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 144,
                          height: 144,
                          child: CustomPaint(
                            painter: _ActivityRingPainter(
                              progress: value,
                              color: Colors.green,
                              strokeWidth: 14,
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner ring - Distance (cyan)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: distanceProgress.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 98,
                          height: 98,
                          child: CustomPaint(
                            painter: _ActivityRingPainter(
                              progress: value,
                              color: Colors.cyan,
                              strokeWidth: 14,
                            ),
                          ),
                        );
                      },
                    ),
                    // Center: animated step count
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedCounter(
                          value: health.todaySteps,
                          duration: const Duration(milliseconds: 1000),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'steps',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Ring legend row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRingLegend(
                    context: context,
                    color: RivlColors.primary,
                    label: 'Steps',
                    value: health.formatSteps(health.todaySteps),
                    goal: '${health.dailyGoal ~/ 1000}K',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.surfaceVariant,
                  ),
                  _buildRingLegend(
                    context: context,
                    color: Colors.green,
                    label: 'Calories',
                    value: health.formatCalories(health.activeCalories),
                    goal: '${health.metrics.caloriesGoal}',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.surfaceVariant,
                  ),
                  _buildRingLegend(
                    context: context,
                    color: Colors.cyan,
                    label: 'Distance',
                    value: health.formatDistance(health.distance),
                    goal: '${health.metrics.distanceGoal.toInt()} mi',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRingLegend({
    required BuildContext context,
    required Color color,
    required String label,
    required String value,
    required String goal,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          '/ $goal',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// Custom painter for circular activity rings
class _ActivityRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ActivityRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Original _ActivityBar kept for compatibility
class _ActivityBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String goal;
  final double progress;
  final Color color;

  const _ActivityBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              ' / $goal',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Progress bar
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Health Metrics Grid with larger tiles
class _HealthMetricsGrid extends StatelessWidget {
  const _HealthMetricsGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Health Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: _MetricTile(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    value: health.heartRate > 0 ? '${health.heartRate}' : '--',
                    unit: 'bpm',
                    color: Colors.red,
                    metricType: HealthMetricType.heartRate,
                    numericValue: health.heartRate > 0 ? health.heartRate : null,
                    description: 'Heart rate measures how many times your heart beats per minute. Tracking it during exercise shows how hard your cardiovascular system is working, and monitoring trends over time can reveal improvements in fitness or flag potential health concerns early.',
                  ),
                ),
                FadeIn(
                  delay: const Duration(milliseconds: 150),
                  child: _MetricTile(
                    icon: Icons.bedtime,
                    label: 'Sleep',
                    value: health.sleepHours > 0 ? health.formatSleep(health.sleepHours) : '--',
                    unit: '',
                    color: Colors.indigo,
                    metricType: HealthMetricType.sleep,
                    description: 'Sleep is when your body recovers, builds muscle, and consolidates memory. Getting 7-9 hours of quality sleep each night improves athletic performance, mental clarity, and immune function. Poor sleep undermines even the best training.',
                  ),
                ),
                FadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: _MetricTile(
                    icon: Icons.show_chart,
                    label: 'HRV',
                    value: health.hrv > 0 ? health.formatHRV(health.hrv) : '--',
                    unit: 'ms',
                    color: Colors.purple,
                    metricType: HealthMetricType.hrv,
                    numericValue: health.hrv > 0 ? health.hrv.round() : null,
                    description: 'Heart Rate Variability (HRV) measures the variation in time between heartbeats. A higher HRV generally indicates better cardiovascular fitness and recovery. It\'s one of the best indicators of how ready your body is to perform and whether you\'re overtraining.',
                  ),
                ),
                FadeIn(
                  delay: const Duration(milliseconds: 250),
                  child: _MetricTile(
                    icon: Icons.monitor_heart,
                    label: 'Resting HR',
                    value: health.restingHeartRate > 0 ? '${health.restingHeartRate}' : '--',
                    unit: 'bpm',
                    color: Colors.pink,
                    metricType: HealthMetricType.restingHeartRate,
                    numericValue: health.restingHeartRate > 0 ? health.restingHeartRate : null,
                    description: 'Resting heart rate is your heart rate when you\'re completely at rest. A lower resting heart rate typically means your heart is more efficient. Athletes often have resting rates between 40-60 bpm. Tracking it over time shows your cardiovascular fitness improving.',
                  ),
                ),
                FadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: _MetricTile(
                    icon: Icons.air,
                    label: 'Blood Oxygen',
                    value: health.bloodOxygen > 0 ? health.formatBloodOxygen(health.bloodOxygen) : '--',
                    unit: '',
                    color: Colors.teal,
                    metricType: HealthMetricType.bloodOxygen,
                    description: 'Blood oxygen (SpO2) measures the percentage of oxygen your red blood cells are carrying. Normal levels are 95-100%. Tracking it helps monitor respiratory health, sleep quality, and how well your body delivers oxygen to muscles during intense exercise.',
                  ),
                ),
                FadeIn(
                  delay: const Duration(milliseconds: 350),
                  child: _MetricTile(
                    icon: Icons.speed,
                    label: 'VO2 Max',
                    value: health.vo2Max > 0 ? health.formatVO2Max(health.vo2Max) : '--',
                    unit: 'ml/kg/min',
                    color: Colors.orange,
                    metricType: HealthMetricType.vo2Max,
                    numericValue: health.vo2Max > 0 ? health.vo2Max.round() : null,
                    description: 'VO2 Max is the maximum amount of oxygen your body can use during intense exercise. It\'s considered the gold standard measure of aerobic fitness. Higher VO2 Max values are linked to better endurance, longer lifespan, and reduced risk of chronic disease.',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// Larger, more tappable metric tile with optional AnimatedCounter
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String description;
  final int? numericValue;
  final HealthMetricType metricType;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.description,
    required this.metricType,
    this.numericValue,
  });

  void _showDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthMetricDetailScreen(
          metricType: metricType,
          icon: icon,
          label: label,
          currentValue: value,
          unit: unit,
          color: color,
          description: description,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.surface, color.withOpacity(0.04)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.15), color.withOpacity(0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: context.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (numericValue != null && value != '--')
                  AnimatedCounter(
                    value: numericValue!,
                    duration: const Duration(milliseconds: 700),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

// Weekly Steps Chart with wider bars and rounded caps
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
            gradient: LinearGradient(
              colors: [context.surface, RivlColors.primary.withOpacity(0.03)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: RivlColors.primary.withOpacity(0.05),
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
                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 130,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final daySteps = index < steps.length ? steps[index].steps : 0;
                    final barHeight = maxSteps > 0 ? (daySteps / maxSteps * 90).clamp(8.0, 90.0) : 8.0;
                    final isToday = index == steps.length - 1;
                    final dayName = _getDayName(index, steps.length);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: barHeight),
                          duration: Duration(milliseconds: 600 + (index * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedHeight, _) {
                            return Container(
                              width: 40,
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? RivlColors.primary
                                    : RivlColors.primary.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isToday
                                    ? [
                                        BoxShadow(
                                          color: RivlColors.primary.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isToday ? RivlColors.primary : context.textSecondary,
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
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
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
            gradient: LinearGradient(
              colors: [context.surface, RivlColors.primary.withOpacity(0.03)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: RivlColors.primary.withOpacity(0.05),
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
              child: Icon(workout.iconData, color: RivlColors.primary, size: 22),
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
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(workout.date),
            style: TextStyle(color: context.textSecondary, fontSize: 12),
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

/// Top-of-page glance row: Earnings, Active Pot, Win Streak
class _QuickGlanceRow extends StatelessWidget {
  const _QuickGlanceRow();

  @override
  Widget build(BuildContext context) {
    return Consumer3<WalletProvider, ChallengeProvider, StreakProvider>(
      builder: (context, wallet, challenges, streak, _) {
        // Calculate total active pot (sum of prize amounts from active challenges)
        final activePot = challenges.activeChallenges.fold<double>(
          0,
          (sum, c) => sum + c.prizeAmount,
        );

        return Row(
          children: [
            Expanded(
              child: _GlanceStat(
                icon: Icons.account_balance_wallet,
                label: 'Balance',
                value: '\$${wallet.balance.toStringAsFixed(0)}',
                color: RivlColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlanceStat(
                icon: Icons.local_fire_department,
                label: 'At Stake',
                value: activePot > 0 ? '\$${activePot.toStringAsFixed(0)}' : '--',
                color: RivlColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlanceStat(
                icon: Icons.whatshot,
                label: 'Streak',
                value: '${streak.currentStreak}d',
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GlanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.surface, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final String text;
  const _InfoBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: RivlColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
