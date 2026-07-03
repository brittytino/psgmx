// ============================================================
// POST /api/fyp/[id]/complete
// FYPRepository is not in scope for Phase 3.
// TODO: Create an fyp_projects table in Supabase if needed.
// ============================================================
import { NextResponse } from 'next/server'

export async function POST() {
  return NextResponse.json({ message: 'TODO: FYP completion not yet migrated to Supabase', status: 'stub' }, { status: 501 })
}
