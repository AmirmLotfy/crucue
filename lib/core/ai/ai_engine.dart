import '../../shared/models/support_plan.dart';

/// Abstract AI engine interface.
///
/// All AI feature calls in Crucue route through this interface.
/// The production implementation is [RemoteGemma4Engine] which
/// delegates to Firebase Cloud Functions (or the Cloud Run AI Gateway)
/// running Gemma 4.
///
/// [HybridGemmaEngine] uses the community `flutter_gemma` plugin (Gemma 4 E2B-class
/// on-device) for the weekly insight path. Native LiteRT-LM MethodChannel bridges
/// exist in the Android/iOS platform code as roadmap scaffolding.
///
/// The active engine is selected by [aiEngineProvider] based on [AiMode].
abstract class AiEngine {
  /// Generates a structured support plan from a care profile and incident.
  ///
  /// [profileId] — Firestore profile ID (empty string for legacy/quick flow)
  /// [incidentId] — optional Firestore incident ID
  /// [personaData] — serialized profile / persona context map
  /// [challenges] — selected or typed challenge strings
  /// [incidentContext] — extended incident fields (trigger, tried, outcome)
  /// [personaTypeKey] — persona type name for policy pack selection
  Future<SupportPlan> generateSupportPlan({
    required String profileId,
    String? incidentId,
    Map<String, dynamic>? personaData,
    List<String>? challenges,
    Map<String, dynamic>? incidentContext,
    String? personaTypeKey,
  });

  /// Sends a message in a grounded care chat and returns the AI response.
  ///
  /// The response is grounded in the profile, active plan, and recent
  /// reflections so the conversation stays contextually relevant.
  ///
  /// [profileId] — Firestore profile ID
  /// [planId] — optional active plan ID for plan-grounded responses
  /// [userMessage] — the user's message text
  /// [threadId] — optional Firestore thread ID for persistence
  /// [history] — recent conversation turns for context window
  /// [personaTypeKey] — persona type name for policy pack selection
  Future<String> chatOnPlan({
    required String profileId,
    String? planId,
    required String userMessage,
    String? threadId,
    List<Map<String, String>>? history,
    String? personaTypeKey,
  });

  /// Summarizes weekly patterns from incidents, plans and check-ins.
  ///
  /// Returns a map with `summary`, `patterns`, `whatWorked`, `suggestions`.
  Future<Map<String, dynamic>> summarizePatterns({
    required String profileId,
    DateTime? weekStart,
  });

  /// Suggests a new routine based on a completed plan check-in reflection.
  ///
  /// [profileId] — Firestore profile ID
  /// [planId] — the plan being reflected on
  /// [reflectionNotes] — free-text notes from the check-in
  /// [stepsHelpedMost] — step IDs that the caregiver found most helpful
  /// [personaTypeKey] — persona type name for policy pack selection
  ///
  /// Returns a map with `title`, `steps`, `frequency`,
  /// `estimatedDurationMinutes`, `tags`, and `rationale`.
  Future<Map<String, dynamic>> suggestRoutineFromReflection({
    required String profileId,
    required String planId,
    String? reflectionNotes,
    List<String>? stepsHelpedMost,
    String? personaTypeKey,
  });

  /// Processes a voice note: transcribes audio via Google Cloud STT, then uses
  /// Gemma 4 to extract structured incident fields from the transcript.
  ///
  /// [voiceNoteId] — Firestore ID of the VoiceNote document
  /// [profileId] — owning profile
  /// [audioStoragePath] — Firebase Storage path (used server-side to read audio)
  ///
  /// Returns a [VoiceProcessingResult] with transcript + structured incident.
  Future<VoiceProcessingResult> processVoiceIncident({
    required String voiceNoteId,
    required String profileId,
    required String audioStoragePath,
    String? personaTypeKey,
  });

  /// Transcribes a short voice clip and returns plain text.
  ///
  /// Used for voice chat input (max 30s clips) where we don't need
  /// full incident extraction — just the user's spoken question.
  Future<String> transcribeShortClip({
    required String audioStoragePath,
  });
}

/// Result returned by [AiEngine.processVoiceIncident].
class VoiceProcessingResult {
  final String transcript;
  final Map<String, dynamic> extractedIncident;
  final bool safetyFlag;

  const VoiceProcessingResult({
    required this.transcript,
    required this.extractedIncident,
    this.safetyFlag = false,
  });

  factory VoiceProcessingResult.fromMap(Map<String, dynamic> map) {
    return VoiceProcessingResult(
      transcript: map['transcript'] as String? ?? '',
      extractedIncident:
          map['extractedIncident'] as Map<String, dynamic>? ?? {},
      safetyFlag: map['safetyFlag'] as bool? ?? false,
    );
  }
}
