// PSGMX — sync-leetcode Edge Function
// Refreshes LeetCode stats for all users who have connected their username.
// Called by GitHub Actions every 6 hours.
// Uses LeetCode public API (no auth required, rate-limit safe with caching).
// See: docs/user-flow.md Chapter 4.5

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')
const CACHE_HOURS = 6  // Don't re-fetch if last sync was less than 6 hours ago

interface LeetCodeStats {
  totalSolved: number
  easySolved: number
  mediumSolved: number
  hardSolved: number
  acceptanceRate: number
  ranking: number
  streak: number
}

async function fetchLeetCodeStats(username: string): Promise<LeetCodeStats | null> {
  // LeetCode public GraphQL API
  const query = `
    query getUserProfile($username: String!) {
      matchedUser(username: $username) {
        submitStats {
          acSubmissionNum {
            difficulty
            count
          }
        }
        profile {
          ranking
        }
        userCalendar {
          streak
        }
      }
      userContestRankingHistory(username: $username) {
        attended
      }
    }
  `

  try {
    const response = await fetch('https://leetcode.com/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'PSGMX-LeetCode-Sync/1.0',
        'Referer': 'https://leetcode.com',
      },
      body: JSON.stringify({ query, variables: { username } }),
      signal: AbortSignal.timeout(10000),  // 10 second timeout
    })

    if (!response.ok) return null
    const data = await response.json()

    const user = data?.data?.matchedUser
    if (!user) return null

    const stats = user.submitStats?.acSubmissionNum || []
    const getCount = (diff: string) => stats.find((s: any) => s.difficulty === diff)?.count || 0

    const totalSolved = getCount('All')
    const easySolved = getCount('Easy')
    const mediumSolved = getCount('Medium')
    const hardSolved = getCount('Hard')

    return {
      totalSolved,
      easySolved,
      mediumSolved,
      hardSolved,
      acceptanceRate: 0,  // Not available in this query
      ranking: user.profile?.ranking || 0,
      streak: user.userCalendar?.streak || 0,
    }
  } catch (err) {
    console.error(`Failed to fetch LeetCode stats for ${username}:`, err)
    return null
  }
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
    const cacheThreshold = new Date(now.getTime() - CACHE_HOURS * 60 * 60 * 1000)

    // Fetch all users with a connected LeetCode username
    // who haven't been synced in the last CACHE_HOURS hours
    const { data: users, error: fetchErr } = await supabase
      .from('users')
      .select('id, leetcode_username, leetcode_last_synced_at')
      .not('leetcode_username', 'is', null)
      .or(`leetcode_last_synced_at.is.null,leetcode_last_synced_at.lt.${cacheThreshold.toISOString()}`)

    if (fetchErr) throw fetchErr
    if (!users || users.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, message: 'No users to sync', synced: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    let syncedCount = 0
    let failedCount = 0

    for (const user of users) {
      if (!user.leetcode_username) continue

      // Rate limit: 1 request per second to be respectful to LeetCode
      await new Promise((resolve) => setTimeout(resolve, 1000))

      const stats = await fetchLeetCodeStats(user.leetcode_username)

      if (!stats) {
        failedCount++
        continue
      }

      // Upsert into leetcode_stats table
      const { error: upsertErr } = await supabase
        .from('leetcode_stats')
        .upsert({
          user_id: user.id,
          problems_solved: stats.totalSolved,
          easy_solved: stats.easySolved,
          medium_solved: stats.mediumSolved,
          hard_solved: stats.hardSolved,
          ranking: stats.ranking,
          streak: stats.streak,
          synced_at: now.toISOString(),
        }, { onConflict: 'user_id' })

      if (upsertErr) {
        console.error(`Failed to upsert stats for user ${user.id}:`, upsertErr)
        failedCount++
        continue
      }

      // Update last synced timestamp on users table
      await supabase
        .from('users')
        .update({ leetcode_last_synced_at: now.toISOString() })
        .eq('id', user.id)

      syncedCount++
    }

    console.log(`LeetCode sync: ${syncedCount} synced, ${failedCount} failed`)

    return new Response(
      JSON.stringify({
        ok: true,
        synced: syncedCount,
        failed: failedCount,
        total: users.length,
        timestamp: now.toISOString(),
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('LeetCode sync error:', err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
