import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '../../../../supabase/types/database.types'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL || "http://localhost",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "dummy"
  )
}
