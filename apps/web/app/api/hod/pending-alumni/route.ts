// ============================================================
// GET /api/hod/pending-alumni
// Lists users pending alumni approval (role='student', pending review).
// Migrated: Previously used MongoDB UserAccount with status='pending'.
// Now uses Supabase users table.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const hod = await requireRole(req, ['hod'])
    if (!hod) {
      return NextResponse.json({ error: 'Unauthorized — HOD only' }, { status: 401 })
    }

    // Users with role='student' but whose onboarding_complete=false and linkedin_url is set
    // indicates an alumni self-registration pending approval.
    // TODO: Add a dedicated `pending_alumni_approval` boolean column if this grows complex.
    const { data: pendingAlumni, error } = await supabaseAdmin
      .from('users')
      .select('id, email, full_name, roll_no, batch_id, linkedin_url, created_at')
      .eq('role', 'student')
      .eq('onboarding_complete', false)
      .not('linkedin_url', 'is', null)
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
    const hod = await requireRole(req, ['hod'])
    if (!hod) {
      return NextResponse.json({ error: 'Unauthorized — HOD only' }, { status: 401 })
    }

    const { userId, action } = await req.json()
    if (!userId || !['approve', 'reject'].includes(action)) {
      return NextResponse.json({ error: 'userId and action (approve|reject) are required' }, { status: 400 })
    }

    if (action === 'approve') {
      const { error } = await supabaseAdmin
        .from('users')
        .update({ role: 'alumni', onboarding_complete: true })
        .eq('id', userId)

      if (error) throw error

      await supabaseAdmin.from('audit_logs').insert({
        actor_id: hod.id,
        action: 'alumni_approved',
        target_table: 'users',
        target_id: userId,
      })
    } else {
      // Reject: delete the auth user and profile
      await supabaseAdmin.auth.admin.deleteUser(userId)
      await supabaseAdmin.from('audit_logs').insert({
        actor_id: hod.id,
        action: 'alumni_rejected',
        target_table: 'users',
        target_id: userId,
      })
    }

    return NextResponse.json({ success: true, message: `Alumni ${action}d.` })
  } catch (error) {
    console.error('HOD alumni action error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
