// ============================================================
// GET /api/governance/stats
// Governance statistics for Faculty and HOD portal.
// Aggregates audit logs, knowledge brain stats, and readiness overview.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || !['faculty', 'hod'].includes(session.roleLabel.toLowerCase())) {
      return NextResponse.json({ error: 'Unauthorized — Faculty or HOD required' }, { status: 401 })
    }

    const [articlesRes, pendingLogRes, usersRes, auditRes] = await Promise.all([
      supabaseAdmin.from('knowledge_brain_articles').select('id, approval_status', { count: 'exact' }),
      supabaseAdmin.from('placement_log_entries').select('id', { count: 'exact' }).eq('approval_status', 'pending'),
      supabaseAdmin.from('users').select('id, role_label', { count: 'exact' }),
      supabaseAdmin.from('audit_logs').select('id, action, created_at').order('created_at', { ascending: false }).limit(10),
    ])

    const totalArticles = articlesRes.count ?? 0
    const pendingLogEntries = pendingLogRes.count ?? 0
    const totalUsers = usersRes.count ?? 0
    const recentAuditLogs = auditRes.data ?? []

    return NextResponse.json({
      success: true,
      stats: {
        totalArticles,
        pendingLogEntries,
        totalUsers,
        recentAuditLogs,
      },
    })
  } catch (err) {
    console.error('[GET /api/governance/stats] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
