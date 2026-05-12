import 'package:cloud_firestore/cloud_firestore.dart';

/// Processing states for the voice pipeline.
enum VoiceNoteStatus {
  /// Audio recorded locally, not yet uploaded.
  pending,

  /// Audio is being uploaded to Firebase Storage.
  uploading,

  /// Audio uploaded; waiting for Cloud Function to start.
  uploaded,

  /// Google Cloud STT is transcribing the audio.
  transcribing,

  /// Gemma 4 is extracting structured incident fields.
  extracting,

  /// Full pipeline complete — transcript + extracted incident available.
  completed,

  /// Pipeline failed at some stage.
  failed;

  bool get isProcessing =>
      this == uploading ||
      this == uploaded ||
      this == transcribing ||
      this == extracting;

  bool get isDone => this == completed || this == failed;

  String get label {
    switch (this) {
      case VoiceNoteStatus.pending:
        return 'Ready to upload';
      case VoiceNoteStatus.uploading:
        return 'Uploading…';
      case VoiceNoteStatus.uploaded:
        return 'Queued for processing';
      case VoiceNoteStatus.transcribing:
        return 'Listening to your recording…';
      case VoiceNoteStatus.extracting:
        return 'Understanding what happened…';
      case VoiceNoteStatus.completed:
        return 'Ready to review';
      case VoiceNoteStatus.failed:
        return 'Processing failed';
    }
  }
}

/// A voice note recorded by the caregiver.
///
/// Stored at: `users/{uid}/profiles/{profileId}/voiceNotes/{voiceNoteId}`
///
/// The processing pipeline:
///   1. Client uploads audio → `audioUrl` set, status = `uploaded`
///   2. `processVoiceIncident` Cloud Function runs:
///      a. Google Cloud STT → `transcript`
///      b. Gemma 4 extraction → `extractedIncident`
///      c. status = `completed`
///   3. Client reads transcript + extractedIncident, shows review screen
///   4. User confirms → Incident created in Firestore, `incidentId` linked
class VoiceNote {
  final String id;
  final String profileId;
  final String userId;

  /// Firebase Storage download URL for the raw audio file.
  final String? audioUrl;

  /// Firebase Storage path (for deletion).
  final String? storagePath;

  /// Recording duration in milliseconds.
  final int durationMs;

  /// Raw transcript from Google Cloud Speech-to-Text.
  final String? transcript;

  /// Current stage of the voice processing pipeline.
  final VoiceNoteStatus status;

  /// Error message if status == failed.
  final String? errorMessage;

  /// Linked incident ID, set after the user confirms and saves.
  final String? incidentId;

  /// Structured incident data extracted by Gemma 4 from the transcript.
  final Map<String, dynamic>? extractedIncident;

  /// Whether the safety engine flagged concerning content.
  final bool safetyFlag;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const VoiceNote({
    required this.id,
    required this.profileId,
    required this.userId,
    this.audioUrl,
    this.storagePath,
    this.durationMs = 0,
    this.transcript,
    this.status = VoiceNoteStatus.pending,
    this.errorMessage,
    this.incidentId,
    this.extractedIncident,
    this.safetyFlag = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory VoiceNote.fromMap(Map<String, dynamic> map, {String? id}) {
    return VoiceNote(
      id: id ?? map['id'] as String? ?? '',
      profileId: map['profileId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      audioUrl: map['audioUrl'] as String?,
      storagePath: map['storagePath'] as String?,
      durationMs: map['durationMs'] as int? ?? 0,
      transcript: map['transcript'] as String?,
      status: _parseStatus(map['status']),
      errorMessage: map['errorMessage'] as String?,
      incidentId: map['incidentId'] as String?,
      extractedIncident: map['extractedIncident'] as Map<String, dynamic>?,
      safetyFlag: map['safetyFlag'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? _parseTimestamp(map['updatedAt'])
          : null,
    );
  }

  factory VoiceNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoiceNote.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'userId': userId,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (storagePath != null) 'storagePath': storagePath,
      'durationMs': durationMs,
      if (transcript != null) 'transcript': transcript,
      'status': status.name,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (incidentId != null) 'incidentId': incidentId,
      if (extractedIncident != null) 'extractedIncident': extractedIncident,
      'safetyFlag': safetyFlag,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  VoiceNote copyWith({
    String? audioUrl,
    String? storagePath,
    int? durationMs,
    String? transcript,
    VoiceNoteStatus? status,
    String? errorMessage,
    String? incidentId,
    Map<String, dynamic>? extractedIncident,
    bool? safetyFlag,
  }) {
    return VoiceNote(
      id: id,
      profileId: profileId,
      userId: userId,
      audioUrl: audioUrl ?? this.audioUrl,
      storagePath: storagePath ?? this.storagePath,
      durationMs: durationMs ?? this.durationMs,
      transcript: transcript ?? this.transcript,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      incidentId: incidentId ?? this.incidentId,
      extractedIncident: extractedIncident ?? this.extractedIncident,
      safetyFlag: safetyFlag ?? this.safetyFlag,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static VoiceNoteStatus _parseStatus(dynamic value) {
    if (value == null) return VoiceNoteStatus.pending;
    return VoiceNoteStatus.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => VoiceNoteStatus.pending,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
