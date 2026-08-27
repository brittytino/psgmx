import { STAFF_ROSTER, type StaffMember } from '@/lib/staff-auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

const STAFF_ROLES = {
  isStudent: false,
  isTeamLeader: false,
  isCoordinator: false,
  isPlacementRep: false,
}

async function findAuthUserId(email: string): Promise<string | null> {
  let page = 1
  while (page <= 20) {
    const { data, error } = await supabaseAdmin.auth.admin.listUsers({ page, perPage: 200 })
    if (error) throw error
    const match = data.users.find((user) => user.email?.toLowerCase() === email)
    if (match) return match.id
    if (data.users.length < 200) return null
    page += 1
  }
  return null
}

export async function provisionStaffAccount(member: StaffMember) {
  const baseRow = {
    email: member.email,
    college_email: member.email,
    name: member.name,
    reg_no: member.regNo,
    batch: 'G1' as const,
    roles: STAFF_ROLES,
  }

  let { error: whitelistError } = await supabaseAdmin.from('whitelist').upsert(
    { ...baseRow, role_label: member.role },
    { onConflict: 'email' },
  )
  if (whitelistError && /role_label/i.test(whitelistError.message)) {
    const fallback = await supabaseAdmin.from('whitelist').upsert(baseRow, { onConflict: 'email' })
    whitelistError = fallback.error
  }
  if (whitelistError) throw whitelistError

  const created = await supabaseAdmin.auth.admin.createUser({
    email: member.email,
    email_confirm: true,
  })

  const { data: existing } = await supabaseAdmin
    .from('users')
    .select('id')
    .eq('email', member.email)
    .maybeSingle()

  const userId = existing?.id ?? created.data.user?.id ?? await findAuthUserId(member.email)
  if (!userId) {
    throw created.error ?? new Error(`Could not provision auth user for ${member.email}`)
  }

  if (existing) {
    const { error } = await supabaseAdmin.from('users').update({
      name: member.name,
      college_email: member.email,
      role_label: member.role,
      roles: STAFF_ROLES,
      onboarding_complete: true,
    }).eq('id', existing.id)
    if (error) throw error
    return
  }

  const { error } = await supabaseAdmin.from('users').insert({
    id: userId,
    email: member.email,
    college_email: member.email,
    name: member.name,
    reg_no: member.regNo,
    batch: 'G1',
    role_label: member.role,
    roles: STAFF_ROLES,
    onboarding_complete: true,
  })
  if (error) throw error
}

export async function provisionStaffByEmail(email: string) {
  const member = STAFF_ROSTER.find((row) => row.email === email)
  if (!member) return
  await provisionStaffAccount(member)
}
