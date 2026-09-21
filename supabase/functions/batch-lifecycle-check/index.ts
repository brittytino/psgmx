// PSGMX — batch-lifecycle-check Edge Function
//
// Was never wired into any GitHub Actions workflow, and read/wrote columns
// that don't exist on `batches` (junior_to_senior_date, graduation_date,
// status_transitioned_at, status_transitioned_by — the real schema derives
// status from start_year/end_year, see 01_schema_core.sql and
// 20_scalable_batch_lifecycle.sql) and called an RPC,
// revoke_batch_admin_capabilities, that was never defined anywhere. It
// would have thrown on its very first query if anything ever invoked it.
//
// The batch lifecycle is correctly and idempotently handled by
// public.rotate_batch_status() (20_scalable_batch_lifecycle.sql, fixed in
// 57_fix_graduation_role_clearing.sql to also clear PR/coordinator/
// team-leader capabilities on graduation), which is what
// apps/web/app/api/cron/daily-maintenance actually calls every day via
// .github/workflows/daily-maintenance.yml. This function now delegates to
// the same RPC — identical to its sibling supabase/functions/batch-
// graduation — so if anything still targets this endpoint directly (e.g.
// an external cron pointed at the Edge Function URL instead of the Next.js
// route), it performs the real, correct transition instead of crashing.
// See docs/batch-lifecycle.md.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')

Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!CRON_SECRET || authHeader !== `Bearer ${CRON_SECRET}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { error } = await supabase.rpc('rotate_batch_status')
  if (error) {
    console.error(JSON.stringify({ event: 'batch_lifecycle_check_failed', message: error.message }))
    return new Response(JSON.stringify({ error: 'Batch lifecycle check failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(
    JSON.stringify({ ok: true, checked_at: new Date().toISOString() }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  )
})
