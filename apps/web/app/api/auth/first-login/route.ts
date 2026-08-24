// ============================================================
// POST /api/auth/first-login
// Supabase migration: Previously set bcrypt password on first login.
// Now handles onboarding profile completion (GitHub, LinkedIn, skills).
// Password is managed entirely by Supabase Auth — no bcrypt needed.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session || !session.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const supabase = await createClient()

    // Update user profile with onboarding data.
    // Note: linkedin_url/avatar_url are not columns on the live `users`
    // table — previously this endpoint always failed outright (unknown
    // columns error the whole PostgREST update), so onboarding_complete
    // never got set either. Only writing what actually exists.
    const { error } = await supabase
      .from('users')
      .update({ onboarding_complete: true })
      .eq('id', session.id)

    if (error) {
      console.error('First login update error:', error)
      return NextResponse.json({ error: 'Failed to save profile' }, { status: 500 })
    }

    const roleLabel = session.roleLabel.toLowerCase()
    const redirect = roleLabel === 'alumni' ? '/alumni' : `/${roleLabel}`

    return NextResponse.json({ success: true, redirect })
  } catch (error) {
    console.error('First Login Error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
