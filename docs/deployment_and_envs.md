# Deployment and Environment Configuration

## Environment strategy

Crucue uses Firebase project **`crucueapp`** as the production project. Both Android and iOS apps are registered, all Cloud Functions are deployed, Firestore rules and indexes are live, and secrets are stored in Secret Manager. A separate staging project is the recommended next step before a public store launch.

### Environment flag

Pass environment at build time via `--dart-define`:

```bash
# Development (hot reload, debug tools, verbose logging)
flutter run --dart-define=ENV=dev

# Staging
flutter build apk --dart-define=ENV=staging

# Production (default when no flag is passed)
flutter build apk --release
```

The `EnvConfig` class (`lib/core/config/env_config.dart`) reads this flag and exposes `EnvConfig.isDev`, `isStaging`, `isProd`.

---

## Secrets handling

### What is a secret vs what is not

| Item | Secret? | Where stored |
|------|---------|-------------|
| Gemma 4 API key | **Yes** | Firebase Secrets Manager |
| Firebase client API key | No | `lib/firebase_options.dart` (standard for Firebase clients) |
| `google-services.json` / `GoogleService-Info.plist` | Not technically secret, but project-specific | gitignored; added per-environment in CI |

### Firebase Secrets Manager (production)

```bash
# Set the Gemma 4 API key as a Firebase secret
firebase functions:secrets:set GEMMA4_API_KEY

# Verify
firebase functions:secrets:get GEMMA4_API_KEY

# Model resource name (must match Gemini Developer API — instruction-tuned id)
printf '%s' 'gemma-4-26b-a4b-it' | firebase functions:secrets:set GEMMA4_MODEL --data-file=-
firebase functions:secrets:get GEMMA4_MODEL
```

After changing secrets, redeploy functions so new revisions pick them up: `firebase deploy --only functions`.

Secrets are accessed in Cloud Functions via `process.env.GEMMA4_API_KEY` and `process.env.GEMMA4_MODEL`. The `functions/.env.example` shows the expected variables.

### Local development

```bash
# Copy example and fill in values
cp functions/.env.example functions/.env
# Edit functions/.env — DO NOT commit this file
```

---

## Firebase Cloud Functions deployment

```bash
# Build TypeScript and deploy all functions
cd functions
npm run build
firebase deploy --only functions

# Deploy a single function
firebase deploy --only functions:generateSupportPlan

# View function logs
firebase functions:log
```

**Functions deployed:**
- `generateSupportPlan` — AI support plan generation
- `chatOnPlan` — grounded care chat
- `summarizePatterns` — weekly insights
- `processVoiceIncident` — STT + Gemma 4 incident extraction
- `transcribeShortClip` — voice chat input transcription

---

## Firestore rules deployment

```bash
firebase deploy --only firestore:rules
```

Rules are in `firestore.rules` at the repo root. Key constraints:
- All data scoped to `users/{uid}` — no cross-user access
- Plans are create-only from the client (no client updates)
- `voiceNotes` updates restricted to `linkedIncidentId` field
- Chat messages are append-only (no client updates)

---

## Firebase Storage rules deployment

```bash
firebase deploy --only storage
```

---

## Cloud Run AI Gateway (scaffolded, not yet deployed)

The `backend/ai-gateway/` directory contains a full Express/TypeScript scaffold for a Cloud Run service. The **Vertex AI client is a placeholder** — the actual Vertex AI `generateContent` call needs to be implemented before deployment.

When ready:

```bash
cd backend/ai-gateway

# Install dependencies
npm install

# Build
npm run build

# Deploy to Cloud Run
gcloud run deploy crucue-ai-gateway \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --set-env-vars GOOGLE_CLOUD_PROJECT=crucueapp,GEMMA4_DEFAULT_MODEL=gemma-4-26b-a4b-it
```

Until the gateway is deployed, the Cloud Functions remain the active AI backend.

---

## Android release build

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore android/app/crucue.keystore \
     -alias crucue -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Create `android/key.properties` (gitignored):
   ```
   storePassword=your-store-password
   keyPassword=your-key-password
   keyAlias=crucue
   storeFile=../app/crucue.keystore
   ```

3. Update `android/app/build.gradle` to reference `key.properties` in the `signingConfigs` block.

4. Build:
   ```bash
   flutter build appbundle --release
   ```

---

## iOS release build

1. In Xcode, configure signing with your Apple Developer account.
2. Set the minimum deployment target (iOS 14.0+) in `ios/Podfile`:
   ```ruby
   platform :ios, '14.0'
   ```
3. Configure Push Notifications capability (required for FCM).
4. Upload APNs key to Firebase Console.
5. Build:
   ```bash
   flutter build ipa --release
   ```

---

## Firebase staging/prod split (recommended before launch)

1. Create a second Firebase project (`crucue-prod` or `crucue-staging`)
2. Configure FlutterFire for multiple environments:
   ```bash
   flutterfire configure --project crucue-prod -o lib/firebase_options_prod.dart
   ```
3. In `main.dart`, select the options based on `EnvConfig.isProd`
4. Use separate `google-services.json` / `GoogleService-Info.plist` per environment in CI

---

## CI/CD (recommended)

A minimal GitHub Actions workflow for analysis:

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
        with:
          flutter-version: '3.22.x'
      - run: flutter pub get
      - run: flutter analyze
```
