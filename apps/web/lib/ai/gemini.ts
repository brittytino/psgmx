import { executeOpenRouterPrompt } from './openrouter-free-chain'

export interface GeminiResponse {
  text: string
  modelUsed: string
}

export async function executeGeminiPrompt(
  prompt: string,
  systemPrompt?: string,
): Promise<GeminiResponse | null> {
  try {
    const res = await executeOpenRouterPrompt(prompt, 'general', systemPrompt)
    return {
      text: res.text,
      modelUsed: res.modelUsed,
    }
  } catch (err) {
    console.warn('[AI Model Engine] OpenRouter fallback call failed:', err instanceof Error ? err.message : String(err))
    return null
  }
}
