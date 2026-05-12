/** JSON Schema for incident extraction output from Gemma 4 voice processing. */
export const INCIDENT_EXTRACTION_SCHEMA = {
  type: 'object',
  required: ['whatHappened'],
  properties: {
    whatHappened: {
      type: 'string',
      minLength: 1,
      description: 'Clear description of what happened during the incident',
    },
    possibleTrigger: {
      type: ['string', 'null'],
      description: 'What may have triggered the incident',
    },
    whatWasAlreadyTried: {
      type: ['string', 'null'],
      description: 'Strategies the caregiver already attempted',
    },
    desiredOutcome: {
      type: ['string', 'null'],
      description: "What the caregiver hopes for going forward",
    },
    safetyFlag: {
      type: 'boolean',
      description: 'True if the incident involves immediate safety concerns',
    },
    confidenceScore: {
      type: 'number',
      minimum: 0,
      maximum: 1,
      description: 'Model confidence in the extraction (0.0–1.0)',
    },
  },
  additionalProperties: false,
} as const;

/** Request body schema for POST /api/v1/extract-incident */
export const EXTRACT_INCIDENT_REQUEST_SCHEMA = {
  type: 'object',
  required: ['voiceNoteId', 'profileId', 'audioStoragePath'],
  properties: {
    voiceNoteId: { type: 'string' },
    profileId: { type: 'string' },
    audioStoragePath: { type: 'string' },
    personaTypeKey: { type: 'string' },
  },
  additionalProperties: false,
} as const;
