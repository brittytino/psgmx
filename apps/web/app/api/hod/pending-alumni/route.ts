// ============================================================
// GET /api/hod/pending-alumni
// Lists users pending alumni approval (role='student', pending review).
// Migrated to Supabase.
// Now uses Supabase users table.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const actor = await requireRole(req, ['faculty', 'hod'])
    if (!actor) {
      return NextResponse.json({ error: 'Unauthorized — Faculty access required' }, { status: 401 })
    }

    // Users with role_label='Student' whose onboarding isn't complete indicate
    // a pending self-registration. (linkedin_url doesn't exist on the live
    // `users` table, so that earlier signal is dropped — see plan Section
    // 12 discussion of columns that don't exist.)
    const { data: pendingAlumni, error } = await supabaseAdmin
      .from('users')
      .select('id, email, name, reg_no, batch_id, created_at')
      .eq('role_label', 'Student')
      .eq('onboarding_complete', false)
      .order('created_at', { ascending: true })

    if (error) throw error

    return NextResponse.json({ success: true, pendingAlumni })
  } catch (error) {
    console.error('HOD pending alumni error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  try {
    const actor = await requireRole(req, ['faculty', 'hod'])
    if (!actor) {
      return NextResponse.json({ error: 'Unauthorized — Faculty access required' }, { status: 401 })
    }

    const { userId, action } = await req.json()
    if (!userId || !['approve', 'reject'].includes(action)) {
      return NextResponse.json({ error: 'userId and action (approve|reject) are required' }, { status: 400 })
    }

    if (action === 'approve') {
      const { error } = await supabaseAdmin
        .from('users')
        .update({ role_label: 'Alumni', onboarding_complete: true })
        .eq('id', userId)

      if (error) throw error

      await supabaseAdmin.from('audit_logs').insert({
        actor_id: actor.id,
        action: 'alumni_approved',
        entity_type: 'users',
        entity_id: userId,
      })
    } else {
      // Reject: delete the auth user and profile
      await supabaseAdmin.auth.admin.deleteUser(userId)
      await supabaseAdmin.from('audit_logs').insert({
        actor_id: actor.id,
        action: 'alumni_rejected',
        entity_type: 'users',
        entity_id: userId,
      })
    }

    return NextResponse.json({ success: true, message: `Alumni ${action}d.` })
  } catch (error) {
    console.error('HOD alumni action error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
