// ============================================================
// GET /api/insights
// Staff-only aggregate dashboard insights.
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
    const session = await requireRole(req, ['faculty', 'hod'])
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Band distribution across current (latest-per-user) scores.
    // `readiness_scores` has no `band` column — it's derived from `score`,
    // and the table is an append-only history log (many rows per user),
    // so this reads from the `current_readiness_scores` view (added in
    // 09_sprint1_schema_and_features.sql) which already collapses to one
    // row per user.
    let studentQuery = supabaseAdmin
      .from('users')
      .select('id')
      .eq('role_label', 'Student')
    if (session.roleLabel.toLowerCase() === 'faculty' && session.batch_id) {
      studentQuery = studentQuery.eq('batch_id', session.batch_id)
    }
    const { data: studentRows, error: studentError } = await studentQuery
    if (studentError) throw studentError
    const studentIds = (studentRows ?? []).map((student) => student.id)

    const scoreResult = studentIds.length
      ? await supabaseAdmin.from('current_readiness_scores').select('score').in('user_id', studentIds)
      : { data: [], error: null }
    const { data: currentScores, error: bandErr } = scoreResult

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

    const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString()
    const admin = supabaseAdmin as any
    const conversationResult = studentIds.length
      ? await admin.from('ai_conversations').select('user_id').in('user_id', studentIds).gte('created_at', thirtyDaysAgo)
      : { data: [], error: null }
    if (conversationResult.error) throw conversationResult.error
    const conversationRows = (conversationResult.data ?? []) as Array<{ user_id: string }>

    const [articleCountResult, pendingCountResult, recentArticleResult] = await Promise.all([
      supabaseAdmin.from('knowledge_brain_articles').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('knowledge_brain_articles').select('id', { count: 'exact', head: true }).eq('approval_status', 'pending'),
      supabaseAdmin.from('knowledge_brain_articles')
        .select('id,title,author_id,approval_status,view_count,created_at')
        .order('created_at', { ascending: false })
        .limit(5),
    ])
    if (articleCountResult.error || pendingCountResult.error || recentArticleResult.error) {
      throw articleCountResult.error || pendingCountResult.error || recentArticleResult.error
    }

    const authorIds = [...new Set((recentArticleResult.data ?? []).map((article) => article.author_id).filter(Boolean))] as string[]
    const authorResult = authorIds.length
      ? await supabaseAdmin.from('users').select('id,name').in('id', authorIds)
      : { data: [], error: null }
    if (authorResult.error) throw authorResult.error
    const authorNames = new Map((authorResult.data ?? []).map((author) => [author.id, author.name]))

    return NextResponse.json({
      success: true,
      bands,
      activeStudents: studentIds.length,
      ai: {
        conversations30d: conversationRows.length,
        uniqueStudents30d: new Set(conversationRows.map((row) => row.user_id)).size,
        knowledgeArticles: articleCountResult.count ?? 0,
        pendingReviews: pendingCountResult.count ?? 0,
        recentArticles: (recentArticleResult.data ?? []).map((article) => ({
          ...article,
          author_name: article.author_id ? (authorNames.get(article.author_id) ?? 'Department member') : 'Department member',
        })),
      },
    })
  } catch (error) {
    console.error('Insights error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
