import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadProfilePhoto(File file) async {
    final uid = AuthService.currentUid;
    if (uid == null) throw Exception('User not authenticated');
    final ref = _storage.ref('users/$uid/profile_photo.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /// Upload a voice note to Storage before it's linked to an incident.
  /// Returns the download URL and the storage path.
  static Future<({String url, String path})> uploadVoiceNoteForProfile({
    required File file,
    required String profileId,
    required String voiceNoteId,
  }) async {
    final uid = AuthService.currentUid;
    if (uid == null) throw Exception('User not authenticated');
    final path =
        'users/$uid/profiles/$profileId/voiceNotes/$voiceNoteId/audio.m4a';
    final ref = _storage.ref(path);
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    final url = await task.ref.getDownloadURL();
    return (url: url, path: path);
  }

  /// Legacy: upload voice note scoped to a specific incident.
  static Future<String> uploadVoiceNote({
    required File file,
    required String profileId,
    required String incidentId,
  }) async {
    final uid = AuthService.currentUid;
    if (uid == null) throw Exception('User not authenticated');
    final ref = _storage.ref(
        'users/$uid/profiles/$profileId/incidents/$incidentId/voice.m4a');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    return await task.ref.getDownloadURL();
  }

  static Future<String> uploadIncidentImage({
    required File file,
    required String profileId,
    required String incidentId,
  }) async {
    final uid = AuthService.currentUid;
    if (uid == null) throw Exception('User not authenticated');
    final ext = file.path.split('.').last;
    final ref = _storage.ref(
        'users/$uid/profiles/$profileId/incidents/$incidentId/image.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }

  static Future<void> deleteUserStorage(String uid) async {
    try {
      final ref = _storage.ref('users/$uid');
      final list = await ref.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (_) {}
  }
}
