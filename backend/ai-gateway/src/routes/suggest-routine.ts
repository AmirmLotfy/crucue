import { Router, Response } from 'express';
import { requireAuth } from '../middleware/auth';
import { validateBody } from '../middleware/validation';
import { RequestWithUser, logger } from '../middleware/logging';
import { generate } from '../ai/vertex-client';
import { buildRoutineSuggestionPrompt } from '../ai/prompt-builder';
import { parseAndValidate } from '../ai/schema-validator';
import {
  ROUTINE_SUGGESTION_SCHEMA,
  SUGGEST_ROUTINE_REQUEST_SCHEMA,
} from '../schemas/routine-suggestion';
import { config } from '../config';

const router = Router();

/**
 * POST /api/v1/suggest-routine
 *
 * Suggests a new routine based on a completed plan check-in reflection.
 * This is the gateway implementation of AiEngine.suggestRoutineFromReflection().
 *
 * Body: { profileId, planId, reflectionNotes?, stepsHelpedMost?, personaTypeKey? }
 * Returns: { title, steps, frequency, estimatedDurationMinutes, tags, rationale }
 */
router.post(
  '/suggest-routine',
  requireAuth,
  validateBody(SUGGEST_ROUTINE_REQUEST_SCHEMA),
  async (req: RequestWithUser, res: Response) => {
    const { profileId, planId, reflectionNotes, stepsHelpedMost, personaTypeKey } = req.body;

    logger.info({
      message: 'suggest-routine request',
      uid: req.uid,
      profileId,
      planId,
      personaTypeKey,
    });

    try {
      const prompt = buildRoutineSuggestionPrompt({
        profileId,
        planId,
        reflectionNotes,
        stepsHelpedMost,
        personaTypeKey,
      });

      const rawText = await generate({
        prompt,
        model: config.models.default,
        maxTokens: 512,
        temperature: 0.4,
        responseSchema: ROUTINE_SUGGESTION_SCHEMA,
      });

      const routine = parseAndValidate(rawText, ROUTINE_SUGGESTION_SCHEMA, 'suggest-routine');

      res.json({ success: true, routine });
    } catch (err) {
      logger.error({ message: 'suggest-routine failed', uid: req.uid, error: String(err) });
      res.status(500).json({ error: 'Failed to suggest routine. Please try again.' });
    }
  }
);

export default router;
