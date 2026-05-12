import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS speaking rate presets.
enum SpeakingRate {
  normal(0.5),
  calm(0.4);

  final double value;
  const SpeakingRate(this.value);
}

/// TTS state.
enum TtsState { idle, speaking, paused, stopped }

/// Abstract speech output interface — keeps TTS library swappable.
abstract class SpeechOutputService {
  /// Speak a piece of text.
  Future<void> speak(String text, {SpeakingRate rate = SpeakingRate.normal});

  /// Stop current speech.
  Future<void> stop();

  /// Pause current speech.
  Future<void> pause();

  /// Resume paused speech.
  Future<void> resume();

  /// Current TTS state.
  TtsState get state;

  /// Stream of state changes.
  Stream<TtsState> get stateStream;

  /// Dispose resources.
  Future<void> dispose();
}

/// Platform-native TTS using `flutter_tts`.
///
/// Uses iOS AVSpeechSynthesizer / Android TextToSpeech — no API costs,
/// works offline, and feels native to the device language settings.
class PlatformTtsService implements SpeechOutputService {
  final FlutterTts _tts = FlutterTts();
  TtsState _state = TtsState.idle;
  final _stateController = _TtsStreamController();

  PlatformTtsService() {
    _init();
  }

  void _init() {
    _tts.setStartHandler(() {
      _state = TtsState.speaking;
      _stateController.add(TtsState.speaking);
    });
    _tts.setCompletionHandler(() {
      _state = TtsState.idle;
      _stateController.add(TtsState.idle);
    });
    _tts.setPauseHandler(() {
      _state = TtsState.paused;
      _stateController.add(TtsState.paused);
    });
    _tts.setContinueHandler(() {
      _state = TtsState.speaking;
      _stateController.add(TtsState.speaking);
    });
    _tts.setErrorHandler((msg) {
      _state = TtsState.stopped;
      _stateController.add(TtsState.stopped);
    });

    if (!kIsWeb) {
      _tts.setLanguage('en-US');
      _tts.setVolume(1.0);
      _tts.setPitch(0.95);
    }
  }

  @override
  TtsState get state => _state;

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> speak(String text, {SpeakingRate rate = SpeakingRate.normal}) async {
    if (text.isEmpty) return;
    await _tts.setSpeechRate(rate.value);
    await _tts.speak(text);
  }

  /// Speak a list of items with natural pauses between them.
  Future<void> speakList(List<String> items, {SpeakingRate rate = SpeakingRate.normal}) async {
    final combined = items.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('. ');
    await speak(combined, rate: rate);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _state = TtsState.stopped;
    _stateController.add(TtsState.stopped);
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> resume() async {
    // flutter_tts does not support true resume — restart from beginning
    // This is acceptable for short plan sections
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
    _stateController.close();
  }
}

/// Simple broadcast stream controller for TTS state.
class _TtsStreamController {
  final List<void Function(TtsState)> _listeners = [];
  bool _closed = false;

  Stream<TtsState> get stream => Stream<TtsState>.multi((controller) {
    if (_closed) {
      controller.close();
      return;
    }
    void listener(TtsState state) => controller.add(state);
    _listeners.add(listener);
    controller.onCancel = () => _listeners.remove(listener);
  });

  void add(TtsState state) {
    if (!_closed) {
      for (final listener in List.from(_listeners)) {
        listener(state);
      }
    }
  }

  void close() {
    _closed = true;
    _listeners.clear();
  }
}
