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
      students: Array<{ email: string; full_name: string; roll_no: string }>
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

    const results: Array<{ roll_no: string; status: string; error?: string }> = []

    for (const student of students) {
      const { email, full_name, roll_no } = student

      if (!email || !full_name || !roll_no) {
        results.push({ roll_no: roll_no ?? 'unknown', status: 'skipped', error: 'Missing required fields' })
        continue
      }

      try {
        // Create Supabase Auth user (OTP-based, no password set by admin)
        const { data: authUser, error: authErr } = await supabaseAdmin.auth.admin.createUser({
          email: email.toLowerCase().trim(),
          email_confirm: false,
          user_metadata: { full_name, roll_no: roll_no.trim().toUpperCase() },
        })

        if (authErr || !authUser.user) {
          results.push({ roll_no, status: 'failed', error: authErr?.message ?? 'Auth creation failed' })
          continue
        }

        // Insert profile
        const { error: insertErr } = await supabaseAdmin.from('users')// @ts-ignore
      .insert({
          id: authUser.user.id,
          email: email.toLowerCase().trim(),
          full_name,
          roll_no: roll_no.trim().toUpperCase(),
          batch_id,
          role: 'student',
          app_role: 'student',
          onboarding_complete: false,
        } as any)

        if (insertErr) {
          // Clean up auth user if profile insert failed
          await supabaseAdmin.auth.admin.deleteUser(authUser.user.id).catch(() => {})
          results.push({ roll_no, status: 'failed', error: insertErr.message })
          continue
        }

        results.push({ roll_no, status: 'created' })

      } catch (err) {
        results.push({ roll_no, status: 'failed', error: String(err) })
      }
    }

    const created = results.filter(r => r.status === 'created').length
    const failed = results.filter(r => r.status === 'failed').length

    await supabaseAdmin.from('audit_logs')// @ts-ignore
      .insert({
      actor_id: faculty.id,
      action: 'batch_import',
      target_table: 'users',
      metadata: { batch_id, batch_code: (batch as any).batch_code, total: students.length, created, failed },
    } as any)

    return NextResponse.json({ success: true, created, failed, results })
  } catch (error) {
    console.error('Batch import error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
