/**
 * Centralized environment configuration for the Crucue AI Gateway.
 *
 * All env vars are validated at startup. Missing required vars throw immediately
 * rather than failing silently during request handling.
 */

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function optional(name: string, defaultValue: string): string {
  return process.env[name] ?? defaultValue;
}

export const config = {
  server: {
    port: parseInt(optional('PORT', '8080'), 10),
    nodeEnv: optional('NODE_ENV', 'development'),
    get isProd(): boolean {
      return this.nodeEnv === 'production';
    },
  },

  google: {
    projectId: optional('GOOGLE_CLOUD_PROJECT', 'octifyai'),
    vertexLocation: optional('VERTEX_AI_LOCATION', 'us-central1'),
  },

  models: {
    /** Default remote model: Gemma 4 26B Mixture-of-Experts */
    default: optional('GEMMA4_DEFAULT_MODEL', 'gemma-4-26b-a4b-it'),
    /** Premium remote model: Gemma 4 31B dense */
    premium: optional('GEMMA4_PREMIUM_MODEL', 'gemma-4-31b-it'),
    /** On-device fast: Gemma 4 2B */
    onDeviceFast: optional('GEMMA4_ONDEVICE_FAST', 'gemma-4-e2b-it'),
    /** On-device quality: Gemma 4 4B */
    onDeviceQuality: optional('GEMMA4_ONDEVICE_QUALITY', 'gemma-4-e4b-it'),
  },

  rateLimit: {
    windowMs: parseInt(optional('RATE_LIMIT_WINDOW_MS', '60000'), 10),
    maxRequests: parseInt(optional('RATE_LIMIT_MAX_REQUESTS', '60'), 10),
  },

  cache: {
    ttlSeconds: parseInt(optional('CACHE_TTL_SECONDS', '300'), 10),
  },
} as const;
