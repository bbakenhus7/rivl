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
import 'providers/wallet_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/battle_pass_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/activity_feed_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Stripe (only for non-web platforms)
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = 'pk_test_51SvOs4FJPVRByrQYaB8DqcSSobK4zBBV3rFO3YpCoTBk0s08yo9Aec1s95uxXnpOesn4Y6QnQItBKX4KnWvzSRwN007RkMUOCl';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BattlePassProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ActivityFeedProvider()),
      ],
      child: MaterialApp(
        title: 'RIVL',
        debugShowCheckedModeBanner: false,
        theme: RivlTheme.lightTheme,
        darkTheme: RivlTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        builder: (context, child) {
          return Column(
            children: [
              const WaitlistBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}

class WaitlistBanner extends StatelessWidget {
  const WaitlistBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 6,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3399FF), Color(0xFF1A6FD4)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'RIVL is launching soon! Be the first to compete.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Link to waitlist signup
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RivlColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Join Waitlist',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
