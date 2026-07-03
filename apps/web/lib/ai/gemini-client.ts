/**
 * Gemini API client — Singleton, fallback AI provider.
 * No caching or routing logic. Only knows how to call Gemini and return raw text.
 * The ai-router owns all routing and caching decisions.
 */
import { GoogleGenerativeAI } from '@google/generative-ai';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY?.trim() || '';
const GEMINI_MODEL   = process.env.GEMINI_MODEL || 'gemini-2.0-flash';

let _client: GoogleGenerativeAI | null = null;

function getClient(): GoogleGenerativeAI {
  if (!_client) {
    if (!GEMINI_API_KEY) {
      throw new Error(
        'GEMINI_API_KEY is not set. Add GEMINI_API_KEY=your_key to your .env file.'
      );
    }
    _client = new GoogleGenerativeAI(GEMINI_API_KEY);
  }
  return _client;
}

export interface AICallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export async function callGemini(prompt: string, modelName: string = GEMINI_MODEL): Promise<AICallResult> {
  const client = getClient();
  const model = client.getGenerativeModel({ 
    model: modelName,
    generationConfig: { temperature: 0.4 }
  });
  
  const resultPromise = model.generateContent(prompt);
  const timeoutPromise = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error('Gemini call timeout (50s)')), 50000)
  );

  const result = await Promise.race([resultPromise, timeoutPromise]) as any;
  const response = await result.response;
  
  const text   = response.text() || '';
  const usage  = (response as any).usageMetadata || {};
  const inTok  = usage.promptTokenCount     || 0;
  const outTok = usage.candidatesTokenCount || 0;

  return { text, inputTokens: inTok, outputTokens: outTok };
}

export function geminiModelName(): string {
  return GEMINI_MODEL;
}

export function isGeminiConfigured(): boolean {
  return Boolean(GEMINI_API_KEY);
}
