// ============================================================
// GET /api/projects/recommend
// FYPRepository recommendations not in scope.
// TODO: Could use pgvector similarity search in knowledge_embeddings.
// ============================================================
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({ message: 'TODO: Project recommendations not yet migrated to Supabase', status: 'stub' })
}
