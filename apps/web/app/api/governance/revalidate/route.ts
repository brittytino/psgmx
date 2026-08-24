// ============================================================
// POST /api/governance/revalidate
// Knowledge Brain cache revalidation endpoint for Faculty/HOD.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { revalidatePath } from 'next/cache'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id || !['faculty', 'hod'].includes(session.roleLabel.toLowerCase())) {
      return NextResponse.json({ error: 'Unauthorized — Faculty or HOD required' }, { status: 401 })
    }

    revalidatePath('/knowledge')
    revalidatePath('/student/knowledge-brain')
    revalidatePath('/faculty/knowledge-brain')

    return NextResponse.json({
      success: true,
      message: 'Knowledge Brain cache revalidated successfully',
    })
  } catch (err) {
    console.error('[POST /api/governance/revalidate] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
