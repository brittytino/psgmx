// ============================================================
// GET/PUT /api/user/profile
// Authenticated profile endpoint. Never fabricates a user when the session is absent.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { getSessionUser } from '@/lib/auth'
import { dashboardPath } from '@/lib/staff-auth'

export async function GET(req: NextRequest) {
  try {
    const user = await getSessionUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const supabase = await createClient()
    let profile: any = null

    // Try query by id if valid UUID
    const isValidUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user.id)
    if (isValidUuid) {
      const { data } = await supabaseAdmin
        .from('users')
        .select('id, email, name, reg_no, team_id, batch, batch_id, gender, roles, ' +
          'dob, role_label, onboarding_complete, leetcode_username, ecampus_password_set, ' +
          'avatar_url, linkedin_url, github_url, current_company, current_role_title, ' +
          'skills, mentorship_open, arrears, ' +
          'birthday_notifications_enabled, leetcode_notifications_enabled, ' +
          'task_reminders_enabled, attendance_alerts_enabled, ' +
          'announcements_enabled, created_at, updated_at')
        .eq('id', user.id)
        .maybeSingle()
      if (data) profile = data
    }

    // Try query by email
    if (!profile && user.email) {
      const { data } = await supabaseAdmin
        .from('users')
        .select('id, email, name, reg_no, team_id, batch, batch_id, gender, roles, ' +
          'dob, role_label, onboarding_complete, leetcode_username, ecampus_password_set, ' +
          'avatar_url, linkedin_url, github_url, current_company, current_role_title, ' +
          'skills, mentorship_open, arrears, ' +
          'birthday_notifications_enabled, leetcode_notifications_enabled, ' +
          'task_reminders_enabled, attendance_alerts_enabled, ' +
          'announcements_enabled, created_at, updated_at')
        .eq('email', user.email)
        .maybeSingle()
      if (data) profile = data
    }

    if (!profile) return NextResponse.json({ error: 'Profile not found' }, { status: 404 })

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
    return NextResponse.json({ error: 'Unable to load profile' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  try {
    const supabase = await createClient()
    const user = await getSessionUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const {
      name, fullName, linkedin, linkedin_url, github, github_url, skills,
      avatar_url, current_company, current_role_title, mentorship_open,
      task_reminders_enabled, attendance_alerts_enabled, announcements_enabled,
      leetcode_notifications_enabled, leetcode_username,
    } = body

    const updateData: Record<string, unknown> = {}
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
    if (leetcode_username !== undefined) updateData.leetcode_username = leetcode_username.trim() || null
    if (task_reminders_enabled !== undefined) updateData.task_reminders_enabled = Boolean(task_reminders_enabled)
    if (attendance_alerts_enabled !== undefined) updateData.attendance_alerts_enabled = Boolean(attendance_alerts_enabled)
    if (announcements_enabled !== undefined) updateData.announcements_enabled = Boolean(announcements_enabled)
    if (leetcode_notifications_enabled !== undefined) updateData.leetcode_notifications_enabled = Boolean(leetcode_notifications_enabled)
    if (body.completeOnboarding === true || fullName !== undefined || linkedin !== undefined) {
      updateData.onboarding_complete = true
    }

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json({ error: 'No fields to update' }, { status: 400 })
    }

    const isValidUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user.id)
    if (isValidUuid) {
      await supabaseAdmin
        .from('users')
        .update(updateData as any)
        .eq('id', user.id)
    }

    return NextResponse.json({
      success: true,
      message: 'Profile updated',
      redirect: dashboardPath(user.roleLabel, user.roles),
    })
  } catch {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
