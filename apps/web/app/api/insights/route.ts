// ============================================================
// GET /api/insights
// Dashboard insights: student count, readiness bands, leaderboard.
// Migrated: Previously queried MongoDB UserEvent + UserAccount.
// Now queries Supabase readiness_scores + users tables.
// ============================================================
import { NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { NextRequest } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    const session = await requireRole(req, ['faculty', 'hod', 'student', 'alumni'])
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Band distribution for all active batches
    const { data: bandCounts, error: bandErr } = await supabaseAdmin
      .from('readiness_scores')
      .select('band')

    if (bandErr) throw bandErr

    const bands: Record<string, number> = {
      strong: 0,
      building: 0,
      needs_attention: 0,
      at_risk: 0,
    }

    for (const row of bandCounts ?? []) {
      if (row.band && row.band in bands) {
        bands[row.band as string]++
      }
    }

    // Top 10 leaderboard by score
    const { data: leaderboard, error: leaderboardErr } = await supabaseAdmin
      .from('readiness_scores')
      .select('user_id, score, band, users!inner(full_name, roll_no, batch_id)')
      .order('score', { ascending: false })
      .limit(10)

    if (leaderboardErr) throw leaderboardErr

    // Active student count
    const { count: activeStudents } = await supabaseAdmin
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('role', 'student')

    return NextResponse.json({
      success: true,
      bands,
      leaderboard: leaderboard ?? [],
      activeStudents: activeStudents ?? 0,
    })
  } catch (error) {
    console.error('Insights error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
