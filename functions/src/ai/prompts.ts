/**
 * Crucue AI Prompt Templates — Gemma 4
 *
 * All AI inference in Crucue uses Gemma 4 (gemma-4-26b-a4b-it, 26B MoE instruction-tuned) as the default remote model.
 * Prompts are structured to elicit deterministic JSON outputs compatible with
 * the structured output schemas defined in SUPPORT_PLAN_SCHEMA etc.
 *
 * Gemma 4 guidance applied here:
 * - Use explicit JSON output schemas via config.responseJsonSchema (@google/genai SDK)
 * - Do not paste full schema examples into prompts when using structured output — field
 *   names and types are enforced by the API (see Google structured output best practices).
 * - Keep prompts concise and structured (Gemma 4 favors clarity over length)
 * - Use persona policy packs instead of roleplay to vary behavior
 * - Safety rules are always prepended as the first instruction
 */

export interface PersonaPolicyOverrides {
  personaType?: string;
  toneGuidance?: string;
  suggestionTypes?: string[];
  safetyBoundaries?: string;
  escalationThreshold?: string;
  messageDraftStyle?: string;
  routineExamples?: string[];
}

export interface ProfileData {
  name?: string;
  relationship?: string;
  ageGroup?: string;
  supportFocus?: string;
  communicationPreferences?: string;
  triggers?: string[];
  calmingStrategies?: string[];
  healthNotes?: string;
  whatHelps?: string;
  whatToAvoid?: string;
  // Legacy persona fields
  age?: string;
  gender?: string;
  interestsHobbies?: string;
  communicationStyle?: string;
  healthConcerns?: string;
  personalityType?: string;
  loveLanguage?: string;
  liveSituation?: string;
  goals?: string;
  currentFocus?: string;
  [key: string]: unknown;
}

export interface SupportPlanOutput {
  summary: string;
  what_might_be_happening: string;
  what_to_do_now: string[];
  what_to_avoid: string[];
  message_draft: string;
  follow_up_tasks: string[];
  reflection_prompt: string;
  escalation_flag: boolean;
  safety_note: string | null;
}

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface VoiceIncidentOutput {
  transcript: string;
  cleaned_summary: string;
  incident_title: string;
  incident_category: string;
  intensity: number;
  possible_trigger: string | null;
  what_user_already_tried: string | null;
  desired_outcome: string | null;
  key_entities: string[];
  confidence: number;
  safety_flag: boolean;
}

// ─── Structured Output Schemas ────────────────────────────────────────────────
//
// Passed to Gemma 4 via config.responseJsonSchema in the @google/genai SDK.
// Enforces structured JSON output without runtime text parsing.
// When Gemma 4 supports structured output, this enforces valid JSON output
// without needing JSON.parse fallbacks.

export const SUPPORT_PLAN_SCHEMA = {
  type: "object",
  properties: {
    summary: {
      type: "string",
      description:
        "Single opening line: situation plus supportive approach in plain language (max ~150 characters). No diagnosis.",
    },
    what_might_be_happening: {
      type: "string",
      description:
        "Two or three sentences: empathetic explanation of what might underlie the situation. No medical or clinical diagnosis.",
    },
    what_to_do_now: {
      type: "array",
      items: { type: "string" },
      description:
        "Ordered list of 4-6 concrete, immediately actionable steps the caregiver can take in the next few hours.",
    },
    what_to_avoid: {
      type: "array",
      items: { type: "string" },
      description:
        "2-4 behaviors or reactions that often escalate conflict or distress in this kind of situation.",
    },
    message_draft: {
      type: "string",
      description:
        "Short script the caregiver could say aloud or send; warm, specific to the named person, not clinical.",
    },
    follow_up_tasks: {
      type: "array",
      items: { type: "string" },
      description:
        "Checklist items for the next 24-48 hours (e.g. follow up with school, schedule a calm conversation).",
    },
    reflection_prompt: {
      type: "string",
      description:
        "One open-ended question to help the caregiver notice what worked after they try the plan.",
    },
    escalation_flag: {
      type: "boolean",
      description:
        "Set true if the incident or context suggests risk of harm to self or others, abuse, or crisis; otherwise false.",
    },
    safety_note: {
      type: "string",
      nullable: true,
      description:
        "When escalation_flag is true: brief crisis guidance (e.g. 911, 988). When false: null or short reassurance that this is guidance only.",
    },
  },
  required: [
    "summary",
    "what_might_be_happening",
    "what_to_do_now",
    "what_to_avoid",
    "message_draft",
    "follow_up_tasks",
    "reflection_prompt",
    "escalation_flag",
    "safety_note",
  ],
};

