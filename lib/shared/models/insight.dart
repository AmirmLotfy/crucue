import 'package:cloud_firestore/cloud_firestore.dart';

class Insight {
  final String id;
  final String profileId;
  final DateTime weekStart;
  final String summary;
  final List<String> patterns;
  final List<String> whatWorked;
  final List<String> suggestions;
  final DateTime createdAt;

  const Insight({
    required this.id,
    required this.profileId,
    required this.weekStart,
    required this.summary,
    this.patterns = const [],
    this.whatWorked = const [],
    this.suggestions = const [],
    required this.createdAt,
  });

  factory Insight.fromMap(Map<String, dynamic> map, {String? id}) {
    return Insight(
      id: id ?? map['id'] as String? ?? '',
      profileId: map['profileId'] as String? ?? '',
      weekStart: _parseTimestamp(map['weekStart']),
      summary: map['summary'] as String? ?? '',
      patterns: _toStringList(map['patterns']),
      whatWorked: _toStringList(map['whatWorked']),
      suggestions: _toStringList(map['suggestions']),
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory Insight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Insight.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'weekStart': Timestamp.fromDate(weekStart),
      'summary': summary,
      'patterns': patterns,
      'whatWorked': whatWorked,
      'suggestions': suggestions,
      'createdAt': FieldValue.serverTimestamp(),
    };
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
