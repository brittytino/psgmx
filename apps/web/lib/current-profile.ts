import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

export async function getCurrentProfile(client: SupabaseClient<Database>) {
  const { data, error } = await client.rpc('get_my_profile')
  if (error) throw error
  return Array.isArray(data) ? data[0] ?? null : data
}
