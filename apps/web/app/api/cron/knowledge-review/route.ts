// ============================================================
// GET /api/cron/knowledge-review
// REPLACED by the knowledge-ingest Supabase Edge Function.
// Trigger-based; no longer needs a cron.
// ============================================================
import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  // TODO: Deprecated. Knowledge Brain ingestion is now trigger-based.
  // When a placement_log_entry is approved, the DB trigger fires
  // knowledge-ingest Edge Function automatically.
  // See supabase/migrations/03_triggers.sql and
  // supabase/functions/knowledge-ingest/index.ts
  return NextResponse.json({
    message: 'Deprecated: Knowledge ingestion is now trigger-based via Supabase Edge Function.',
    trigger: 'trig_placement_log_approval',
    edgeFunction: 'supabase/functions/knowledge-ingest/index.ts',
  })
}
