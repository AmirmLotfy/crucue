# On-Device AI Strategy

## Status: Scaffolded, not yet active

The on-device AI path in Crucue is architecturally complete but not operationally active. Native platform channels are defined, Android and iOS plugins are written, and the `AiEngine` interface accommodates on-device engines. What is missing is model weight delivery — the mechanism to get the Gemma 4 E2B/E4B weights onto the device.

---

## Why on-device matters

Crucue handles sensitive care data. The strongest privacy guarantee possible is that **care data never leaves the device during AI inference**. Remote inference necessarily sends a summary of the incident and profile context to Google Cloud. On-device inference sends nothing.

For caregivers with high privacy sensitivity — caring for vulnerable adults, managing confidential medical situations, or simply uncomfortable with cloud AI — on-device mode is the right answer.

**Additional benefits:**
- Offline capability — plan generation without network access
- Lower latency for short plans (no round-trip)
- Zero marginal AI inference cost at scale

---

## Architecture

```
Flutter AiEngine interface
        │
        ├── [AiMode.remote]  → RemoteGemma4Engine → Cloud Functions → Gemma 4 API
        │
        └── [AiMode.onDevice]
              ├── Android → AndroidOnDeviceGemma4Engine
              │     └── OnDeviceChannel (MethodChannel: "com.crucue.app/on_device_ai")
              │           └── OnDeviceAiPlugin.kt
              │                 ├── Android AICore (Pixel 8+, system Gemma Nano)
              │                 └── LiteRT-LM (GGUF weights, Play Asset Delivery)
              │
              └── iOS → IosOnDeviceGemma4Engine
                    └── OnDeviceChannel (same MethodChannel)
                          └── OnDeviceAiPlugin.swift
                                └── LiteRT-LM (GGUF weights, On-Demand Resources)
```

---

## Supported devices

### Android

| Variant | Params | Min RAM | Min API | Path |
|---------|--------|---------|---------|------|
| `gemma-4-e2b-it` | 2B | 4 GB | Android 10 | AICore (Pixel 8+) or LiteRT-LM |
| `gemma-4-e4b-it` | 4B | 6 GB | Android 11 | LiteRT-LM only |

**Android AICore** (preferred for Pixel 8 and later): System-managed inference via `com.google.android.gms.aicore`. The OS manages model weights — no download required by the app.

**LiteRT-LM** (fallback, works on any compatible device): The app delivers model weights via Play Asset Delivery. Device must meet RAM requirements.

### iOS

| Variant | Min Device | Notes |
|---------|------------|-------|
| `gemma-4-e2b-it` | iPhone 12 | A14 Bionic, 4 GB RAM |
| `gemma-4-e4b-it` | iPhone 15 | A16 Bionic, 8 GB RAM |

iOS uses LiteRT-LM via On-Demand Resources. No equivalent of AICore exists on iOS.

---

## MethodChannel contract

Channel: `com.crucue.app/on_device_ai`

| Method | Arguments | Returns | Status |
|--------|-----------|---------|--------|
| `isAvailable` | — | `bool` | Implemented (returns `false` until weights configured) |
| `initialize` | `{modelVariant: String}` | void | Stub (returns `MODEL_NOT_FOUND`) |
| `generate` | `{prompt, maxTokens, temperature}` | `String` | Stub (returns `NOT_INITIALIZED`) |
| `dispose` | — | void | Implemented |

---

## Current stub behavior

Both `OnDeviceAiPlugin.kt` (Android) and `OnDeviceAiPlugin.swift` (iOS) are written and registered in the native app. They return:
- `isAvailable` → `false`
- `initialize` → error code `MODEL_NOT_FOUND`
- `generate` → error code `NOT_INITIALIZED`

When a user selects `AiMode.onDevice` in Settings, the respective `AndroidOnDeviceGemma4Engine` or `IosOnDeviceGemma4Engine` is instantiated. All method calls throw `UnimplementedError` with a message explaining that model weights are not yet delivered.

The `AiMode.auto` setting currently behaves the same as `AiMode.remote` — automatic capability detection is planned but not yet implemented.

---

## Why this is "hybrid, not fake offline everywhere"

Some AI apps claim offline capability without being honest about device requirements. Crucue does not.

The `FeatureFlags.onDeviceAiEnabled` is set to `false` in production. This means:
- The AI engine mode selector shows on-device options
- A user can select on-device mode
- The engine correctly throws an error when model weights are absent
- The `AiMode.auto` setting falls back to remote rather than silently failing

When a user explicitly selects `AiMode.onDevice` and the model is not available, the error surfaces. We do not silently fall back to remote without the user's knowledge — that would defeat the privacy purpose of on-device mode.

---

## Integration path (when ready)

### Android (Play Asset Delivery)

1. Create an asset pack in `assetPacks/gemma4e2b_assets/`:
   ```
   assetPacks/
     gemma4e2b_assets/
       src/main/assets/
         gemma-4-e2b-it.bin    (GGUF model weights)
   ```

2. Update `android/app/build.gradle`:
   ```gradle
   assetPacks = [":gemma4e2b_assets"]
   ```

3. In `OnDeviceAiPlugin.kt.handleInitialize()`:
   ```kotlin
   val assetManager = context.assets
   val modelPath = resolveModelPath(modelVariant)
   val options = LlmInference.Options.builder()
     .setModelPath(modelPath)
     .build()
   session = LlmInference.createFromOptions(context, options)
   isModelLoaded = true
   result.success(null)
   ```

### iOS (On-Demand Resources)

1. Add model weights as on-demand resources in Xcode with tag `gemma4e2b`

2. In `OnDeviceAiPlugin.swift.handleInitialize()`:
   ```swift
   let resourceRequest = NSBundleResourceRequest(tags: ["gemma4e2b"])
   resourceRequest.beginAccessingResources { error in
     guard error == nil else { /* handle */ return }
     let modelPath = Bundle.main.path(forResource: "gemma-4-e2b-it", ofType: "bin")
     let options = LlmInference.Options(modelPath: modelPath!)
     self.session = try LlmInference(options: options)
     self.isModelLoaded = true
     result(nil)
   }
   ```

### AiMode.auto capability detection

Update `aiEngineProvider` in `lib/core/ai/ai_engine_registry.dart`:
```dart
case AiMode.auto:
  final available = await OnDeviceChannel.isAvailable();
  if (available) {
    if (Platform.isAndroid) return AndroidOnDeviceGemma4Engine();
    if (Platform.isIOS) return IosOnDeviceGemma4Engine();
  }
  return const RemoteGemma4Engine();
```

---

## References

- [LiteRT-LM Inference Guide](https://ai.google.dev/edge/litert/models/generative_ai)
- [Android AICore documentation](https://developer.android.com/ai/aicore)
- [Gemma 4 model card](https://ai.google.dev/gemma/docs/gemma4)
- [Play Asset Delivery](https://developer.android.com/guide/playcore/asset-delivery)
