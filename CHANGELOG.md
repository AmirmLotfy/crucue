# Changelog

All notable changes to Crucue are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Gemini API alignment

- Default remote Gemma model ID updated to **`gemma-4-26b-a4b-it`** (instruction-tuned resource name per [Gemma on Gemini API](https://ai.google.dev/gemma/docs/core/gemma_on_gemini_api)); premium placeholder **`gemma-4-31b-it`**. Shared constant in [`functions/src/ai/model-ids.ts`](functions/src/ai/model-ids.ts).
- Production: rotate `GEMMA4_MODEL` to match (see [`docs/deployment_and_envs.md`](docs/deployment_and_envs.md)).

### Voice privacy (Storage)

- After successful processing, **`processVoiceIncident`** deletes the uploaded voice audio object from Firebase Storage (non-fatal if delete fails).
- **`transcribeShortClip`** deletes the short-clip object after STT.

### FlutterFire

- Bumped Firebase plugins to **FlutterFire BoM 4.12.0**–aligned versions (`firebase_core` ^4.7.0, `cloud_firestore` ^6.3.0, `cloud_functions` ^6.2.0, etc.).
- **iOS minimum deployment target** raised to **15.0** in `ios/Podfile` and `ios/Runner.xcodeproj` for Firebase iOS SDK 12.x compatibility.

### Code quality

- Chat welcome message now seeds via `ChatViewModel.ensureWelcomeMessage` instead of mutating `StateNotifier.state` from the widget layer
- Removed several unused imports; dropped dead `items` branch in privacy settings UI; simplified settings list row divider parameter where it was never customized

### SDK Migration — `@google/generative-ai` → `@google/genai`

- Replaced deprecated `@google/generative-ai` npm package with `@google/genai` v1.50.0 (Google's current unified SDK for Gemini Developer API and Vertex AI)
- All 4 Cloud Function AI files rewritten to use new API patterns:
  - `new GoogleGenerativeAI(key)` → `new GoogleGenAI({ apiKey: key })`
  - `generationConfig.responseSchema` + `// @ts-ignore` → `config.responseJsonSchema` (properly typed)
  - `result.response.text().trim()` → `response.text`
  - `.getGenerativeModel({ model, generationConfig })` → `.models.generateContent({ model, contents, config })`
- Installed `@modelcontextprotocol/sdk` peer dependency required by `@google/genai`
- Upgraded Cloud Functions Node.js runtime from **Node.js 20** (deprecated April 30, 2026) to **Node.js 22**
- Upgraded `firebase-functions` from `^6.0.0` to `7.2.5`

### Flutter Packages

- Removed `flutter_markdown` (marked discontinued by pub.dev) — replaced with `flutter_markdown_plus` v1.0.7 (API-compatible maintained fork)
- Updated `flutter_svg` → `^2.2.4`, `animate_do` → `^4.2.0`, `shared_preferences` → `^2.5.5`, `url_launcher` → `^6.3.0`, `image_picker` → `^1.1.2`

### Firebase Production Deployment (`crucueapp`)

- Created Android app (`1:696766634035:android:3208606342b698d7802b46`) and iOS app (`1:696766634035:ios:fb6ea06e096ffff2802b46`) in Firebase project `crucueapp`
- Generated `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` for `crucueapp`
- Regenerated `lib/firebase_options.dart` for `crucueapp` (replacing legacy `octifyai`)
- Deployed Firestore security rules and 4 composite indexes
- Deployed Firebase Storage rules
- Deployed all 5 Cloud Functions (Node.js 22, Gen 2, us-central1)
- Set `GEMMA4_API_KEY` and `GEMMA4_MODEL` in Firebase Secret Manager
- Granted IAM roles: `speech.client`, `secretmanager.secretAccessor`, `datastore.user`, `storage.objectViewer` to compute service account
- Enabled APIs: Cloud Functions, Firestore, Storage, Speech-to-Text, Secret Manager, Cloud Run, Cloud Build, Identity Toolkit

### Docs Updated

- `docs/gemma4_strategy.md` — SDK migration, `responseJsonSchema` API, updated tech table
- `docs/gemma4_function_calling.md` — Fully rewritten to reflect `@google/genai` patterns
- `docs/kaggle_writeup_truthful_draft.md` — Updated all stale SDK/project references; new "what changed" section
- `docs/deployment_and_envs.md` — Firebase project updated to `crucueapp`
- `docs/hackathon_submission_notes.md` — Firebase project deployment status updated
- `README.md` — Node.js version, SDK name, Firebase project, tech stack table all updated
- `functions/src/ai/prompts.ts` — SDK comments updated (`responseJsonSchema`)

---

## [Unreleased — Previous]

### Added
- `AiEngine` abstraction layer with `RemoteGemma4Engine`, `AndroidOnDeviceGemma4Engine`, `IosOnDeviceGemma4Engine`
- `AiMode` enum (remote / on-device / auto) with user preference persistence and Settings UI
- `FeatureFlags` class — compile-time kill switches for voice, on-device AI, insights, routine suggestion
- `EnvConfig` — environment configuration with support URL, privacy URL, app version
- `CrucueAnalytics` — typed Firebase Analytics event helpers (11 events)
- Full Crashlytics coverage: `PlatformDispatcher.instance.onError` + `runZonedGuarded`
- Privacy Policy and Terms screens with hosted URL links
- Version display in Settings
- Root `.gitignore` covering Flutter, Firebase platform files, and build artifacts
- Cloud Run AI Gateway scaffold in `backend/ai-gateway/` (Express/TypeScript, 5 routes, AJV validation, Firebase Auth middleware, Winston logging)
- Native on-device AI platform channels: `OnDeviceChannel` MethodChannel contract, `OnDeviceAiPlugin.kt` (Android), `OnDeviceAiPlugin.swift` (iOS)
- `FirestoreService.savePlanWithContext()` — consolidated plan save replacing direct Firestore writes in views
- `docs/about-crucue.md`, `docs/setup_local_development.md`, `docs/deployment_and_envs.md`, `docs/privacy_and_safety.md`, `docs/analytics_events.md`, `docs/hackathon_submission_notes.md`

### Changed
- Corrected Gemma 4 model identifier from `gemma-4-27b` to `gemma-4-26b-a4b` throughout Cloud Functions, `.env.example`, and documentation (later aligned to `gemma-4-26b-a4b-it` in [Unreleased] to match Gemini API resource names)
- `AiProvider` → renamed to `AiEngine` across all Dart code and documentation
- `careProfilesProvider` removed in favour of `profilesStreamProvider` (canonical repository provider)
- Onboarding pages now use theme-aware colours (light + dark mode safe)
- 15 hardcoded `Color(0x...)` values in widget files replaced with `CrucueTokens` or `Theme.of(context).*`
- `navigatorKey` now wired to `MaterialApp` — `navigateTo()` and `showMessage()` no longer at risk of NPE
- Facebook SDK removed from `AndroidManifest.xml` and `strings.xml`
- `AddIncidentScreen._save()` now navigates to `ResultsView` (plan generation) after saving, matching the button label
- `TranscriptReviewScreen` persona type now resolved from care profile relationship, not hardcoded to `PersonaType.child`
- Firestore rules: `plans` collection is now create-only from the client (no client updates). `voiceNotes` updates restricted to `linkedIncidentId` field only.
- `ChatViewModel.sendMessage()` now catches errors and shows a fallback message
- Chat voice transcription failure now shows a user-visible warning instead of silently failing

### Removed
- `ai_provider.dart` — re-export shim (deleted)
- `ai_provider_registry.dart` — re-export shim (deleted)
- `gemma4_edge_provider.dart` — superseded by platform-specific on-device engines (deleted)
- `gemma4_backend_provider.dart` — superseded by `RemoteGemma4Engine` (deleted)
- `profile_list_screen.dart` — orphaned screen with no in-app navigation (deleted)
- Facebook SDK metadata (removed from Android manifest and strings)
- Direct `FirebaseFirestore.instance` calls from view files — moved to `FirestoreService`

---

## [1.0.0] — Hackathon Release Candidate

Initial Crucue build from the Octify codebase migration:

- Project renamed from Octify to Crucue
- Package identifier: `com.crucue.app`
- Firebase Auth (email, Google)
- Care profile creation (5 relationship types, expanded to 9 persona types)
- Text-based incident logging
- Gemma 4 support plan generation via Cloud Functions
- Voice incident logging pipeline (record → STT → Gemma 4 extraction → review → plan)
- Platform TTS plan playback
- Grounded follow-up chat (plan + profile context)
- Reflection / check-in
- Routines (save from plan, list, detail)
- Weekly AI insights
- Light and dark mode with semantic `CrucueTokens` design system
- `AiMode` selector in Settings (Cloud / On-device / Auto)
