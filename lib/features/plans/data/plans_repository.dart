import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../shared/models/support_plan.dart';

class PlansRepository {
  Stream<List<SupportPlan>> watchPlans(String profileId) =>
      FirestoreService.watchPlans(profileId);

  Future<SupportPlan?> getPlan(String profileId, String planId) =>
      FirestoreService.getPlan(profileId, planId);

  Future<String> savePlan(String profileId, SupportPlan plan) =>
      FirestoreService.savePlan(profileId, plan);
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository();
});

final plansProvider =
    StreamProvider.family<List<SupportPlan>, String>((ref, profileId) {
  return ref.watch(plansRepositoryProvider).watchPlans(profileId);
});
