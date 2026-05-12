# Crucue

> **Gemma 4 Good Hackathon submission** · [Live demo](https://www.crucue.com/hackathon) · [Download APK](https://www.crucue.com/downloads/crucue.apk)

**Private AI support for caregivers.** Crucue helps people navigate the hardest everyday moments with a loved one — turning difficult situations into structured support plans, grounded follow-up, and actionable routines.

---

## What it is

Crucue is a private B2C mobile app for caregivers: parents supporting children through behavioral challenges, adults caring for aging parents, partners supporting someone through illness, and anyone providing hands-on daily care for another person.

When a difficult moment happens, the caregiver logs it — by voice or text — and receives a calm, structured AI-generated support plan. Plans are grounded in the specific profile of the person being cared for, the type of challenge, and previous reflections. Follow-up chat is grounded in the plan context, not generic. Routines that work get saved. Weekly insights surface what is helping over time.

Everything is private. Nothing is shared. The app is designed to feel calm, trustworthy, and practically useful — not like a demo glued to a language model.

---

## Core user journey

```
Log a challenging moment (text or voice)
  ↓
Gemma 4 generates a structured support plan
  — summary, actionable steps, message draft, safety note
  ↓
Listen to the plan via TTS, save it, chat with Crucue for follow-up
  ↓
Reflect: what helped, what didn't?
  ↓
Save effective strategies as routines
  ↓
Weekly AI insights surface patterns over time
```

---

## Key features

| Feature | Status |
|---------|--------|
| Care profile creation (9 relationship types) | ✅ Implemented |
| Text incident logging → structured support plan | ✅ Implemented |
| Voice incident logging → transcript → plan | ✅ Implemented |
| Plan TTS playback (platform-native) | ✅ Implemented |
| Grounded follow-up chat (plan + profile context) | ✅ Implemented |
| Voice chat input (transcribe → message) | ✅ Implemented |
| Reflection / check-in | ✅ Implemented |
| Save as routine from reflection | ✅ Implemented |
| Weekly AI insights and pattern summary | ✅ Implemented |
| Light and dark mode | ✅ Implemented |
| AI engine mode selector (cloud / on-device / auto) | ✅ UI + logic; on-device requires model weights |
| On-device inference (LiteRT-LM / AICore) | 🔧 Native channels scaffolded, model weights pending |
| Cloud Run AI Gateway | 🔧 Scaffolded, Vertex client pending |

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.22+ / Dart 3.4+ |
| Auth | Firebase Authentication (email + Google Sign-In + Apple) |
| Database | Cloud Firestore (owner-scoped, rules-enforced) |
| File Storage | Firebase Storage (voice audio, avatars) |
| Notifications | Firebase Cloud Messaging |
| Analytics | Firebase Analytics (typed event helpers) |
| Crash reporting | Firebase Crashlytics (full async coverage) |
| AI — remote | Firebase Cloud Functions (Node.js 22) → `@google/genai` SDK → Gemma 4 (`gemma-4-26b-a4b-it`) |
| AI — on-device | LiteRT-LM / Android AICore (scaffolded, pending weights) |
| State management | Riverpod (consistent throughout) |
| Navigation | `navigatorKey` + `navigateTo()` (GoRouter defined, cutover planned) |
| Audio | `record` (capture) + `flutter_tts` (TTS) + `just_audio` (playback) |
| AI Gateway | Cloud Run (Express/TypeScript scaffold in `backend/ai-gateway/`) |

---

## Architecture summary

```
Flutter App
├── AiEngine (abstract interface)
│   ├── RemoteGemma4Engine → Cloud Functions → Gemma 4 API (primary)
│   └── HybridGemmaEngine → flutter_gemma on-device (weekly insights only)
│       └── OnDeviceChannel (MethodChannel) → LiteRT-LM / AICore (scaffolded, roadmap)
├── FirestoreService (all DB reads/writes)
├── StorageService (voice audio, avatars)
├── CrucueAnalytics (typed Firebase Analytics events)
└── Riverpod providers (theme mode, AI mode, profiles, chat, routines, insights)

Firebase Backend (project: crucueapp — deployed)
├── Cloud Functions (7 callables — Node.js 22, @google/genai SDK)
│   ├── generateSupportPlan
│   ├── chatOnPlan
│   ├── summarizePatterns
│   ├── processVoiceIncident (Google Cloud STT + Gemma 4 extraction)
│   ├── transcribeShortClip
│   ├── suggestRoutineFromReflection
│   └── sendTestPushNotification
├── Firestore (owner-scoped security rules + indexes, deployed)
└── Storage (rules deployed, voice audio deleted after processing)

Cloud Run AI Gateway (backend/ai-gateway/) — scaffolded, not deployed
└── See backend/ai-gateway/STATUS.md
```

See [`docs/final_production_architecture.md`](docs/final_production_architecture.md) for the full architecture diagram.

---

## Gemma 4

Crucue uses **Gemma 4** as its primary AI model family.

- **Remote default**: `gemma-4-26b-a4b-it` (26B Mixture-of-Experts, production)
- **Remote premium**: `gemma-4-31b-it` (31B dense, planned)
- **On-device fast**: `gemma-4-e2b-it` (2B, Android AICore / LiteRT-LM, pending)
- **On-device quality**: `gemma-4-e4b-it` (4B, flagship devices, pending)

All AI outputs use structured JSON schemas enforced via `config.responseJsonSchema` in the `@google/genai` SDK. No raw text is returned and parsed. See [`docs/gemma4_strategy.md`](docs/gemma4_strategy.md).

---

## Firebase usage

- **Auth**: Email/password + Google Sign-In + Sign in with Apple
- **Firestore**: All structured data. Paths are `users/{uid}/profiles/{id}/...`. Security rules enforce owner-only access.
- **Storage**: Voice audio files (deleted after processing) + profile avatars
- **Cloud Functions**: All AI inference (API keys never in the client)
- **FCM**: Push notifications (infrastructure in place, targeted push pending)
- **Analytics + Crashlytics**: Full event tracking and async error coverage

---

## Repo structure

```
crucue/
├── lib/
│   ├── app/                  # Providers, constants
│   ├── core/
│   │   ├── ai/               # AiEngine interface + RemoteGemma4Engine + on-device stubs
│   │   ├── audio/            # Recorder, TTS, playback services
│   │   ├── config/           # FeatureFlags, EnvConfig
│   │   ├── design/           # Shared UI components
│   │   ├── logic/            # Helpers, navigation, cache, notifications
│   │   ├── observability/    # CrucueAnalytics (typed events)
│   │   ├── services/         # FirestoreService, StorageService, CloudFunctionsService
│   │   └── theme.dart        # CrucueTokens + AppTheme light/dark
│   ├── features/
│   │   ├── incidents/        # Incident logging
│   │   ├── insights/         # Weekly AI insights
│   │   ├── plans/            # Check-in / reflection
│   │   ├── profiles/         # Care profile management
│   │   ├── routines/         # Saved routines
│   │   └── voice_capture/    # Voice pipeline (record → process → review)
│   ├── shared/
│   │   ├── models/           # 9 typed Firestore models
│   │   └── persona_policies.dart
│   └── views/                # Auth, home, chat, results, settings, legal
├── functions/                # Firebase Cloud Functions (TypeScript, Node.js 22, @google/genai)
│   └── src/ai/               # 5 AI callable handlers + prompts + safety
├── backend/
│   └── ai-gateway/           # Cloud Run AI Gateway scaffold (Express/TypeScript)
├── android/                  # Android platform (com.crucue.app)
├── ios/                      # iOS platform (com.crucue.app)
├── docs/                     # Architecture, strategy, and deployment docs
└── firestore.rules           # Firestore security rules
```

---

## Setup

### Prerequisites

- Flutter 3.22+ / Dart 3.4+
- Node.js 22+ (for Cloud Functions — functions run on Node.js 22 in production)
- Firebase CLI: `npm install -g firebase-tools`
- Firebase project `crucueapp` (production project — already deployed)

### Local development

See [`docs/setup_local_development.md`](docs/setup_local_development.md) for the full step-by-step guide.

**Quick start:**

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Set up Firebase platform config
#    Place google-services.json in android/app/
#    Place GoogleService-Info.plist in ios/Runner/

# 3. Install Cloud Functions dependencies
cd functions && npm install

# 4. Set Gemma 4 API key (required for AI features)
firebase functions:secrets:set GEMMA4_API_KEY

# 5. Run the app
flutter run
```

### Environment variables

Cloud Functions read from Firebase Secrets Manager in production. For local development, copy `functions/.env.example` to `functions/.env` and fill in your values.

```bash
GEMMA4_API_KEY=your-gemma4-api-key-here
GEMMA4_MODEL=gemma-4-26b-a4b-it
```

**No Gemma 4 API key belongs in the Flutter app.** All AI calls are server-side.

---

## Running the app

```bash
# Development
flutter run

# Release build (Android)
flutter build appbundle --release

# Release build (iOS)
flutter build ipa --release
```

---

## Deployment

Cloud Functions:
```bash
cd functions && firebase deploy --only functions
```

Firestore rules:
```bash
firebase deploy --only firestore:rules
```

See [`docs/deployment_and_envs.md`](docs/deployment_and_envs.md) for the full deployment guide, including Cloud Run AI Gateway deployment steps.

---

## Privacy and safety

Crucue handles sensitive personal data about caregiving situations, family members, and medical context. The app is designed around strict privacy principles:

- All Firestore data is owner-scoped — no cross-user access is possible via security rules
- Voice recordings are processed server-side and deleted after transcription
- AI inference uses your anonymized context — no care data is used for model training
- On-device AI mode (when available) performs all inference locally, with no network calls during plan generation
- Crucue is **not** a licensed medical, therapeutic, or legal service

See [`docs/privacy_and_safety.md`](docs/privacy_and_safety.md) for the full privacy and safety architecture.

---

## Roadmap

**Completed for hackathon submission:**
- ✅ Android release signing (keystore + signed APK)
- ✅ On-device model downloader UI in Settings
- ✅ Flutter analyze clean (zero issues)
- ✅ App URLs updated to crucue.com

**Next milestones:**
- On-device AI: LiteRT-LM via Android AICore (MethodChannel scaffolded, model delivery pending)
- Cloud Run AI Gateway: complete Vertex AI client and deploy
- iOS FCM push capability and APNs setup
- GoRouter navigation cutover
- Google Play / App Store submission
- Multilingual STT and UI (currently en-US only)

See [`docs/submission_checklist.md`](docs/submission_checklist.md) for the full hackathon submission state.

---

## Documentation index

| Doc | Purpose |
|-----|---------|
| [`docs/about-crucue.md`](docs/about-crucue.md) | Product mission, target user, care loop |
| [`docs/final_production_architecture.md`](docs/final_production_architecture.md) | System architecture with diagrams |
| [`docs/firebase_data_model.md`](docs/firebase_data_model.md) | Firestore schema reference |
| [`docs/gemma4_strategy.md`](docs/gemma4_strategy.md) | Gemma 4 model strategy, structured outputs |
| [`docs/on_device_strategy.md`](docs/on_device_strategy.md) | LiteRT-LM / AICore on-device path |
| [`docs/theme_system.md`](docs/theme_system.md) | Design tokens, dark mode |
| [`docs/setup_local_development.md`](docs/setup_local_development.md) | Local dev setup guide |
| [`docs/deployment_and_envs.md`](docs/deployment_and_envs.md) | Deployment and env configuration |
| [`docs/privacy_and_safety.md`](docs/privacy_and_safety.md) | Privacy architecture and safety model |
| [`docs/analytics_events.md`](docs/analytics_events.md) | Analytics event reference |
| [`docs/hackathon_submission_notes.md`](docs/hackathon_submission_notes.md) | Hackathon demo notes |
| [`docs/release_checklist.md`](docs/release_checklist.md) | Pre-release checklist |

---

## License

Copyright © 2026 Crucue. All rights reserved.

This repository is submitted as part of the **Gemma 4 Good Hackathon**. The code is not yet open-source. See the LICENSE file for terms.
