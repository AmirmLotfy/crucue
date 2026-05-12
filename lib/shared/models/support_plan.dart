import 'package:cloud_firestore/cloud_firestore.dart';

class SupportPlan {
  final String id;
  final String? profileId;
  final String? incidentId;
  final String summary;
  final String whatMightBeHappening;
  final List<String> whatToDoNow;
  final List<String> whatToAvoid;
  final String messageDraft;
  final List<String> followUpTasks;
  final String reflectionPrompt;
  final bool escalationFlag;
  final String? safetyNote;
  final DateTime createdAt;

  const SupportPlan({
    required this.id,
    this.profileId,
    this.incidentId,
    required this.summary,
    required this.whatMightBeHappening,
    required this.whatToDoNow,
    required this.whatToAvoid,
    required this.messageDraft,
    required this.followUpTasks,
    required this.reflectionPrompt,
    this.escalationFlag = false,
    this.safetyNote,
    required this.createdAt,
  });

  factory SupportPlan.fromMap(Map<String, dynamic> map, {String? id}) {
    return SupportPlan(
      id: id ?? map['id'] as String? ?? '',
      profileId: map['profileId'] as String?,
      incidentId: map['incidentId'] as String?,
      summary: map['summary'] as String? ?? '',
      whatMightBeHappening: map['what_might_be_happening'] as String? ??
          map['whatMightBeHappening'] as String? ?? '',
      whatToDoNow: _toStringList(map['what_to_do_now'] ?? map['whatToDoNow']),
      whatToAvoid: _toStringList(map['what_to_avoid'] ?? map['whatToAvoid']),
      messageDraft: map['message_draft'] as String? ??
          map['messageDraft'] as String? ?? '',
      followUpTasks:
          _toStringList(map['follow_up_tasks'] ?? map['followUpTasks']),
      reflectionPrompt: map['reflection_prompt'] as String? ??
          map['reflectionPrompt'] as String? ?? '',
      escalationFlag: map['escalation_flag'] as bool? ??
          map['escalationFlag'] as bool? ?? false,
      safetyNote:
          map['safety_note'] as String? ?? map['safetyNote'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory SupportPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportPlan.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'incidentId': incidentId,
      'summary': summary,
      'whatMightBeHappening': whatMightBeHappening,
      'whatToDoNow': whatToDoNow,
      'whatToAvoid': whatToAvoid,
      'messageDraft': messageDraft,
      'followUpTasks': followUpTasks,
      'reflectionPrompt': reflectionPrompt,
      'escalationFlag': escalationFlag,
      'safetyNote': safetyNote,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  SupportPlan copyWith({
    String? id,
    String? profileId,
    String? incidentId,
    String? summary,
    String? whatMightBeHappening,
    List<String>? whatToDoNow,
    List<String>? whatToAvoid,
    String? messageDraft,
    List<String>? followUpTasks,
    String? reflectionPrompt,
    bool? escalationFlag,
    String? safetyNote,
    DateTime? createdAt,
  }) {
    return SupportPlan(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      incidentId: incidentId ?? this.incidentId,
      summary: summary ?? this.summary,
      whatMightBeHappening: whatMightBeHappening ?? this.whatMightBeHappening,
      whatToDoNow: whatToDoNow ?? this.whatToDoNow,
      whatToAvoid: whatToAvoid ?? this.whatToAvoid,
      messageDraft: messageDraft ?? this.messageDraft,
      followUpTasks: followUpTasks ?? this.followUpTasks,
      reflectionPrompt: reflectionPrompt ?? this.reflectionPrompt,
      escalationFlag: escalationFlag ?? this.escalationFlag,
      safetyNote: safetyNote ?? this.safetyNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
