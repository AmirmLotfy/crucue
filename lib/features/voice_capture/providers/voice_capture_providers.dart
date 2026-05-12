import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_recorder_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/voice_note.dart';

// ─── Recorder singleton ────────────────────────────────────────────────────

final audioRecorderProvider = Provider<AudioRecorderService>(
  (ref) {
    final service = RecordAudioService();
    ref.onDispose(() => service.dispose());
    return service;
  },
);

// ─── Recording state ──────────────────────────────────────────────────────

class VoiceRecordingState {
  final RecordingState recordingState;
  final Duration elapsed;
  final String? recordedFilePath;
  final bool isUploading;
  final String? errorMessage;

  const VoiceRecordingState({
    this.recordingState = RecordingState.idle,
    this.elapsed = Duration.zero,
    this.recordedFilePath,
    this.isUploading = false,
    this.errorMessage,
  });

  VoiceRecordingState copyWith({
    RecordingState? recordingState,
    Duration? elapsed,
    String? recordedFilePath,
    bool? isUploading,
    String? errorMessage,
  }) {
    return VoiceRecordingState(
      recordingState: recordingState ?? this.recordingState,
      elapsed: elapsed ?? this.elapsed,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage,
    );
  }

  bool get isRecording => recordingState == RecordingState.recording;
  bool get isPaused => recordingState == RecordingState.paused;
  bool get hasStopped => recordingState == RecordingState.stopped;
  bool get isIdle => recordingState == RecordingState.idle;
  bool get hasRecording => recordedFilePath != null;
}

class VoiceRecordingNotifier extends StateNotifier<VoiceRecordingState> {
  final AudioRecorderService _recorder;
  Timer? _timer;
  static const maxDuration = Duration(minutes: 3);

  VoiceRecordingNotifier(this._recorder)
      : super(const VoiceRecordingState());

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> checkPermission() async {
    return _recorder.hasMicrophonePermission();
  }

  Future<bool> requestPermission() async {
    return _recorder.requestMicrophonePermission();
  }

  Future<void> startRecording() async {
    state = const VoiceRecordingState(recordingState: RecordingState.recording);
    try {
      final path = await _recorder.startRecording();
      _startTimer();
      state = state.copyWith(
        recordingState: RecordingState.recording,
        recordedFilePath: path,
      );
    } catch (e) {
      state = VoiceRecordingState(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stopRecording();
    state = state.copyWith(
      recordingState: RecordingState.stopped,
      recordedFilePath: path,
    );
  }

  Future<void> pauseRecording() async {
    _timer?.cancel();
    await _recorder.pauseRecording();
    state = state.copyWith(recordingState: RecordingState.paused);
  }

  Future<void> resumeRecording() async {
    await _recorder.resumeRecording();
    _startTimer();
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  Future<void> cancelRecording() async {
    _timer?.cancel();
    await _recorder.cancelRecording();
    state = const VoiceRecordingState();
  }

  void reset() {
    _timer?.cancel();
    state = const VoiceRecordingState();
  }

  /// Upload the recorded audio and create a VoiceNote in Firestore.
  /// Returns the VoiceNote ID.
  Future<String?> uploadAndCreateVoiceNote({
    required String profileId,
  }) async {
    if (state.recordedFilePath == null) return null;

    state = state.copyWith(isUploading: true);

    try {
      final uid = AuthService.currentUid;
      if (uid == null) throw Exception('Not authenticated');
      final file = File(state.recordedFilePath!);

      // Create a placeholder VoiceNote first to get the ID
      final voiceNote = VoiceNote(
        id: '',
        profileId: profileId,
        userId: uid,
        durationMs: state.elapsed.inMilliseconds,
        status: VoiceNoteStatus.uploading,
        createdAt: DateTime.now(),
      );
      final voiceNoteId =
          await FirestoreService.createVoiceNote(profileId, voiceNote);

      // Upload audio to Storage
      final uploaded = await StorageService.uploadVoiceNoteForProfile(
        file: file,
        profileId: profileId,
        voiceNoteId: voiceNoteId,
      );

      // Update VoiceNote with URL and status
      await FirestoreService.updateVoiceNote(profileId, voiceNoteId, {
        'audioUrl': uploaded.url,
        'storagePath': uploaded.path,
        'status': VoiceNoteStatus.uploaded.name,
      });

      // Clean up local file
      try {
        file.deleteSync();
      } catch (_) {}

      state = state.copyWith(isUploading: false);
      return voiceNoteId;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Upload failed. Please try again.',
      );
      return null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed = state.elapsed + const Duration(seconds: 1);
      if (newElapsed >= maxDuration) {
        stopRecording();
      } else {
        state = state.copyWith(elapsed: newElapsed);
      }
    });
  }
}

final voiceRecordingProvider =
    StateNotifierProvider.autoDispose<VoiceRecordingNotifier, VoiceRecordingState>(
  (ref) {
    final recorder = ref.watch(audioRecorderProvider);
    return VoiceRecordingNotifier(recorder);
  },
);

// ─── Amplitude stream for waveform ────────────────────────────────────────

final amplitudeStreamProvider = StreamProvider.autoDispose<double>((ref) {
  final recorder = ref.watch(audioRecorderProvider);
  if (recorder is RecordAudioService) {
    return recorder.amplitudeStream;
  }
  return const Stream.empty();
});
