import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../shared/models/care_profile.dart';

class ProfilesRepository {
  Stream<List<CareProfile>> watchProfiles() =>
      FirestoreService.watchProfiles();

  Future<CareProfile?> getProfile(String profileId) =>
      FirestoreService.getProfile(profileId);

  Future<String> createProfile(CareProfile profile) =>
      FirestoreService.createProfile(profile);

  Future<void> updateProfile(String profileId, CareProfile profile) =>
      FirestoreService.updateProfile(profileId, profile);

  Future<void> deleteProfile(String profileId) =>
      FirestoreService.deleteProfile(profileId);
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  return ProfilesRepository();
});

final profilesStreamProvider = StreamProvider<List<CareProfile>>((ref) {
  return ref.watch(profilesRepositoryProvider).watchProfiles();
});
