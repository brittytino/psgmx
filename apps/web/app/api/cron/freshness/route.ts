import { NextRequest, NextResponse } from 'next/server'
import { isAuthorizedCron } from '@/lib/cron-auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

const confidenceFor = (value: string | null): 'low' | 'medium' | 'high' => {
  if (!value) return 'low'
  const days = Math.floor((Date.now() - new Date(value).getTime()) / 86400_000)
  return days < 30 ? 'high' : days < 60 ? 'medium' : 'low'
}

export async function POST(request: NextRequest) {
  if (!isAuthorizedCron(request)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const db = supabaseAdmin as any
  const { data, error } = await db.from('readiness_dimension_scores').select('id,confidence,evidence_fresh_at')
  if (error) return NextResponse.json({ error: 'Readiness evidence could not be loaded.' }, { status: 500 })
  let updated = 0
  for (const dimension of data || []) {
    const confidence = confidenceFor(dimension.evidence_fresh_at)
    if (confidence === dimension.confidence) continue
    const result = await db.from('readiness_dimension_scores').update({ confidence }).eq('id', dimension.id)
    if (!result.error) updated += 1
  }
  return NextResponse.json({ success: true, examined: data?.length || 0, updated })
}
