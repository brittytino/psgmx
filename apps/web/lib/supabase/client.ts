import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '../../../../supabase/types/database.types'

const DEFAULT_SUPABASE_URL = 'https://ucmskbgdpnolnyrmkotz.supabase.co'
const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_FYSPL2NrQ7uby010u8hTmg_26v9e2MI'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL || DEFAULT_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || DEFAULT_SUPABASE_ANON_KEY
  )
}
