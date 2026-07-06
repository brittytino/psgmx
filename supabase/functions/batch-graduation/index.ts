// ============================================================
// PSGMX — supabase/functions/batch-graduation/index.ts (v2)
// Deno Edge Function. Called by CRON: 0 0 1 6 * (midnight June 1st)
// Also manually invocable for testing.
//
// Uses the graduate_batch() SQL RPC for true atomicity.
// If any step in the SQL function fails, Postgres rolls back all changes.
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (_req: Request) => {
  const supabase = createClient(supabaseUrl, serviceRoleKey)

  const today = new Date().toISOString().split('T')[0]
  const results: string[] = []

  try {
    // Find all batches that should graduate (end_date <= today, not yet graduated)
    const { data: graduatingBatches, error: batchErr } = await supabase
      .from('batches')
      .select('id, batch_code, status, end_date')
      .neq('status', 'graduated')
      .lte('end_date', today)

    if (batchErr) throw new Error(`Failed to query batches: ${batchErr.message}`)

    if (!graduatingBatches || graduatingBatches.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No batches to graduate today', date: today }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Graduate each batch using the transactional SQL RPC
    for (const batch of graduatingBatches) {
      const { data: result, error: gradErr } = await supabase
        .rpc('graduate_batch', { p_batch_id: batch.id })

      if (gradErr) {
        throw new Error(`Failed to graduate batch ${batch.batch_code}: ${gradErr.message}`)
      }

      if (result?.skipped) {
        results.push(`Skipped ${batch.batch_code}: ${result.reason}`)
      } else {
        results.push(
          `Graduated ${batch.batch_code}: ${result?.users_graduated ?? 0} students → alumni` +
          (result?.promoted_batch ? ` | Promoted: ${result.promoted_batch}` : '')
        )
      }
    }

    return new Response(
      JSON.stringify({ success: true, date: today, actions: results }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('batch-graduation error:', err)

    // Log failure to audit_logs
    await supabase.from('audit_logs').insert({
      actor_id:     null,
      action:       'batch_graduation_failed',
      target_table: 'batches',
      target_id:    null,
      metadata:     { error: String(err), date: today, partial_results: results },
    }).catch(() => {})

    return new Response(
      JSON.stringify({ error: 'Graduation process failed', detail: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
