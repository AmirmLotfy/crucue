import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import 'ai_engine.dart';
import 'hybrid_gemma_engine.dart';
import 'remote_gemma4_engine.dart';

// ─── AiMode ──────────────────────────────────────────────────────────────────

/// The user's chosen AI inference mode.
///
/// - [remote] — Cloud Functions + GenAI API (full quality, online).
/// - [onDevice] — Hybrid: local Gemma 4 E2B for weekly insights when downloaded;
///   plans, chat, voice stay remote.
/// - [auto] — Same hybrid as [onDevice] on Android/iOS; otherwise remote.
enum AiMode {
  /// Cloud-first: Firebase Cloud Functions → Gemma 4 (gemma-4-26b-a4b-it).
  /// Requires network. Works on all devices. Default.
  remote,

  /// On-device / hybrid: `flutter_gemma` + Gemma 4 E2B weights for weekly insights;
  /// plans, chat, and voice stay remote. See Settings → on-device model when enabled.
  onDevice,

  /// Same hybrid engine as [onDevice] on Android/iOS; cloud-only elsewhere.
  auto,
}

extension AiModeLabel on AiMode {
  String get label {
    switch (this) {
      case AiMode.remote:
        return 'Cloud (recommended)';
      case AiMode.onDevice:
        return 'On-device';
      case AiMode.auto:
        return 'Automatic';
    }
  }

  String get description {
    switch (this) {
      case AiMode.remote:
        return 'Always use Gemma 4 via Google Cloud. Best quality, requires internet.';
      case AiMode.onDevice:
        return 'Weekly insights can run on-device (Gemma 4 E2B, private). '
            'Support plans, chat, and voice still use the cloud for quality and safety.';
      case AiMode.auto:
        return 'Same as On-device on phones: local weekly insight when the model is '
            'installed; cloud for everything else.';
    }
  }
}

// ─── AiMode persistence ───────────────────────────────────────────────────────

const _kAiModeKey = 'ai_mode_preference';

class AiModeNotifier extends StateNotifier<AiMode> {
  AiModeNotifier() : super(AiMode.remote) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kAiModeKey);
    if (stored != null) {
      state = AiMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => AiMode.remote,
      );
    }
  }

  Future<void> setMode(AiMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAiModeKey, mode.name);
  }
}

final aiModeProvider = StateNotifierProvider<AiModeNotifier, AiMode>(
  (ref) => AiModeNotifier(),
);

// ─── Smart engine selection ───────────────────────────────────────────────────

/// The active [AiEngine] for this build.
///
/// Selects [RemoteGemma4Engine] or [HybridGemmaEngine] from [AiMode].
///
/// [HybridGemmaEngine] runs weekly insights on-device when Gemma E2B weights are
/// installed (`flutter_gemma`); other AI calls use Cloud Functions.
///
/// To override in tests:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     aiEngineProvider.overrideWithValue(MockAiEngine()),
///   ],
/// );
/// ```
final aiEngineProvider = Provider<AiEngine>((ref) {
  final mode = ref.watch(aiModeProvider);

  switch (mode) {
    case AiMode.remote:
      return const RemoteGemma4Engine();

    case AiMode.onDevice:
    case AiMode.auto:
      if (FeatureFlags.onDeviceAiEnabled &&
          (Platform.isAndroid || Platform.isIOS)) {
        return const HybridGemmaEngine();
      }
      return const RemoteGemma4Engine();
  }
});
