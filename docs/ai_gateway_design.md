# Crucue AI Gateway — Design Document

## Purpose

The Cloud Run AI Gateway (`backend/ai-gateway/`) is the production AI orchestration layer for Crucue. It:

1. Authenticates all requests via Firebase Auth
2. Validates request and response schemas with AJV
3. Builds persona-policy-aware prompts for Gemma 4
4. Calls Vertex AI (Gemma 4) and validates structured outputs
5. Logs all requests with Cloud Logging-compatible structured JSON

The existing Firebase Cloud Functions are the current working backend. The gateway is deployed alongside them and cutover is done by updating `RemoteGemma4Engine` to call the gateway URL instead of Cloud Functions.

---

## Endpoints

### `POST /api/v1/generate-plan`

Generates a structured AI support plan.

**Auth**: Firebase ID token (Bearer)

**Request**:
```json
{
  "profileId": "string",
  "incidentId": "string?",
  "personaData": {},
  "challenges": ["string"],
  "incidentContext": {},
  "personaTypeKey": "child | teenager | baby | parent | partner | sibling | friend | pet | myself"
}
```

**Response**:
```json
{
  "success": true,
  "plan": {
    "summary": "string",
    "steps": [{ "title": "string", "description": "string" }],
    "messageDraft": "string?",
    "safetyNote": "string?",
    "followUpQuestions": ["string"]
  }
}
```

---

### `POST /api/v1/chat`

Sends a grounded care chat message.

**Request**:
```json
{
  "profileId": "string",
  "userMessage": "string",
  "planId": "string?",
  "threadId": "string?",
  "history": [{ "role": "user|assistant", "content": "string" }],
  "personaTypeKey": "string?"
}
```

**Response**:
```json
{
  "success": true,
  "message": "string",
  "threadId": "string?"
}
```

---

### `POST /api/v1/extract-incident`

Extracts structured incident fields from a voice note transcript.

**Request**:
```json
{
  "voiceNoteId": "string",
  "profileId": "string",
  "audioStoragePath": "string",
  "transcript": "string",
  "personaTypeKey": "string?"
}
```

**Response**:
```json
{
  "success": true,
  "incident": {
    "whatHappened": "string",
    "possibleTrigger": "string?",
    "whatWasAlreadyTried": "string?",
    "desiredOutcome": "string?",
    "safetyFlag": false,
    "confidenceScore": 0.9
  },
  "safetyFlag": false
}
```

---

### `POST /api/v1/summarize-patterns`

Generates a weekly insight summary by reading Firestore data.

**Request**:
```json
{
  "profileId": "string",
  "weekStart": "YYYY-MM-DD?"
}
```

**Response**:
```json
{
  "success": true,
  "summary": {
    "summary": "string",
    "patterns": ["string"],
    "whatWorked": ["string"],
    "suggestions": ["string"],
    "moodTrend": "improving | stable | declining | null"
  }
}
```

---

### `POST /api/v1/suggest-routine`

Suggests a routine from a plan check-in reflection.

**Request**:
```json
{
  "profileId": "string",
  "planId": "string",
  "reflectionNotes": "string?",
  "stepsHelpedMost": ["string"],
  "personaTypeKey": "string?"
}
```

**Response**:
```json
{
  "success": true,
  "routine": {
    "title": "string",
    "steps": ["string"],
    "frequency": "daily | weekdays | weekly | as-needed",
    "estimatedDurationMinutes": 15,
    "tags": ["string"],
    "rationale": "string"
  }
}
```

---

### `GET /health`

Health check for Cloud Run and load balancer probes. No auth required.

**Response**: `{ "status": "ok", "service": "crucue-ai-gateway", "model": "gemma-4-26b-a4b-it" }`

---

## Middleware Stack

```
Request
  │
  ├── helmet()          — Security headers
  ├── cors()            — CORS policy
  ├── express.json()    — Body parsing (1MB limit)
  ├── requestLogger     — Structured Cloud Logging
  ├── rateLimit()       — 60 req/min per IP
  ├── requireAuth       — Firebase ID token verification
  ├── validateBody()    — AJV schema validation
  │
  ▼
Route Handler
  │
  ├── buildPrompt()    — Persona-policy prompt construction
  ├── generate()       — Vertex AI Gemma 4 call
  ├── parseAndValidate() — Output schema validation + fallback
  │
  ▼
Response
```

---

## Deployment

```bash
# From backend/ai-gateway/
gcloud run deploy crucue-ai-gateway \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --concurrency 80 \
  --min-instances 0 \
  --max-instances 10 \
  --set-env-vars GOOGLE_CLOUD_PROJECT=crucueapp,VERTEX_AI_LOCATION=us-central1,GEMMA4_DEFAULT_MODEL=gemma-4-26b-a4b-it
```

After deployment, update `RemoteGemma4Engine` to call the gateway URL and remove the Cloud Functions dependency.

---

## Error Handling

All routes return structured error responses:

```json
{ "error": "Human-readable error message." }
```

HTTP status codes:
- `400` — request validation failed
- `401` — missing or invalid auth token
- `429` — rate limit exceeded
- `500` — AI inference or server error

On schema validation failures of AI output, the gateway logs a warning and returns partial data rather than a 500. This prevents a single malformed AI response from breaking the user flow.
