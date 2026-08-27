import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })
  if (req.headers.get('authorization') !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } })
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)
  const { error } = await supabase.rpc('rotate_batch_status')
  if (error) {
    console.error(JSON.stringify({ event: 'batch_rotation_failed', message: error.message }))
    return new Response(JSON.stringify({ error: 'Batch rotation failed' }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
  return new Response(JSON.stringify({ success: true, rotated_at: new Date().toISOString() }), { status: 200, headers: { 'Content-Type': 'application/json' } })
})
