import { NextRequest, NextResponse } from 'next/server'
import { normalizeEmail, normalizeRegisterNumber } from '@/lib/auth-input'
import { checkRateLimit } from '@/lib/limiter'
import { supabaseAdmin } from '@/lib/supabase/admin'

function requestIp(request: NextRequest) {
  return request.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
    || request.headers.get('x-real-ip')
    || 'unknown'
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => null) as { regNo?: unknown; token?: unknown; email?: unknown } | null
    const regNo = normalizeRegisterNumber(body?.regNo ?? body?.token)
    const email = normalizeEmail(body?.email)

    if (!regNo || !email) {
      return NextResponse.json(
        { error: 'Enter your MCA register number and approved email address.' },
        { status: 400 },
      )
    }

    const rate = checkRateLimit(`join-alumni:${requestIp(request)}:${regNo}`)
    if (!rate.success) {
      return NextResponse.json({ error: 'Too many attempts. Wait one minute and try again.' }, { status: 429 })
    }

    const { data: roster, error: rosterError } = await supabaseAdmin
      .from('whitelist')
      .select('email, personal_email, college_email, reg_no, batch_id, role_label')
      .eq('reg_no', regNo)
      .maybeSingle()
    if (rosterError) throw rosterError

    // Alumni access reactivates a department roster entry; it never creates a
    // public account from user-supplied profile details.
    if (!roster?.batch_id) {
      return NextResponse.json(
        { error: 'These details do not match an approved alumni record. Contact the department for access.' },
        { status: 403 },
      )
    }

    const [{ data: batch, error: batchError }, { data: alias, error: aliasError }, { data: existingProfile, error: profileError }] = await Promise.all([
      supabaseAdmin.from('batches').select('batch_code, end_year, status').eq('id', roster.batch_id).maybeSingle(),
      supabaseAdmin.from('whitelist_email_aliases').select('whitelist_email').eq('email', email).maybeSingle(),
      supabaseAdmin.from('users').select('role_label').eq('reg_no', regNo).maybeSingle(),
    ])
    if (batchError || aliasError || profileError) throw batchError || aliasError || profileError

    const approvedEmails = [roster.email, roster.personal_email, roster.college_email]
      .filter((value): value is string => Boolean(value))
      .map((value) => value.toLowerCase())
    const matchesRoster = approvedEmails.includes(email) || alias?.whitelist_email === roster.email
    const isAlumniRecord = batch?.status === 'graduated'
      && (!existingProfile || existingProfile.role_label === 'Alumni')

    if (!matchesRoster || !isAlumniRecord) {
      return NextResponse.json(
        { error: 'These details do not match an approved alumni record. Contact the department for access.' },
        { status: 403 },
      )
    }

    return NextResponse.json({
      success: true,
      message: 'Approved alumni record found. A secure sign-in code can now be sent.',
      batch: { code: batch.batch_code, graduationYear: batch.end_year },
    })
  } catch (error) {
    console.error('[POST /api/auth/join-alumni]', error)
    return NextResponse.json({ error: 'We could not verify this alumni record. Please try again.' }, { status: 500 })
  }
}
