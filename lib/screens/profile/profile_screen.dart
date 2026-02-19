// screens/profile/profile_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/cached_avatar.dart';
import '../wallet/wallet_screen.dart';
import '../notifications/notifications_screen.dart';
import 'health_connection_screen.dart';
import 'help_support_screen.dart';
import 'friends_screen.dart';
import '../../providers/friend_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();
      final userId = authProvider.user?.id ?? 'demo-user';
      walletProvider.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user ?? UserModel.demo();

          return CustomScrollView(
            slivers: [
              // Gradient header with profile info — condenses on scroll
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: RivlColors.primary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: () => _showSettings(context),
                  ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final statusBarHeight = MediaQuery.of(context).padding.top;
                    final collapsedHeight = kToolbarHeight + statusBarHeight;
                    final expandedHeight = 260 + statusBarHeight;
                    // 0.0 = fully collapsed, 1.0 = fully expanded
                    final t = ((top - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

                    // Sizes interpolated between collapsed and expanded
                    final avatarRadius = 16.0 + (28.0 * t); // 16 → 44
                    final nameFontSize = 16.0 + (6.0 * t);  // 16 → 22
                    final usernameFontSize = 12.0 + (3.0 * t); // 12 → 15
                    final borderWidth = 1.0 + (1.0 * t);    // 1 → 2

                    return Container(
                      decoration: const BoxDecoration(
                        gradient: RivlColors.primaryDeepGradient,
                      ),
                      child: SafeArea(
                        child: t > 0.3
                            // --- EXPANDED: centered column layout ---
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 16 * t),
                                  Semantics(
                                    label: 'Profile picture for ${user.displayName}',
                                    image: true,
                                    child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: borderWidth,
                                      ),
                                    ),
                                    child: CachedAvatar(
                                      imageUrl: user.profileImageUrl,
                                      displayName: user.displayName,
                                      radius: avatarRadius,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      textColor: Colors.white,
                                    ),
                                  ),
                                  ),
                                  SizedBox(height: 8 * t + 4),
                                  Text(
                                    user.displayName,
                                    style: TextStyle(
                                      fontSize: nameFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${user.username}',
                                    style: TextStyle(
                                      fontSize: usernameFontSize,
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                                  ),
                                  if (t > 0.6) ...[
                                    SizedBox(height: 8 * t),
                                    Opacity(
                                      opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (user.isVerified)
                                            _HeaderBadge(icon: Icons.verified, label: 'Verified'),
                                          if (user.isPremium)
                                            _HeaderBadge(icon: Icons.star, label: 'Premium'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            // --- COLLAPSED: compact row in app bar ---
                            : Padding(
                                padding: const EdgeInsets.only(left: 16, right: 56),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: CachedAvatar(
                                          imageUrl: user.profileImageUrl,
                                          displayName: user.displayName,
                                          radius: 16,
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          textColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.displayName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '@${user.username}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Demo mode banner
                    if (authProvider.user == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RivlColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RivlColors.info.withOpacity(0.15)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: RivlColors.info, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo Mode — Sign in to see your real stats',
                                style: TextStyle(color: RivlColors.info, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Quick Stats, Wallet, Performance, Attributes, Achievements
                    // Show skeleton while initial data is loading
                    Consumer2<WalletProvider, HealthProvider>(
                      builder: (context, wallet, health, _) {
                        if (authProvider.isLoading || wallet.isLoading || health.isLoading) {
                          return const _ProfileStatsSkeleton();
                        }
                        return Column(
                          children: [
                            // Quick Stats Row (Robinhood-style bold numbers)
                            SlideIn(
                              child: _QuickStatsRow(user: user),
                            ),
                            const SizedBox(height: 16),

                            // Wallet Card
                            SlideIn(
                              delay: const Duration(milliseconds: 50),
                              child: _WalletQuickAccess(),
                            ),
                            const SizedBox(height: 16),

                            // Detailed Stats
                            SlideIn(
                              delay: const Duration(milliseconds: 100),
                              child: _DetailedStats(user: user),
                            ),
                            const SizedBox(height: 16),

                            // Personal Attributes
                            SlideIn(
                              delay: const Duration(milliseconds: 150),
                              child: _PersonalAttributes(user: user),
                            ),
                            const SizedBox(height: 16),

                            // Achievements
                            SlideIn(
                              delay: const Duration(milliseconds: 200),
                              child: _AchievementsSection(user: user),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Referral
                    SlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: _ReferralSection(user: user),
                    ),
                    const SizedBox(height: 16),

                    // Account Actions
                    SlideIn(
                      delay: const Duration(milliseconds: 250),
                      child: _AccountActions(),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Bold number stats at top (like Robinhood portfolio summary)
class _QuickStatsRow extends StatelessWidget {
  final UserModel user;

  const _QuickStatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickStat(value: '${user.wins}', label: 'Wins', color: RivlColors.success)),
        Container(width: 1, height: 40, color: context.surfaceVariant),
        Expanded(child: _QuickStat(value: '${user.losses}', label: 'Losses', color: RivlColors.error)),
        Container(width: 1, height: 40, color: context.surfaceVariant),
        Expanded(child: _QuickStat(value: user.winPercentage, label: 'Win Rate', color: RivlColors.primary)),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _QuickStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WalletQuickAccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        return Semantics(
          label: 'Wallet balance: \$${walletProvider.balance.toStringAsFixed(2)}. Tap to manage wallet',
          button: true,
          child: ScaleOnTap(
          onTap: () {
            Navigator.push(
              context,
              SlidePageRoute(page: const WalletScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: RivlColors.successGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: RivlColors.success.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Balance',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${walletProvider.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

class _DetailedStats extends StatelessWidget {
  final UserModel user;

  const _DetailedStats({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Performance'),
          const SizedBox(height: 16),
          _StatRow(
            icon: Icons.local_fire_department,
            label: 'Current Streak',
            value: '${user.currentStreak} days',
            color: RivlColors.warning,
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.directions_walk,
            label: 'Total Steps',
            value: _formatNumber(user.totalSteps),
            color: RivlColors.info,
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.attach_money,
            label: 'Total Earned',
            value: '\$${user.totalEarnings.toStringAsFixed(0)}',
            color: RivlColors.success,
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.emoji_events,
            label: 'Longest Streak',
            value: '${user.longestStreak} days',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: context.textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PersonalAttributes extends StatelessWidget {
  final UserModel user;

  const _PersonalAttributes({required this.user});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final runningWorkouts = health.recentWorkouts
        .where((w) => w.type.toUpperCase() == 'RUNNING' && w.distance > 0)
        .toList();

    // Average pace from running workouts (min per mile)
    double? avgPaceMinPerMile;
    if (runningWorkouts.isNotEmpty) {
      double totalPace = 0;
      for (final w in runningWorkouts) {
        totalPace += w.duration.inSeconds / 60 / w.distance;
      }
      avgPaceMinPerMile = totalPace / runningWorkouts.length;
    }

    // --- Compute 6 stats as user percentiles (1-99) ---
    // Uses population benchmarks to map raw values to percentile rank.

    final benchVal = (user.benchPressPR ?? 0).toDouble();
    final squatVal = (user.squatPR ?? 0).toDouble();

    // STR: bench + squat combined (population: mean ~350 lbs, sd ~120)
    final strength = _percentile(benchVal + squatVal, 350, 120);

    // SPD: mile pace — lower is better, so we invert
    // Population: mean ~9.5 min/mi, sd ~2.0 (lower = faster = higher percentile)
    final speed = avgPaceMinPerMile != null
        ? _percentile(19.0 - avgPaceMinPerMile, 9.5, 2.0)  // invert so faster = higher
        : 1.0;

    // END: VO2 Max (population: mean ~38, sd ~8)
    final endurance = _percentile(health.vo2Max, 38, 8);

    // PWR: pull-ups (population: mean ~8, sd ~5)
    final power = _percentile((user.pullUpsPR ?? 0).toDouble(), 8, 5);

    // VIT: recovery score (population: mean ~55, sd ~18)
    final vitality = _percentile(health.recoveryScore.toDouble(), 55, 18);

    // STA: daily steps (population: mean ~6000, sd ~3000)
    final stamina = _percentile(health.todaySteps.toDouble(), 6000, 3000);

    final stats = [
      _RadarStat('STR', strength, '${(benchVal + squatVal).toInt()} lbs'),
      _RadarStat('SPD', speed, avgPaceMinPerMile != null ? _formatPace(avgPaceMinPerMile) : '—'),
      _RadarStat('END', endurance, '${health.vo2Max.toStringAsFixed(1)} VO2'),
      _RadarStat('PWR', power, '${user.pullUpsPR ?? 0} reps'),
      _RadarStat('VIT', vitality, '${health.recoveryScore}%'),
      _RadarStat('STA', stamina, '${health.todaySteps} steps'),
    ];

    final overallRating = (stats.fold(0.0, (sum, s) => sum + s.value) / stats.length).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Attributes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: RivlColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$overallRating OVR',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'Edit personal attributes',
                button: true,
                child: GestureDetector(
                  onTap: () => _showEditSheet(context, user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: RivlColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RivlColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Radar chart
          SizedBox(
            height: 240,
            child: CustomPaint(
              size: const Size(240, 240),
              painter: _RadarChartPainter(
                stats: stats,
                primaryColor: RivlColors.primary,
                gridColor: context.surfaceVariant,
                textColor: context.textSecondary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Stat bars beneath the chart
          ...stats.map((s) => _StatBar(stat: s)),

          // Compact data row beneath
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _CompactStat(
                  label: 'Weight',
                  value: user.weightLbs != null ? '${user.weightLbs!.toStringAsFixed(0)}' : '—',
                  unit: 'lbs',
                ),
                _compactDivider(context),
                _CompactStat(
                  label: 'Height',
                  value: user.heightInches != null
                      ? '${(user.heightInches! ~/ 12)}\'${(user.heightInches! % 12).toStringAsFixed(0)}"'
                      : '—',
                  unit: '',
                ),
                _compactDivider(context),
                _CompactStat(
                  label: 'BMI',
                  value: user.bmi != null ? user.bmi!.toStringAsFixed(1) : '—',
                  unit: '',
                ),
                _compactDivider(context),
                _CompactStat(
                  label: '5K',
                  value: avgPaceMinPerMile != null ? _formatTime(avgPaceMinPerMile * 3.107) : '—',
                  unit: '',
                ),
                _compactDivider(context),
                _CompactStat(
                  label: '10K',
                  value: avgPaceMinPerMile != null ? _formatTime(avgPaceMinPerMile * 6.214) : '—',
                  unit: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactDivider(BuildContext context) {
    return Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 6), color: context.surfaceVariant);
  }

  /// Approximate percentile rank (1-99) using a normal CDF.
  /// Maps a raw [value] against a population with [mean] and [sd].
  static double _percentile(double value, double mean, double sd) {
    if (sd <= 0) return 50;
    // Approximate normal CDF using logistic sigmoid
    final z = (value - mean) / sd;
    final cdf = 1.0 / (1.0 + math.exp(-1.7 * z));
    return (cdf * 98 + 1).clamp(1.0, 99.0);
  }

  String _formatPace(double minPerMile) {
    final mins = minPerMile.floor();
    final secs = ((minPerMile - mins) * 60).round();
    return '${mins}:${secs.toString().padLeft(2, '0')}/mi';
  }

  String _formatTime(double totalMinutes) {
    final mins = totalMinutes.floor();
    final secs = ((totalMinutes - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditAttributesSheet(user: user),
    );
  }
}

class _RadarStat {
  final String label;
  final double value; // 0-99
  final String detail;

  const _RadarStat(this.label, this.value, this.detail);
}

class _RadarChartPainter extends CustomPainter {
  final List<_RadarStat> stats;
  final Color primaryColor;
  final Color gridColor;
  final Color textColor;
  final bool isDark;

  _RadarChartPainter({
    required this.stats,
    required this.primaryColor,
    required this.gridColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    final sides = stats.length;
    final angleStep = (2 * math.pi) / sides;
    // Rotate so first stat points up
    const startAngle = -math.pi / 2;

    // Grid rings
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = startAngle + angleStep * (i % sides);
        final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Spoke lines
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final outer = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(center, outer, gridPaint);
    }

    // Filled data polygon
    final dataPath = Path();
    final dataPoints = <Offset>[];
    for (int i = 0; i <= sides; i++) {
      final idx = i % sides;
      final fraction = (stats[idx].value / 99).clamp(0.05, 1.0);
      final r = radius * fraction;
      final angle = startAngle + angleStep * idx;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
      if (i < sides) dataPoints.add(point);
    }

    // Fill
    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, strokePaint);

    // Vertex dots
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    for (final point in dataPoints) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, Paint()..color = (isDark ? Colors.black : Colors.white)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // Labels + values at each vertex
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 22;
      final lx = center.dx + labelRadius * math.cos(angle);
      final ly = center.dy + labelRadius * math.sin(angle);

      // Stat number
      final valueSpan = TextSpan(
        text: stats[i].value.round().toString(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );
      final valuePainter = TextPainter(text: valueSpan, textDirection: TextDirection.ltr)..layout();

      // Label text
      final labelSpan = TextSpan(
        text: ' ${stats[i].label}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      );
      final labelPainter = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();

      final totalWidth = valuePainter.width + labelPainter.width;
      final xOffset = lx - totalWidth / 2;
      final yOffset = ly - valuePainter.height / 2;

      valuePainter.paint(canvas, Offset(xOffset, yOffset));
      labelPainter.paint(canvas, Offset(xOffset + valuePainter.width, yOffset + (valuePainter.height - labelPainter.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) =>
      old.stats != stats || old.primaryColor != primaryColor;
}

class _StatBar extends StatelessWidget {
  final _RadarStat stat;

  const _StatBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              stat.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textSecondary),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 26,
            child: Text(
              stat.value.round().toString(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: stat.value / 99,
                  backgroundColor: context.surfaceVariant.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _barColor(stat.value),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              stat.detail,
              style: TextStyle(fontSize: 10, color: context.textSecondary),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(double value) {
    if (value >= 80) return RivlColors.success;
    if (value >= 60) return RivlColors.primary;
    if (value >= 40) return RivlColors.warning;
    return RivlColors.error;
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _CompactStat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit.isNotEmpty ? '$label ($unit)' : label,
            style: TextStyle(fontSize: 9, color: context.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EditAttributesSheet extends StatefulWidget {
  final UserModel user;

  const _EditAttributesSheet({required this.user});

  @override
  State<_EditAttributesSheet> createState() => _EditAttributesSheetState();
}

class _EditAttributesSheetState extends State<_EditAttributesSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightFtCtrl;
  late final TextEditingController _heightInCtrl;
  late final TextEditingController _pullUpsCtrl;
  late final TextEditingController _benchCtrl;
  late final TextEditingController _squatCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.user.weightLbs?.toStringAsFixed(0) ?? '',
    );
    _heightFtCtrl = TextEditingController(
      text: widget.user.heightInches != null ? '${widget.user.heightInches! ~/ 12}' : '',
    );
    _heightInCtrl = TextEditingController(
      text: widget.user.heightInches != null ? '${(widget.user.heightInches! % 12).toStringAsFixed(0)}' : '',
    );
    _pullUpsCtrl = TextEditingController(
      text: widget.user.pullUpsPR?.toString() ?? '',
    );
    _benchCtrl = TextEditingController(
      text: widget.user.benchPressPR?.toString() ?? '',
    );
    _squatCtrl = TextEditingController(
      text: widget.user.squatPR?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();
    _pullUpsCtrl.dispose();
    _benchCtrl.dispose();
    _squatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final weight = double.tryParse(_weightCtrl.text);
    final heightFt = int.tryParse(_heightFtCtrl.text);
    final heightIn = int.tryParse(_heightInCtrl.text);
    final totalInches = (heightFt != null || heightIn != null)
        ? ((heightFt ?? 0) * 12 + (heightIn ?? 0)).toDouble()
        : null;
    final pullUps = int.tryParse(_pullUpsCtrl.text);
    final bench = int.tryParse(_benchCtrl.text);
    final squat = int.tryParse(_squatCtrl.text);

    final updates = <String, dynamic>{};
    if (weight != null) updates['weightLbs'] = weight;
    if (totalInches != null && totalInches > 0) updates['heightInches'] = totalInches;
    if (pullUps != null) updates['pullUpsPR'] = pullUps;
    if (bench != null) updates['benchPressPR'] = bench;
    if (squat != null) updates['squatPR'] = squat;

    if (updates.isNotEmpty) {
      try {
        await FirebaseService().updateUser(widget.user.id, updates);
        // Refresh user data
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Edit Attributes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Body
              Row(
                children: [
                  Expanded(
                    child: _FieldInput(
                      controller: _weightCtrl,
                      label: 'Weight (lbs)',
                      hint: '175',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: _FieldInput(
                      controller: _heightFtCtrl,
                      label: 'Feet',
                      hint: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: _FieldInput(
                      controller: _heightInCtrl,
                      label: 'Inches',
                      hint: '10',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PRs
              Row(
                children: [
                  Expanded(
                    child: _FieldInput(
                      controller: _pullUpsCtrl,
                      label: 'Pull-ups PR',
                      hint: '15',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldInput(
                      controller: _benchCtrl,
                      label: 'Bench PR (lbs)',
                      hint: '225',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldInput(
                      controller: _squatCtrl,
                      label: 'Squat PR (lbs)',
                      hint: '315',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RivlColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _FieldInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.4)),
            filled: true,
            fillColor: context.surfaceVariant.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final UserModel user;

  const _AchievementsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement(icon: Icons.emoji_events, title: 'First Win', unlocked: user.wins >= 1),
      _Achievement(icon: Icons.military_tech, title: '10 Wins', unlocked: user.wins >= 10),
      _Achievement(icon: Icons.local_fire_department, title: 'On Fire', unlocked: user.currentStreak >= 5),
      _Achievement(icon: Icons.directions_walk, title: '100K Steps', unlocked: user.totalSteps >= 100000),
      _Achievement(icon: Icons.star, title: 'Champion', unlocked: user.wins >= 50),
      _Achievement(icon: Icons.trending_up, title: '30 Day Streak', unlocked: user.longestStreak >= 30),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Achievements',
            trailing: Text(
              '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
              style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) => _AchievementBadge(achievement: a)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final IconData icon;
  final String title;
  final bool unlocked;

  const _Achievement({required this.icon, required this.title, required this.unlocked});
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber.withOpacity(0.1) : context.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: unlocked
                  ? Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Icon(
              achievement.icon,
              size: 28,
              color: unlocked ? Colors.amber[700] : context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? context.textPrimary : context.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReferralSection extends StatelessWidget {
  final UserModel user;

  const _ReferralSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RivlColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people, size: 18, color: RivlColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Refer Friends', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(
                      'Earn \$2 for each friend who joins!',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RivlColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user.referralCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: RivlColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy referral code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: user.referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  tooltip: 'Share referral code',
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Join me on RIVL and compete in fitness challenges! '
                            'Use my referral code ${user.referralCode} to sign up. '
                            'https://rivl.app/refer/${user.referralCode}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${user.referralCount} referrals', style: TextStyle(color: context.textSecondary, fontSize: 13)),
              Text(
                '+\$${user.referralEarnings.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: RivlColors.success, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Consumer<FriendProvider>(
            builder: (context, friendProvider, _) {
              final requestCount = friendProvider.pendingRequests.length;
              return _ActionTile(
                icon: Icons.people_outline,
                label: 'Friends',
                badge: requestCount > 0 ? '$requestCount' : null,
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(page: const FriendsScreen()),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 56, color: context.surfaceVariant),
          _ActionTile(
            icon: Icons.health_and_safety,
            label: 'Health App Connection',
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: const HealthConnectionScreen()),
            ),
          ),
          Divider(height: 1, indent: 56, color: context.surfaceVariant),
          _ActionTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: const NotificationsScreen()),
            ),
          ),
          Divider(height: 1, indent: 56, color: context.surfaceVariant),
          _ActionTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: const HelpSupportScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _ActionTile({required this.icon, required this.label, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: badge != null ? '$label, $badge new' : label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: context.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RivlColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder shown while profile stats are loading
class _ProfileStatsSkeleton extends StatelessWidget {
  const _ProfileStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        children: [
          // Quick stats row skeleton (Wins / Losses / Win Rate)
          Row(
            children: [
              Expanded(child: _statPlaceholder()),
              const SizedBox(width: 12),
              Expanded(child: _statPlaceholder()),
              const SizedBox(width: 12),
              Expanded(child: _statPlaceholder()),
            ],
          ),
          const SizedBox(height: 16),
          // Wallet card skeleton
          SkeletonBox(height: 90, width: double.infinity, borderRadius: 16),
          const SizedBox(height: 16),
          // Performance / Detailed stats skeleton
          SkeletonBox(height: 200, width: double.infinity, borderRadius: 16),
          const SizedBox(height: 16),
          // Attributes / radar chart skeleton
          SkeletonBox(height: 360, width: double.infinity, borderRadius: 16),
          const SizedBox(height: 16),
          // Achievements skeleton
          SkeletonBox(height: 160, width: double.infinity, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _statPlaceholder() {
    return Column(
      children: const [
        SkeletonBox(height: 28, width: 48, borderRadius: 6),
        SizedBox(height: 6),
        SkeletonBox(height: 12, width: 56, borderRadius: 4),
      ],
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: RivlColors.error),
            title: const Text('Sign Out', style: TextStyle(color: RivlColors.error)),
            onTap: () async {
              Navigator.pop(context); // close bottom sheet
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  FadePageRoute(page: const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
        ),
      ),
    );
  }
}
