// Server-only OpenRouter routing using exclusively verified free-tier models.
// Allows Placement Reps to dynamically customize the main model and fallback chain.

import fs from 'node:fs'
import path from 'node:path'

export type AITaskType =
  | 'code_evaluation'
  | 'ai_senior_qa'
  | 'communication_evaluation'
  | 'knowledge_moderation'
  | 'fyp_explanation'
  | 'general'

export const FREE_MODELS_CATALOG: string[] = [
  'nvidia/nemotron-3-ultra-550b-a55b:free',
  'poolside/laguna-s-2.1:free',
  'nvidia/nemotron-3.5-lightning:free',
  'nvidia/nemotron-3-super-120b-a12b:free',
  'dots-studio/dots-3-note-preview:free',
  'thinkingmachines/inkling:free',
  'poolside/laguna-xs-2.1:free',
  'google/gemma-4-26b-a4b-it:free',
  'google/gemma-4-31b-it:free',
  'fish-audio/s2.1-pro-free:free',
]

export interface AIModelConfig {
  mainModel: string
  fallbackModels: string[]
}

const DEFAULT_CONFIG: AIModelConfig = {
  mainModel: 'nvidia/nemotron-3-ultra-550b-a55b:free',
  fallbackModels: [
    'poolside/laguna-s-2.1:free',
    'nvidia/nemotron-3.5-lightning:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'dots-studio/dots-3-note-preview:free',
    'thinkingmachines/inkling:free',
    'poolside/laguna-xs-2.1:free',
    'google/gemma-4-26b-a4b-it:free',
    'google/gemma-4-31b-it:free',
    'fish-audio/s2.1-pro-free:free',
  ],
}

// In-memory runtime cache
let runtimeConfig: AIModelConfig = { ...DEFAULT_CONFIG }

// Config file path
const CONFIG_FILE = path.join(process.cwd(), 'lib', 'ai', 'ai-models-config.json')

function loadPersistedConfig(): AIModelConfig {
  try {
    if (fs.existsSync(CONFIG_FILE)) {
      const raw = fs.readFileSync(CONFIG_FILE, 'utf-8')
      const parsed = JSON.parse(raw)
      if (parsed?.mainModel && Array.isArray(parsed?.fallbackModels)) {
        return parsed
      }
    }
  } catch {
    // ignore
  }
  return DEFAULT_CONFIG
}

export function getAIModelConfig(): AIModelConfig {
  if (!runtimeConfig.mainModel) {
    runtimeConfig = loadPersistedConfig()
  }
  return runtimeConfig
}

export function updateAIModelConfig(newConfig: Partial<AIModelConfig>): AIModelConfig {
  const updated: AIModelConfig = {
    mainModel: newConfig.mainModel || runtimeConfig.mainModel || DEFAULT_CONFIG.mainModel,
    fallbackModels: Array.isArray(newConfig.fallbackModels) && newConfig.fallbackModels.length > 0
      ? newConfig.fallbackModels
      : runtimeConfig.fallbackModels || DEFAULT_CONFIG.fallbackModels,
  }

  runtimeConfig = updated

  try {
    const dir = path.dirname(CONFIG_FILE)
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(updated, null, 2), 'utf-8')
  } catch (err) {
    console.warn('Could not persist ai-models-config.json:', err)
  }

  return runtimeConfig
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
  modelOverride?: string,
): Promise<AICallResponse> {
  const apiKey = process.env.OPENROUTER_API_KEY?.trim()
  if (!apiKey) {
    throw new AIUnavailableError(0)
  }

  const config = getAIModelConfig()
  // Chain: if modelOverride is provided, try that first then fallbacks
  const modelChain = modelOverride
    ? [modelOverride, ...config.fallbackModels.filter((m) => m !== modelOverride)]
    : [config.mainModel, ...config.fallbackModels.filter((m) => m !== config.mainModel)]

  let attempts = 0
  let lastError = 'Unknown error'

  for (const modelId of modelChain) {
    attempts += 1
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 10_000)

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
          model: modelId,
          messages,
          max_tokens: maxTokensOverride || 1200,
          temperature: 0.25,
        }),
        signal: controller.signal,
      })

      if (!response.ok) {
        lastError = `Model ${modelId} HTTP ${response.status}`
        continue
      }

      const data = await response.json()
      const content = data?.choices?.[0]?.message?.content
      if (typeof content === 'string' && content.trim()) {
        return {
          text: content.trim(),
          modelUsed: data?.model || modelId,
          isFallback: attempts > 1,
          attempts,
        }
      }
      lastError = `Model ${modelId} returned empty content`
    } catch (err) {
      lastError = err instanceof Error ? err.message : String(err)
    } finally {
      clearTimeout(timeout)
    }
  }

  console.warn(`All ${attempts} OpenRouter free models failed. Last error: ${lastError}`)
  throw new AIUnavailableError(attempts)
}

export const OPENROUTER_MODEL_CHAINS = {
  programming: [
    'poolside/laguna-s-2.1:free',
    'nvidia/nemotron-3.5-lightning:free',
    'openrouter/free',
  ],
  thinking: [
    'inclusionai/ling-3.0-flash-fin:free',
    'nvidia/nemotron-3-ultra-550b-a55b:free',
    'google/gemma-4-31b-it:free',
    'openrouter/free',
  ],
  textToSpeech: ['deepgram/flux-tts:free'],
} as const

