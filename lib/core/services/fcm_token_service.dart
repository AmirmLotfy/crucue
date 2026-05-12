import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../logic/cache_helper.dart';
import 'firestore_service.dart';

/// Persists the device FCM token under `users/{uid}/devices/{installationId}`.
class FcmTokenService {
  FcmTokenService._();

  static String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'unknown';
    }
  }

  static Future<void> syncForUser(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final installationId = await CacheHelper.getOrCreateInstallationId();
      await FirestoreService.upsertDeviceToken(
        uid: uid,
        installationId: installationId,
        token: token,
        platform: _platformLabel(),
      );
    } catch (e, st) {
      debugPrint('[FcmTokenService] sync failed: $e $st');
    }
  }

  static void listenTokenRefresh(String Function() currentUid) {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = currentUid();
      if (uid.isEmpty || token.isEmpty) return;
      final installationId = await CacheHelper.getOrCreateInstallationId();
      await FirestoreService.upsertDeviceToken(
        uid: uid,
        installationId: installationId,
        token: token,
        platform: _platformLabel(),
      );
    });
  }
}
