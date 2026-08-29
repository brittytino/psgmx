// PSGMX — batch-lifecycle-check Edge Function
// Idempotently checks if any batch should transition stage and executes the transition.
// Transitions:
//   active_junior -> active_senior: when the batch's junior_to_senior_date is passed
//   active_senior -> graduated: when the batch's graduation_date is passed
// Called by GitHub Actions every day at midnight IST.
// See: docs/user-flow.md Chapter 8.2

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')

Deno.serve(async (req) => {
  // Authenticate the GitHub Actions caller
  const authHeader = req.headers.get('Authorization')
  if (!CRON_SECRET || authHeader !== `Bearer ${CRON_SECRET}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const now = new Date()
    const transitions: { batch_code: string; from: string; to: string }[] = []

    // Fetch all active batches with transition date config
    const { data: batches, error: fetchErr } = await supabase
      .from('batches')
      .select('id, batch_code, status, start_year, end_year, junior_to_senior_date, graduation_date')
      .in('status', ['active_junior', 'active_senior'])

    if (fetchErr) throw fetchErr
    if (!batches || batches.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, message: 'No active batches to check', transitions: [] }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    for (const batch of batches) {
      let newStatus: string | null = null

      if (
        batch.status === 'active_junior' &&
        batch.junior_to_senior_date &&
        new Date(batch.junior_to_senior_date) <= now
      ) {
        newStatus = 'active_senior'
      } else if (
        batch.status === 'active_senior' &&
        batch.graduation_date &&
        new Date(batch.graduation_date) <= now
      ) {
        newStatus = 'graduated'
      }

      if (!newStatus) continue

      // Execute the transition idempotently
      const { error: updateErr } = await supabase
        .from('batches')
        .update({
          status: newStatus,
          status_transitioned_at: now.toISOString(),
          status_transitioned_by: 'batch-lifecycle-check-cron',
        })
        .eq('id', batch.id)
        .eq('status', batch.status)  // Idempotent: only update if still in expected status

      if (updateErr) {
        console.error(`Failed to transition batch ${batch.batch_code}:`, updateErr)
        continue
      }

      transitions.push({
        batch_code: batch.batch_code,
        from: batch.status,
        to: newStatus,
      })

      // If graduating: revoke all student-level admin capabilities
      if (newStatus === 'graduated') {
        const { error: revokeErr } = await supabase.rpc('revoke_batch_admin_capabilities', {
          p_batch_id: batch.id,
        })
        if (revokeErr) {
          console.error(`Failed to revoke capabilities for batch ${batch.batch_code}:`, revokeErr)
        }
      }

      // Log the transition to audit_logs
      await supabase.from('audit_logs').insert({
        actor_id: null,  // system action
        action: 'batch_lifecycle_transition',
        table_name: 'batches',
        record_id: batch.id,
        old_data: { status: batch.status },
        new_data: { status: newStatus, transitioned_at: now.toISOString() },
      })

      console.log(`Batch ${batch.batch_code}: ${batch.status} -> ${newStatus}`)
    }

    return new Response(
      JSON.stringify({
        ok: true,
        transitions,
        checked: batches.length,
        timestamp: now.toISOString(),
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('Batch lifecycle check error:', err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
