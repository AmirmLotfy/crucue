# Gemma 4 Voice Strategy — Crucue

## Hackathon Alignment

Crucue is a Gemma 4 Good Hackathon submission. The voice pipeline is designed to showcase Gemma 4's reasoning capability in a caregiving context — not just as a chatbot, but as a structured reasoning engine that extracts meaning from spoken caregiver observations.

---

## Why Two-Step (STT + Gemma 4)?

Gemma 4 is a text model. Audio transcription requires a dedicated speech model. Using Google Cloud Speech-to-Text for transcription and Gemma 4 for reasoning is the technically correct architecture:

| Step | Tool | Why |
|------|------|-----|
| Audio → Text | Google Cloud STT | Specialized for speech; handles accents, background noise, medical/caregiving vocabulary |
| Text → Structured Incident | Gemma 4 | Reasoning over the transcript; extracts intent, infers missing context, applies care policy |
| Structured Incident → Support Plan | Gemma 4 | Same reasoning engine; grounded in profile context, persona policy, past reflections |

This is honest about what Gemma 4 does well and what it doesn't.

---

## Gemma 4's Role in Voice

### 1. Incident extraction from transcript (`buildExtractIncidentPrompt`)

Gemma 4 reads the caregiver's spoken description and produces:
- A cleaned, structured summary
- Incident title, category, and intensity
- Likely trigger (inferred from language)
- What the caregiver already tried
- Desired outcome
- Safety flag if concerning content detected

This is not a simple NLP extraction — Gemma 4 applies caregiving context and reasoning to infer what wasn't explicitly said.

### 2. Support plan generation (`buildSupportPlanPrompt`)

The extracted incident feeds directly into `generateSupportPlan`. The voice pipeline produces richer input than manual form entry because it captures the caregiver's own words, tone, and framing.

### 3. Grounded follow-up reasoning (`buildChatPrompt`)

Voice chat input (short transcribed clips) feeds into the same `chatOnPlan` function. Gemma 4 reasons in the context of the profile, plan, and recent reflections — even when the input arrives via voice rather than typing.

---

## Persona Policy Integration

Voice prompts respect the same persona policy packs as text prompts:

- Baby, teenager, and parent personas have persona-specific extraction guidance
- Safety thresholds vary by persona (e.g. `myself` persona has highest sensitivity)
- Tone guidance affects how the extracted summary is phrased

The `policyOverrides` are passed from `CloudFunctionsService` to the `processVoiceIncident` function.

---

## Structured Output Design

Voice extraction uses `VOICE_INCIDENT_SCHEMA` passed as `generationConfig.responseSchema`:

```json
{
  "cleaned_summary": "string",
  "incident_title": "string (max 60 chars)",
  "incident_category": "behavior|communication|emotion|health|routine|safety|other",
  "intensity": "1-5 integer",
  "possible_trigger": "string or null",
  "what_user_already_tried": "string or null",
  "desired_outcome": "string or null",
  "key_entities": ["array of strings"],
  "confidence": "0.0-1.0 float",
  "safety_flag": "boolean"
}
```

The `confidence` field is shown to the user in `TranscriptReviewScreen` — this transparency helps caregivers understand when to correct Gemma 4's extraction.

---

## Calibration — Temperature Settings

| Function | Temperature | Reason |
|----------|-------------|--------|
| `processVoiceIncident` | 0.3 | Low — deterministic extraction from specific transcript |
| `generateSupportPlan` | 0.7 | Medium — creative but grounded support advice |
| `chatOnPlan` | 0.8 | Higher — more natural conversational response |
| `summarizePatterns` | 0.6 | Balanced — factual patterns + warm framing |

---

## Safety in Voice

Voice input introduces additional safety surface compared to typed text:

1. **Input safety check** — `checkSafety()` runs on the raw transcript before Gemma 4 processes it
2. **`safety_flag` in extraction** — Gemma 4 is instructed to flag concerning content
3. **`safetyFlag` stored on VoiceNote** — persisted in Firestore for audit
4. **Escalation banner** — shown in `TranscriptReviewScreen` if `safety_flag = true`
5. **Crisis resources** — `SAFETY_SYSTEM` prompt is always prepended, containing crisis line info

---

## Future Path: Gemma 4 Multimodal Audio

When Gemma 4 gains multimodal audio input capability (direct audio understanding), the pipeline can be simplified:

```
Current: Audio → STT → Transcript → Gemma 4 text reasoning
Future:  Audio → Gemma 4 multimodal → Structured JSON
```

The `AiProvider` interface has `processVoiceIncident` as an abstract method. When multimodal is available, `Gemma4BackendProvider` can be updated to call a new Cloud Function that passes raw audio to the model — without changing any Flutter UI code.

The `Gemma4EdgeProvider` placeholder is also designed to support this future capability on-device.
