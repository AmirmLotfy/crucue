import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { requireAuth } from '../middleware/auth';
import { validateBody } from '../middleware/validation';
import { RequestWithUser, logger } from '../middleware/logging';
import { generate } from '../ai/vertex-client';
import { buildPatternSummaryPrompt } from '../ai/prompt-builder';
import { parseAndValidate } from '../ai/schema-validator';
import {
  INSIGHT_SUMMARY_SCHEMA,
  SUMMARIZE_PATTERNS_REQUEST_SCHEMA,
} from '../schemas/insight-summary';
import { config } from '../config';

const router = Router();

/**
 * POST /api/v1/summarize-patterns
 *
 * Analyzes a week of incidents, plans, and check-ins to generate an
 * AI-powered weekly insight summary.
 *
 * Body: { profileId, weekStart? }
 * Returns: { summary, patterns, whatWorked, suggestions, moodTrend? }
 */
router.post(
  '/summarize-patterns',
  requireAuth,
  validateBody(SUMMARIZE_PATTERNS_REQUEST_SCHEMA),
  async (req: RequestWithUser, res: Response) => {
    const { profileId, weekStart } = req.body;

    logger.info({
      message: 'summarize-patterns request',
      uid: req.uid,
      profileId,
      weekStart,
    });

    try {
      const db = admin.firestore();
      const weekStartDate = weekStart ? new Date(weekStart) : getWeekStart();
      const weekEndDate = new Date(weekStartDate);
      weekEndDate.setDate(weekEndDate.getDate() + 7);

      const [incidentsSnap, plansSnap, checkInsSnap] = await Promise.all([
        db
          .collection(`users/${req.uid}/profiles/${profileId}/incidents`)
          .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(weekStartDate))
          .where('createdAt', '<', admin.firestore.Timestamp.fromDate(weekEndDate))
          .orderBy('createdAt', 'desc')
          .limit(20)
          .get(),
        db
          .collection(`users/${req.uid}/profiles/${profileId}/plans`)
          .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(weekStartDate))
          .where('createdAt', '<', admin.firestore.Timestamp.fromDate(weekEndDate))
          .limit(10)
          .get(),
        db
          .collection(`users/${req.uid}/profiles/${profileId}/checkIns`)
          .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(weekStartDate))
          .where('createdAt', '<', admin.firestore.Timestamp.fromDate(weekEndDate))
          .limit(20)
          .get(),
      ]);

      const incidents = incidentsSnap.docs.map((d) => d.data());
      const plans = plansSnap.docs.map((d) => d.data());
      const checkIns = checkInsSnap.docs.map((d) => d.data());

      const prompt = buildPatternSummaryPrompt({
        profileId,
        incidents,
        plans,
        checkIns,
        weekStart: weekStartDate.toISOString(),
      });

      const rawText = await generate({
        prompt,
        model: config.models.default,
        maxTokens: 1024,
        temperature: 0.3,
        responseSchema: INSIGHT_SUMMARY_SCHEMA,
      });

      const summary = parseAndValidate(rawText, INSIGHT_SUMMARY_SCHEMA, 'summarize-patterns');

      res.json({ success: true, summary, weekStart: weekStartDate.toISOString() });
    } catch (err) {
      logger.error({ message: 'summarize-patterns failed', uid: req.uid, error: String(err) });
      res.status(500).json({ error: 'Failed to generate weekly insights. Please try again.' });
    }
  }
);

function getWeekStart(): Date {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(now.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  return monday;
}

export default router;
