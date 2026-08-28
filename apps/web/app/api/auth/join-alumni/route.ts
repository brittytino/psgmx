import { NextRequest, NextResponse } from 'next/server'
import { normalizeEmail, normalizeRegisterNumber } from '@/lib/auth-input'
import { supabaseAdmin } from '@/lib/supabase/admin'

const ALUMNI_ROLES = {
  isStudent: false,
  isTeamLeader: false,
  isCoordinator: false,
  isPlacementRep: false,
}

function cleanName(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const name = value.replace(/\s+/g, ' ').trim()
  return name.length >= 2 && name.length <= 100 ? name : null
}

function cleanLinkedIn(value: unknown): string | null {
  if (value === undefined || value === null || value === '') return null
  if (typeof value !== 'string') return null
  try {
    const url = new URL(value.trim())
    if (url.protocol !== 'https:' || !/(^|\.)linkedin\.com$/i.test(url.hostname)) return null
    return url.toString()
  } catch {
    return null
  }
}

async function findAuthUserId(email: string): Promise<string | null> {
  for (let page = 1; page <= 20; page += 1) {
    const { data, error } = await supabaseAdmin.auth.admin.listUsers({ page, perPage: 200 })
    if (error) throw error
    const match = data.users.find((user) => user.email?.toLowerCase() === email)
    if (match) return match.id
    if (data.users.length < 200) break
  }
  return null
}

async function ensureGraduatedBatch(regNo: string) {
  const batchCode = regNo.slice(0, 4)
  const startYear = 2000 + Number(batchCode.slice(0, 2))
  const endYear = startYear + 2
  const currentYear = new Date().getFullYear()

  if (startYear < 2000 || endYear > currentYear) throw new Error('ACTIVE_BATCH')

  const { data: existing, error } = await supabaseAdmin
    .from('batches')
    .select('id, batch_code, start_year, end_year, status')
    .eq('batch_code', batchCode)
    .maybeSingle()
  if (error) throw error
  if (existing) {
    if (existing.status !== 'graduated') throw new Error('ACTIVE_BATCH')
    return existing
  }

  const { data, error: insertError } = await supabaseAdmin
    .from('batches')
    .insert({ batch_code: batchCode, start_year: startYear, end_year: endYear, status: 'graduated' })
    .select('id, batch_code, start_year, end_year, status')
    .single()
  if (insertError) throw insertError
  return data
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const name = cleanName(body.name)
    const regNo = normalizeRegisterNumber(body.regNo ?? body.token)
    const email = normalizeEmail(body.email)
    const linkedin = cleanLinkedIn(body.linkedin)

    if (!name || !regNo || !email) {
      return NextResponse.json(
        { error: 'Enter your full name, valid MCA register number, and email address.' },
        { status: 400 },
      )
    }
    if (body.linkedin && !linkedin) {
      return NextResponse.json({ error: 'Enter a valid https://linkedin.com profile URL.' }, { status: 400 })
    }

    let batch
    try {
      batch = await ensureGraduatedBatch(regNo)
    } catch (error) {
      if (error instanceof Error && error.message === 'ACTIVE_BATCH') {
        return NextResponse.json(
          { error: 'This register number belongs to a current batch. Please use Student OTP login.' },
          { status: 400 },
        )
      }
      throw error
    }

    const [{ data: existingByReg }, { data: existingByEmail }] = await Promise.all([
      supabaseAdmin
        .from('users')
        .select('id, email, personal_email, college_email, role_label')
        .eq('reg_no', regNo)
        .maybeSingle(),
      supabaseAdmin
        .from('users')
        .select('id, reg_no')
        .eq('email', email)
        .maybeSingle(),
    ])

    if (existingByEmail && existingByEmail.reg_no !== regNo) {
      return NextResponse.json({ error: 'This email is already linked to another account.' }, { status: 409 })
    }
    if (existingByReg && existingByReg.role_label !== 'Alumni') {
      return NextResponse.json({ error: 'This register number already has an active PSGMX account.' }, { status: 409 })
    }
    if (existingByReg) {
      const acceptedEmails = [existingByReg.email, existingByReg.personal_email, existingByReg.college_email]
        .filter((value): value is string => Boolean(value))
        .map((value) => value.toLowerCase())
      if (!acceptedEmails.includes(email)) {
        return NextResponse.json(
          { error: 'This register number is already linked to a different email. Contact the department to add another identity.' },
          { status: 409 },
        )
      }
    }

    let authUserId = existingByReg?.id ?? null
    if (!authUserId) {
      const created = await supabaseAdmin.auth.admin.createUser({ email, email_confirm: true })
      authUserId = created.data.user?.id ?? await findAuthUserId(email)
      if (!authUserId) throw created.error ?? new Error('Could not create the secure login identity.')
    }

    if (!existingByReg) {
      const { error } = await supabaseAdmin.from('users').insert({
        id: authUserId,
        email,
        personal_email: email.endsWith('@psgtech.ac.in') ? null : email,
        college_email: email.endsWith('@psgtech.ac.in') ? email : null,
        reg_no: regNo,
        name,
        batch: 'G1',
        batch_id: batch.id,
        role_label: 'Alumni',
        roles: ALUMNI_ROLES,
        linkedin_url: linkedin,
        onboarding_complete: true,
      })
      if (error) throw error
    } else {
      const update = {
        name,
        batch_id: batch.id,
        onboarding_complete: true,
        ...(linkedin ? { linkedin_url: linkedin } : {}),
      }
      const { error } = await supabaseAdmin.from('users').update(update).eq('id', existingByReg.id)
      if (error) throw error
    }

    const { data: roster } = await supabaseAdmin
      .from('whitelist')
      .select('email')
      .eq('reg_no', regNo)
      .maybeSingle()
    const rosterRow = {
      name,
      reg_no: regNo,
      batch: 'G1' as const,
      batch_id: batch.id,
      personal_email: email.endsWith('@psgtech.ac.in') ? null : email,
      college_email: email.endsWith('@psgtech.ac.in') ? email : null,
      role_label: 'Alumni',
      roles: ALUMNI_ROLES,
    }
    const rosterResult = roster
      ? await supabaseAdmin.from('whitelist').update(rosterRow).eq('reg_no', regNo)
      : await supabaseAdmin.from('whitelist').insert({ email, ...rosterRow })
    if (rosterResult.error) throw rosterResult.error

    return NextResponse.json({
      success: true,
      message: 'Your alumni profile is ready. We will now send a secure sign-in code.',
      batch: { code: batch.batch_code, graduationYear: batch.end_year },
    }, { status: existingByReg ? 200 : 201 })
  } catch (error) {
    console.error('[POST /api/auth/join-alumni]', error)
    return NextResponse.json({ error: 'We could not prepare this alumni account. Please try again.' }, { status: 500 })
  }
}
