import { NextRequest, NextResponse } from 'next/server'
import { isAuthorizedCron } from '@/lib/cron-auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  if (!isAuthorizedCron(request)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const reviewDueAt = new Date().toISOString()
  const staleBefore = new Date(Date.now() - (548 * 86400_000)).toISOString()
  const { data, error } = await (supabaseAdmin as any)
    .from('knowledge_brain_articles')
    .update({ review_due_at: reviewDueAt })
    .eq('approval_status', 'approved')
    .lt('updated_at', staleBefore)
    .is('review_due_at', null)
    .select('id')
  if (error) return NextResponse.json({ error: 'Knowledge review scheduling failed.' }, { status: 500 })
  return NextResponse.json({ success: true, flagged: data?.length || 0, review_due_at: reviewDueAt })
}
