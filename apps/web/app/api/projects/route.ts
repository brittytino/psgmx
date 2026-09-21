// ============================================================
// GET/POST /api/projects
// FYP Project listings and submission endpoints via Supabase.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    if (!['faculty', 'hod'].includes(session.roleLabel.toLowerCase())) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
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
        batch_id,
        users (
          name,
          reg_no
        )
      `)
      .order('created_at', { ascending: false })

    // Mirrors the batch scoping in GET /api/insights: faculty only see their
    // own batch's projects, hod has department-wide access.
    if (session.roleLabel.toLowerCase() === 'faculty' && session.batch_id) {
      query = query.eq('batch_id', session.batch_id)
    }

    if (statusFilter && ['proposal', 'in_progress', 'completed', 'archived'].includes(statusFilter)) {
      query = query.eq('status', statusFilter as 'proposal' | 'in_progress' | 'completed' | 'archived')
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
    if (!isStudent(session)) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const body = await req.json()
    const title = typeof body.title === 'string' ? body.title.trim() : ''
    const description = typeof body.description === 'string' ? body.description.trim() : ''
    const guideName = typeof body.guide_name === 'string' ? body.guide_name.trim() : ''
    const teamMembersCount = Number(body.team_members_count ?? 1)
    const repositoryUrl = typeof body.repository_url === 'string' && body.repository_url.trim()
      ? body.repository_url.trim()
      : null

    if (!title || title.length > 160 || description.length > 5_000 || guideName.length > 120) {
      return NextResponse.json({ error: 'Enter a valid title and project details.' }, { status: 400 })
    }
    if (!Number.isInteger(teamMembersCount) || teamMembersCount < 1 || teamMembersCount > 10) {
      return NextResponse.json({ error: 'Team size must be between 1 and 10.' }, { status: 400 })
    }
    if (repositoryUrl) {
      try {
        const url = new URL(repositoryUrl)
        if (url.protocol !== 'https:') throw new Error('invalid protocol')
      } catch {
        return NextResponse.json({ error: 'Repository URL must be a valid HTTPS URL.' }, { status: 400 })
      }
    }

    const { data: newProject, error } = await supabaseAdmin
      .from('fyp_projects')
      .insert({
        student_id: session.id,
        batch_id: session.batch_id,
        title,
        description,
        guide_name: guideName || null,
        team_members_count: teamMembersCount,
        repository_url: repositoryUrl,
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
