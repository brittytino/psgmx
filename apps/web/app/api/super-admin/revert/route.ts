// ============================================================
// POST /api/super-admin/revert
// MIGRATED: super-admin → hod
// Impersonation is not currently supported in the new Supabase Auth flow.
// ============================================================
import { NextResponse } from 'next/server'

export async function POST() {
  return NextResponse.json({ message: 'TODO: Impersonation not yet implemented in Supabase flow', status: 'stub' }, { status: 501 })
}
