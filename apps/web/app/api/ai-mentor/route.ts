import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { checkRateLimit } from '@/lib/limiter'
import { logEvent, requestId } from '@/lib/observability'

export async function POST(request: NextRequest) {
  const traceId = requestId(request.headers)
  const user = await getUserFromRequest(request)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!checkRateLimit(`ai-mentor:${user.id}`).success) return NextResponse.json({ error: 'Please wait before asking again.' }, { status: 429 })
  const body = await request.json().catch(() => null) as { system_prompt?: unknown; message?: unknown; max_tokens?: unknown } | null
  if (!body || typeof body.message !== 'string' || !body.message.trim() || body.message.length > 1800) return NextResponse.json({ error: 'A message up to 1800 characters is required.' }, { status: 400 })
  const system = typeof body.system_prompt === 'string' ? body.system_prompt.slice(0, 1200) : 'You are a concise and encouraging placement-prep mentor for MCA students.'
  const maxTokens = Math.max(100, Math.min(Number(body.max_tokens) || 300, 500))
  const apiKey = process.env.OPENROUTER_API_KEY
  if (!apiKey) return NextResponse.json({ error: 'AI mentor is not configured.' }, { status: 503 })
  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST', headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json', 'HTTP-Referer': process.env.NEXT_PUBLIC_APP_URL ?? 'https://app.psgmx.tech', 'X-Title': 'PSGMX AI Mentor' },
      body: JSON.stringify({ model: process.env.OPENROUTER_MENTOR_MODEL ?? 'google/gemma-3-27b-it:free', max_tokens: maxTokens, messages: [{ role: 'system', content: system }, { role: 'user', content: body.message }] }),
      signal: AbortSignal.timeout(20_000),
    })
    if (!response.ok) throw new Error(`Provider status ${response.status}`)
    const data = await response.json()
    const answer = data.choices?.[0]?.message?.content
    if (!answer) throw new Error('Empty provider response')
    logEvent('info', 'ai_mentor_completed', { trace_id: traceId, user_id: user.id })
    return NextResponse.json({ answer }, { headers: { 'x-request-id': traceId } })
  } catch (error) {
    logEvent('error', 'ai_mentor_failed', { trace_id: traceId, user_id: user.id, message: String(error) })
    return NextResponse.json({ error: 'AI mentor is temporarily unavailable.' }, { status: 503 })
  }
}
