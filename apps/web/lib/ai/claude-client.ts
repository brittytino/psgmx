/**
 * Claude API client — Singleton, primary AI provider.
 * No caching or routing logic. Only knows how to call Claude and return raw text.
 * The ai-router owns all routing and caching decisions.
 */
import Anthropic from '@anthropic-ai/sdk';

const CLAUDE_API_KEY = process.env.CLAUDE_API_KEY?.trim() || '';
const CLAUDE_MODEL = process.env.CLAUDE_MODEL || 'claude-sonnet-4-5';

let _client: Anthropic | null = null;

function getClient(): Anthropic {
  if (!_client) {
    if (!CLAUDE_API_KEY) {
      throw new Error(
        'CLAUDE_API_KEY is not set. Add CLAUDE_API_KEY=your_key to your .env file.'
      );
    }
    _client = new Anthropic({ apiKey: CLAUDE_API_KEY });
  }
  return _client;
}

export interface AICallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export async function callClaude(prompt: string): Promise<AICallResult> {
  const client = getClient();

  // max_tokens was 8000 (caused 2+ min responses for large prompts).
  // The actual insight JSON is ~1500-2000 tokens — 3000 is a safe ceiling.
  // Timeout set to 120s: the student prompt is ~2k tokens of input,
  // generating ~3k tokens of structured JSON takes 60-90s on Sonnet during peak load.
  const callPromise = client.messages.create({
    model: CLAUDE_MODEL,
    max_tokens: 5000,
    temperature: 0.4,
    messages: [{ role: 'user', content: prompt }],
  });
  const timeoutPromise = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error('Request timed out.')), 120000) // 120s
  );

  const response = await Promise.race([callPromise, timeoutPromise]);
  const text = (response.content[0] as { type: string; text: string }).text;
  const inTok = response.usage.input_tokens;
  const outTok = response.usage.output_tokens;
  console.log(`[claude] ${CLAUDE_MODEL} — in:${inTok} out:${outTok} tokens`);
  return { text, inputTokens: inTok, outputTokens: outTok };
}

export function claudeModelName(): string {
  return CLAUDE_MODEL;
}

export function isClaudeConfigured(): boolean {
  return Boolean(CLAUDE_API_KEY);
}
