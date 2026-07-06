// ============================================================
// POST /api/auth/change-password
// Migrated to Supabase.
// Now: Uses Supabase Auth updateUser() — no bcrypt needed.
// Supabase Auth handles password verification and hashing.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { getUserFromRequest } from '@/lib/auth'

export async function POST(request: NextRequest) {
  const caller = await getUserFromRequest(request)
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  let body: { newPassword?: string }
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid body' }, { status: 400 })
  }

  const { newPassword } = body
  if (typeof newPassword !== 'string') {
    return NextResponse.json({ error: 'newPassword is required' }, { status: 400 })
  }

  if (newPassword.length < 8) {
    return NextResponse.json({ error: 'Password must be at least 8 characters' }, { status: 400 })
  }

  try {
    const supabase = await createClient()

    // Supabase Auth manages password verification internally
    const { error } = await supabase.auth.updateUser({ password: newPassword })

    if (error) {
      console.error('[POST /api/auth/change-password]', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json({ message: 'Password updated successfully' }, { status: 200 })
  } catch (error) {
    console.error('[POST /api/auth/change-password] Unexpected error:', error)
    return NextResponse.json({ error: 'Failed to update password' }, { status: 500 })
  }
}
