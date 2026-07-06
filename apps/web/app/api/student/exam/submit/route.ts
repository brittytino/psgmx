// ============================================================
// POST /api/student/exam/submit
// Server-side exam submission. Evaluates answers in Postgres
// via the submit_exam_server_side() RPC — correct answers are
// NEVER sent to the browser.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Only students can submit exams
    if (session.role !== 'student') {
      return NextResponse.json({ error: 'Only students can submit exams' }, { status: 403 })
    }

    const body = await req.json()
    const { exam_id, answers, time_taken_seconds, proctoring_flags } = body

    if (!exam_id || typeof answers !== 'object') {
      return NextResponse.json({ error: 'exam_id and answers are required' }, { status: 400 })
    }

    // Call server-side evaluation RPC — correct_option is never exposed to the client
    const { data: resultData, error } = await supabaseAdmin.rpc('submit_exam_server_side', {
      p_exam_id:            exam_id,
      p_student_id:         session.id,
      p_answers:            answers,
      p_time_taken_seconds: time_taken_seconds ?? 0,
      p_proctoring_flags:   proctoring_flags ?? [],
    } as any)
    const result: any = resultData;

    if (error) {
      console.error('[POST /api/student/exam/submit] RPC error:', error)
      if (error.message?.includes('Already submitted')) {
        return NextResponse.json({ error: 'Exam already submitted' }, { status: 409 })
      }
      return NextResponse.json({ error: 'Submission failed', detail: error.message }, { status: 500 })
    }

    if (result?.error) {
      return NextResponse.json({ error: result.error }, { status: 400 })
    }

    return NextResponse.json({
      success:   true,
      result_id: result.result_id,
      score:     result.score,
      raw_marks: result.raw_marks,
      out_of:    result.out_of,
    })
  } catch (err) {
    console.error('[POST /api/student/exam/submit] Error:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
