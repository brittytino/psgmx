// ============================================================
// POST /api/feedback
// UserFeedback model not in scope for this migration.
// TODO: Create feedback table in Supabase or use external service.
// ============================================================
import { NextResponse } from 'next/server'

export async function POST() {
  // TODO: Create feedback table in Supabase or redirect to external feedback service
  return NextResponse.json({ message: 'TODO: Feedback submission not yet migrated to Supabase', status: 'stub' }, { status: 501 })
}
