# Crucue — Private AI Support for Caregivers, Grounded in Gemma 4

> Flutter + Firebase app that turns difficult caregiving moments into structured support plans, grounded follow-up chat, and routines — using **Gemma 4** on Google’s **Gemini Developer API** (`@google/genai`) for server-side inference, plus optional **flutter_gemma** for on-device weekly summaries when weights are installed. **Intended hackathon tracks:** Main; Impact — Health & Sciences; Safety & Trust (select whatever the Kaggle form allows for your submission).

---

## The problem

Millions of **unpaid family caregivers** juggle stress, logistics, and emotional load with little structured help in the moment. Generic assistants rarely stay anchored to **this person, this relationship, and what already worked**. Caregivers need calm, **actionable** guidance and a system that respects that the underlying facts are **private**.

---

## The product (what actually ships)

Crucue is a **Firebase-backed Flutter app** (project **`crucueapp`**) built around one loop:

1. **Log the moment (voice or text).** Voice audio is uploaded to **Cloud Storage**, transcribed with the **Google Cloud Speech-to-Text** REST API (`en-US`), then **Gemma 4** fills **typed incident fields** using **`responseJsonSchema`**. The function **deletes the Storage object after processing** (best-effort; failures are logged). If Gemma extraction fails, a **heuristic fallback** still returns structured fields.

2. **Structured support plan.** **Gemma 4** returns JSON matching **`SUPPORT_PLAN_SCHEMA`**: summary, what might be happening, what to do now, what to avoid, message draft, follow-up tasks, reflection prompt, escalation flag, safety note. The function merges **keyword-based safety checks** on user input and plan text (`applySafetyToResponse`); **the model is still invoked** so this path is not a full “block inference” gate.

3. **Listen.** **flutter_tts** reads the plan (platform TTS).

4. **Follow-up chat.** **Gemma 4** returns **plain text** (no `responseJsonSchema` on this callable). **High-risk user messages** skip the model and return a fixed crisis-resources reply. **High-risk model output** is replaced with that same crisis reply. Last **three** check-ins (when present) are merged into the plan summary string for grounding.

5. **Reflect → routines.** Check-ins in Firestore; optional **AI routine suggestion** via **`suggestRoutineFromReflection`** (schema-enforced JSON). **High-risk reflection text blocks** the call before inference.

6. **Weekly insights.** **`summarizePatterns`** uses **`responseJsonSchema`** (`INSIGHT_SCHEMA`). Alternatively, **`HybridGemmaEngine`** can run **`summarizeWeeklyWithFlutterGemma`**: a **prompted JSON shape** parsed in Dart — **not** the Cloud `responseJsonSchema` path — when **`FeatureFlags.localWeeklyInsightWithFlutterGemma`** is true and **`FlutterGemma.hasActiveModel()`** is true; otherwise it falls back to the remote callable.

**Profiles:** Firestore **`CareRelationship`** enum has **five** values (child, parent, partner, sibling, familyMember). **Nine** distinct **`PersonaPolicy`** packs (child, teenager, baby, parent, partner, sibling, friend, pet, myself) tune prompts via `policyOverrides`.

---

## How we used Gemma 4 (precise)

| Callable / path | Gemma? | Structured output |
|-----------------|--------|---------------------|
| `generateSupportPlan` | Yes | **`responseJsonSchema`** (`SUPPORT_PLAN_SCHEMA`) |
| `processVoiceIncident` (extract step) | Yes | **`responseJsonSchema`** (`VOICE_INCIDENT_SCHEMA`) |
| `summarizePatterns` | Yes | **`responseJsonSchema`** (`INSIGHT_SCHEMA`) |
| `suggestRoutineFromReflection` | Yes | **`responseJsonSchema`** (`ROUTINE_SUGGESTION_SCHEMA`) |
| `chatOnPlan` | Yes | **Free text** + safety filters |
| `transcribeShortClip` | **No** | STT only (same file as voice pipeline) |
| On-device weekly (`flutter_gemma`) | Yes (local runtime) | Prompt asks for JSON; **parsed in app code** |

**Secrets:** `GEMMA4_API_KEY` and optional **`GEMMA4_MODEL`** (defaults to **`gemma-4-26b-a4b-it`** in code) are **Firebase Secrets**, not embedded in the APK.

**Auth / abuse surface (facts):** All callables require **`request.auth`**. **`enforceAppCheck` is `false`** on these functions in the current tree so a **sideloaded release APK** can call them without Play Integrity / App Check attestation setup — tighten this before a wide production launch.

---

## Architecture (one paragraph)

**Flutter** → **Firebase Auth**, **Firestore**, **Storage**, **FCM** → **Cloud Functions** (Node.js 22, `@google/genai`) → **Gemma 4** on the Gemini API. **Seven** HTTPS callables are exported from **`functions/src/index.ts`**. **`sendTestPushNotification`** sends a test FCM notification to tokens under **`users/{uid}/devices/*`** (not a model call).

Demo page (APK, diagram, video slot): **https://www.crucue.com/hackathon**  
Public code: **https://github.com/AmirmLotfy/crucue**

---

## Safety & Trust (what the code does)

- **Keyword regex gate** (`functions/src/ai/safety.ts`) on user/reflection text; **chat** and **routine suggestion** can **avoid** Gemma on high-risk input; **support plans** still generate then **override** flags/notes when input matched high risk.
- **Schema-constrained** JSON for plans, extraction, weekly cloud summary, and routine suggestion — fewer “surprise shapes” than ad-hoc parsing for those endpoints.
- **Owner-scoped Firestore / Storage rules** (ship in repo); voice audio deletion after STT as above.
- **Not** a licensed medical, therapeutic, or legal service — reflected in product positioning.

We do **not** operate a separate fine-tuning pipeline in this repo; “no training on user data” here means **we are not using your Firestore exports to train our own model weights** — while **inference** necessarily sends prompt content to **Google’s APIs** under their terms.

---

## What’s next (scoped, real)

**`backend/ai-gateway/`** is an **undeployed** Express scaffold. **Native `MethodChannel` plugins** exist for a future **LiteRT-LM / AICore** path; **weekly insights** today use **flutter_gemma**, not those channels. Multilingual STT/UI (`en-US` today) and tool-calling are future work.

---

## Try it

- **Demo hub:** https://www.crucue.com/hackathon  
- **APK:** linked there (Android). Install permissions as prompted; **microphone** for voice.  
- **Repo:** https://github.com/AmirmLotfy/crucue  
- **Video:** record a **public** ≤3 min demo; put the YouTube ID in the **`Crucue-web`** `/hackathon` page when ready.  
- **Competition:** https://www.kaggle.com/competitions/gemma-4-good-hackathon — paste this writeup, attach URLs, upload cover art from **`docs/kaggle_cover.png`**, and confirm word count against the current Kaggle limit before submitting.
