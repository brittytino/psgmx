// ============================================================
// GET/POST /api/faculty/batch-import
// Faculty batch-imports student user accounts.
// Migrated to Supabase.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(req: NextRequest) {
  try {
    const faculty = await requireRole(req, ['faculty', 'hod'])
    if (!faculty) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { students, batch_id } = body as {
      students: Array<{ email: string; name: string; reg_no: string }>
      batch_id: string
    }

    if (!students || !Array.isArray(students) || !batch_id) {
      return NextResponse.json({ error: 'students[] and batch_id are required' }, { status: 400 })
    }

    // Verify batch exists
    const { data: batch } = await supabaseAdmin
      .from('batches')
      .select('id, batch_code')
      .eq('id', batch_id)
      .single()

    if (!batch) {
      return NextResponse.json({ error: 'Batch not found' }, { status: 404 })
    }

    const results: Array<{ reg_no: string; status: string; error?: string }> = []

    for (const student of students) {
      const { email, name, reg_no } = student

      if (!email || !name || !reg_no) {
        results.push({ reg_no: reg_no ?? 'unknown', status: 'skipped', error: 'Missing required fields' })
        continue
      }

      try {
        // Create Supabase Auth user (OTP-based, no password set by admin)
        const { data: authUser, error: authErr } = await supabaseAdmin.auth.admin.createUser({
          email: email.toLowerCase().trim(),
          email_confirm: false,
          user_metadata: { name, reg_no: reg_no.trim().toUpperCase() },
        })

        if (authErr || !authUser.user) {
          results.push({ reg_no, status: 'failed', error: authErr?.message ?? 'Auth creation failed' })
          continue
        }

        // Insert profile. `batch` (legacy G1/G2 text field, still NOT NULL
        // on the live schema alongside `batch_id`) defaults to 'G1' — pass
        // an explicit `batch` in the request body to override.
        const { error: insertErr } = await supabaseAdmin.from('users').insert({
          id: authUser.user.id,
          email: email.toLowerCase().trim(),
          name,
          reg_no: reg_no.trim().toUpperCase(),
          batch_id,
          batch: (body as { batch?: string }).batch || 'G1',
          role_label: 'Student',
          roles: { isStudent: true, isTeamLeader: false, isCoordinator: false, isPlacementRep: false },
          onboarding_complete: false,
        })

        if (insertErr) {
          // Clean up auth user if profile insert failed
          await supabaseAdmin.auth.admin.deleteUser(authUser.user.id).catch(() => {})
          results.push({ reg_no, status: 'failed', error: insertErr.message })
          continue
        }

        results.push({ reg_no, status: 'created' })

      } catch (err) {
        results.push({ reg_no, status: 'failed', error: String(err) })
      }
    }

    const created = results.filter(r => r.status === 'created').length
    const failed = results.filter(r => r.status === 'failed').length

    await supabaseAdmin.from('audit_logs').insert({
      actor_id: faculty.id,
      action: 'batch_import',
      entity_type: 'users',
      metadata: { batch_id, batch_code: (batch as { batch_code: string }).batch_code, total: students.length, created, failed },
    })

    return NextResponse.json({ success: true, created, failed, results })
  } catch (error) {
    console.error('Batch import error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
