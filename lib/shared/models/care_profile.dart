import 'package:cloud_firestore/cloud_firestore.dart';

enum CareRelationship {
  child,
  parent,
  partner,
  sibling,
  familyMember;

  String get label {
    switch (this) {
      case CareRelationship.child:
        return 'Child';
      case CareRelationship.parent:
        return 'Parent';
      case CareRelationship.partner:
        return 'Partner';
      case CareRelationship.sibling:
        return 'Sibling';
      case CareRelationship.familyMember:
        return 'Family Member';
    }
  }

  String get icon {
    switch (this) {
      case CareRelationship.child:
        return 'child_fill.svg';
      case CareRelationship.parent:
        return 'parent_fill.svg';
      case CareRelationship.partner:
        return 'partner_filled.svg';
      case CareRelationship.sibling:
        return 'sibling.svg';
      case CareRelationship.familyMember:
        return 'friend_filled.svg';
    }
  }
}

class CareProfile {
  final String id;
  final String name;
  final CareRelationship relationship;
  final String? ageGroup;
  final String? supportFocus;
  final String? communicationPreferences;
  final List<String> triggers;
  final List<String> calmingStrategies;
  final List<String> routines;
  final String? healthNotes;
  final String? whatHelps;
  final String? whatToAvoid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareProfile({
    required this.id,
    required this.name,
    required this.relationship,
    this.ageGroup,
    this.supportFocus,
    this.communicationPreferences,
    this.triggers = const [],
    this.calmingStrategies = const [],
    this.routines = const [],
    this.healthNotes,
    this.whatHelps,
    this.whatToAvoid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareProfile.fromMap(Map<String, dynamic> map, {String? id}) {
    return CareProfile(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      relationship: _parseRelationship(map['relationship']),
      ageGroup: map['ageGroup'] as String?,
      supportFocus: map['supportFocus'] as String?,
      communicationPreferences: map['communicationPreferences'] as String?,
      triggers: _toStringList(map['triggers']),
      calmingStrategies: _toStringList(map['calmingStrategies']),
      routines: _toStringList(map['routines']),
      healthNotes: map['healthNotes'] as String?,
      whatHelps: map['whatHelps'] as String?,
      whatToAvoid: map['whatToAvoid'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  factory CareProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CareProfile.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship.name,
      'ageGroup': ageGroup,
      'supportFocus': supportFocus,
      'communicationPreferences': communicationPreferences,
      'triggers': triggers,
      'calmingStrategies': calmingStrategies,
      'routines': routines,
      'healthNotes': healthNotes,
      'whatHelps': whatHelps,
      'whatToAvoid': whatToAvoid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CareProfile copyWith({
    String? id,
    String? name,
    CareRelationship? relationship,
    String? ageGroup,
    String? supportFocus,
    String? communicationPreferences,
    List<String>? triggers,
    List<String>? calmingStrategies,
    List<String>? routines,
    String? healthNotes,
    String? whatHelps,
    String? whatToAvoid,
  }) {
    return CareProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      ageGroup: ageGroup ?? this.ageGroup,
      supportFocus: supportFocus ?? this.supportFocus,
      communicationPreferences:
          communicationPreferences ?? this.communicationPreferences,
      triggers: triggers ?? this.triggers,
      calmingStrategies: calmingStrategies ?? this.calmingStrategies,
      routines: routines ?? this.routines,
      healthNotes: healthNotes ?? this.healthNotes,
      whatHelps: whatHelps ?? this.whatHelps,
      whatToAvoid: whatToAvoid ?? this.whatToAvoid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static CareRelationship _parseRelationship(dynamic value) {
    if (value == null) return CareRelationship.child;
    final str = value.toString();
    return CareRelationship.values.firstWhere(
      (e) => e.name == str,
      orElse: () => CareRelationship.child,
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