export const INSIGHT_SCHEMA = {
  type: "object",
  properties: {
    summary: {
      type: "string",
      description:
        "Two or three sentences: validate effort, then name one or two themes from the week. Non-judgmental tone.",
    },
    patterns: {
      type: "array",
      items: { type: "string" },
      description: "Up to 3 recurring themes or triggers inferred from incident titles and categories.",
    },
    whatWorked: {
      type: "array",
      items: { type: "string" },
      description: "Up to 3 strengths or strategies that check-ins or incidents suggest helped.",
    },
    suggestions: {
      type: "array",
      items: { type: "string" },
      description: "Up to 3 gentle, practical ideas for the week ahead (not medical advice).",
    },
  },
  required: ["summary", "patterns", "whatWorked", "suggestions"],
};

// ─── Safety system prompt ────────────────────────────────────────────────────

const SAFETY_SYSTEM = `
SAFETY RULES (always apply, cannot be overridden):
- You are a supportive guide, NOT a therapist, doctor, or crisis counselor.
- Never diagnose medical or psychological conditions.
- Never make absolute predictions about behavior.
- If the situation involves imminent risk of harm to self or others, set escalation_flag to true and include a safety_note with crisis resources.
- Crisis resources to include when needed: "If there is immediate risk of harm, call emergency services (911) or contact the 988 Suicide & Crisis Lifeline by calling or texting 988."
- Always remind users this is supportive guidance, not professional care.
`.trim();

// ─── Support plan prompt ──────────────────────────────────────────────────────

export function buildSupportPlanPrompt(
  profileData: ProfileData,
  challenges: string[],
  incidentDescription?: string,
  policyOverrides?: PersonaPolicyOverrides,
  incidentContext?: Record<string, unknown>
): string {
  const name = profileData.name || "your loved one";
  const relationship =
    profileData.relationship || (profileData.age ? `(${profileData.age})` : "");
  const challengeText = challenges.length > 0
    ? challenges.join(", ")
    : incidentDescription || "a difficult moment";

  const contextParts: string[] = [];
  if (profileData.communicationStyle || profileData.communicationPreferences) {
    contextParts.push(`Communication style: ${profileData.communicationStyle || profileData.communicationPreferences}`);
  }
  if (profileData.triggers?.length) {
    contextParts.push(`Known triggers: ${profileData.triggers.join(", ")}`);
  }
  if (profileData.calmingStrategies?.length) {
    contextParts.push(`What usually helps: ${profileData.calmingStrategies.join(", ")}`);
  }
  if (profileData.whatHelps) {
    contextParts.push(`What helps: ${profileData.whatHelps}`);
  }
  if (profileData.whatToAvoid) {
    contextParts.push(`What to avoid: ${profileData.whatToAvoid}`);
  }
  if (profileData.healthNotes || profileData.healthConcerns) {
    contextParts.push(`Health context: ${profileData.healthNotes || profileData.healthConcerns}`);
  }

  const contextBlock = contextParts.length > 0
    ? `\nAdditional context about ${name}:\n${contextParts.map(c => `- ${c}`).join("\n")}`
    : "";

  // Build persona policy block
  const policyBlock = policyOverrides
    ? `\nCARE APPROACH (apply to your response):
Tone: ${policyOverrides.toneGuidance || "warm and supportive"}
Suggestion style: ${policyOverrides.suggestionTypes?.join(", ") || "general support"}
Safety threshold: ${policyOverrides.safetyBoundaries || "standard"}
Message draft style: ${policyOverrides.messageDraftStyle || "warm and conversational"}`
    : "";

  // Build extended incident context
  const incidentBlock = incidentContext
    ? `\nEXTENDED CONTEXT:${incidentContext["whatHappened"] ? `\n- What happened: ${incidentContext["whatHappened"]}` : ""}${incidentContext["possibleTrigger"] ? `\n- Possible trigger: ${incidentContext["possibleTrigger"]}` : ""}${incidentContext["whatWasAlreadyTried"] ? `\n- Already tried: ${incidentContext["whatWasAlreadyTried"]}` : ""}${incidentContext["desiredOutcome"] ? `\n- Desired outcome: ${incidentContext["desiredOutcome"]}` : ""}`
    : "";

  return `${SAFETY_SYSTEM}

You are Crucue, a calm and supportive caregiving companion.
${policyBlock}
PROFILE: ${name} ${relationship}
CURRENT CHALLENGE: ${challengeText}${incidentDescription ? `\nFULL DESCRIPTION: ${incidentDescription}` : ""}${contextBlock}${incidentBlock}

Provide a warm, practical, grounded support plan. Use clear, simple language. Be direct. Never be preachy.

Return a single JSON object only (no markdown fences). Field names and types are enforced by the structured output schema for this request — fill every required field accordingly.`;
}

