// ============================================================
// POST /api/super-admin/revert
// Reverts active HOD impersonation by clearing impersonation cookie.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { cookies } from 'next/headers'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || session.role !== 'hod') {
      return NextResponse.json({ error: 'Unauthorized — HOD role required' }, { status: 401 })
    }

    const cookieStore = await cookies()
    const impersonatedId = cookieStore.get('psgmx_impersonated_user_id')?.value

    cookieStore.delete('psgmx_impersonated_user_id')

    if (impersonatedId) {
      await supabaseAdmin.from('audit_logs').insert({
        actor_id: session.id,
        action: 'IMPERSONATE_END',
        target_table: 'users',
        target_id: impersonatedId,
      })
    }

    return NextResponse.json({ success: true, message: 'Impersonation ended' })
  } catch (err) {
    console.error('[POST /api/super-admin/revert] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
