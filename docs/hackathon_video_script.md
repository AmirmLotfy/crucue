# Crucue — Gemma 4 Good Hackathon Video Script
## Target: ≤3 minutes (aim for 2:30–2:50)

---

## Production notes (before you start)

- **Device:** Real Android device mirrored via `scrcpy` or AirDroid Cast at 1080p 60fps.
- **Demo profile:** Load the "Mom" demo profile before recording (Settings → Demo → Load demo profile). Profile: parent, age 75–85, early-stage dementia.
- **Voice-over:** Recorded separately, mixed quietly under the screen capture. Calm, unhurried pacing — caregiving context, not a tech demo.
- **Music:** Quiet, warm instrumental under the voice-over. Fade to silence at the plan generation moment so the UI can breathe.
- **Export:** H.264, 1920×1080, ≤500 MB, upload as YouTube Public (NOT unlisted).

---

## Beat 1 — Cold open (0:00–0:15)

**Screen:** Black.

**Voice-over (slow, personal):**
> "It's 2 AM. My mom won't take her medication. She thinks I'm trying to hurt her. I don't know what to do. I just need someone to help me think."

**Screen:** Fade in — Crucue app icon. Then the home screen with the "Mom" care profile already visible.

*No typing sounds, no UI clicks yet. Just the voice and the icon.*

---

## Beat 2 — Problem (0:15–0:30)

**Screen:** Three statistics, one at a time, on a dark background — styled title cards:

1. "53M unpaid caregivers in the US alone."
2. "Most face crises without any structured support."
3. "Their care conversations are too private for generic AI."

**Voice-over:**
> "Caregiving is one of the most demanding things a person can do. And it happens in private — the kind of situations where you need real, specific help, not a generic chatbot answer."

---

## Beat 3 — The moment (0:30–1:00)

**Screen:** App open on the "Mom" profile. Tap "Log a moment." Choose Voice. Show the waveform animation while speaking into the phone (record a natural 10-second voice note, don't narrate — just record the moment naturally).

**Voice-over (as the plan generates):**
> "Crucue lets you speak — or type — about what just happened. Google Cloud Speech-to-Text transcribes it. Then Gemma 4 extracts what happened, what triggered it, and what outcome you're hoping for."

Gemma 4 generates the plan. **Pan slowly over the plan sections as the voice-over names them:**

**Voice-over:**
> "The plan arrives as a structured object — not a paragraph. A calm summary. Concrete steps. What to avoid. A message you can actually say to your mom right now. A reflection prompt. And a safety note if the situation calls for it."

*Pause on the "What to say right now" message draft for 2 seconds.*

---

## Beat 4 — Chat (1:00–1:30)

**Screen:** Tap "Ask about this plan." Type a short follow-up question (something like "She's getting more upset, what do I do?"). Show the grounded response arrive.

**Voice-over:**
> "Follow-up chat is grounded in the specific plan and profile — not generic conversation. Crucue knows this is your mom, what usually helps her, and what just happened. That context travels with every message."

Show the crisis pre-check working — type something like "I can't handle this anymore" — show the escalation safety banner appear with crisis resources. Brief, 3 seconds.

**Voice-over:**
> "And the safety layer runs before every call. Anything that signals a crisis short-circuits the model and returns resources immediately."

---

## Beat 5 — Reflect and save (1:30–2:00)

**Screen:** Return to the plan. Tap "Mark as tried." The check-in screen appears. Slide the "outcome" rating, tap one or two steps that helped, and tap "Save as routine."

**Voice-over:**
> "After the moment passes, log what helped. Rate it. The things that work become saved routines. Over time, Crucue builds a picture of what actually works for this specific relationship."

*Show the routine appearing in the routines list. Fast-paced montage — 15 seconds.*

---

## Beat 6 — The Gemma 4 edge story (2:00–2:30)

**Screen:** Go to Settings. Tap "Enable on-device weekly insight." Show the model download tile (don't actually re-download — this should already be pre-warmed on the recording device). Toggle AI mode to "On-device / Auto."

Go to Weekly Insights. **Turn on Airplane Mode visibly** (pull down the status bar, tap the airplane icon — show it turn on). Tap "Generate this week's insight."

Show the weekly insight generating — the loading spinner, then the text appearing.

**Voice-over:**
> "For the weekly summary, Crucue runs a small Gemma 4 model entirely on device — via the flutter_gemma plugin. No network. No cloud call. The summary of your week, and what patterns Crucue noticed, generated on your phone, offline."

Turn Airplane Mode off.

---

## Beat 7 — Close (2:30–3:00)

**Screen:** Fade to the Crucue app icon, then the crucue.com/hackathon URL, then the GitHub link.

**Voice-over:**
> "Every plan is grounded in a specific person, a specific moment. Every output is a schema — no free-text parsing. No API keys in the app. No care data used for training. And when the device can handle it, no data leaves the phone at all."

> "Crucue. Try the demo at crucue.com/hackathon."

**Screen:** Logo hold for 3 seconds. Fade out.

---

## Production checklist

- [ ] Record device screen via scrcpy at 1080p (USB or wireless)
- [ ] Pre-load "Mom" demo profile (Settings → Demo → Load demo profile)
- [ ] Pre-download flutter_gemma weights on the recording device before the session
- [ ] Record all screen capture in one take where possible
- [ ] Record voice-over in a quiet room, separate track
- [ ] Mix in DaVinci Resolve or Final Cut Pro
- [ ] Export H.264 1920×1080, ≤500MB
- [ ] Upload to YouTube as **Public** (not Unlisted)
- [ ] Verify it plays in an incognito browser tab
- [ ] Paste YouTube URL into `YOUTUBE_VIDEO_ID` constant in `src/pages/Hackathon.tsx`
- [ ] Rebuild and deploy Crucue-web
