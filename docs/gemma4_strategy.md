# Gemma 4 Strategy

## Why Gemma 4

Crucue uses Gemma 4 as its primary AI model family for three reasons:

1. **Quality for structured tasks.** The 26B Mixture-of-Experts architecture delivers strong reasoning quality with efficient inference — well-suited for generating structured care plans, extracting incident context, and producing grounded chat responses.

2. **Privacy-aligned on-device path.** Gemma 4's E2B and E4B edge variants (2B and 4B parameters) are designed for on-device inference via LiteRT-LM and Android AICore. This aligns with Crucue's core privacy promise: care data doesn't need to leave the device.

3. **Structured output support.** Gemma 4 via the Gemini API supports `responseMimeType: "application/json"` with `responseJsonSchema`. Crucue uses that for **plans, voice extraction, weekly cloud summaries, and routine suggestions**. **Grounded chat** uses the same model but returns **plain text** (see *Grounded chat* below). **`transcribeShortClip`** does not call Gemma (Speech-to-Text only). Optional **on-device weekly** summaries use `flutter_gemma` with **prompted JSON** parsed in Dart.

---

## SDK: `@google/genai` (current standard)

All Cloud Functions use the **`@google/genai`** package — Google's current unified SDK (v1.50.0, April 2026) that replaces the deprecated `@google/generative-ai`:

```typescript
import { GoogleGenAI } from "@google/genai";
import { gemma4BaseSampling, GEMMA4_TEMP_SUPPORT_PLAN } from "./genai-sampling";

const ai = new GoogleGenAI({ apiKey });

const response = await ai.models.generateContent({
  model: "gemma-4-26b-a4b-it",
  contents: prompt,
  config: {
    ...gemma4BaseSampling({
      temperature: GEMMA4_TEMP_SUPPORT_PLAN,
      maxOutputTokens: 1024,
    }),
    responseMimeType: "application/json",
    responseJsonSchema: SUPPORT_PLAN_SCHEMA,
  },
});

const text = response.text ?? "";
```

Shared sampling constants live in [`functions/src/ai/genai-sampling.ts`](../functions/src/ai/genai-sampling.ts).

**Key API differences from the old SDK:**

| Old `@google/generative-ai` | New `@google/genai` |
|-----------------------------|---------------------|
| `new GoogleGenerativeAI(key)` | `new GoogleGenAI({ apiKey: key })` |
| `.getGenerativeModel({ model, generationConfig })` | `.models.generateContent({ model, contents, config })` |
| `generationConfig.responseSchema` + `// @ts-ignore` | `config.responseJsonSchema` (properly typed) |
| `result.response.text().trim()` | `response.text` |

---

## Model identifiers

| ID | Type | Params | Use case | Status |
|----|------|--------|----------|--------|
| `gemma-4-26b-a4b-it` | Remote (default) | 26B MoE (~4B activated per call) | Production default — all features | **Active** |
| `gemma-4-31b-it` | Remote (premium) | 31B dense | Optional: set `GEMMA4_MODEL` secret to evaluate quality/latency vs 26B | **Opt-in** (same code path as default) |
| `gemma-4-e2b-it` | On-device (fast) | 2B | Optional weights via **flutter_gemma** (weekly insight path) | **User-downloaded weights** |
| `gemma-4-e4b-it` | On-device (quality) | 4B | Same stack, larger weights | **Planned** |
| Native LiteRT / AICore | Platform bridge | — | Future full on-device loop | **MethodChannel scaffold only** (not wired as primary engine) |

---

## How each operation uses Gemma 4

### Support plan generation

**Model:** `GEMMA4_MODEL` secret or `gemma-4-26b-a4b-it` default  
**Sampling:** `temperature` 0.7; **`topP` 0.95** and **`topK` 64** (Gemma 4 model card defaults) via `gemma4BaseSampling()`  
**Schema:** `SUPPORT_PLAN_SCHEMA` via `config.responseJsonSchema`

Output fields: `summary`, `what_might_be_happening`, `what_to_do_now[]`, `what_to_avoid[]`, `message_draft`, `follow_up_tasks[]`, `reflection_prompt`, `escalation_flag`, `safety_note`

Cloud Functions log `generateSupportPlan: model=... ms=...` for latency comparison (e.g. when testing `gemma-4-31b-it`).

### Incident extraction from voice

**Model:** same as above  
**Sampling:** temperature **0.3**; `topP` / `topK` as above  
**Schema:** `VOICE_INCIDENT_SCHEMA` via `config.responseJsonSchema`

Input: Google Cloud Speech-to-Text transcript  
Output: `incident_title`, `incident_category`, `intensity`, `possible_trigger`, `what_user_already_tried`, `desired_outcome`, `safety_flag`, `confidence`

