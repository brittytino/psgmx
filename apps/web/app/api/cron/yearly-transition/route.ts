// ============================================================
// GET /api/cron/yearly-transition
// REPLACED by the batch-graduation Supabase Edge Function.
// This CRON is now a no-op stub — the actual graduation logic
// runs as a Supabase Edge Function with schedule 0 0 1 6 *.
// ============================================================
import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  // TODO: This route is deprecated.
  // Batch graduation now runs automatically via the Supabase Edge Function
  // `batch-graduation` on CRON schedule `0 0 1 6 *` (midnight on June 1st).
  // See supabase/functions/batch-graduation/index.ts for the implementation.
  return NextResponse.json({
    message: 'Deprecated: Batch graduation is handled by the Supabase Edge Function.',
    edgeFunction: 'supabase/functions/batch-graduation/index.ts',
  })
}
