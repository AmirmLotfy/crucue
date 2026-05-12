import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/app_user.dart';
import '../../shared/models/care_profile.dart';
import '../../shared/models/incident.dart';
import '../../shared/models/support_plan.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/checkin.dart';
import '../../shared/models/insight.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/voice_note.dart';
import 'auth_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ─── Collection References ───────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _users() =>
      _db.collection('users');

  static DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _users().doc(uid);

  static CollectionReference<Map<String, dynamic>> _profiles(String uid) =>
      _user(uid).collection('profiles');

  static DocumentReference<Map<String, dynamic>> _profile(
          String uid, String profileId) =>
      _profiles(uid).doc(profileId);

  static CollectionReference<Map<String, dynamic>> _incidents(
          String uid, String profileId) =>
      _profile(uid, profileId).collection('incidents');

  static CollectionReference<Map<String, dynamic>> _plans(
          String uid, String profileId) =>
      _profile(uid, profileId).collection('plans');

  static CollectionReference<Map<String, dynamic>> _routines(
          String uid, String profileId) =>
      _profile(uid, profileId).collection('routines');

  static CollectionReference<Map<String, dynamic>> _checkins(
          String uid, String profileId) =>
      _profile(uid, profileId).collection('checkins');

  static CollectionReference<Map<String, dynamic>> _insights(
          String uid, String profileId) =>
      _profile(uid, profileId).collection('insights');

  static CollectionReference<Map<String, dynamic>> _chatThreads(String uid) =>
      _user(uid).collection('chatThreads');

  static CollectionReference<Map<String, dynamic>> _devices(String uid) =>
      _user(uid).collection('devices');

  static CollectionReference<Map<String, dynamic>> _voiceNotes(
          String uid, String profileId) =>
      _profile(uid, profileId).collection('voiceNotes');

  // ─── User ─────────────────────────────────────────────────────────

  static Future<void> createUser(AppUser user) async {
    await _user(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  static Future<AppUser?> getUser(String uid) async {
    final doc = await _user(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _user(uid)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Stores FCM token for targeted push (one doc per app installation).
  static Future<void> upsertDeviceToken({
    required String uid,
    required String installationId,
    required String token,
    required String platform,
  }) async {
    if (uid.isEmpty || installationId.isEmpty || token.isEmpty) return;
    await _devices(uid).doc(installationId).set(
      {
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> deleteUser(String uid) async {
    await _user(uid).delete();
  }

  // ─── Care Profiles ────────────────────────────────────────────────

  static String get _uid => AuthService.currentUid ?? '';

  static Stream<List<CareProfile>> watchProfiles() {
    return _profiles(_uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CareProfile.fromFirestore(d)).toList());
  }

  static Future<CareProfile?> getProfile(String profileId) async {
    final doc = await _profile(_uid, profileId).get();
    if (!doc.exists) return null;
    return CareProfile.fromFirestore(doc);
  }

  static Future<String> createProfile(CareProfile profile) async {
    final ref = _profiles(_uid).doc();
    await ref.set(profile.toMap());
    return ref.id;
  }

  static Future<void> updateProfile(
      String profileId, CareProfile profile) async {
    await _profile(_uid, profileId).update({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProfile(String profileId) async {
    await _profile(_uid, profileId).delete();
  }

  // ─── Incidents ────────────────────────────────────────────────────

  static Stream<List<Incident>> watchIncidents(String profileId,
      {int limit = 20}) {
    return _incidents(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Incident.fromFirestore(d)).toList());
  }

  static Stream<List<Incident>> watchRecentIncidents(String profileId,
      {int limit = 5}) {
    return _incidents(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Incident.fromFirestore(d)).toList());
  }

  static Future<String> createIncident(
      String profileId, Incident incident) async {
    final ref = _incidents(_uid, profileId).doc();
    await ref.set(incident.toMap());
    return ref.id;
  }

  static Future<Incident?> getIncident(
      String profileId, String incidentId) async {
    final doc = await _incidents(_uid, profileId).doc(incidentId).get();
    if (!doc.exists) return null;
    return Incident.fromFirestore(doc);
  }

  // ─── Support Plans ─────────────────────────────────────────────────

  static Stream<List<SupportPlan>> watchPlans(String profileId,
      {int limit = 20}) {
    return _plans(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SupportPlan.fromFirestore(d)).toList());
  }

  static Stream<List<SupportPlan>> watchRecentPlans(String profileId,
      {int limit = 3}) {
    return _plans(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SupportPlan.fromFirestore(d)).toList());
  }

  static Future<String> savePlan(String profileId, SupportPlan plan) async {
    final ref = _plans(_uid, profileId).doc();
    await ref.set(plan.toMap());
    return ref.id;
  }

  /// Saves a plan with additional UI context (persona model, challenges, incident link).
  ///
  /// If [profileId] is empty, falls back to the legacy `/users/{uid}/history` collection.
  static Future<String> savePlanWithContext({
    required String? profileId,
    required SupportPlan plan,
    required Map<String, dynamic> personaModel,
    required List<String> selectedChallenges,
    String? incidentId,
  }) async {
    final uid = _uid;
    final extra = {
      'personaModel': personaModel,
      'selectedChallenges': selectedChallenges,
      if (incidentId != null) 'incidentId': incidentId,
    };

    if (profileId != null && profileId.isNotEmpty) {
      final ref = _plans(uid, profileId).doc();
      await ref.set({...plan.toMap(), ...extra});
      return ref.id;
    } else {
      // Legacy: save without a profile scope
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc();
      await ref.set({...plan.toMap(), ...extra, 'createdAt': FieldValue.serverTimestamp()});
      return ref.id;
    }
  }

  static Future<SupportPlan?> getPlan(
      String profileId, String planId) async {
    final doc = await _plans(_uid, profileId).doc(planId).get();
    if (!doc.exists) return null;
    return SupportPlan.fromFirestore(doc);
  }

  // ─── Routines ─────────────────────────────────────────────────────

  static Stream<List<Routine>> watchRoutines(String profileId,
      {bool activeOnly = false}) {
    var query = _routines(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(50);
    return query.snapshots().map((snap) {
      final routines =
          snap.docs.map((d) => Routine.fromFirestore(d)).toList();
      if (activeOnly) return routines.where((r) => r.isActive).toList();
      return routines;
    });
  }

  static Future<String> createRoutine(
      String profileId, Routine routine) async {
    final ref = _routines(_uid, profileId).doc();
    await ref.set(routine.toMap());
    return ref.id;
  }

  static Future<void> updateRoutine(
      String profileId, String routineId, Map<String, dynamic> data) async {
    await _routines(_uid, profileId).doc(routineId).update(data);
  }

  static Future<void> deleteRoutine(
      String profileId, String routineId) async {
    await _routines(_uid, profileId).doc(routineId).delete();
  }

  static Future<void> markRoutineUsed(
      String profileId, String routineId) async {
    await _routines(_uid, profileId).doc(routineId).update({
      'lastUsedAt': FieldValue.serverTimestamp(),
      'completionCount': FieldValue.increment(1),
    });
  }

  static Future<Routine?> getRoutine(
      String profileId, String routineId) async {
    final doc = await _routines(_uid, profileId).doc(routineId).get();
    if (!doc.exists) return null;
    return Routine.fromFirestore(doc);
  }

  // ─── Check-Ins / Reflections ─────────────────────────────────────

  static Future<String> createCheckIn(
      String profileId, CheckIn checkIn) async {
    final ref = _checkins(_uid, profileId).doc();
    await ref.set(checkIn.toMap());
    return ref.id;
  }

  static Stream<List<CheckIn>> watchCheckIns(String profileId,
      {int limit = 20}) {
    return _checkins(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CheckIn.fromFirestore(d)).toList());
  }

  static Stream<List<CheckIn>> watchRecentCheckIns(String profileId,
      {int limit = 5}) {
    return _checkins(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CheckIn.fromFirestore(d)).toList());
  }

  static Future<List<CheckIn>> getRecentCheckInsOnce(String profileId,
      {int limit = 10}) async {
    final snap = await _checkins(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => CheckIn.fromFirestore(d)).toList();
  }

  // ─── Weekly summarize context (mirrors `summarizePatterns` callable) ─

  /// Fetches incidents, plans, and check-ins for [weekStart]..[weekStart+7d),
  /// using the same collection filters as the `summarizePatterns` Cloud Function.
  static Future<WeeklySummarizeSnapshot> fetchWeeklySummarizeInput(
    String profileId,
    DateTime weekStart,
  ) async {
    final uid = _uid;
    final startTs = Timestamp.fromDate(weekStart);
    final endTs = Timestamp.fromDate(weekStart.add(const Duration(days: 7)));
    final profileBase = _profile(uid, profileId);

    final results = await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      profileBase
          .collection('incidents')
          .where('createdAt', isGreaterThanOrEqualTo: startTs)
          .where('createdAt', isLessThan: endTs)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(),
      profileBase
          .collection('plans')
          .where('createdAt', isGreaterThanOrEqualTo: startTs)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get(),
      profileBase
          .collection('checkins')
          .where('createdAt', isGreaterThanOrEqualTo: startTs)
          .where('createdAt', isLessThan: endTs)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(),
    ]);

    final incidentsSnap = results[0];
    final plansSnap = results[1];
    final checkinsSnap = results[2];

    final incidents = incidentsSnap.docs.map((d) {
      final m = d.data();
      return {
        'title': '${m['title'] ?? m['trigger'] ?? ''}',
        'category': '${m['category'] ?? 'unknown'}',
        'intensity': (m['intensity'] as num?)?.toInt() ?? 3,
      };
    }).toList();

    final plans = plansSnap.docs.map((d) {
      final m = d.data();
      final tasks = m['followUpTasks'] ?? m['follow_up_tasks'];
      return {
        'summary': '${m['summary'] ?? ''}',
        'followUpTasks': tasks is List
            ? tasks.map((e) => e.toString()).toList()
            : <String>[],
      };
    }).toList();

    final checkins = checkinsSnap.docs.map((d) {
      final m = d.data();
      return {
        'didThisHelp': m['didThisHelp'] as bool? ?? false,
        'notes': m['notes'] as String?,
      };
    }).toList();

    return WeeklySummarizeSnapshot(
      incidents: incidents,
      plans: plans,
      checkins: checkins,
    );
  }

  // ─── Insights ─────────────────────────────────────────────────────

  static Future<String> saveInsight(String profileId, Insight insight) async {
    final ref = _insights(_uid, profileId).doc();
    await ref.set(insight.toMap());
    return ref.id;
  }

  static Stream<List<Insight>> watchInsights(String profileId) {
    return _insights(_uid, profileId)
        .orderBy('weekStart', descending: true)
        .limit(8)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => Insight.fromFirestore(d)).toList());
  }

  // ─── Chat Threads ─────────────────────────────────────────────────

  static Future<String> createChatThread(Map<String, dynamic> data) async {
    final ref = _chatThreads(_uid).doc();
    await ref.set({...data, 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  static Future<void> updateChatThread(
      String threadId, Map<String, dynamic> data) async {
    await _chatThreads(_uid)
        .doc(threadId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static CollectionReference<Map<String, dynamic>> chatMessages(
          String threadId) =>
      _chatThreads(_uid).doc(threadId).collection('messages');

  static Future<void> addChatMessage(
      String threadId, ChatMessage message) async {
    await chatMessages(threadId).add(message.toMap());
  }

  static Stream<List<ChatMessage>> watchChatMessages(String threadId) {
    return chatMessages(threadId)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList());
  }

  // ─── Voice Notes ──────────────────────────────────────────────────

  static Future<String> createVoiceNote(
      String profileId, VoiceNote voiceNote) async {
    final ref = _voiceNotes(_uid, profileId).doc();
    await ref.set(voiceNote.toMap());
    return ref.id;
  }

  static Future<void> updateVoiceNote(
      String profileId, String voiceNoteId, Map<String, dynamic> data) async {
    await _voiceNotes(_uid, profileId).doc(voiceNoteId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<VoiceNote?> getVoiceNote(
      String profileId, String voiceNoteId) async {
    final doc = await _voiceNotes(_uid, profileId).doc(voiceNoteId).get();
    if (!doc.exists) return null;
    return VoiceNote.fromFirestore(doc);
  }

  static Stream<VoiceNote?> watchVoiceNote(
      String profileId, String voiceNoteId) {
    return _voiceNotes(_uid, profileId)
        .doc(voiceNoteId)
        .snapshots()
        .map((snap) => snap.exists ? VoiceNote.fromFirestore(snap) : null);
  }

  static Stream<List<VoiceNote>> watchVoiceNotes(String profileId,
      {int limit = 20}) {
    return _voiceNotes(_uid, profileId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VoiceNote.fromFirestore(d)).toList());
  }

  static Future<void> linkVoiceNoteToIncident({
    required String profileId,
    required String voiceNoteId,
    required String incidentId,
  }) async {
    await updateVoiceNote(profileId, voiceNoteId, {'incidentId': incidentId});
  }

  // ─── Legacy history bridge ─────────────────────────────────────────

  static Future<void> saveLegacyHistory(Map<String, dynamic> data) async {
    await _user(_uid).collection('history').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchLegacyHistory() {
    return _user(_uid)
        .collection('history')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

/// Firestore slices aligned with the `summarizePatterns` Cloud Function queries.
class WeeklySummarizeSnapshot {
  const WeeklySummarizeSnapshot({
    required this.incidents,
    required this.plans,
    required this.checkins,
  });

  final List<Map<String, dynamic>> incidents;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> checkins;
}
