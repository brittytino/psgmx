// ============================================================
// GET /api/health
// System health check — Supabase ping + version info.
// Migrated to Supabase.
// ============================================================
import { NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export const dynamic = 'force-dynamic'

export async function GET() {
  const checks: Record<string, { status: string; latencyMs?: number; error?: string }> = {}

  // Supabase ping
  const supabaseStart = Date.now()
  try {
    const { error } = await supabaseAdmin.from('batches').select('id').limit(1)
    checks.supabase = {
      status: error ? 'error' : 'ok',
      latencyMs: Date.now() - supabaseStart,
      error: error?.message,
    }
  } catch (err) {
    checks.supabase = { status: 'error', latencyMs: Date.now() - supabaseStart, error: String(err) }
  }

  const configStart = Date.now()
  try {
    const { data, error } = await supabaseAdmin
      .from('app_config')
      .select('rollout_stage')
      .limit(1)
      .maybeSingle()
    checks.rolloutConfig = {
      status: error || !data?.rollout_stage ? 'error' : 'ok',
      latencyMs: Date.now() - configStart,
      error: error?.message,
    }
  } catch (err) {
    checks.rolloutConfig = { status: 'error', latencyMs: Date.now() - configStart, error: String(err) }
  }

  const allOk = Object.values(checks).every(c => c.status === 'ok')

  return NextResponse.json({
    status: allOk ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version ?? 'unknown',
    checks,
  }, { status: allOk ? 200 : 503 })
}
