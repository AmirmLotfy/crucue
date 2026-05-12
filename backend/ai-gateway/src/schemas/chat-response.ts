/** JSON Schema for grounded chat response output. */
export const CHAT_RESPONSE_SCHEMA = {
  type: 'object',
  required: ['message'],
  properties: {
    message: {
      type: 'string',
      minLength: 1,
      description: 'The AI assistant response message',
    },
    suggestedFollowUps: {
      type: 'array',
      items: { type: 'string' },
      description: 'Optional 2–3 follow-up questions or actions the caregiver might take',
    },
    safetyFlag: {
      type: 'boolean',
      description: 'True if safety concern detected in the user message',
    },
  },
  additionalProperties: false,
} as const;

/** Request body schema for POST /api/v1/chat */
export const CHAT_REQUEST_SCHEMA = {
  type: 'object',
  required: ['profileId', 'userMessage'],
  properties: {
    profileId: { type: 'string' },
    planId: { type: 'string' },
    userMessage: { type: 'string', minLength: 1 },
    threadId: { type: 'string' },
    history: {
      type: 'array',
      items: {
        type: 'object',
        required: ['role', 'content'],
        properties: {
          role: { type: 'string', enum: ['user', 'assistant'] },
          content: { type: 'string' },
        },
      },
    },
    personaTypeKey: { type: 'string' },
  },
  additionalProperties: false,
} as const;
