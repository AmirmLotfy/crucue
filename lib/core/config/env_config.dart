import 'package:flutter/foundation.dart';

/// Environment configuration for Crucue.
///
/// Differentiates between dev, staging, and production environments.
/// Configure via `--dart-define` at build time:
///
/// ```bash
/// # Development
/// flutter run --dart-define=ENV=dev
///
/// # Staging
/// flutter build apk --dart-define=ENV=staging
///
/// # Production (default)
/// flutter build apk --release
/// ```
class EnvConfig {
  EnvConfig._();

  static const _env = String.fromEnvironment('ENV', defaultValue: 'prod');

  static bool get isDev => _env == 'dev';
  static bool get isStaging => _env == 'staging';
  static bool get isProd => _env == 'prod';

  /// App name displayed to users (same for all envs in Crucue).
  static const appName = 'Crucue';

  /// Support email for in-app links.
  static const supportEmail = 'support@crucue.com';

  /// Privacy policy URL.
  static const privacyPolicyUrl = 'https://www.crucue.com/privacy';

  /// Terms of service URL.
  static const termsUrl = 'https://www.crucue.com/terms';

  /// App version — read from pubspec at build time in production.
  static const appVersion = '1.0.0';

  /// Build info for debug overlay.
  static String get buildInfo =>
      '${appVersion}_${_env}_${kDebugMode ? 'debug' : 'release'}';
}
