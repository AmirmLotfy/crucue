import 'package:flutter/services.dart';

/// MethodChannel contract for native on-device AI inference.
///
/// Communicates with the native platform adapters:
/// - Android: OnDeviceAiPlugin.kt (AICore / LiteRT-LM roadmap)
/// - iOS:     OnDeviceAiPlugin.swift (LiteRT-LM roadmap)
///
/// Currently used by [HybridGemmaEngine] for the `isAvailable()` check only.
/// Full inference is handled by [HybridGemmaEngine] + `flutter_gemma` at the
/// Dart layer. Native LiteRT-LM inference is scaffolded for a future release.
///
/// ## Channel methods
///
/// | Method | Input map | Output |
/// |--------|-----------|--------|
/// | `isAvailable` | — | `bool` |
/// | `initialize` | `{modelVariant: String}` | `void` |
/// | `generate` | `{prompt: String, maxTokens: int, temperature: double}` | `String` |
/// | `dispose` | — | `void` |
///
/// ## Model variants
///
/// Pass one of:
/// - `"gemma-4-e2b-it"` — 2B on-device, fast (Android AICore default)
/// - `"gemma-4-e4b-it"` — 4B on-device, higher quality
///
/// The native layer resolves the variant to the correct LiteRT-LM / AICore
/// model asset path.
class OnDeviceChannel {
  OnDeviceChannel._();

  static const MethodChannel _channel =
      MethodChannel('com.crucue.app/on_device_ai');

  /// Returns `true` if the device supports on-device Gemma 4 inference.
  ///
  /// Android: checks Android AICore availability and RAM (>= 4 GB).
  /// iOS: checks LiteRT-LM support and RAM (>= 3 GB).
  static Future<bool> isAvailable() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
      return result;
    } on PlatformException {
      return false;
    }
  }

  /// Initializes the on-device model.
  ///
  /// [modelVariant] — one of `"gemma-4-e2b-it"` or `"gemma-4-e4b-it"`.
  ///
  /// Throws [OnDeviceAiException] if model weights are not available on the
  /// device (must be downloaded via asset delivery or background fetch first).
  static Future<void> initialize({
    required String modelVariant,
  }) async {
    try {
      await _channel.invokeMethod<void>('initialize', {
        'modelVariant': modelVariant,
      });
    } on PlatformException catch (e) {
      throw OnDeviceAiException(
        'Failed to initialize on-device model ($modelVariant): ${e.message}',
        code: e.code,
      );
    }
  }

  /// Generates a text response from the on-device model.
  ///
  /// [prompt] — the full prompt string (system + user combined).
  /// [maxTokens] — maximum tokens to generate (default 512).
  /// [temperature] — sampling temperature 0.0–1.0 (default 0.4).
  ///
  /// Throws [OnDeviceAiException] if the model is not initialized or
  /// generation fails.
  static Future<String> generate({
    required String prompt,
    int maxTokens = 512,
    double temperature = 0.4,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw OnDeviceAiException(
        'On-device generation failed: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Releases the native model from memory.
  static Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException {
      // Ignore — dispose is best-effort.
    }
  }
}

/// Exception thrown by [OnDeviceChannel] when native AI operations fail.
class OnDeviceAiException implements Exception {
  final String message;
  final String? code;

  const OnDeviceAiException(this.message, {this.code});

  @override
  String toString() =>
      code != null ? 'OnDeviceAiException[$code]: $message' : 'OnDeviceAiException: $message';
}
