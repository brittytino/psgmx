// ============================================================
// POST /api/auth/login
// Supabase OTP-based authentication.
// The client sends the email → Supabase sends the OTP.
// This endpoint initiates the OTP flow.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  let body: { email?: unknown }

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const { email } = body

  if (typeof email !== 'string' || !email.trim()) {
    return NextResponse.json({ error: 'email is required' }, { status: 400 })
  }

  const trimmedEmail = email.trim().toLowerCase()

  const supabase = await createClient()

  const { error } = await supabase.auth.signInWithOtp({
    email: trimmedEmail,
    options: {
      shouldCreateUser: true,  // Allow new user creation on OTP sign-in
    },
  })

  if (error) {
    console.error('[POST /api/auth/login] OTP send error:', error)
    return NextResponse.json({ error: 'Failed to send OTP', detail: error.message }, { status: 500 })
  }

  return NextResponse.json({
    success: true,
    message: 'OTP sent to your email. Check your inbox.',
  })
}
