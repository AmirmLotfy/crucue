import { Router, Response } from 'express';
import { requireAuth } from '../middleware/auth';
import { validateBody } from '../middleware/validation';
import { RequestWithUser, logger } from '../middleware/logging';
import { generate } from '../ai/vertex-client';
import { buildChatPrompt } from '../ai/prompt-builder';
import { config } from '../config';

const router = Router();

/**
 * POST /api/v1/chat
 *
 * Sends a grounded chat message and returns the AI response.
 * Context is enriched from the profile, active plan, and recent check-ins.
 *
 * Body: { profileId, userMessage, planId?, threadId?, history?, personaTypeKey? }
 * Returns: { message: string, suggestedFollowUps?: string[], safetyFlag?: boolean }
 */
router.post(
  '/chat',
  requireAuth,
  validateBody({
    type: 'object',
    required: ['profileId', 'userMessage'],
    properties: {
      profileId: { type: 'string' },
      userMessage: { type: 'string', minLength: 1 },
      planId: { type: 'string' },
      threadId: { type: 'string' },
      history: { type: 'array' },
      personaTypeKey: { type: 'string' },
    },
  }),
  async (req: RequestWithUser, res: Response) => {
    const { profileId, userMessage, planId, threadId, history, personaTypeKey } = req.body;

    logger.info({
      message: 'chat request',
      uid: req.uid,
      profileId,
      personaTypeKey,
    });

    try {
      const prompt = buildChatPrompt({
        profileId,
        planId,
        userMessage,
        history,
        personaTypeKey,
      });

      const rawText = await generate({
        prompt,
        model: config.models.default,
        maxTokens: 512,
        temperature: 0.5,
        topP: 0.95,
      });

      res.json({
        success: true,
        message: rawText.trim(),
        threadId,
      });
    } catch (err) {
      logger.error({ message: 'chat failed', uid: req.uid, error: String(err) });
      res.status(500).json({ error: 'Failed to get response. Please try again.' });
    }
  }
);

export default router;
