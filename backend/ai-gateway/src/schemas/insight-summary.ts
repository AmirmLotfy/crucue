/** JSON Schema for weekly insight summary output from Gemma 4. */
export const INSIGHT_SUMMARY_SCHEMA = {
  type: 'object',
  required: ['summary', 'patterns'],
  properties: {
    summary: {
      type: 'string',
      minLength: 1,
      description: 'A 2–3 sentence summary of the week in caregiving',
    },
    patterns: {
      type: 'array',
      items: { type: 'string' },
      description: 'Recurring patterns observed across incidents and plans',
    },
    whatWorked: {
      type: 'array',
      items: { type: 'string' },
      description: 'Strategies that appeared effective this week',
    },
    suggestions: {
      type: 'array',
      items: { type: 'string' },
      description: 'Actionable suggestions for the coming week',
    },
    moodTrend: {
      type: ['string', 'null'],
      enum: ['improving', 'stable', 'declining', null],
      description: 'Overall mood/stress trend inferred from check-ins',
    },
  },
  additionalProperties: false,
} as const;

/** Request body schema for POST /api/v1/summarize-patterns */
export const SUMMARIZE_PATTERNS_REQUEST_SCHEMA = {
  type: 'object',
  required: ['profileId'],
  properties: {
    profileId: { type: 'string' },
    weekStart: { type: 'string', format: 'date' },
  },
  additionalProperties: false,
} as const;
