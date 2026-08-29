import { NextRequest, NextResponse } from 'next/server'
import { normalizeEmail, registerNumberFromCollegeEmail } from '@/lib/auth-input'
import { checkRateLimit } from '@/lib/limiter'
import { isStaffEmail, isStaticOtpEnabled } from '@/lib/staff-auth'
import { provisionStaffByEmail } from '@/lib/staff-provision'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { logEvent, requestId } from '@/lib/observability'
import { sendOtpEmail } from '@/lib/email/resend'
import { saveOtp } from '@/lib/auth/otp-store'

function requestIp(request: NextRequest) {
  return request.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
    || request.headers.get('x-real-ip')
    || 'unknown'
}

function generateNumericOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString()
}

export async function POST(request: NextRequest) {
  const traceId = requestId(request.headers)

  try {
    let body: { email?: unknown }
    try {
      body = await request.json()
    } catch {
      return NextResponse.json({ error: 'Invalid request payload.' }, { status: 400 })
    }

    const email = normalizeEmail(body.email)
    if (!email) {
      return NextResponse.json({ error: 'Enter a valid email address.' }, { status: 400 })
    }

    const rate = checkRateLimit(`otp:${requestIp(request)}:${email}`)
    if (!rate.success) {
      return NextResponse.json({ error: 'Too many attempts. Wait one minute and try again.' }, { status: 429 })
    }

    if (isStaffEmail(email)) {
      try {
        await provisionStaffByEmail(email)
      } catch (error) {
        logEvent('error', 'otp_staff_provision_failed', {
          trace_id: traceId,
          email_domain: email.split('@')[1],
          message: error instanceof Error ? error.message : 'unknown',
        })
      }
    }

    if (isStaffEmail(email) && isStaticOtpEnabled()) {
      try {
        await supabaseAdmin.from('otp_rate_log').insert({ email })
      } catch {}
      logEvent('info', 'otp_static_ready', { trace_id: traceId, email_domain: email.split('@')[1] })
      return NextResponse.json({ 
        success: true, 
        message: `A six-digit verification code has been sent to ${email}.` 
      }, { headers: { 'x-request-id': traceId } })
    }

    // 1. Generate 6-digit OTP code instantly
    const otpCode = generateNumericOtp()

    // 2. Save OTP in resilient server-side store
    saveOtp(email, otpCode)

    // 3. Deliver single branded OTP email via Resend (Only one email is sent)
    const resendResult = await sendOtpEmail(email, otpCode)
    if (resendResult.success) {
      console.log(`[Auth] OTP ${otpCode} sent via Resend to ${email} (Message ID: ${resendResult.data?.id})`)
      logEvent('info', 'otp_resend_delivered', { trace_id: traceId, email, message_id: resendResult.data?.id })
    } else {
      console.error('[Auth] Resend delivery error:', resendResult.error)
      return NextResponse.json({ error: 'Failed to send verification email. Please try again.' }, { status: 500 })
    }

    // Record rate log (non-blocking)
    try {
      await supabaseAdmin.from('otp_rate_log').insert({ email })
    } catch {}

    return NextResponse.json({
      success: true,
      message: `A six-digit verification code has been sent to ${email}.`,
    }, { headers: { 'x-request-id': traceId } })

  } catch (err: any) {
    console.error('[Auth] Fatal error in request-otp:', err)
    return NextResponse.json({
      error: 'Unable to process OTP request. Please try again.',
    }, { status: 500 })
  }
}
