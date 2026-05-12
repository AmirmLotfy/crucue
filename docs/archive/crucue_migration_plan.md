# Crucue Migration Plan (Octify → Crucue)

## Overview

This document describes the migration from the Octify prototype to the Crucue production-grade app.

---

## Migration Phases Completed

### Phase 1: Full Rebrand ✅
- Package name: `com.araby.octify` → `com.crucue.app`
- Flutter package: `octify` → `crucue`
- All `package:octify/` imports → `package:crucue/`
- Android: `applicationId`, `namespace`, `AndroidManifest.xml`, Kotlin package dir
- iOS: `CFBundleDisplayName`, `CFBundleName`, `PRODUCT_BUNDLE_IDENTIFIER`
- `firebase_options.dart`: iosBundleId updated
- `google-services.json`: package_name updated
- `README.md`: completely rewritten, Zeplin credentials removed
- All Octify string references replaced with Crucue

**Action needed**: Register `com.crucue.app` as a new Android and iOS app in Firebase console, download fresh `google-services.json` and `GoogleService-Info.plist`.

### Phase 2: Architecture Cleanup ✅
- Removed: `flutter_bloc`, `kiwi`, `dio`, `google_generative_ai`, `firebase_database`, `quick_log`, `hive_generator`
- Added: `cloud_firestore`, `cloud_functions`, `go_router`, `firebase_analytics`, `firebase_crashlytics`
- Deleted: 17+ dead files (Bloc, Kiwi, Dio, empty stubs, non-caregiving forms)
- Created: `core/services/`, `shared/models/`, `app/` directories
- New services: `AuthService`, `FirestoreService`, `CloudFunctionsService`, `StorageService`
- New models: `AppUser`, `CareProfile`, `Incident`, `SupportPlan`, `Routine`, `CheckIn`, `Insight`, `ChatMessage`
- New top-level providers: auth state, care profiles, active profile
- Rewrote: `main.dart`, `theme.dart`, `cache_helper.dart`, `input_validator.dart`
- Updated: All screens using `firebase_database` → Firestore
- Updated: All screens using `google_generative_ai` → `CloudFunctionsService`
- Persona types: 14 generic → 5 caregiving relationships
- Theme: `#FF4F00` aggressive orange → `#2A9D8F` calm teal

### Phase 3: Firestore Security ✅
- `firestore.rules`: Owner-only access, field validation, subcollection rules
- `storage.rules`: Owner-only, 10 MB limit, MIME type check
- `.firebaserc`: Points to `octifyai` project
- `firebase.json`: Updated with functions, firestore, storage sections
- `firestore.indexes.json`: Indexes for profile-based queries

### Phase 4: AI Backend ✅
- Cloud Functions directory: `functions/src/`
- `generateSupportPlan`: Loads profile/incident → Gemma 4 → structured JSON → saves to Firestore
- `chatOnPlan`: Context-grounded conversation with full safety checking
- `summarizePatterns`: Weekly insight generation from incidents/checkins
- `prompts.ts`: Prompt templates with safety system prefix
- `safety.ts`: Risk pattern detection + crisis escalation logic
- API key: Environment variable `GEMMA4_API_KEY` (never in source)
- `CloudFunctionsService.dart`: Flutter service with graceful demo fallback

### Phase 5-6: UX & New Screens ✅
- Onboarding: Rewritten with caregiving-focused copy and emoji illustration
- Splash: Crucue wordmark with animated entrance
- Select Persona: Redesigned as "Choose Support Focus" with 5 relationship cards
- Challenges: Rewritten with caregiving-appropriate challenge categories
- Results: Completely rebuilt as structured support plan (cards, not raw markdown)
- Chat: Rebuilt with typing indicator, safety banner, and grounded context
- CreateProfileScreen: Full care profile creation with contextual fields
- AddIncidentScreen: Incident logging with category and intensity
- WeeklyInsightsScreen: Riverpod-powered insights with empty states
- CheckInScreen: Post-plan reflection with step tracking
- ProfileListScreen: Care profiles overview

---

## Outstanding Action Items

### Firebase Console (required before demo)
1. Register `com.crucue.app` as new Android app in Firebase console
2. Download new `google-services.json` → place in `android/app/`
3. Register `com.crucue.app` as new iOS app in Firebase console
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. Enable Firestore in the Firebase project
6. Deploy Firestore rules: `firebase deploy --only firestore:rules`
7. Deploy Storage rules: `firebase deploy --only storage`

### Cloud Functions (required for AI features)
1. Set Gemma 4 API key: `firebase functions:secrets:set GEMMA4_API_KEY`
2. Install: `cd functions && npm install`
3. Deploy: `firebase deploy --only functions`

### Firebase Analytics
- Enabled in `pubspec.yaml` (`firebase_analytics: ^11.3.6`)
- Add event logging in key flows (Phase 8 extension)

### Firebase Crashlytics
- Enabled in `main.dart` (`FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`)
- Add iOS NSCrashReporterUrl to Info.plist if needed

### iOS Configuration
- Add `GoogleService-Info.plist` URL scheme to `ios/Runner/Info.plist` for Google Sign-In

---

## Technical Debt Remaining

- `views/` directory still contains some legacy screens not yet migrated to `features/`
- GoRouter not yet wired to MaterialApp (using imperative navigation during transition)
- `CacheHelper` still caches user data in SharedPreferences; long-term should use Firestore only
- Facebook auth removed; social auth currently supports Google + Apple only
- Notification deep-linking not yet implemented
- `flutter_html` and `pin_code_fields` still in pubspec.lock (transitive deps)

---

## Testing Checklist

- [ ] Email/password registration flow
- [ ] Email verification requirement
- [ ] Login → home screen
- [ ] Create care profile → saved to Firestore
- [ ] Select support focus → fill form → challenges
- [ ] Challenges → generate support plan (Cloud Function)
- [ ] Support plan displays correctly (all sections)
- [ ] Save plan → appears in home history
- [ ] Chat with Crucue from plan screen
- [ ] Check-in reflection saved to Firestore
- [ ] Profile update saved
- [ ] Delete account cleans up Firestore
- [ ] Logout clears session
