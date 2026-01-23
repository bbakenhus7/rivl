// main.dart
// RIVL - Flutter App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/health_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/create/create_challenge_screen.dart';
import 'screens/challenges/challenge_detail_screen.dart';
import 'screens/stats/stats_dashboard_screen.dart';
import 'screens/history/challenge_history_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/discovery/challenge_discovery_screen.dart';
import 'services/firebase_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Stripe (only for non-web platforms)
  // Use a Stripe test publishable key placeholder for local development.
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = 'pk_test_FAKE_PUBLISHABLE_KEY_FOR_LOCAL';
      await Stripe.instance.applySettings();
    } catch (e) {
      // If Stripe fails to initialize, continue without blocking app startup.
      // Web and some desktop targets may not support the platform API used by the package.
      debugPrint('Stripe init skipped: $e');
    }
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const RivlApp());
}

class RivlApp extends StatelessWidget {
  const RivlApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => WalletProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider(firebaseService)),
      ],
      child: MaterialApp(
        title: 'RIVL',
        debugShowCheckedModeBanner: false,
        theme: RivlTheme.lightTheme,
        darkTheme: RivlTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/create-challenge': (context) => const CreateChallengeScreen(),
          '/stats': (context) => const StatsDashboardScreen(),
          '/challenge-history': (context) => const ChallengeHistoryScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/discovery': (context) => const ChallengeDiscoveryScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/challenge-detail') {
            final challengeId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challengeId: challengeId),
            );
          }
          return null;
        },
      ),
    );
  }
}
