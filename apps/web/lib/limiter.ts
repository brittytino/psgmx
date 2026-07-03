type RateLimitInfo = {
  count: number;
  resetTime: number;
};

// Simple in-memory Map to store IP limits.
// In Serverless standard environments, this resets frequently (per instance).
// For strict distributed limits, Redis (Upstash) is recommended but Map works for basic protection.
const rateLimitMap = new Map<string, RateLimitInfo>();

const RATE_LIMIT_COUNT = 5; // Max 5 requests
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute

export function checkRateLimit(ip: string): { limit: number; remaining: number; success: boolean } {
  const now = Date.now();
  const info = rateLimitMap.get(ip);

  if (!info) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW_MS });
    return { limit: RATE_LIMIT_COUNT, remaining: RATE_LIMIT_COUNT - 1, success: true };
  }

  // If the time window has passed, reset the count
  if (now > info.resetTime) {
    info.count = 1;
    info.resetTime = now + RATE_LIMIT_WINDOW_MS;
    rateLimitMap.set(ip, info);
    return { limit: RATE_LIMIT_COUNT, remaining: RATE_LIMIT_COUNT - 1, success: true };
  }

  // If within the time window and exceeded the limit
  if (info.count >= RATE_LIMIT_COUNT) {
    return { limit: RATE_LIMIT_COUNT, remaining: 0, success: false };
  }

  // Increment counter
  info.count += 1;
  rateLimitMap.set(ip, info);
  return { limit: RATE_LIMIT_COUNT, remaining: RATE_LIMIT_COUNT - info.count, success: true };
}

// Optional cleanup loop if needed for long-running instances
setInterval(() => {
  const now = Date.now();
  rateLimitMap.forEach((value, key) => {
    if (now > value.resetTime) {
      rateLimitMap.delete(key);
    }
  });
}, 5 * 60 * 1000); // Clean up every 5 minutes
