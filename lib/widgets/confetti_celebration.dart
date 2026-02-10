// widgets/confetti_celebration.dart

import 'dart:math';
import 'package:flutter/material.dart';

/// Confetti overlay animation for celebrations (wins, milestones, etc.)
/// Inspired by Robinhood's trade confirmation and Duolingo's streak celebrations.
class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final bool celebrate;
  final Duration duration;
  final int particleCount;

  const ConfettiCelebration({
    super.key,
    required this.child,
    this.celebrate = false,
    this.duration = const Duration(milliseconds: 2500),
    this.particleCount = 40,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _particles = _generateParticles();

    if (widget.celebrate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && !oldWidget.celebrate) {
      _particles = _generateParticles();
      _controller.forward(from: 0);
    }
  }

  List<_ConfettiParticle> _generateParticles() {
    const colors = [
      Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
      Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFFFFEB3B),
      Color(0xFF00BCD4), Color(0xFFFF5722),
    ];

    return List.generate(widget.particleCount, (_) {
      return _ConfettiParticle(
        x: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        wobble: _random.nextDouble() * 2 * pi,
        wobbleSpeed: 1 + _random.nextDouble() * 3,
        size: 4 + _random.nextDouble() * 6,
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        isCircle: _random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.celebrate)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double speed;
  final double wobble;
  final double wobbleSpeed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.wobble,
    required this.wobbleSpeed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final x = p.x * size.width + sin(p.wobble + progress * p.wobbleSpeed * pi * 2) * 20;
      final y = -20 + progress * size.height * (0.8 + p.speed * 0.6);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.rotationSpeed);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animated number counter that counts up from 0 to target value.
/// Like Robinhood's portfolio value animation.
class AnimatedValue extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  const AnimatedValue({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          '$prefix${val.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}

/// Shimmer glow effect for premium/winning elements
class ShimmerGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool enabled;

  const ShimmerGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFFD700),
    this.enabled = true,
  });

  @override
  State<ShimmerGlow> createState() => _ShimmerGlowState();
}

class _ShimmerGlowState extends State<ShimmerGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.15 + _controller.value * 0.15),
                blurRadius: 12 + _controller.value * 8,
                spreadRadius: _controller.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Empty state widget with illustration-style icons (like Duolingo/Strava)
class IllustratedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final Widget? action;

  const IllustratedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered icon illustration
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
                // Inner circle
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                ),
                // Icon
                Icon(icon, size: 44, color: color.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
