// ============================================================
// PSGMX — lib/auth.ts
// Supabase-based auth utilities.
// Replaces the previous custom bcrypt/HS256 JWT implementation.
// Session management is handled entirely by Supabase Auth + @supabase/ssr.
// ============================================================
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { type NextRequest } from 'next/server'

// ──────────────────────────────────────────────────────────────
// SessionUser — the shape returned by getSessionUser()
//
// CORRECTED to match the live `users` table (verified by direct schema
// introspection — see supabase/migrations/08_security_fixes_sprint0.sql
// header). There is no `role`/`app_role` enum pair live; the real role
// model is `role_label` (TEXT: 'Student' | 'Faculty' | 'Alumni' | 'HOD')
// plus a `roles` JSONB of student sub-flags (isStudent, isTeamLeader,
// isCoordinator, isPlacementRep). The previous version of this file
// selected role/app_role/full_name/roll_no, none of which exist — every
// caller of requireRole/requireAppRole/isAdminUser was silently failing
// closed (always rejecting) rather than actually checking anything.
// ──────────────────────────────────────────────────────────────
export interface UserRoles {
  isStudent?: boolean
  isTeamLeader?: boolean
  isCoordinator?: boolean
  isPlacementRep?: boolean
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
 * Reads the current Supabase session from cookies (server-side).
 * Returns null if not authenticated or if the user row is missing.
 */
export async function getSessionUser(): Promise<SessionUser | null> {
  const supabase = await createClient()

  const {
    data: { user },
    error: authErr,
  } = await supabase.auth.getUser()

  if (authErr || !user) return null

  const { data: profileRows, error: profileErr } = await supabase.rpc('get_my_profile')
  const profile = Array.isArray(profileRows) ? profileRows[0] : profileRows

  if (profileErr || !profile) return null

  return { ...profile, roleLabel: profile.role_label } as unknown as SessionUser
}

/**
 * getUserFromRequest
 * Use in API routes where createClient() can't be called directly.
 * Validates the session from the request's Authorization header (Bearer token)
 * or from cookies (fallback).
 */
export async function getUserFromRequest(req: NextRequest): Promise<SessionUser | null> {
  const bearer = req.headers.get('authorization')?.match(/^Bearer\s+(.+)$/i)?.[1]
  if (bearer) {
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(bearer)
    if (error || !user) return null
    const { data: identity } = await supabaseAdmin
      .from('user_auth_identities')
      .select('user_id')
      .eq('auth_user_id', user.id)
      .maybeSingle()
    const logicalId = identity?.user_id ?? user.id
    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('id, email, role_label, roles, batch_id, name, reg_no')
      .eq('id', logicalId)
      .maybeSingle()
    if (!profile) return null
    return { ...profile, roleLabel: profile.role_label } as unknown as SessionUser
  }

  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) return null

  const { data: profileRows } = await supabase.rpc('get_my_profile')
  const profile = Array.isArray(profileRows) ? profileRows[0] : profileRows

  if (!profile) return null

  return { ...profile, roleLabel: profile.role_label } as unknown as SessionUser
}

/**
 * requireRole
 * Utility for API routes to enforce role requirements. Matches against
 * role_label case-insensitively so existing call sites (which pass
 * lowercase strings like 'faculty', 'hod') keep working unchanged.
 * Returns the SessionUser if the role matches, null otherwise.
 */
export async function requireRole(
  req: NextRequest,
  allowedRoles: string[]
): Promise<SessionUser | null> {
  const user = await getUserFromRequest(req)
  if (!user) return null
  const normalized = allowedRoles.map((r) => r.toLowerCase())
  if (!normalized.includes(user.roleLabel.toLowerCase())) return null
  return user
}

/**
 * requireAppRole
 * Utility for API routes to enforce a student sub-role from the `roles`
 * JSONB flags (e.g. 'placement_rep' → roles.isPlacementRep, 'team_leader'
 * → roles.isTeamLeader, 'coordinator' → roles.isCoordinator).
 */
export async function requireAppRole(
  req: NextRequest,
  allowedAppRoles: string[]
): Promise<SessionUser | null> {
  const user = await getUserFromRequest(req)
  if (!user) return null
  const flagMap: Record<string, keyof UserRoles> = {
    placement_rep: 'isPlacementRep',
    team_leader: 'isTeamLeader',
    coordinator: 'isCoordinator',
    student: 'isStudent',
  }
  const matches = allowedAppRoles.some((r) => {
    const flag = flagMap[r.toLowerCase()]
    return flag ? user.roles?.[flag] === true : false
  })
  if (!matches) return null
  return user
}

/**
 * isAdminUser
 * Governance-level access (impersonation, faculty/batch management) —
 * HOD only, per plan Section 10 ("/super-admin/* folds into /faculty/*
 * under the HOD-gated section"). Previously this checked
 * roles.isPlacementRep, left over from a mid-refactor where /super-admin
 * had been repurposed as a placement-rep console — that console now
 * lives properly at /placement-rep (Section 8), so this reverts to what
 * the locked plan actually specifies.
 */
export function isAdminUser(session: SessionUser): boolean {
  return session.roleLabel.toLowerCase() === 'hod'
}

/**
 * isFacultyOrHod
 * Convenience check used for the HOD/Faculty consolidation (plan Section
 * 10) — HOD is just role_label = 'HOD', gated as extra nav inside
 * /faculty/*, not a separate portal.
 */
export function isFacultyOrHod(session: SessionUser): boolean {
  const label = session.roleLabel.toLowerCase()
  return label === 'faculty' || label === 'hod'
}

export function isHod(session: SessionUser): boolean {
  return session.roleLabel.toLowerCase() === 'hod'
}

/**
 * inviteUser
 * Invites a new faculty user via Supabase Admin API.
 * Only @psgtech.ac.in emails are allowed.
 * Call this from a server action or admin API route.
 */
export async function inviteUser(email: string, role: 'faculty') {
  if (!email.endsWith('@psgtech.ac.in')) {
    throw new Error('Only @psgtech.ac.in email addresses are permitted for faculty accounts')
  }

  const { data, error } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
    data: { role },
    redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/onboarding/accept-invite`,
  })

  if (error) throw error
  return data
}

/**
 * isValidOrigin
 * Validates that the request origin matches the expected domains.
 * Use in API routes to prevent CSRF.
 */
export function isValidOrigin(request: NextRequest): boolean {
  const origin = request.headers.get('origin')
  const referer = request.headers.get('referer')
  const host = request.headers.get('host')

  const checkUrl = (url: string | null) => {
    if (!url) return false
    try {
      const urlObj = new URL(url)
      return urlObj.host === host
    } catch {
      return false
    }
  }

  if (origin) return checkUrl(origin)
  if (referer) return checkUrl(referer)
  return false
}
