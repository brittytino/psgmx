// ============================================================
// GET /api/governance/stats
// Migrated to Supabase.
// TODO: Define what "governance" means in new schema.
// Stubbed for now.
// ============================================================
import { NextResponse } from 'next/server'

export async function GET() {
  // TODO: Governance stats — map to Supabase audit_logs and knowledge_brain_articles
  return NextResponse.json({ message: 'TODO: Governance stats — not yet implemented', status: 'stub' })
}