Gemma 4 handles text understanding only — audio transcription uses Google Cloud Speech-to-Text REST API.

### Grounded chat

**Model:** same as above  
**Sampling:** temperature **0.8**; `topP` / `topK` as above  
**Schema:** None (conversational text output)

Context includes: profile summary, active plan, last 3 check-ins, conversation history.

### Weekly insight summary

**Model:** same as above  
**Sampling:** temperature **0.6**; `topP` / `topK` as above  
**Schema:** `INSIGHT_SCHEMA` via `config.responseJsonSchema`

Output: `summary`, `patterns[]`, `whatWorked[]`, `suggestions[]`

### Routine suggestion (reflection → routine)

**Model:** same as above  
**Sampling:** temperature **0.4**; `topP` / `topK` as above  
**Schema:** `ROUTINE_SUGGESTION_SCHEMA` via `config.responseJsonSchema`

Callable: `suggestRoutineFromReflection`

---

## Persona policies

Each of 9 persona types has a policy pack that configures Gemma 4's behavior:

| Policy field | Effect |
|-------------|--------|
| `toneGuidance` | Injected into system prompt |
| `suggestionTypes` | Focus areas for plan generation |
| `safetyBoundaries` | What triggers escalation for this persona |
| `messageDraftStyle` | Communication style for the message draft |
| `routineExamples` | Seed examples for routine suggestion |

The global safety preamble is always prepended regardless of persona policy.

Persona policies are defined in:
- Dart: `lib/shared/persona_policies.dart`
- TypeScript: `backend/ai-gateway/src/policies/persona-policies.ts`

---

## Structured output approach

Crucue uses `config.responseJsonSchema` to enforce JSON output at the model level:

1. Prompts ask for a single JSON object and **do not duplicate** the full schema (per Google structured output guidance)
2. Property `description` strings in the schemas guide field semantics
3. `responseJsonSchema` enforces shape at the API
4. The server parses JSON; on failure, typed fallbacks apply where implemented

This is documented in [`docs/gemma4_function_calling.md`](gemma4_function_calling.md).

---

## Safety and validation

Every Gemma 4 call is preceded by the global safety preamble (defined in `functions/src/ai/safety.ts`):

- No impersonation of licensed professionals
- Emergency safety resources required when `escalation_flag: true`
- No diagnosis or clinical recommendations
- All suggestions are supportive guidance only

The `checkSafety()` function scans input text for crisis keywords before the AI call. If triggered, it bypasses Gemma 4 entirely and returns a crisis response directly.

---

## Temperature calibration

The Gemma 4 model card recommends **temperature 1.0** with **top_p 0.95** and **top_k 64** as a general-purpose default. Crucue uses the **same top_p and top_k** on every call (`functions/src/ai/genai-sampling.ts`) but **lower temperatures** for JSON-heavy tasks so extraction and care plans stay consistent; chat uses a higher temperature for natural wording.

| Task | Temperature | top_p / top_k | Rationale |
|------|-------------|---------------|-----------|
| Incident extraction | 0.3 | 0.95 / 64 | Deterministic field extraction from transcript |
| Routine suggestion | 0.4 | 0.95 / 64 | Structured list, minimal variation |
| Weekly insight | 0.6 | 0.95 / 64 | Analytical summary, still consistent |
| Support plan | 0.7 | 0.95 / 64 | Structured JSON with empathetic language |
| Chat | 0.8 | 0.95 / 64 | Natural follow-up; no JSON schema |

---

## Evaluating `gemma-4-31b-it` (optional)

The default remote model is **`gemma-4-26b-a4b-it`**. To compare the **31B dense** instruction-tuned model:

1. Set Firebase secret **`GEMMA4_MODEL`** to `gemma-4-31b-it` (same callable code path).
2. Deploy functions and run the same flows (support plan, voice, chat).
3. Compare **latency** in Cloud Logging (`generateSupportPlan: ... ms=...` and sibling log lines) and **subjective quality** of plans.

Revert the secret to `gemma-4-26b-a4b-it` for production if cost or latency is higher than you want.

---

## Current implementation vs roadmap

| Feature | Current | Roadmap |
|---------|---------|---------|
| Remote model | `gemma-4-26b-a4b-it` via Cloud Functions | Same via Cloud Run Gateway (Vertex AI) |
| SDK | `@google/genai` v1.50.0 | Same |
| On-device model | Native channel stubs, no weights | `gemma-4-e2b-it` via LiteRT-LM / AICore |
| Premium model | Opt-in via `GEMMA4_MODEL` | `gemma-4-31b-it` for A/B or premium tier |
| Routine suggestion | Callable `suggestRoutineFromReflection` (GenAI API) | Optional gateway `POST /api/v1/suggest-routine` (Vertex) |
| Structured output | `responseJsonSchema` + JSON.parse fallback | Same |
