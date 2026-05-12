# Gemma 4 Structured Output in Crucue

## Approach

Crucue does not use automatic tool execution or function calling. It uses **structured prompt-to-JSON output** with explicit schemas — the most compatible and reliable approach for production Gemma 4 usage via the `@google/genai` SDK.

The flow for every AI feature:

```
1. Caregiver action (Flutter)
      │
      ▼
2. AiEngine.generateSupportPlan() / chatOnPlan() / summarizePatterns()
      │ (calls Firebase Callable Function via CloudFunctionsService)
      ▼
3. Cloud Function (Node.js 22 / TypeScript / @google/genai SDK)
      ├─ Load context from Firestore (profile, incident, check-ins)
      ├─ Apply persona policy overrides
      ├─ Build structured prompt with output schema embedded
      ├─ Call Gemma 4 via ai.models.generateContent({ config.responseJsonSchema })
      ├─ Parse and validate JSON response
      ├─ Run safety checks (pre and post)
      ├─ Persist result to Firestore
      └─ Return typed response to Flutter
      │
      ▼
4. Flutter renders structured plan (typed SupportPlan model)
```

---

## SDK: `@google/genai`

All Cloud Functions use the current Google Gen AI SDK:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey });

const response = await ai.models.generateContent({
  model: "gemma-4-26b-a4b-it",
  contents: prompt,
  config: {
    temperature: 0.7,
    maxOutputTokens: 1024,
    responseMimeType: "application/json",
    responseJsonSchema: SUPPORT_PLAN_SCHEMA,   // structured output
  },
});

const text = response.text ?? "";
const plan = JSON.parse(text);
```

**`@google/generative-ai` (old SDK) was deprecated and has been removed.** The `responseJsonSchema` field in `config` is the properly typed replacement for the old `generationConfig.responseSchema` pattern.

---

## Output Schemas

### Support Plan (`SUPPORT_PLAN_SCHEMA`)

Used by `generateSupportPlan` — passed as `config.responseJsonSchema`:

```json
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "what_might_be_happening": { "type": "string" },
    "what_to_do_now": { "type": "array", "items": { "type": "string" } },
    "what_to_avoid": { "type": "array", "items": { "type": "string" } },
    "message_draft": { "type": "string" },
    "follow_up_tasks": { "type": "array", "items": { "type": "string" } },
    "reflection_prompt": { "type": "string" },
    "escalation_flag": { "type": "boolean" },
    "safety_note": { "type": "string", "nullable": true }
  }
}
```

### Insight Schema (`INSIGHT_SCHEMA`)

Used by `summarizePatterns`:

```json
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "patterns": { "type": "array", "items": { "type": "string" } },
    "whatWorked": { "type": "array", "items": { "type": "string" } },
    "suggestions": { "type": "array", "items": { "type": "string" } }
  }
}
```

### Voice Incident Schema (`VOICE_INCIDENT_SCHEMA`)

Used by `processVoiceIncident`:

```json
{
  "type": "object",
  "properties": {
    "incident_title": { "type": "string" },
    "incident_category": { "type": "string" },
    "intensity": { "type": "number" },
    "possible_trigger": { "type": "string", "nullable": true },
    "what_user_already_tried": { "type": "string", "nullable": true },
    "desired_outcome": { "type": "string", "nullable": true },
    "safety_flag": { "type": "boolean" },
    "confidence": { "type": "number" }
  }
}
```

---

## Cloud Functions

### `generateSupportPlan`

**Input:**
```typescript
{
  profileId?: string;
  incidentId?: string;
  profileData?: ProfileData;
  challenges?: string[];
  incidentContext?: Record<string, unknown>;
  policyOverrides?: PersonaPolicyOverrides;
}
```

**Steps:**
1. Auth check (Firebase callable — uid required)
2. Load profile from Firestore if `profileId` provided
3. Load incident from Firestore if `incidentId` provided
4. Safety pre-check on user input text
5. Build structured prompt with policy pack injection
6. Call Gemma 4 via `ai.models.generateContent` with `responseJsonSchema: SUPPORT_PLAN_SCHEMA`
7. Parse JSON → `SupportPlanOutput`
8. Safety post-check; escalation flag override if triggered
9. Persist plan to `users/{uid}/profiles/{profileId}/plans/{planId}`
10. Return plan + `planId`

---

### `chatOnPlan`

**Steps:**
1. Auth check
2. Safety pre-check on `userMessage` (crisis response returned directly — no Gemma 4 call)
3. Load profile, plan summary, last 3 check-ins from Firestore for grounding
4. Build grounded chat prompt with policy overrides injected
5. Call Gemma 4 (text output, no `responseJsonSchema` for conversational response)
6. Safety post-check on response
7. Persist message pair to Firestore thread if `threadId` set
8. Return `{ response: string, escalated: boolean }`

---

### `summarizePatterns`

**Steps:**
1. Auth check
2. Load incidents, plans, check-ins for the week from Firestore (parallel)
3. Build summarization prompt
4. Call Gemma 4 with `responseJsonSchema: INSIGHT_SCHEMA`
5. Parse JSON → insight object
6. Persist to `users/{uid}/profiles/{profileId}/insights`
7. Return insight

---

### `processVoiceIncident`

**Steps:**
1. Auth check
2. Download audio from Firebase Storage
3. Call Google Cloud Speech-to-Text REST API → transcript
4. Call Gemma 4 with `responseJsonSchema: VOICE_INCIDENT_SCHEMA` → extracted incident fields
5. Update VoiceNote doc in Firestore (status, transcript, extractedIncident)
6. Delete audio from Storage
7. Return transcript + extracted fields

---

## Validation and Failure Handling

Every Cloud Function:
- Validates `JSON.parse` succeeds before using the response
- Has a typed fallback response that never fails (demo plan / fallback extraction)
- Logs structured errors via `functions.logger.error`
- Returns `HttpsError` with user-friendly message on hard failure
- Never returns raw model output directly — always parsed through typed interfaces

The Flutter `CloudFunctionsService` also has:
- `_buildDemoPlan()` — returns a realistic offline plan when the function is unreachable
- `_defaultChatResponse()` — returns a warm fallback when chat fails
- Both are persona-policy-aware for consistent behavior
