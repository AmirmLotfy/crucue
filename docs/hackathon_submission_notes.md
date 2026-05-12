# Hackathon Submission Notes

## Submission: Gemma 4 Good Hackathon

**Project:** Crucue — Private AI Support for Caregivers  
**Primary model:** `gemma-4-26b-a4b-it` (Gemma 4, 26B Mixture-of-Experts)  
**Platform:** Flutter mobile (Android + iOS)  
**Backend:** Firebase Cloud Functions → Gemma 4 API

---

## What is implemented

### Core features (fully working)
- Care profile creation (9 relationship types: child, teenager, baby, parent, partner, sibling, friend, pet, self-care)
- Text incident logging → structured Gemma 4 support plan (summary, steps, message draft, safety note)
- Voice incident logging: record → upload → Google Cloud STT → Gemma 4 extraction → transcript review → plan
- Platform TTS plan playback (listen to the plan)
- Grounded follow-up chat (context = plan + profile + recent reflections)
- Voice input in chat (transcribe short clip → populate message)
- Reflection / check-in (did it help? what worked best? outcome rating)
- Save as routine from reflection
- Routines list and detail
- Weekly AI pattern summary and insights
- Light and dark mode
- Settings: theme mode selector + AI engine mode selector

### Architecture
- `AiEngine` abstraction layer — all AI calls route through a single typed interface
- `RemoteGemma4Engine` — active production implementation via Cloud Functions
- `HybridGemmaEngine` — routes weekly insights to `flutter_gemma` on-device when weights are installed; all other AI stays remote
- Native LiteRT-LM `MethodChannel` bridges (Android/iOS platform code) — scaffolded for future native weight delivery
- Cloud Run AI Gateway (`backend/ai-gateway/`) — full Express/TypeScript scaffold with 5 routes, AJV validation, Firebase Auth middleware, structured JSON schemas for all 5 AI operations. See `backend/ai-gateway/STATUS.md`.
- `HybridGemmaEngine` — routes **weekly insights** to **flutter_gemma** when a local model is active; all other AI stays **remote** (see `docs/edge_demo_path.md`)
- `AiMode` enum (remote / on-device / auto) — user-selectable in Settings
- Feature flags (`FeatureFlags`) — kill switches for voice, on-device AI, insights, AI routine suggestion
- Typed analytics events (`CrucueAnalytics`) — 11 events covering the full caregiving loop
- Full Crashlytics coverage via `PlatformDispatcher.instance.onError` + `runZonedGuarded`

---

## What is scaffolded but not yet active

| Feature | Status | Notes |
|---------|--------|-------|
| On-device Gemma 4 (weekly) | Partial | **flutter_gemma** path for `summarizePatterns` when weights installed; native LiteRT `MethodChannel` still stub |
| Cloud Run AI Gateway | 🔧 Scaffolded | Vertex AI client is a placeholder — Cloud Functions are active backend |
| AI routine suggestion | ✅ Callable path | `suggestRoutineFromReflection` Cloud Function + check-in → `SaveAsRoutineScreen` (flag: `FeatureFlags.aiRoutineSuggestionEnabled`) |
| GoRouter navigation | 🔧 Defined | `app/router.dart` exists; active navigation uses `navigatorKey` + `navigateTo()` |

---

## How to demonstrate Gemma 4 usage

### The primary demo flow

1. Open the app → create a care profile (e.g., "Jamie, age 7, Child")
2. Tap "Log Challenge" → add a title and one sentence of context
3. Tap "Save & Get Support Plan" — Gemma 4 generates a structured plan
4. Show the plan: summary, numbered steps, optional message draft
5. Tap the TTS button — hear the plan spoken aloud
6. Tap "Continue Chat" — have a grounded follow-up conversation
7. Navigate to "Reflect" — show the reflection screen
8. Navigate to Weekly Insights — show AI-generated pattern summary

### The voice demo (most impressive)

