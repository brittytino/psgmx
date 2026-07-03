import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/../../supabase/types/database.types'

// ⚠️  SERVICE ROLE CLIENT — SERVER ONLY
// This client bypasses Row Level Security.
// NEVER import this in Client Components, pages, or any file that
// could be bundled for the browser.
// Use only in:
//   - API routes (app/api/**/route.ts)
//   - Server Actions
//   - Edge Functions

export const supabaseAdmin = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL || "http://localhost",
  process.env.SUPABASE_SERVICE_ROLE_KEY || "dummy",
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
)
