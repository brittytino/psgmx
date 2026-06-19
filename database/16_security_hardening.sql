-- ============================================================================
-- PSGMX v4 — Migration 16: Security Hardening
-- ============================================================================
-- Hardens audit_logs, adds helper functions that future RLS policies for
-- the new batch/permission tables will use, and enables pg_cron for the
-- batch rotation job.
--
-- Run this AFTER 15_fix_security_definer_views.sql
-- ============================================================================

-- ── 1. Ensure pg_cron is available (Supabase enables this by default) ─────────
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ── 2. Make audit_logs insert-only from the app (no app-level deletes) ────────
-- (The insert policy already exists in 02_policies.sql; we tighten it to
--  require actor_id = auth.uid() so a user cannot log fake actions for others.)
DROP POLICY IF EXISTS "audit_logs_insert_auth" ON audit_logs;
CREATE POLICY "audit_logs_insert_auth" ON audit_logs
    FOR INSERT WITH CHECK (
        auth.uid() = actor_id
        AND actor_id IS NOT NULL
    );

-- No app-level DELETE on audit_logs — only service-role (background scripts).
DROP POLICY IF EXISTS "audit_logs_delete" ON audit_logs;

-- ── 3. Helper function: user_has_permission() ─────────────────────────────────
-- Used by new RLS policies in 17_batch_system.sql.
-- Returns TRUE if the calling user has the given permission key in
-- user_permissions (added in migration 17).
-- We define it now as a forward reference so policies can reference it.
CREATE OR REPLACE FUNCTION user_has_permission(p_user_id UUID, p_key TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM user_permissions
        WHERE user_id = p_user_id
          AND permission_key = p_key
    );
$$;

-- ── 4. Helper function: get_user_batch_id() ───────────────────────────────────
-- Returns the batch_id for any user. Used in RLS policies to scope reads
-- to the same batch.
CREATE OR REPLACE FUNCTION get_user_batch_id(p_user_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT batch_id FROM users WHERE id = p_user_id LIMIT 1;
$$;

-- ── 5. OTP rate-limit guard (application-side helper) ─────────────────────────
-- Supabase Auth's built-in rate limiting should be configured in the dashboard
-- (Auth → Settings → Rate Limits → OTP: 5 per hour per email).
-- This table records explicit OTP send events for additional audit visibility.
CREATE TABLE IF NOT EXISTS otp_rate_log (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT        NOT NULL,
    sent_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_rate_log_email_time
    ON otp_rate_log (email, sent_at DESC);

-- Clean up log entries older than 24 hours (keep the table small)
SELECT cron.schedule(
    'clean-otp-rate-log',
    '0 * * * *',   -- every hour
    $$DELETE FROM otp_rate_log WHERE sent_at < NOW() - INTERVAL '24 hours'$$
);

-- ── 6. Success ─────────────────────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration 16 complete: Security Hardening';
    RAISE NOTICE '  - audit_logs insert policy tightened';
    RAISE NOTICE '  - user_has_permission() helper created';
    RAISE NOTICE '  - get_user_batch_id() helper created';
    RAISE NOTICE '  - otp_rate_log table + pg_cron cleanup added';
    RAISE NOTICE 'NEXT: Run 17_batch_system.sql';
    RAISE NOTICE '========================================';
END $$;
