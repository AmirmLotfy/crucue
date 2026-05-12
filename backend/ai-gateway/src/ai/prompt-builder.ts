import { PersonaPolicy, personaPolicies } from '../policies/persona-policies';
import { safetyPreamble } from '../policies/safety';

/**
 * Builds structured prompts for each Gemma 4 inference endpoint.
 *
 * All prompts follow the same structure:
 *   [SYSTEM]: safety preamble + persona policy + task instruction
 *   [USER]: serialized context + user input
 *
 * Gemma 4 uses structured JSON output when a responseSchema is provided.
 * The prompt explicitly instructs the model to return JSON only.
 */

export interface IncidentExtractionContext {
  transcript: string;
  personaTypeKey?: string;
}

export interface SupportPlanContext {
  profileId: string;
  personaData?: Record<string, unknown>;
  challenges?: string[];
  incidentContext?: Record<string, unknown>;
  personaTypeKey?: string;
}

export interface ChatContext {
  profileId: string;
  planId?: string;
  userMessage: string;
  history?: Array<{ role: string; content: string }>;
  personaTypeKey?: string;
  recentCheckIns?: Array<Record<string, unknown>>;
}

export interface PatternSummaryContext {
  profileId: string;
  incidents: Array<Record<string, unknown>>;
  plans: Array<Record<string, unknown>>;
  checkIns: Array<Record<string, unknown>>;
  weekStart?: string;
}

export interface RoutineSuggestionContext {
  profileId: string;
  planId: string;
  reflectionNotes?: string;
  stepsHelpedMost?: string[];
  personaTypeKey?: string;
}

function getPolicy(personaTypeKey?: string): PersonaPolicy {
  return personaPolicies[personaTypeKey ?? 'child'] ?? personaPolicies['child'];
}

export function buildIncidentExtractionPrompt(ctx: IncidentExtractionContext): string {
  const policy = getPolicy(ctx.personaTypeKey);
  return `${safetyPreamble}

You are a compassionate caregiving AI assistant. ${policy.toneGuidance}

TASK: Extract structured incident information from the following caregiver voice note transcript.

Return ONLY a valid JSON object matching this structure (no markdown, no explanation):
{
  "whatHappened": "clear description of the incident",
  "possibleTrigger": "what may have caused it, or null",
  "whatWasAlreadyTried": "strategies already attempted, or null",
  "desiredOutcome": "what the caregiver hopes for, or null",
  "safetyFlag": false,
  "confidenceScore": 0.0
}

TRANSCRIPT:
"""
${ctx.transcript}
"""`;
}

export function buildSupportPlanPrompt(ctx: SupportPlanContext): string {
  const policy = getPolicy(ctx.personaTypeKey);
  const persona = JSON.stringify(ctx.personaData ?? {}, null, 2);
  const challenges = ctx.challenges?.join(', ') ?? 'not specified';
  const incident = JSON.stringify(ctx.incidentContext ?? {}, null, 2);

  return `${safetyPreamble}

You are a compassionate caregiving AI assistant. ${policy.toneGuidance}
Suggestion types to focus on: ${policy.suggestionTypes.join(', ')}.

TASK: Create a structured support plan for a caregiver.

CARE PROFILE:
${persona}

CHALLENGES:
${challenges}

INCIDENT CONTEXT:
${incident}

Return ONLY a valid JSON object. Do not add markdown or explanations.`;
}

export function buildChatPrompt(ctx: ChatContext): string {
  const policy = getPolicy(ctx.personaTypeKey);
  const historyText = (ctx.history ?? [])
    .map((m) => `${m.role === 'user' ? 'Caregiver' : 'Assistant'}: ${m.content}`)
    .join('\n');
  const checkInText = ctx.recentCheckIns?.length
    ? `\nRECENT REFLECTIONS:\n${JSON.stringify(ctx.recentCheckIns, null, 2)}`
    : '';

  return `${safetyPreamble}

You are a compassionate caregiving AI assistant. ${policy.toneGuidance}
${policy.messageDraftStyle ? `Communication style: ${policy.messageDraftStyle}` : ''}

Your responses must be:
- Grounded in the caregiver's context (profile, active plan, reflections)
- Practical and immediately actionable
- Calm, non-judgmental, and supportive
- Concise (2–4 sentences unless more detail is clearly needed)
${checkInText}

CONVERSATION HISTORY:
${historyText}

Caregiver: ${ctx.userMessage}
Assistant:`;
}

export function buildPatternSummaryPrompt(ctx: PatternSummaryContext): string {
  return `${safetyPreamble}

You are a compassionate caregiving AI assistant analyzing a week of care data.

TASK: Identify patterns, what worked, and actionable suggestions for the coming week.

INCIDENTS (${ctx.incidents.length}):
${JSON.stringify(ctx.incidents, null, 2)}

PLANS (${ctx.plans.length}):
${JSON.stringify(ctx.plans, null, 2)}

CHECK-INS (${ctx.checkIns.length}):
${JSON.stringify(ctx.checkIns, null, 2)}

Return ONLY a valid JSON object. Do not add markdown or explanations.`;
}

export function buildRoutineSuggestionPrompt(ctx: RoutineSuggestionContext): string {
  const policy = getPolicy(ctx.personaTypeKey);
  const examples = policy.routineExamples?.join(', ') ?? 'none';

  return `${safetyPreamble}

You are a compassionate caregiving AI assistant. ${policy.toneGuidance}

TASK: Suggest a daily routine based on a completed plan reflection.

PLAN ID: ${ctx.planId}
REFLECTION NOTES: ${ctx.reflectionNotes ?? 'none provided'}
STEPS THAT HELPED MOST: ${ctx.stepsHelpedMost?.join(', ') ?? 'not specified'}
EXAMPLE ROUTINES FOR THIS PERSONA: ${examples}

Return ONLY a valid JSON object with this structure:
{
  "title": "routine name",
  "steps": ["step 1", "step 2"],
  "frequency": "daily | weekdays | weekly | as-needed",
  "estimatedDurationMinutes": 15,
  "tags": ["tag1"],
  "rationale": "why this routine will help"
}`;
}
