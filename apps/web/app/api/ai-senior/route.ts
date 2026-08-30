import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { buildRAGContext, formatRAGContextForPrompt } from '@/lib/ai/rag'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { AIUnavailableError, executeOpenRouterPrompt } from '@/lib/ai/openrouter-free-chain'

const db = supabaseAdmin as any
const SYSTEM_PROMPT = `You are AI Senior, the continuing placement-preparation companion for PSG Tech MCA students.
Ground claims in the supplied Knowledge Brain and current student evidence. NEO PAT is the only source for official drives, eligibility, shortlists, and package information; PSGMX prepares students and preserves clearly labelled historical interview evidence.
Give practical next actions at the student's current level. State uncertainty when evidence is missing or old. Never invent company facts, scores, attendance, or alumni experiences. Do not reveal hidden chain-of-thought; provide a concise rationale and answer.`

async function ownedConversation(conversationId: string, userId: string) {
  if (!/^[0-9a-f-]{36}$/i.test(conversationId)) return null
  const { data } = await db.from('ai_conversations').select('*').eq('id', conversationId).eq('user_id', userId).maybeSingle()
  return data
}

export async function GET(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const requested = req.nextUrl.searchParams.get('conversation_id') || ''
  const conversation = requested ? await ownedConversation(requested, user.id) : null
  const [{ count: articleCount }, { count: patternCount }, { count: alumniCount }] = await Promise.all([
    db.from('knowledge_brain_articles').select('id', { count: 'exact', head: true }).eq('approval_status', 'approved'),
    db.from('interview_patterns').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    db.from('users').select('id', { count: 'exact', head: true }).eq('role_label', 'Alumni'),
  ])

  let messages: Array<{ role: string; content: string; created_at: string }> = []
  if (conversation) {
    const { data } = await db.from('ai_messages')
      .select('role, content, created_at')
      .eq('conversation_id', conversation.id)
      .order('created_at')
      .limit(40)
    messages = data || []
  }

  return NextResponse.json({
    conversation_id: conversation?.id || null,
    messages,
    knowledge_stats: {
      articles: articleCount || 0,
      interview_patterns: patternCount || 0,
      alumni_contributors: alumniCount || 0,
    },
  })
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = await req.json().catch(() => null) as { query?: unknown; conversation_id?: unknown } | null
  const query = typeof body?.query === 'string' ? body.query.trim() : ''
  if (!query || query.length > 2000) {
    return NextResponse.json({ error: 'Enter a question of at most 2,000 characters.' }, { status: 400 })
  }

  const requestedId = typeof body?.conversation_id === 'string' ? body.conversation_id : ''
  let conversation = requestedId ? await ownedConversation(requestedId, user.id) : null
  if (requestedId && !conversation) {
    return NextResponse.json({ error: 'Conversation not found.' }, { status: 404 })
  }
  if (!conversation) {
    const { data, error } = await db.from('ai_conversations').insert({
      user_id: user.id,
      title: query.slice(0, 80),
    }).select('*').single()
    if (error || !data) return NextResponse.json({ error: 'Could not create a conversation.' }, { status: 500 })
    conversation = data
  }

  const [{ data: history }, ragContext, { data: readiness }, { data: streak }, { data: leetcode }] = await Promise.all([
    db.from('ai_messages').select('role, content').eq('conversation_id', conversation.id).order('created_at', { ascending: false }).limit(8),
    buildRAGContext(query, user.id),
    db.from('current_readiness_scores').select('score, components_json, computed_at').eq('user_id', user.id).maybeSingle(),
    db.from('daily_five_streaks').select('current_streak, longest_streak, last_accuracy_rate').eq('user_id', user.id).maybeSingle(),
    user.reg_no
      ? db.from('users').select('leetcode_username').eq('id', user.id).maybeSingle().then(async ({ data }: any) => {
          if (!data?.leetcode_username) return { data: null }
          return db.from('leetcode_stats').select('total_solved, easy_solved, medium_solved, hard_solved, weekly_score, last_updated').eq('username', data.leetcode_username).maybeSingle()
        })
      : Promise.resolve({ data: null }),
  ])

  const recent = [...(history || [])].reverse()
    .map((message: any) => `${message.role === 'assistant' ? 'AI Senior' : 'Student'}: ${message.content}`)
    .join('\n')
  const evidence = JSON.stringify({
    name: user.name,
    register_number: user.reg_no,
    readiness: readiness || null,
    daily_five: streak || null,
    leetcode: leetcode || null,
  })
  const prompt = `Current verified student evidence:\n${evidence}\n\nRolling context summary:\n${conversation.context_summary || '(new conversation)'}\n\nRecent conversation:\n${recent || '(none)'}\n\nKnowledge Brain evidence:\n${formatRAGContextForPrompt(ragContext)}\n\nStudent question:\n${query}`

  try {
    const ai = await executeOpenRouterPrompt(prompt, 'ai_senior_qa', `${SYSTEM_PROMPT}\n${ragContext.systemPrompt}`)
    const summary = `${conversation.context_summary || ''}\nStudent asked: ${query.slice(0, 220)}`.trim().slice(-1200)
    const now = new Date().toISOString()

    const { error: messageError } = await db.from('ai_messages').insert([
      { conversation_id: conversation.id, role: 'user', content: query },
      { conversation_id: conversation.id, role: 'assistant', content: ai.text, model_used: ai.modelUsed },
    ])
    if (messageError) throw messageError
    await db.from('ai_conversations').update({
      context_summary: summary,
      last_model_used: ai.modelUsed,
      last_message_at: now,
      updated_at: now,
    }).eq('id', conversation.id).eq('user_id', user.id)

    return NextResponse.json({
      success: true,
      answer: ai.text,
      conversation_id: conversation.id,
      model_used: ai.modelUsed,
      used_fallback_model: ai.isFallback,
      sources: ragContext.articles.map((article) => article.title),
    })
  } catch (error) {
    const status = error instanceof AIUnavailableError ? 503 : 500
    return NextResponse.json({
      error: status === 503
        ? 'All free AI models are currently busy. Your question was not answered or stored; please retry shortly.'
        : 'The response could not be stored safely. Please retry.',
      conversation_id: conversation.id,
    }, { status })
  }
}
