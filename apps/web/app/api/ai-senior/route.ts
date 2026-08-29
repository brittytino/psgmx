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
import { supabaseAdmin } from '@/lib/supabase/admin'
import { GoogleGenerativeAI } from '@google/generative-ai'

import { executeOpenRouterPrompt } from '@/lib/ai/openrouter-free-chain'

const SYSTEM_PROMPT = `You are AI Senior, a preparation companion for MCA students at PSG Tech. 
Answer using the provided approved knowledge as your primary source. Always cite which knowledge item you are drawing from. 
If no approved knowledge directly answers the question, say so and provide general guidance while noting its lower confidence. 
Never fabricate faculty names, company names as official partners, or official drive details. 
If the question is about an active drive or placement portal, respond: "For official drive details, please check NEO PAT."`


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

    // 2. Generate response using OpenRouter Free Model Fallback Chain
    const aiResult = await executeOpenRouterPrompt(
      `Knowledge Brain Context:\n${contextText}\n\nStudent Question: ${query}`,
      'ai_senior_qa',
      ragContext.systemPrompt || SYSTEM_PROMPT
    )

    const answer = aiResult.text
    const llmUsed = aiResult.modelUsed


    // Fire-and-forget: powers the faculty dashboard's "AI Senior Top
    // Queries" widget (Section 7.2). Never block the response on this.
    supabaseAdmin.from('ai_query_logs').insert({ user_id: session.id, query_text: query }).then(
      () => {},
      (err) => console.warn('[AI Senior] Failed to log query:', err)
    )

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
