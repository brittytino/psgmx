// ============================================================
// PSGMX — supabase/functions/batch-graduation/index.ts
// Deno Edge Function. Called by CRON: 0 0 1 6 * (midnight June 1st)
// Also manually invocable for testing.
//
// Transaction steps (per spec Section 5.2):
// 1. Find batches where status != 'graduated' AND end_date <= today
// 2. Set each such batch status = 'graduated'
// 3. Set all students in those batches: role = 'alumni', app_role = 'student'
// 4. Insert graduation notifications for all affected users
// 5. Promote the most junior active_junior batch to active_senior
// 6. Log to audit_logs
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (_req: Request) => {
  const supabase = createClient(supabaseUrl, serviceRoleKey)

  const today = new Date().toISOString().split('T')[0]
  const results: string[] = []

  try {
    // ────────────────────────────────────────
    // Step 1: Find batches that should graduate
    // ────────────────────────────────────────
    const { data: graduatingBatches, error: batchErr } = await supabase
      .from('batches')
      .select('id, batch_code, status')
      .neq('status', 'graduated')
      .lte('end_date', today)

    if (batchErr) throw new Error(`Failed to query batches: ${batchErr.message}`)

    if (!graduatingBatches || graduatingBatches.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No batches to graduate today', date: today }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    for (const batch of graduatingBatches) {
      // ────────────────────────────────────────
      // Step 2: Graduate the batch
      // ────────────────────────────────────────
      const { error: batchUpdateErr } = await supabase
        .from('batches')
        .update({ status: 'graduated' })
        .eq('id', batch.id)

      if (batchUpdateErr) throw new Error(`Failed to graduate batch ${batch.batch_code}: ${batchUpdateErr.message}`)

      // ────────────────────────────────────────
      // Step 3: Convert students to alumni
      // ────────────────────────────────────────
      const { data: affectedUsers, error: usersErr } = await supabase
        .from('users')
        .select('id, full_name')
        .eq('batch_id', batch.id)
        .eq('role', 'student')

      if (usersErr) throw new Error(`Failed to query users for batch ${batch.batch_code}: ${usersErr.message}`)

      if (affectedUsers && affectedUsers.length > 0) {
        const userIds = affectedUsers.map((u: { id: string }) => u.id)

        const { error: roleUpdateErr } = await supabase
          .from('users')
          .update({ role: 'alumni', app_role: 'student' })
          .in('id', userIds)

        if (roleUpdateErr) throw new Error(`Failed to update user roles for batch ${batch.batch_code}: ${roleUpdateErr.message}`)

        // ────────────────────────────────────────
        // Step 4: Insert graduation notifications
        // ────────────────────────────────────────
        const notifications = userIds.map((uid: string) => ({
          user_id: uid,
          type: 'graduation' as const,
          title: `Congratulations! You've graduated from ${batch.batch_code}`,
          body: `Your batch ${batch.batch_code} has officially graduated. Welcome to the PSGMX alumni network! Visit psgmx.tech to explore alumni features.`,
          is_read: false,
          reference_type: 'batch',
          reference_id: batch.id,
        }))

        const { error: notifErr } = await supabase.from('notifications').insert(notifications)
        if (notifErr) throw new Error(`Failed to insert notifications for batch ${batch.batch_code}: ${notifErr.message}`)

        results.push(`Graduated ${batch.batch_code}: ${affectedUsers.length} students → alumni`)

        // ────────────────────────────────────────
        // Step 6: Log to audit_logs
        // ────────────────────────────────────────
        await supabase.from('audit_logs').insert({
          actor_id: null,             // system action
          action: 'batch_graduation',
          target_table: 'batches',
          target_id: batch.id,
          metadata: {
            batch_code: batch.batch_code,
            previous_status: batch.status,
            users_graduated: affectedUsers.length,
            graduated_at: new Date().toISOString(),
          },
        })
      }
    }

    // ────────────────────────────────────────
    // Step 5: Promote the most junior active_junior batch to active_senior
    // (Do this after all graduations so we don't promote a batch that just graduated)
    // ────────────────────────────────────────
    const { data: juniorBatch, error: juniorErr } = await supabase
      .from('batches')
      .select('id, batch_code')
      .eq('status', 'active_junior')
      .order('start_date', { ascending: true })
      .limit(1)
      .maybeSingle()

    if (juniorErr) throw new Error(`Failed to query junior batch: ${juniorErr.message}`)

    if (juniorBatch) {
      const { error: promoteErr } = await supabase
        .from('batches')
        .update({ status: 'active_senior' })
        .eq('id', juniorBatch.id)

      if (promoteErr) throw new Error(`Failed to promote batch ${juniorBatch.batch_code}: ${promoteErr.message}`)

      results.push(`Promoted ${juniorBatch.batch_code}: active_junior → active_senior`)

      await supabase.from('audit_logs').insert({
        actor_id: null,
        action: 'batch_promotion',
        target_table: 'batches',
        target_id: juniorBatch.id,
        metadata: {
          batch_code: juniorBatch.batch_code,
          previous_status: 'active_junior',
          new_status: 'active_senior',
          promoted_at: new Date().toISOString(),
        },
      })
    }

    return new Response(
      JSON.stringify({
        success: true,
        date: today,
        actions: results,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('batch-graduation error:', err)

    // Log the failure to audit_logs for visibility
    await supabase.from('audit_logs').insert({
      actor_id: null,
      action: 'batch_graduation_failed',
      target_table: 'batches',
      target_id: null,
      metadata: {
        error: String(err),
        date: today,
        partial_results: results,
      },
    }).catch(() => {})  // don't throw if audit log also fails

    return new Response(
      JSON.stringify({ error: 'Graduation process failed', detail: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
