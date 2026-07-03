// ============================================================
// GET/POST /api/projects
// FYPRepository is not in scope for this migration phase.
// TODO: If FYP tracking is needed, create a new Supabase table.
// ============================================================
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({ message: 'TODO: FYP project listings not yet migrated to Supabase', status: 'stub' })
}
export async function POST() {
  return NextResponse.json({ message: 'TODO: FYP project creation not yet migrated to Supabase', status: 'stub' }, { status: 501 })
}
