# Privacy and Safety

## Overview

Crucue handles some of the most sensitive personal data that exists: notes about caregiving situations, behavioral incidents involving vulnerable individuals, medical context, and family dynamics. The privacy architecture is designed to reflect that.

---

## Data access model

All Firestore data is scoped to the authenticated user's UID. The security rules (`firestore.rules`) enforce:

```
users/{uid}/...  →  accessible only to the user with that UID
```

There is no cross-user data access. No admin role can read user data through the client API — only the Firebase Admin SDK (used by Cloud Functions) can read across users, and Cloud Functions only do so for the specific user making the call.

### What the client can read/write

| Collection | Client create | Client update | Client delete |
|-----------|--------------|--------------|--------------|
| `profiles` | ✅ | ✅ | ✅ |
| `incidents` | ✅ | ✅ | ✅ |
| `plans` | ✅ (with schema validation) | ❌ | ✅ |
| `checkins` | ✅ | ✅ | ✅ |
| `routines` | ✅ | ✅ | ✅ |
| `insights` | ✅ | ❌ | ✅ |
| `voiceNotes` | ✅ | Only `linkedIncidentId` | ✅ |
| `chatThreads/messages` | ✅ | ❌ | ✅ |
| `devices` (FCM installation docs) | ✅ | ✅ | ✅ |

Plans are immutable from the client once created (AI-generated plans should not be modified). Voice note fields like `transcript`, `status`, and `extractedIncident` are written exclusively by Cloud Functions.

---

## Voice data handling

Voice recordings are the most sensitive artifact in the system.

**Processing pipeline:**
1. Caregiver records audio on device
2. Audio is uploaded to Firebase Storage at `users/{uid}/voices/{profileId}/{voiceNoteId}.m4a`
3. Cloud Function downloads the audio, calls Google Cloud Speech-to-Text, and runs Gemma 4 extraction
4. The resulting transcript and structured incident fields are written to Firestore
5. **The audio file is deleted from Storage after successful processing**

At no point does the audio file persist beyond the processing window. It is not retained for training, analysis, or any purpose other than the single transcription call.

---

## AI inference and data

### Remote inference (current)
Care context (incident description, profile summary) is sent to the Gemma 4 API via Google Cloud infrastructure. This data is:
- Used only to generate the support plan for the current request
- Not retained by Google AI Studio beyond the API call window (per Google's API data terms)
- Never used to train Gemma 4 or any other model

The Crucue app does not log or store the raw prompts sent to the model.

### On-device inference (future)
When on-device AI mode is active on supported devices, **no care data leaves the device during inference**. The model runs locally using LiteRT-LM / Android AICore. Only Firestore writes (to the user's own collection) are sent to the cloud.

---

## User control

Users have full control over their data:

- **Delete account**: Deletes all associated Firestore data and Firebase Auth credentials immediately. Found in Settings → Delete Account.
- **Delete individual records**: Incidents, plans, routines, and reflections can be deleted individually.
- **Voice recordings**: Automatically deleted after processing; there is nothing to manually delete.
- **Export**: Not currently implemented. Planned for a future release.

---

## Non-diagnostic positioning

Crucue is not a medical, psychological, or therapeutic service.

Every support plan includes this context. The app's prompts explicitly instruct the AI:
- Never impersonate a licensed professional
- Never diagnose conditions
- Never prescribe treatments
- Always recommend professional consultation for safety concerns

The safety preamble injected into every AI call is defined in `backend/ai-gateway/src/policies/safety.ts` and `functions/src/ai/safety.ts`.

---

## Escalation and safety checks

When a voice note transcript or typed incident contains safety-related language (mentions of injury, self-harm, emergency, abuse, etc.), the AI pipeline:

1. Sets `safetyFlag: true` on the extracted incident
2. Displays a prominent safety banner in the transcript review screen:
   *"This situation may benefit from professional support. Please reach out to a qualified care provider if needed."*
3. Includes a `safetyNote` in the generated support plan

The safety keyword list is defined in the Cloud Functions safety module. It is not a replacement for a real crisis line — the banner explicitly directs users to professional services.

---

## Responsible AI behavior

Persona policies in `lib/shared/persona_policies.dart` (Dart) and `backend/ai-gateway/src/policies/persona-policies.ts` (TypeScript) configure the AI's behavior per relationship type:

- **Tone guidance**: How the AI communicates (e.g., "respectful and dignified" for parent personas, "non-condescending" for teenager personas)
- **Suggestion types**: What kinds of interventions to emphasize
- **Safety boundaries**: What triggers immediate escalation for this persona type
- **Escalation threshold**: When the response must include a safety note

These policies control *behavior*, not *identity*. The AI does not roleplay as a therapist, doctor, or care coordinator. It is always an AI support tool.

---

## Privacy in the product experience

Privacy is not just a backend concern — it shows up in the product itself:

- No ads, no data sharing, no recommendation engine
- No social features — care data is never shared with other users
- The onboarding screen states explicitly: *"Your care notes are yours alone. Crucue keeps everything private and encrypted — never shared, never sold."*
- The Privacy Policy and Terms are accessible from Settings
- The app name (Crucue) does not appear in system logs or notification identifiers in a way that reveals the user's caregiving role to bystanders
