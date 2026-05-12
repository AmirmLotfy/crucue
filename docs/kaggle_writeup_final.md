# Crucue — Private AI Support for the World's Caregivers, Grounded in Gemma 4

> A Flutter mobile app that turns the hardest caregiving moments into structured support plans, grounded follow-up, and routines that stick — powered by Gemma 4 structured outputs, a live voice pipeline, and a full reflection loop.

---

## The problem

There are an estimated 53 million unpaid caregivers in the United States alone. Parents of children with behavioral or developmental challenges. Adults caring for aging parents with dementia. Partners managing a spouse through chronic illness. Siblings coordinating care from a distance.

When a difficult moment happens — a refusal to take medication, an unexpected behavioral episode, a conversation that went wrong — most caregivers face it alone, with no structure and no support. Generic AI chat tools can offer general advice. What caregivers need is something more specific: a tool that knows who they're caring for, what has happened before in this relationship, what strategies help this particular person, and can give them a plan they can actually use right now.

This is intimate, private information. It must stay private. And it must be handled with care — because the caregiver is already exhausted, and the last thing they need is an AI tool that adds complexity instead of clarity.

---

## The product

Crucue is a deployed Flutter mobile app built around a simple caregiving support loop.

**1. Log the moment (voice or text).** The caregiver describes what happened. A voice note is transcribed by Google Cloud Speech-to-Text, then Gemma 4 extracts structured incident fields — what happened, the possible trigger, what was already tried, and the desired outcome — via `responseJsonSchema`. No text parsing; typed fields from the first call.

**2. Get a structured plan.** Gemma 4 generates a support plan grounded in the specific care profile and incident. The output is a typed JSON object enforced at the model level: a calm summary, concrete steps for right now, what to avoid, a message draft for the loved one, follow-up tasks, a reflection prompt, and an escalation flag if safety resources are needed.

**3. Listen to the plan.** Platform TTS reads the plan aloud. No extra API or cost. Useful when a caregiver can't hold a screen during a difficult situation.

**4. Grounded follow-up chat.** Chat with Crucue about the plan. Responses are anchored to the specific plan, care profile, and the last three check-ins — not generic chat. Voice input supported.

**5. Reflect and build routines.** After trying the plan, the caregiver logs what helped, rates the outcome, and saves effective strategies as reusable routines.

**6. Weekly insights.** Gemma 4 analyzes the week's incidents, plans, and reflections into patterns and suggestions. Cloud by default; an optional on-device path uses a small Gemma model via `flutter_gemma` for this screen only, when weights are installed.

Nine care profile types (child with ADHD, aging parent with memory issues, partner with chronic illness, and more) shape every prompt, plan, and safety boundary. All care data is owner-scoped in Firestore. Voice recordings are deleted after processing.

---

## How we used Gemma 4

Every AI call in Crucue uses Gemma 4's `responseJsonSchema` via the `@google/genai` SDK — Google's current unified SDK. There are no `@ts-ignore` hacks and no JSON parsing fragility. The model receives a schema and returns a typed object. This is the foundation of the app's reliability.

**1. Structured support plan generation.** The core call. Gemma 4 (`gemma-4-26b-a4b-it`, 26B MoE / 4B active parameters) receives the care profile, persona policy, incident fields, and recent reflections. The schema enforces six named output sections. The plan arrives shaped, not scraped. (See `functions/src/ai/generate-support-plan.ts`, `functions/src/ai/prompts.ts`)

**2. Voice incident extraction.** A 90-second voice note from a caregiver is transcribed by Google Cloud Speech-to-Text and then sent to Gemma 4 with a schema that extracts `possible_trigger`, `what_user_already_tried`, and `desired_outcome` as named typed fields. These are stored in Firestore and used to inform future plans. (See `functions/src/ai/process-voice-incident.ts`)

**3. Grounded chat.** The follow-up chat call sends the care profile, the full generated plan, and the last three check-in records as context with every message. Gemma 4 reasons over the specific situation. The schema includes a `crisis_detected` flag. (See `functions/src/ai/chat-on-plan.ts:114–121`)

**4. Dual-layer safety pipeline.** A keyword-based crisis pre-check short-circuits the model call before it runs — no inference cost on clearly unsafe inputs. Post-generation, the schema's `escalation_flag` drives a UI safety banner with links to crisis resources. No unsafe output reaches the app. (See `functions/src/ai/safety.ts:7–39`)

