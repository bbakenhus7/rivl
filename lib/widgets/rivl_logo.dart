import 'package:flutter/material.dart';

/// Reusable RIVL logo widget.
///
/// Displays the app icon: purple split background, white R lettermark,
/// and green heartbeat ECG line.
class RivlLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final BlendMode? colorBlendMode;

  const RivlLogo({
    super.key,
    required this.size,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/rivl_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (_, __, ___) => Icon(
        Icons.sports_score,
        size: size,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
