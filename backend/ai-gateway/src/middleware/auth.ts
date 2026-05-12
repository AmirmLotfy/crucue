import { Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import { RequestWithUser, logger } from './logging';

/** Verifies the Firebase Auth ID token in the Authorization header.
 *
 * Attaches `req.uid` on success. Returns 401 if the token is missing
 * or invalid.
 */
export async function requireAuth(
  req: RequestWithUser,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header.' });
    return;
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.uid = decoded.uid;
    next();
  } catch (err) {
    logger.warn({ message: 'Auth token verification failed', error: String(err) });
    res.status(401).json({ error: 'Unauthorized: invalid or expired token.' });
  }
}
