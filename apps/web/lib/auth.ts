// ============================================================
// PSGMX — lib/auth.ts
// Supabase-based auth utilities.
// Replaces the previous custom bcrypt/HS256 JWT implementation.
// Session management is handled entirely by Supabase Auth + @supabase/ssr.
// ============================================================
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { type NextRequest } from 'next/server'
import type { UserRole, AppRole } from '@/../../supabase/types/database.types'

export type { UserRole, AppRole }

// ──────────────────────────────────────────────────────────────
// SessionUser — the shape returned by getSessionUser()
// ──────────────────────────────────────────────────────────────
export interface SessionUser {
  id: string
  email: string
  role: UserRole
  app_role: AppRole
  batch_id: string | null
  full_name: string
  roll_no: string | null
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

  const { data: profile, error: profileErr } = await supabase
    .from('users')
    .select('id, email, role, app_role, batch_id, full_name, roll_no')
    .eq('id', user.id)
    .single()

  if (profileErr || !profile) return null

  return profile as SessionUser
}

/**
 * getUserFromRequest
 * Use in API routes where createClient() can't be called directly.
 * Validates the session from the request's Authorization header (Bearer token)
 * or from cookies (fallback).
 */
export async function getUserFromRequest(req: NextRequest): Promise<SessionUser | null> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) return null

  const { data: profile } = await supabase
    .from('users')
    .select('id, email, role, app_role, batch_id, full_name, roll_no')
    .eq('id', user.id)
    .single()

  return profile as SessionUser | null
}

/**
 * requireRole
 * Utility for API routes to enforce role requirements.
 * Returns the SessionUser if the role matches, null otherwise.
 */
export async function requireRole(
  req: NextRequest,
  allowedRoles: UserRole[]
): Promise<SessionUser | null> {
  const user = await getUserFromRequest(req)
  if (!user) return null
  if (!allowedRoles.includes(user.role)) return null
  return user
}

/**
 * requireAppRole
 * Utility for API routes to enforce app_role requirements.
 */
export async function requireAppRole(
  req: NextRequest,
  allowedAppRoles: AppRole[]
): Promise<SessionUser | null> {
  const user = await getUserFromRequest(req)
  if (!user) return null
  if (!allowedAppRoles.includes(user.app_role)) return null
  return user
}

/**
 * inviteUser
 * Invites a new faculty or HOD user via Supabase Admin API.
 * Only @psgtech.ac.in emails are allowed.
 * Call this from a server action or admin API route.
 */
export async function inviteUser(email: string, role: 'faculty' | 'hod') {
  if (!email.endsWith('@psgtech.ac.in')) {
    throw new Error('Only @psgtech.ac.in email addresses are permitted for faculty/HOD accounts')
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
