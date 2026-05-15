# Crucue — Private AI Support for Caregivers, Powered by Gemma 4

> When a caregiver is alone at 2 AM and doesn't know what to do next, they need a structured plan — not a paragraph of generic advice. Crucue uses Gemma 4's structured JSON outputs to turn difficult caregiving moments into actionable support, grounded in the specific person, the specific relationship, and what has actually worked before.

---

## The problem

It's 2 AM. Your mother won't take her medication. She thinks you're trying to hurt her. You're exhausted, alone, and you need someone to help you think clearly — right now.

There are 53 million unpaid caregivers in the United States alone. Parents of children with autism or ADHD navigating daily meltdowns. Adults caring for aging parents with dementia. Partners supporting someone through chronic illness. They face recurring, high-stress moments with limited support, limited time, and no practical tool that meets them where they are.

Generic AI chatbots can offer general advice. But caregiving isn't generic. A plan for a 7-year-old mid-meltdown looks nothing like a plan for a 78-year-old who doesn't recognize you. Caregivers need a tool that knows *who* they're caring for, *what* has happened before, and *what* actually helped — and can deliver a structured response they can use while their hands are shaking.

---

## What Crucue does

Crucue is a Flutter mobile app built around one caregiving support loop:

**1. Log the moment.** The caregiver speaks or types what just happened. Voice notes are transcribed via Google Cloud Speech-to-Text, then Gemma 4 extracts structured incident fields — what happened, the possible trigger, what was already tried, and the desired outcome — using `responseJsonSchema`. The model returns typed fields directly; no text parsing, no regex.

**2. Get a structured support plan.** Gemma 4 (`gemma-4-26b-a4b-it`) generates a complete care plan grounded in the specific care profile and incident. The output is a typed JSON object enforced at the model level: a calm summary, concrete steps, what to avoid, a suggested message to say to the loved one, follow-up tasks, a reflection prompt, and a safety flag with crisis resources when needed.

**3. Listen.** The plan is read aloud via platform TTS — because a caregiver managing a crisis shouldn't have to hold a screen to get help.

**4. Chat with context.** Follow-up conversation is grounded in the specific plan, the care profile, and recent reflections — not generic dialogue. The AI knows this is your mother, what usually calms her, and what just happened.

**5. Reflect and save.** After the moment passes, the caregiver logs what helped, what made things worse, and rates the outcome. Strategies that work become saved routines. Each cycle through the loop makes future plans more informed.

**6. Weekly insights.** Gemma 4 analyzes a week of incidents, plans, and reflections — surfacing patterns and suggestions. This runs on the cloud by default, or entirely on-device using a smaller Gemma model via `flutter_gemma` when the user has downloaded weights. No network call. No data leaving the phone.

---

## Why Gemma 4

Crucue's use of Gemma 4 is structural, not cosmetic.

A caregiving support plan is not useful as a paragraph of prose. It needs to be a typed object — a summary the caregiver can scan in five seconds, a numbered list of steps, a message they can say out loud, and clear guidance on what *not* to do. Gemma 4's `responseJsonSchema` in the `@google/genai` SDK makes this enforceable at the model level. The plan arrives already shaped — not scraped from free text after the fact. This eliminates an entire class of parsing failures and means every plan is immediately renderable in the UI.

The same principle applies to voice extraction. When a caregiver speaks for 90 seconds about what happened, Gemma 4 extracts named, typed fields (`possible_trigger`, `what_user_already_tried`, `desired_outcome`) that are stored, compared across incidents, and used to inform future plans. Structure turns raw emotion into something actionable.

Crucue also calibrates Gemma 4's behavior per task: low temperature (0.3) for deterministic incident extraction, moderate (0.7) for empathetic plan generation, and higher (0.8) for natural follow-up chat — all using the model card's recommended `topP` and `topK` defaults. Nine distinct persona policies tune every prompt: a plan for a toddler reads differently than a plan for an aging parent, and the safety boundaries shift accordingly.

---

## Technical architecture

**Flutter app** — Riverpod state management, Firebase Auth (email, Google, Apple), Firestore with owner-scoped security rules, Cloud Storage for voice audio (deleted after processing), Firebase Analytics and Crashlytics with full async error coverage.

**Cloud Functions (deployed)** — Node.js 22, Gen 2, us-central1. Five callable functions handle all AI inference: `generateSupportPlan`, `chatOnPlan`, `summarizePatterns`, `processVoiceIncident`, and `transcribeShortClip`. The `@google/genai` SDK (v1.50.0) calls Gemma 4 via the Google AI Studio API. API keys live in Firebase Secret Manager — never in the client.

**AI abstraction layer** — The `AiEngine` interface routes all inference through a single typed contract. `RemoteGemma4Engine` handles cloud calls. `HybridGemmaEngine` routes weekly insights to on-device Gemma when weights are available, with automatic fallback to cloud. Users choose between Cloud, On-device, or Automatic modes in Settings.

---

## Challenges and decisions

**Structured output over free text.** Early prototypes used free-text Gemma responses parsed with regex. Plans were inconsistent — sometimes missing steps, sometimes returning narrative instead of lists. Switching to `responseJsonSchema` made every plan deterministic in shape and immediately usable in the UI without fragile post-processing.

**Safety before inference.** We built a pre-inference safety layer that scans caregiver input for crisis language *before* calling Gemma 4. High-risk messages bypass the model entirely and return crisis resources immediately — no latency, no risk of an unhelpful AI response during a genuine emergency. Model outputs are checked independently: if the plan's escalation flag is set, a safety banner with resources appears in the UI.

**Hybrid routing, not all-or-nothing.** Full on-device inference for complex care plans isn't practical on current mobile hardware at the quality level caregivers need. We route only the weekly insight — a lower-stakes analytical summary — to on-device Gemma, keeping plans and chat on the cloud where the 26B MoE model and server-side safety checking are strongest. Native LiteRT-LM platform bridges are built for when edge models catch up.

**Persona-aware prompting.** A single system prompt doesn't work across caregiving contexts. Nine persona policies — each with distinct tone guidance, suggestion types, safety boundaries, and message draft styles — ensure that a plan for a partner through illness sounds nothing like a plan for a child during a sensory meltdown.

---

## Privacy and safety

Care data is among the most sensitive personal information that exists. It describes the vulnerabilities of the people we love most. Parents don't want notes about their child's meltdowns on an ad-supported platform. Adults don't want their parent's health history analyzed by a recommendation algorithm.

Crucue is designed around this reality. All data is owner-scoped in Firestore with deployed security rules. Voice recordings are deleted after transcription. No care data is used for model training. When on-device mode is active for weekly insights, AI inference produces no network traffic at all. The app is not a medical or therapeutic service — every plan includes a note to that effect, and crisis detection operates independently of the model.

---

## Try it

- **Live demo & APK:** [crucue.com/hackathon](https://www.crucue.com/hackathon)
- **Source code:** [github.com/AmirmLotfy/crucue](https://github.com/AmirmLotfy/crucue)

*Built for the Gemma 4 Good Hackathon. Tracks: Main · Health & Sciences · Safety & Trust.*
