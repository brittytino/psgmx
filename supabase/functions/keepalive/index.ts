// PSGMX — keepalive Edge Function
// Simple SELECT 1 to prevent Supabase free tier project pause.
// Called by GitHub Actions every Sunday at 08:00 AM IST.
// See: docs/user-flow.md Chapter 0.4

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

    // Lightweight query — just enough to register activity
    const { error } = await supabase.rpc('keepalive_ping')
    if (error) {
      // Fallback: if RPC doesn't exist, just query a system table
      const { error: fallbackErr } = await supabase
        .from('batches')
        .select('id')
        .limit(1)

      if (fallbackErr) throw fallbackErr
    }

    return new Response(
      JSON.stringify({ ok: true, timestamp: new Date().toISOString() }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('Keepalive error:', err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
