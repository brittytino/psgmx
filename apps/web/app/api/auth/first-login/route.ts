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

    const body = await req.json()
    const { linkedin_url, avatar_url } = body

    const supabase = await createClient()

    // Update user profile with onboarding data
    const updateData: Record<string, unknown> = { onboarding_complete: true }
    if (linkedin_url) updateData.linkedin_url = linkedin_url
    if (avatar_url) updateData.avatar_url = avatar_url

    const { error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', session.id)

    if (error) {
      console.error('First login update error:', error)
      return NextResponse.json({ error: 'Failed to save profile' }, { status: 500 })
    }

    const redirect = session.role === 'alumni' ? '/alumni' : `/${session.role}`

    return NextResponse.json({ success: true, redirect })
  } catch (error) {
    console.error('First Login Error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
