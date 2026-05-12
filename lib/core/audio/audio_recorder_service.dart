import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Recording state exposed to the UI.
enum RecordingState { idle, recording, paused, stopped }

/// Abstract audio recorder interface — keeps the UI decoupled from the
/// concrete recording library and enables future edge/on-device swap.
abstract class AudioRecorderService {
  /// Maximum allowed recording duration.
  static const maxDuration = Duration(minutes: 3);

  /// Whether the microphone permission is granted.
  Future<bool> hasMicrophonePermission();

  /// Request microphone permission. Returns true if granted.
  Future<bool> requestMicrophonePermission();

  /// Start recording. Returns the local file path where audio is saved.
  Future<String> startRecording();

  /// Stop recording and return the completed file path.
  Future<String?> stopRecording();

  /// Pause the current recording.
  Future<void> pauseRecording();

  /// Resume a paused recording.
  Future<void> resumeRecording();

  /// Cancel and discard the current recording.
  Future<void> cancelRecording();

  /// Current duration of the recording in progress.
  Stream<Duration> get durationStream;

  /// Current recording state.
  RecordingState get state;

  /// Dispose resources.
  Future<void> dispose();
}

/// Concrete implementation using the `record` package.
///
/// Records in M4A (AAC) format for broad compatibility with
/// Google Cloud Speech-to-Text.
class RecordAudioService implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  String? _currentPath;

  @override
  RecordingState get state => _state;

  @override
  Future<bool> hasMicrophonePermission() async {
    if (kIsWeb) return true;
    return await _recorder.hasPermission();
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<String> startRecording() async {
    if (!await hasMicrophonePermission()) {
      final granted = await requestMicrophonePermission();
      if (!granted) throw Exception('Microphone permission denied');
    }

    final dir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/crucue_voice_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000, // Optimal for Google STT
        numChannels: 1,    // Mono is sufficient and smaller
      ),
      path: _currentPath!,
    );

    _state = RecordingState.recording;
    return _currentPath!;
  }

  @override
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _state = RecordingState.stopped;
    _currentPath = path;
    return path;
  }

  @override
  Future<void> pauseRecording() async {
    await _recorder.pause();
    _state = RecordingState.paused;
  }

  @override
  Future<void> resumeRecording() async {
    await _recorder.resume();
    _state = RecordingState.recording;
  }

  @override
  Future<void> cancelRecording() async {
    await _recorder.stop();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (file.existsSync()) file.deleteSync();
    }
    _state = RecordingState.idle;
    _currentPath = null;
  }

  @override
  Stream<Duration> get durationStream => _recorder.onStateChanged().map(
        (event) => const Duration(), // amplitude stream not needed
      );

  /// Returns a stream of amplitude values (0.0–1.0) for waveform display.
  Stream<double> get amplitudeStream => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 100))
      .map((amp) => ((amp.current + 60) / 60).clamp(0.0, 1.0));

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
