# Release Checklist

Use this checklist before any public store release. Not all items apply to a hackathon demo build.

---

## Secrets and credentials

- [ ] `GEMMA4_API_KEY` set in Firebase Secrets Manager (not in source, not in `.env` committed)
- [ ] `google-services.json` is in `.gitignore` and provided out-of-band in CI
- [ ] `GoogleService-Info.plist` is in `.gitignore` and provided out-of-band in CI
- [ ] No API keys, tokens, or passwords in `lib/`, `functions/src/`, or any committed files
- [ ] `functions/.env` is NOT committed (only `functions/.env.example`)
- [ ] Android keystore is NOT committed (only referenced via `android/key.properties` which is gitignored)

---

## Build configuration

- [ ] Android `applicationId`: `com.crucue.app`
- [ ] Android `minSdk`: 23+
- [ ] Android release signing configured in `android/app/build.gradle` via `android/key.properties`
- [ ] iOS Bundle ID: `com.crucue.app`
- [ ] iOS minimum deployment target: `14.0` set in `ios/Podfile`
- [ ] iOS signing configured in Xcode with Apple Developer account
- [ ] App version in `pubspec.yaml`: `version: 1.0.0+1` (update before each release)
- [ ] `debugShowCheckedModeBanner: false` in `main.dart` ✅

---

## Firebase

- [ ] Cloud Functions deployed: `firebase deploy --only functions`
- [ ] Firestore rules deployed: `firebase deploy --only firestore:rules`
- [ ] Storage rules deployed: `firebase deploy --only storage`
- [ ] App Check initialized in `main.dart` (`PlayIntegrity` / `AppAttestWithDeviceCheckFallback` in release; debug providers in dev)
- [ ] `firebase_app_check` in `pubspec.yaml` ✅
- [ ] Firebase Console: App Check providers enabled; debug tokens registered for dev devices
- [ ] Cloud Functions callables deployed with `enforceAppCheck: true` ✅
- [ ] FCM push capability enabled in Xcode
- [ ] APNs key or certificate uploaded to Firebase Console
- [ ] `UIBackgroundModes remote-notification` in `ios/Runner/Info.plist`
- [ ] FCM device tokens stored in Firestore user doc on login

---

## Legal

- [ ] Privacy Policy hosted at `crucue.app/privacy`
- [ ] Terms of Service hosted at `crucue.app/terms`
- [ ] Privacy Policy screen links to correct URL in `EnvConfig.privacyPolicyUrl`
- [ ] Terms screen links to correct URL in `EnvConfig.termsUrl`
- [ ] Support email `support@crucue.app` active
- [ ] App Store privacy labels filled in (data types, purpose, linked to identity)
- [ ] Google Play Data Safety section filled in

---

## Branding and app identity

- [ ] App icon set for all required sizes (Android + iOS)
- [ ] Splash screen updated (if applicable)
- [ ] `EnvConfig.appVersion` matches `pubspec.yaml` version
- [ ] Copyright year current in `README.md` and `LICENSE`

---

## Analytics and crash reporting

- [ ] Firebase Analytics enabled and receiving events in Console
- [ ] Crashlytics enabled — test crash verified: `FirebaseCrashlytics.instance.crash()`
- [ ] `PlatformDispatcher.instance.onError` wired ✅
- [ ] `runZonedGuarded` wrapping `runApp()` ✅
- [ ] `CrucueAnalytics` typed events implemented ✅

---

## Theme and dark mode

- [ ] Light and dark mode verified on physical devices (both platforms)
- [ ] Onboarding screens verified in dark mode ✅ (adaptive color palettes)
- [ ] All screens use `Theme.of(context).colorScheme.*` for color decisions ✅
- [ ] No `Color(0xff...)` literals in widget files ✅ (audit with `grep`)

---

## Feature flags

- [ ] `FeatureFlags.onDeviceAiEnabled` is `false` (model weights not yet delivered)
- [ ] `FeatureFlags.aiRoutineSuggestionEnabled` matches product intent (`true` = callable AI pre-fill on “save as routine”)
- [ ] `FeatureFlags.voiceCaptureEnabled` is `true`
- [ ] `FeatureFlags.weeklyInsightsEnabled` is `true`
- [ ] `FeatureFlags.chatEnabled` is `true`

---

## Quality assurance

- [ ] `flutter analyze` — 0 errors
- [ ] Full hero flow tested on physical iOS device: profile → voice incident → plan → chat → reflection
- [ ] Full hero flow tested on physical Android device
- [ ] Voice recording tested on both platforms (permission grant + permission deny + settings redirect)
- [ ] TTS playback tested on both platforms
- [ ] Account deletion tested (data cleared from Firestore + Storage)
- [ ] Dark mode tested at all screens on both platforms
- [ ] Error states tested: network failure during plan generation shows retry UI
- [ ] Chat error state tested: AI failure shows graceful fallback message ✅

---

## Store submission

- [ ] App Store Connect listing complete (name, subtitle, description, keywords)
- [ ] App Store screenshots prepared (5–8 per device size)
- [ ] Google Play Console listing complete
- [ ] Google Play feature graphic and screenshots prepared
- [ ] Age rating confirmed (4+)
- [ ] Category confirmed (Health & Fitness)

---

## Post-launch monitoring

- [ ] Firebase Console → Dashboard monitored for error spikes (first 24h)
- [ ] Crashlytics monitored for fatal errors (first 24h)
- [ ] Cloud Functions logs monitored for AI failures (first 24h)
- [ ] Analytics funnel `profile_created → incident_logged → plan_generated` checked for drop-offs (first week)
