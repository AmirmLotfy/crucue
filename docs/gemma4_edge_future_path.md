# Gemma 4 On-Device Strategy — LiteRT-LM / Android AICore

## Overview

Crucue's `AiEngine` interface supports two deployment modes:

1. **Remote mode** (current) — Flutter → `RemoteGemma4Engine` → Cloud Run AI Gateway / Cloud Functions → Gemma 4 (gemma-4-26b-a4b-it)
2. **On-device mode** (planned) — Flutter → `AndroidOnDeviceGemma4Engine` or `IosOnDeviceGemma4Engine` → LiteRT-LM / AICore → Gemma 4 E2B/E4B

The on-device path is a first-class design goal. It is the ultimate privacy architecture for a private caregiving app.

---

## Why On-Device Matters for Crucue

Crucue handles deeply personal data — care notes, incident descriptions, family dynamics, health context. The strongest privacy guarantee is that sensitive content never leaves the device during AI inference.

On-device Gemma 4 means:
- Care plan generation works fully offline
- No caregiving data sent to any server for inference
- Faster response times (no network round-trip)
- Lower operational cost at scale
- Aligned with privacy-sensitive caregivers caring for vulnerable family members

---

## Implementation Path

### Step 1: Native Channel Contract (DONE)

`lib/core/ai/native/on_device_channel.dart` defines the `MethodChannel` contract for:
- `isAvailable` — capability check
- `initialize(modelVariant)` — load model
- `generate(prompt, maxTokens, temperature)` — inference
- `dispose` — release model

### Step 2: Android Native Stub (DONE)

`android/app/src/main/kotlin/com/crucue/app/ai/OnDeviceAiPlugin.kt` is ready to integrate with:
- **Android AICore** (preferred): System-managed Gemma Nano on Pixel 8+ devices via `com.google.android.gms.aicore`
- **LiteRT-LM** (fallback): Runs Gemma 4 E2B or E4B GGUF weights via `google_ai_edge_litert_lm` engine

### Step 3: iOS Native Stub (DONE)

`ios/Runner/OnDeviceAiPlugin.swift` is ready to integrate with **LiteRT-LM** (TensorFlow Lite successor):
```swift
import GoogleAIEdgeLiteRT

let options = LlmInference.Options(modelPath: resolvedModelPath)
let session = try LlmInference(options: options)
let response = try session.generateResponse(inputText: prompt)
```

### Step 4: Model Delivery

**Android**: Play Asset Delivery (PAD)
```
# In app/build.gradle:
assetPacks = [":gemma4e2b_assets"]
# assetPacks/gemma4e2b_assets/src/main/assets/gemma-4-e2b-it.bin
```

**iOS**: On-Demand Resources (ODR)
```
# In Info.plist:
NSBundleResourceRequest initial install tags: ["gemma4e2b"]
# Background download on first launch or explicit trigger
```

### Step 5: Dart Engine Integration

Implement the real inference calls in `AndroidOnDeviceGemma4Engine` and `IosOnDeviceGemma4Engine` by calling `OnDeviceChannel.generate()` after building the prompt using the same `prompt-builder` logic as the Cloud Run gateway.

### Step 6: AiMode.auto Capability Detection

Update `aiEngineProvider` in `ai_engine_registry.dart` to support true auto-mode:
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

## Model Variants

| Variant | Params | Size | RAM req | Use case |
|---------|--------|------|---------|----------|
| `gemma-4-e2b-it` | 2B | ~1.5 GB | 4+ GB | Fast, mid-range Android / iPhone 13+ |
| `gemma-4-e4b-it` | 4B | ~2.5 GB | 6+ GB | Higher quality, Pixel 8+ / iPhone 15+ |

---

## Privacy Architecture

```
[On-device mode]
User input → Dart → MethodChannel → Kotlin/Swift → LiteRT-LM
                                                    ↓
                                              [On-device weights]
                                                    ↓
                                            Structured JSON output
                                                    ↓
                                      Dart → Firestore (anonymized)
```

No inference data crosses the network boundary. Only Firestore writes (user's own collection) go to the cloud.

---

## Timeline

| Milestone | Dependency |
|-----------|-----------|
| LiteRT-LM Flutter integration stable | LiteRT-LM SDK release for Flutter |
| Android AICore production rollout | Google Play Services update |
| Gemma 4 E2B GGUF weights on Play Asset Delivery | App review + asset delivery setup |
| Full offline capability | All of the above |

Estimated: 4–6 weeks of focused engineering once LiteRT-LM Flutter integration is stable.

---

## References

- [LiteRT-LM Inference Guide](https://ai.google.dev/edge/litert/models/generative_ai)
- [Android AICore documentation](https://developer.android.com/ai/aicore)
- [Gemma 4 model card](https://ai.google.dev/gemma/docs/gemma4)
- [Play Asset Delivery](https://developer.android.com/guide/playcore/asset-delivery)
