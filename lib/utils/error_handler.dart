import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Global error handler utilities for RIVL
class ErrorHandler {
  /// Initialize error handling — call from main() after Firebase.initializeApp
  static Future<void> initialize() async {
    if (kIsWeb) return;

    // Pass all uncaught Flutter framework errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Log a non-fatal error
  static void logError(dynamic error, {StackTrace? stackTrace, String? reason}) {
    if (kIsWeb) {
      debugPrint('Error: $error');
      return;
    }
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: reason ?? 'non-fatal',
    );
  }

  /// Log a message to Crashlytics
  static void log(String message) {
    if (kIsWeb) {
      debugPrint(message);
      return;
    }
    FirebaseCrashlytics.instance.log(message);
  }

  /// Set user identifier for crash reports
  static void setUserId(String userId) {
    if (kIsWeb) return;
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Custom error widget for production (replaces red screen of death)
  static Widget errorWidget(FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please restart the app and try again.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
