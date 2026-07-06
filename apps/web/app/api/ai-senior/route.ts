// ============================================================
// POST /api/ai-senior/route.ts (v2)
// AI Senior RAG chatbot.
// Primary LLM: Gemini 2.5 Flash via @google/generative-ai
// Fallback LLM: OpenRouter (claude-3-haiku) on Gemini failure
// Final fallback: static message
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { buildRAGContext, formatRAGContextForPrompt } from '@/lib/ai/rag'
import { GoogleGenerativeAI } from '@google/generative-ai'

const FALLBACK_MESSAGE =
  "I couldn't find a specific answer in the knowledge base right now. " +
  "Try searching the Knowledge Brain directly for more detailed information."

async function callGemini(systemPrompt: string, contextText: string, query: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY
  if (!apiKey) throw new Error('GEMINI_API_KEY not configured')

  const genAI  = new GoogleGenerativeAI(apiKey)
  const model  = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    systemInstruction: systemPrompt,
    generationConfig: {
      maxOutputTokens: 800,
      temperature:     0.3,
    },
  })

  const prompt = `Knowledge Brain Context:\n${contextText}\n\nStudent Question: ${query}`

  // 8-second timeout
  const result = await Promise.race([
    model.generateContent(prompt),
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('Gemini timeout')), 8000)
    ),
  ])

  const text = result.response.text()
  if (!text) throw new Error('Empty response from Gemini')
  return text
}

async function callOpenRouter(systemPrompt: string, contextText: string, query: string): Promise<string> {
  const apiKey = process.env.OPENROUTER_API_KEY
  if (!apiKey) throw new Error('OPENROUTER_API_KEY not configured')

  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type':  'application/json',
      'HTTP-Referer':  process.env.NEXT_PUBLIC_APP_URL ?? 'https://psgmx.tech',
      'X-Title':       'PSGMX AI Senior',
    },
    body: JSON.stringify({
      model:      'anthropic/claude-3-haiku',
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role:    'user',
          content: `Knowledge Brain Context:\n${contextText}\n\nStudent Question: ${query}`,
        },
      ],
      max_tokens:  800,
      temperature: 0.3,
    }),
    signal: AbortSignal.timeout(10000),
  })

  if (!response.ok) {
    const err = await response.text()
    throw new Error(`OpenRouter error: ${err}`)
  }

  const data = await response.json()
  const text = data.choices?.[0]?.message?.content
  if (!text) throw new Error('Empty response from OpenRouter')
  return text
}

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { query } = body

    if (!query || typeof query !== 'string') {
      return NextResponse.json({ error: 'query is required' }, { status: 400 })
    }
    if (query.length > 500) {
      return NextResponse.json({ error: 'Query too long (max 500 characters)' }, { status: 400 })
    }

    // 1. Build RAG context from Knowledge Brain
    const ragContext  = await buildRAGContext(query, session.id)
    const contextText = formatRAGContextForPrompt(ragContext)

    // 2. Try Gemini 2.5 Flash as primary
    let answer: string | null = null
    let llmUsed = 'none'

    try {
      answer  = await callGemini(ragContext.systemPrompt, contextText, query)
      llmUsed = 'gemini-2.5-flash'
    } catch (geminiErr) {
      console.warn('Gemini failed, trying OpenRouter fallback:', geminiErr)

      // 3. Fallback to OpenRouter (claude-3-haiku)
      try {
        answer  = await callOpenRouter(ragContext.systemPrompt, contextText, query)
        llmUsed = 'openrouter/claude-3-haiku'
      } catch (orErr) {
        console.error('OpenRouter also failed:', orErr)
        // 4. Static fallback
        answer  = FALLBACK_MESSAGE
        llmUsed = 'static_fallback'
      }
    }

    return NextResponse.json({
      success:      true,
      answer,
      llm_used:     llmUsed,
      sources_count: ragContext.articles.length,
    })

  } catch (error) {
    console.error('AI Senior error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
