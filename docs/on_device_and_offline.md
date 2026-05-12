# On-device AI and offline scope

This document sets **honest** expectations for Crucue. It complements [`on_device_strategy.md`](on_device_strategy.md).

## Capability tiers (do not conflate)

| Tier | What it is | Typical use in Crucue |
|------|------------|------------------------|
| **Cloud** | `gemma-4-26b-a4b-it` (or `GEMMA4_MODEL`) via Cloud Functions + Google GenAI API | Support plans, chat, voice extraction, routine suggestion, weekly insights when local is off or fails |
| **On-device** | Gemma 4 **E2B** (~2.6 GB) or **E4B** LiteRT-LM weights via the community [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) plugin (not a first-party Google Flutter SDK) | **Weekly insights only** when the user downloads weights and `AiMode` is On-device or Automatic |

The **26B cloud model does not run on phones**. Marketing and in-app copy must not imply identical quality between local E2B and remote 26B.

## On-device AI (current)

- **Implemented:** `HybridGemmaEngine` + `flutter_gemma` for the weekly insight path when an E2B `.litertlm` model is installed (`Settings` → on-device model). Other AI features remain **remote** for safety and structured JSON quality.
- **Legacy stubs:** `AndroidOnDeviceGemma4Engine` / `IosOnDeviceGemma4Engine` (native `MethodChannel`) are not selected by `aiEngineProvider`; they remain as optional native-channel experiments.

## Offline

- **Partial offline (Firestore):** Cached reads/writes for owner data per Firestore SDK behavior.
- **Weekly insights offline:** Possible only with a downloaded on-device model **and** cached Firestore data for the week’s incidents/check-ins; if local inference throws (e.g. OOM), the app falls back to the `summarizePatterns` callable when online.
- **Plans, chat, voice, routine AI:** Require network today.

Distinguish **cached data offline** from **full AI offline**.
