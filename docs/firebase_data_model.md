# Firebase Data Model

## Firestore collection structure

All user data is scoped under `users/{uid}/`. Care data is further scoped under `profiles/{profileId}/`.

```
users/{uid}/
  (user document — display name, email)
  devices/{installationId}   (FCM token, platform, updatedAt — one doc per app install)
  profiles/{profileId}/
    (care profile document)
    incidents/{incidentId}
    plans/{planId}
    checkins/{checkinId}
    routines/{routineId}
    insights/{insightId}
    voiceNotes/{voiceNoteId}
  chatThreads/{threadId}/
    messages/{messageId}
  history/{historyId}   (legacy — plans saved without a profile)
```

```mermaid
graph TD
  U[users/{uid}]
  P[profiles/{profileId}]
  I[incidents/{incidentId}]
  PL[plans/{planId}]
  CH[checkins/{checkinId}]
  R[routines/{routineId}]
  IN[insights/{insightId}]
  VN[voiceNotes/{voiceNoteId}]
  CT[chatThreads/{threadId}]
  MSG[messages/{messageId}]

  U --> P
  P --> I
  P --> PL
  P --> CH
  P --> R
  P --> IN
  P --> VN
  U --> CT
  CT --> MSG
```

---

## Document schemas

### User (`users/{uid}`)

```json
{
  "uid": "string",
  "displayName": "string",
  "email": "string",
  "createdAt": "Timestamp",
  "fcmTokens": ["string"]
}
```

---

### Care Profile (`profiles/{profileId}`)

