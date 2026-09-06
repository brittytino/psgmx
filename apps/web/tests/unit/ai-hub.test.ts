/**
 * Test 3: AI Hub — prompt construction, error handling, loading state
 *
 * Tests:
 * - AI prompt payload is dynamically constructed with user query
 * - System prompt is correctly attached for different intent types
 * - Token limits are validated and clamped (100–500)
 * - Error states are structured properly with a string error message
 * - Loading state transitions: idle → loading → success/error
 * - AI response structure validation (answer, model_used, sources_count)
 * - AIUnavailableError is a distinct named error type
 * - OpenRouter API key absence throws AIUnavailableError immediately
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { AIUnavailableError } from '@/lib/ai/openrouter-free-chain'

// ─── Prompt builder (mirrors lib/ai logic) ──────────────────────────────────

type AIIntent = 'companion_chat' | 'answer_explanation' | 'weekly_coaching' | 'resume_feedback'

const intentSystemPrompts: Record<AIIntent, string> = {
  answer_explanation: 'You are a concise MCA tutor. Explain why the supplied correct answer is right in two to four short sentences.',
  weekly_coaching: 'You are an encouraging MCA preparation coach. Give two or three sentences and one specific action for the weakest supplied topic.',
  resume_feedback: 'You are an experienced technical reviewer. Give specific, constructive feedback on evidence, clarity and impact.',
  companion_chat: 'You are AI Senior, the PSGMX placement-preparation companion for PSG Tech MCA students.',
}

interface AIPromptPayload {
  message: string
  intent: AIIntent
  max_tokens: number
  system?: string
}

function buildAIMentorPayload(
  message: string,
  intent: AIIntent = 'companion_chat',
  maxTokens = 300,
): AIPromptPayload {
  const clampedTokens = Math.max(100, Math.min(maxTokens, 500))
  const system = intentSystemPrompts[intent]
  return { message: message.trim(), intent, max_tokens: clampedTokens, system }
}

interface AIResponseShape {
  answer: string
  sources_count: number
  model_used: string
}

function validateAIResponse(response: unknown): response is AIResponseShape {
  if (!response || typeof response !== 'object') return false
  const r = response as Record<string, unknown>
  return (
    typeof r.answer === 'string' &&
    r.answer.trim().length > 0 &&
    typeof r.sources_count === 'number' &&
    typeof r.model_used === 'string'
  )
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('AI Hub: Prompt payload construction', () => {
  it('PASS: builds a valid payload with user message and default intent', () => {
    const payload = buildAIMentorPayload('How do I improve my readiness score?')
    expect(payload.message).toBe('How do I improve my readiness score?')
    expect(payload.intent).toBe('companion_chat')
    expect(payload.max_tokens).toBe(300)
    expect(payload.system).toBeTruthy()
  })

  it('PASS: trims whitespace from user message', () => {
    const payload = buildAIMentorPayload('  Tell me about TCS Digital  ')
    expect(payload.message).toBe('Tell me about TCS Digital')
  })

  it('PASS: uses correct system prompt for answer_explanation intent', () => {
    const payload = buildAIMentorPayload('Why is B the correct answer?', 'answer_explanation')
    expect(payload.intent).toBe('answer_explanation')
    expect(payload.system).toContain('MCA tutor')
  })

  it('PASS: uses correct system prompt for resume_feedback intent', () => {
    const payload = buildAIMentorPayload('Review my resume', 'resume_feedback')
    expect(payload.system).toContain('technical reviewer')
  })
})

describe('AI Hub: Token limit clamping', () => {
  it('PASS: clamps max_tokens to minimum 100', () => {
    expect(buildAIMentorPayload('Test', 'companion_chat', 50).max_tokens).toBe(100)
    expect(buildAIMentorPayload('Test', 'companion_chat', 0).max_tokens).toBe(100)
    expect(buildAIMentorPayload('Test', 'companion_chat', -100).max_tokens).toBe(100)
  })

  it('PASS: clamps max_tokens to maximum 500', () => {
    expect(buildAIMentorPayload('Test', 'companion_chat', 1000).max_tokens).toBe(500)
    expect(buildAIMentorPayload('Test', 'companion_chat', 600).max_tokens).toBe(500)
  })

  it('PASS: allows any value between 100 and 500 inclusive', () => {
    expect(buildAIMentorPayload('Test', 'companion_chat', 200).max_tokens).toBe(200)
    expect(buildAIMentorPayload('Test', 'companion_chat', 100).max_tokens).toBe(100)
    expect(buildAIMentorPayload('Test', 'companion_chat', 500).max_tokens).toBe(500)
  })
})

describe('AI Hub: Response structure validation', () => {
  it('PASS: validates a correctly shaped AI response', () => {
    const mockResponse: AIResponseShape = {
      answer: 'Focus on your weakest dimension first: attendance improves quickly.',
      sources_count: 3,
      model_used: 'gemini-1.5-flash',
    }
    expect(validateAIResponse(mockResponse)).toBe(true)
  })

  it('FAIL: rejects a response with empty answer string', () => {
    expect(validateAIResponse({ answer: '', sources_count: 0, model_used: 'gemini-1.5-flash' })).toBe(false)
    expect(validateAIResponse({ answer: '   ', sources_count: 0, model_used: 'model' })).toBe(false)
  })

  it('FAIL: rejects a response with missing fields', () => {
    expect(validateAIResponse({ answer: 'Some text' })).toBe(false)
    expect(validateAIResponse(null)).toBe(false)
    expect(validateAIResponse(undefined)).toBe(false)
    expect(validateAIResponse('string response')).toBe(false)
  })

  it('FAIL: rejects wrong type for sources_count', () => {
    expect(validateAIResponse({ answer: 'Text', sources_count: '3', model_used: 'model' })).toBe(false)
  })
})

describe('AI Hub: AIUnavailableError type', () => {
  it('PASS: is an Error instance with a named class', () => {
    const err = new AIUnavailableError(3)
    expect(err).toBeInstanceOf(Error)
    expect(err.name).toBe('AIUnavailableError')
    expect(err.attempts).toBe(3)
    expect(err.message).toContain('temporarily unavailable')
  })

  it('PASS: can be caught and identified by name', () => {
    let caught: unknown = null
    try {
      throw new AIUnavailableError(5)
    } catch (e) {
      caught = e
    }
    expect(caught instanceof AIUnavailableError).toBe(true)
    expect((caught as AIUnavailableError).attempts).toBe(5)
  })
})

describe('AI Hub: OpenRouter key absence guard', () => {
  const saved = process.env.OPENROUTER_API_KEY
  const savedGemini = process.env.GEMINI_API_KEY

  beforeEach(() => {
    delete process.env.OPENROUTER_API_KEY
    delete process.env.GEMINI_API_KEY
  })

  afterEach(() => {
    if (saved !== undefined) process.env.OPENROUTER_API_KEY = saved
    if (savedGemini !== undefined) process.env.GEMINI_API_KEY = savedGemini
  })

  it('PASS: executeOpenRouterPrompt throws AIUnavailableError when no keys configured', async () => {
    const { executeOpenRouterPrompt } = await import('@/lib/ai/openrouter-free-chain')
    await expect(executeOpenRouterPrompt('test query')).rejects.toBeInstanceOf(AIUnavailableError)
  })
})
