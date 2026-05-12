# Kaggle Writeup — Truthful Draft

**Repo audit basis:** All claims below are verified against the actual code and deployment state as of April 2026.

---

## Audit Evidence Summary

Before writing, the following was verified in the codebase and against the live Firebase project:


| Item                    | Reality                                                                                                                                                                 |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AI SDK                  | `@google/genai` v1.50.0 — Google's current unified SDK (replaced deprecated `@google/generative-ai`)                                                                    |
| Model called            | `gemma-4-26b-a4b-it` via Google AI Studio API                                                                                                                           |
| Structured output       | `responseMimeType: "application/json"` + `responseJsonSchema: SUPPORT_PLAN_SCHEMA` — properly typed, no `@ts-ignore` needed                                             |
| Cloud Functions runtime | Node.js 22 (Gen 2, us-central1)                                                                                                                                         |
| Firebase project        | `crucueapp` — both Android + iOS apps registered, all 5 functions deployed                                                                                              |
| Secrets                 | `GEMMA4_API_KEY` and `GEMMA4_MODEL` in Firebase Secret Manager                                                                                                          |
| Voice pipeline          | Flutter recording (`record`) + Google Cloud STT (REST API) + Gemma 4 extraction — full pipeline in code and deployed                                                    |
| Voice Flutter screens   | `VoiceRecordingSheet`, `VoiceProcessingScreen`, `TranscriptReviewScreen` — all implemented                                                                              |
| TTS                     | `flutter_tts` wired via `PlatformTtsService`; `_TtsAppBarButton` in `ResultsView` calls `speakText()`                                                                   |
| Dark mode               | `darkTheme: AppTheme.dark` and `themeMode` wired in `main.dart` — user selectable in settings                                                                           |
| On-device AI            | Hybrid path: community `flutter_gemma` + Gemma 4 **E2B** LiteRT-LM for **weekly insights** when weights downloaded; plans/chat/voice stay cloud — **not** 26B on device |
| Cloud Run AI Gateway    | Express scaffold in `backend/ai-gateway/`; Vertex AI client is placeholder; not deployed                                                                                |
| Firebase project naming | `crucueapp` throughout — no `octifyai` legacy in `firebase_options.dart`                                                                                                |
| Demo fallback           | `CloudFunctionsService._buildDemoPlan()` — transparent graceful degradation when API is unavailable                                                                     |
| Riverpod                | Used consistently throughout; duplicate `careProfilesProvider` removed                                                                                                  |
| flutter_markdown        | Replaced with `flutter_markdown_plus` (original package discontinued)                                                                                                   |


---

## 1. Draft Title Options

1. **Crucue: Private AI Support for Caregivers, Powered by Gemma 4**
2. **From Chaos to Calm: Gemma 4-Structured Care Plans for Everyday Caregiving**
3. **Crucue — A Gemma 4-Powered Companion for the Hardest Moments in Caregiving**
4. **Private Caregiving Intelligence: Structured AI Plans Built on Gemma 4**
5. **AI That Holds Space: Structured Care Support for Families, Built on Gemma 4**

---

## 2. Draft Subtitle Options

1. A mobile app that turns a caregiver's difficult moments into structured, private, AI-generated support plans
2. Voice-to-plan caregiving support — structured Gemma 4 outputs enforced by `responseJsonSchema`
3. Calm, private, and practical: AI support built for the people doing the hardest work in healthcare
4. A complete caregiving support loop — incident to plan to reflection — powered by Gemma 4
5. Because caregiving is hard enough without having to figure it out alone

---

## 3. Final Recommended Title + Subtitle

**Title:** Crucue — Private AI Support for Caregivers, Powered by Gemma 4

**Subtitle:** A Flutter mobile app that turns daily caregiving challenges into structured, private support plans — built on Gemma 4 structured JSON outputs, a live voice capture pipeline, and a full reflection loop.

---

## 4. One-Sentence Project Summary

Crucue is a deployed Flutter mobile app for caregivers that uses Gemma 4 (`gemma-4-26b-a4b-it` via Cloud Functions) to generate structured support plans from voice or text incident logs, with grounded follow-up chat, reflection, routines, and AI-powered weekly insights. Primary AI is server-side (no API keys in the client); optional **on-device** weekly insights use smaller Gemma 4 E2B weights via the community `flutter_gemma` plugin — not the same model as cloud.

---

## 5. Project Description

### The problem

