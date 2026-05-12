# Crucue Launch Checklist

A sequential checklist from "codebase is ready" to "app is in store".

---

## T-minus 2 weeks: Backend

- [ ] `GEMMA4_API_KEY` set in Firebase Secrets Manager
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Storage rules deployed (`firebase deploy --only storage`)
- [ ] Test voice incident flow end-to-end (voice → processing → plan)
- [ ] Test chat flow end-to-end with plan context
- [ ] Test weekly insights generation
- [ ] Verify Cloud Function error responses are graceful (not leaking stack traces)

## T-minus 2 weeks: Mobile

- [ ] `flutter analyze` — 0 errors
- [ ] Android release keystore created and `key.properties` configured
- [ ] iOS minimum deployment target set to `14.0` in Podfile
- [ ] FCM push capability added in Xcode
- [ ] APNs key uploaded to Firebase Console
- [ ] `UIBackgroundModes remote-notification` in `Info.plist`
- [ ] App Check initialized in `main.dart`
- [ ] `firebase_app_check` added to `pubspec.yaml`

## T-minus 1 week: Content

- [ ] Privacy policy live at `crucue.app/privacy`
- [ ] Terms live at `crucue.app/terms`
- [ ] Support email `support@crucue.app` active and monitored
- [ ] App Store screenshots (5-8 per device)
- [ ] App Store description (short + long)
- [ ] Google Play screenshots + feature graphic
- [ ] Google Play description + short description

## T-minus 3 days: QA

- [ ] Full hero flow tested on physical iOS device
- [ ] Full hero flow tested on physical Android device
- [ ] Dark mode verified at all screens on both platforms
- [ ] Voice permission flow tested on both platforms (first-time, denied, settings link)
- [ ] TTS playback tested on both platforms
- [ ] Account deletion tested (data cleared from Firestore + Storage)
- [ ] Analytics events appearing in Firebase Console > Realtime
- [ ] Crashlytics test crash verified (use `FirebaseCrashlytics.instance.crash()` in debug)
- [ ] App builds in release mode without errors

## T-minus 1 day: Submission

- [ ] Build app bundle: `flutter build appbundle --release`
- [ ] Build iOS archive: `flutter build ipa --release`
- [ ] Upload to Google Play Internal Track
- [ ] Upload to TestFlight
- [ ] Verify metadata, screenshots, privacy labels in both stores
- [ ] Submit for review

## Launch day

- [ ] Monitor Firebase Console for error spikes
- [ ] Monitor Crashlytics for fatal errors
- [ ] Monitor Cloud Functions logs for API failures
- [ ] Respond to any App Review feedback within 24h

## Post-launch week 1

- [ ] Check analytics funnel: profile_created → incident_logged → plan_generated → plan_saved
- [ ] Review Crashlytics for any P0 crashes
- [ ] Check retention metrics (D1, D3, D7)
- [ ] Collect first user feedback
- [ ] Plan first update sprint based on data
