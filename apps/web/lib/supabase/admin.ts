import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

const DEFAULT_SUPABASE_URL = 'https://ucmskbgdpnolnyrmkotz.supabase.co'
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim()

export const supabaseAdmin = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL || DEFAULT_SUPABASE_URL,
  serviceRoleKey || 'service-role-key-not-configured',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
)
