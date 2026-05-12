# Release Readiness — Crucue

## Status Summary

| Category | Status |
|----------|--------|
| Crashlytics (Flutter errors) | DONE |
| Crashlytics (async errors) | DONE — `PlatformDispatcher.instance.onError` + `runZonedGuarded` |
| Analytics events | DONE — typed `CrucueAnalytics` helpers |
| Root `.gitignore` | DONE |
| `google-services.json` in `.gitignore` | DONE |
| Facebook SDK removed | DONE |
| Firestore rules tightened | DONE — plans immutable, voiceNotes restricted |
| Feature flags | DONE — `FeatureFlags` class |
| Env config | DONE — `EnvConfig` with support email, URLs, version |
| Privacy Policy screen | DONE — links to hosted URL |
| Terms screen | DONE — links to hosted URL |
| Version in Settings | DONE |
| Android release signing | NOT DONE |
| App Check | NOT DONE |
| FCM iOS background modes | NEEDS VERIFICATION |
| iOS minimum target pinned | NOT DONE |
| CI/CD pipeline | NOT DONE |

---

## Outstanding Release Blockers

### 1. Android release signing
Configure in `android/key.properties` (gitignored) and `android/app/build.gradle`:
```gradle
signingConfigs {
  release {
    storeFile file(keystoreProperties['storeFile'])
    storePassword keystoreProperties['storePassword']
    keyAlias keystoreProperties['keyAlias']
    keyPassword keystoreProperties['keyPassword']
  }
}
```

### 2. App Check
Add to `pubspec.yaml`:
```yaml
firebase_app_check: ^0.3.1+4
```
Initialize in `main.dart` before `runApp`:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

### 3. iOS minimum deployment target
Uncomment in `ios/Podfile`:
```ruby
platform :ios, '14.0'
```

### 4. FCM iOS push
- Add Push Notifications capability in Xcode
- Upload APNs certificate or key to Firebase Console
- Add to `ios/Runner/Info.plist`:
  ```xml
  <key>UIBackgroundModes</key>
  <array><string>remote-notification</string></array>
  ```

### 5. Server-side FCM token storage
Store device FCM token in `users/{uid}` Firestore doc on login, so the backend can send targeted push notifications for weekly insights and plan reminders.

### 6. CI/CD
Recommend GitHub Actions:
```yaml
# .github/workflows/analyze.yml
name: Flutter Analyze
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
```

---

## Env Separation Strategy

Currently: single Firebase project `octifyai`.

For staging/prod separation:
- Create `octifyai-staging` Firebase project
- Use `--dart-define=ENV=staging` in CI staging builds
- Wire `EnvConfig.isDev`/`isStaging`/`isProd` to Firebase project selection via `FlutterFire` targets

---

## Security Checklist

- [x] API keys (Gemma 4) server-side only — not in Flutter app
- [x] Firebase client keys in `firebase_options.dart` (expected — not sensitive)
- [x] `google-services.json` in `.gitignore`
- [x] Firestore rules: owner-scoped, plans immutable, voiceNotes restricted
- [ ] App Check: not yet initialized
- [ ] Storage rules: verify audio upload size limits and path validation
- [x] Auth: all Firestore writes require valid Firebase Auth token
- [x] Cloud Functions: all callables check `request.auth`

---

## Store Submission Metadata (to be filled)

### App Store (iOS)
- **Name:** Crucue
- **Subtitle:** Private caregiving support
- **Category:** Health & Fitness (primary), Lifestyle (secondary)
- **Age Rating:** 4+
- **Privacy:** Declare data collection for analytics, no third-party sharing

### Google Play (Android)
- **Title:** Crucue — Private Caregiving AI
- **Category:** Health & Fitness
- **Content Rating:** Everyone
- **Data Safety:** User data encrypted, no data sold, data deletable
