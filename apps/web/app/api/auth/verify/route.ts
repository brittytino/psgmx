import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import type { Database } from '@/../../supabase/types/database.types'
import { normalizeEmail } from '@/lib/auth-input'
import { dashboardPath, isStaticStaffOtp } from '@/lib/staff-auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

type CookieToSet = { name: string; value: string; options: Record<string, unknown> }

export async function POST(request: NextRequest) {
  let body: { email?: unknown; token?: unknown }

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const email = normalizeEmail(body.email)
  const token = typeof body.token === 'string' ? body.token.trim() : ''

  if (!email) {
    return NextResponse.json({ error: 'email is required' }, { status: 400 })
  }
  if (!token) {
    return NextResponse.json({ error: 'token (OTP) is required' }, { status: 400 })
  }

  const cookiesToSet: CookieToSet[] = []

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(incoming) {
          incoming.forEach((c) => cookiesToSet.push(c as CookieToSet))
        },
      },
    },
  )

  let userId: string | undefined
  let userEmail: string | undefined

  if (isStaticStaffOtp(email, token)) {
    const { data: linkData, error: linkError } = await supabaseAdmin.auth.admin.generateLink({
      type: 'magiclink',
      email,
    })
    const hashedToken = linkData?.properties?.hashed_token
    if (linkError || !hashedToken) {
      console.error('[POST /api/auth/verify] Static OTP link error:', linkError)
      return NextResponse.json({ error: 'Invalid or expired OTP. Please try again.' }, { status: 401 })
    }
    const { data, error } = await supabase.auth.verifyOtp({
      type: 'email',
      token_hash: hashedToken,
    })
    if (error || !data.user) {
      console.error('[POST /api/auth/verify] Static OTP verify error:', error)
      return NextResponse.json({ error: 'Invalid or expired OTP. Please try again.' }, { status: 401 })
    }
    userId = data.user.id
    userEmail = data.user.email
  } else {
    const { data, error } = await supabase.auth.verifyOtp({
      email,
      token,
      type: 'email',
    })
    if (error || !data.user) {
      console.error('[POST /api/auth/verify] OTP verify error:', error)
      return NextResponse.json({ error: 'Invalid or expired OTP. Please try again.' }, { status: 401 })
    }
    userId = data.user.id
    userEmail = data.user.email
  }

  const { data: profileRows } = await supabase.rpc('get_my_profile')
  const profileRaw = Array.isArray(profileRows) ? profileRows[0] : profileRows

  const profile = profileRaw as {
    id: string
    role_label: string
    roles: Record<string, boolean> | null
    onboarding_complete: boolean
    name: string
  } | null

  if (profile && !profile.onboarding_complete) {
    await supabaseAdmin.from('users').update({ onboarding_complete: true }).eq('id', profile.id)
    profile.onboarding_complete = true
  }

  const redirect = profile ? dashboardPath(profile.role_label, profile.roles) : '/onboarding'

  const response = NextResponse.json({
    success: true,
    message: 'Login successful',
    redirect,
    user: {
      id: userId,
      email: userEmail,
      role: profile?.role_label ?? 'student',
      full_name: profile?.name ?? null,
    },
  })

  cookiesToSet.forEach(({ name, value, options }) => {
    response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2])
  })

  return response
}
