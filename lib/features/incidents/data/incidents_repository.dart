import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../shared/models/incident.dart';

class IncidentsRepository {
  Stream<List<Incident>> watchIncidents(String profileId) =>
      FirestoreService.watchIncidents(profileId);

  Future<Incident?> getIncident(String profileId, String incidentId) =>
      FirestoreService.getIncident(profileId, incidentId);

  Future<String> createIncident(String profileId, Incident incident) =>
      FirestoreService.createIncident(profileId, incident);
}

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return IncidentsRepository();
});

final incidentsProvider =
    StreamProvider.family<List<Incident>, String>((ref, profileId) {
  return ref.watch(incidentsRepositoryProvider).watchIncidents(profileId);
});
