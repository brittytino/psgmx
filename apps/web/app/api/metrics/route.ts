// ============================================================
// GET /api/metrics
// Platform metrics for the HOD/faculty dashboard.
// Migrated to Supabase.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    const session = await requireRole(req, ['hod', 'faculty'])
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Student count by batch
    const { data: batches } = await supabaseAdmin
      .from('batches')
      .select('id, batch_code, status')
      .neq('status', 'graduated')

    // Knowledge Brain articles count
    const { count: totalArticles } = await supabaseAdmin
      .from('knowledge_brain_articles')
      .select('*', { count: 'exact', head: true })
      .eq('approval_status', 'approved')

    // Pending articles count
    const { count: pendingArticles } = await supabaseAdmin
      .from('knowledge_brain_articles')
      .select('*', { count: 'exact', head: true })
      .eq('approval_status', 'pending')

    // Average readiness score
    const { data: scoreStats } = await supabaseAdmin
      .from('readiness_scores')
      .select('score')

    const avgScore = scoreStats && scoreStats.length > 0
      ? (scoreStats as any[]).reduce((sum, r) => sum + Number(r.score), 0) / scoreStats.length
      : 0

    // Students with active streaks (current_streak > 0)
    const { count: activeStreaks } = await supabaseAdmin
      .from('daily_five_streaks')
      .select('*', { count: 'exact', head: true })
      .gt('current_streak', 0)

    return NextResponse.json({
      success: true,
      metrics: {
        totalArticles: totalArticles ?? 0,
        pendingArticles: pendingArticles ?? 0,
        avgReadinessScore: Math.round(avgScore * 100) / 100,
        activeStreaks: activeStreaks ?? 0,
        activeBatches: batches?.length ?? 0,
      },
    })
  } catch (error) {
    console.error('Metrics error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
