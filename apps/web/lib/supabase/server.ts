import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '../../../../supabase/types/database.types'

const DEFAULT_SUPABASE_URL = 'https://ucmskbgdpnolnyrmkotz.supabase.co'
const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_FYSPL2NrQ7uby010u8hTmg_26v9e2MI'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL || DEFAULT_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || DEFAULT_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // setAll called from a Server Component — cookies cannot be set.
            // This is safe to ignore; the middleware will refresh the session.
          }
        },
      },
    }
  )
}
