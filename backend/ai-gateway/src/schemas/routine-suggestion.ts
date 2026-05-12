/** JSON Schema for routine suggestion output from Gemma 4. */
export const ROUTINE_SUGGESTION_SCHEMA = {
  type: 'object',
  required: ['title', 'steps', 'frequency'],
  properties: {
    title: {
      type: 'string',
      minLength: 1,
      description: 'Name of the suggested routine',
    },
    steps: {
      type: 'array',
      minItems: 1,
      maxItems: 10,
      items: { type: 'string' },
      description: 'Ordered list of routine steps',
    },
    frequency: {
      type: 'string',
      enum: ['daily', 'weekdays', 'weekends', 'weekly', 'as-needed'],
      description: 'How often the routine should be performed',
    },
    estimatedDurationMinutes: {
      type: 'number',
      minimum: 1,
      description: 'Total estimated time for the routine in minutes',
    },
    tags: {
      type: 'array',
      items: { type: 'string' },
      description: 'Category tags for the routine',
    },
    rationale: {
      type: 'string',
      description: 'Why this routine is suggested based on the reflection',
    },
  },
  additionalProperties: false,
} as const;

/** Request body schema for POST /api/v1/suggest-routine */
export const SUGGEST_ROUTINE_REQUEST_SCHEMA = {
  type: 'object',
  required: ['profileId', 'planId'],
  properties: {
    profileId: { type: 'string' },
    planId: { type: 'string' },
    reflectionNotes: { type: 'string' },
    stepsHelpedMost: { type: 'array', items: { type: 'string' } },
    personaTypeKey: { type: 'string' },
  },
  additionalProperties: false,
} as const;
