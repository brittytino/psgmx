/**
 * AI Router — TypeScript port of both Python ai_router.py files.
 *
 * Routing logic:
 *   1. Cache hit → return immediately (no AI call).
 *   2. CB CLOSED / HALF_OPEN → try Claude first.
 *      Success → cache + return.
 *      Failure → fall back to Gemini.
 *   3. CB OPEN → skip Claude, go straight to Gemini.
 *   4. Both fail → throw Error.
 *
 * Separate caches for candidate insights, faculty insights, and batch insights.
 * Cache TTL: 30 minutes.
 */

import { callClaude, claudeModelName, isClaudeConfigured } from './claude-client';
import { callGemini, geminiModelName, isGeminiConfigured } from './gemini-client';
import { CircuitBreaker, CBState } from './circuit-breaker';

// ── Shared Circuit Breaker (module-level singleton) ──────────────────────────
const _cb = new CircuitBreaker();

// ── Caches ────────────────────────────────────────────────────────────────────
const CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes

interface CacheEntry {
  data: Record<string, unknown>;
  cachedAt: number;
}

const _studentCache  = new Map<string, CacheEntry>();
const _facultyCache  = new Map<string, CacheEntry>();
const _batchCache    = new Map<string, CacheEntry>();

// ── JSON extraction helper ────────────────────────────────────────────────────
function extractJson(text: string): Record<string, unknown> {
  let clean = text.trim();
  clean = clean.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '');
  try {
    return JSON.parse(clean);
  } catch {
    const match = clean.match(/\{[\s\S]*\}/);
    if (match) {
      return JSON.parse(match[0]);
    }
    throw new Error('Could not extract JSON from AI response');
  }
}

// ── Core routing ──────────────────────────────────────────────────────────────
async function routeWithFallback(
  contextId: string,
  prompt: string,
): Promise<Record<string, unknown>> {
  const state = _cb.state;
  // Helper for logging
  const logProvider = (provider: string, success: boolean, start: number, err?: any) => {
    const duration = Date.now() - start;
    if (success) {
      console.log(`[ai-router] ${provider} success for ${contextId} in ${duration}ms`);
    } else {
      console.warn(`[ai-router] ${provider} failed for ${contextId} after ${duration}ms:`, err?.message || err);
    }
  };

  // 1. Skip Claude if not configured
  if (!isClaudeConfigured()) {
    if (!isGeminiConfigured()) throw new Error('No AI providers configured (Claude or Gemini).');
    const start = Date.now();
    try {
      const result = await callGemini(prompt);
      logProvider('Gemini (Direct)', true, start);
      return extractJson(result.text);
    } catch (err) {
      logProvider('Gemini (Direct)', false, start, err);
      throw err;
    }
  }

  // 2. Skip Claude if Circuit Breaker is OPEN
  if (state === CBState.OPEN) {
    const start = Date.now();
    try {
      const result = await callGemini(prompt);
      logProvider('Gemini (Fallback - CB OPEN)', true, start);
      return extractJson(result.text);
    } catch (err) {
      logProvider('Gemini (Fallback - CB OPEN)', false, start, err);
      throw err;
    }
  }

  // 3. Try Claude First
  const claudeStart = Date.now();
  try {
    const result = await callClaude(prompt);
    _cb.recordSuccess();
    logProvider('Claude', true, claudeStart);
    return extractJson(result.text);
  } catch (claudeErr: unknown) {
    _cb.recordFailure();
    logProvider('Claude', false, claudeStart, claudeErr);

    const errMsg = claudeErr instanceof Error ? claudeErr.message : String(claudeErr);
    
    // Auth errors should bubble up immediately
    if (errMsg.includes('authentication') || errMsg.includes('401')) {
      throw new Error(`Claude auth failed: ${errMsg}`);
    }

    // Attempt Gemini Fallback
    if (!isGeminiConfigured()) {
      throw new Error(`Claude failed and Gemini not configured. Claude error: ${errMsg}`);
    }

    const geminiStart = Date.now();
    try {
      const result = await callGemini(prompt);
      logProvider('Gemini (Fallback)', true, geminiStart);
      return extractJson(result.text);
    } catch (geminiErr: unknown) {
      const gMsg = geminiErr instanceof Error ? geminiErr.message : String(geminiErr);
      logProvider('Gemini (Fallback)', false, geminiStart, geminiErr);
      throw new Error(`AI Providers failed for ${contextId}. Claude: ${errMsg} | Gemini: ${gMsg}`);
    }
  }
}

// ── Public API: Candidate Insights ──────────────────────────────────────────────
export async function generateStudentInsights(
  studentId: string,
  prompt: string,
  forceRefresh = false,
): Promise<Record<string, unknown>> {
  const key = studentId.toUpperCase();

  if (!forceRefresh) {
    const cached = _studentCache.get(key);
    if (cached && Date.now() - cached.cachedAt < CACHE_TTL_MS) {
      return cached.data;
    }
  }

  const result = await routeWithFallback(studentId, prompt);
  _studentCache.set(key, { data: result, cachedAt: Date.now() });
  return result;
}

export function clearStudentCache(studentId?: string): void {
  if (studentId) {
    _studentCache.delete(studentId.toUpperCase());
  } else {
    _studentCache.clear();
  }
}

// ── Public API: Faculty Insights ──────────────────────────────────────────────
export async function generateFacultyStudentInsights(
  facultyId: string,
  studentId: string,
  prompt: string,
  forceRefresh = false,
): Promise<Record<string, unknown>> {
  const key = `${facultyId}:${studentId}`.toUpperCase();

  if (!forceRefresh) {
    const cached = _facultyCache.get(key);
    if (cached && Date.now() - cached.cachedAt < CACHE_TTL_MS) {
      return cached.data;
    }
  }

  const result = await routeWithFallback(`${facultyId}:${studentId}`, prompt);
  _facultyCache.set(key, { data: result, cachedAt: Date.now() });
  return result;
}

// ── Public API: Batch Insights ───────────────────────────────────────────────
export async function generateBatchInsights(
  batchKey: string,
  prompt: string,
  forceRefresh = false,
): Promise<Record<string, unknown>> {
  const key = batchKey.toUpperCase();

  if (!forceRefresh) {
    const cached = _batchCache.get(key);
    if (cached && Date.now() - cached.cachedAt < CACHE_TTL_MS) {
      return cached.data;
    }
  }

  const result = await routeWithFallback(key, prompt);
  _batchCache.set(key, { data: result, cachedAt: Date.now() });
  return result;
}

export function clearBatchCache(batchKey?: string): void {
  if (batchKey) {
    _batchCache.delete(batchKey.toUpperCase());
  } else {
    _batchCache.clear();
  }
}

export function clearFacultyCache(facultyId?: string, studentId?: string): void {
  if (facultyId && studentId) {
    _facultyCache.delete(`${facultyId}:${studentId}`.toUpperCase());
  } else if (facultyId) {
    const prefix = facultyId.toUpperCase() + ':';
    for (const key of _facultyCache.keys()) {
      if (key.startsWith(prefix)) _facultyCache.delete(key);
    }
  } else {
    _facultyCache.clear();
  }
}

// ── Router status (for health endpoint) ──────────────────────────────────────
export function getRouterStatus() {
  return {
    circuit_breaker: _cb.asDict(),
    student_cache_size: _studentCache.size,
    faculty_cache_size: _facultyCache.size,
    batch_cache_size: _batchCache.size,
    providers: {
      claude: { configured: isClaudeConfigured(), model: claudeModelName() },
      gemini: { configured: isGeminiConfigured(), model: geminiModelName() },
    },
  };
}
