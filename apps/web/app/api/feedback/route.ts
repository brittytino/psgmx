// ============================================================
// POST /api/feedback
// Submits platform feedback to user_feedback table in Supabase.
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

    const body = await req.json()
    const { category, feedback_text, rating } = body

    if (!feedback_text || typeof feedback_text !== 'string') {
      return NextResponse.json({ error: 'feedback_text is required' }, { status: 400 })
    }

    const { data: newFeedback, error } = await supabaseAdmin
      .from('user_feedback')
      .insert({
        user_id: session.id,
        category: category ?? 'general',
        feedback_text,
        rating: rating ? Math.min(5, Math.max(1, Number(rating))) : 5,
      })
      .select()
      .single()

    if (error) {
      console.error('[POST /api/feedback] Error:', error)
      return NextResponse.json({ error: 'Failed to submit feedback' }, { status: 500 })
    }

    return NextResponse.json({ success: true, feedback: newFeedback }, { status: 201 })
  } catch (err) {
    console.error('[POST /api/feedback] Exception:', err)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
