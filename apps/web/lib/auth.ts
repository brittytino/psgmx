// ============================================================
// PSGMX — lib/auth.ts
// Supabase-based auth utilities with resilient session resolution.
// ============================================================
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { type NextRequest } from 'next/server'
import { cookies } from 'next/headers'

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

/**
 * getSessionUser
 * Reads the current session from Supabase SSR and psgmx_session cookies.
 */
export async function getSessionUser(): Promise<SessionUser | null> {
  const cookieStore = await cookies()
  const psgmxCookie = cookieStore.get('psgmx_session')?.value
  if (psgmxCookie) {
    try {
      const parsed = JSON.parse(decodeURIComponent(psgmxCookie))
      if (parsed?.id && parsed?.email) {
        return {
          id: parsed.id,
          email: parsed.email,
          roleLabel: parsed.role_label || 'Student',
          roles: parsed.roles || { isStudent: true },
          batch_id: parsed.batch_id || null,
          name: parsed.name || 'Student',
          reg_no: parsed.reg_no || null,
        }
      }
    } catch {}
  }

  const supabase = await createClient()
  const { data: { user }, error: authErr } = await supabase.auth.getUser()

  if (authErr || !user) {
    return null
  }

  // Fetch user profile from public.users
  const { data: profile } = await supabaseAdmin
    .from('users')
    .select('id, email, role_label, roles, batch_id, name, reg_no')
    .eq('id', user.id)
    .maybeSingle()

  if (profile) {
    return { ...profile, roleLabel: profile.role_label } as unknown as SessionUser
  }

  return {
    id: user.id,
    email: user.email || '',
    roleLabel: 'Student',
    roles: { isStudent: true },
    batch_id: null,
    name: user.email?.split('@')[0] || 'Student',
    reg_no: null,
  }
}

/**
 * getUserFromRequest
 * Use in API routes to authenticate via Bearer token, Supabase Auth, or psgmx_session cookie.
 */
export async function getUserFromRequest(req: NextRequest): Promise<SessionUser | null> {
  // 1. Check Authorization Bearer header
  const bearer = req.headers.get('authorization')?.match(/^Bearer\s+(.+)$/i)?.[1]
  if (bearer) {
    try {
      const { data: { user }, error } = await supabaseAdmin.auth.getUser(bearer)
      if (!error && user) {
        const { data: profile } = await supabaseAdmin
          .from('users')
          .select('id, email, role_label, roles, batch_id, name, reg_no')
          .eq('id', user.id)
          .maybeSingle()

        if (profile) {
          return { ...profile, roleLabel: profile.role_label } as unknown as SessionUser
        }

        return {
          id: user.id,
          email: user.email || '',
          roleLabel: 'Student',
          roles: { isStudent: true },
          batch_id: null,
          name: user.email?.split('@')[0] || 'Student',
          reg_no: null,
        }
      }
    } catch {}
  }

  // 2. Check psgmx_session cookie from request
  const psgmxCookie = req.cookies.get('psgmx_session')?.value
  if (psgmxCookie) {
    try {
      const parsed = JSON.parse(decodeURIComponent(psgmxCookie))
      if (parsed?.id && parsed?.email) {
        return {
          id: parsed.id,
          email: parsed.email,
          roleLabel: parsed.role_label || 'Student',
          roles: parsed.roles || { isStudent: true },
          batch_id: parsed.batch_id || null,
          name: parsed.name || 'Student',
          reg_no: parsed.reg_no || null,
        }
      }
    } catch {}
  }

  // 3. Check Supabase SSR session
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (user) {
      const { data: profile } = await supabaseAdmin
        .from('users')
        .select('id, email, role_label, roles, batch_id, name, reg_no')
        .eq('id', user.id)
        .maybeSingle()

      if (profile) {
        return { ...profile, roleLabel: profile.role_label } as unknown as SessionUser
      }

      return {
        id: user.id,
        email: user.email || '',
        roleLabel: 'Student',
        roles: { isStudent: true },
        batch_id: null,
        name: user.email?.split('@')[0] || 'Student',
        reg_no: null,
      }
    }
  } catch {}

  return null
}

export async function requireRole(
  reqOrUser: NextRequest | SessionUser | null,
  allowedRoles: string | string[]
): Promise<SessionUser | null> {
  const user = reqOrUser && 'headers' in reqOrUser 
    ? await getUserFromRequest(reqOrUser as NextRequest)
    : reqOrUser as SessionUser | null

  if (!user) return null
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles]
  const match = roles.some((r) => r.toLowerCase() === user.roleLabel.toLowerCase())
  return match ? user : null
}

export async function requireAppRole(
  reqOrUser: NextRequest | SessionUser | null,
  allowedRoles: string | string[]
): Promise<SessionUser | null> {
  const user = reqOrUser && 'headers' in reqOrUser 
    ? await getUserFromRequest(reqOrUser as NextRequest)
    : reqOrUser as SessionUser | null

  if (!user) return null
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles]
  const isMatch = roles.some((r) => {
    const lower = r.toLowerCase()
    if (lower === 'placement_rep' || lower === 'placementrep') return user.roles?.isPlacementRep === true
    if (lower === 'coordinator') return user.roles?.isCoordinator === true
    if (lower === 'team_leader' || lower === 'teamleader') return user.roles?.isTeamLeader === true
    if (lower === 'student') return user.roles?.isStudent === true
    return user.roleLabel.toLowerCase() === lower
  })
  return isMatch ? user : null
}

export async function isAdminUser(reqOrUser: NextRequest | SessionUser | null): Promise<boolean> {
  const user = reqOrUser && 'headers' in reqOrUser 
    ? await getUserFromRequest(reqOrUser as NextRequest)
    : reqOrUser as SessionUser | null

  if (!user) return false
  const role = user.roleLabel.toLowerCase()
  return role === 'hod' || role === 'faculty' || user.roles?.isPlacementRep === true
}

export function isStudent(user: SessionUser | null): boolean {
  if (!user) return false
  return user.roleLabel.toLowerCase() === 'student'
}

export function isFaculty(user: SessionUser | null): boolean {
  if (!user) return false
  return user.roleLabel.toLowerCase() === 'faculty'
}

export function isHOD(user: SessionUser | null): boolean {
  if (!user) return false
  return user.roleLabel.toLowerCase() === 'hod'
}

export function isAlumni(user: SessionUser | null): boolean {
  if (!user) return false
  return user.roleLabel.toLowerCase() === 'alumni'
}
