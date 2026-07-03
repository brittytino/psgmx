// ============================================================
// POST /api/governance/revalidate
// Migrated stub. Knowledge Brain revalidation now handled by
// the knowledge-ingest Edge Function.
// ============================================================
import { NextResponse } from 'next/server'

export async function POST() {
  return NextResponse.json({ message: 'TODO: Use Supabase Edge Function for knowledge ingestion', status: 'stub' })
}
