# On-device / edge demo path (hackathon alignment)

This document fixes **one** coherent story for judges: what runs **offline**, what runs **online**, and how we validate **Gemma 4 on edge** without overstating shipping code.

## Production reality (Crucue today)

| Path | Runtime | Models | Status |
|------|---------|--------|--------|
| **Remote AI** | Firebase Callable → `@google/genai` | `GEMMA4_MODEL` (default `gemma-4-26b-a4b-it`) | **Shipped** — all plans, chat, voice extraction, weekly insights when not using local |
| **Hybrid weekly insights** | [`HybridGemmaEngine`](../lib/core/ai/hybrid_gemma_engine.dart) | Small Gemma via **flutter_gemma** when user downloaded weights | **Shipped when** `FeatureFlags.localWeeklyInsightWithFlutterGemma` + active local model |
| **Native MethodChannel** | [`OnDeviceAiPlugin.kt`](../android/app/src/main/kotlin/com/crucue/app/ai/OnDeviceAiPlugin.kt) / iOS counterpart | LiteRT-LM / AICore (planned) | **Stub** — `isAvailable` false until integrated |

## Chosen demo strategy (recommended for Kaggle / Gemma 4 Good)

1. **Lead the video with remote Gemma 4** — the full caregiving loop (voice → plan → chat → reflection) uses the **hosted** instruction-tuned model and structured JSON. This is the strongest, honest demo.
2. **Show hybrid routing in Settings + Weekly Insights** — when `flutter_gemma` has an E2B-class model installed, **only** `summarizePatterns` can run locally; everything else stays on Cloud Functions. That is the **Cactus** “route tasks between models” story.
3. **LiteRT / Google AI Edge** — For **LiteRT prize** credibility without faking app integration:
   - **Short term:** Run **[Google AI Edge Gallery](https://github.com/google-ai-edge)** on a physical device, load **Gemma 4 E2B or E4B**, and note latency/thermal in the writeup or appendix. This proves the **edge stack** on real hardware.
   - **Medium term:** Replace or augment the native stub with **LiteRT-LM** Android SDK (see [LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM)) wired to `OnDeviceAiPlugin`, then optionally converge weekly insights on that path.

## What not to claim

- Full **offline** parity with the cloud **26B** model — not possible on phones.
- **LiteRT** inside Crucue without code — use Gallery validation or say “roadmap.”
- **Ollama** unless you explicitly add it — not part of this repo.

## Related docs

- [`on_device_and_offline.md`](on_device_and_offline.md) — capability tiers
- [`on_device_strategy.md`](on_device_strategy.md) — native channel architecture
- [`gemma4_edge_future_path.md`](gemma4_edge_future_path.md) — LiteRT-LM / AICore direction
