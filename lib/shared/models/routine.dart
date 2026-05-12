import 'package:cloud_firestore/cloud_firestore.dart';

enum RoutineFrequency {
  daily,
  weekdays,
  weekends,
  weekly,
  asNeeded;

  String get label {
    switch (this) {
      case RoutineFrequency.daily:
        return 'Every day';
      case RoutineFrequency.weekdays:
        return 'Weekdays';
      case RoutineFrequency.weekends:
        return 'Weekends';
      case RoutineFrequency.weekly:
        return 'Weekly';
      case RoutineFrequency.asNeeded:
        return 'As needed';
    }
  }
}

class Routine {
  final String id;
  final String profileId;
  final String title;
  final String? description;
  final RoutineFrequency frequency;
  final String? timeOfDay;
  final List<String> steps;
  final bool isActive;
  final DateTime createdAt;

  // Extended fields
  final String? basedOnPlanId;
  final String? basedOnIncidentId;
  final List<String> tags;
  final DateTime? lastUsedAt;
  final List<String> reminders;
  final int completionCount;

  const Routine({
    required this.id,
    required this.profileId,
    required this.title,
    this.description,
    this.frequency = RoutineFrequency.daily,
    this.timeOfDay,
    this.steps = const [],
    this.isActive = true,
    required this.createdAt,
    this.basedOnPlanId,
    this.basedOnIncidentId,
    this.tags = const [],
    this.lastUsedAt,
    this.reminders = const [],
    this.completionCount = 0,
  });

  factory Routine.fromMap(Map<String, dynamic> map, {String? id}) {
    return Routine(
      id: id ?? map['id'] as String? ?? '',
      profileId: map['profileId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      frequency: _parseFrequency(map['frequency']),
      timeOfDay: map['timeOfDay'] as String?,
      steps: _toStringList(map['steps']),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      basedOnPlanId: map['basedOnPlanId'] as String?,
      basedOnIncidentId: map['basedOnIncidentId'] as String?,
      tags: _toStringList(map['tags']),
      lastUsedAt: map['lastUsedAt'] != null
          ? _parseTimestamp(map['lastUsedAt'])
          : null,
      reminders: _toStringList(map['reminders']),
      completionCount: map['completionCount'] as int? ?? 0,
    );
  }

  factory Routine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Routine.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'title': title,
      'description': description,
      'frequency': frequency.name,
      'timeOfDay': timeOfDay,
      'steps': steps,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      if (basedOnPlanId != null) 'basedOnPlanId': basedOnPlanId,
      if (basedOnIncidentId != null) 'basedOnIncidentId': basedOnIncidentId,
      'tags': tags,
      if (lastUsedAt != null)
        'lastUsedAt': Timestamp.fromDate(lastUsedAt!),
      'reminders': reminders,
      'completionCount': completionCount,
    };
  }

  Routine copyWith({
    String? title,
    String? description,
    RoutineFrequency? frequency,
    String? timeOfDay,
    List<String>? steps,
    bool? isActive,
    List<String>? tags,
    DateTime? lastUsedAt,
    List<String>? reminders,
    int? completionCount,
  }) {
    return Routine(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      steps: steps ?? this.steps,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      basedOnPlanId: basedOnPlanId,
      basedOnIncidentId: basedOnIncidentId,
      tags: tags ?? this.tags,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      reminders: reminders ?? this.reminders,
      completionCount: completionCount ?? this.completionCount,
    );
  }

  static RoutineFrequency _parseFrequency(dynamic value) {
    return frequencyFromApi(value?.toString());
  }

  /// Maps Cloud Function / API strings (e.g. `as-needed`) to [RoutineFrequency].
  static RoutineFrequency frequencyFromApi(String? raw) {
    if (raw == null || raw.isEmpty) return RoutineFrequency.daily;
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'weekdays':
        return RoutineFrequency.weekdays;
      case 'weekends':
        return RoutineFrequency.weekends;
      case 'weekly':
        return RoutineFrequency.weekly;
      case 'as-needed':
      case 'asneeded':
        return RoutineFrequency.asNeeded;
      case 'daily':
      default:
        if (s == RoutineFrequency.daily.name) return RoutineFrequency.daily;
        return RoutineFrequency.daily;
    }
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
