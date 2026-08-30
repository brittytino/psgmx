import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { type NextRequest } from 'next/server'

export interface UserRoles {
  isStudent?: boolean
  isTeamLeader?: boolean
  isCoordinator?: boolean
  isPlacementRep?: boolean
  isFaculty?: boolean
}

export interface SessionUser {
  id: string
  email: string
  roleLabel: string
  roles: UserRoles
  batch_id: string | null
  name: string
  reg_no: string | null
}

type ProfileRow = {
  id: string
  email: string
  role_label: string
  roles: UserRoles | null
  batch_id: string | null
  name: string
  reg_no: string | null
}

function sessionUser(profile: ProfileRow): SessionUser {
  return {
    id: profile.id,
    email: profile.email,
    roleLabel: profile.role_label,
    roles: profile.roles || {},
    batch_id: profile.batch_id,
    name: profile.name,
    reg_no: profile.reg_no,
  }
}

async function profileForAuthId(authUserId: string): Promise<SessionUser | null> {
  const { data: identity } = await supabaseAdmin
    .from('user_auth_identities')
    .select('user_id')
    .eq('auth_user_id', authUserId)
    .maybeSingle()

  const logicalId = identity?.user_id || authUserId
  const { data: profile } = await supabaseAdmin
    .from('users')
    .select('id, email, role_label, roles, batch_id, name, reg_no')
    .eq('id', logicalId)
    .maybeSingle()

  return profile ? sessionUser(profile as unknown as ProfileRow) : null
}

export async function getSessionUser(): Promise<SessionUser | null> {
  const supabase = await createClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null

  const { data: rows } = await supabase.rpc('get_my_profile')
  const profile = Array.isArray(rows) ? rows[0] : rows
  if (profile) return sessionUser(profile as unknown as ProfileRow)
  return profileForAuthId(user.id)
}

export async function getUserFromRequest(req: NextRequest): Promise<SessionUser | null> {
  const bearer = req.headers.get('authorization')?.match(/^Bearer\s+(.+)$/i)?.[1]
  if (bearer) {
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(bearer)
    if (!error && user) return profileForAuthId(user.id)
    return null
  }
  return getSessionUser()
}

export async function requireRole(
  reqOrUser: NextRequest | SessionUser | null,
  allowedRoles: string | string[],
): Promise<SessionUser | null> {
  const user = reqOrUser && 'headers' in reqOrUser
    ? await getUserFromRequest(reqOrUser as NextRequest)
    : reqOrUser as SessionUser | null
  if (!user) return null
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles]
  return roles.some((role) => role.toLowerCase() === user.roleLabel.toLowerCase()) ? user : null
}

export async function requireAppRole(
  reqOrUser: NextRequest | SessionUser | null,
  allowedRoles: string | string[],
): Promise<SessionUser | null> {
  const user = reqOrUser && 'headers' in reqOrUser
    ? await getUserFromRequest(reqOrUser as NextRequest)
    : reqOrUser as SessionUser | null
  if (!user) return null
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles]
  const match = roles.some((role) => {
    const value = role.toLowerCase()
    if (value === 'placement_rep' || value === 'placementrep') return user.roles.isPlacementRep === true
    if (value === 'coordinator') return user.roles.isCoordinator === true
    if (value === 'team_leader' || value === 'teamleader') return user.roles.isTeamLeader === true
    if (value === 'student') return user.roleLabel.toLowerCase() === 'student' && user.roles.isStudent === true
    return user.roleLabel.toLowerCase() === value
  })
  return match ? user : null
}

export async function isAdminUser(reqOrUser: NextRequest | SessionUser | null): Promise<boolean> {
  const user = reqOrUser && 'headers' in reqOrUser
    ? await getUserFromRequest(reqOrUser as NextRequest)
    : reqOrUser as SessionUser | null
  if (!user) return false
  return user.roles.isPlacementRep === true
}

export function isStudent(user: SessionUser | null): boolean {
  return Boolean(user && user.roleLabel.toLowerCase() === 'student' && user.roles.isStudent === true)
}

export function isFaculty(user: SessionUser | null): boolean {
  return user?.roleLabel.toLowerCase() === 'faculty'
}

export function isHOD(user: SessionUser | null): boolean {
  return user?.roleLabel.toLowerCase() === 'hod'
}

export function isAlumni(user: SessionUser | null): boolean {
  return user?.roleLabel.toLowerCase() === 'alumni'
}
