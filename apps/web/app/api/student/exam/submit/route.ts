import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const body = await req.json().catch(() => null) as {
    exam_id?: unknown; answers?: unknown; time_taken_seconds?: unknown; proctoring_flags?: unknown
  } | null
  const examId = typeof body?.exam_id === 'string' ? body.exam_id : ''
  const answers = body?.answers && typeof body.answers === 'object' && !Array.isArray(body.answers) ? body.answers : null
  const flags = Array.isArray(body?.proctoring_flags) ? body.proctoring_flags.slice(0, 50) : []
  if (!/^[0-9a-f-]{36}$/i.test(examId) || !answers || Object.keys(answers).length > 100) {
    return NextResponse.json({ error: 'Exam submission is invalid.' }, { status: 400 })
  }

  const supabase = await createClient()
  const { data, error } = await supabase.rpc('submit_exam_server_side', {
    p_exam_id: examId,
    p_student_id: user.id,
    p_answers: answers as any,
    p_time_taken_seconds: Math.max(0, Number(body?.time_taken_seconds || 0)),
    p_proctoring_flags: flags as any,
  })
  if (error) return NextResponse.json({ error: error.message }, { status: 409 })
  return NextResponse.json({ success: true, ...data as Record<string, unknown> })
}
