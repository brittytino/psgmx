// ============================================================
// PSGMX — supabase/functions/compute-readiness-score/index.ts
// Deno Edge Function. Called by database triggers after changes to:
// daily_five_streaks, leetcode_stats, mock_exam_results, placement_attendance
//
// Formula (exact, per spec Section 5.1):
//   daily_five_score = clamp((accuracy * 0.10 * 100) + (adherence * 0.20 * 100), 0, 30)
//   leetcode_score   = clamp(batch_percentile * 0.25, 0, 25)
//   mock_exam_score  = clamp(weighted_avg_exam_score * 0.35, 0, 35)
//   session_score    = clamp((attended / max(eligible, 1)) * 10, 0, 10)
//   total            = sum of all four
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  let userId: string
  try {
    const body = await req.json()
    userId = body.user_id
    if (!userId) throw new Error('Missing user_id')
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Invalid request body', detail: String(err) }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)

  try {
    // ────────────────────────────────────────
    // 1. Fetch user + batch info
    // ────────────────────────────────────────
    const { data: user, error: userErr } = await supabase
      .from('users')
      .select('id, batch_id, role')
      .eq('id', userId)
      .single()

    if (userErr || !user) {
      return new Response(JSON.stringify({ error: 'User not found' }), { status: 404 })
    }

    // ────────────────────────────────────────
    // 2. Compute daily_five_score
    // ────────────────────────────────────────
    const { data: streak } = await supabase
      .from('daily_five_streaks')
      .select('running_accuracy_rate, total_days_completed, updated_at')
      .eq('user_id', userId)
      .maybeSingle()

    let dailyFiveScore = 0
    if (streak) {
      const accuracyRate = Number(streak.running_accuracy_rate) / 100 // convert 0–100 → 0–1
      // adherence_rate_last_90_days: we use total_days_completed as proxy
      // For a more precise calculation, we'd need a history table. Using available data:
      const adherenceRate = Math.min(streak.total_days_completed / 90, 1)
      dailyFiveScore = clamp(
        (accuracyRate * 0.10 * 100) + (adherenceRate * 0.20 * 100),
        0, 30
      )
    }

    // ────────────────────────────────────────
    // 3. Recompute batch_percentile for all students in batch (if leetcode changed)
    //    Then fetch this user's batch_percentile
    // ────────────────────────────────────────
    let leetcodeScore = 0
    if (user.batch_id) {
      // Get all leetcode stats for the batch
      const { data: batchStats } = await supabase
        .from('leetcode_stats')
        .select('user_id, batch_weighted_score')
        .in(
          'user_id',
          (await supabase
            .from('users')
            .select('id')
            .eq('batch_id', user.batch_id)
          ).data?.map((u: { id: string }) => u.id) ?? []
        )

      if (batchStats && batchStats.length > 0) {
        // Sort descending by batch_weighted_score
        const sorted = [...batchStats].sort((a, b) => b.batch_weighted_score - a.batch_weighted_score)
        const total = sorted.length

        // Compute and update percentile for every student in batch
        const updates = sorted.map((s, rank) => {
          const percentile = total === 1 ? 100 : ((total - rank - 1) / (total - 1)) * 100
          return { user_id: s.user_id, batch_percentile: Math.round(percentile * 100) / 100 }
        })

        // Upsert all percentiles
        await supabase.from('leetcode_stats').upsert(updates, { onConflict: 'user_id' })

        // Find this user's percentile
        const myPercentile = updates.find(u => u.user_id === userId)?.batch_percentile ?? 0
        leetcodeScore = clamp(myPercentile * 0.25, 0, 25)
      }
    } else {
      // No batch — use stored percentile directly
      const { data: ls } = await supabase
        .from('leetcode_stats')
        .select('batch_percentile')
        .eq('user_id', userId)
        .maybeSingle()
      if (ls) {
        leetcodeScore = clamp(Number(ls.batch_percentile) * 0.25, 0, 25)
      }
    }

    // ────────────────────────────────────────
    // 4. Compute mock_exam_score (time-weighted)
    // ────────────────────────────────────────
    const { data: examResults } = await supabase
      .from('mock_exam_results')
      .select('score, submitted_at')
      .eq('student_id', userId)

    let mockExamScore = 0
    if (examResults && examResults.length > 0) {
      const now = Date.now()
      const DAY_MS = 24 * 60 * 60 * 1000

      let weightedSum = 0
      let weightTotal = 0

      for (const result of examResults) {
        const submittedAt = new Date(result.submitted_at).getTime()
        const daysAgo = (now - submittedAt) / DAY_MS

        let weight: number
        if (daysAgo <= 30) weight = 1.0
        else if (daysAgo <= 90) weight = 0.7
        else weight = 0.4

        weightedSum += Number(result.score) * weight
        weightTotal += weight
      }

      const weightedAvg = weightTotal > 0 ? weightedSum / weightTotal : 0
      mockExamScore = clamp(weightedAvg * 0.35, 0, 35)
    }

    // ────────────────────────────────────────
    // 5. Compute session_score
    // ────────────────────────────────────────
    // sessions_attended: present or excused
    const { count: sessionsAttended } = await supabase
      .from('placement_attendance')
      .select('*', { count: 'exact', head: true })
      .eq('student_id', userId)
      .in('status', ['present', 'excused'])

    // sessions_eligible: sessions that targeted this student
    // (via batch scope or team scope)
    let sessionsEligible = 0
    if (user.batch_id) {
      // Batch-scoped sessions
      const { count: batchSessions } = await supabase
        .from('placement_sessions')
        .select('*', { count: 'exact', head: true })
        .eq('batch_id', user.batch_id)
        .eq('target_scope', 'batch')

      // Team-scoped sessions for this student's team
      const { data: userTeam } = await supabase
        .from('users')
        .select('team_id')
        .eq('id', userId)
        .single()

      let teamSessions = 0
      if (userTeam?.team_id) {
        const { count } = await supabase
          .from('placement_session_teams')
          .select('*', { count: 'exact', head: true })
          .eq('team_id', userTeam.team_id)
        teamSessions = count ?? 0
      }

      sessionsEligible = (batchSessions ?? 0) + teamSessions
    }

    const sessionScore = clamp(
      ((sessionsAttended ?? 0) / Math.max(sessionsEligible, 1)) * 10,
      0, 10
    )

    // ────────────────────────────────────────
    // 6. Compute total score
    // ────────────────────────────────────────
    const totalScore = Math.round(
      (dailyFiveScore + leetcodeScore + mockExamScore + sessionScore) * 100
    ) / 100

    const scoreData = {
      user_id: userId,
      score: clamp(totalScore, 0, 100),
      daily_five_score: Math.round(dailyFiveScore * 100) / 100,
      leetcode_score: Math.round(leetcodeScore * 100) / 100,
      mock_exam_score: Math.round(mockExamScore * 100) / 100,
      session_score: Math.round(sessionScore * 100) / 100,
      computed_at: new Date().toISOString(),
    }

    // ────────────────────────────────────────
    // 7. Upsert readiness_scores
    // ────────────────────────────────────────
    const { error: upsertErr } = await supabase
      .from('readiness_scores')
      .upsert(scoreData, { onConflict: 'user_id' })

    if (upsertErr) throw upsertErr

    // ────────────────────────────────────────
    // 8. Write daily snapshot (upsert on user_id + snapshot_date)
    // ────────────────────────────────────────
    const today = new Date().toISOString().split('T')[0]
    await supabase.from('readiness_score_history').upsert(
      {
        user_id: userId,
        score: scoreData.score,
        daily_five_score: scoreData.daily_five_score,
        leetcode_score: scoreData.leetcode_score,
        mock_exam_score: scoreData.mock_exam_score,
        session_score: scoreData.session_score,
        snapshot_date: today,
      },
      { onConflict: 'user_id,snapshot_date' }
    )

    return new Response(
      JSON.stringify({ success: true, user_id: userId, score: scoreData.score }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('compute-readiness-score error:', err)
    return new Response(
      JSON.stringify({ error: 'Internal server error', detail: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
