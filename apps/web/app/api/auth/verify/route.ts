import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import type { Database } from '@/../../supabase/types/database.types'
import { normalizeEmail } from '@/lib/auth-input'
import { dashboardPath, isStaticStaffOtp } from '@/lib/staff-auth'
import { readOtpChallenge } from '@/lib/auth/otp-challenge'
import { supabaseAdmin } from '@/lib/supabase/admin'

type CookieToSet = { name: string; value: string; options: Record<string, unknown> }

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null) as { email?: unknown; token?: unknown } | null
  const email = normalizeEmail(body?.email)
  const token = typeof body?.token === 'string' ? body.token.trim() : ''
  if (!email || !/^\d{6}$/.test(token)) {
    return NextResponse.json({ error: 'Enter the email and six-digit code.' }, { status: 400 })
  }

  const now = Date.now()
  const { data: attemptState, error: attemptReadError } = await supabaseAdmin
    .from('otp_verification_attempts')
    .select('failed_count, last_failed_at, locked_until')
    .eq('email', email)
    .maybeSingle()
  if (attemptReadError) {
    console.error('[POST /api/auth/verify] Lockout read failed:', attemptReadError)
    return NextResponse.json({ error: 'Verification is temporarily unavailable.' }, { status: 503 })
  }
  const lockedUntil = attemptState?.locked_until ? new Date(attemptState.locked_until).getTime() : 0
  if (lockedUntil > now) {
    return NextResponse.json(
      { error: 'Too many invalid codes. Try again after the 15-minute lockout.' },
      { status: 429 },
    )
  }

  const cookiesToSet: CookieToSet[] = []
  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL || '',
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (incoming) => incoming.forEach((cookie) => cookiesToSet.push(cookie as CookieToSet)),
      },
    },
  )

  const staticChallenge = isStaticStaffOtp(email, token)
    ? readOtpChallenge(request.cookies.get('psgmx_otp_challenge')?.value)
    : null

  const verification = staticChallenge?.email === email
    ? await supabase.auth.verifyOtp({ token_hash: staticChallenge.tokenHash, type: 'email' })
    : await supabase.auth.verifyOtp({ email, token, type: 'email' })

  if (verification.error || !verification.data.user) {
    const lastFailedAt = attemptState?.last_failed_at ? new Date(attemptState.last_failed_at).getTime() : 0
    const previousCount = now - lastFailedAt < 15 * 60 * 1000 ? Number(attemptState?.failed_count ?? 0) : 0
    const failedCount = previousCount + 1
    const lock = failedCount >= 3 ? new Date(now + 15 * 60 * 1000).toISOString() : null
    const { error: attemptWriteError } = await supabaseAdmin.from('otp_verification_attempts').upsert({
      email,
      failed_count: failedCount,
      last_failed_at: new Date(now).toISOString(),
      locked_until: lock,
      updated_at: new Date(now).toISOString(),
    })
    if (attemptWriteError) console.error('[POST /api/auth/verify] Lockout write failed:', attemptWriteError)
    return NextResponse.json(
      { error: lock ? 'Too many invalid codes. Sign-in is locked for 15 minutes.' : 'Invalid or expired code. Request a new code and try again.' },
      { status: lock ? 429 : 401 },
    )
  }

  await supabaseAdmin.from('otp_verification_attempts').delete().eq('email', email)

  const { data: rows, error: profileError } = await supabase.rpc('get_my_profile')
  const profile = Array.isArray(rows) ? rows[0] : rows
  if (profileError || !profile) {
    await supabase.auth.signOut()
    return NextResponse.json({ error: 'This verified identity is not linked to a PSGMX profile.' }, { status: 403 })
  }

  const isMobileClient = request.headers.get('x-psgmx-client') === 'mobile'
  const response = NextResponse.json({
    success: true,
    redirect: dashboardPath(profile.role_label, profile.roles as { isPlacementRep?: boolean }),
    user: {
      id: profile.id,
      email,
      role: profile.role_label,
      full_name: profile.name,
    },
    ...(isMobileClient && verification.data.session ? {
      session: {
        access_token: verification.data.session.access_token,
        refresh_token: verification.data.session.refresh_token,
      },
    } : {}),
  })

  cookiesToSet.forEach(({ name, value, options }) => {
    response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2])
  })
  response.cookies.set('psgmx_otp_challenge', '', { path: '/api/auth', maxAge: 0 })
  return response
}
