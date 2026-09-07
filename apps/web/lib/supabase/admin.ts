import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
if (!supabaseUrl) {
  throw new Error('NEXT_PUBLIC_SUPABASE_URL must be set.')
}
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim()

export const supabaseAdmin = createClient<Database>(
  supabaseUrl,
  serviceRoleKey || 'service-role-key-not-configured',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
)
