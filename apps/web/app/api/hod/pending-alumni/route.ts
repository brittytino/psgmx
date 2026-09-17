import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'

async function retiredResponse(req: NextRequest) {
  const actor = await requireRole(req, 'hod')
  if (!actor) return NextResponse.json({ error: 'Forbidden — HOD access required' }, { status: 403 })
  return NextResponse.json(
    { error: 'Pending alumni approval was retired. Alumni access now reactivates department-approved roster records only.' },
    { status: 410 },
  )
}

export const GET = retiredResponse
export const PUT = retiredResponse
