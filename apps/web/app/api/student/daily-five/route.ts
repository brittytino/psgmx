import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

type Rpc = (name: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: { message: string } | null }>

export async function GET(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const supabase = await createClient()
  const [{ data: streak, error: streakError }, { data: attempt, error: attemptError }] = await Promise.all([
    supabase.from('daily_five_streaks').select('current_streak,longest_streak,freezes_remaining').eq('user_id', user.id).maybeSingle(),
    supabase.from('daily_five_attempts').select('submitted_at,correct_count,accuracy_rate,flagged').eq('user_id', user.id).eq('attempt_date', new Date().toISOString().slice(0, 10)).maybeSingle(),
  ])
  if (streakError || attemptError) return NextResponse.json({ error: streakError?.message || attemptError?.message }, { status: 500 })
  if (attempt?.submitted_at) return NextResponse.json({ completed: true, result: attempt, streak: streak ?? { current_streak: 0 } })

  const { data, error } = await (supabase.rpc.bind(supabase) as unknown as Rpc)('get_daily_five_questions', { p_user_id: user.id })
  if (error) return NextResponse.json({ error: error.message }, { status: 409 })
  return NextResponse.json({ completed: false, questions: data ?? [], streak: streak ?? { current_streak: 0 } })
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const body = await req.json().catch(() => null) as { answers?: unknown } | null
  if (!body?.answers || typeof body.answers !== 'object' || Array.isArray(body.answers)) {
    return NextResponse.json({ error: 'Answers are required.' }, { status: 400 })
  }
  const supabase = await createClient()
  const { data, error } = await (supabase.rpc.bind(supabase) as unknown as Rpc)('submit_daily_five_answers', { p_user_id: user.id, p_answers: body.answers })
  if (error) return NextResponse.json({ error: error.message }, { status: 409 })
  return NextResponse.json({ success: true, result: data })
}
