// ============================================================
// DEPRECATED — lib/mongodb.ts
// This file previously connected to MongoDB.
// All database operations now use Supabase (PostgreSQL).
// This file is kept as an empty placeholder to prevent build errors
// from any remaining import that hasn't been migrated yet.
// DELETE this file once all imports are confirmed removed.
// ============================================================

// TODO: Verify no remaining imports of this file after Phase 3.
// Run: grep -r "from '@/lib/mongodb'" apps/web --include="*.ts" --include="*.tsx"

export default async function connectDB() {
  throw new Error(
    '[PSGMX] connectDB() is deprecated. All database access now uses Supabase. ' +
    'Import from @/lib/supabase/server or @/lib/supabase/admin instead.'
  )
}
