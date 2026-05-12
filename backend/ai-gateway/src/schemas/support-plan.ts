/** JSON Schema for support plan output from Gemma 4. */
export const SUPPORT_PLAN_SCHEMA = {
  type: 'object',
  required: ['summary', 'steps'],
  properties: {
    summary: {
      type: 'string',
      minLength: 1,
      description: 'A compassionate 2–3 sentence summary of the situation and suggested approach',
    },
    steps: {
      type: 'array',
      minItems: 1,
      maxItems: 8,
      items: {
        type: 'object',
        required: ['title', 'description'],
        properties: {
          title: { type: 'string' },
          description: { type: 'string' },
          estimatedMinutes: { type: 'number' },
          tags: { type: 'array', items: { type: 'string' } },
        },
        additionalProperties: false,
      },
    },
    messageDraft: {
      type: ['string', 'null'],
      description: 'Optional draft message the caregiver could send or say to their loved one',
    },
    safetyNote: {
      type: ['string', 'null'],
      description: 'Safety note if any safety concerns were detected',
    },
    followUpQuestions: {
      type: 'array',
      items: { type: 'string' },
      description: 'Optional clarifying questions to deepen the plan',
    },
  },
  additionalProperties: false,
} as const;

/** Request body schema for POST /api/v1/generate-plan */
export const GENERATE_PLAN_REQUEST_SCHEMA = {
  type: 'object',
  required: ['profileId'],
  properties: {
    profileId: { type: 'string' },
    incidentId: { type: 'string' },
    personaData: { type: 'object' },
    challenges: { type: 'array', items: { type: 'string' } },
    incidentContext: { type: 'object' },
    personaTypeKey: { type: 'string' },
  },
  additionalProperties: false,
} as const;
