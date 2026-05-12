# Cloud Run AI Gateway — Status

**Status: Scaffolded, not deployed.**

This directory contains a full Express/TypeScript scaffold for an optional Cloud Run AI Gateway. It is **not** the active AI backend for Crucue.

## What is here

- `src/server.ts` — Express app with 5 routes (`/api/v1/generate-plan`, `/api/v1/chat`, `/api/v1/extract-incident`, `/api/v1/summarize-patterns`, `/api/v1/suggest-routine`), Helmet security headers, CORS, and per-route AJV validation middleware.
- `src/middleware/auth.ts` — Firebase Admin token verification.
- `src/ai/prompt-builder.ts` — Persona-aware prompt builders (mirrors `functions/src/ai/prompts.ts`).
- `src/schemas/` — JSON schemas for all 5 AI operations.
- `src/vertex-client.ts` — **Placeholder only.** The actual Vertex AI `generateContent` call is not implemented.
- `Dockerfile` — Container build ready.

## What is active

All production AI traffic routes through **Firebase Cloud Functions** in `functions/src/ai/`:
- `generateSupportPlan`
- `chatOnPlan`
- `summarizePatterns`
- `processVoiceIncident` (+ `transcribeShortClip`)
- `suggestRoutineFromReflection`

These call `gemma-4-26b-a4b-it` via `@google/genai` v1.50.0. The Cloud Functions are deployed and active in Firebase project `crucueapp`.

## Roadmap

The gateway is intended as a future migration path to Vertex AI for enterprise-grade rate limiting and SLA, or for direct HTTP access without Firebase SDK dependency. The remaining work is wiring `vertex-client.ts` to the `@google-cloud/aiplatform` `generateContent` endpoint and deploying to Cloud Run.
