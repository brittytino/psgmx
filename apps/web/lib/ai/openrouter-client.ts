import OpenAI from 'openai';

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY?.trim() || '';

let _client: OpenAI | null = null;

function getClient(): OpenAI {
  if (!_client) {
    if (!OPENROUTER_API_KEY) {
      throw new Error('OPENROUTER_API_KEY is not set.');
    }
    _client = new OpenAI({
      baseURL: 'https://openrouter.ai/api/v1',
      apiKey: OPENROUTER_API_KEY,
      defaultHeaders: {
        'HTTP-Referer': 'https://psgmx.local',
        'X-Title': 'PSGMX Department OS',
      }
    });
  }
  return _client;
}

export interface AICallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export async function callOpenRouter(prompt: string, modelName: string): Promise<AICallResult> {
  const client = getClient();
  
  const callPromise = client.chat.completions.create({
    model: modelName,
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.4,
  });

  const timeoutPromise = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error(`OpenRouter timeout for model ${modelName}`)), 60000)
  );

  const response = await Promise.race([callPromise, timeoutPromise]) as OpenAI.Chat.Completions.ChatCompletion;
  
  const text = response.choices[0]?.message?.content || '';
  const inTok = response.usage?.prompt_tokens || 0;
  const outTok = response.usage?.completion_tokens || 0;

  return { text, inputTokens: inTok, outputTokens: outTok };
}

export function isOpenRouterConfigured(): boolean {
  return Boolean(OPENROUTER_API_KEY);
}