**5. Persona-policy prompt steering.** Nine care relationship types map to compact persona policies prepended to every prompt. These tune tone, suggestion style, safety thresholds, and message register — behavioral fine-tuning through structured prompting, not model training. (See `lib/shared/persona_policies.dart`)

**6. Hybrid on-device weekly insight.** The `HybridGemmaEngine` routes the weekly insights call to `flutter_gemma` (Gemma 4 E2B, ~2.6 GB) when the user has downloaded weights and enabled hybrid mode. This is the only AI call that can run entirely on-device, with no network traffic. The full caregiving support loop — plan, chat, voice — stays on hosted Gemma 4 for quality and safety. (See `lib/core/ai/hybrid_gemma_engine.dart:79–95`)

---

## Architecture

Flutter mobile app → Firebase Auth / Firestore / Storage / FCM → Firebase Cloud Functions (Node.js 22, `@google/genai` SDK) → Gemma 4 (`gemma-4-26b-a4b-it`).

Side branch (weekly insights only): Flutter ↔ `flutter_gemma` (on-device, Gemma 4 E2B, opt-in after weight download).

Five Cloud Functions deployed in the `crucueapp` Firebase project: `generateSupportPlan`, `chatOnPlan`, `summarizePatterns`, `processVoiceIncident`, `transcribeShortClip`. All callables require Firebase Auth and App Check. The Gemma 4 API key lives in Firebase Secret Manager — never in the mobile client.

Full architecture diagram and code references: https://www.crucue.com/hackathon

---

## Safety & Trust

Crucue's safety design is a generalizable pattern for any app using Gemma 4 in sensitive contexts.

**No API keys in the client.** All Gemma 4 calls run server-side in Cloud Functions. The `GEMMA4_API_KEY` lives in Firebase Secret Manager. Firebase Auth and App Check guard every callable.

**Pre-call crisis short-circuit.** Before any model inference, a keyword scan checks the input. Detected crisis language halts the AI call and returns a direct resource response immediately. No generation cost, no model exposure to extreme content.

**Schema-enforced safe outputs.** The `responseJsonSchema` in every callable means the model cannot return unstructured text. The `escalation_flag` field in the support plan schema drives a UI safety banner with crisis line links when true. The plan cannot omit the safety field — it is required by the schema.

**No training on user data.** Care data is owner-scoped in Firestore. Voice recordings are deleted server-side after transcription. No user data is used to train or fine-tune the model.

**On-device maximizes privacy.** When on-device mode is active for weekly insights, no data leaves the device for that AI call. The architecture is designed to extend this to the full caregiving loop as LiteRT-LM integration matures.

---

## What's next, honestly

Native LiteRT-LM inference via Android AICore and Apple's on-device framework is on the roadmap. Platform `MethodChannel` bridges are scaffolded on both Android and iOS; model weight delivery via Play Asset Delivery or On-Demand Resources is the remaining step. When complete, the full caregiving loop — plans, chat, voice extraction — could run entirely on-device.

The Vertex AI Cloud Run gateway is scaffolded in `backend/ai-gateway/` — authenticated REST endpoints, AJV-validated schemas, and persona routing — but the Vertex client is a placeholder. This enables a future migration from Google AI Studio to Vertex AI without changing the Flutter app.

Additional planned milestones: multilingual STT and UI (currently English-only), fine-tuning persona variants for clinical caregiver tone with Unsloth, and native function calling to replace the structured-prompt-to-JSON pattern.

---

## Try it

**Live demo page:** https://www.crucue.com/hackathon — hero, embedded video, APK download, architecture diagram, and full Gemma 4 code references.

**Demo APK (Android 8+):** Download from the demo page. Enable "Install from unknown sources," install, grant microphone permission, and create a care profile to see the full Gemma 4 pipeline in action.

**Source code:** https://github.com/frameless-studio/crucue — all Cloud Functions, Dart AI engine layer, safety pipeline, prompt schemas, and persona policies.

**Video:** [linked from demo page] — 3-minute walkthrough of the full caregiving loop, ending with the on-device weekly insight running in airplane mode.
