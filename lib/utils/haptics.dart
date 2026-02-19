// utils/haptics.dart
// Centralized haptic feedback for premium tactile feel

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Provides consistent haptic feedback across the app.
/// All methods are no-ops on web where haptics aren't supported.
class Haptics {
  Haptics._();

  /// Light tap — used for selection changes, toggles, tab switches
  static void light() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact();
  }

  /// Medium tap — used for button presses, card taps, navigation
  static void medium() {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy tap — used for important actions: accept challenge, send money
  static void heavy() {
    if (kIsWeb) return;
    HapticFeedback.heavyImpact();
  }

  /// Selection tick — used for picker changes, scroll snap points
  static void selection() {
    if (kIsWeb) return;
    HapticFeedback.selectionClick();
  }

  /// Success pattern — double tap for confirmations (challenge accepted, etc.)
  static void success() {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Error/warning vibration
  static void error() {
    if (kIsWeb) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.heavyImpact();
    });
  }
}
