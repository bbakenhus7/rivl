// screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/health_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/battle_pass_provider.dart';
import '../providers/activity_feed_provider.dart';
import '../providers/friend_provider.dart';
import '../models/activity_feed_model.dart';
import '../models/battle_pass_model.dart';
import '../widgets/streak_reward_popup.dart';
import 'home/home_screen.dart';
import 'challenges/challenges_screen.dart';
import 'create/create_challenge_screen.dart';
import 'feed/activity_feed_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  /// Static callback to switch tabs from child screens (e.g. HomeScreen "See All").
  static void Function(int)? onTabSelected;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChallengesScreen(),
    CreateChallengeScreen(),
    ActivityFeedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainScreen.onTabSelected = (index) {
      if (mounted) setState(() => _currentIndex = index);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final authProvider = context.read<AuthProvider>();
    final challengeProvider = context.read<ChallengeProvider>();
    final healthProvider = context.read<HealthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final streakProvider = context.read<StreakProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final battlePassProvider = context.read<BattlePassProvider>();
    final activityFeedProvider = context.read<ActivityFeedProvider>();

    if (authProvider.user != null) {
      final userId = authProvider.user!.id;

      // Core
      challengeProvider.startListening(userId);
      healthProvider.requestAuthorization();
      walletProvider.initialize(userId);

      // Wire XP awards into battle pass from all providers
      challengeProvider.onXPEarned = (xp, source) {
        battlePassProvider.addXP(userId, xp, source);
      };
      healthProvider.onXPEarned = (xp, source) {
        battlePassProvider.addXP(userId, xp, source);
      };

      // Wire activity feed posting from challenge events
      challengeProvider.onActivityFeedPost = (type, message, data) {
        final user = authProvider.user;
        if (user != null) {
          activityFeedProvider.postActivity(
            userId: user.id,
            username: user.username,
            displayName: user.displayName,
            type: ActivityType.challengeWon,
            message: message,
            data: data,
          );
        }
      };

      // Wire streak milestone posting
      streakProvider.onStreakMilestone = (streakDays) {
        final user = authProvider.user;
        if (user != null) {
          activityFeedProvider.postStreakMilestone(
            userId: user.id,
            username: user.username,
            displayName: user.displayName,
            streakDays: streakDays,
          );
        }
      };

      // New features
      streakProvider.loadStreak(userId);
      notificationProvider.initialize(userId);
      battlePassProvider.loadProgress(userId);
      activityFeedProvider.startListening();
      context.read<FriendProvider>().startListening(userId);

      // Start periodic health data refresh
      healthProvider.startAutoRefresh();

      // Auto-claim daily streak reward
      _checkDailyStreak(userId);
    } else {
      // Load demo data for unauthenticated users so UI isn't empty
      challengeProvider.loadDemoChallenges();
      challengeProvider.loadDemoOpponents();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final healthProvider = context.read<HealthProvider>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Pause health refresh to save battery
        healthProvider.stopAutoRefresh();
        break;
      case AppLifecycleState.resumed:
        // Resume refresh and do an immediate data pull
        healthProvider.startAutoRefresh();
        healthProvider.refreshData();
        break;
    }
  }

  void _checkDailyStreak(String userId) async {
    final streakProvider = context.read<StreakProvider>();
    final battlePassProvider = context.read<BattlePassProvider>();

    // Wait for streak and battle pass data to load
    await Future.delayed(const Duration(milliseconds: 500));

    if (streakProvider.canClaimToday && mounted) {
      await streakProvider.claimDailyReward(userId);

      // Award daily login XP
      await battlePassProvider.addXP(
        userId,
        XPSource.DAILY_LOGIN,
        'daily_login',
      );

      // Award streak bonus XP (scales with streak, capped at 7 days)
      final streakDays = streakProvider.currentStreak.clamp(1, 7);
      if (streakDays > 1) {
        await battlePassProvider.addXP(
          userId,
          XPSource.STREAK_BONUS * (streakDays - 1),
          'streak_bonus',
        );
      }

      // Show reward popup
      if (streakProvider.showRewardPopup && streakProvider.lastReward != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => StreakRewardPopup(
            reward: streakProvider.lastReward!,
            currentStreak: streakProvider.currentStreak,
            onDismiss: () {
              streakProvider.dismissRewardPopup();
              Navigator.pop(context);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer2<ChallengeProvider, NotificationProvider>(
        builder: (context, challengeProvider, notificationProvider, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.light
                  ? const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFAF9FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF1E1E2E), Color(0xFF1A1528)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              boxShadow: [
                BoxShadow(
                  color: RivlColors.primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: challengeProvider.pendingCount > 0,
                  label: Text('${challengeProvider.pendingCount}'),
                  child: const Icon(Icons.local_fire_department_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: challengeProvider.pendingCount > 0,
                  label: Text('${challengeProvider.pendingCount}'),
                  child: const Icon(Icons.local_fire_department),
                ),
                label: 'Challenges',
              ),
              NavigationDestination(
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: RivlColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: RivlColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
                selectedIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: RivlColors.primaryDeepGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: RivlColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
                label: 'Create',
              ),
              const NavigationDestination(
                icon: Icon(Icons.dynamic_feed_outlined),
                selectedIcon: Icon(Icons.dynamic_feed),
                label: 'Hub',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}
