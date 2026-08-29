// PSGMX — freshness-daemon Edge Function
// Applies evidence age penalties to all student readiness scores.
// Called by GitHub Actions every Sunday at 10:00 AM IST.
// Replaces pg_cron (Supabase Pro feature).
// See: docs/user-flow.md Chapter 5.3
//
// Evidence age rules:
//   < 30 days  -> confidence = 'high',   penalty = 0%
//   30-60 days -> confidence = 'medium', penalty = -10%
//   > 60 days  -> confidence = 'low',    penalty = -25%

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')

interface ReadinessScore {
  id: string
  profile_id: string
  dimension: string
  score: number
  confidence: string
  evidence_date: string
}

function getPenalty(ageDays: number): { confidence: string; penaltyPct: number } {
  if (ageDays < 30) return { confidence: 'high', penaltyPct: 0 }
  if (ageDays < 60) return { confidence: 'medium', penaltyPct: 10 }
  return { confidence: 'low', penaltyPct: 25 }
}

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
    let updatedCount = 0
    let skippedCount = 0

    // Fetch all readiness scores with evidence dates
    const { data: scores, error: fetchErr } = await supabase
      .from('readiness_scores')
      .select('id, profile_id, dimension, score, confidence, evidence_date')

    if (fetchErr) throw fetchErr
    if (!scores || scores.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, message: 'No scores to process', updated: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const updates: { id: string; confidence: string; score_with_penalty: number }[] = []

    for (const score of scores as ReadinessScore[]) {
      if (!score.evidence_date) { skippedCount++; continue }

      const evidenceDate = new Date(score.evidence_date)
      const ageDays = Math.floor((now.getTime() - evidenceDate.getTime()) / (1000 * 60 * 60 * 24))

      const { confidence, penaltyPct } = getPenalty(ageDays)

      // Only update if confidence changed (avoids unnecessary writes)
      if (confidence === score.confidence) { skippedCount++; continue }

      // Apply penalty to the base score (score is 0-100)
      const scoreWithPenalty = Math.max(0, Math.round(score.score * (1 - penaltyPct / 100)))

      updates.push({ id: score.id, confidence, score_with_penalty: scoreWithPenalty })
    }

    // Batch update in chunks of 100
    for (let i = 0; i < updates.length; i += 100) {
      const chunk = updates.slice(i, i + 100)
      for (const u of chunk) {
        const { error: updateErr } = await supabase
          .from('readiness_scores')
          .update({ confidence: u.confidence, score: u.score_with_penalty })
          .eq('id', u.id)

        if (updateErr) {
          console.error(`Failed to update score ${u.id}:`, updateErr)
        } else {
          updatedCount++
        }
      }
    }

    console.log(`Freshness daemon: ${updatedCount} scores updated, ${skippedCount} unchanged`)

    return new Response(
      JSON.stringify({
        ok: true,
        updated: updatedCount,
        skipped: skippedCount,
        timestamp: now.toISOString(),
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('Freshness daemon error:', err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
