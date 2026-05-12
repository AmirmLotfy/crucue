/**
 * Remote Gemma 4 model resource names for the Gemini Developer API (Google AI Studio).
 * Use instruction-tuned (-it) IDs as documented for generateContent.
 *
 * @see https://ai.google.dev/gemma/docs/core/gemma_on_gemini_api
 */
export const DEFAULT_REMOTE_GEMMA_MODEL = "gemma-4-26b-a4b-it";

/**
 * Optional premium / deeper reasoning tier (31B dense, instruction-tuned).
 * Set Firebase secret `GEMMA4_MODEL` to this value to A/B against the default;
 * Cloud Functions log line timings (e.g. `generateSupportPlan: model=... ms=...`) for comparison.
 */
export const PREMIUM_REMOTE_GEMMA_MODEL = "gemma-4-31b-it";
