# Gemma 4 Good Hackathon — 2–3 minute demo script

Use this order so judges see **hosted Gemma 4** first, then **optional hybrid** context.

## 0. Prereqs (off-camera)

- Firebase project with Functions deployed; `GEMMA4_API_KEY` configured.
- Test account signed in; one care profile created (e.g. child, name + age).

## 1. Hero flow — remote Gemma 4 (~90 s)

1. **Profile** — Open the care profile; show relationship and focus areas.
2. **Log a challenge** — Text or **voice** (voice is higher impact): short description of a hard moment.
3. **Support plan** — Show structured output: summary, steps, message draft, reflection prompt, safety line if present. Point out this is **JSON-shaped**, not generic chat.
4. **TTS** — Tap listen; emphasize no extra LLM call.
5. **Chat** — One follow-up grounded in the plan.
6. **Reflect** — Quick check-in (what helped).

## 2. Weekly insights (~30 s)

- Open **Weekly insights** after a week’s data exists, or explain the screen.
- If **remote only:** say insights use the same **Cloud Function** + `INSIGHT_SCHEMA`.
- If **flutter_gemma** model is installed: say **only weekly insights** can run on-device; plans/chat remain cloud.

## 3. Settings — AI engine (~20 s)

- **Settings → AI Engine:** Cloud / On-device / Auto.
- **One sentence:** “Plans and chat always use hosted Gemma 4 for quality and safety; weekly summary can use a small on-device model when downloaded.”

## 4. Optional — edge validation (spoken, no app UI)

- Mention **Google AI Edge Gallery** or **LiteRT-LM** as how you validated Gemma 4 E2B/E4B on hardware — see `docs/edge_demo_path.md`.

## Closing line

> “Crucue uses Gemma 4 with structured schemas end-to-end on the server, and a deliberate hybrid path for weekly insights when a local model is available — privacy-first without pretending the phone runs the 26B model.”
