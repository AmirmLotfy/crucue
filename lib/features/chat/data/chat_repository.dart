import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../shared/models/chat_message.dart';

class ChatRepository {
  Future<String> createThread({
    required String profileId,
    String? planId,
  }) =>
      FirestoreService.createChatThread({
        'profileId': profileId,
        if (planId != null) 'planId': planId,
      });

  Stream<List<ChatMessage>> watchMessages(String threadId) =>
      FirestoreService.watchChatMessages(threadId);

  Future<void> addMessage(String threadId, ChatMessage message) =>
      FirestoreService.addChatMessage(threadId, message);
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, threadId) {
  return ref.watch(chatRepositoryProvider).watchMessages(threadId);
});
