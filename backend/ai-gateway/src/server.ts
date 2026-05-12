/**
 * Crucue AI Gateway — Cloud Run service entry point.
 *
 * Orchestrates all Gemma 4 AI inference for the Crucue app:
 * - POST /api/v1/extract-incident  — voice incident extraction
 * - POST /api/v1/generate-plan     — AI support plan generation
 * - POST /api/v1/chat              — grounded care chat
 * - POST /api/v1/summarize-patterns — weekly insight summary
 * - POST /api/v1/suggest-routine   — routine suggestion from reflection
 *
 * All endpoints require Firebase Auth. Requests are logged with
 * Cloud Logging-compatible JSON, validated with AJV, and rate-limited.
 *
 * Deploy: gcloud run deploy crucue-ai-gateway --source . --region us-central1
 */

import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import * as admin from 'firebase-admin';

import { config } from './config';
import { requestLogger, logger } from './middleware/logging';

import extractIncidentRouter from './routes/extract-incident';
import generatePlanRouter from './routes/generate-plan';
import chatRouter from './routes/chat';
import summarizePatternsRouter from './routes/summarize-patterns';
import suggestRoutineRouter from './routes/suggest-routine';

// ─── Firebase Admin init ──────────────────────────────────────────────────────

admin.initializeApp({
  projectId: config.google.projectId,
});

// ─── Express app ─────────────────────────────────────────────────────────────

const app = express();

// Security headers
app.use(helmet());

// CORS — allow only the Firebase Hosting domain and localhost for dev
app.use(
  cors({
    origin:
      config.server.isProd
        ? [`https://${config.google.projectId}.web.app`, `https://${config.google.projectId}.firebaseapp.com`]
        : '*',
    methods: ['POST', 'GET', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Body parsing
app.use(express.json({ limit: '1mb' }));

// Structured request logging
app.use(requestLogger);

// Rate limiting — 60 requests per minute per IP
app.use(
  '/api',
  rateLimit({
    windowMs: config.rateLimit.windowMs,
    max: config.rateLimit.maxRequests,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests. Please try again in a moment.' },
  })
);

// ─── Routes ───────────────────────────────────────────────────────────────────

app.use('/api/v1', extractIncidentRouter);
app.use('/api/v1', generatePlanRouter);
app.use('/api/v1', chatRouter);
app.use('/api/v1', summarizePatternsRouter);
app.use('/api/v1', suggestRoutineRouter);

// Health check — no auth required (used by Cloud Run and Docker HEALTHCHECK)
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'crucue-ai-gateway',
    model: config.models.default,
    timestamp: new Date().toISOString(),
  });
});

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found.' });
});

// Global error handler
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error({ message: 'Unhandled error', error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error.' });
});

// ─── Start ────────────────────────────────────────────────────────────────────

const port = config.server.port;
app.listen(port, () => {
  logger.info({
    message: 'Crucue AI Gateway started',
    port,
    model: config.models.default,
    env: config.server.nodeEnv,
  });
});

export default app;
