// ============================================================
// POST /api/fyp/[id]/complete
// Marks an FYP project as completed in Supabase.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const resolvedParams = await params
    const projectId = resolvedParams.id

    const { data: project, error: fetchErr } = await supabaseAdmin
      .from('fyp_projects')
      .select('id, student_id')
      .eq('id', projectId)
      .single()

    if (fetchErr || !project) {
      return NextResponse.json({ error: 'Project not found' }, { status: 404 })
    }

    if (project.student_id !== session.id && !['faculty', 'hod'].includes(session.roleLabel.toLowerCase())) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const { error: updateErr } = await supabaseAdmin
      .from('fyp_projects')
      .update({ status: 'completed', updated_at: new Date().toISOString() })
      .eq('id', projectId)

    if (updateErr) {
      console.error('[POST /api/fyp/[id]/complete] Error:', updateErr)
      return NextResponse.json({ error: 'Failed to update project status' }, { status: 500 })
    }

    return NextResponse.json({ success: true, message: 'FYP Project marked as completed' })
  } catch (err) {
    console.error('[POST /api/fyp/[id]/complete] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
