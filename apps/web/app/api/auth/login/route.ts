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
    const { data: userData, error: userError } = await supabaseAdmin
      .from('users')
      .select('email')
      .ilike('reg_no', trimmedIdentifier)
      .single()

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

  // Determine redirect based on role label
  const { data: profile } = await supabaseAdmin
    .from('users')
    .select('role_label, roles')
    .eq('id', data.user.id)
    .single()

  const roleLabel = profile?.role_label?.toLowerCase() || 'student'
  let redirectUrl = '/student'
  
  if (roleLabel === 'faculty' || roleLabel === 'hod') redirectUrl = '/faculty'
  if (roleLabel === 'alumni') redirectUrl = '/alumni'
  // Could also check profile.roles.isCoordinator, etc.

  return NextResponse.json({
    success: true,
    redirect: redirectUrl,
  })
}
