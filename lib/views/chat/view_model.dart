import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/analytics_events.dart';
import 'model.dart';

final chatProvider =
    StateNotifierProvider<ChatViewModel, List<String>>((ref) {
  return ChatViewModel(ref);
});

class ChatViewModel extends StateNotifier<List<String>> {
  final StateNotifierProviderRef _ref;
  String? _profileId;
  String? _planId;
  String? _personaTypeKey;

  ChatViewModel(this._ref) : super([]);

  void setContext({
    String? profileId,
    String? planId,
    String? personaTypeKey,
  }) {
    _profileId = profileId;
    _planId = planId;
    _personaTypeKey = personaTypeKey;
  }

  Future<void> sendMessage(String message, {bool isVoice = false}) async {
    state = [...state, 'You: $message'];
    CrucueAnalytics.logChatMessageSent(isVoice: isVoice);
    try {
      final response = await _ref.read(cloudChatServiceProvider).sendMessage(
            message,
            profileId: _profileId,
            planId: _planId,
            personaTypeKey: _personaTypeKey,
          );
      state = [...state, 'AI: $response'];
    } catch (e) {
      CrucueAnalytics.recordError(e, StackTrace.current, reason: 'chat_send_failed');
      state = [
        ...state,
        "AI: I'm having trouble connecting right now. Please try again in a moment.",
      ];
    }
  }

  void clearChat() {
    _ref.read(cloudChatServiceProvider).clearHistory();
    state = [];
  }

  /// Seeds the initial assistant greeting when the thread is still empty.
  void ensureWelcomeMessage({String? profileName}) {
    if (state.isNotEmpty) return;
    state = [
      'AI: Hi${profileName != null ? ", I know about $profileName" : ""}. I\'m here to help you think through what\'s going on. What would you like to talk through?',
    ];
  }
}
