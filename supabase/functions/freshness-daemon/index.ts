import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')

function confidenceFor(value: string | null): 'low' | 'medium' | 'high' {
  if (!value) return 'low'
  const ageDays = Math.floor((Date.now() - new Date(value).getTime()) / 86400_000)
  if (ageDays < 30) return 'high'
  if (ageDays < 60) return 'medium'
  return 'low'
}

Deno.serve(async (request) => {
  if (!CRON_SECRET || request.headers.get('Authorization') !== `Bearer ${CRON_SECRET}`) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const { data: dimensions, error } = await supabase
    .from('readiness_dimension_scores')
    .select('id,confidence,evidence_fresh_at')
  if (error) return Response.json({ error: 'Could not load readiness evidence.' }, { status: 500 })

  let updated = 0
  for (const dimension of dimensions || []) {
    const confidence = confidenceFor(dimension.evidence_fresh_at)
    if (confidence === dimension.confidence) continue
    const result = await supabase.from('readiness_dimension_scores')
      .update({ confidence })
      .eq('id', dimension.id)
    if (!result.error) updated += 1
  }
  return Response.json({ ok: true, examined: dimensions?.length || 0, updated })
})
