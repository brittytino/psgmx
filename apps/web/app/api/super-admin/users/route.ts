// ============================================================
// GET/POST /api/super-admin/users
// User management endpoint for HOD role.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function GET(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || session.role !== 'hod') {
      return NextResponse.json({ error: 'Unauthorized — HOD role required' }, { status: 401 })
    }

    const { data: users, error } = await supabaseAdmin
      .from('users')
      .select(`
        id,
        email,
        full_name,
        roll_no,
        role,
        app_role,
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
    if (!session?.id || session.role !== 'hod') {
      return NextResponse.json({ error: 'Unauthorized — HOD role required' }, { status: 401 })
    }

    const body = await req.json()
    const { userId, role, app_role } = body

    if (!userId || !role) {
      return NextResponse.json({ error: 'userId and role are required' }, { status: 400 })
    }

    const updatePayload: Record<string, any> = { role, updated_at: new Date().toISOString() }
    if (app_role) updatePayload.app_role = app_role

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
      target_table: 'users',
      target_id: userId,
      metadata: { new_role: role, new_app_role: app_role },
    })

    return NextResponse.json({ success: true, user: updatedUser })
  } catch (err) {
    console.error('[POST /api/super-admin/users] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
