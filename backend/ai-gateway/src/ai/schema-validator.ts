import { validateOutput } from '../middleware/validation';
import { logger } from '../middleware/logging';

/**
 * Validates AI output JSON against a schema with graceful fallback.
 *
 * If the AI response is a raw JSON string, parses it first. If schema
 * validation fails, logs the error and returns the partial data rather
 * than crashing the request — the client should handle incomplete data.
 */
export function parseAndValidate<T>(rawText: string, schema: object, label: string): Partial<T> {
  let parsed: unknown;

  // Strip markdown code fences if present (some models include them)
  const cleaned = rawText.replace(/^```(?:json)?\n?/m, '').replace(/\n?```$/m, '').trim();

  try {
    parsed = JSON.parse(cleaned);
  } catch (err) {
    logger.warn({ message: `${label}: failed to parse JSON`, raw: cleaned.slice(0, 200) });
    return {};
  }

  try {
    return validateOutput<T>(parsed, schema);
  } catch (err) {
    logger.warn({ message: `${label}: schema validation failed`, error: String(err) });
    // Return parsed data anyway — partial is better than nothing
    return parsed as Partial<T>;
  }
}
