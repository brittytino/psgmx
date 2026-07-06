// ============================================================
// POST /api/auth/join-alumni
// Migrated: Previously used bcrypt + MongoDB UserAccount.
// Now: Uses Supabase Auth signUp (OTP flow) + users table insert.
// Alumni registration requires HOD approval (users.role stays 'student'
// until HOD promotes to 'alumni' via the alumni approval flow).
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { roll_no, email, full_name, linkedin_url, graduation_year } = body

    if (!roll_no || !email || !full_name) {
      return NextResponse.json(
        { error: 'roll_no, email, and full_name are required.' },
        { status: 400 }
      )
    }

    const cleanedRollNo = roll_no.trim().toUpperCase()
    const cleanedEmail = email.trim().toLowerCase()

    // Check roll_no not already registered
    const { data: existing } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('roll_no', cleanedRollNo)
      .maybeSingle()

    if (existing) {
      return NextResponse.json(
        { error: 'This roll number is already registered.' },
        { status: 409 }
      )
    }

    // Create Supabase Auth user (OTP-based — no password)
    const { data: authUser, error: authErr } = await supabaseAdmin.auth.admin.createUser({
      email: cleanedEmail,
      email_confirm: false,  // Will confirm on first OTP login
      user_metadata: { full_name, roll_no: cleanedRollNo },
    })

    if (authErr || !authUser.user) {
      console.error('Supabase Auth createUser error:', authErr)
      return NextResponse.json(
        { error: 'Failed to create account', detail: authErr?.message },
        { status: 500 }
      )
    }

    // Insert into users table with role 'student' pending HOD approval to 'alumni'
    // TODO: HOD approval flow should update role to 'alumni' when approved
    const { error: insertErr } = await supabaseAdmin.from('users').insert({
      id: authUser.user.id,
      email: cleanedEmail,
      full_name,
      roll_no: cleanedRollNo,
      role: 'student',          // stays student until HOD approves alumni status
      app_role: 'student',
      linkedin_url: linkedin_url || null,
      onboarding_complete: false,
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
