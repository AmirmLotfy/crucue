# About Crucue

## Mission

Crucue exists to make caregiving a little less lonely and a little more navigable.

Caring for someone you love — a child with behavioral challenges, an aging parent, a partner through illness — is relentless, emotionally demanding work. Most caregivers are doing it without enough support, without good tools, and without anyone to help them make sense of what keeps going wrong.

Crucue is the companion for the hard moments between appointments and support groups. When something difficult happens, it helps the caregiver understand it, plan a response, and track what works.

---

## Target user

**Primary:** Parents of children with behavioral, developmental, or emotional challenges — autism, ADHD, anxiety, trauma, developmental delays. These caregivers face recurring high-stress incidents and often feel under-equipped and unsupported.

**Secondary:** Adults caring for aging or unwell parents, partners supporting someone through chronic illness or mental health challenges, siblings or family members providing daily care.

**What they have in common:**
- Recurring difficult moments that follow similar patterns
- A need for structure and practical steps, not sympathy
- Privacy expectations — they don't want their care data on a social platform or sold to advertisers
- Limited time — they need help in the moment, not a therapy appointment in two weeks

---

## The core support loop

```
Something hard happens
  ↓
Log it (voice or text, 2 minutes)
  ↓
Crucue generates a structured support plan
  — grounded in this specific person, this specific challenge
  ↓
Follow the plan, adapt in real time
  ↓
Reflect: what helped? What made it worse?
  ↓
Save what worked as a routine
  ↓
Weekly insights show what's changing over time
  ↓
Better plans next time (context improves with each cycle)
```

Each cycle through the loop builds a richer picture of what works for this person in this family. The AI gets more useful. The caregiver gets more confident.

---

## What makes Crucue different from generic chatbots

Generic AI chat tools (ChatGPT, Claude, Gemini) can give general caregiving advice. Crucue does something different:

1. **Profile-grounded.** Plans are generated against a specific care profile — the person's age, relationship, communication style, known triggers, and what has worked before. A plan for a 7-year-old with ADHD looks different from a plan for a 78-year-old with dementia.

2. **Structured, not conversational.** Every support plan is a structured JSON document: summary, ordered steps, optional message draft, safety note. Not a wall of paragraph text. Actionable in the moment.

3. **Reflection-powered.** The app learns from check-ins. What helped most? What made things worse? This informs future plan generation.

4. **Voice-first logging.** Caregivers can speak what happened — the app transcribes and extracts structured incident fields using Gemma 4. Logging takes 90 seconds, not 10 minutes of typing.

5. **Private by design.** No ads. No data sharing. Voice recordings deleted after processing. Owner-only Firestore rules. On-device AI path for maximum privacy on supported devices.

---

## Tone principles

Crucue's tone is deliberate and non-negotiable:

**Support, not control.** The app makes suggestions. It never prescribes, diagnoses, or makes clinical claims.

**Calm, not clinical.** The language is warm and human. It doesn't feel like a health app or a behavior chart.

**Practical, not philosophical.** Every response is immediately actionable. No lengthy advice. No platitudes.

**Private, not intrusive.** The app doesn't send unsolicited notifications, push the user to share data, or suggest premium upsells during vulnerable moments.

**Non-judgmental.** Caregiving is hard. The app never implies the caregiver is doing it wrong.

---

## Why privacy and structure matter

Care data is among the most sensitive personal data that exists. It describes the vulnerabilities of the people we love most. Parents don't want notes about their child's meltdowns on an ad-supported platform. Adults don't want their parent's health history analyzed by a recommendation algorithm.

Crucue's data model is designed so that:
- All data is scoped to the user's Firebase UID. No cross-user access is possible.
- Voice recordings are processed server-side and deleted immediately after transcription.
- Care notes are stored in Firestore under the user's own collection, not accessible to anyone else.
- The on-device AI path (in development) ensures inference happens locally with no network calls.

Structure matters because caregiving moments are chaotic. A wall of AI-generated text is not useful when you're in the middle of a crisis. Structured plans — steps, time estimates, message drafts — give caregivers something to hold onto when they're overwhelmed.

---

## What Crucue is not

- Not a medical or therapeutic service
- Not a behavior tracking or data-reporting tool for institutions
- Not a communication platform between caregivers and care recipients
- Not a replacement for professional care coordination
