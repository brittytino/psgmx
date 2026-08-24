// ============================================================
// POST /api/auth/login
// Supabase Password-based authentication.
// Supports Email OR Reg Number (Token) as identifier.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(request: NextRequest) {
  let body: { identifier?: string; password?: string }

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const { identifier, password } = body

  if (!identifier?.trim() || !password?.trim()) {
    return NextResponse.json({ error: 'Identifier and password are required' }, { status: 400 })
  }

  const trimmedIdentifier = identifier.trim().toLowerCase()
  let loginEmail = trimmedIdentifier

  // If it doesn't look like an email, assume it's a registration number (token)
  if (!trimmedIdentifier.includes('@')) {
    const { data: rawData, error: userError } = await supabaseAdmin
      .from('users')
      .select('email')
      .ilike('reg_no', trimmedIdentifier)
      .single()
    const userData = rawData as any;

    if (userError || !userData?.email) {
      console.log('User lookup error or not found:', userError?.message)
      return NextResponse.json({ error: 'Invalid identifier or password' }, { status: 401 })
    }
    loginEmail = userData.email
  }

  const supabase = await createClient()

  const { data, error } = await supabase.auth.signInWithPassword({
    email: loginEmail,
    password: password.trim(),
  })

  if (error || !data.user) {
    console.error('[POST /api/auth/login] Sign in error:', error?.message)
    return NextResponse.json({ error: 'Invalid identifier or password' }, { status: 401 })
  }

  // Determine redirect based on role_label and roles (JSONB sub-flags)
  const { data: rawProfile } = await supabaseAdmin
    .from('users')
    .select('role_label, roles, onboarding_complete')
    .eq('id', data.user.id)
    .single()
  const profile = rawProfile as { role_label: string; roles: Record<string, boolean> | null; onboarding_complete: boolean } | null

  let redirectUrl = '/student'
  if (profile) {
    const roleLabel = (profile.role_label || '').toLowerCase()
    const isPlacementRep = profile.roles?.isPlacementRep === true
    if (!profile.onboarding_complete) {
      redirectUrl = '/onboarding'
    } else if (roleLabel === 'faculty' || roleLabel === 'hod') {
      redirectUrl = '/faculty'
    } else if (roleLabel === 'alumni') {
      redirectUrl = '/alumni'
    } else if (roleLabel === 'student' && isPlacementRep) {
      redirectUrl = '/placement-rep'
    }
  }

  return NextResponse.json({
    success: true,
    redirect: redirectUrl,
  })
}
