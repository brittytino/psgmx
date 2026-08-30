import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const body = await req.json().catch(() => null) as { exam_id?: unknown; reflection?: unknown } | null
  const examId = typeof body?.exam_id === 'string' ? body.exam_id : ''
  const reflection = typeof body?.reflection === 'string' ? body.reflection.trim() : ''
  if (!/^[0-9a-f-]{36}$/i.test(examId) || reflection.length < 20 || reflection.length > 2000) {
    return NextResponse.json({ error: 'Enter a reflection between 20 and 2,000 characters.' }, { status: 400 })
  }
  const { data, error } = await supabaseAdmin.from('mock_exam_results').update({
    reflection,
    reflected_at: new Date().toISOString(),
  }).eq('exam_id', examId).eq('student_id', user.id).in('status', ['submitted', 'auto_submitted']).select('id').maybeSingle()
  if (error || !data) return NextResponse.json({ error: 'A completed assessment result was not found.' }, { status: 404 })
  return NextResponse.json({ success: true })
}
