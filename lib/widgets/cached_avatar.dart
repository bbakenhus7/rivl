import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';

/// Cached avatar widget with fallback to initials
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final bgColor = backgroundColor ?? RivlColors.primary.withOpacity(0.12);
    final fgColor = textColor ?? RivlColors.primary;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: fgColor,
              fontSize: radius * 0.7,
            ),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: fgColor,
              fontSize: radius * 0.7,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: fgColor,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
