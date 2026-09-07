import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

function normalizeProfile(p: any) {
  if (!p) return null
  const role_label = p.role_label || p.roleLabel || p.role || 'Student'
  const roleLabel = p.roleLabel || p.role_label || p.role || 'Student'
  const role = roleLabel
  const roles = p.roles || {
    isStudent: roleLabel.toLowerCase() === 'student',
    isTeamLeader: false,
    isCoordinator: false,
    isPlacementRep: false,
  }
  return {
    ...p,
    id: p.id,
    name: p.name || p.fullName || 'Student',
    role_label,
    roleLabel,
    role,
    roles,
  }
}

export async function getCurrentProfile(client?: SupabaseClient<Database>) {
  let profileRaw: any = null

  // 1. Try fetching from server-side profile API
  if (typeof window !== 'undefined') {
    try {
      const res = await fetch('/api/user/profile')
      if (res.ok) {
        const json = await res.json()
        if (json.success && json.profile) {
          profileRaw = json.profile
        }
      }
    } catch {}
  }

  // 2. Try Supabase client if provided and profile not yet obtained
  if (!profileRaw && client) {
    try {
      const { data: { user } } = await client.auth.getUser()
      if (user && user.id) {
        const { data: profile } = await client
          .from('users')
          .select('*')
          .eq('id', user.id)
          .maybeSingle()
        if (profile) profileRaw = profile
      }
    } catch {}

    if (!profileRaw) {
      try {
        const { data } = await client.rpc('get_my_profile')
        if (data) {
          profileRaw = Array.isArray(data) ? data[0] ?? null : data
        }
      } catch {}
    }
  }

  return normalizeProfile(profileRaw)
}

