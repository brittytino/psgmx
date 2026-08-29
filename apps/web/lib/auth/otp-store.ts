// Global in-memory OTP cache for instant, resilient verification across dev & serverless
declare global {
  // eslint-disable-next-line no-var
  var __psgmx_otp_cache: Map<string, { code: string; expiresAt: number }> | undefined;
}

const cache = globalThis.__psgmx_otp_cache || new Map<string, { code: string; expiresAt: number }>();
if (process.env.NODE_ENV !== 'production') {
  globalThis.__psgmx_otp_cache = cache;
}

const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes

export function saveOtp(email: string, code: string): void {
  const normalized = email.trim().toLowerCase();
  cache.set(normalized, {
    code: code.trim(),
    expiresAt: Date.now() + OTP_TTL_MS,
  });
}

export function verifyStoredOtp(email: string, code: string): boolean {
  const normalized = email.trim().toLowerCase();
  const entry = cache.get(normalized);
  if (!entry) return false;

  if (Date.now() > entry.expiresAt) {
    cache.delete(normalized);
    return false;
  }

  const isMatch = entry.code === code.trim();
  if (isMatch) {
    cache.delete(normalized); // Single-use consumption
  }
  return isMatch;
}

export function getStoredOtp(email: string): string | null {
  const normalized = email.trim().toLowerCase();
  const entry = cache.get(normalized);
  if (!entry || Date.now() > entry.expiresAt) {
    return null;
  }
  return entry.code;
}
