import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_engine.dart';
import '../../core/ai/ai_engine_registry.dart';
import '../../core/services/firestore_service.dart';
import '../../shared/models/chat_message.dart';

final cloudChatServiceProvider = Provider<CloudChatService>((ref) {
  final aiEngine = ref.watch(aiEngineProvider);
  return CloudChatService(aiEngine: aiEngine);
});

/// Chat service that maintains conversation history, persists messages
/// to Firestore, and delegates AI inference to the active [AiEngine].
class CloudChatService {
  final AiEngine _aiEngine;
  final List<Map<String, String>> _history = [];
  String? _threadId;

  CloudChatService({required AiEngine aiEngine}) : _aiEngine = aiEngine;

  /// Sends a user message to the AI, maintains history, and
  /// optionally persists to a Firestore chat thread.
  Future<String> sendMessage(
    String message, {
    String? profileId,
    String? planId,
    String? personaTypeKey,
  }) async {
    // Ensure a Firestore thread exists if profileId is provided
    await _ensureThread(profileId: profileId, planId: planId);

    _history.add({'role': 'user', 'content': message});

    // Persist user message to Firestore if we have a thread
    if (_threadId != null) {
      try {
        await FirestoreService.addChatMessage(
          _threadId!,
          ChatMessage(
            id: '',
            role: MessageRole.user,
            content: message,
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {/* non-blocking */}
    }

    // Delegate to the active Gemma 4 engine
    final response = await _aiEngine.chatOnPlan(
      profileId: profileId ?? '',
      planId: planId,
      userMessage: message,
      threadId: _threadId,
      history: List.from(_history),
      personaTypeKey: personaTypeKey,
    );

    _history.add({'role': 'assistant', 'content': response});

    // Persist AI response to Firestore
    if (_threadId != null) {
      try {
        await FirestoreService.addChatMessage(
          _threadId!,
          ChatMessage(
            id: '',
            role: MessageRole.assistant,
            content: response,
            timestamp: DateTime.now(),
          ),
        );
        await FirestoreService.updateChatThread(_threadId!, {});
      } catch (_) {/* non-blocking */}
    }

    return response;
  }

  Future<void> _ensureThread({
    String? profileId,
    String? planId,
  }) async {
    if (_threadId != null) return;
    if (profileId == null || profileId.isEmpty) return;
    try {
      _threadId = await FirestoreService.createChatThread({
        'profileId': profileId,
        if (planId != null) 'planId': planId,
      });
    } catch (_) {/* non-blocking */}
  }

  void clearHistory() {
    _history.clear();
    _threadId = null;
  }

  String? get threadId => _threadId;

  List<Map<String, String>> get history => List.unmodifiable(_history);
}
