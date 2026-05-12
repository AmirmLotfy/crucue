# Crucue Feature Slice 02 — Caregiving Vertical

## Summary

This feature slice builds the complete caregiving product loop:

```
Profile → Log Incident → Get Support Plan → Reflect → Save Routine → Chat → Weekly Insights
```

Everything is wired together, stored in Firestore, and driven by persona-specific AI policies.

---

## What Was Built

### 1. PersonaType Expansion (9 types)
`lib/views/select_persona.dart`

Expanded from 5 to 9 MVP persona types:
- child, teenager, baby
- parent, partner, sibling, friend
- pet, myself

Each type has: label, description, icon (Material), color, policyKey.

Deprioritized (not shown in main flow): colleague, customer, neighbor, teacher.

### 2. PersonaPolicy System
`lib/shared/persona_policies.dart`

One policy pack per persona type. Fields:
- `toneGuidance` — how the AI should speak for this relationship
- `suggestionTypes` — categories of suggestions to prioritize
- `safetyBoundaries` — specific escalation rules
- `escalationThreshold` — sensitivity level (higher for myself/baby)
- `messageDraftStyle` — how to phrase the suggested message
- `routineExamples` — example routines for this persona type

Policies are serialized and passed to Cloud Functions as `policyOverrides`.

### 3. Model Expansions

**Incident** — added 4 context fields:
- `whatHappened` (detailed narrative)
- `possibleTrigger`
- `whatWasAlreadyTried`
- `desiredOutcome`

**Routine** — added 6 fields:
- `basedOnPlanId`, `basedOnIncidentId`
- `tags`, `lastUsedAt`, `reminders`
- `completionCount`

**CheckIn** — added 4 fields:
- `stepsHelpedMost`
- `whatMadeItWorse`
- `shouldBecomeRoutine`
- `outcomeRating` (1-5)

### 4. Profile Detail Hub
`lib/features/profiles/presentation/profile_detail_screen.dart`

Central screen after selecting a profile. Contains:
- Profile header with relationship type and support focus
- Quick action row: Log Challenge, Chat, My Routines, Weekly Insights
- Recent incidents feed (last 3)
- Recent support plans (last 3, with "Reflect" link)
- Active routines preview

### 5. Enhanced Incident Logging
`lib/features/incidents/presentation/add_incident_screen.dart`

Full incident logging with:
- Title (required)
- Brief description
- Category chips (behavior, communication, emotion, health, routine, safety, other)
- Intensity slider (1-5 with labels)
- Expandable "Add more context" section (trigger, already tried, desired outcome, detailed narrative)
- Voice note and photo attachment placeholders
- "Save & Get Support Plan" CTA

### 6. Connected Support Plan
`lib/views/results.dart`

Now accepts `profileId` and `incidentId`. Passes persona policy to Cloud Function. Bottom action bar with three options:
- "Continue Chat" → ChatView with profile/plan context
- "Reflect" → CheckInScreen
- "Back to Home"

### 7. Enhanced Reflection Flow
`lib/features/plans/presentation/checkin_screen.dart`

Full reflection screen with:
- Did it help? (yes/no)
- Outcome rating (1-5 slider)
- Steps tried (checkbox list)
- Steps that helped most (from tried steps)
- What made it harder (text)
- General notes (text)
- Reflection prompt from AI plan
- "Save as routine?" toggle (navigates to SaveAsRoutineScreen on save)

### 8. Routine Builder
Three new screens + repository:
- `save_as_routine_screen.dart` — create routine with title, frequency, draggable steps (pre-filled from plan)
- `routines_list_screen.dart` — view all routines for a profile, active/archived grouping, completion stats
- `routine_detail_screen.dart` — step-by-step routine player with completion tracking, mark-as-done, archive
- `routines_repository.dart` — Riverpod repository, `routinesProvider`, `activeRoutinesProvider`

### 9. Grounded Chat
`lib/views/chat/model.dart`, `view_model.dart`, `view.dart`

- Chat now accepts `profileId`, `planId`, `personaTypeKey`
- Creates Firestore thread on first message (persists conversation)
- Persists user and AI messages to Firestore
- Passes persona policy key to `chatOnPlan` function
- `ChatViewModel.setContext()` stores context for all messages in the session

### 10. Weekly Insights
`lib/features/insights/presentation/weekly_insights_screen.dart`

