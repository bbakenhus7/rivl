/// Environment configuration loaded via --dart-define at build time.
///
/// Usage:
///   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
///   flutter build apk --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx
///
/// Falls back to the test key when no value is provided (development only).
class Env {
  Env._();

  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51SvOs4FJPVRByrQYaB8DqcSSobK4zBBV3rFO3YpCoTBk0s08yo9Aec1s95uxXnpOesn4Y6QnQItBKX4KnWvzSRwN007RkMUOCl',
  );
}
