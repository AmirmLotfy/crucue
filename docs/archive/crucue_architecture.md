# Crucue Architecture

## Overview

Crucue is a Flutter mobile app backed by Firebase, with AI capabilities powered by Gemma 4 via secure Cloud Functions. All user data is private, owner-scoped, and encrypted at rest.

---

## Layer Architecture

```
┌────────────────────────────────────────────────┐
│                Flutter App                      │
│  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Features  │  │   Shared Models/Widgets │  │
│  │  (screens)  │  │   (typed, reusable)     │  │
│  └──────┬──────┘  └─────────────────────────┘  │
│         │                                       │
│  ┌──────▼──────────────────────────────────┐   │
│  │       Core Services Layer               │   │
│  │  FirestoreService | CloudFunctionsService│   │
│  │  AuthService | StorageService            │   │
│  └──────┬───────────────┬──────────────────┘   │
└─────────┼───────────────┼────────────────────── ┘
          │               │
          ▼               ▼
   Firestore DB    Firebase Cloud Functions
                         │
                         ▼
                    Gemma 4 27B API
```

---

## Directory Structure

```
lib/
  main.dart                     # App entry point (Crashlytics, FCM, Riverpod)
  firebase_options.dart         # FlutterFire auto-generated config

  app/
    constants.dart              # App-wide constants, collection names
    providers.dart              # Top-level Riverpod auth/profile providers
    router.dart                 # GoRouter with auth guards

  core/
    theme.dart                  # Crucue calm-teal design system
    design/                     # Reusable UI widgets (AppInput, AppButton, etc.)
    logic/
      cache_helper.dart         # SharedPreferences wrapper (session data)
      firebase_notifications.dart # FCM + local notification setup
      helper_methods.dart       # Navigation helpers, showMessage
      input_validator.dart      # Form validation utilities
    services/
      auth_service.dart         # Firebase Auth wrapper
      firestore_service.dart    # All Firestore read/write operations
      cloud_functions_service.dart # Callable Firebase Functions wrapper
      storage_service.dart      # Firebase Storage wrapper

  shared/
    models/
      app_user.dart             # User profile model
      care_profile.dart         # Loved-one profile model + CareRelationship enum
      incident.dart             # Challenge/incident model + IncidentCategory enum
      support_plan.dart         # AI-generated support plan model
      routine.dart              # Routine/task model
      checkin.dart              # Follow-up check-in model
      insight.dart              # Weekly insight model
      chat_message.dart         # Chat message model + MessageRole enum

  features/
    profiles/
      data/profiles_repository.dart
      presentation/
        create_profile_screen.dart
        profile_list_screen.dart
    incidents/
      data/incidents_repository.dart
      presentation/add_incident_screen.dart
    plans/
      data/plans_repository.dart
      presentation/checkin_screen.dart
    chat/
      data/chat_repository.dart
    insights/
      data/insights_repository.dart
      presentation/weekly_insights_screen.dart

  views/                        # Legacy screens (being migrated to features/)
    auth/                       # Login, register, onboarding, splash
    home/                       # Home shell, settings
    chat/                       # Chat view + view model
    results.dart                # Support plan display (key demo screen)
    challenges.dart             # Challenge selection
    select_persona.dart         # Support focus selection
    tell_about_persona/         # Care profile form components

functions/
  src/
    index.ts                    # Function exports + Firebase Admin init
    ai/
      generate-support-plan.ts  # generateSupportPlan callable function
      chat-on-plan.ts           # chatOnPlan callable function
      summarize-patterns.ts     # summarizePatterns callable function
      prompts.ts                # Prompt templates + output interfaces
      safety.ts                 # Risk detection + crisis escalation
```

---

## Firestore Data Schema

```
users/{uid}
  displayName, email, photoUrl, createdAt, updatedAt

users/{uid}/history/{id}           (Phase 2 bridge — legacy plans)

users/{uid}/profiles/{profileId}
  name, relationship, ageGroup, supportFocus
  communicationPreferences, triggers[], calmingStrategies[]
  healthNotes, whatHelps, whatToAvoid
  createdAt, updatedAt

users/{uid}/profiles/{profileId}/incidents/{incidentId}
  title, description, category, intensity (1-5)
  tags[], voiceNoteRef?, imageRef?, createdAt

users/{uid}/profiles/{profileId}/plans/{planId}
  summary, whatMightBeHappening, whatToDoNow[]
  whatToAvoid[], messageDraft, followUpTasks[]
  reflectionPrompt, escalationFlag, safetyNote
  basedOnIncidentId, createdAt

users/{uid}/profiles/{profileId}/routines/{routineId}
  title, description, frequency, timeOfDay, steps[], isActive

users/{uid}/profiles/{profileId}/checkins/{checkinId}
  planId, didThisHelp, notes, moodOutcome, stepsCompleted[]

users/{uid}/profiles/{profileId}/insights/{insightId}
  weekStart, summary, patterns[], whatWorked[], suggestions[]

users/{uid}/chatThreads/{threadId}
  profileId, planId, createdAt, updatedAt
  .../messages/{messageId}
    role (user|assistant), content, timestamp
```

---

## AI Flow

```
Flutter UI
  └─► CloudFunctionsService.generateSupportPlan()
        └─► Firebase Callable Function (generateSupportPlan)
              ├─► Load profile + incident from Firestore
              ├─► Build structured prompt (prompts.ts)
              ├─► Safety pre-check (safety.ts)
              ├─► Call Gemma 4 27B API
              ├─► Parse JSON response → SupportPlanOutput
              ├─► Apply safety overrides
              ├─► Persist plan to Firestore
              └─► Return structured plan to Flutter

Flutter UI
  └─► CloudFunctionsService.chatOnPlan()
        └─► Firebase Callable Function (chatOnPlan)
              ├─► Load profile + plan context from Firestore
              ├─► Safety check on user message
              ├─► Build grounded chat prompt
              ├─► Call Gemma 4 27B
              ├─► Safety check on AI response
              ├─► Persist messages to Firestore thread
              └─► Return response text
```

---

## Security

- **Firestore rules**: Owner-only access (`request.auth.uid == uid`)
- **Storage rules**: Owner-only, file size limit (10 MB), MIME type restricted
- **AI keys**: Stored in Firebase Secrets Manager (never in source code or client)
- **App Check**: Configured in Firebase console for production
- **Auth**: Firebase Authentication (email/password + Google Sign-In)

---

## State Management

Riverpod is the single state management solution:
- `StateNotifierProvider` for chat state and form state
- `StreamProvider` for real-time Firestore listeners
- `FutureProvider` for one-time async data loads
- `Provider` for services and repositories

---

## Key Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| State management | Riverpod only | Removed Bloc/Kiwi; clean, consistent |
| Navigation | Imperative + GoRouter (migration in progress) | Backward compatible; GoRouter for new screens |
| Database | Firestore | Better querying, offline support, realtime |
| AI | Cloud Functions → Gemma 4 | No client-side keys, safety controls, context loading |
| Theme | Calm teal (#2A9D8F) | Trustworthy, supportive, not clinical |
| Persona types | 5 caregiving relationships | Focused MVP, not 14 generic types |
