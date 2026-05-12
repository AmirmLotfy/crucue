class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Crucue';
  static const String appTagline = 'Care, guided by insight.';
  static const String supportEmail = 'support@crucue.app';
  static const String privacyPolicyUrl = 'https://crucue.app/privacy';
  static const String termsUrl = 'https://crucue.app/terms';

  // Safety
  static const String safetyDisclaimer =
      'Crucue provides supportive guidance, not medical or psychological advice. '
      'If you or someone you care for is in crisis, please contact emergency services.';

  static const String crisisLineUS = '988';
  static const String crisisLineText = 'Text HOME to 741741';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String profilesCollection = 'profiles';
  static const String incidentsCollection = 'incidents';
  static const String plansCollection = 'plans';
  static const String routinesCollection = 'routines';
  static const String checkinsCollection = 'checkins';
  static const String insightsCollection = 'insights';
  static const String chatThreadsCollection = 'chatThreads';
  static const String historyCollection = 'history';

  // SharedPreferences keys
  static const String keyFirstName = 'firstName';
  static const String keyLastName = 'lastName';
  static const String keyEmail = 'email';
  static const String keyImage = 'image';
  static const String keyIsFirstTime = 'isFirstTime';
  static const String keyActiveProfileId = 'activeProfileId';
  /// Stable per-installation ID for FCM token documents (preserved across logout).
  static const String keyInstallationId = 'installationId';

  // UI
  static const double designWidth = 430;
  static const double designHeight = 932;
}
