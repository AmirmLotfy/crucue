import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  final String id;
  final String profileId;
  final String planId;
  final bool didThisHelp;
  final String? notes;
  final String? moodOutcome;
  final List<String> stepsCompleted;
  final DateTime createdAt;

  // Extended reflection fields
  final List<String> stepsHelpedMost;   // Which specific steps made the biggest difference
  final String? whatMadeItWorse;        // What made the situation harder
  final bool shouldBecomeRoutine;       // Flag to convert this plan into a reusable routine
  final int outcomeRating;              // 1-5 how well the overall situation resolved

  const CheckIn({
    required this.id,
    required this.profileId,
    required this.planId,
    required this.didThisHelp,
    this.notes,
    this.moodOutcome,
    this.stepsCompleted = const [],
    required this.createdAt,
    this.stepsHelpedMost = const [],
    this.whatMadeItWorse,
    this.shouldBecomeRoutine = false,
    this.outcomeRating = 3,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map, {String? id}) {
    return CheckIn(
      id: id ?? map['id'] as String? ?? '',
      profileId: map['profileId'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      didThisHelp: map['didThisHelp'] as bool? ?? false,
      notes: map['notes'] as String?,
      moodOutcome: map['moodOutcome'] as String?,
      stepsCompleted: _toStringList(map['stepsCompleted']),
      createdAt: _parseTimestamp(map['createdAt']),
      stepsHelpedMost: _toStringList(map['stepsHelpedMost']),
      whatMadeItWorse: map['whatMadeItWorse'] as String?,
      shouldBecomeRoutine: map['shouldBecomeRoutine'] as bool? ?? false,
      outcomeRating: map['outcomeRating'] as int? ?? 3,
    );
  }

  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckIn.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'planId': planId,
      'didThisHelp': didThisHelp,
      'notes': notes,
      'moodOutcome': moodOutcome,
      'stepsCompleted': stepsCompleted,
      'stepsHelpedMost': stepsHelpedMost,
      if (whatMadeItWorse != null) 'whatMadeItWorse': whatMadeItWorse,
      'shouldBecomeRoutine': shouldBecomeRoutine,
      'outcomeRating': outcomeRating,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a compact summary for AI context injection.
  Map<String, dynamic> toAIContext() {
    return {
      'didHelp': didThisHelp,
      'outcomeRating': outcomeRating,
      if (stepsHelpedMost.isNotEmpty) 'whatWorked': stepsHelpedMost,
      if (whatMadeItWorse != null && whatMadeItWorse!.isNotEmpty)
        'whatMadeItWorse': whatMadeItWorse,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
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
