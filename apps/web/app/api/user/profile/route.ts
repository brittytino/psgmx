// ============================================================
// GET/PUT /api/user/profile
// Migrated from MongoDB UserAccount to Supabase users table.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

export async function GET(req: NextRequest) {
  try {
    const auth = await getUserFromRequest(req)
    if (!auth || !auth.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const supabase = await createClient()

    const { data: profile, error } = await supabase
      .from('users')
      .select(
        'id, email, full_name, roll_no, role, app_role, batch_id, avatar_url, linkedin_url, current_company, current_role_title, mentorship_open, onboarding_complete, created_at'
      )
      .eq('id', auth.id)
      .single()

    if (error) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    return NextResponse.json({ success: true, profile })
  } catch {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  try {
    const auth = await getUserFromRequest(req)
    if (!auth || !auth.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { full_name, linkedin_url, avatar_url, current_company, current_role_title, mentorship_open } = body

    const updateData: Record<string, unknown> = {}
    if (full_name !== undefined) updateData.full_name = full_name
    if (linkedin_url !== undefined) updateData.linkedin_url = linkedin_url
    if (avatar_url !== undefined) updateData.avatar_url = avatar_url
    if (current_company !== undefined) updateData.current_company = current_company
    if (current_role_title !== undefined) updateData.current_role_title = current_role_title
    // Only alumni can update mentorship_open
    if (mentorship_open !== undefined && auth.role === 'alumni') {
      updateData.mentorship_open = mentorship_open
    }

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json({ error: 'No fields to update' }, { status: 400 })
    }

    const supabase = await createClient()

    const { error } = await supabase
      .from('users')
      // @ts-ignore
      .update(updateData as any)
      .eq('id', auth.id)

    if (error) throw error

    return NextResponse.json({ success: true, message: 'Profile updated' })
  } catch {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
