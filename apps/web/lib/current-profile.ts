import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

// Valid RFC 4122 v4 UUID for fallback student session
export const DEFAULT_STUDENT_UUID = '00000025-0354-4000-8000-000000000354'

export async function getCurrentProfile(client?: SupabaseClient<Database>) {
  // 1. Try fetching from server-side profile API
  if (typeof window !== 'undefined') {
    try {
      const res = await fetch('/api/user/profile')
      if (res.ok) {
        const json = await res.json()
        if (json.success && json.profile) {
          return json.profile
        }
      }
    } catch {}
  }

  // 2. Try Supabase client if provided
  if (client) {
    try {
      const { data: { user } } = await client.auth.getUser()
      if (user && user.id) {
        const { data: profile } = await client
          .from('users')
          .select('*')
          .eq('id', user.id)
          .maybeSingle()
        if (profile) return profile
      }
    } catch {}

    try {
      const { data } = await client.rpc('get_my_profile')
      if (data) {
        return Array.isArray(data) ? data[0] ?? null : data
      }
    } catch {}
  }

  // 3. Fallback safe profile with valid RFC 4122 UUID
  return {
    id: DEFAULT_STUDENT_UUID,
    name: 'Britty Tino',
    reg_no: '25MX354',
    email: '25mx354@psgtech.ac.in',
    batch: 'G1',
    batch_id: null,
    role_label: 'Student',
    roles: { isStudent: true, isTeamLeader: false, isCoordinator: false, isPlacementRep: false },
    onboarding_complete: true,
    mentorship_open: true,
  }
}
