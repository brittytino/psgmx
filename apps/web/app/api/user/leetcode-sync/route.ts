import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { checkRateLimit } from '@/lib/limiter'
import { supabaseAdmin } from '@/lib/supabase/admin'

// The mobile app (apps/mobile/lib/providers/leetcode_provider.dart) used to
// fetch leetcode.com/graphql directly from the client and upsert the result
// straight into `leetcode_stats` using the student's own anon-key session.
// `leetcode_stats_update_own` (52_private_progress_guardrails.sql) only
// checks row ownership, not column values, so a modified client could set
// `total_solved`/`weekly_score` to anything and inflate the readiness score
// the `readiness_after_leetcode_sync` trigger computes from those columns.
// The PRD (docs/user-flow.md 4.5) specifies server-side sync only.
//
// This route is the trusted, server-side path: it re-derives the caller's
// OWN leetcode_username from their authenticated profile (never a
// client-supplied username), fetches the stats itself, and writes with the
// service-role client. Direct client writes are closed off in
// 58_lock_down_leetcode_writes.sql, which restricts INSERT/UPDATE on
// `leetcode_stats` to service_role only. Mobile calls this endpoint instead
// of writing to Supabase directly for the "connect now" instant-sync UX;
// the 6-hourly `sync-leetcode` GitHub Actions job remains the background
// refresh path for everyone, including students who never open the app.

interface LeetcodeStats {
  total_solved: number
  easy_solved: number
  medium_solved: number
  hard_solved: number
  ranking: number
  profile_picture: string | null
}

async function fetchStats(username: string): Promise<LeetcodeStats | null> {
  const query = `query profile($username: String!) {
    matchedUser(username: $username) {
      submitStats { acSubmissionNum { difficulty count } }
      profile { ranking userAvatar }
    }
  }`
  try {
    const response = await fetch('https://leetcode.com/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'PSGMX-Preparation-Sync/2.0',
        Referer: 'https://leetcode.com',
      },
      body: JSON.stringify({ query, variables: { username } }),
      signal: AbortSignal.timeout(12_000),
    })
    if (!response.ok) return null
    const matched = (await response.json())?.data?.matchedUser
    if (!matched) return null
    const values = matched.submitStats?.acSubmissionNum || []
    const count = (difficulty: string) =>
      Number(values.find((item: { difficulty: string }) => item.difficulty === difficulty)?.count || 0)
    return {
      total_solved: count('All'),
      easy_solved: count('Easy'),
      medium_solved: count('Medium'),
      hard_solved: count('Hard'),
      ranking: Number(matched.profile?.ranking || 0),
      profile_picture: matched.profile?.userAvatar || null,
    }
  } catch {
    return null
  }
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const rate = checkRateLimit(`leetcode-sync:${user.id}`)
  if (!rate.success) return NextResponse.json({ error: 'Please wait before syncing again.' }, { status: 429 })

  const { data: profile } = await supabaseAdmin
    .from('users')
    .select('leetcode_username')
    .eq('id', user.id)
    .maybeSingle()

  const username = String(profile?.leetcode_username || '').trim()
  if (!username) {
    return NextResponse.json({ error: 'Connect a LeetCode username first.' }, { status: 400 })
  }

  const stats = await fetchStats(username)
  if (!stats) {
    return NextResponse.json({ error: 'Could not reach LeetCode right now. Try again shortly.' }, { status: 502 })
  }

  const { data: baseline } = await supabaseAdmin
    .from('leetcode_stat_snapshots')
    .select('total_solved')
    .eq('username', username)
    .lte('snapshot_date', new Date(Date.now() - 7 * 86_400_000).toISOString().slice(0, 10))
    .order('snapshot_date', { ascending: false })
    .limit(1)
    .maybeSingle()

  const { data: previous } = await supabaseAdmin
    .from('leetcode_stats')
    .select('weekly_score')
    .eq('username', username)
    .maybeSingle()

  const weeklyScore = baseline
    ? Math.max(0, stats.total_solved - Number(baseline.total_solved || 0))
    : Number(previous?.weekly_score || 0)
  const now = new Date().toISOString()

  const { error } = await supabaseAdmin.from('leetcode_stats').upsert(
    { username, ...stats, weekly_score: weeklyScore, last_updated: now },
    { onConflict: 'username' },
  )
  if (error) return NextResponse.json({ error: 'Sync could not be saved.' }, { status: 500 })

  await supabaseAdmin.from('leetcode_stat_snapshots').upsert(
    {
      username,
      snapshot_date: now.slice(0, 10),
      total_solved: stats.total_solved,
      easy_solved: stats.easy_solved,
      medium_solved: stats.medium_solved,
      hard_solved: stats.hard_solved,
      ranking: stats.ranking,
      captured_at: now,
    },
    { onConflict: 'username,snapshot_date' },
  )

  return NextResponse.json({ success: true, stats: { ...stats, weekly_score: weeklyScore, last_updated: now } })
}
