# Analytics Events

Crucue uses Firebase Analytics with typed event helpers defined in `lib/core/observability/analytics_events.dart`.

All events use snake_case names following Firebase Analytics conventions. Parameters are limited to string, number, or boolean values — no personally identifiable information is logged.

---

## Implementation

```dart
// lib/core/observability/analytics_events.dart
CrucueAnalytics.logIncidentLogged(category: 'behavior', intensity: 3);
CrucueAnalytics.logPlanGenerated(personaType: 'child', hasProfileId: true);
```

Errors are reported to Crashlytics:
```dart
CrucueAnalytics.recordError(e, StackTrace.current, reason: 'plan_generation_failed');
```

---

## Event reference

### Profile events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `profile_created` | `relationship: string` | User saves a new care profile |

---

### Incident events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `incident_logged` | `category: string`, `intensity: int`, `is_voice: bool` | Incident saved to Firestore |

**`category` values:** `behavior`, `communication`, `emotion`, `health`, `routine`, `safety`, `other`

---

### Plan events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `plan_generated` | `persona_type: string`, `has_profile: bool` | Gemma 4 returns a support plan |
| `plan_saved` | `persona_type: string` | User taps "Save plan" |
| `plan_tts_played` | — | User taps the TTS listen button |

---

### Chat events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `chat_message_sent` | `is_voice: bool` | Message sent to AI (voice or text) |

---

### Reflection events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `reflection_saved` | `did_help: bool`, `outcome_rating: int`, `became_routine: bool` | Check-in saved to Firestore |

---

### Routine events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `routine_created` | `frequency: string` | Routine saved to Firestore |
| `routine_used` | — | User marks a routine as used |

**`frequency` values:** `daily`, `weekdays`, `weekends`, `weekly`, `as-needed`

---

### Insight events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `insight_generated` | — | Weekly insight generation completes |

---

### Voice events

| Event | Parameters | When fired |
|-------|-----------|-----------|
| `voice_recording_started` | — | Recording sheet opens and recording begins |
| `voice_processing_completed` | `success: bool` | Voice processing pipeline finishes (success or error) |

---

## Planned events (not yet implemented)

| Event | Notes |
|-------|-------|
| `user_signed_up` | On first successful auth |
| `user_signed_in` | On subsequent sign-ins |
| `weekly_insight_viewed` | When insight screen is opened |
| `routine_detail_opened` | Routine engagement |
| `plan_detail_opened` | Plan engagement |
| `voice_note_uploaded` | After successful voice upload |

---

## Crashlytics events

Errors reported via `CrucueAnalytics.recordError()` appear in Firebase Crashlytics under non-fatal issues. Reasons logged include:

- `plan_generation_failed`
- `chat_send_failed`

Fatal errors are captured automatically via:
- `FlutterError.onError` → Flutter framework errors
- `PlatformDispatcher.instance.onError` → async/platform errors
- `runZonedGuarded` → zone errors

---

## Funnel analysis

Key conversion funnel using these events:

```
profile_created
  ↓
incident_logged
  ↓
plan_generated
  ↓
plan_saved
  ↓
reflection_saved
  ↓
routine_created  (if became_routine: true)
```

Drop-off between `incident_logged` → `plan_generated` indicates AI or network failures.
Drop-off between `plan_generated` → `plan_saved` indicates low plan quality or relevance.
