import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/support_plan.dart';

class RoutinesRepository {
  Stream<List<Routine>> watchRoutines(String profileId,
          {bool activeOnly = false}) =>
      FirestoreService.watchRoutines(profileId, activeOnly: activeOnly);

  Future<Routine?> getRoutine(String profileId, String routineId) =>
      FirestoreService.getRoutine(profileId, routineId);

  Future<String> createRoutine(String profileId, Routine routine) =>
      FirestoreService.createRoutine(profileId, routine);

  Future<void> updateRoutine(
          String profileId, String routineId, Map<String, dynamic> data) =>
      FirestoreService.updateRoutine(profileId, routineId, data);

  Future<void> deleteRoutine(String profileId, String routineId) =>
      FirestoreService.deleteRoutine(profileId, routineId);

  Future<void> markUsed(String profileId, String routineId) =>
      FirestoreService.markRoutineUsed(profileId, routineId);

  /// Creates a Routine pre-filled from a SupportPlan's follow-up tasks.
  Routine routineFromPlan({
    required String profileId,
    required SupportPlan plan,
    required String title,
    RoutineFrequency frequency = RoutineFrequency.daily,
    List<String>? tags,
  }) {
    final steps = [
      ...plan.whatToDoNow,
      ...plan.followUpTasks,
    ].where((s) => s.isNotEmpty).toList();

    return Routine(
      id: '',
      profileId: profileId,
      title: title,
      description: plan.summary.length > 100
          ? '${plan.summary.substring(0, 100)}…'
          : plan.summary,
      frequency: frequency,
      steps: steps,
      basedOnPlanId: plan.id.isEmpty ? null : plan.id,
      tags: tags ?? [],
      createdAt: DateTime.now(),
    );
  }
}

final routinesRepositoryProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository();
});

final routinesProvider =
    StreamProvider.family<List<Routine>, String>((ref, profileId) {
  return ref.watch(routinesRepositoryProvider).watchRoutines(profileId);
});

final activeRoutinesProvider =
    StreamProvider.family<List<Routine>, String>((ref, profileId) {
  return ref
      .watch(routinesRepositoryProvider)
      .watchRoutines(profileId, activeOnly: true);
});
