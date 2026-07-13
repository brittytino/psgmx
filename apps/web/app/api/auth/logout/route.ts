// ============================================================
// POST /api/auth/logout
// Signs the user out of Supabase Auth and clears session cookies.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'

export async function POST(request: NextRequest) {
  const cookiesToSet: Array<{ name: string; value: string; options: Record<string, unknown> }> = []

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(incoming) {
          incoming.forEach(c =>
            cookiesToSet.push(c as { name: string; value: string; options: Record<string, unknown> })
          )
        },
      },
    }
  )

  await supabase.auth.signOut()

  const response = NextResponse.json({ success: true })

  // Clear session cookies
  cookiesToSet.forEach(({ name, value, options }) => {
    response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2])
  })

  // Also explicitly clear the auth-token cookie (belt and suspenders)
  response.cookies.set('sb-access-token', '', { maxAge: 0, path: '/' })
  response.cookies.set('sb-refresh-token', '', { maxAge: 0, path: '/' })

  return response
}
