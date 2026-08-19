// ============================================================
// GET /api/insights
// Dashboard insights: student count, readiness bands, leaderboard.
// Migrated to Supabase.
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

    // Band distribution across current (latest-per-user) scores.
    // `readiness_scores` has no `band` column — it's derived from `score`,
    // and the table is an append-only history log (many rows per user),
    // so this reads from the `current_readiness_scores` view (added in
    // 09_sprint1_schema_and_features.sql) which already collapses to one
    // row per user.
    const { data: currentScores, error: bandErr } = await supabaseAdmin
      .from('current_readiness_scores')
      .select('score')

    if (bandErr) throw bandErr

    const bandFor = (score: number) => {
      if (score >= 80) return 'strong'
      if (score >= 60) return 'building'
      if (score >= 40) return 'needs_attention'
      return 'at_risk'
    }

    const bands: Record<string, number> = {
      strong: 0,
      building: 0,
      needs_attention: 0,
      at_risk: 0,
    }

    for (const row of currentScores ?? []) {
      bands[bandFor(row.score)]++
    }

    // Top 10 leaderboard by current score
    const { data: leaderboard, error: leaderboardErr } = await supabaseAdmin
      .from('current_readiness_scores')
      .select('user_id, score, users!inner(name, reg_no, batch_id)')
      .order('score', { ascending: false })
      .limit(10)

    if (leaderboardErr) throw leaderboardErr

    // Active student count
    const { count: activeStudents } = await supabaseAdmin
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('role_label', 'Student')

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
