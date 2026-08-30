// ============================================================
// POST /api/auth/first-login
// Supabase migration: Previously set bcrypt password on first login.
// Now handles onboarding profile completion (GitHub, LinkedIn, skills).
// Password is managed entirely by Supabase Auth — no bcrypt needed.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { dashboardPath } from '@/lib/staff-auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session || !session.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json().catch(() => null) as {
      linkedin_url?: unknown; github_url?: unknown; skills?: unknown;
      interests?: unknown; career_goal?: unknown; arrears?: unknown;
    } | null
    const optionalUrl = (value: unknown) => {
      if (value === null || value === undefined || value === '') return null
      if (typeof value !== 'string' || value.length > 500) throw new Error('Profile URL is invalid')
      const url = new URL(value)
      if (url.protocol !== 'https:') throw new Error('Profile URLs must use HTTPS')
      return url.toString()
    }
    const toTags = (value: unknown) => typeof value === 'string'
      ? value.split(',').map((item) => item.trim()).filter(Boolean).slice(0, 30)
      : []
    const skills = toTags(body?.skills)
    const interests = toTags(body?.interests)
    const careerGoal = typeof body?.career_goal === 'string'
      ? body.career_goal.trim().slice(0, 500) || null
      : null
    const arrears = Array.isArray(body?.arrears) ? body.arrears.filter((value): value is string => typeof value === 'string').slice(0, 20) : []
    const { error } = await supabaseAdmin
      .from('users')
      .update({
        onboarding_complete: true,
        linkedin_url: optionalUrl(body?.linkedin_url),
        github_url: optionalUrl(body?.github_url),
        skills,
        interests,
        career_goal: careerGoal,
        arrears: arrears.map((subject) => ({ subject })),
      })
      .eq('id', session.id)

    if (error) {
      console.error('First login update error:', error)
      return NextResponse.json({ error: 'Failed to save profile' }, { status: 500 })
    }

    const redirect = dashboardPath(session.roleLabel, session.roles)

    return NextResponse.json({ success: true, redirect })
  } catch (error) {
    console.error('First Login Error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
