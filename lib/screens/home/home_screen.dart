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
import '../../widgets/add_funds_sheet.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';

import '../../models/health_category.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/rivl_logo.dart';
import '../challenges/challenge_detail_screen.dart';
import '../main_screen.dart';
import '../notifications/notifications_screen.dart';
import 'health_category_detail_screen.dart';
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

  PopupMenuEntry<ThemeMode> _themeMenuItem(
    ThemeMode value,
    IconData icon,
    String label,
    ThemeMode current,
  ) {
    final selected = value == current;
    return PopupMenuItem<ThemeMode>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? RivlColors.primary : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? RivlColors.primary : null,
            ),
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check, size: 18, color: RivlColors.primary),
        ],
      ),
    );
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
              _InfoBullet(text: 'Compete on steps, distance, sleep, Zone 2 cardio, and more'),
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
            // App Bar with RIVL Logo — condenses on scroll
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: RivlColors.primaryDark,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  final statusBarHeight = MediaQuery.of(context).padding.top;
                  final collapsedHeight = kToolbarHeight + statusBarHeight;
                  final expandedHeight = 180 + statusBarHeight;
                  // 0.0 = fully collapsed, 1.0 = fully expanded
                  final t = ((top - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

                  // Interpolated sizes
                  final logoSize = 28.0 + (36.0 * t);       // 28 → 64
                  final titleFontSize = 18.0 + (10.0 * t);  // 18 → 28
                  final letterSpacing = 2.0 + (4.0 * t);    // 2 → 6

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
                                SizedBox(height: 8 * t),
                                Semantics(
                                  label: 'RIVL logo',
                                  excludeSemantics: true,
                                  child: RivlLogo(size: logoSize),
                                ),
                                SizedBox(height: 8 * t + 4),
                                Text(
                                  'RIVL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: letterSpacing,
                                  ),
                                ),
                                if (t > 0.6) ...[
                                  SizedBox(height: 4 * t),
                                  Opacity(
                                    opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                                    child: Text(
                                      'Compete. Win. Earn.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.5,
                                      ),
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
                                    Semantics(
                                      label: 'RIVL logo',
                                      excludeSemantics: true,
                                      child: const RivlLogo(size: 28),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'RIVL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
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
              actions: [
                // Streak badge
                Consumer<StreakProvider>(
                  builder: (context, streak, _) {
                    if (streak.currentStreak <= 0) return const SizedBox.shrink();
                    return Semantics(
                      label: '${streak.currentStreak} day streak',
                      excludeSemantics: true,
                      child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Chip(
                        avatar: const Icon(Icons.whatshot, color: RivlColors.streak, size: 18),
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
                      tooltip: notif.hasUnread
                          ? '${notif.unreadCount} unread notifications'
                          : 'Notifications',
                      onPressed: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: const NotificationsScreen()),
                        );
                      },
                    );
                  },
                ),
                // Theme toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProv, _) {
                    return PopupMenuButton<ThemeMode>(
                      tooltip: 'Change theme',
                      icon: Icon(
                        themeProv.themeMode == ThemeMode.light
                            ? Icons.light_mode
                            : themeProv.themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.brightness_auto,
                        color: Colors.white,
                      ),
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (mode) => themeProv.setThemeMode(mode),
                      itemBuilder: (_) => [
                        _themeMenuItem(
                          ThemeMode.light,
                          Icons.light_mode_outlined,
                          'Light',
                          themeProv.themeMode,
                        ),
                        _themeMenuItem(
                          ThemeMode.dark,
                          Icons.dark_mode_outlined,
                          'Dark',
                          themeProv.themeMode,
                        ),
                        _themeMenuItem(
                          ThemeMode.system,
                          Icons.brightness_auto_outlined,
                          'Device',
                          themeProv.themeMode,
                        ),
                      ],
                    );
                  },
                ),
                // Info button
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'About RIVL',
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

                  // Demo data banner (when health data is sample/fake)
                  Consumer<HealthProvider>(
                    builder: (context, health, _) {
                      if (!health.isUsingDemoData) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FadeIn(
                          child: Semantics(
                            label: 'Showing sample health data. Tap Connect to link Apple Health or Google Fit.',
                            button: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: RivlColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: RivlColors.warning.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: RivlColors.warning),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Showing sample data. Connect Apple Health or Google Fit for real metrics.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: RivlColors.warning,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => health.requestAuthorization(),
                                    child: Text(
                                      'Connect',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: RivlColors.primary,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
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
                                Icon(Icons.notifications_active, size: 18, color: RivlColors.warning),
                                const SizedBox(width: 8),
                                Text(
                                  'Action Required',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: RivlColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: RivlColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pending.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: RivlColors.warning,
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
                                  currentUserId: context.read<AuthProvider>().user?.id ?? 'demo-user',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      SlidePageRoute(
                                        page: ChallengeDetailScreen(challengeId: challenge.id),
                                      ),
                                    );
                                  },
                                  onAccept: () async {
                                    var walletBalance = context.read<WalletProvider>().balance;
                                    if (challenge.stakeAmount > 0 && walletBalance < challenge.stakeAmount) {
                                      final funded = await showAddFundsSheet(
                                        context,
                                        stakeAmount: challenge.stakeAmount,
                                        currentBalance: walletBalance,
                                      );
                                      if (!funded || !context.mounted) return;
                                      walletBalance = context.read<WalletProvider>().balance;
                                    }
                                    final success = await provider.acceptChallenge(
                                      challenge.id,
                                      walletBalance: walletBalance,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Challenge accepted! Good luck!'
                                            : provider.errorMessage ?? 'Failed to accept challenge'),
                                        backgroundColor: success ? RivlColors.success : RivlColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    provider.clearMessages();
                                  },
                                  onDecline: () async {
                                    final success = await provider.declineChallenge(challenge.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Challenge declined'
                                            : provider.errorMessage ?? 'Failed to decline challenge'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    provider.clearMessages();
                                  },
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),

                  // RIVL Health Score Card, Activity Rings, Health Categories
                  // Show skeleton placeholders while health data is loading
                  Consumer<HealthProvider>(
                    builder: (context, health, _) {
                      if (health.isLoading) {
                        return const _HomeScreenSkeleton();
                      }
                      return Column(
                        children: [
                          // RIVL Health Score Card
                          StaggeredListAnimation(
                            index: 1,
                            child: const _RivlHealthScoreCard(),
                          ),
                          const SizedBox(height: 16),

                          // Activity Rings (standalone)
                          StaggeredListAnimation(
                            index: 2,
                            child: const _ActivityBarsCard(),
                          ),
                          const SizedBox(height: 16),

                          // Health Category Tiles (2x2 grid)
                          StaggeredListAnimation(
                            index: 3,
                            child: const _HealthCategoryGrid(),
                          ),
                        ],
                      );
                    },
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
                            SectionHeader(
                              title: 'Active Challenges',
                              actionLabel: 'See All',
                              onAction: () => MainScreen.onTabSelected?.call(1),
                            ),
                            const SizedBox(height: 12),
                            ...provider.activeChallenges.take(2).map((challenge) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ChallengeCard(
                                  challenge: challenge,
                                  currentUserId: context.read<AuthProvider>().user?.id ?? 'demo-user',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      SlidePageRoute(
                                        page: ChallengeDetailScreen(challengeId: challenge.id),
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

// RIVL Health Score Card
class _RivlHealthScoreCard extends StatelessWidget {
  const _RivlHealthScoreCard();

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return RivlColors.success;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return RivlColors.warning;
      default:
        return RivlColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final score = health.rivlHealthScore;
        final grade = health.rivlHealthGrade;
        final color = _getGradeColor(grade);

        return Semantics(
          label: 'RIVL Health Score: $score out of 100, grade $grade. Tap for details',
          button: true,
          child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              SlidePageRoute(
                page: HealthMetricDetailScreen(
                  metricType: HealthMetricType.healthScore,
                  icon: Icons.favorite_rounded,
                  label: 'RIVL Health Score',
                  currentValue: '$score',
                  unit: '/100',
                  color: color,
                  description:
                      'Your RIVL Health Score is a single number that captures your '
                      'overall fitness across six key dimensions: Steps (25%), '
                      'Distance (20%), Sleep (15%), Resting Heart Rate (15%), '
                      'VO2 Max (15%), and HRV (10%).\n\n'
                      'Why it matters: Instead of checking six different metrics, '
                      'this score tells you at a glance whether your health is '
                      'trending in the right direction. Research shows that people '
                      'who track a single composite health metric are more likely '
                      'to stay consistent with their fitness routines. Use it to '
                      'spot patterns -- a dipping score often means sleep or '
                      'recovery needs attention before you feel it.',
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [context.surface, color.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
            child: Row(
              children: [
                // Score and grade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.18),
                                  color.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.favorite_rounded, color: color, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RIVL Health Score',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: context.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: context.textSecondary, size: 22),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                grade,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your overall fitness across steps, sleep, heart health, and cardio capacity. Tap to see your 30-day trend.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
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
    if (stepsProgress >= 0.75) return RivlColors.warning;
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
              SectionHeader(
                title: "Today's Activity",
                trailing: FadeIn(
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



// Health Category Grid (2x2 tiles)
class _HealthCategoryGrid extends StatelessWidget {
  const _HealthCategoryGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Health Categories'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: [
            FadeIn(
              delay: const Duration(milliseconds: 100),
              child: _CategoryTile(category: HealthCategory.heartHealth),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 150),
              child: _CategoryTile(category: HealthCategory.activityPerformance),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: _CategoryTile(category: HealthCategory.sleepRecovery),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 250),
              child: _CategoryTile(category: HealthCategory.overall),
            ),
          ],
        ),
      ],
    );
  }
}

// Individual category tile with preview values
class _CategoryTile extends StatelessWidget {
  final HealthCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final config = HealthCategoryConfig.of(category);

    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final preview = _getPreview(health);

        return Semantics(
          label: '${config.name}: ${preview.heroValue} ${preview.heroLabel}. Tap for details',
          button: true,
          child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              SlidePageRoute(
                page: HealthCategoryDetailScreen(category: category),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.surface, config.accentColor.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: config.accentColor.withOpacity(0.08),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + category name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            config.accentColor.withOpacity(0.18),
                            config.accentColor.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(config.icon, color: config.accentColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        config.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Hero value
                Text(
                  preview.heroValue,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: config.accentColor,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview.heroLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle metrics
                Text(
                  preview.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Tap hint
                Row(
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: config.accentColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  _CategoryPreview _getPreview(HealthProvider health) {
    switch (category) {
      case HealthCategory.heartHealth:
        final hr = health.heartRate > 0 ? '${health.heartRate}' : '--';
        final hrv = health.hrv > 0 ? 'HRV ${health.hrv.round()}ms' : 'HRV --';
        final rhr = health.restingHeartRate > 0 ? 'RHR ${health.restingHeartRate}' : 'RHR --';
        return _CategoryPreview(
          heroValue: '$hr bpm',
          heroLabel: 'Heart Rate',
          subtitle: '$hrv  •  $rhr',
        );
      case HealthCategory.activityPerformance:
        final steps = health.formatSteps(health.todaySteps);
        final vo2 = health.vo2Max > 0 ? 'VO2 ${health.vo2Max.toStringAsFixed(1)}' : 'VO2 --';
        final exertion = 'Exertion ${health.strainScore}';
        return _CategoryPreview(
          heroValue: '$steps',
          heroLabel: 'Steps Today',
          subtitle: '$vo2  •  $exertion',
        );
      case HealthCategory.sleepRecovery:
        final sleep = health.sleepHours > 0 ? health.formatSleep(health.sleepHours) : '--';
        final recovery = 'Recovery ${health.recoveryScore}';
        final spo2 = health.bloodOxygen > 0 ? 'SpO2 ${health.bloodOxygen.round()}%' : 'SpO2 --';
        return _CategoryPreview(
          heroValue: sleep,
          heroLabel: 'Sleep',
          subtitle: '$recovery  •  $spo2',
        );
      case HealthCategory.overall:
        final score = health.rivlHealthScore;
        final grade = health.rivlHealthGrade;
        return _CategoryPreview(
          heroValue: '$score',
          heroLabel: 'Health Score',
          subtitle: 'Grade $grade  •  AI Insights',
        );
    }
  }
}

class _CategoryPreview {
  final String heroValue;
  final String heroLabel;
  final String subtitle;

  const _CategoryPreview({
    required this.heroValue,
    required this.heroLabel,
    required this.subtitle,
  });
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
                color: RivlColors.streak,
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

/// Skeleton placeholder shown while health data is loading
class _HomeScreenSkeleton extends StatelessWidget {
  const _HomeScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Column(
          children: [
            // Health score card skeleton
            SkeletonBox(height: 200, width: double.infinity, borderRadius: 16),
            const SizedBox(height: 16),
            // Activity rings card skeleton
            SkeletonBox(height: 280, width: double.infinity, borderRadius: 24),
            const SizedBox(height: 16),
            // Health Categories header skeleton
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(height: 18, width: 140, borderRadius: 6),
            ),
            const SizedBox(height: 12),
            // Category grid skeleton (2x2)
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 160, borderRadius: 20)),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 160, borderRadius: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 160, borderRadius: 20)),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 160, borderRadius: 20)),
              ],
            ),
          ],
        ),
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
