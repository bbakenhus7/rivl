import 'package:flutter/material.dart';

/// Reusable RIVL logo widget with the signature bottom-right fade effect.
///
/// The R's bottom-right leg fades into the background using a diagonal
/// gradient shader mask.
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
    Widget image = Image.asset(
      'assets/images/rivl_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: colorBlendMode,
    );

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,
            Color(0x4DFFFFFF), // ~30% opacity
            Colors.transparent,
          ],
          stops: [0.0, 0.55, 0.85, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: image,
    );
  }
}
