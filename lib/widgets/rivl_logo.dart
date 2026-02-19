import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable RIVL logo widget.
///
/// Displays the app icon SVG: rounded purple gradient background,
/// white R lettermark, and green heartbeat ECG accent line.
///
/// Set [variant] to [RivlLogoVariant.white] for the white-only
/// version (no background) — ideal for placing on coloured surfaces.
enum RivlLogoVariant { full, white }

class RivlLogo extends StatelessWidget {
  final double size;
  final RivlLogoVariant variant;

  const RivlLogo({
    super.key,
    required this.size,
    this.variant = RivlLogoVariant.full,
    // Kept for backward compat — ignored now that we use SVG
    Color? color,
    BlendMode? colorBlendMode,
  });

  String get _asset => variant == RivlLogoVariant.white
      ? 'assets/images/rivl_logo_white.svg'
      : 'assets/images/rivl_logo.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.sports_score,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
