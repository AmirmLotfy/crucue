import 'package:cloud_functions/cloud_functions.dart';

import '../../core/ai/ai_engine.dart';
import '../../shared/models/support_plan.dart';
import '../../shared/persona_policies.dart';

class CloudFunctionsService {
  static FirebaseFunctions get _functions => FirebaseFunctions.instance;

  /// Generates an AI support plan based on the profile and incident context.
  /// Passes persona-specific policy overrides for tailored guidance.
  /// Falls back to a demo plan if the Cloud Function is unavailable.
  static Future<SupportPlan> generateSupportPlan({
    required String profileId,
    String? incidentId,
    Map<String, dynamic>? profileData,
    List<String>? challenges,
    Map<String, dynamic>? personaData,
    Map<String, dynamic>? incidentContext,
    String? personaTypeKey,
  }) async {
    // Build persona policy overrides for the Cloud Function
    final policyOverrides = personaTypeKey != null
        ? PersonaPolicy.forType(personaTypeKey).toMap()
        : null;

    try {
      final callable = _functions.httpsCallable(
        'generateSupportPlan',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );
      final result = await callable.call({
        'profileId': profileId,
        if (incidentId != null) 'incidentId': incidentId,
        if (profileData != null) 'profileData': profileData,
        if (challenges != null) 'challenges': challenges,
        if (personaData != null) 'personaData': personaData,
        if (incidentContext != null) 'incidentContext': incidentContext,
        if (policyOverrides != null) 'policyOverrides': policyOverrides,
      });
      return SupportPlan.fromMap(
        Map<String, dynamic>.from(result.data as Map),
        id: result.data['planId'] as String? ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      _logError('generateSupportPlan', e.message ?? e.toString());
      return _buildDemoPlan(
        profileId: profileId,
        profileData: profileData,
        challenges: challenges,
        personaTypeKey: personaTypeKey,
      );
    } catch (e) {
      _logError('generateSupportPlan', e.toString());
      return _buildDemoPlan(
        profileId: profileId,
        profileData: profileData,
        challenges: challenges,
        personaTypeKey: personaTypeKey,
      );
    }
  }

  /// Sends a message to the grounded chat and returns the AI response.
  /// Optionally persists to a Firestore thread via [threadId].
  static Future<String> chatOnPlan({
    required String profileId,
    String? planId,
    required String userMessage,
    String? threadId,
    List<Map<String, String>>? history,
    String? personaTypeKey,
  }) async {
    final policyOverrides = personaTypeKey != null
        ? PersonaPolicy.forType(personaTypeKey).toMap()
        : null;
    try {
      final callable = _functions.httpsCallable(
        'chatOnPlan',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final result = await callable.call({
        'profileId': profileId,
        if (planId != null) 'planId': planId,
        'userMessage': userMessage,
        if (threadId != null) 'threadId': threadId,
        if (history != null) 'history': history,
        if (policyOverrides != null) 'policyOverrides': policyOverrides,
      });
      return result.data['response'] as String? ??
          _defaultChatResponse(userMessage);
    } on FirebaseFunctionsException catch (e) {
      _logError('chatOnPlan', e.message ?? e.toString());
      return _defaultChatResponse(userMessage);
    } catch (e) {
      _logError('chatOnPlan', e.toString());
      return _defaultChatResponse(userMessage);
    }
  }

  /// Generates a weekly insight summary for a care profile.
  /// Suggests a routine from a completed plan reflection (callable `suggestRoutineFromReflection`).
  static Future<Map<String, dynamic>> suggestRoutineFromReflection({
    required String profileId,
    required String planId,
    String? reflectionNotes,
    List<String>? stepsHelpedMost,
    String? personaTypeKey,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'suggestRoutineFromReflection',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
      );
      final result = await callable.call({
        'profileId': profileId,
        'planId': planId,
        if (reflectionNotes != null) 'reflectionNotes': reflectionNotes,
        if (stepsHelpedMost != null) 'stepsHelpedMost': stepsHelpedMost,
        if (personaTypeKey != null) 'personaTypeKey': personaTypeKey,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      _logError('suggestRoutineFromReflection', e.message ?? e.toString());
      rethrow;
    } catch (e) {
      _logError('suggestRoutineFromReflection', e.toString());
      rethrow;
    }
  }

  /// Sends a test FCM to all tokens under `users/{uid}/devices/*`.
  static Future<Map<String, dynamic>> sendTestPushNotification({
    String title = 'Crucue',
    String body = 'Test notification',
  }) async {
    try {
      final callable = _functions.httpsCallable('sendTestPushNotification');
      final result = await callable.call({
        'title': title,
        'body': body,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      _logError('sendTestPushNotification', e.message ?? e.toString());
      rethrow;
    } catch (e) {
      _logError('sendTestPushNotification', e.toString());
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> summarizePatterns({
    required String profileId,
    DateTime? weekStart,
  }) async {
    try {
      final callable = _functions.httpsCallable('summarizePatterns');
      final result = await callable.call({
        'profileId': profileId,
        if (weekStart != null) 'weekStart': weekStart.toIso8601String(),
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      _logError('summarizePatterns', e.toString());
      return {
        'summary': 'Keep going — you\'re learning what works best.',
        'patterns': <String>[],
        'whatWorked': <String>[],
        'suggestions': <String>[
          'Continue logging daily moments to build insights.'
        ],
      };
    }
  }

  static SupportPlan _buildDemoPlan({
    required String profileId,
    Map<String, dynamic>? profileData,
    List<String>? challenges,
    String? personaTypeKey,
  }) {
    final name = profileData?['name'] as String? ?? 'your loved one';
    final challengeText = challenges?.isNotEmpty == true
        ? challenges!.join(', ')
        : 'the current situation';
    final policy = personaTypeKey != null
        ? PersonaPolicy.forType(personaTypeKey)
        : null;

    return SupportPlan(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      profileId: profileId,
      summary:
          'Here\'s a calm, practical approach to support $name through $challengeText.',
      whatMightBeHappening:
          '$name may be feeling overwhelmed, uncertain, or in need of more connection right now. '
          'These moments are often communication, not just behavior.',
      whatToDoNow: [
        'Start by acknowledging their feelings without jumping to solutions',
        'Offer calm, unhurried presence — sit nearby if possible',
        'Use simple, clear language and reduce noise or distractions',
        'Try a familiar comfort: a favorite activity, snack, or routine',
        'Give them some choice and control over a small decision',
      ],
      whatToAvoid: [
        'Avoid escalating your own tone or body language',
        'Don\'t try to reason through the emotion in the moment',
        'Avoid too many questions at once',
      ],
      messageDraft:
          'I can see this is hard right now. I\'m here with you and we\'ll get through this together.',
      followUpTasks: [
        'Check in after 30 minutes to see how they\'re feeling',
        'Note what helped so you can remember for next time',
        if (policy != null && policy.routineExamples.isNotEmpty)
          'Consider: ${policy.routineExamples.first}',
      ],
      reflectionPrompt:
          'After trying this, pause and ask yourself: What shifted? What did $name respond to most?',
      escalationFlag: false,
      safetyNote:
          'This guidance is supportive, not clinical. If you\'re concerned about safety or wellbeing, please reach out to a qualified professional.',
      createdAt: DateTime.now(),
    );
  }

  static String _defaultChatResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('help') || lower.contains('what do i do')) {
      return 'You\'re doing the right thing by reaching out. Let\'s think through this step by step. Can you tell me a bit more about what\'s happening right now?';
    }
    if (lower.contains('thank')) {
      return 'You\'re very welcome. Remember, you\'re not alone in this — you\'re showing up with care and intention, and that matters deeply.';
    }
    return 'I\'m here to support you through this. What would be most helpful to focus on right now?';
  }

  // ─── Voice Processing ─────────────────────────────────────────────

  /// Triggers the full voice pipeline:
  ///   1. Google Cloud STT transcribes audio from Storage
  ///   2. Gemma 4 extracts structured incident fields from transcript
  ///
  /// The Cloud Function also updates the Firestore VoiceNote document
  /// with status changes and the final result.
  static Future<VoiceProcessingResult> processVoiceIncident({
    required String voiceNoteId,
    required String profileId,
    required String audioStoragePath,
    String? personaTypeKey,
  }) async {
    final policyOverrides = personaTypeKey != null
        ? PersonaPolicy.forType(personaTypeKey).toMap()
        : null;
    try {
      final callable = _functions.httpsCallable(
        'processVoiceIncident',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final result = await callable.call({
        'voiceNoteId': voiceNoteId,
        'profileId': profileId,
        'audioStoragePath': audioStoragePath,
        if (policyOverrides != null) 'policyOverrides': policyOverrides,
      });
      return VoiceProcessingResult.fromMap(
          Map<String, dynamic>.from(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      _logError('processVoiceIncident', e.message ?? e.toString());
      return _buildDemoVoiceResult();
    } catch (e) {
      _logError('processVoiceIncident', e.toString());
      return _buildDemoVoiceResult();
    }
  }

  /// Transcribes a short voice clip (max 30s) for voice chat input.
  static Future<String> transcribeShortClip({
    required String audioStoragePath,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'transcribeShortClip',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final result = await callable.call({
        'audioStoragePath': audioStoragePath,
      });
      return result.data['transcript'] as String? ?? '';
    } on FirebaseFunctionsException catch (e) {
      _logError('transcribeShortClip', e.message ?? e.toString());
      return '';
    } catch (e) {
      _logError('transcribeShortClip', e.toString());
      return '';
    }
  }

  static VoiceProcessingResult _buildDemoVoiceResult() {
    return VoiceProcessingResult(
      transcript:
          'I just wanted to record what happened this morning. There was a difficult moment with bedtime. '
          'My child had a hard time settling down and was upset for about 20 minutes. '
          'I tried the usual calm-down steps but they weren\'t working as well as usual.',
      extractedIncident: {
        'incident_title': 'Difficult bedtime — upset and hard to settle',
        'incident_category': 'routine',
        'intensity': 3,
        'possible_trigger': 'Overtired, missed afternoon nap',
        'what_user_already_tried': 'Usual calm-down steps',
        'desired_outcome': 'Settle down and get to sleep',
        'cleaned_summary':
            'Child had a prolonged difficult bedtime, resisting settling for about 20 minutes.',
        'confidence': 0.85,
      },
      safetyFlag: false,
    );
  }

  static void _logError(String function, String message) {
    // ignore: avoid_print
    print('[CloudFunctionsService] $function error: $message');
  }
}
