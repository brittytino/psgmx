// ============================================================
// POST /api/super-admin/impersonate
// HOD Impersonation endpoint — logs action to audit_logs and sets impersonation cookie.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isAdminUser } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { cookies } from 'next/headers'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || !isAdminUser(session)) {
      return NextResponse.json({ error: 'Unauthorized — Admin access required' }, { status: 401 })
    }

    const body = await req.json()
    const { targetUserId } = body

    if (!targetUserId) {
      return NextResponse.json({ error: 'targetUserId is required' }, { status: 400 })
    }

    const { data: targetUser, error } = await supabaseAdmin
      .from('users')
      .select('id, full_name, email, role')
      .eq('id', targetUserId)
      .single()

    if (error || !targetUser) {
      return NextResponse.json({ error: 'Target user not found' }, { status: 404 })
    }

    // Set impersonation cookie
    const cookieStore = await cookies()
    cookieStore.set('psgmx_impersonated_user_id', targetUserId, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      path: '/',
      maxAge: 3600, // 1 hour
    })

    // Log impersonation in audit_logs
    await supabaseAdmin.from('audit_logs').insert({
      actor_id: session.id,
      action: 'IMPERSONATE_START',
      target_table: 'users',
      target_id: targetUserId,
      metadata: { target_email: targetUser.email, target_role: targetUser.role },
    })

    return NextResponse.json({
      success: true,
      message: `Now impersonating ${targetUser.full_name}`,
      targetUser,
    })
  } catch (err) {
    console.error('[POST /api/super-admin/impersonate] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