There are an estimated 53 million unpaid caregivers in the United States alone. Parents of children with behavioral or developmental challenges. Adults caring for aging parents. Partners navigating chronic illness. Siblings managing family situations from a distance.

What they have in common: they face recurring, high-stress moments with limited support, limited time, and no practical tool that meets them where they are.

Generic AI chat can offer generic advice. What caregivers need is something different — a tool that knows who they're caring for, what's happened before, what helps this specific person, and can give them a structured plan they can actually use in the moment.

### What Crucue does

Crucue is a Flutter mobile app that helps caregivers navigate difficult moments with a loved one. The core loop is simple:

1. **Log the moment.** The caregiver describes what happened — by typing or by speaking into the app. A voice note goes through Google Cloud Speech-to-Text transcription, then Gemma 4 extracts structured incident fields (what happened, possible trigger, what was already tried, desired outcome) using `config.responseJsonSchema`.
2. **Get a structured plan.** Gemma 4 generates a support plan grounded in the specific profile and incident context. The output is a typed JSON object enforced by `responseJsonSchema` — a summary, actionable steps, what to avoid, a message draft for the loved one, follow-up tasks, and a reflection prompt.
3. **Listen to the plan.** The plan can be read aloud via platform TTS (`flutter_tts`). The caregiver doesn't have to read while managing a difficult situation.
4. **Have a grounded follow-up chat.** Chat responses are grounded in the specific plan, profile, and recent reflections — not generic. Voice input is supported.
5. **Reflect.** After trying the plan, the caregiver logs what helped, what didn't, and rates the outcome. This data enriches future plan generation.
6. **Save routines.** Strategies that work become saved routines — reusable and trackable.
7. **Review weekly insights.** A week’s incidents and check-ins are summarized into patterns and suggestions — **on the cloud** by default, or **on-device** (Gemma 4 E2B via `flutter_gemma`) when the user has downloaded weights and chosen On-device / Automatic mode.

### Technical implementation

