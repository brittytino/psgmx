import { NextRequest, NextResponse } from 'next/server'
import { requireAppRole } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

type HandoverRpc = (name: string, args: Record<string, string>) => Promise<{ data: unknown; error: { message: string } | null }>

export async function POST(req: NextRequest) {
  const pr = await requireAppRole(req, 'placement_rep')
  if (!pr) return NextResponse.json({ error: 'Placement Representative access required.' }, { status: 403 })
  const body = await req.json().catch(() => null) as {
    graduating_batch?: unknown; incoming_batch?: unknown; new_pr?: unknown;
    checklist?: Array<{ done?: unknown }>
  } | null
  const outgoing = typeof body?.graduating_batch === 'string' ? body.graduating_batch.trim() : ''
  const incoming = typeof body?.incoming_batch === 'string' ? body.incoming_batch.trim() : ''
  const newPr = typeof body?.new_pr === 'string' ? body.new_pr.trim() : ''
  if (!outgoing || !incoming || !newPr || body?.checklist?.length !== 7 || body.checklist.some((item) => item.done !== true)) {
    return NextResponse.json({ error: 'Complete all seven checks and provide the incoming PR register number or email.' }, { status: 400 })
  }
  const supabase = await createClient()
  const { data, error } = await (supabase.rpc.bind(supabase) as unknown as HandoverRpc)('handover_placement_rep', {
    p_outgoing_batch_code: outgoing, p_incoming_batch_code: incoming, p_incoming_identity: newPr,
  })
  if (error) return NextResponse.json({ error: error.message }, { status: 409 })
  return NextResponse.json({ success: true, result: data })
}
