import 'package:flutter/foundation.dart';

/// Feature flags and kill switches for Crucue.
///
/// These control feature availability at runtime without a full app release.
///
/// Production values are set here as constants. For remote kill switches,
/// wire these to Firebase Remote Config when ready:
/// ```dart
/// final remoteConfig = FirebaseRemoteConfig.instance;
/// static bool get voiceCaptureEnabled =>
///     remoteConfig.getBool('voice_capture_enabled');
/// ```
class FeatureFlags {
  FeatureFlags._();

  // ─── Core features ────────────────────────────────────────────────────────

  /// Voice recording and transcript-to-incident pipeline.
  /// Disable to fall back to text-only incident logging.
  static const bool voiceCaptureEnabled = true;

  /// On-device AI via [flutter_gemma](https://pub.dev/packages/flutter_gemma) (community
  /// plugin) + Gemma 4 **E2B/E4B** LiteRT-LM weights — not the cloud 26B model.
  /// Enables hybrid engine on Android/iOS and the Settings model download UI.
  static const bool onDeviceAiEnabled = true;

  /// When true, [HybridGemmaEngine] may run **weekly insights** on-device if weights
  /// are installed; otherwise falls back to the `summarizePatterns` callable.
  static const bool localWeeklyInsightWithFlutterGemma = true;

  /// Weekly insights AI generation.
  /// Requires sufficient incident/plan data for meaningful output.
  static const bool weeklyInsightsEnabled = true;

  /// Grounded chat follow-up on support plans.
  static const bool chatEnabled = true;

  /// Routine suggestion from reflection via callable `suggestRoutineFromReflection`.
  /// Set to `false` to skip the network call and use heuristic step pre-fill only.
  static const bool aiRoutineSuggestionEnabled = true;

  /// Text-to-speech plan playback (always available via platform TTS).
  static const bool ttsPlanPlaybackEnabled = true;

  // ─── Dev / debug ──────────────────────────────────────────────────────────

  /// Shows verbose AI debug info in the plan screen (debug builds only).
  static bool get showAiDebugInfo => kDebugMode;

  /// Forces AI to return a demo plan without network calls (debug builds only).
  static bool get forceDemoPlan => false;
}
