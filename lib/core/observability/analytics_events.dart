import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Typed analytics event helpers for Crucue.
///
/// All event names use snake_case to match Firebase Analytics conventions.
/// Properties are limited to string, number, or bool values.
///
/// Usage:
/// ```dart
/// CrucueAnalytics.logIncidentLogged(category: 'behavior', intensity: 3);
/// ```
class CrucueAnalytics {
  CrucueAnalytics._();

  static final _analytics = FirebaseAnalytics.instance;

  // ─── Profile Events ──────────────────────────────────────────────────────

  static Future<void> logProfileCreated({
    required String relationship,
  }) => _log('profile_created', {'relationship': relationship});

  // ─── Incident Events ─────────────────────────────────────────────────────

  static Future<void> logIncidentLogged({
    required String category,
    required int intensity,
    bool isVoice = false,
  }) => _log('incident_logged', {
        'category': category,
        'intensity': intensity,
        'is_voice': isVoice,
      });

  // ─── Plan Events ─────────────────────────────────────────────────────────

  static Future<void> logPlanGenerated({
    required String personaType,
    bool hasProfileId = false,
  }) => _log('plan_generated', {
        'persona_type': personaType,
        'has_profile': hasProfileId,
      });

  static Future<void> logPlanSaved({
    required String personaType,
  }) => _log('plan_saved', {'persona_type': personaType});

  static Future<void> logPlanListenedToTts() =>
      _log('plan_tts_played', {});

  // ─── Chat Events ─────────────────────────────────────────────────────────

  static Future<void> logChatMessageSent({
    bool isVoice = false,
  }) => _log('chat_message_sent', {'is_voice': isVoice});

  // ─── Reflection Events ───────────────────────────────────────────────────

  static Future<void> logReflectionSaved({
    required bool didHelp,
    required int outcomeRating,
    bool becameRoutine = false,
  }) => _log('reflection_saved', {
        'did_help': didHelp,
        'outcome_rating': outcomeRating,
        'became_routine': becameRoutine,
      });

  // ─── Routine Events ──────────────────────────────────────────────────────

  static Future<void> logRoutineCreated({
    required String frequency,
  }) => _log('routine_created', {'frequency': frequency});

  static Future<void> logRoutineUsed() => _log('routine_used', {});

  // ─── Insights Events ─────────────────────────────────────────────────────

  static Future<void> logInsightGenerated() =>
      _log('insight_generated', {});

  // ─── Voice Events ────────────────────────────────────────────────────────

  static Future<void> logVoiceRecordingStarted() =>
      _log('voice_recording_started', {});

  static Future<void> logVoiceProcessingCompleted({
    required bool success,
  }) => _log('voice_processing_completed', {'success': success});

  // ─── Error Reporting ─────────────────────────────────────────────────────

  /// Reports a non-fatal error to Crashlytics.
  static void recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('[CrucueAnalytics] error: $exception\nreason: $reason');
    }
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Logs a breadcrumb message to Crashlytics for debugging context.
  static void logBreadcrumb(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  static Future<void> _log(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) debugPrint('[CrucueAnalytics] logEvent failed: $e');
    }
  }
}
