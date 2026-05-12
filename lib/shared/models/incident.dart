import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentCategory {
  behavior,
  communication,
  emotion,
  health,
  routine,
  safety,
  other;

  String get label {
    switch (this) {
      case IncidentCategory.behavior:
        return 'Behavior';
      case IncidentCategory.communication:
        return 'Communication';
      case IncidentCategory.emotion:
        return 'Emotional';
      case IncidentCategory.health:
        return 'Health';
      case IncidentCategory.routine:
        return 'Routine';
      case IncidentCategory.safety:
        return 'Safety';
      case IncidentCategory.other:
        return 'Other';
    }
  }
}

class Incident {
  final String id;
  final String profileId;
  final String title;
  final String description;
  final IncidentCategory category;
  final int intensity; // 1-5
  final List<String> tags;

  // Extended context fields
  final String? whatHappened;       // Detailed narrative beyond description
  final String? possibleTrigger;    // What may have triggered this
  final String? whatWasAlreadyTried; // What the caregiver already attempted
  final String? desiredOutcome;     // What a good resolution looks like

  // Attachment placeholders
  final String? voiceNoteRef;
  final String? imageRef;

  final DateTime createdAt;

  const Incident({
    required this.id,
    required this.profileId,
    required this.title,
    required this.description,
    required this.category,
    required this.intensity,
    this.tags = const [],
    this.whatHappened,
    this.possibleTrigger,
    this.whatWasAlreadyTried,
    this.desiredOutcome,
    this.voiceNoteRef,
    this.imageRef,
    required this.createdAt,
  });

  factory Incident.fromMap(Map<String, dynamic> map, {String? id}) {
    return Incident(
      id: id ?? map['id'] as String? ?? '',
      profileId: map['profileId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: _parseCategory(map['category']),
      intensity: map['intensity'] as int? ?? 3,
      tags: _toStringList(map['tags']),
      whatHappened: map['whatHappened'] as String?,
      possibleTrigger: map['possibleTrigger'] as String?,
      whatWasAlreadyTried: map['whatWasAlreadyTried'] as String?,
      desiredOutcome: map['desiredOutcome'] as String?,
      voiceNoteRef: map['voiceNoteRef'] as String?,
      imageRef: map['imageRef'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'title': title,
      'description': description,
      'category': category.name,
      'intensity': intensity,
      'tags': tags,
      if (whatHappened != null) 'whatHappened': whatHappened,
      if (possibleTrigger != null) 'possibleTrigger': possibleTrigger,
      if (whatWasAlreadyTried != null) 'whatWasAlreadyTried': whatWasAlreadyTried,
      if (desiredOutcome != null) 'desiredOutcome': desiredOutcome,
      if (voiceNoteRef != null) 'voiceNoteRef': voiceNoteRef,
      if (imageRef != null) 'imageRef': imageRef,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a rich context map for AI prompt injection.
  Map<String, dynamic> toAIContext() {
    return {
      'title': title,
      'description': description,
      'category': category.label,
      'intensity': intensity,
      if (whatHappened != null && whatHappened!.isNotEmpty)
        'whatHappened': whatHappened,
      if (possibleTrigger != null && possibleTrigger!.isNotEmpty)
        'possibleTrigger': possibleTrigger,
      if (whatWasAlreadyTried != null && whatWasAlreadyTried!.isNotEmpty)
        'whatWasAlreadyTried': whatWasAlreadyTried,
      if (desiredOutcome != null && desiredOutcome!.isNotEmpty)
        'desiredOutcome': desiredOutcome,
    };
  }

  static IncidentCategory _parseCategory(dynamic value) {
    if (value == null) return IncidentCategory.other;
    return IncidentCategory.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => IncidentCategory.other,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
