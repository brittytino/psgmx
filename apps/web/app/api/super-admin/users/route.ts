// ============================================================
// GET/POST /api/super-admin/users
// User management endpoint for HOD role.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isAdminUser } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || !isAdminUser(session)) {
      return NextResponse.json({ error: 'Unauthorized — Admin access required' }, { status: 401 })
    }

    const { data: users, error } = await supabaseAdmin
      .from('users')
      .select(`
        id,
        email,
        name,
        reg_no,
        role_label,
        roles,
        batch_id,
        created_at,
        batches (
          batch_code
        )
      `)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('[GET /api/super-admin/users] Error:', error)
      return NextResponse.json({ error: 'Failed to fetch users' }, { status: 500 })
    }

    return NextResponse.json({ success: true, users })
  } catch (err) {
    console.error('[GET /api/super-admin/users] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || !isAdminUser(session)) {
      return NextResponse.json({ error: 'Unauthorized — Admin access required' }, { status: 401 })
    }

    const body = await req.json()
    const { userId, roleLabel, subRole } = body

    if (!userId || !roleLabel) {
      return NextResponse.json({ error: 'userId and roleLabel are required' }, { status: 400 })
    }

    const updatePayload: { role_label: string; updated_at: string; roles?: Record<string, boolean> } = {
      role_label: roleLabel,
      updated_at: new Date().toISOString(),
    }

    // Sub-role flags (placement_rep / team_leader / coordinator) live inside
    // the `roles` JSONB, so merge rather than overwrite.
    if (subRole) {
      const { data: existing } = await supabaseAdmin.from('users').select('roles').eq('id', userId).single()
      const flagMap: Record<string, string> = {
        placement_rep: 'isPlacementRep',
        team_leader: 'isTeamLeader',
        coordinator: 'isCoordinator',
      }
      const flag = flagMap[subRole]
      if (flag) {
        updatePayload.roles = { ...(existing?.roles as Record<string, boolean> || {}), [flag]: true }
      }
    }

    const { data: updatedUser, error } = await supabaseAdmin
      .from('users')
      .update(updatePayload)
      .eq('id', userId)
      .select()
      .single()

    if (error) {
      console.error('[POST /api/super-admin/users] Error:', error)
      return NextResponse.json({ error: 'Failed to update user' }, { status: 500 })
    }

    // Log action to audit_logs
    await supabaseAdmin.from('audit_logs').insert({
      actor_id: session.id,
      action: 'USER_ROLE_UPDATE',
      entity_type: 'users',
      entity_id: userId,
      metadata: { new_role_label: roleLabel, new_sub_role: subRole },
    })

    return NextResponse.json({ success: true, user: updatedUser })
  } catch (err) {
    console.error('[POST /api/super-admin/users] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
