// ============================================================
// POST /api/auth/join-alumni
// Uses Supabase Auth signUp (Password flow) + users table insert.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { token, graduationYear, linkedin, email, password } = body

    if (!token || !email || !password || !graduationYear) {
      return NextResponse.json(
        { error: 'Roll number, email, graduation year, and password are required.' },
        { status: 400 }
      )
    }

    const cleanedRegNo = token.trim().toUpperCase()
    const cleanedEmail = email.trim().toLowerCase()

    // Check reg_no not already registered
    const { data: existing } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('reg_no', cleanedRegNo)
      .maybeSingle()

    if (existing) {
      return NextResponse.json(
        { error: 'This roll number is already registered.' },
        { status: 409 }
      )
    }

    // Create Supabase Auth user (Password-based)
    const { data: authUser, error: authErr } = await supabaseAdmin.auth.admin.createUser({
      email: cleanedEmail,
      password: password,
      email_confirm: true,  // Automatically confirm for simplicity, or false if HOD must approve first
      user_metadata: { reg_no: cleanedRegNo },
    })

    if (authErr || !authUser.user) {
      console.error('Supabase Auth createUser error:', authErr)
      return NextResponse.json(
        { error: 'Failed to create account', detail: authErr?.message },
        { status: 500 }
      )
    }

    // Insert into users table
    const { error: insertErr } = await supabaseAdmin.from('users').insert({
      id: authUser.user.id,
      email: cleanedEmail,
      reg_no: cleanedRegNo,
      role_label: 'Alumni',
      roles: {
        isStudent: false,
        isTeamLeader: false,
        isCoordinator: false,
        isPlacementRep: false
      },
      name: 'Alumni ' + cleanedRegNo, // Default name since it's not collected
      batch: 'G1', // Default required column
    } as any)

    if (insertErr) {
      console.error('Users insert error:', insertErr)
      // Clean up auth user if profile insert failed
      await supabaseAdmin.auth.admin.deleteUser(authUser.user.id).catch(() => {})
      return NextResponse.json(
        { error: 'Failed to create user profile', detail: insertErr.message },
        { status: 500 }
      )
    }

    return NextResponse.json({
      success: true,
      message: 'Registration submitted. You will receive an OTP email once approved.',
    }, { status: 201 })

  } catch (error) {
    console.error('Alumni Join Error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
