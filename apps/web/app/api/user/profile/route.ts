// ============================================================
// GET/PUT /api/user/profile
// Migrated to Supabase (New Schema).
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user || !user.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Explicit column list — never select('*') on `users`. ecampus_password
    // is column-level REVOKEd for the authenticated role, so a wildcard
    // select here would error the whole request.
    const { data: profile, error } = await supabase
      .from('users')
      .select('id, email, name, reg_no, team_id, batch, batch_id, gender, roles, ' +
        'dob, role_label, leetcode_username, ecampus_password_set, ' +
        'avatar_url, linkedin_url, github_url, current_company, current_role_title, ' +
        'skills, mentorship_open, arrears, ' +
        'birthday_notifications_enabled, leetcode_notifications_enabled, ' +
        'task_reminders_enabled, attendance_alerts_enabled, ' +
        'announcements_enabled, created_at, updated_at')
      .eq('id', user.id)
      .single()

    if (error) {
      console.error('Profile fetch error:', error)
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    // The onboarding form (apps/web/app/onboarding/page.tsx) reads these
    // aliased keys alongside the raw column names above.
    // `as any`: supabase/types/database.types.ts needs regenerating
    // (`supabase gen types typescript`) against this rebuilt schema.
    const p = profile as any
    return NextResponse.json({
      success: true,
      profile: {
        ...p,
        fullName: p.name,
        linkedin: p.linkedin_url,
        github: p.github_url,
      },
    })
  } catch (error) {
    console.error('Profile API Error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user || !user.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const {
      name, fullName, linkedin, linkedin_url, github, github_url, skills,
      avatar_url, current_company, current_role_title, mentorship_open,
    } = body

    const updateData: Record<string, unknown> = {}
    // `fullName`/`linkedin`/`github` are the onboarding form's field names
    // (apps/web/app/onboarding/page.tsx); `name`/`linkedin_url`/`github_url`
    // are the raw column names, accepted too for any other caller.
    if (name !== undefined) updateData.name = name
    if (fullName !== undefined) updateData.name = fullName
    if (linkedin_url !== undefined) updateData.linkedin_url = linkedin_url
    if (linkedin !== undefined) updateData.linkedin_url = linkedin
    if (github_url !== undefined) updateData.github_url = github_url
    if (github !== undefined) updateData.github_url = github
    if (skills !== undefined) updateData.skills = skills
    if (avatar_url !== undefined) updateData.avatar_url = avatar_url
    if (current_company !== undefined) updateData.current_company = current_company
    if (current_role_title !== undefined) updateData.current_role_title = current_role_title
    if (mentorship_open !== undefined) updateData.mentorship_open = mentorship_open

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json({ error: 'No fields to update' }, { status: 400 })
    }

    const { error } = await supabase
      .from('users')
      // @ts-ignore — see the `as any` note in GET above re: stale generated types
      .update(updateData)
      .eq('id', user.id)

    if (error) throw error

    return NextResponse.json({ success: true, message: 'Profile updated' })
  } catch {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
