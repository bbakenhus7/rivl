// screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../config/router.dart';
import '../../utils/theme.dart';
import '../../utils/haptics.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static final _pages = [
    _OnboardingPageData(
      icon: Icons.favorite,
      title: 'Connect Your Health',
      subtitle:
          'Link Apple Health or Google Fit to track steps, sleep, heart rate, and more.',
      gradient: [RivlColors.primary, RivlColors.primaryDark],
    ),
    _OnboardingPageData(
      icon: Icons.local_fire_department,
      title: 'Challenge Friends',
      subtitle:
          'Create head-to-head fitness challenges with real-money stakes.',
      gradient: [RivlColors.secondary, const Color(0xFFFF6B00)],
    ),
    _OnboardingPageData(
      icon: Icons.emoji_events,
      title: 'Win Real Money',
      subtitle:
          'Beat your rivals and earn cash rewards. No fees on friend challenges!',
      gradient: [RivlColors.success, const Color(0xFF00A86B)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    Haptics.success();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _OnboardingPage(
                icon: page.icon,
                title: page.title,
                subtitle: page.subtitle,
                gradient: page.gradient,
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: RivlColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Skip button (hidden on last page)
                    if (_currentPage < _pages.length - 1) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 48),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
