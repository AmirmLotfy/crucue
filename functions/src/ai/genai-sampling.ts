/**
 * Gemma 4 generation defaults aligned with the official model card sampling table
 * (temperature / top_p / top_k). We apply the documented top_p and top_k on every
 * Cloud Functions call; temperature is tuned per task because structured JSON and
 * extraction benefit from lower values than open-ended chat.
 *
 * @see https://ai.google.dev/gemma/docs/core/model_card_4 — "Best Practices" sampling
 */

/** Model-card defaults for nucleus and top-k sampling (used with all remote Gemma calls). */
export const GEMMA4_MODEL_CARD_TOP_P = 0.95;
export const GEMMA4_MODEL_CARD_TOP_K = 64;

/** Per-flow temperatures (see docs/gemma4_strategy.md). */
export const GEMMA4_TEMP_VOICE_EXTRACT = 0.3;
export const GEMMA4_TEMP_ROUTINE_SUGGEST = 0.4;
export const GEMMA4_TEMP_WEEKLY_INSIGHT = 0.6;
export const GEMMA4_TEMP_SUPPORT_PLAN = 0.7;
export const GEMMA4_TEMP_CHAT = 0.8;

export interface BaseSamplingConfig {
  temperature: number;
  maxOutputTokens: number;
  topP: number;
  topK: number;
}

/** Base fields included in every `generateContent` config (plus task-specific fields). */
export function gemma4BaseSampling(overrides: {
  temperature: number;
  maxOutputTokens: number;
}): BaseSamplingConfig {
  return {
    temperature: overrides.temperature,
    maxOutputTokens: overrides.maxOutputTokens,
    topP: GEMMA4_MODEL_CARD_TOP_P,
    topK: GEMMA4_MODEL_CARD_TOP_K,
  };
}
