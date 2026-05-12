# Crucue AI Architecture

## Principles

1. **No API keys in client code** — All Gemma 4 calls go through Firebase Cloud Functions
2. **One shared engine** — Single Gemma 4 model, persona variation through policy packs
3. **Structured outputs** — All AI responses are strongly typed JSON
4. **Safe by default** — Safety rules apply on every request, cannot be disabled
5. **Grounded context** — Chat is grounded in profile, plan, and reflections — not generic

---

## AI Pipeline

```
Flutter app
  └─► CloudFunctionsService (lib/core/services/cloud_functions_service.dart)
        └─► PersonaPolicy.forType(personaType).toMap() → policyOverrides
        └─► Firebase Callable Function (functions/src/ai/)
              ├─► Load profile from Firestore (if profileId provided)
              ├─► Load incident from Firestore (if incidentId provided)
              ├─► Load recent check-ins (for chat grounding)
              ├─► Build prompt (prompts.ts)
              │     ├─► SAFETY_SYSTEM (constant, always applied)
              │     ├─► Persona policy block (from policyOverrides)
              │     ├─► Profile context block
              │     ├─► Incident context block (new fields)
              │     └─► Output format specification
              ├─► Safety pre-check (safety.ts — regex on user input)
              ├─► Gemma 4 27B API
              ├─► Parse JSON response
              ├─► Safety post-check (safety.ts — on AI output)
              ├─► Persist to Firestore if profileId provided
              └─► Return to Flutter
```

---

## Functions

### `generateSupportPlan`

**Input:**
```typescript
{
  profileId?: string;
  incidentId?: string;
  profileData?: ProfileData;
  challenges?: string[];
  personaData?: Record<string, unknown>;
  incidentContext?: {        // Extended incident fields
    whatHappened?: string;
    possibleTrigger?: string;
    whatWasAlreadyTried?: string;
    desiredOutcome?: string;
  };
  policyOverrides?: PersonaPolicyOverrides;
}
```

**Output (SupportPlanOutput):**
```typescript
{
  summary: string;
  what_might_be_happening: string;
  what_to_do_now: string[];
  what_to_avoid: string[];
  message_draft: string;
  follow_up_tasks: string[];
  reflection_prompt: string;
  escalation_flag: boolean;
  safety_note: string | null;
  planId: string;            // Firestore ID if persisted
}
```

**Persists to:** `users/{uid}/profiles/{profileId}/plans/{planId}`

---

### `chatOnPlan`

**Input:**
```typescript
{
  profileId: string;
  planId?: string;
  userMessage: string;
  threadId?: string;
  history?: Array<{role: "user"|"assistant"; content: string}>;
  policyOverrides?: PersonaPolicyOverrides;
}
```

**Context loaded from Firestore:**
- Profile document (name, relationship, whatHelps, whatToAvoid)
- Plan summary (if planId provided)
- Last 3 check-ins (stepsHelpedMost, whatMadeItWorse) — reflection grounding

**Output:** `{ response: string, escalated: boolean }`

**Persists to:** `users/{uid}/chatThreads/{threadId}/messages/`

---

### `summarizePatterns`

**Input:** `{ profileId: string, weekStart?: string }`

**Loads from Firestore:**
- Incidents created in the week window
- Plans created in the week window
- Check-ins created in the week window

**Output:**
```json
{
  "summary": "string",
  "patterns": ["string"],
  "whatWorked": ["string"],
  "suggestions": ["string"]
}
```

**Persists to:** `users/{uid}/profiles/{profileId}/insights/{insightId}`

---

## PersonaPolicy System

Each of the 9 persona types has a static policy pack (`lib/shared/persona_policies.dart`):

| Field | Purpose |
|-------|---------|
| `toneGuidance` | How the AI should speak for this relationship type |
| `suggestionTypes` | Priority categories of suggestions |
| `safetyBoundaries` | Specific escalation triggers for this persona |
| `escalationThreshold` | `"medium"`, `"lower"`, `"highest"`, `"high-sensitivity"` |
| `messageDraftStyle` | How to phrase the suggested message to the loved one |
| `routineExamples` | Example routines to mention in plans |

The Flutter app serializes the policy via `PersonaPolicy.forType(type.name).toMap()` and passes it as `policyOverrides` in the callable. The Cloud Function injects it into the Gemma 4 system prompt.

**This is configuration, not roleplay.** The AI uses one shared engine — the policy adjusts tone and behaviour, it does not change the AI's identity.

---

## Safety Architecture

### Input Safety (safety.ts)
Pattern matching on user-submitted text before calling Gemma 4:
- Self-harm patterns
- Harm to others patterns
- Crisis keywords
- Abuse or violence patterns

If triggered: returns crisis response immediately without calling Gemma 4.

### Output Safety (safety.ts)
Same pattern matching on Gemma 4 output. If triggered: overrides with crisis response.

### Escalation Flag
When AI output contains certain risk patterns, `escalation_flag: true` is set. The Flutter app renders a visible `_SafetyBanner` widget.

### Crisis Resources
Hardcoded in `safety.ts`:
- 988 Suicide & Crisis Lifeline (call or text)
- Crisis Text Line (text HOME to 741741)
- Emergency services (911)

### Persona-Specific Thresholds
- `myself` type: highest sensitivity (self-harm risk)
- `baby` type: high-sensitivity (child safety)
- `teenager` type: lower threshold (teens may minimize distress)

---

## Fallback / Demo Mode

`CloudFunctionsService` in Flutter has a built-in demo plan fallback. When the Cloud Function is unavailable (network, not deployed), it returns a realistic pre-built `SupportPlan` based on the persona type and persona policy's routine examples.

This means the app is fully demonstrable without deployed Cloud Functions.

---

## Configuration

**API Key:** `GEMMA4_API_KEY` — stored in Firebase Secrets Manager
```bash
firebase functions:secrets:set GEMMA4_API_KEY
```

**Model:** `GEMMA4_MODEL` — defaults to `gemma-4-27b`

**Deployment:**
```bash
cd functions && npm install && npm run build
firebase deploy --only functions
```
