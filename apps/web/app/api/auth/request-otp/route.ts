import { createClient } from '@supabase/supabase-js'
import { NextRequest, NextResponse } from 'next/server'
import { normalizeEmail } from '@/lib/auth-input'
import { checkRateLimit } from '@/lib/limiter'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { logEvent, requestId } from '@/lib/observability'

const GENERIC_MESSAGE = 'If this email is on the PSGMX roster, a six-digit code has been sent.'

function requestIp(request: NextRequest) {
  return request.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
    || request.headers.get('x-real-ip')
    || 'unknown'
}

export async function POST(request: NextRequest) {
  const traceId = requestId(request.headers)
  let body: { email?: unknown }
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid request.' }, { status: 400 })
  }

  const email = normalizeEmail(body.email)
  if (!email) return NextResponse.json({ error: 'Enter a valid email address.' }, { status: 400 })
  if (email.endsWith('@roster.psgmx.invalid')) {
    return NextResponse.json({ success: true, message: GENERIC_MESSAGE })
  }

  const rate = checkRateLimit(`otp:${requestIp(request)}:${email}`)
  if (!rate.success) {
    return NextResponse.json({ error: 'Too many attempts. Wait one minute and try again.' }, { status: 429 })
  }

  const since = new Date(Date.now() - 10 * 60 * 1000).toISOString()
  const [{ data: alias }, { count }] = await Promise.all([
    supabaseAdmin
      .from('whitelist_email_aliases')
      .select('email')
      .eq('email', email)
      .maybeSingle(),
    supabaseAdmin
      .from('otp_rate_log')
      .select('id', { count: 'exact', head: true })
      .eq('email', email)
      .gte('sent_at', since),
  ])

  // Keep the response intentionally indistinguishable for unknown addresses.
  if (!alias) return NextResponse.json({ success: true, message: GENERIC_MESSAGE })
  if ((count ?? 0) >= 3) {
    return NextResponse.json({ error: 'Too many codes requested. Try again in ten minutes.' }, { status: 429 })
  }

  const auth = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  )

  const { error } = await auth.auth.signInWithOtp({
    email,
    options: { shouldCreateUser: true },
  })

  if (error) {
    logEvent('error', 'otp_send_failed', { trace_id: traceId, email_domain: email.split('@')[1], message: error.message })
    return NextResponse.json({ error: 'The code could not be sent. Please try again.' }, { status: 503 })
  }

  await supabaseAdmin.from('otp_rate_log').insert({ email })
  logEvent('info', 'otp_sent', { trace_id: traceId, email_domain: email.split('@')[1] })
  return NextResponse.json({ success: true, message: GENERIC_MESSAGE }, { headers: { 'x-request-id': traceId } })
}
