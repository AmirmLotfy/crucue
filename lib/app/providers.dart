import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logic/cache_helper.dart';
import '../core/services/firestore_service.dart';
import '../features/profiles/data/profiles_repository.dart';
import '../shared/models/app_user.dart';
import '../shared/models/care_profile.dart';

// ─── Theme Mode ────────────────────────────────────────────────────────────

/// The active theme mode — persisted to SharedPreferences via [CacheHelper].
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(CacheHelper.savedThemeMode);

  void setMode(ThemeMode mode) {
    state = mode;
    CacheHelper.saveThemeMode(mode);
  }
}

// ─── Auth State ────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// ─── App User ──────────────────────────────────────────────────────────────

final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return FirestoreService.getUser(uid);
});

// ─── Care Profiles ─────────────────────────────────────────────────────────
// Canonical stream: use profilesStreamProvider from ProfilesRepository.

final activeProfileIdProvider = StateProvider<String?>((ref) => null);

final activeProfileProvider = Provider<CareProfile?>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final profiles = ref.watch(profilesStreamProvider).valueOrNull ?? [];
  if (profileId == null || profiles.isEmpty) {
    return profiles.isNotEmpty ? profiles.first : null;
  }
  return profiles.firstWhere(
    (p) => p.id == profileId,
    orElse: () => profiles.first,
  );
});
