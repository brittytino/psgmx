// ============================================================
// POST /api/ai-senior
// AI Senior RAG chatbot — migrated to Supabase pgvector search.
// Queries knowledge_embeddings for relevant context, then calls
// the LLM via OpenRouter with the retrieved context.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { buildRAGContext, formatRAGContextForPrompt } from '@/lib/ai/rag'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session || !session.id) {
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
    const ragContext = await buildRAGContext(query, session.id)
    const contextText = formatRAGContextForPrompt(ragContext)

    // 2. Call LLM via OpenRouter
    const openRouterKey = process.env.OPENROUTER_API_KEY
    if (!openRouterKey) {
      return NextResponse.json({ error: 'AI service not configured' }, { status: 503 })
    }

    const messages = [
      { role: 'system', content: ragContext.systemPrompt },
      {
        role: 'user',
        content: `Knowledge Brain Context:\n${contextText}\n\nStudent Question: ${query}`,
      },
    ]

    const llmResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': process.env.NEXT_PUBLIC_APP_URL ?? 'https://psgmx.tech',
        'X-Title': 'PSGMX AI Senior',
      },
      body: JSON.stringify({
        model: 'google/gemini-flash-1.5',  // Fast, cost-effective for educational use
        messages,
        max_tokens: 800,
        temperature: 0.3,  // Low temperature for factual accuracy
      }),
    })

    if (!llmResponse.ok) {
      const err = await llmResponse.text()
      console.error('OpenRouter error:', err)
      return NextResponse.json({ error: 'AI service error' }, { status: 502 })
    }

    const llmData = await llmResponse.json()
    const answer = llmData.choices?.[0]?.message?.content ?? 'I could not generate a response. Please try again.'

    return NextResponse.json({
      success: true,
      answer,
      sourcesCount: ragContext.articles.length,
    })

  } catch (error) {
    console.error('AI Senior error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
