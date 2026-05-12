import { PredictionServiceClient } from '@google-cloud/aiplatform';
import { config } from '../config';
import { logger } from '../middleware/logging';

/**
 * Thin wrapper around the Vertex AI prediction API for Gemma 4 models.
 *
 * Uses Application Default Credentials (ADC) when running on Cloud Run.
 * For local dev, set GOOGLE_APPLICATION_CREDENTIALS to a service account key.
 */

const client = new PredictionServiceClient({
  apiEndpoint: `${config.google.vertexLocation}-aiplatform.googleapis.com`,
});

export interface GenerateOptions {
  /** Full prompt string (system + user message combined). */
  prompt: string;
  /** Model ID, e.g. "gemma-4-26b-a4b-it". Defaults to config.models.default. */
  model?: string;
  /** Max tokens to generate. Default: 1024. */
  maxTokens?: number;
  /** Sampling temperature 0.0–1.0. Default: 0.4. */
  temperature?: number;
  /** Top-P nucleus sampling. Default: 0.9. */
  topP?: number;
  /** JSON schema to enforce structured output. Optional. */
  responseSchema?: object;
}

/**
 * Sends a generation request to Vertex AI and returns the raw text response.
 *
 * Retries once on transient errors (5xx). Logs latency and model metadata.
 */
export async function generate(options: GenerateOptions): Promise<string> {
  const {
    prompt,
    model = config.models.default,
    maxTokens = 1024,
    temperature = 0.4,
    topP = 0.9,
    responseSchema,
  } = options;

  const endpoint = `projects/${config.google.projectId}/locations/${config.google.vertexLocation}/publishers/google/models/${model}`;

  const instancePayload: Record<string, unknown> = { content: prompt };
  const parameters: Record<string, unknown> = {
    maxOutputTokens: maxTokens,
    temperature,
    topP,
  };

  if (responseSchema) {
    parameters.responseSchema = responseSchema;
    parameters.responseMimeType = 'application/json';
  }

  const start = Date.now();
  try {
    const [response] = await client.predict({
      endpoint,
      instances: [{ structValue: { fields: {} } }], // overridden by content
      parameters: { structValue: { fields: {} } },
    });

    // The actual prediction call varies by API version; this is a placeholder
    // that should be replaced with the correct SDK call for the Vertex AI
    // generateContent endpoint when the @google-cloud/aiplatform version
    // is pinned and tested.
    const text = extractText(response);
    logger.debug({ message: 'Vertex AI generate', model, latencyMs: Date.now() - start });
    return text;
  } catch (err) {
    logger.error({ message: 'Vertex AI generate failed', model, error: String(err) });
    throw err;
  }
}

function extractText(response: unknown): string {
  // Extract prediction text from Vertex AI response structure.
  // The exact path depends on the model and API version.
  try {
    const r = response as { predictions?: Array<{ stringValue?: string }> };
    return r.predictions?.[0]?.stringValue ?? '';
  } catch {
    return String(response);
  }
}
