// config/router.dart
// GoRouter configuration for RIVL app
//
// This provides:
//   - Deep link support (e.g. /challenge/:id)
//   - Auth-aware redirects (unauthenticated users -> login)
//   - 404 error page
//   - Named route constants for gradual migration
//
// IMPORTANT: MainScreen keeps its own IndexedStack tab navigation.
// This router handles top-level screen routing only.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/main_screen.dart';
import '../screens/challenges/challenge_detail_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

/// Route path constants for the app.
///
/// Usage:
///   context.go(AppRoutes.home);
///   context.go(AppRoutes.challengeDetail('abc123'));
class AppRoutes {
  AppRoutes._(); // prevent instantiation

  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const challenges = '/challenges';
  static const create = '/create';
  static const feed = '/feed';
  static const profile = '/profile';
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const onboarding = '/onboarding';

  // Parameterized routes — use the helper methods below
  static const _challengeDetail = '/challenge/:id';

  /// Returns the path for a specific challenge detail screen.
  static String challengeDetail(String challengeId) => '/challenge/$challengeId';
}

/// Creates and returns the app's [GoRouter] instance.
///
/// [authProvider] is used for auth-aware redirects and as a
/// [refreshListenable] so the router re-evaluates redirects
/// whenever auth state changes.
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: authProvider,

    // ---------------------------------------------------------------
    // Global redirect: enforces auth gating on all routes
    // ---------------------------------------------------------------
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final location = state.matchedLocation;

      final isOnAuth = location == AppRoutes.login ||
          location == AppRoutes.signup;
      final isOnSplash = location == AppRoutes.splash;

      // Let the splash screen handle its own logic (animation + auth check)
      if (isOnSplash) return null;

      // Not authenticated and not already on an auth screen -> login
      if (!isAuthenticated && !isOnAuth) return AppRoutes.login;

      // Authenticated but still on an auth screen -> home
      if (isAuthenticated && isOnAuth) return AppRoutes.home;

      // No redirect needed
      return null;
    },

    // ---------------------------------------------------------------
    // Route definitions
    // ---------------------------------------------------------------
    routes: <RouteBase>[
      // Splash (entry point)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth screens — fade transitions for auth flow
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignUpScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      // Main app (tabs handled internally by MainScreen's IndexedStack)
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      // These routes also show MainScreen but pre-select a tab.
      // MainScreen.onTabSelected is a static callback that child
      // screens can use to switch tabs programmatically.
      // For now we route them all to MainScreen; tab pre-selection
      // can be wired up as a follow-up enhancement.
      GoRoute(
        path: AppRoutes.challenges,
        redirect: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MainScreen.onTabSelected?.call(1);
          });
          return AppRoutes.home;
        },
      ),
      GoRoute(
        path: AppRoutes.create,
        redirect: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MainScreen.onTabSelected?.call(2);
          });
          return AppRoutes.home;
        },
      ),
      GoRoute(
        path: AppRoutes.feed,
        redirect: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MainScreen.onTabSelected?.call(3);
          });
          return AppRoutes.home;
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        redirect: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MainScreen.onTabSelected?.call(4);
          });
          return AppRoutes.home;
        },
      ),

      // ---------------------------------------------------------------
      // Detail / push routes (deep-linkable)
      // ---------------------------------------------------------------
      GoRoute(
        path: AppRoutes._challengeDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ChallengeDetailScreen(challengeId: id),
            transitionsBuilder: _slideFromRight,
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WalletScreen(),
          transitionsBuilder: _slideFromRight,
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: _slideFromRight,
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
    ],

    // ---------------------------------------------------------------
    // 404 error page
    // ---------------------------------------------------------------
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Page not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error?.toString() ??
                      'The page you requested does not exist.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shared slide-from-right transition for detail screens.
Widget _slideFromRight(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: child,
  );
}
