import '../../shared/models/support_plan.dart';
import '../services/cloud_functions_service.dart';
import 'ai_engine.dart';

/// Production AI engine that routes inference through Firebase Cloud Functions
/// calling Gemma via the Google GenAI API (API key in Secrets). The optional
/// Cloud Run AI gateway (`backend/ai-gateway`) can expose Vertex-backed HTTP routes.
///
/// Flow:
///   Flutter → [RemoteGemma4Engine] → Callable Functions → Gemma 4 → JSON
///
/// This engine:
/// - Keeps the Gemma 4 API key entirely server-side
/// - Supports structured JSON output schemas
/// - Enables server-side safety checks and context enrichment
/// - Maintains a clean abstraction over the inference endpoint
class RemoteGemma4Engine implements AiEngine {
  const RemoteGemma4Engine();

  @override
  Future<SupportPlan> generateSupportPlan({
    required String profileId,
    String? incidentId,
    Map<String, dynamic>? personaData,
    List<String>? challenges,
    Map<String, dynamic>? incidentContext,
    String? personaTypeKey,
  }) async {
    return CloudFunctionsService.generateSupportPlan(
      profileId: profileId,
      incidentId: incidentId,
      personaData: personaData,
      challenges: challenges,
      incidentContext: incidentContext,
      personaTypeKey: personaTypeKey,
    );
  }

  @override
  Future<String> chatOnPlan({
    required String profileId,
    String? planId,
    required String userMessage,
    String? threadId,
    List<Map<String, String>>? history,
    String? personaTypeKey,
  }) async {
    return CloudFunctionsService.chatOnPlan(
      profileId: profileId,
      planId: planId,
      userMessage: userMessage,
      threadId: threadId,
      history: history,
      personaTypeKey: personaTypeKey,
    );
  }

  @override
  Future<Map<String, dynamic>> summarizePatterns({
    required String profileId,
    DateTime? weekStart,
  }) async {
    return CloudFunctionsService.summarizePatterns(
      profileId: profileId,
      weekStart: weekStart,
    );
  }

  @override
  Future<Map<String, dynamic>> suggestRoutineFromReflection({
    required String profileId,
    required String planId,
    String? reflectionNotes,
    List<String>? stepsHelpedMost,
    String? personaTypeKey,
  }) async {
    return CloudFunctionsService.suggestRoutineFromReflection(
      profileId: profileId,
      planId: planId,
      reflectionNotes: reflectionNotes,
      stepsHelpedMost: stepsHelpedMost,
      personaTypeKey: personaTypeKey,
    );
  }

  @override
  Future<VoiceProcessingResult> processVoiceIncident({
    required String voiceNoteId,
    required String profileId,
    required String audioStoragePath,
    String? personaTypeKey,
  }) async {
    return CloudFunctionsService.processVoiceIncident(
      voiceNoteId: voiceNoteId,
      profileId: profileId,
      audioStoragePath: audioStoragePath,
      personaTypeKey: personaTypeKey,
    );
  }

  @override
  Future<String> transcribeShortClip({
    required String audioStoragePath,
  }) async {
    return CloudFunctionsService.transcribeShortClip(
      audioStoragePath: audioStoragePath,
    );
  }
}
