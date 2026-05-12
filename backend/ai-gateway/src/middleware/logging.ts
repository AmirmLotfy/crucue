import { Request, Response, NextFunction } from 'express';
import winston from 'winston';

/** Structured JSON logger for Cloud Logging compatibility. */
export const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()],
});

/** Express middleware that logs every request and response with Cloud Logging fields. */
export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();

  res.on('finish', () => {
    const durationMs = Date.now() - start;
    const logEntry = {
      httpRequest: {
        requestMethod: req.method,
        requestUrl: req.originalUrl,
        status: res.statusCode,
        userAgent: req.get('user-agent') ?? '',
        remoteIp: req.ip ?? '',
        latency: `${durationMs}ms`,
      },
      uid: (req as RequestWithUser).uid ?? null,
    };

    if (res.statusCode >= 500) {
      logger.error(logEntry);
    } else if (res.statusCode >= 400) {
      logger.warn(logEntry);
    } else {
      logger.info(logEntry);
    }
  });

  next();
}

// Augment Request type to carry authenticated uid
export interface RequestWithUser extends Request {
  uid?: string;
}
