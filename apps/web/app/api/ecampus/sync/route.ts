import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { checkRateLimit } from '@/lib/limiter'
import { logEvent, requestId } from '@/lib/observability'

export async function POST(request: NextRequest) {
  const traceId = requestId(request.headers)
  const user = await getUserFromRequest(request)
  if (!user?.reg_no) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const rate = checkRateLimit(`ecampus:${user.id}`)
  if (!rate.success) return NextResponse.json({ error: 'Please wait before refreshing again.' }, { status: 429 })

  const baseUrl = process.env.ECAMPUS_API_URL
  const secret = process.env.ECAMPUS_API_SECRET
  if (!baseUrl || !secret) {
    return NextResponse.json({ error: 'Academic sync is not configured.' }, { status: 503 })
  }

  const target = new URL('/api/ecampus/sync', baseUrl)
  target.searchParams.set('rollno', user.reg_no)
  try {
    const response = await fetch(target, {
      method: 'POST',
      headers: { 'X-Api-Secret': secret, 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(90_000),
      cache: 'no-store',
    })
    const text = await response.text()
    if (!response.ok) {
      logEvent('warn', 'ecampus_sync_failed', { trace_id: traceId, user_id: user.id, status: response.status })
      return NextResponse.json({ error: response.status === 422 ? 'eCampus login failed. Update your portal password.' : 'Academic attendance could not be refreshed.' }, { status: response.status === 422 ? 422 : 502 })
    }
    logEvent('info', 'ecampus_sync_completed', { trace_id: traceId, user_id: user.id })
    return new NextResponse(text, { status: 200, headers: { 'Content-Type': 'application/json', 'x-request-id': traceId } })
  } catch (error) {
    logEvent('error', 'ecampus_sync_unreachable', { trace_id: traceId, user_id: user.id, message: String(error) })
    return NextResponse.json({ error: 'Academic sync is temporarily unavailable.' }, { status: 503 })
  }
}
