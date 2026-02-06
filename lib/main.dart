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
      ),
    );
  }
}
