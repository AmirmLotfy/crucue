import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'speech_output_service.dart';

final speechOutputProvider = Provider<SpeechOutputService>((ref) {
  final service = PlatformTtsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Lightweight state for the TTS playback button.
class TtsPlaybackState {
  final TtsState ttsState;
  final String? currentSection;

  const TtsPlaybackState({
    this.ttsState = TtsState.idle,
    this.currentSection,
  });

  bool get isPlaying => ttsState == TtsState.speaking;
  bool get isStopped => ttsState == TtsState.idle || ttsState == TtsState.stopped;

  TtsPlaybackState copyWith({TtsState? ttsState, String? currentSection}) {
    return TtsPlaybackState(
      ttsState: ttsState ?? this.ttsState,
      currentSection: currentSection ?? this.currentSection,
    );
  }
}

class TtsPlaybackNotifier extends StateNotifier<TtsPlaybackState> {
  final SpeechOutputService _tts;

  TtsPlaybackNotifier(this._tts) : super(const TtsPlaybackState()) {
    _tts.stateStream.listen((s) {
      state = state.copyWith(ttsState: s);
    });
  }

  Future<void> speakText(String text, {String? sectionLabel, SpeakingRate rate = SpeakingRate.normal}) async {
    if (state.isPlaying) {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    state = TtsPlaybackState(ttsState: TtsState.speaking, currentSection: sectionLabel);
    await _tts.speak(text, rate: rate);
  }

  Future<void> speakList(List<String> items, {String? sectionLabel, SpeakingRate rate = SpeakingRate.normal}) async {
    if (state.isPlaying) {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    state = TtsPlaybackState(ttsState: TtsState.speaking, currentSection: sectionLabel);
    await (_tts as PlatformTtsService).speakList(items, rate: rate);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = const TtsPlaybackState();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

final ttsPlaybackProvider =
    StateNotifierProvider.autoDispose<TtsPlaybackNotifier, TtsPlaybackState>((ref) {
  final tts = ref.watch(speechOutputProvider);
  return TtsPlaybackNotifier(tts);
});