The Flutter app communicates with Firebase Cloud Functions running on **Node.js 22** that call Gemma 4 via the **@google/genai** SDK (v1.50.0, Google's current unified SDK). All three primary AI operations use `responseMimeType: "application/json"` with `responseJsonSchema` — Gemma 4's structured output, properly typed without hacks. The voice pipeline uses Google Cloud Speech-to-Text via REST, then passes the transcript to Gemma 4 for incident field extraction, also with a structured schema.

The `AiEngine` abstraction layer allows the active inference engine to be swapped without changing any Flutter UI code. The `AiMode` setting lets users choose cloud, on-device (when available), or automatic. The production Firebase project `crucueapp` has all 5 functions deployed, Firestore rules and indexes live, secrets in Secret Manager, and IAM grants for Speech-to-Text and Secret Manager.

---

## 6. What Is Actually Built Today

**Deployed and live (Firebase project `crucueapp`):**

- 5 Cloud Functions on Node.js 22, Gen 2, us-central1
  - `generateSupportPlan`, `chatOnPlan`, `summarizePatterns`, `processVoiceIncident`, `transcribeShortClip`
- Firestore rules (owner-scoped) + 4 composite indexes
- Firebase Storage rules (audio: 10 MB max, image/audio MIME only)
- Secrets: `GEMMA4_API_KEY`, `GEMMA4_MODEL` in Firebase Secret Manager
- IAM: compute SA has `speech.client`, `secretmanager.secretAccessor`, `datastore.user`, `storage.objectViewer`

**Flutter app features (all implemented):**

- Care profile creation (5 relationship types → 9 persona types for AI)
- Text incident logging → Gemma 4 support plan via `generateSupportPlan`
- Voice incident logging: `VoiceRecordingSheet` → Storage upload → `VoiceProcessingScreen` (polls status) → Google Cloud STT → Gemma 4 field extraction → `TranscriptReviewScreen` → plan
- Structured plan display: `summary`, `whatToDoNow[]`, `messageDraft`, `followUpTasks[]`, `reflectionPrompt`
- Platform TTS plan playback (`flutter_tts`) — `_TtsAppBarButton` in `ResultsView`
- Graceful demo fallback: `_buildDemoPlan()` when API unavailable — transparent, persona-aware
- Grounded follow-up chat via `chatOnPlan` — profile + plan + last 3 reflections as context
- Voice chat input (short clip → `transcribeShortClip` → message field)
- Reflection / check-in (`CheckInScreen`): outcome rating, steps that helped, what made it worse
- Save as routine from reflection → `SaveAsRoutineScreen` → `RoutinesListScreen`
- Weekly AI insights (`WeeklyInsightsScreen`) → `summarizePatterns` → `INSIGHT_SCHEMA`
- Profile detail hub: recent incidents, recent plans, saved routines, quick actions
- Light and dark mode (both themes, user toggle in Settings)
- AI engine mode selector in Settings (Cloud / On-device / Auto) with `AiMode` persistence
- Persona policies (9 types) — tone, suggestions, safety boundaries, message style
- Safety checking: keyword scan pre-AI + `escalation_flag` in output + safety banner in UI
- `CrucueAnalytics` — 11 typed Firebase Analytics events across the full caregiving loop
- Full Crashlytics: `FlutterError.onError` + `PlatformDispatcher.instance.onError` + `runZonedGuarded`
- Feature flags (`FeatureFlags`), environment config (`EnvConfig`), `.gitignore` guarding secrets
- Privacy Policy + Terms screens with links to hosted URLs

---

## 7. What Is Partially Implemented or Still Evolving


| Feature                | Status                                                                                  | Honest framing                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| On-device AI inference | Native channels + stubs deployed; `isAvailable()` returns `false`                       | "Architecture ready; model weight delivery is the remaining step"              |
| Cloud Run AI Gateway   | Express service in `backend/ai-gateway/` (Vertex); optional vs callables                | "Scaffolded; deploy when you want Vertex HTTP APIs — not required for the app" |
| AI routine suggestion  | Callable `suggestRoutineFromReflection` + check-in flow pre-fills `SaveAsRoutineScreen` | "Active when `FeatureFlags.aiRoutineSuggestionEnabled` is true"                |
| GoRouter navigation    | `MaterialApp.router` + `router.dart`; legacy `navigateTo()` still works                 | "Hybrid; migrate screens to `context.go` over time"                            |
| Firebase App Check     | `firebase_app_check` in `main.dart`; callables `enforceAppCheck: true`                  | "Register debug tokens (dev) + production providers in Console"                |
| FCM targeted push      | Tokens under `users/{uid}/devices/`*; `sendTestPushNotification` callable               | "Product campaigns / triggers still to be defined"                             |

### Hybrid routing (Cactus track angle)

Crucue’s [`HybridGemmaEngine`](../lib/core/ai/hybrid_gemma_engine.dart) implements **explicit task routing**:

- **Always remote (hosted Gemma 4 via Cloud Functions):** support plan generation, grounded chat, voice pipeline (STT + extraction), short-clip transcription, routine suggestion. These need the **26B-class** instruction-tuned model and shared server-side safety.
- **Weekly insights (`summarizePatterns`):** if the user has downloaded a small Gemma model into the **flutter_gemma** runtime and flags allow it, **only this call** runs on-device; otherwise the same Cloud Function path. On failure, the app **falls back to remote**.

Native **LiteRT-LM** integration via `MethodChannel` is still a **stub**; for edge validation without overclaiming, see [`docs/edge_demo_path.md`](edge_demo_path.md) (Google AI Edge Gallery + roadmap).

### Reproducibility (pinned toolchain)

| Component | Version / constraint |
|-----------|----------------------|
| Flutter | 3.22+ (see `pubspec.yaml` environment) |
| Dart | SDK `>=3.4.0 <4.0.0` |
| Cloud Functions runtime | Node.js **22** (`functions/package.json` `engines`) |
| `@google/genai` | **^1.50.0** |
| Firebase Admin / Functions | ^13.8.0 / ^7.2.5 (see `functions/package.json`) |

Secrets: `GEMMA4_API_KEY`, `GEMMA4_MODEL` (default remote model `gemma-4-26b-a4b-it`; set to `gemma-4-31b-it` only for optional A/B). Local: `functions/.env` — never commit keys.

**Demo script (2–3 min):** see [`docs/hackathon_demo_script.md`](hackathon_demo_script.md).

---

## 8. Technical Stack

**Flutter app:**

- Flutter 3.22+ / Dart 3.4+
- Riverpod (consistent state management throughout)
- Navigation: GoRouter (`MaterialApp.router`) + `navigatorKey` + `navigateTo()` during migration
- UI: `flutter_screenutil`, `flutter_svg`, `animate_do`, `flutter_markdown_plus`
- Audio: `record` (M4A capture), `flutter_tts` (platform TTS), `just_audio` (playback)
- Local storage: `shared_preferences`
- Auth: `google_sign_in`, `sign_in_with_apple`

**Firebase (all active in `crucueapp`):**

- Firebase Authentication
- Cloud Firestore (structured data, owner-scoped rules)
- Firebase Storage (voice audio deleted after processing, profile avatars)
- Firebase Cloud Functions (AI callables + messaging helpers; App Check enforced)
- Firebase Analytics + Crashlytics (typed events + full async coverage)
- Firebase Cloud Messaging (infrastructure ready)

**Cloud Functions (active AI backend):**

- **Runtime:** Node.js 22, Gen 2, us-central1
- **SDK:** `@google/genai` v1.50.0 — Google's current unified SDK
- **Model:** `GEMMA4_MODEL` secret or `gemma-4-26b-a4b-it` default via Google AI Studio API
- **Sampling:** `temperature` per task; **`topP` 0.95** and **`topK` 64** (Gemma 4 model card defaults) on every call — see `functions/src/ai/genai-sampling.ts` and [`docs/gemma4_strategy.md`](gemma4_strategy.md)
- **Structured output:** `config.responseJsonSchema` — enforces typed JSON output at the model level; **latency logs** (`generateSupportPlan: model=... ms=...`, etc.) for optional `gemma-4-31b-it` comparison
- **STT:** Google Cloud Speech-to-Text REST API (no separate package needed)
- **Secrets:** `GEMMA4_API_KEY` + `GEMMA4_MODEL` via Firebase Secret Manager
- **Auth guard:** All callables check `request.auth` — no unauthenticated calls possible

**NOT in use (confirmed absent):**

- `@google/generative-ai` (deprecated — replaced by `@google/genai`)
- `firebase_database` (Realtime Database — not used)
- `flutter_markdown` (discontinued — replaced by `flutter_markdown_plus`)

---

## 9. Why This Fits Gemma 4

Crucue's use of Gemma 4 is structural, not superficial.

A caregiving support plan is not useful as a paragraph of prose. It needs to be a typed object — a summary the caregiver can read in 5 seconds, a numbered list of concrete steps, a message they can say to their loved one, and clear guidance on what to avoid. Gemma 4's `responseJsonSchema` in the `@google/genai` SDK makes this enforceable at the model level — the plan arrives already shaped, not scraped from text after the fact. No `@ts-ignore` hacks. No text-to-JSON fragility.

The same is true for voice extraction: when a caregiver speaks for 90 seconds about what happened, Gemma 4 extracts named, typed fields (`possible_trigger`, `what_user_already_tried`, `desired_outcome`) that are stored, compared across incidents, and used to inform future plans.

The on-device direction (Gemma 4 E2B/E4B via LiteRT-LM / Android AICore) is the privacy-maximizing endpoint. Native platform MethodChannel bridges are scaffolded for both Android and iOS. The shipped on-device path today is `flutter_gemma` for the weekly insight only; full native LiteRT-LM inference is the next integration milestone. When delivered, care data never leaves the device during AI calls.

---

## 10. Safe Demo Positioning

**Lead with the hero flow:** Profile → voice or text incident → support plan → TTS playback → chat → reflection. This is fully implemented and works end-to-end with the deployed Cloud Functions.

**Be specific about what the AI returns:** Show the structured plan — the labeled sections, the message draft, the reflection prompt. The `responseJsonSchema` field is what makes this deterministic. This is more compelling than "the AI generated a response."

**Mention the graceful fallback honestly:** If the API call fails or the network is slow, the app generates a `_buildDemoPlan()` — a warm, persona-aware fallback plan. It's transparent graceful degradation, not fake AI.

**Show the AI mode selector:** Settings → AI Engine shows remote / on-device / auto. Explain on-device honestly: **weekly insights** can use a small on-device model via **flutter_gemma** when weights are installed; **native LiteRT** stubs are not yet wired; **plans and chat** stay on the cloud for quality and safety.

**Show dark mode.** It's wired and looks good. Small signal, high polish.

---

## 11. Copy-Safe Claims

### 10 claims you can make safely

1. "Crucue uses Gemma 4 for all **hosted** AI (default `gemma-4-26b-a4b-it`) via the current `@google/genai` unified SDK; `GEMMA4_MODEL` can override the model ID."
2. "All **hosted** AI runs in Cloud Functions — no API key is in the mobile app. The key lives in Firebase Secret Manager."
3. "Support plans are structured JSON objects enforced by Gemma 4's `responseJsonSchema` — not parsed from raw text."
4. "Caregivers can log incidents by voice — the app records audio, transcribes via Google Cloud STT, and uses Gemma 4 to extract structured incident fields."
5. "Plans can be listened to using platform-native TTS — no additional API or cost."
6. "Grounded follow-up chat is anchored to the specific plan and care profile context, not generic conversation."
7. "The app includes a full reflection loop — after a plan, the caregiver logs what helped and can save effective strategies as routines."
8. "Weekly AI insights use Gemma 4 — on the **cloud** by default, or on-device via **flutter_gemma** when the user has downloaded small Gemma weights and hybrid mode applies."
9. "Native **LiteRT-LM / AICore** integration is scaffolded on Android and iOS `MethodChannel` stubs; the shipped on-device path for weekly insights uses **flutter_gemma**. See `docs/edge_demo_path.md`."
10. "All care data is private and owner-scoped in Firestore. The production Firebase project (`crucueapp`) is live with rules deployed."

### 10 claims to avoid

1. ❌ "Native LiteRT on-device AI is fully working in Crucue" — `OnDeviceAiPlugin.isAvailable()` returns `false`; weekly insights may still use **flutter_gemma** when configured.
2. ❌ "The app works fully offline for all AI" — plans, chat, and voice need network for hosted Gemma 4 + STT; only the weekly hybrid path can be local with weights.
3. ❌ "All Crucue AI runs on Vertex AI" — primary callables use the Google GenAI API (`@google/genai` + API key). The optional Cloud Run gateway uses Vertex.
4. ❌ "The Cloud Run AI Gateway is deployed" — scaffolded, not deployed.
5. ❌ "AI routine suggestions always succeed offline" — the callable requires network (same as other AI).
6. ❌ "Uses outdated Firebase v3 packages" — FlutterFire in `pubspec.yaml` is on the v4-era BoM; verify versions before claiming.
7. ❌ "App Check is fully enforced without Console setup" — you must enable providers and debug tokens in Firebase Console.
8. ❌ "Automated push reminder campaigns ship out of the box" — tokens + test callable exist; product logic is not built-in.
9. ❌ "Navigation is 100% declarative GoRouter only" — `navigateTo()` remains in use during migration.
10. ❌ "Production-ready for the App Store" — release signing, App Check, and FCM APNs setup are still needed.

---

## 12. Final Paste-Ready Kaggle Writeup

```markdown
# Crucue — Private AI Support for Caregivers, Powered by Gemma 4

> A Flutter mobile app that turns daily caregiving challenges into structured, private support plans — built on Gemma 4 structured JSON outputs (`responseJsonSchema`), a live voice capture pipeline, and a full reflection loop.

---

## The problem

There are tens of millions of unpaid caregivers navigating some of the most demanding work a person can do — caring for a child with behavioral challenges, an aging parent, a partner through illness. When a difficult moment happens, they are usually alone, often overwhelmed, and rarely equipped with a practical framework for what to do next.

Generic AI chat tools can offer general advice. Crucue does something more specific: it knows who the caregiver is caring for, what has happened before, what helps this particular person, and it generates a care plan they can actually use in the moment.

---

## What Crucue does

Crucue is a Flutter mobile app built around a simple caregiving support loop:

**1. Log the moment (voice or text)**
The caregiver describes what happened — by typing or speaking. A voice note goes through Google Cloud Speech-to-Text transcription, then Gemma 4 extracts structured incident fields: what happened, possible trigger, what was already tried, and the desired outcome. All extracted via Gemma 4's `responseJsonSchema` in the `@google/genai` SDK — not text parsing after the fact.

**2. Get a structured support plan**
Gemma 4 (`gemma-4-26b-a4b-it`) generates a care plan grounded in the specific care profile and incident context. The output is a typed JSON object enforced at the model level:
- A calm, actionable summary
- Concrete steps (what to do now)
- What to avoid
- A suggested message to the loved one
- Follow-up tasks for the next 24–48 hours
- A reflection prompt
- An escalation flag with safety resources if needed

**3. Listen to the plan**
The plan can be read aloud via platform-native TTS. No additional API. Useful for caregivers managing a difficult situation who can't hold a screen.

**4. Grounded follow-up chat**
Chat with Crucue about the plan or the situation. Responses are grounded in the specific plan, profile context, and recent reflections — not generic chat. Voice input is supported.

**5. Reflect**
After trying the plan, the caregiver logs what helped, what didn't, and rates the outcome. Strategies that work become saved routines.

**6. Weekly insights**
Gemma 4 analyzes a week of incidents, plans, and reflections (hosted by default; optional small-model path for this screen only when the user has on-device weights — see hybrid routing in the repo).

---

## Why Gemma 4

Crucue's use of Gemma 4 is structural, not superficial.

A caregiving support plan needs to be a typed object — not a paragraph. The `responseJsonSchema` field in the `@google/genai` SDK means the plan arrives already shaped: labeled sections, typed arrays, a boolean safety flag. This is immediately actionable in a difficult moment in a way that prose is not. No `@ts-ignore` hacks. No JSON.parse fragility.

The same is true for voice extraction: Gemma 4 extracts named, typed fields that can be stored, compared across incidents, and used to inform future plans.

Crucue also implements **hybrid routing**: weekly insights can use a small Gemma on-device via **flutter_gemma** when available; plans and chat stay on hosted Gemma 4 for quality and safety. Native LiteRT-LM bridges are scaffolded for a future first-party edge stack — see `docs/edge_demo_path.md`.

---

## Technical implementation

**Flutter app**
- Riverpod state management (consistent throughout)
- Firebase Auth (email, Google Sign-In, Apple)
- Firestore (owner-scoped security rules — production rules deployed)
- Firebase Storage (voice audio deleted after processing)
- Firebase Cloud Functions (all AI inference — API key in Secret Manager, never in client)
- Firebase Analytics + Crashlytics (11 typed events + full async error coverage)
- `record` + `flutter_tts` + `just_audio` for the audio stack
- Light and dark mode (both themes implemented, user-selectable)

**Cloud Functions (deployed — Firebase project `crucueapp`)**
- Runtime: Node.js 22, Gen 2, us-central1
- SDK: `@google/genai` v1.50.0 — Google's current unified SDK
- Model: `gemma-4-26b-a4b-it` via Google AI Studio API
- Structured output: `config.responseJsonSchema` — properly typed, enforces JSON at model level
- STT: Google Cloud Speech-to-Text REST API (service account has `roles/speech.client`)
- Secrets: Firebase Secret Manager (`GEMMA4_API_KEY`, `GEMMA4_MODEL`)
- 5 callable functions: `generateSupportPlan`, `chatOnPlan`, `summarizePatterns`, `processVoiceIncident`, `transcribeShortClip`

**AI abstraction layer**
- `AiEngine` interface — all AI calls route through a single typed interface
- `RemoteGemma4Engine` — active implementation via Cloud Functions
- `HybridGemmaEngine` — routes weekly insights to `flutter_gemma` on-device when weights installed; all other calls stay remote
- Native LiteRT-LM MethodChannel bridges (Android/iOS platform code) — scaffolded for future native weight delivery
- `AiMode` selector in Settings (Cloud / On-device / Auto)

---

## Current status

The core caregiving loop is fully implemented and the backend is deployed.

On-device inference is architecturally ready. Native channel bridges are written. Model weight delivery via Play Asset Delivery (Android) or On-Demand Resources (iOS) is the remaining step.

The Cloud Run AI Gateway is scaffolded in `backend/ai-gateway/` — 5 endpoints with AJV validation, Firebase Auth middleware, and persona-aware prompts. The Vertex AI client is the remaining piece before deployment.

---

## Privacy

Care data is owner-scoped in Firestore. Voice recordings are processed server-side and deleted after transcription. No care data is used for model training. When on-device mode is active, AI inference produces no network traffic at all. Account deletion removes all data immediately.

Crucue is not a medical or therapeutic service. All AI outputs are supportive guidance, and every plan includes a note to that effect.

---

*Built for the Gemma 4 Good Hackathon.*
```

---

## What changed from the previous version of this writeup


| Previous claim                                           | Corrected to                                                  |
| -------------------------------------------------------- | ------------------------------------------------------------- |
| SDK was `@google/generative-ai`                          | Now `@google/genai` v1.50.0 (deprecated SDK removed)          |
| `responseSchema` in `generationConfig` with `@ts-ignore` | Now `responseJsonSchema` in `config` — properly typed         |
| Node.js 20                                               | Now Node.js 22 (Node 20 deprecated April 30, 2026)            |
| Firebase project `octifyai` referenced                   | Production project is now `crucueapp` — deployed              |
| `flutter_markdown` in dependencies                       | Replaced with `flutter_markdown_plus` (original discontinued) |
| "Firebase project `octifyai` — legacy naming"            | Resolved — `crucueapp` project is live with apps registered   |


