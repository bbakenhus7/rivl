// screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/router.dart';
import '../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../widgets/rivl_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );

    _animController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Short delay for splash effect on native; on web, skip long waits
    if (!kIsWeb) await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();

      // On web, skip login and go straight to home with a demo athlete profile.
      if (kIsWeb && !authProvider.isAuthenticated) {
        authProvider.enableDemoMode();
        _navigateTo(AppRoutes.home);
        return;
      }

      if (authProvider.isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        if (!hasSeenOnboarding) {
          _navigateTo(AppRoutes.onboarding);
        } else {
          _navigateTo(AppRoutes.home);
        }
      } else {
        _navigateTo(AppRoutes.login);
      }
    } catch (e) {
      // If anything goes wrong, fall back to home so app remains navigable.
      _navigateTo(AppRoutes.home);
    }
  }

  void _navigateTo(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RivlColors.primaryDeepGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: child,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo — white R + heartbeat on the gradient background
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const RivlLogo(
                    size: 68,
                    variant: RivlLogoVariant.white,
                  ),
                ),
                const SizedBox(height: 32),

                // App name
                const Text(
                  'RIVL',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'AI-Powered Fitness Competition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading
                const _PulsingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = ((_controller.value + index * 0.2) % 1.0);
        final double scale;
        if (t < 0.3) {
          scale = 0.3 + (t / 0.3) * 0.7;
        } else if (t < 0.6) {
          scale = 1.0 - ((t - 0.3) / 0.3) * 0.7;
        } else {
          scale = 0.3;
        }
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3 + scale * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_dot(0), _dot(1), _dot(2)],
      ),
    );
  }
}
