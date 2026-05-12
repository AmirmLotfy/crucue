import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../shared/models/support_plan.dart';
import '../config/feature_flags.dart';
import '../services/firestore_service.dart';
import 'ai_engine.dart';
import 'gemma_local_summarizer.dart';
import 'remote_gemma4_engine.dart';

/// Hybrid **mobile** engine: routes **weekly insight** (`summarizePatterns`) to a
/// small on-device Gemma when the **flutter_gemma** runtime has an active model;
/// every other AI call uses the **remote** Cloud Functions path (`gemma-4-26b-a4b-it`
/// or `GEMMA4_MODEL`).
///
/// **Routing policy (explicit):**
/// 1. `generateSupportPlan`, `chatOnPlan`, `processVoiceIncident`, `transcribeShortClip`,
///    `suggestRoutineFromReflection` → always **remote** (quality + shared safety layer).
/// 2. `summarizePatterns` → **local** if `FeatureFlags.localWeeklyInsightWithFlutterGemma`
///    is true and `FlutterGemma.hasActiveModel()`; else **remote**. On local failure,
///    falls back to remote (see [summarizePatterns] implementation).
///
/// This is not quality parity with cloud `gemma-4-26b-a4b-it`; see
/// `FeatureFlags` and repo doc `docs/edge_demo_path.md`.
class HybridGemmaEngine implements AiEngine {
  const HybridGemmaEngine();

  static const RemoteGemma4Engine _remote = RemoteGemma4Engine();

  static DateTime _weekStartMonday(DateTime? weekStart) {
    if (weekStart != null) return weekStart;
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Future<SupportPlan> generateSupportPlan({
    required String profileId,
    String? incidentId,
    Map<String, dynamic>? personaData,
    List<String>? challenges,
    Map<String, dynamic>? incidentContext,
    String? personaTypeKey,
  }) {
    return _remote.generateSupportPlan(
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
  }) {
    return _remote.chatOnPlan(
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
    final ws = _weekStartMonday(weekStart);

    if (FeatureFlags.localWeeklyInsightWithFlutterGemma &&
        FlutterGemma.hasActiveModel()) {
      try {
        final snap =
            await FirestoreService.fetchWeeklySummarizeInput(profileId, ws);
        return await summarizeWeeklyWithFlutterGemma(snap);
      } catch (e, st) {
        debugPrint(
          'HybridGemmaEngine: on-device weekly insight failed, using remote: $e',
        );
        debugPrint('$st');
      }
    }

    return _remote.summarizePatterns(profileId: profileId, weekStart: ws);
  }

  @override
  Future<Map<String, dynamic>> suggestRoutineFromReflection({
    required String profileId,
    required String planId,
    String? reflectionNotes,
    List<String>? stepsHelpedMost,
    String? personaTypeKey,
  }) {
    return _remote.suggestRoutineFromReflection(
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
  }) {
    return _remote.processVoiceIncident(
      voiceNoteId: voiceNoteId,
      profileId: profileId,
      audioStoragePath: audioStoragePath,
      personaTypeKey: personaTypeKey,
    );
  }

  @override
  Future<String> transcribeShortClip({
    required String audioStoragePath,
  }) {
    return _remote.transcribeShortClip(audioStoragePath: audioStoragePath);
  }
}