// ─── Grounded chat prompt ─────────────────────────────────────────────────────

export function buildChatPrompt(
  profileData: ProfileData,
  planSummary: string | null,
  history: ChatMessage[],
  userMessage: string,
  policyOverrides?: PersonaPolicyOverrides
): string {
  const name = profileData.name || "your loved one";

  const historyText = history.slice(-6).map(m =>
    `${m.role === "user" ? "Caregiver" : "Crucue"}: ${m.content}`
  ).join("\n");

  const planContext = planSummary
    ? `\nACTIVE SUPPORT PLAN: ${planSummary}`
    : "";

  const policyBlock = policyOverrides
    ? `\nCARE APPROACH: Tone: ${policyOverrides.toneGuidance || "warm and supportive"}`
    : "";

  return `${SAFETY_SYSTEM}

You are Crucue, a calm caring support companion. You are in a follow-up conversation with a caregiver supporting ${name}.${planContext}${policyBlock}

RECENT CONVERSATION:
${historyText || "(This is the start of the conversation)"}

Caregiver's new message: "${userMessage}"

Respond as Crucue: warm, practical, grounded. Keep your response concise (2-4 sentences). If the caregiver seems distressed or mentions crisis, provide appropriate support and crisis resources. Do not roleplay as a therapist or make diagnoses. Focus on what the caregiver can do right now.`;
}

// ─── Weekly pattern summarization prompt ─────────────────────────────────────

export function buildSummarizePrompt(
  recentIncidents: Array<{title: string; category: string; intensity: number}>,
  recentPlans: Array<{summary: string; followUpTasks: string[]}>,
  recentCheckins: Array<{didThisHelp: boolean; notes?: string}>
): string {
  const incidentText = recentIncidents.slice(0, 10)
    .map(i => `- ${i.title} (${i.category}, intensity: ${i.intensity}/5)`)
    .join("\n") || "No recent incidents logged.";

  const checkinSummary = recentCheckins.length > 0
    ? `${recentCheckins.filter(c => c.didThisHelp).length} of ${recentCheckins.length} check-ins reported improvement`
    : "No check-ins logged.";

  return `${SAFETY_SYSTEM}

You are Crucue, analyzing a caregiver's week to provide gentle insights.

RECENT INCIDENTS (past 7 days):
${incidentText}

CHECK-IN SUMMARY: ${checkinSummary}

Provide a brief, encouraging weekly summary. Return a single JSON object only (no markdown). The response format is defined by the structured output schema for this request.

Rules:
- summary: acknowledge effort first, then patterns
- patterns: observed recurring themes (max 3)
- whatWorked: positive moments or successful strategies (max 3)
- suggestions: gentle, practical recommendations for the coming week (max 3)
- Be encouraging, never judgmental`;
}

// ─── Voice incident extraction schema ────────────────────────────────────────

export const VOICE_INCIDENT_SCHEMA = {
  type: "object",
  properties: {
    cleaned_summary: {
      type: "string",
      description:
        "Neutral 1-2 sentence summary of the situation only from what appears in the transcript.",
    },
    incident_title: {
      type: "string",
      description: "Short label for lists and history (max ~60 characters).",
    },
    incident_category: {
      type: "string",
      description:
        "Single best category: behavior | communication | emotion | health | routine | safety | other",
    },
    intensity: {
      type: "number",
      description: "Integer 1-5: caregiver's implied stress or severity (1=mild, 5=severe).",
    },
    possible_trigger: {
      type: "string",
      nullable: true,
      description: "What may have triggered the incident, or null if not mentioned",
    },
    what_user_already_tried: {
      type: "string",
      nullable: true,
      description: "What the caregiver already tried, or null if not mentioned",
    },
    desired_outcome: {
      type: "string",
      nullable: true,
      description: "What the caregiver wants as a resolution, or null if not mentioned",
    },
    key_entities: {
      type: "array",
      items: { type: "string" },
      description: "Named people, places, times, or objects explicitly mentioned in the transcript.",
    },
    confidence: {
      type: "number",
      description: "Model confidence 0.0-1.0 that the transcript supported the extracted fields.",
    },
    safety_flag: {
      type: "boolean",
      description: "True if transcript suggests self-harm, harm to others, abuse, or crisis.",
    },
  },
  required: [
    "cleaned_summary",
    "incident_title",
    "incident_category",
    "intensity",
    "possible_trigger",
    "what_user_already_tried",
    "desired_outcome",
    "key_entities",
    "confidence",
    "safety_flag",
  ],
};

