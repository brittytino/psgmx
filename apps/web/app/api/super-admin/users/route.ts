import { NextRequest, NextResponse } from 'next/server'
import { requireAppRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  const admin = await requireAppRole(req, 'placement_rep')
  if (!admin?.batch_id) return NextResponse.json({ error: 'PR access required.' }, { status: 403 })
  const { data, error } = await supabaseAdmin.from('users')
    .select('id,email,name,reg_no,role_label,roles,batch_id,created_at,batches(batch_code)')
    .eq('batch_id', admin.batch_id).order('reg_no')
  if (error) return NextResponse.json({ error: 'Users could not be loaded.' }, { status: 500 })
  return NextResponse.json({ success: true, users: data ?? [] })
}

export async function POST(req: NextRequest) {
  const admin = await requireAppRole(req, 'placement_rep')
  if (!admin?.batch_id) return NextResponse.json({ error: 'PR access required.' }, { status: 403 })
  const body = await req.json().catch(() => null) as { userId?: unknown; subRole?: unknown } | null
  const userId = typeof body?.userId === 'string' ? body.userId : ''
  const subRole = typeof body?.subRole === 'string' ? body.subRole : ''
  const allowed = new Set(['team_leader', 'coordinator', 'member'])
  if (!/^[0-9a-f-]{36}$/i.test(userId) || !allowed.has(subRole)) {
    return NextResponse.json({ error: 'A valid student and batch role are required.' }, { status: 400 })
  }
  const { data: target } = await supabaseAdmin.from('users').select('id,batch_id,role_label,roles').eq('id', userId).maybeSingle()
  if (!target || target.batch_id !== admin.batch_id || target.role_label !== 'Student') {
    return NextResponse.json({ error: 'PRs can manage students only within their own batch.' }, { status: 403 })
  }
  const roles = { ...(target.roles as Record<string, boolean> || {}), isTeamLeader: subRole === 'team_leader', isCoordinator: subRole === 'coordinator' }
  const { data, error } = await supabaseAdmin.from('users').update({ roles, updated_at: new Date().toISOString() }).eq('id', userId).select('id,name,reg_no,roles').single()
  if (error) return NextResponse.json({ error: 'Student role could not be updated.' }, { status: 500 })
  await supabaseAdmin.from('audit_logs').insert({ actor_id: admin.id, action: 'BATCH_ROLE_UPDATE', entity_type: 'users', entity_id: userId, metadata: { sub_role: subRole, batch_id: admin.batch_id } })
  return NextResponse.json({ success: true, user: data })
}
