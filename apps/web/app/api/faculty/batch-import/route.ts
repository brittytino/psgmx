// ============================================================
// GET/POST /api/faculty/batch-import
// Faculty batch-imports student user accounts.
// Migrated to Supabase.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { requireAppRole } from '@/lib/auth'
import { collegeEmailForRegisterNumber, normalizeRosterStudent } from '@/lib/auth-input'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(req: NextRequest) {
  try {
    const faculty = await requireRole(req, ['faculty', 'hod'])
      ?? await requireAppRole(req, ['placement_rep'])
    if (!faculty) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { students, batch_id } = body as {
      students: Array<Record<string, unknown>>
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

    if (faculty.roles?.isPlacementRep && faculty.batch_id !== batch_id) {
      return NextResponse.json({ error: 'Placement Reps can import only their own batch.' }, { status: 403 })
    }

    const results: Array<{ reg_no: string; status: string; error?: string }> = []

    for (const rawStudent of students) {
      const student = normalizeRosterStudent(rawStudent)
      if (!student) {
        const rawRegNo = typeof rawStudent?.reg_no === 'string' ? rawStudent.reg_no : 'unknown'
        results.push({ reg_no: rawRegNo, status: 'skipped', error: 'Name and register number are required' })
        continue
      }

      const {
        name,
        reg_no,
        personal_email,
        college_email,
        alternate_personal_emails,
        section,
        team_code,
        gender,
      } = student

      try {
        const { data: existingRoster } = await supabaseAdmin
          .from('whitelist')
          .select('email,personal_email,college_email,batch,team_id,gender')
          .eq('reg_no', reg_no)
          .maybeSingle()
        // Keep the canonical roster key stable when a college email is added
        // later; both addresses are synchronized into the alias table.
        const email = existingRoster?.email
          ?? personal_email
          ?? college_email
          ?? `pending+${reg_no.toLowerCase()}@roster.psgmx.invalid`
        const effectivePersonalEmail = personal_email ?? existingRoster?.personal_email ?? null
        const generatedCollegeEmail = collegeEmailForRegisterNumber(reg_no)
        const effectiveCollegeEmail = college_email
          ?? existingRoster?.college_email
          ?? generatedCollegeEmail
          ?? null
        const incomingIdentities = [...new Set([
          effectivePersonalEmail,
          effectiveCollegeEmail,
          ...(alternate_personal_emails ?? []),
        ].filter((identity): identity is string => Boolean(identity)))]

        if (incomingIdentities.length) {
          const { data: aliasOwners } = await supabaseAdmin
            .from('whitelist_email_aliases')
            .select('email,whitelist_email')
            .in('email', incomingIdentities)
          const conflict = aliasOwners?.some((alias) => alias.whitelist_email !== email)
          if (conflict) {
            results.push({ reg_no, status: 'failed', error: 'An email identity already belongs to another roster row' })
            continue
          }
        }
        // Roster-only provisioning: the first OTP creates auth safely through
        // the database trigger. This avoids dead accounts and duplicate users.
        const { error: insertErr } = await supabaseAdmin.from('whitelist').upsert({
          email,
          personal_email: effectivePersonalEmail,
          college_email: effectiveCollegeEmail,
          name,
          reg_no,
          batch_id,
          batch: section ?? (body as { batch?: string }).batch ?? existingRoster?.batch ?? 'G1',
          team_id: team_code ?? existingRoster?.team_id ?? null,
          gender: gender ?? existingRoster?.gender ?? null,
          roles: { isStudent: true, isTeamLeader: false, isCoordinator: false, isPlacementRep: false },
        }, { onConflict: 'reg_no' })

        if (insertErr) {
          results.push({ reg_no, status: 'failed', error: insertErr.message })
          continue
        }

        if (alternate_personal_emails?.length) {
          const { error: aliasError } = await supabaseAdmin
            .from('whitelist_email_aliases')
            .upsert(
              alternate_personal_emails.map((alias) => ({
                email: alias,
                whitelist_email: email,
                email_type: 'personal',
              })),
              { onConflict: 'email' },
            )
          if (aliasError) {
            results.push({ reg_no, status: 'failed', error: aliasError.message })
            continue
          }
        }

        results.push({
          reg_no,
          status: effectivePersonalEmail || effectiveCollegeEmail ? 'rostered' : 'pending_email',
        })

      } catch (err) {
        results.push({ reg_no, status: 'failed', error: String(err) })
      }
    }

    const readyForOtp = results.filter(r => r.status === 'rostered').length
    const pendingEmail = results.filter(r => r.status === 'pending_email').length
    const created = readyForOtp + pendingEmail
    const failed = results.filter(r => r.status === 'failed').length

    await supabaseAdmin.from('audit_logs').insert({
      actor_id: faculty.id,
      action: 'BATCH_ROSTER_IMPORTED',
      entity_type: 'whitelist',
      batch_id,
      metadata: {
        batch_id,
        batch_code: (batch as { batch_code: string }).batch_code,
        total: students.length,
        created,
        ready_for_otp: readyForOtp,
        pending_email: pendingEmail,
        failed,
      },
    })

    return NextResponse.json({ success: true, created, readyForOtp, pendingEmail, failed, results })
  } catch (error) {
    console.error('Batch import error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