- "Generate" button in header to call `summarizePatterns` Cloud Function
- Generate card with gradient header
- Insight cards: expandable summary + what worked, patterns, suggestions
- Empty state with generate CTA

### 11. Home Screen Rewired
`lib/views/home/pages/home.dart`, `view.dart`

- Now shows care profiles from Firestore (not legacy history)
- Quick "Log" shortcut on each profile card
- Profile list with navigation to ProfileDetailScreen
- Recent activity feed across first 2 profiles
- No-profile empty state with two CTAs

---

## Cloud Functions Updates

- `generateSupportPlan` now accepts `policyOverrides` and `incidentContext`
- `chatOnPlan` now loads last 3 check-ins for reflection-grounded context
- Both prompts inject persona policy into system message
- TypeScript compiles cleanly

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/shared/persona_policies.dart` | Persona-specific AI policy packs |
| `lib/features/profiles/presentation/profile_detail_screen.dart` | Profile hub |
| `lib/features/routines/data/routines_repository.dart` | Routines Riverpod repo |
| `lib/features/routines/presentation/save_as_routine_screen.dart` | Create routine |
| `lib/features/routines/presentation/routines_list_screen.dart` | List routines |
| `lib/features/routines/presentation/routine_detail_screen.dart` | Use a routine |
| `lib/views/tell_about_persona/components/teenager.dart` | Teen profile form |
| `lib/views/tell_about_persona/components/baby.dart` | Baby profile form |
| `lib/views/tell_about_persona/components/pet.dart` | Pet profile form |
| `lib/views/tell_about_persona/components/myself.dart` | Self-care form |
| `docs/crucue_feature_slice_02.md` | This document |
| `docs/crucue_ai_architecture.md` | AI pipeline docs |
| `docs/crucue_firestore_schema.md` | Schema docs |

---

## Files Modified

| File | What changed |
|------|-------------|
| `lib/shared/models/incident.dart` | +4 context fields, `toAIContext()` |
| `lib/shared/models/routine.dart` | +6 extended fields, `copyWith()`, frequency labels |
| `lib/shared/models/checkin.dart` | +4 reflection fields, `toAIContext()` |
| `lib/views/select_persona.dart` | 5 → 9 PersonaType values with full extensions |
| `lib/views/tell_about_persona/view.dart` | All 9 types handled, new fields in PersonaModelData |
| `lib/views/challenges.dart` | +4 new challenge category sets |
| `lib/views/results.dart` | profileId/incidentId, persona policy, action bar |
| `lib/views/chat/view.dart` | personaTypeKey param |
| `lib/views/chat/model.dart` | Firestore thread persistence, persona policy |
| `lib/views/chat/view_model.dart` | personaTypeKey context |
| `lib/views/home/view.dart` | FAB → CreateProfileScreen |
| `lib/views/home/pages/home.dart` | Profile-based feed, real-time Firestore |
| `lib/core/services/firestore_service.dart` | +watchRecentIncidents, +watchRecentPlans, +deleteRoutine, +markRoutineUsed, +getRoutine, +updateChatThread, +getRecentCheckInsOnce |
| `lib/core/services/cloud_functions_service.dart` | +policyOverrides param, +incidentContext, +personaTypeKey |
| `lib/features/incidents/presentation/add_incident_screen.dart` | Full enhancement |
| `lib/features/plans/presentation/checkin_screen.dart` | Full enhancement |
| `lib/features/insights/presentation/weekly_insights_screen.dart` | Generate button, better cards |
| `functions/src/ai/prompts.ts` | PersonaPolicyOverrides type, policy injection |
| `functions/src/ai/generate-support-plan.ts` | policyOverrides + incidentContext |
| `functions/src/ai/chat-on-plan.ts` | Load check-ins for grounding, policyOverrides |

---

## Legacy Files That Can Be Removed/Deprecated

| File | Reason |
|------|--------|
| `lib/views/home/pages/home.dart` (old version) | Replaced — now uses Firestore profiles feed |
| Legacy `history` Firestore collection writes | Bridge still works but can be migrated to profile-scoped plans |
| `lib/features/profiles/presentation/profile_list_screen.dart` | `ProfileDetailScreen` + home page now cover this flow |

---

## Next Steps

- Replace `SelectPersonaView` flow entirely with direct profile creation + incident logging from ProfileDetailScreen
- Add notification reminders for routines (FCM)
- Streak indicator for daily check-ins
- Privacy/trust screen walkthrough
- Voice note recording (platform channel or package)
