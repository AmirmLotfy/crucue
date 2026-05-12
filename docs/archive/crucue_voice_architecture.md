# Crucue Voice Architecture

## Overview

Crucue supports a voice-first caregiving flow built on three pillars:

1. **Voice incident capture** — record a voice note describing what happened, have it transcribed and structured into incident fields
2. **Plan read-aloud** — listen to the generated support plan via platform TTS
3. **Voice input in chat and reflection** — speak follow-up questions and reflections, transcribed to text before sending to Gemma 4

---

## Full Voice Pipeline

```
User taps "Voice note" in incident screen
        │
        ▼
VoiceRecordingSheet (modal bottom sheet)
  - States: idle / recording / paused / review / uploading
  - Timer, animated waveform indicator
  - Max 3 minutes, stops automatically
  - Permission handling with education UI
        │
        ▼ (upload triggers processVoiceIncident Cloud Function)
Firebase Storage
  path: users/{uid}/profiles/{profileId}/voiceNotes/{id}/audio.m4a
        │
        ▼
VoiceProcessingScreen (polls Firestore VoiceNote.status)
  Step 1: uploading → uploaded
  Step 2: transcribing (Google Cloud STT)
  Step 3: extracting (Gemma 4 structured extraction)
  Step 4: completed
        │
        ▼
TranscriptReviewScreen
  - Full transcript shown (editable)
  - Extracted fields shown (title, category, intensity, trigger, etc.)
  - Confidence indicator
  - User confirms or edits before saving
        │
        ▼
Incident created in Firestore
  - voiceNoteRef linked to VoiceNote ID
        │
        ▼
ResultsView — generateSupportPlan (Gemma 4 via Cloud Function)
  - "Listen" menu → reads summary / steps / message draft via platform TTS
```

---

## Service Abstractions

### `AudioRecorderService` (`lib/core/audio/audio_recorder_service.dart`)

Abstract interface with `RecordAudioService` (uses `record` package) as the default implementation.

- Records in M4A/AAC at 16kHz mono (optimal for Google Cloud STT)
- Max 3 minutes enforced with auto-stop timer
- `amplitudeStream` provides 100ms samples for waveform display
- Permission checking and requesting baked in

### `SpeechOutputService` (`lib/core/audio/speech_output_service.dart`)

Abstract TTS interface with `PlatformTtsService` (uses `flutter_tts`) as default.

- iOS: AVSpeechSynthesizer
- Android: Android TTS
- No API costs, works offline
- Two speaking rates: `normal` (0.5) and `calm` (0.4)
- State stream for play/pause/stop UI

### `AudioPlaybackService` (`lib/core/audio/audio_playback_service.dart`)

For playback of recorded audio before upload. Uses `just_audio`.

---

## Voice Chat Input

Short voice clips (max 30s) for chat follow-up questions:

1. User holds mic button in ChatView
2. `RecordAudioService` records the clip
3. Clip uploaded to a temporary Storage path
4. `transcribeShortClip` Cloud Function transcribes via Google STT
5. Transcript populates the text field
6. User taps send → Gemma 4 receives the grounded text message

---

## Voice Reflection

Short voice clips in CheckInScreen:

1. User holds "Hold to speak" button next to the notes field
2. Same `RecordAudioService` flow
3. `transcribeShortClip` fills the notes field
4. User reviews and submits normally

---

## What Needs Real Credentials / Configuration

### Required for voice pipeline to work

| Requirement | What to do |
|-------------|-----------|
| Google Cloud Speech-to-Text API | Enable in GCP console under the Firebase project |
| Service account IAM | Add `Cloud Speech-to-Text API User` role to Cloud Functions service account |
| Firebase Storage rules | Already deployed — allows `audio/*` files up to 10 MB |
| GEMMA4_API_KEY | Set via `firebase functions:secrets:set GEMMA4_API_KEY` |

### Optional / Future

| Item | Status |
|------|--------|
| Gemma 4 multimodal audio input | Not yet available in API; STT bridge is the production approach |
| On-device TTS voice selection | Works with system voice, can be extended with `flutter_tts` language/voice settings |
| Voice waveform from actual amplitude | `amplitudeStream` exists; simple animated bars used in current UI |
| Gemma 4 E4B on-device voice processing | Planned via `Gemma4EdgeProvider` — see `gemma4_edge_future_path.md` |

---

## Privacy Model

| Data | Where it lives | Access |
|------|---------------|--------|
| Raw audio | Firebase Storage (encrypted at rest) | Owner only (uid-scoped rules) |
| Transcript | Firestore VoiceNote document | Owner only |
| Extracted incident | Firestore VoiceNote.extractedIncident map | Owner only |
| TTS synthesis | On-device (platform native) | Never leaves device |
| Short clip transcriptions | Storage path deleted after transcription | Ephemeral |

No voice audio is retained after the pipeline completes and the user confirms. Audio can be deleted from Storage at any time.
