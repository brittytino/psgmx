import { NextRequest, NextResponse } from 'next/server'
import { normalizeEmail } from '@/lib/auth-input'
import { checkRateLimit } from '@/lib/limiter'
import { isStaffEmail, isStaticOtpEnabled } from '@/lib/staff-auth'
import { provisionStaffByEmail } from '@/lib/staff-provision'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { logEvent, requestId } from '@/lib/observability'
import { sendOtpEmail } from '@/lib/email/resend'
import { signOtpChallenge } from '@/lib/auth/otp-challenge'

function requestIp(request: NextRequest) {
  return request.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
    || request.headers.get('x-real-ip')
    || 'unknown'
}

async function isApprovedIdentity(email: string) {
  const { data: alias } = await supabaseAdmin
    .from('whitelist_email_aliases')
    .select('email')
    .eq('email', email)
    .maybeSingle()
  if (alias) return true

  const { data: roster } = await supabaseAdmin
    .from('whitelist')
    .select('email')
    .or(`email.eq.${email},personal_email.eq.${email},college_email.eq.${email}`)
    .maybeSingle()
  if (roster) return true

  const { data: user } = await supabaseAdmin
    .from('users')
    .select('email')
    .or(`email.eq.${email},personal_email.eq.${email},college_email.eq.${email}`)
    .maybeSingle()
  return Boolean(user)
}

async function ensureAuthIdentity(email: string) {
  const created = await supabaseAdmin.auth.admin.createUser({ email, email_confirm: true })
  if (!created.error || /already|registered|exists/i.test(created.error.message)) return
  throw created.error
}

export async function POST(request: NextRequest) {
  const traceId = requestId(request.headers)
  try {
    const body = await request.json().catch(() => null) as { email?: unknown } | null
    const email = normalizeEmail(body?.email)
    if (!email) return NextResponse.json({ error: 'Enter a valid email address.' }, { status: 400 })

    const rate = checkRateLimit(`otp:${requestIp(request)}:${email}`)
    if (!rate.success) {
      return NextResponse.json({ error: 'Too many attempts. Wait one minute and try again.' }, { status: 429 })
    }

    if (isStaffEmail(email)) await provisionStaffByEmail(email)
    if (!(await isApprovedIdentity(email))) {
      return NextResponse.json(
        { error: 'This email is not on the approved student, faculty, or alumni roster.' },
        { status: 403 },
      )
    }

    await ensureAuthIdentity(email)
    const redirectTo = `${process.env.NEXT_PUBLIC_APP_URL || request.nextUrl.origin}/login`
    const { data, error } = await supabaseAdmin.auth.admin.generateLink({
      type: 'magiclink',
      email,
      options: { redirectTo },
    })
    if (error || !data.properties?.email_otp || !data.properties?.hashed_token) {
      throw error || new Error('Supabase did not issue an OTP challenge.')
    }

    const delivery = await sendOtpEmail(email, data.properties.email_otp)
    if (!delivery.success) throw new Error('OTP email delivery failed.')

    await supabaseAdmin.from('otp_rate_log').insert({ email })
    logEvent('info', 'otp_issued', { trace_id: traceId, email_domain: email.split('@')[1] })

    const response = NextResponse.json({
      success: true,
      message: `A six-digit verification code has been sent to ${email}.`,
    }, { headers: { 'x-request-id': traceId } })

    if (isStaffEmail(email) && isStaticOtpEnabled()) {
      const signed = signOtpChallenge({
        email,
        tokenHash: data.properties.hashed_token,
        expiresAt: Date.now() + 10 * 60 * 1000,
      })
      if (signed) {
        response.cookies.set('psgmx_otp_challenge', signed, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          path: '/api/auth',
          maxAge: 10 * 60,
        })
      }
    }

    return response
  } catch (error) {
    logEvent('error', 'otp_request_failed', {
      trace_id: traceId,
      message: error instanceof Error ? error.message : 'unknown',
    })
    return NextResponse.json({ error: 'Unable to send a verification code. Please try again.' }, { status: 500 })
  }
}
