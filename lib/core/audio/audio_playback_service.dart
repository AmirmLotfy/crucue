import 'package:just_audio/just_audio.dart';

/// Playback state wrapper.
enum AudioPlaybackState { idle, loading, playing, paused, completed, error }

/// Service for playing back recorded voice notes.
///
/// Used to let caregivers review their recording before uploading.
class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  AudioPlaybackState _state = AudioPlaybackState.idle;

  Stream<AudioPlaybackState> get stateStream => _player.playerStateStream.map(
        (ps) {
          if (ps.processingState == ProcessingState.loading ||
              ps.processingState == ProcessingState.buffering) {
            return AudioPlaybackState.loading;
          }
          if (ps.processingState == ProcessingState.completed) {
            return AudioPlaybackState.completed;
          }
          if (ps.playing) return AudioPlaybackState.playing;
          if (ps.processingState == ProcessingState.idle) {
            return AudioPlaybackState.idle;
          }
          return AudioPlaybackState.paused;
        },
      );

  AudioPlaybackState get state => _state;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> loadFromPath(String filePath) async {
    _state = AudioPlaybackState.loading;
    await _player.setFilePath(filePath);
    _state = AudioPlaybackState.idle;
  }

  Future<void> loadFromUrl(String url) async {
    _state = AudioPlaybackState.loading;
    await _player.setUrl(url);
    _state = AudioPlaybackState.idle;
  }

  Future<void> play() async {
    await _player.play();
    _state = AudioPlaybackState.playing;
  }

  Future<void> pause() async {
    await _player.pause();
    _state = AudioPlaybackState.paused;
  }

  Future<void> stop() async {
    await _player.stop();
    _state = AudioPlaybackState.idle;
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
