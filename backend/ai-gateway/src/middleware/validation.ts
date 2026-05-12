import { Request, Response, NextFunction } from 'express';
import Ajv, { JSONSchemaType, ValidateFunction } from 'ajv';
import addFormats from 'ajv-formats';

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

/**
 * Returns an Express middleware that validates `req.body` against the given
 * JSON Schema. Responds with 400 and error details on failure.
 */
export function validateBody<T>(schema: object): (req: Request, res: Response, next: NextFunction) => void {
  const validate = ajv.compile(schema);

  return (req: Request, res: Response, next: NextFunction): void => {
    const valid = validate(req.body);
    if (!valid) {
      res.status(400).json({
        error: 'Request body validation failed.',
        details: validate.errors?.map((e) => ({
          field: e.instancePath || e.schemaPath,
          message: e.message,
        })),
      });
      return;
    }
    next();
  };
}

/**
 * Validates AI-generated JSON output against a schema.
 * Returns `true` on success, throws on failure.
 *
 * Used by routes to ensure AI output conforms to the expected schema
 * before returning it to the client.
 */
export function validateOutput<T>(data: unknown, schema: object): T {
  const validate = ajv.compile(schema);
  if (!validate(data)) {
    const errors = validate.errors?.map((e) => `${e.instancePath}: ${e.message}`).join('; ');
    throw new Error(`AI output schema validation failed: ${errors}`);
  }
  return data as T;
}
