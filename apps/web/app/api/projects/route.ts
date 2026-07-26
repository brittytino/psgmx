// ============================================================
// GET/POST /api/projects
// FYP Project listings and submission endpoints via Supabase.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { searchParams } = new URL(req.url)
    const statusFilter = searchParams.get('status')

    let query = supabaseAdmin
      .from('fyp_projects')
      .select(`
        id,
        title,
        description,
        guide_name,
        team_members_count,
        status,
        repository_url,
        created_at,
        updated_at,
        student_id,
        users (
          full_name,
          email,
          roll_no
        )
      `)
      .order('created_at', { ascending: false })

    if (statusFilter) {
      query = query.eq('status', statusFilter)
    }

    const { data: projects, error } = await query

    if (error) {
      console.error('[GET /api/projects] Supabase error:', error)
      return NextResponse.json({ error: 'Failed to fetch projects' }, { status: 500 })
    }

    return NextResponse.json({ success: true, projects })
  } catch (err) {
    console.error('[GET /api/projects] Error:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { title, description, guide_name, team_members_count, repository_url } = body

    if (!title) {
      return NextResponse.json({ error: 'title is required' }, { status: 400 })
    }

    const { data: newProject, error } = await supabaseAdmin
      .from('fyp_projects')
      .insert({
        student_id: session.id,
        batch_id: session.batch_id,
        title,
        description: description ?? '',
        guide_name: guide_name ?? 'Dr. Arunkumar',
        team_members_count: team_members_count ?? 1,
        repository_url: repository_url ?? null,
        status: 'in_progress',
      })
      .select()
      .single()

    if (error) {
      console.error('[POST /api/projects] Supabase insert error:', error)
      return NextResponse.json({ error: 'Failed to create project' }, { status: 500 })
    }

    return NextResponse.json({ success: true, project: newProject }, { status: 201 })
  } catch (err) {
    console.error('[POST /api/projects] Error:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
