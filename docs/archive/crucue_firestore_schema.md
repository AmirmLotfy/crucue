# Crucue Firestore Schema

## Collection Structure

```
users/{uid}
  displayName, email, photoUrl, createdAt, updatedAt

users/{uid}/profiles/{profileId}
  name, relationship, ageGroup, supportFocus
  communicationPreferences, triggers[], calmingStrategies[]
  healthNotes, whatHelps, whatToAvoid
  createdAt, updatedAt

users/{uid}/profiles/{profileId}/incidents/{incidentId}
  profileId, title, description
  category (enum), intensity (1-5)
  whatHappened, possibleTrigger, whatWasAlreadyTried, desiredOutcome
  tags[], voiceNoteRef?, imageRef?
  createdAt

users/{uid}/profiles/{profileId}/plans/{planId}
  profileId, incidentId?
  summary, whatMightBeHappening
  whatToDoNow[], whatToAvoid[]
  messageDraft, followUpTasks[]
  reflectionPrompt, escalationFlag, safetyNote?
  personaModel, selectedChallenges  (legacy bridge fields)
  createdAt

users/{uid}/profiles/{profileId}/routines/{routineId}
  profileId, title, description?
  frequency (daily|weekdays|weekends|weekly)
  timeOfDay?, steps[], isActive
  basedOnPlanId?, basedOnIncidentId?
  tags[], lastUsedAt?, reminders[]
  completionCount
  createdAt

users/{uid}/profiles/{profileId}/checkins/{checkinId}
  profileId, planId
  didThisHelp, outcomeRating (1-5)
  notes?, moodOutcome?
  stepsCompleted[], stepsHelpedMost[]
  whatMadeItWorse?, shouldBecomeRoutine
  createdAt

users/{uid}/profiles/{profileId}/insights/{insightId}
  profileId, weekStart (timestamp)
  summary, patterns[], whatWorked[], suggestions[]
  createdAt

users/{uid}/chatThreads/{threadId}
  profileId, planId?, createdAt, updatedAt
  .../messages/{messageId}
    role (user|assistant), content, timestamp

users/{uid}/history/{historyId}
  (Legacy bridge — plans saved before profileId was implemented)
  summary, whatMightBeHappening, whatToDoNow[], ...
  personaModel, selectedChallenges, createdAt
```

---

## Field Types Reference

### users/{uid}
| Field | Type | Notes |
|-------|------|-------|
| displayName | string | Full name |
| email | string | From auth |
| photoUrl | string? | Storage URL |
| createdAt | timestamp | Server timestamp |
| updatedAt | timestamp | Server timestamp |

### profiles/{profileId}
| Field | Type | Notes |
|-------|------|-------|
| name | string | Required |
| relationship | string | Enum: child, parent, partner, sibling, familyMember |
| ageGroup | string? | e.g. "Toddler (2-4)", "Senior (65+)" |
| supportFocus | string? | Main care focus |
| communicationPreferences | string? | How they communicate best |
| triggers | string[] | Known triggers |
| calmingStrategies | string[] | What usually helps calm them |
| healthNotes | string? | Health context |
| whatHelps | string? | Summary of what helps |
| whatToAvoid | string? | Summary of what to avoid |

### incidents/{incidentId}
| Field | Type | Notes |
|-------|------|-------|
| title | string | Required, 1 line |
| description | string | Brief description |
| category | string | Enum: behavior, communication, emotion, health, routine, safety, other |
| intensity | int | 1-5 |
| whatHappened | string? | Detailed narrative |
| possibleTrigger | string? | What may have caused it |
| whatWasAlreadyTried | string? | Caregiver's attempts |
| desiredOutcome | string? | What good resolution looks like |
| tags | string[] | Optional tags |
| voiceNoteRef | string? | Storage URL |
| imageRef | string? | Storage URL |

### plans/{planId}
| Field | Type | Notes |
|-------|------|-------|
| summary | string | 1 sentence |
| whatMightBeHappening | string | AI explanation |
| whatToDoNow | string[] | Action steps |
| whatToAvoid | string[] | What not to do |
| messageDraft | string | Suggested words |
| followUpTasks | string[] | Next 24-48h tasks |
| reflectionPrompt | string | Post-plan reflection Q |
| escalationFlag | bool | Safety escalation |
| safetyNote | string? | Crisis note if needed |

### routines/{routineId}
| Field | Type | Notes |
|-------|------|-------|
| title | string | Required |
| frequency | string | Enum: daily, weekdays, weekends, weekly |
| steps | string[] | Ordered steps |
| isActive | bool | Active/archived |
| completionCount | int | Usage counter |
| lastUsedAt | timestamp? | Last completion |
| tags | string[] | Categorization |
| basedOnPlanId | string? | Source plan reference |

### checkins/{checkinId}
| Field | Type | Notes |
|-------|------|-------|
| planId | string | Source plan |
| didThisHelp | bool | Overall help |
| outcomeRating | int | 1-5 |
| stepsCompleted | string[] | Steps tried |
| stepsHelpedMost | string[] | Most effective steps |
| whatMadeItWorse | string? | What made it harder |
| shouldBecomeRoutine | bool | Routine flag |
| notes | string? | Open reflection |

---

## Security Rules Summary

All collections under `users/{uid}` require:
- `isAuthenticated()` — Firebase Auth required
- `isOwner(uid)` — Request UID must match document path UID

See `firestore.rules` for full rule definitions.

---

## Indexes

See `firestore.indexes.json`.

Key composite indexes:
- incidents: `profileId ASC, createdAt DESC`
- plans: `profileId ASC, createdAt DESC`
- checkins: `planId ASC, createdAt DESC`
- insights: `profileId ASC, weekStart DESC`
- messages: `timestamp ASC`

---

## Migration Notes

### Legacy `history` collection
`users/{uid}/history/{id}` is a flat collection created during Phase 2 migration. Plans saved before `profileId` integration use this path. The `home/pages/home.dart` no longer reads from it. New plans are saved to `users/{uid}/profiles/{profileId}/plans/{planId}`.

The legacy bridge write in `results.dart` persists for backwards compatibility when `profileId` is empty.

### Future migration
Run a one-time script to copy `history` documents to the appropriate `profiles/.../plans/` paths once all users have at least one profile.
