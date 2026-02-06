// main.dart
// RIVL - Flutter App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        navigatorKey: navigatorKey,
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
              final navContext = RivlApp.navigatorKey.currentContext;
              if (navContext != null) {
                showDialog(
                  context: navContext,
                  builder: (ctx) => const _WaitlistDialog(),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RivlColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Join Waitlist',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitlistDialog extends StatefulWidget {
  const _WaitlistDialog();

  @override
  State<_WaitlistDialog> createState() => _WaitlistDialogState();
}

class _WaitlistDialogState extends State<_WaitlistDialog> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance.collection('waitlist').add({
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // If Firestore is unavailable, still show success for demo
    }

    if (mounted) {
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: RivlColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: RivlColors.success, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          "You're on the list!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll notify you as soon as RIVL launches.",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: RivlColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join the Waitlist',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to compete when RIVL launches.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Your full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your name';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _contactController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email or Phone',
              hintText: 'email@example.com or (555) 123-4567',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter email or phone';
              final v = val.trim();
              final hasAt = v.contains('@');
              final hasDigits = RegExp(r'\d{7,}').hasMatch(v.replaceAll(RegExp(r'[\s\-\(\)\+]'), ''));
              if (!hasAt && !hasDigits) return 'Enter a valid email or phone number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign Up'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}
