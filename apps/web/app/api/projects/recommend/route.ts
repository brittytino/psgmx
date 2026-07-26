// ============================================================
// GET /api/projects/recommend
// Returns recommended FYP projects from Knowledge Brain & fyp_projects.
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

    const { data: recommendations, error } = await supabaseAdmin
      .from('fyp_projects')
      .select('id, title, description, guide_name, repository_url, status, created_at')
      .order('created_at', { ascending: false })
      .limit(5)

    if (error) {
      console.error('[GET /api/projects/recommend] Error:', error)
      return NextResponse.json({ error: 'Failed to fetch recommendations' }, { status: 500 })
    }

    return NextResponse.json({
      success: true,
      recommendations: recommendations ?? [],
    })
  } catch (err) {
    console.error('[GET /api/projects/recommend] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
