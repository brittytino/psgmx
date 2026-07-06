import { callGemini, isGeminiConfigured } from './gemini-client';
import { callOpenRouter, isOpenRouterConfigured, AICallResult } from './openrouter-client';

import { CircuitBreaker, CBState } from './circuit-breaker';

export interface OrchestratorParams {
  prompt: string;
  userToken: string;
  role: string;
  retrievedSources: string[];
}

export interface OrchestratorResponse {
  answer: string;
  modelUsed: string;
}

const FALLBACK_CHAIN = [
  { provider: 'google', model: 'gemini-2.5-pro' },
  { provider: 'openrouter', model: 'anthropic/claude-3.5-sonnet' },
  { provider: 'openrouter', model: 'openai/gpt-4o' },
  { provider: 'google', model: 'gemini-2.5-flash' },
  { provider: 'openrouter', model: 'deepseek/deepseek-r1' },
  { provider: 'openrouter', model: 'qwen/qwen-max' }
];

// Initialize a circuit breaker for each model
const circuitBreakers: Record<string, CircuitBreaker> = {};
FALLBACK_CHAIN.forEach(target => {
  circuitBreakers[target.model] = new CircuitBreaker();
});

const TIMEOUT_MS = 15000; // 15 seconds timeout per model

async function callWithTimeout(promise: Promise<AICallResult>, timeoutMs: number): Promise<AICallResult> {
  let timeoutHandle: NodeJS.Timeout;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeoutHandle = setTimeout(() => reject(new Error('Model execution timed out')), timeoutMs);
  });

  return Promise.race([
    promise,
    timeoutPromise
  ]).finally(() => clearTimeout(timeoutHandle));
}

export async function orchestrateAI(params: OrchestratorParams): Promise<OrchestratorResponse> {
  const { prompt, userToken, role, retrievedSources } = params;
  let lastError: any = null;

  for (const target of FALLBACK_CHAIN) {
    if (target.provider === 'google' && !isGeminiConfigured()) continue;
    if (target.provider === 'openrouter' && !isOpenRouterConfigured()) continue;

    const cb = circuitBreakers[target.model];
    if (cb.state === CBState.OPEN) {
      console.log(JSON.stringify({ level: 'WARN', event: 'CIRCUIT_BREAKER_OPEN', model: target.model }));
      continue; // Skip this model, it's failing
    }

    // Try up to 2 times (1 initial + 1 retry)
    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        const modelStart = Date.now();
        let resultPromise: Promise<AICallResult>;

        if (target.provider === 'google') {
          resultPromise = callGemini(prompt, target.model);
        } else {
          resultPromise = callOpenRouter(prompt, target.model);
        }

        const result = await callWithTimeout(resultPromise, TIMEOUT_MS);
        const latencyMs = Date.now() - modelStart;

        // Record success on circuit breaker
        cb.recordSuccess();

        // Structured Logging
        console.log(JSON.stringify({
          level: 'INFO',
          event: 'AI_SUCCESS',
          model: target.model,
          latencyMs,
          attempt,
          userToken
        }));



        return {
          answer: result.text,
          modelUsed: target.model
        };

      } catch (error: any) {
        cb.recordFailure();
        console.warn(JSON.stringify({
          level: 'WARN',
          event: 'AI_FAILURE',
          model: target.model,
          attempt,
          error: error.message
        }));
        lastError = error;
        
        // Wait 1 second before retry if it's the first attempt
        if (attempt === 1) await new Promise(res => setTimeout(res, 1000));
      }
    }
  }

  // If we reach here, all models in the chain failed
  console.error(JSON.stringify({ level: 'ERROR', event: 'ALL_MODELS_FAILED', lastError: lastError?.message }));
  throw new Error(`All AI models in the fallback chain failed. Last error: ${lastError?.message || lastError}`);
}
