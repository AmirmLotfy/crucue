import { Router, Response } from 'express';
import { requireAuth } from '../middleware/auth';
import { validateBody } from '../middleware/validation';
import { RequestWithUser, logger } from '../middleware/logging';
import { generate } from '../ai/vertex-client';
import { buildSupportPlanPrompt } from '../ai/prompt-builder';
import { parseAndValidate } from '../ai/schema-validator';
import { SUPPORT_PLAN_SCHEMA, GENERATE_PLAN_REQUEST_SCHEMA } from '../schemas/support-plan';
import { config } from '../config';

const router = Router();

/**
 * POST /api/v1/generate-plan
 *
 * Generates a structured support plan for a caregiver using Gemma 4.
 *
 * Body: { profileId, incidentId?, personaData?, challenges?, incidentContext?, personaTypeKey? }
 * Returns: Support plan JSON (summary, steps[], messageDraft?, safetyNote?, followUpQuestions?)
 */
router.post(
  '/generate-plan',
  requireAuth,
  validateBody(GENERATE_PLAN_REQUEST_SCHEMA),
  async (req: RequestWithUser, res: Response) => {
    const { profileId, incidentId, personaData, challenges, incidentContext, personaTypeKey } =
      req.body;

    logger.info({
      message: 'generate-plan request',
      uid: req.uid,
      profileId,
      personaTypeKey,
    });

    try {
      const prompt = buildSupportPlanPrompt({
        profileId,
        personaData,
        challenges,
        incidentContext,
        personaTypeKey,
      });

      const rawText = await generate({
        prompt,
        model: config.models.default,
        maxTokens: 1500,
        temperature: 0.35,
        responseSchema: SUPPORT_PLAN_SCHEMA,
      });

      const plan = parseAndValidate(rawText, SUPPORT_PLAN_SCHEMA, 'generate-plan');

      res.json({ success: true, plan, incidentId });
    } catch (err) {
      logger.error({ message: 'generate-plan failed', uid: req.uid, error: String(err) });
      res.status(500).json({ error: 'Failed to generate support plan. Please try again.' });
    }
  }
);

export default router;
