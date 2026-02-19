/// Environment configuration loaded via --dart-define at build time.
///
/// Usage:
///   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
///   flutter build apk --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx
///
/// Defaults to empty string — release builds must supply a key via --dart-define.
class Env {
  Env._();

  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
}
