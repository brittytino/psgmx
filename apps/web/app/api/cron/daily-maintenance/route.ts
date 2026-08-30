import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { isAuthorizedCron } from '@/lib/cron-auth'

export async function POST(request: NextRequest) {
  if (!isAuthorizedCron(request)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const db = supabaseAdmin as any
  const [maintenance, lifecycle] = await Promise.all([
    db.rpc('run_daily_maintenance'),
    db.rpc('rotate_batch_status'),
  ])
  if (maintenance.error || lifecycle.error) {
    return NextResponse.json({ error: 'Daily companion maintenance failed.' }, { status: 500 })
  }
  return NextResponse.json({ success: true, maintenance: maintenance.data, lifecycle: lifecycle.data })
}
