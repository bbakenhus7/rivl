// main.dart
// RIVL - Flutter App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, kReleaseMode;
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'utils/error_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'config/env.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/health_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/battle_pass_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/activity_feed_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/connectivity_provider.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize global error handling & Crashlytics
  await ErrorHandler.initialize();

  // Replace red screen of death in release mode
  ErrorWidgetBuilder previousBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      return ErrorHandler.errorWidget(details);
    }
    return previousBuilder(details);
  };

  // Warn if Stripe key is missing in release mode
  if (kReleaseMode && Env.stripePublishableKey.isEmpty) {
    debugPrint(
      'WARNING: STRIPE_PUBLISHABLE_KEY is not set. '
      'Release builds should use: --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx',
    );
  }

  // Initialize Stripe (only for non-web platforms)
  if (!kIsWeb && Env.stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = Env.stripePublishableKey;
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

  /// Global navigator key -- still available for legacy dialog access
  /// (e.g. the WaitlistBanner). GoRouter manages its own navigator internally.
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const _RivlMaterialApp(),
    );
  }
}

/// Separate stateful widget that creates the [GoRouter] exactly once,
/// preventing navigation state resets when Provider values change and
/// trigger rebuilds upstream.
class _RivlMaterialApp extends StatefulWidget {
  const _RivlMaterialApp();

  @override
  State<_RivlMaterialApp> createState() => _RivlMaterialAppState();
}

class _RivlMaterialAppState extends State<_RivlMaterialApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the router once. GoRouter uses refreshListenable (AuthProvider)
    // internally to re-evaluate redirects when auth state changes, so we
    // do not need to recreate it on every build.
    final authProvider = context.read<AuthProvider>();
    _router = createRouter(authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'RIVL',
      debugShowCheckedModeBanner: false,
      theme: RivlTheme.lightTheme,
      darkTheme: RivlTheme.darkTheme,
      themeMode: themeProv.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return Column(
          children: [
            const WaitlistBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
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
        gradient: RivlColors.primaryGradient,
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
              showDialog(
                context: context,
                builder: (ctx) => const _WaitlistDialog(),
              );
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
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance.collection('waitlist').add({
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to join waitlist. Check your connection and try again.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