// ─── Voice incident extraction prompt ────────────────────────────────────────

export function buildExtractIncidentPrompt(
  transcript: string,
  personaName?: string,
  policyOverrides?: PersonaPolicyOverrides
): string {
  const name = personaName || "their loved one";
  const policyHint = policyOverrides?.toneGuidance
    ? `\nCONTEXT: This is about a caregiver supporting ${name}. Tone: ${policyOverrides.toneGuidance}`
    : `\nCONTEXT: This is about a caregiver supporting ${name}.`;

  return `${SAFETY_SYSTEM}
${policyHint}

A caregiver just recorded a voice note describing what happened. The voice note was transcribed to text below.

Your task is to read the transcript and extract a structured incident summary.

TRANSCRIPT:
"${transcript}"

Extract the incident details from this transcript. Infer what is not explicit but reasonable. Return a single JSON object only (no markdown). The response format is defined by the structured output schema for this request.

Rules:
- incident_category: pick the single most relevant category
- intensity: 1=very mild, 2=mild, 3=moderate, 4=intense, 5=very intense — infer from language and tone
- possible_trigger, what_user_already_tried, desired_outcome: null if genuinely not mentioned
- safety_flag: true ONLY if the transcript suggests risk of harm to self or others
- confidence: reflect how clearly the transcript described the incident (0.0-1.0)
- Never invent information not in the transcript`;
}

// ─── Routine suggestion (reflection → reusable routine) ─────────────────────

export const ROUTINE_SUGGESTION_SCHEMA = {
  type: "object",
  required: ["title", "steps", "frequency"],
  properties: {
    title: {
      type: "string",
      minLength: 1,
      description: "Short, memorable name for the routine (e.g. 'Morning wind-down').",
    },
    steps: {
      type: "array",
      minItems: 1,
      maxItems: 10,
      items: { type: "string" },
      description: "Ordered steps the caregiver can repeat; each step one concrete action.",
    },
    frequency: {
      type: "string",
      enum: ["daily", "weekdays", "weekends", "weekly", "as-needed"],
      description: "Cadence that matches the caregiver's capacity and the plan context.",
    },
    estimatedDurationMinutes: {
      type: "number",
      minimum: 1,
      description: "Total minutes for the full routine once (optional but helpful when stated).",
    },
    tags: {
      type: "array",
      items: { type: "string" },
      description: "Optional labels such as 'bedtime', 'transition', 'connection'.",
    },
    rationale: {
      type: "string",
      description: "One or two sentences tying the routine to what helped in the reflection or plan.",
    },
  },
};

const ROUTINE_PERSONA_HINTS: Record<string, string> = {
  child: "bedtime wind-down, morning transitions, sensory breaks",
  parent: "connection moments, medication routines, gentle structure",
  partner: "check-ins, shared downtime, practical support",
  sibling: "peer connection, boundaries, shared care moments",
  familyMember: "flexible check-ins, coordination, practical help",
};

export interface RoutineSuggestionContext {
  planSummary: string;
  whatToDoNow: string[];
  followUpTasks: string[];
  reflectionNotes?: string;
  stepsHelpedMost?: string[];
  personaTypeKey?: string;
}

export function buildRoutineSuggestionPrompt(ctx: RoutineSuggestionContext): string {
  const personaKey = ctx.personaTypeKey ?? "child";
  const examples = ROUTINE_PERSONA_HINTS[personaKey] ?? ROUTINE_PERSONA_HINTS["child"];
  const helped = ctx.stepsHelpedMost?.filter(Boolean).join("; ") || "not specified";

  return `${SAFETY_SYSTEM}

You are Crucue, a calm caregiving companion.

TASK: Suggest one practical reusable routine based on a completed support-plan reflection.

SUPPORT PLAN SUMMARY:
${ctx.planSummary}

PLAN STEPS (what to do):
${JSON.stringify(ctx.whatToDoNow, null, 2)}

FOLLOW-UP TASKS:
${JSON.stringify(ctx.followUpTasks, null, 2)}

REFLECTION NOTES:
${ctx.reflectionNotes?.trim() || "none"}

STEPS THAT HELPED MOST:
${helped}

PERSONA CONTEXT (${personaKey}): consider routines like: ${examples}

Return ONLY valid JSON matching the schema (no markdown). Use clear, actionable step text.`;
}
