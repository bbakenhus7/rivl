// screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/health_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/battle_pass_provider.dart';
import '../providers/activity_feed_provider.dart';
import '../widgets/streak_reward_popup.dart';
import 'home/home_screen.dart';
import 'challenges/challenges_screen.dart';
import 'create/create_challenge_screen.dart';
import 'feed/activity_feed_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

      // New features
      streakProvider.loadStreak(userId);
      notificationProvider.initialize(userId);
      battlePassProvider.loadProgress(userId);
      activityFeedProvider.startListening();

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

  void _checkDailyStreak(String userId) async {
    final streakProvider = context.read<StreakProvider>();

    // Wait for streak data to load
    await Future.delayed(const Duration(milliseconds: 500));

    if (streakProvider.canClaimToday && mounted) {
      await streakProvider.claimDailyReward(userId);

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
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
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
              const NavigationDestination(
                icon: Icon(Icons.add_circle_outline, size: 32),
                selectedIcon: Icon(Icons.add_circle, size: 32),
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
          );
        },
      ),
    );
  }
}
