// Server-only OpenRouter routing. Model order is intentionally centralized so
// every AI feature uses the same free-tier fallback and telemetry contract.

export type AITaskType =
  | 'code_evaluation'
  | 'ai_senior_qa'
  | 'communication_evaluation'
  | 'knowledge_moderation'
  | 'fyp_explanation'
  | 'general'

type ModelMode = 'programming' | 'thinking'

interface ModelConfig {
  id: string
  maxTokens: number
  temperature: number
}

const PROGRAMMING_MODELS: ModelConfig[] = [
  { id: 'nvidia/nemotron-3-ultra-550b-a55b:free', maxTokens: 1600, temperature: 0.15 },
  { id: 'minimax/minimax-m3:free', maxTokens: 1600, temperature: 0.15 },
  { id: 'poolside/laguna-s-2.1:free', maxTokens: 1600, temperature: 0.15 },
  { id: 'nvidia/nemotron-3.5-lightning:free', maxTokens: 1400, temperature: 0.15 },
  { id: 'nvidia/nemotron-3-super-120b-a12b:free', maxTokens: 1400, temperature: 0.15 },
  { id: 'openrouter/free', maxTokens: 1400, temperature: 0.15 },
]

const THINKING_MODELS: ModelConfig[] = [
  { id: 'thinkingmachines/inkling:free', maxTokens: 1400, temperature: 0.3 },
  { id: 'minimax/minimax-m2.7:free', maxTokens: 1400, temperature: 0.3 },
  { id: 'inclusionai/ling-3.0-flash-fin:free', maxTokens: 1400, temperature: 0.3 },
  { id: 'google/gemma-4-31b-it:free', maxTokens: 1400, temperature: 0.3 },
  { id: 'google/gemma-4-26b-a4b-it:free', maxTokens: 1400, temperature: 0.3 },
  { id: 'openrouter/free', maxTokens: 1400, temperature: 0.3 },
]

function modeForTask(taskType: AITaskType): ModelMode {
  return taskType === 'code_evaluation' || taskType === 'fyp_explanation'
    ? 'programming'
    : 'thinking'
}

export interface AICallResponse {
  text: string
  modelUsed: string
  isFallback: boolean
  attempts: number
}

export class AIUnavailableError extends Error {
  constructor(public readonly attempts: number) {
    super('The AI mentor is temporarily unavailable. Please try again shortly.')
    this.name = 'AIUnavailableError'
  }
}

export async function executeOpenRouterPrompt(
  prompt: string,
  taskType: AITaskType = 'general',
  systemPrompt?: string,
  maxTokensOverride?: number,
): Promise<AICallResponse> {
  const apiKey = process.env.OPENROUTER_API_KEY?.trim()
  if (!apiKey) throw new AIUnavailableError(0)

  const mode = modeForTask(taskType)
  const chain = mode === 'programming' ? PROGRAMMING_MODELS : THINKING_MODELS
  let attempts = 0

  for (const model of chain) {
    attempts += 1
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 15_000)

    try {
      const messages: Array<{ role: 'system' | 'user'; content: string }> = []
      if (systemPrompt?.trim()) messages.push({ role: 'system', content: systemPrompt.trim() })
      messages.push({ role: 'user', content: prompt })

      const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': process.env.NEXT_PUBLIC_APP_URL || 'https://psgmx.tech',
          'X-Title': 'PSGMX Placement Preparation Companion',
        },
        body: JSON.stringify({
          model: model.id,
          messages,
          max_tokens: maxTokensOverride ? Math.max(100, Math.min(maxTokensOverride, model.maxTokens)) : model.maxTokens,
          temperature: model.temperature,
        }),
        signal: controller.signal,
      })

      if (!response.ok) continue
      const data = await response.json()
      const content = data?.choices?.[0]?.message?.content
      if (typeof content === 'string' && content.trim()) {
        return {
          text: content.trim(),
          modelUsed: data?.model || model.id,
          isFallback: attempts > 1,
          attempts,
        }
      }
    } catch {
      // A timeout, transient network failure, or unavailable free model advances
      // to the next configured model. Prompt or provider bodies are not logged.
    } finally {
      clearTimeout(timeout)
    }
  }

  throw new AIUnavailableError(attempts)
}

export const OPENROUTER_MODEL_CHAINS = {
  programming: PROGRAMMING_MODELS.map((model) => model.id),
  thinking: THINKING_MODELS.map((model) => model.id),
  textToSpeech: ['deepgram/flux-tts:free'],
} as const
