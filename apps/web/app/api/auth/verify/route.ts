import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import type { Database } from '@/../../supabase/types/database.types'
import { normalizeEmail } from '@/lib/auth-input'
import { dashboardPath, isStaticStaffOtp } from '@/lib/staff-auth'
import { readOtpChallenge } from '@/lib/auth/otp-challenge'

type CookieToSet = { name: string; value: string; options: Record<string, unknown> }

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null) as { email?: unknown; token?: unknown } | null
  const email = normalizeEmail(body?.email)
  const token = typeof body?.token === 'string' ? body.token.trim() : ''
  if (!email || !/^\d{6}$/.test(token)) {
    return NextResponse.json({ error: 'Enter the email and six-digit code.' }, { status: 400 })
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
    return NextResponse.json({ error: 'Invalid or expired code. Request a new code and try again.' }, { status: 401 })
  }

  const { data: rows, error: profileError } = await supabase.rpc('get_my_profile')
  const profile = Array.isArray(rows) ? rows[0] : rows
  if (profileError || !profile) {
    await supabase.auth.signOut()
    return NextResponse.json({ error: 'This verified identity is not linked to a PSGMX profile.' }, { status: 403 })
  }

  const response = NextResponse.json({
    success: true,
    redirect: dashboardPath(profile.role_label, profile.roles as { isPlacementRep?: boolean }),
    user: {
      id: profile.id,
      email,
      role: profile.role_label,
      full_name: profile.name,
    },
  })

  cookiesToSet.forEach(({ name, value, options }) => {
    response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2])
  })
  response.cookies.set('psgmx_otp_challenge', '', { path: '/api/auth', maxAge: 0 })
  return response
}
