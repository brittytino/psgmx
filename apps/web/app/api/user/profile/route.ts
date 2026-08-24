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
        'birthday_notifications_enabled, leetcode_notifications_enabled, ' +
        'task_reminders_enabled, attendance_alerts_enabled, ' +
        'announcements_enabled, created_at, updated_at')
      .eq('id', user.id)
      .single()

    if (error) {
      console.error('Profile fetch error:', error)
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    return NextResponse.json({ success: true, profile })
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
    const { name, linkedin_url, avatar_url, current_company, current_role_title, mentorship_open } = body

    const updateData: { name?: string } = {}
    if (name !== undefined) updateData.name = name
    // (Other fields can be added if you alter the table to add them later)

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json({ error: 'No fields to update' }, { status: 400 })
    }

    const { error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', user.id)

    if (error) throw error

    return NextResponse.json({ success: true, message: 'Profile updated' })
  } catch {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
