// ============================================================
// GET /api/cron/community-health
// Community health & engagement analytics based on Supabase metrics.
// ============================================================
import { NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const [scoresRes, streaksRes, logsRes] = await Promise.all([
      supabaseAdmin.from('readiness_scores').select('band'),
      supabaseAdmin.from('daily_five_streaks').select('current_streak'),
      supabaseAdmin.from('audit_logs').select('id', { count: 'exact' }),
    ])

    const bands = {
      strong: 0,
      building: 0,
      needs_attention: 0,
      at_risk: 0,
    }

    scoresRes.data?.forEach(s => {
      if (s.band in bands) {
        bands[s.band as keyof typeof bands]++
      }
    })

    const totalStreaks = streaksRes.data?.reduce((acc, curr) => acc + (curr.current_streak > 0 ? 1 : 0), 0) ?? 0

    return NextResponse.json({
      success: true,
      timestamp: new Date().toISOString(),
      community_health: {
        readiness_bands: bands,
        active_streaks_count: totalStreaks,
        total_audit_events: logsRes.count ?? 0,
      },
    })
  } catch (err) {
    console.error('[GET /api/cron/community-health] Error:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
