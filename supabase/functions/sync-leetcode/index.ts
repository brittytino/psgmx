import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')
const CACHE_MS = 6 * 60 * 60 * 1000

interface Stats {
  total_solved: number
  easy_solved: number
  medium_solved: number
  hard_solved: number
  ranking: number
  profile_picture: string | null
}

async function fetchStats(username: string): Promise<Stats | null> {
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
    const count = (difficulty: string) => Number(values.find((item: { difficulty: string }) => item.difficulty === difficulty)?.count || 0)
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

Deno.serve(async (request) => {
  if (!CRON_SECRET || request.headers.get('Authorization') !== `Bearer ${CRON_SECRET}`) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const { data: users, error: userError } = await supabase
    .from('users')
    .select('leetcode_username')
    .not('leetcode_username', 'is', null)
  if (userError) return Response.json({ error: 'Could not load connected profiles.' }, { status: 500 })

  const usernames = [...new Set((users || []).map((item) => String(item.leetcode_username || '').trim()).filter(Boolean))]
  if (!usernames.length) return Response.json({ ok: true, synced: 0, failed: 0 })

  const { data: cached } = await supabase
    .from('leetcode_stats')
    .select('username,total_solved,weekly_score,last_updated')
    .in('username', usernames)
  const cache = new Map((cached || []).map((item) => [item.username.toLowerCase(), item]))
  const due = usernames.filter((username) => {
    const updated = cache.get(username.toLowerCase())?.last_updated
    return !updated || Date.now() - new Date(updated).getTime() >= CACHE_MS
  })

  let synced = 0
  let failed = 0
  const snapshotDate = new Date().toISOString().slice(0, 10)
  const baselineDate = new Date(Date.now() - 7 * 86400_000).toISOString().slice(0, 10)

  for (let offset = 0; offset < due.length; offset += 4) {
    const batch = due.slice(offset, offset + 4)
    await Promise.all(batch.map(async (username) => {
      const stats = await fetchStats(username)
      if (!stats) { failed += 1; return }

      const { data: baseline } = await supabase
        .from('leetcode_stat_snapshots')
        .select('total_solved')
        .eq('username', username)
        .lte('snapshot_date', baselineDate)
        .order('snapshot_date', { ascending: false })
        .limit(1)
        .maybeSingle()
      const previous = cache.get(username.toLowerCase())
      const weeklyScore = baseline
        ? Math.max(0, stats.total_solved - Number(baseline.total_solved || 0))
        : Number(previous?.weekly_score || 0)
      const now = new Date().toISOString()

      const { error } = await supabase.from('leetcode_stats').upsert({
        username,
        ...stats,
        weekly_score: weeklyScore,
        last_updated: now,
      }, { onConflict: 'username' })
      if (error) { failed += 1; return }

      await supabase.from('leetcode_stat_snapshots').upsert({
        username,
        snapshot_date: snapshotDate,
        total_solved: stats.total_solved,
        easy_solved: stats.easy_solved,
        medium_solved: stats.medium_solved,
        hard_solved: stats.hard_solved,
        ranking: stats.ranking,
        captured_at: now,
      }, { onConflict: 'username,snapshot_date' })
      synced += 1
    }))
    if (offset + 4 < due.length) await new Promise((resolve) => setTimeout(resolve, 500))
  }

  return Response.json({ ok: true, connected: usernames.length, due: due.length, synced, failed })
})