1. On the incident screen, tap the microphone chip
2. Speak a 30-60 second description of a difficult situation
3. Watch the processing screen: uploading → transcribing → extracting
4. Review the transcript + extracted fields (trigger, tried, desired outcome)
5. Confirm → full support plan generated from the voice note

### Settings demo

Open Settings → AI Engine to show the `AiMode` selector (Cloud / On-device / Auto). Explain **hybrid routing**: hosted Gemma 4 for plans/chat/voice; optional **on-device** path for **weekly insights only** when a small model is installed (`flutter_gemma`). Native LiteRT plugin is still a stub — see `docs/edge_demo_path.md`.

### Video script

See [`docs/hackathon_demo_script.md`](hackathon_demo_script.md) for a 2–3 minute ordering.

---

## How to present Gemma 4 usage honestly

**True claims:**
- Crucue uses Gemma 4 via Cloud Functions (default `gemma-4-26b-a4b-it`, overridable with `GEMMA4_MODEL` secret)
- The model is called server-side — API keys are never in the client
- Structured operations use `responseJsonSchema` (plans, extraction, insights, routine suggestion)
- Persona policies guide the model's tone without roleplay
- **Weekly insights** can run on a **small** Gemma via **flutter_gemma** when the user has downloaded weights; native LiteRT channels are stubs until integrated

**Avoid claiming:**
- "Full offline AI" — plans, chat, and voice still need network for hosted Gemma 4 and STT
- "27B parameters on device" — remote model is MoE (~4B active per forward pass); phone uses smaller edge weights only for the weekly path
- "LiteRT is shipping in-app" — use Gallery validation or say roadmap (see `docs/edge_demo_path.md`)

---

## Reproducibility

### Pinned toolchain (April 2026)

| Item | Source |
|------|--------|
| Dart SDK | `>=3.4.0 <4.0.0` — `pubspec.yaml` |
| Node.js | **22** — `functions/package.json` `engines` |
| `@google/genai` | **^1.50.0** — `functions/package.json` |
| Structured sampling | `functions/src/ai/genai-sampling.ts` (`topP` 0.95, `topK` 64 + per-task temperature) |

Optional A/B: set secret `GEMMA4_MODEL` to `gemma-4-31b-it` and compare Cloud Logging lines ending in `ms=...`.

### Running the demo yourself

Requirements:
1. Flutter 3.22+ environment
2. Firebase project with Firestore + Auth + Storage + Functions enabled
3. `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase project
4. `GEMMA4_API_KEY` and optional `GEMMA4_MODEL` in `functions/.env` (local) or Firebase Secrets (production)

```bash
flutter pub get
cd functions && npm install && npm run build
firebase deploy --only functions
flutter run
```

### Firebase project

The production Firebase project is **`crucueapp`** (Project Number: 696766634035). Both Android (`com.crucue.app`) and iOS (`com.crucue.app`) apps are registered. All 5 Cloud Functions are deployed on Node.js 22. The `google-services.json` and `GoogleService-Info.plist` are in the repo (platform config files, not secrets). `GEMMA4_API_KEY` is stored in Firebase Secret Manager.

---

## Judging criteria notes

| Criteria | Crucue's approach |
|----------|------------------|
| Gemma 4 usage | Central — hosted Gemma 4 for plans, chat, voice extraction, routines, and remote weekly insights; optional on-device weekly via **flutter_gemma** |
| Impact | Private caregiving support — a high-stakes, underserved use case |
| Privacy | Owner-scoped Firestore, voice deletion, hybrid weekly path, no ads |
| Production quality | Typed models, Riverpod, structured outputs, Crashlytics, analytics, dark mode, voice pipeline |
| Cactus / routing | `HybridGemmaEngine` sends only **summarizePatterns** local when model active; everything else remote |
| Honesty | Native LiteRT stub; gateway scaffolded not deployed — see `docs/edge_demo_path.md` |
