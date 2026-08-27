import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json({ error: 'Method Not Allowed' }, 405)
  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) return json({ error: 'Unauthorized' }, 401)

  let userId: string
  try {
    const body = await req.json()
    userId = body.user_id
    if (!/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(userId)) throw new Error('Invalid user_id')
  } catch (error) {
    return json({ error: 'Invalid request body', detail: String(error) }, 400)
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)
  const token = authHeader.slice(7)
  if (token !== serviceRoleKey) {
    const { data: { user }, error } = await supabase.auth.getUser(token)
    if (error || !user) return json({ error: 'Unauthorized' }, 401)
    const { data: identity } = await supabase.from('user_auth_identities').select('user_id').eq('auth_user_id', user.id).maybeSingle()
    if ((identity?.user_id ?? user.id) !== userId) return json({ error: 'Forbidden' }, 403)
  }

  const { data, error } = await supabase.rpc('compute_readiness_score', { p_user_id: userId })
  if (error) {
    console.error(JSON.stringify({ event: 'readiness_compute_failed', user_id: userId, message: error.message }))
    return json({ error: 'Readiness computation failed' }, 500)
  }
  return json({ success: true, user_id: userId, result: data })
})