```json
{
  "id": "string",
  "name": "string",
  "relationship": "child | parent | partner | sibling | familyMember",
  "ageGroup": "string | null",
  "supportFocus": "string | null",
  "communicationPreferences": "string | null",
  "triggers": ["string"],
  "calmingStrategies": ["string"],
  "whatHelps": "string | null",
  "whatToAvoid": "string | null",
  "healthNotes": "string | null",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Notes:**
- `relationship` is the structured enum used for icon, color, and default persona type
- The AI persona type (child, teenager, baby, parent, partner, sibling, friend, pet, myself) is derived from `relationship` at plan generation time
- Profile data enriches Gemma 4 prompts but is never sent raw — it is summarized via `personaData`

---

### Incident (`profiles/{profileId}/incidents/{incidentId}`)

```json
{
  "id": "string",
  "profileId": "string",
  "title": "string",
  "description": "string",
  "category": "behavior | communication | emotion | health | routine | safety | other",
  "intensity": 1,
  "whatHappened": "string | null",
  "possibleTrigger": "string | null",
  "whatWasAlreadyTried": "string | null",
  "desiredOutcome": "string | null",
  "voiceNoteRef": "string | null",
  "linkedPlanId": "string | null",
  "createdAt": "Timestamp"
}
```

**Notes:**
- `intensity` is an integer from 1–5 (validated in Firestore rules)
- `voiceNoteRef` links to a VoiceNote document when the incident was logged via voice
- Extended fields (`whatHappened`, `possibleTrigger`, etc.) are extracted by Gemma 4 from voice transcripts

---

### Support Plan (`profiles/{profileId}/plans/{planId}`)

```json
{
  "id": "string",
  "profileId": "string | null",
  "summary": "string",
  "whatMightBeHappening": "string",
  "whatToDoNow": ["string"],
  "whatToAvoid": ["string"],
  "messageDraft": "string",
  "followUpTasks": ["string"],
  "reflectionPrompt": "string",
  "createdAt": "Timestamp",
  "personaModel": {},
  "selectedChallenges": ["string"],
  "incidentId": "string | null"
}
```

**Notes:**
- Plans are written by the client via `FirestoreService.savePlanWithContext()`
- AI-generated plans via Cloud Functions use the Admin SDK and bypass client rules
- Plans are **immutable from the client** after creation (Firestore rules: no client update allowed)
- `personaModel` and `selectedChallenges` are the context used to generate the plan, stored for reflection reference

---

### Check-In / Reflection (`profiles/{profileId}/checkins/{checkinId}`)

```json
{
  "id": "string",
  "profileId": "string",
  "planId": "string",
  "didThisHelp": true,
  "notes": "string | null",
  "stepsCompleted": ["string"],
  "stepsHelpedMost": ["string"],
  "whatMadeItWorse": "string | null",
  "shouldBecomeRoutine": false,
  "outcomeRating": 3,
  "createdAt": "Timestamp"
}
```

**Notes:**
- `outcomeRating` is 1–5
- `shouldBecomeRoutine: true` triggers navigation to `SaveAsRoutineScreen` in the app
- Completed check-ins inform Gemma 4 context in future plan generation and weekly insights

---

### Routine (`profiles/{profileId}/routines/{routineId}`)

```json
{
  "id": "string",
  "profileId": "string",
  "title": "string",
  "steps": ["string"],
  "frequency": "daily | weekdays | weekends | weekly | as-needed",
  "estimatedDurationMinutes": 15,
  "tags": ["string"],
  "basedOnPlanId": "string | null",
  "basedOnIncidentId": "string | null",
  "reminders": ["string"],
  "lastUsedAt": "Timestamp | null",
  "completionCount": 0,
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

### Insight (`profiles/{profileId}/insights/{insightId}`)

```json
{
  "id": "string",
  "profileId": "string",
  "weekStart": "Timestamp",
  "summary": "string",
  "patterns": ["string"],
  "whatWorked": ["string"],
  "suggestions": ["string"],
  "moodTrend": "improving | stable | declining | null",
  "createdAt": "Timestamp"
}
```

**Notes:**
- Insight **documents** are written only by the Flutter client (`FirestoreService.saveInsight`) after `AiEngine.summarizePatterns` returns — either from the `summarizePatterns` callable (cloud Gemma 26B) or from on-device Gemma 4 E2B via `flutter_gemma` when enabled.
- The callable reads recent incidents, plans, and check-ins for the week; the client uses the same query shape when building the local prompt.
- Insights are write-once from the client (no update rule in Firestore)

---

### Voice Note (`profiles/{profileId}/voiceNotes/{voiceNoteId}`)

```json
{
  "id": "string",
  "profileId": "string",
  "storagePath": "string",
  "durationSeconds": 0,
  "status": "pending | uploading | uploaded | transcribing | extracting | completed | failed",
  "transcript": "string | null",
  "extractedIncident": {
    "incident_title": "string",
    "incident_category": "string",
    "intensity": 3,
    "possible_trigger": "string | null",
    "what_user_already_tried": "string | null",
    "desired_outcome": "string | null",
    "cleaned_summary": "string",
    "safety_flag": false,
    "confidence": 0.85
  },
  "linkedIncidentId": "string | null",
  "errorMessage": "string | null",
  "createdAt": "Timestamp"
}
```

**Notes:**
- `status` is a pipeline state machine managed by Cloud Functions via Admin SDK
- Client can only update `linkedIncidentId` (Firestore rules enforce this)
- `storagePath` points to the audio in Firebase Storage (`users/{uid}/voices/{profileId}/{voiceNoteId}.m4a`)
- Audio is deleted from Storage after `status: completed`

---

### Chat Thread (`users/{uid}/chatThreads/{threadId}`)

```json
{
  "id": "string",
  "profileId": "string",
  "planId": "string | null",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Note:** Chat threads are scoped to `users/{uid}/chatThreads/`, not under `profiles/`. This allows a thread to reference multiple profiles or exist without a profile. The `profileId` field links back to the relevant profile.

---

### Chat Message (`users/{uid}/chatThreads/{threadId}/messages/{messageId}`)

```json
{
  "id": "string",
  "role": "user | assistant",
  "content": "string",
  "timestamp": "Timestamp"
}
```

**Notes:**
- Messages are append-only (no client update — Firestore rules enforce this)
- History is passed to Cloud Functions for grounded responses (last N messages)

---

## Firestore security rules summary

Key constraints enforced by `firestore.rules`:

| Rule | Rationale |
|------|-----------|
| All access requires auth + owner UID match | No cross-user data access |
| Plans: no client update | AI-generated plans are immutable |
| VoiceNotes: update restricted to `linkedIncidentId` only | Status/transcript fields are server-controlled |
| Chat messages: no client update | Append-only chat history |
| Insights: no client update | Server-generated content |
| Default deny on all unmatched paths | Defense in depth |

---

## Firestore indexes

Queries requiring composite indexes:

```json
{
  "indexes": [
    {
      "collectionGroup": "incidents",
      "fields": [
        { "fieldPath": "profileId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "plans",
      "fields": [
        { "fieldPath": "profileId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Deploy with: `firebase deploy --only firestore:indexes`
