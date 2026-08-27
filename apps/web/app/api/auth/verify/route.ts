// ============================================================
// POST /api/auth/verify
// Verifies the Supabase OTP sent to the user's email.
// On success, the Supabase SSR client sets the session cookie via the response.
// Returns the redirect path based on user role.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import type { Database } from '@/../../supabase/types/database.types'

export async function POST(request: NextRequest) {
  let body: { email?: unknown; token?: unknown }

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const { email, token } = body

  if (typeof email !== 'string' || !email.trim()) {
    return NextResponse.json({ error: 'email is required' }, { status: 400 })
  }
  if (typeof token !== 'string' || !token.trim()) {
    return NextResponse.json({ error: 'token (OTP) is required' }, { status: 400 })
  }

  // We need to track cookies to set on the response
  const cookiesToSet: Array<{ name: string; value: string; options: Record<string, unknown> }> = []

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(incoming) {
          incoming.forEach(c => cookiesToSet.push(c as { name: string; value: string; options: Record<string, unknown> }))
        },
      },
    }
  )

  const { data, error } = await supabase.auth.verifyOtp({
    email: email.trim().toLowerCase(),
    token: token.trim(),
    type: 'email',
  })

  if (error || !data.user) {
    console.error('[POST /api/auth/verify] OTP verify error:', error)
    return NextResponse.json(
      { error: 'Invalid or expired OTP. Please try again.' },
      { status: 401 }
    )
  }

  // Fetch user profile from the database to determine role-based redirect
  const { data: profileRows } = await supabase.rpc('get_my_profile')
  const profileRaw = Array.isArray(profileRows) ? profileRows[0] : profileRows

  const profile = profileRaw as {
    role_label: string;
    roles: Record<string, boolean> | null;
    onboarding_complete: boolean;
    name: string;
  } | null

  // Determine redirect path
  let redirect = '/student' // default
  if (profile) {
    const roleLabel = (profile.role_label || '').toLowerCase()
    const isPlacementRep = profile.roles?.isPlacementRep === true
    if (roleLabel === 'faculty' || roleLabel === 'hod') redirect = '/faculty'
    else if (roleLabel === 'alumni') redirect = '/alumni'
    else if (roleLabel === 'student' && isPlacementRep) redirect = '/placement-rep'
    else if (roleLabel === 'student') redirect = '/student'

    // If onboarding not complete, send to onboarding
    if (!profile.onboarding_complete) {
      redirect = '/onboarding'
    }
  } else {
    // New user — no profile row yet, send to onboarding
    redirect = '/onboarding'
  }

  const responseData = {
    success: true,
    message: 'Login successful',
    redirect,
    user: {
      id: data.user.id,
      email: data.user.email,
      role: profile?.role_label ?? 'student',
      full_name: profile?.name ?? null,
    },
  }

  const response = NextResponse.json(responseData)

  // Apply all session cookies to the response
  cookiesToSet.forEach(({ name, value, options }) => {
    response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2])
  })

  return response
}
