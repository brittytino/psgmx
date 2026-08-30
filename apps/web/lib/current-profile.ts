import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

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

  return null
}
