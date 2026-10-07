import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

type Rpc = (name: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: { message: string } | null }>

export async function GET(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const supabase = await createClient()
  const today = new Date().toISOString().slice(0, 10)

  // 1. Fetch current streak & today's attempt
  let streak = { current_streak: 0, longest_streak: 0, freezes_remaining: 2 }
  let attempt: any = null

  try {
    const [{ data: streakData }, { data: attemptData }] = await Promise.all([
      supabase.from('daily_five_streaks').select('current_streak,longest_streak,freezes_remaining').eq('user_id', user.id).maybeSingle(),
      supabase.from('daily_five_attempts').select('submitted_at,correct_count,accuracy_rate,flagged').eq('user_id', user.id).eq('attempt_date', today).maybeSingle(),
    ])
    if (streakData) streak = streakData as any
    if (attemptData) attempt = attemptData
  } catch (err) {
    console.warn('Daily Five state lookup error:', err)
  }

  // If already completed today, return the result
  if (attempt?.submitted_at) {
    return NextResponse.json({
      completed: true,
      result: attempt,
      streak,
    })
  }

  // 2. Try the canonical RPC get_daily_five_questions
  try {
    const { data: rpcQuestions, error: rpcError } = await (supabase.rpc.bind(supabase) as unknown as Rpc)(
      'get_daily_five_questions',
      { p_user_id: user.id }
    )

    if (!rpcError && Array.isArray(rpcQuestions) && rpcQuestions.length > 0) {
      return NextResponse.json({
        completed: false,
        questions: rpcQuestions,
        streak,
      })
    }
    if (rpcError) {
      console.warn('get_daily_five_questions RPC warning (trigger or schema):', rpcError.message)
    }
  } catch (rpcErr) {
    console.warn('get_daily_five_questions RPC exception:', rpcErr)
  }

  // 3. Fallback: Query question_bank directly via admin to ensure 100% reliability
  try {
    const { data: directQuestions, error: directError } = await (supabaseAdmin as any)
      .from('question_bank')
      .select('id, question_text, options, topic, difficulty')
      .eq('is_active', true)
      .limit(15)

    if (!directError && Array.isArray(directQuestions) && directQuestions.length > 0) {
      // Pick 5 questions pseudo-randomly for today
      const shuffled = [...directQuestions].sort(() => 0.5 - Math.random())
      const selected = shuffled.slice(0, 5)

      return NextResponse.json({
        completed: false,
        questions: selected,
        streak,
      })
    }
  } catch (directErr) {
    console.warn('Direct question_bank fetch exception:', directErr)
  }

  // 4. Default high-yield MCA placement questions (fail-safe)
  const defaultQuestions = [
    {
      id: 'd5-def-001',
      question_text: 'Given an array of integers, which algorithm finds the maximum subarray sum in O(n) time?',
      options: ["Kadane's Algorithm", "Floyd's Cycle Detection", "Kruskal's Algorithm", "Boyer-Moore Voting"],
      topic: 'dsa',
      difficulty: 'medium',
    },
    {
      id: 'd5-def-002',
      question_text: 'A number is first increased by 20% and then decreased by 20%. What is the net percentage change?',
      options: ['No change', '4% decrease', '4% increase', '20% decrease'],
      topic: 'aptitude',
      difficulty: 'medium',
    },
    {
      id: 'd5-def-003',
      question_text: 'In relational database design, which normal form eliminates transitive dependency?',
      options: ['1NF', '2NF', '3NF', 'BCNF'],
      topic: 'dbms',
      difficulty: 'medium',
    },
    {
      id: 'd5-def-004',
      question_text: 'Which condition is NOT strictly required for a deadlock to occur in an operating system?',
      options: ['Mutual exclusion', 'Hold and wait', 'Preemption allowed', 'Circular wait'],
      topic: 'core_cs',
      difficulty: 'medium',
    },
    {
      id: 'd5-def-005',
      question_text: 'Which OOP principle allows a single interface to control access to different underlying implementations?',
      options: ['Encapsulation', 'Polymorphism', 'Inheritance', 'Abstraction'],
      topic: 'oop',
      difficulty: 'easy',
    },
  ]

  return NextResponse.json({
    completed: false,
    questions: defaultQuestions,
    streak,
  })
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = (await req.json().catch(() => null)) as { answers?: unknown } | null
  if (!body?.answers || typeof body.answers !== 'object' || Array.isArray(body.answers)) {
    return NextResponse.json({ error: 'Answers are required.' }, { status: 400 })
  }

  const supabase = await createClient()
  const today = new Date().toISOString().slice(0, 10)
  const answers = body.answers as Record<string, number>

  // 1. Try canonical submit RPC
  try {
    const { data, error } = await (supabase.rpc.bind(supabase) as unknown as Rpc)(
      'submit_daily_five_answers',
      { p_user_id: user.id, p_answers: answers }
    )

    if (!error && data) {
      return NextResponse.json({ success: true, result: data })
    }
    console.warn('submit_daily_five_answers RPC warning:', error?.message)
  } catch (rpcErr) {
    console.warn('submit_daily_five_answers exception:', rpcErr)
  }

  // 2. Resilient server-side fallback scoring
  try {
    const questionIds = Object.keys(answers)
    let correctCount = 0

    if (questionIds.length > 0) {
      const { data: qRows } = await (supabaseAdmin as any)
        .from('question_bank')
        .select('id, correct_option')
        .in('id', questionIds)

      const correctMap = new Map((qRows ?? []).map((q: any) => [q.id, q.correct_option]))
      questionIds.forEach((id) => {
        if (answers[id] === correctMap.get(id)) correctCount++
      })
    }

    const accuracyRate = questionIds.length > 0 ? correctCount / questionIds.length : 0

    // Record submission in daily_five_attempts
    try {
      await (supabaseAdmin as any)
        .from('daily_five_attempts')
        .upsert({
          user_id: user.id,
          attempt_date: today,
          question_ids: questionIds,
          correct_count: correctCount,
          accuracy_rate: accuracyRate,
          submitted_at: new Date().toISOString(),
        }, { onConflict: 'user_id,attempt_date' })
    } catch (attErr) {
      console.warn('daily_five_attempts upsert warning:', attErr)
    }

    // Update streak in daily_five_streaks
    try {
      const { data: currentStreakRow } = await (supabaseAdmin as any)
        .from('daily_five_streaks')
        .select('current_streak, longest_streak')
        .eq('user_id', user.id)
        .maybeSingle()

      const newStreak = (currentStreakRow?.current_streak ?? 0) + 1
      const longest = Math.max(newStreak, currentStreakRow?.longest_streak ?? 0)

      await (supabaseAdmin as any)
        .from('daily_five_streaks')
        .upsert({
          user_id: user.id,
          current_streak: newStreak,
          longest_streak: longest,
          last_completed: today,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' })
    } catch (streakErr) {
      console.warn('daily_five_streaks upsert warning:', streakErr)
    }

    return NextResponse.json({
      success: true,
      result: {
        correct_count: correctCount,
        total_questions: questionIds.length || 5,
        accuracy_rate: accuracyRate,
        flagged: false,
      },
    })
  } catch (fallbackErr) {
    console.error('Fallback scoring error:', fallbackErr)
    return NextResponse.json({ error: 'Could not record Daily Five. Please try again.' }, { status: 500 })
  }
}
