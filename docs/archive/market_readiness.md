# Market Readiness — Crucue

## ICP and Positioning

**Primary ICP:** Caregivers of children or adults with behavioral, developmental, or health challenges — feeling overwhelmed, under-supported, and wanting practical help without judgment.

**Positioning:** *Private AI support for caregivers.* Not a therapy app. Not a tracking app. A moment-by-moment companion that turns hard caregiving moments into actionable plans.

**Tone:** Calm, warm, practical, non-judgmental. Never clinical. Never manipulative.

---

## Retention Loop

```
Difficult moment
  ↓
Log it (voice or text)
  ↓
Get a support plan (Gemma 4)
  ↓
Follow the plan
  ↓
Reflect: what helped, what didn't?
  ↓
Save a routine if something worked
  ↓
Weekly insights: see patterns over time
  ↓
Better plans next time (context improves)
```

Each loop builds data that makes the next plan better. Routines and insights create habit.

---

## Privacy as a Market Differentiator

- Care notes and incident logs never leave the user's account
- Voice recordings deleted after transcription
- On-device AI mode (future) for zero-network inference
- No ads, no data selling, no anonymous research
- Delete account = delete all data, immediately

This is a hard positioning claim that most AI tools cannot make.

---

## Analytics Hooks (implemented)

Typed `CrucueAnalytics` events at:
- `profile_created`
- `incident_logged` (category, intensity, is_voice)
- `plan_generated` (persona_type, has_profile)
- `plan_saved`
- `plan_tts_played`
- `chat_message_sent` (is_voice)
- `reflection_saved` (did_help, outcome_rating, became_routine)
- `routine_created` (frequency)
- `insight_generated`
- `voice_recording_started`
- `voice_processing_completed`

These feed into Firebase Analytics for funnel analysis without personal data.

---

## Premium Expansion Path

The architecture supports premium tiers without breaking changes:

| Feature | Free | Premium (future) |
|---------|------|------------------|
| Care profiles | 2 | Unlimited |
| Saved plans | 10 | Unlimited |
| AI model quality | Standard (`gemma-4-26b-a4b-it`) | Premium (`gemma-4-31b-it`) |
| On-device privacy mode | — | Available on supported devices |
| Team/family sharing | — | Shared profile access |
| Export (PDF) | — | Weekly plan exports |

The `AiMode` and `RemoteGemma4Engine` switching is already wired for premium model routing.

---

## Market Launch Remaining

- [ ] App store descriptions finalized
- [ ] Screenshot set (5-8 per platform)
- [ ] Privacy policy hosted at `crucue.app/privacy`
- [ ] Terms hosted at `crucue.app/terms`
- [ ] Support email `support@crucue.app` active
- [ ] App Check initialized (prevent API abuse at scale)
- [ ] FCM push configured (for reflection reminders, weekly insights)
- [ ] Onboarding A/B test infrastructure
