// ============================================================
// GET/PUT /api/user/profile
// Migrated to Supabase (New Schema).
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user || !user.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data: profile, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()

    if (error) {
      console.error('Profile fetch error:', error)
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    return NextResponse.json({ success: true, profile })
  } catch (error) {
    console.error('Profile API Error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user || !user.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { name, linkedin_url, avatar_url, current_company, current_role_title, mentorship_open } = body

    const updateData: Record<string, unknown> = {}
    if (name !== undefined) updateData.name = name
    // (Other fields can be added if you alter the table to add them later)

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json({ error: 'No fields to update' }, { status: 400 })
    }

    const { error } = await supabase
      .from('users')
      // @ts-expect-error Supabase types are out of sync with new schema
      .update(updateData as any)
      .eq('id', user.id)

    if (error) throw error

    return NextResponse.json({ success: true, message: 'Profile updated' })
  } catch {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
