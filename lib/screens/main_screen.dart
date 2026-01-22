// screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/health_provider.dart';
import 'home/home_screen.dart';
import 'challenges/challenges_screen.dart';
import 'create/create_challenge_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen.dart';

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
    LeaderboardScreen(),
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

    if (authProvider.user != null) {
      challengeProvider.startListening(authProvider.user!.id);
    }

    healthProvider.requestAuthorization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<ChallengeProvider>(
        builder: (context, challengeProvider, _) {
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
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: 'Leaderboard',
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
