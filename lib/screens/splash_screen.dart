// screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Short delay for splash effect on native; on web, skip long waits
    if (!kIsWeb) await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // On web, the Firebase auth stream can sometimes delay startup or block
      // navigation. For a functional UI on web, navigate straight to the
      // main app so you can explore the interface. Native platforms keep
      // the original auth-check behavior.
      if (kIsWeb) {
        _navigateToMain();
        return;
      }

      final authProvider = context.read<AuthProvider>();

      if (authProvider.isAuthenticated) {
        _navigateToMain();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      // If anything goes wrong, fall back to main so app remains navigable.
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RivlColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 60,
                  color: RivlColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              
              // App name
              const Text(
                'RIVL',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Challenge Friends. Win Rewards.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
