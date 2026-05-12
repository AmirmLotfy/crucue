# Crucue Voice Data Model

## Firestore: VoiceNote

**Path:** `users/{uid}/profiles/{profileId}/voiceNotes/{voiceNoteId}`

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `profileId` | string | Parent profile ID |
| `userId` | string | Owner UID (redundant with path, useful for security rules) |
| `audioUrl` | string? | Firebase Storage download URL (set after upload) |
| `storagePath` | string? | Firebase Storage bucket path (for deletion) |
| `durationMs` | int | Recording duration in milliseconds |
| `transcript` | string? | Raw text from Google Cloud STT (set after transcription) |
| `status` | string | Processing pipeline stage (see below) |
| `errorMessage` | string? | Human-readable error if status = `failed` |
| `incidentId` | string? | Linked incident ID (set after user confirms in review screen) |
| `extractedIncident` | map? | Structured incident data from Gemma 4 (see below) |
| `safetyFlag` | boolean | True if safety system detected concerning content |
| `createdAt` | timestamp | Firestore server timestamp |
| `updatedAt` | timestamp | Updated at each pipeline stage |

### Processing Status Values

| Status | Description |
|--------|-------------|
| `pending` | Audio recorded locally, not yet uploaded |
| `uploading` | Upload in progress |
| `uploaded` | Upload complete; Cloud Function has been triggered |
| `transcribing` | Google Cloud STT is running |
| `extracting` | Gemma 4 extraction is running |
| `completed` | Full pipeline complete |
| `failed` | Pipeline failed; `errorMessage` contains details |

### `extractedIncident` Map

This map is written by the `processVoiceIncident` Cloud Function after Gemma 4 processes the transcript.

| Field | Type | Description |
|-------|------|-------------|
| `transcript` | string | Same as top-level transcript field (convenience) |
| `cleaned_summary` | string | 1-2 sentence summary |
| `incident_title` | string | Short title (max 60 chars) |
| `incident_category` | string | behavior / communication / emotion / health / routine / safety / other |
| `intensity` | int | 1-5 |
| `possible_trigger` | string? | Inferred trigger or null |
| `what_user_already_tried` | string? | What the caregiver tried or null |
| `desired_outcome` | string? | Desired resolution or null |
| `key_entities` | string[] | People, places, things mentioned |
| `confidence` | float | 0.0–1.0 extraction confidence |
| `safety_flag` | boolean | Safety concern flag |

---

## Firebase Storage: Voice Audio

**Path:** `users/{uid}/profiles/{profileId}/voiceNotes/{voiceNoteId}/audio.m4a`

- Format: M4A (AAC-LC), 16 kHz, mono, 64 kbps
- Max size: ~10 MB (well within the 10 MB storage rule)
- Access: owner-only (storage.rules: uid-scoped)
- Deletion: can be called via `StorageService.deleteFile(url)` when VoiceNote is deleted

---

## Firestore Security Rules

```javascript
match /voiceNotes/{voiceNoteId} {
  allow read: if isAuthenticated() && isOwner(uid);
  allow create: if isAuthenticated() && isOwner(uid)
    && isValidString(request.resource.data.profileId, 1, 128)
    && isValidString(request.resource.data.userId, 1, 128);
  allow update: if isAuthenticated() && isOwner(uid);
  allow delete: if isAuthenticated() && isOwner(uid);
}
```

The Cloud Function uses Admin SDK (bypasses client rules) to update processing status.

---

## Flutter Model: `VoiceNote`

**File:** `lib/shared/models/voice_note.dart`

Key features:
- `VoiceNoteStatus` enum with `isProcessing` and `isDone` getters for UI logic
- `status.label` for human-readable stage descriptions in `VoiceProcessingScreen`
- `fromFirestore` / `toMap` for Firestore serialization
- `copyWith` for immutable updates

---

## Relationship to `Incident`

```
VoiceNote (1) ──────────── (0..1) Incident
  voiceNote.incidentId        incident.voiceNoteRef
```

- A VoiceNote is created before an Incident
- After the user confirms in `TranscriptReviewScreen`, an Incident is created
- `voiceNoteId` is stored on the Incident as `voiceNoteRef`
- `incidentId` is stored on the VoiceNote as `incidentId`
- Both sides of the link are set atomically via `FirestoreService.linkVoiceNoteToIncident`

---

## Riverpod Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `audioRecorderProvider` | `Provider<AudioRecorderService>` | Singleton recorder service |
| `voiceRecordingProvider` | `StateNotifierProvider<VoiceRecordingNotifier, VoiceRecordingState>` | Recording state + timer |
| `amplitudeStreamProvider` | `StreamProvider<double>` | 0–1 amplitude for waveform |
| `speechOutputProvider` | `Provider<SpeechOutputService>` | Singleton TTS service |
| `ttsPlaybackProvider` | `StateNotifierProvider<TtsPlaybackNotifier, TtsPlaybackState>` | TTS play/stop state |

---

## What Needs Configuration

### Before voice features work

1. **Enable Google Cloud Speech-to-Text API** in the GCP project linked to Firebase
   - Go to: `console.cloud.google.com → APIs & Services → Speech-to-Text API`
   - Enable for the project ID in `firebase.json` (currently `octifyai`)

2. **Grant IAM role to Cloud Functions service account**
   - Service account: `{project-id}@appspot.gserviceaccount.com`
   - Role: `Cloud Speech-to-Text API User`

3. **Deploy Cloud Functions**
   ```bash
   firebase deploy --only functions
   ```

4. **Deploy Firestore rules** (already includes voiceNotes rules)
   ```bash
   firebase deploy --only firestore:rules
   ```

### Already ready (no additional config needed)

- Firebase Storage rules allow `audio/*` up to 10 MB
- `StorageService.uploadVoiceNoteForProfile()` is implemented
- `FirestoreService` voice note CRUD methods are implemented
- Flutter packages (`record`, `flutter_tts`, `just_audio`, `permission_handler`) installed
- iOS: `NSMicrophoneUsageDescription` was already in `Info.plist`
- Android: `RECORD_AUDIO` permission needs to be added to `AndroidManifest.xml`

### Android manifest addition needed

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

This is handled at runtime by `permission_handler` but must also be declared.
