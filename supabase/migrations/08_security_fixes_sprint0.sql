-- ============================================================
-- PSGMX — 08_security_fixes_sprint0.sql
-- Sprint 0 security fixes (PSGMX_Final_Production_Plan.md, Section 3).
--
-- IMPORTANT — written against the database as VERIFIED LIVE via direct
-- read-only introspection (service_role + anon probes against
-- ucmskbgdpnolnyrmkotz.supabase.co), NOT against either
-- `supabase/migrations/00-07_*.sql` or `apps/mobile/database/01_MASTER_SETUP.sql`.
-- Both of those files were found to diverge from production:
--   - `supabase/migrations/01_rls_policies.sql` depends on a `get_user_role()`
--     function and `role`/`app_role` columns that DO NOT EXIST live.
--   - The live `users` table actually has: reg_no, name, roles (JSONB of
--     student sub-flags), batch, batch_id, role_label (TEXT: 'Student',
--     'Faculty', 'Alumni', presumably 'HOD'), ecampus_password(_set), etc.
--   - `fyp_projects`, `mock_exam_results`, `readiness_score_history`, and
--     `knowledge_brain_articles` do not exist live at all — Section 3's S4
--     (FYP RLS) has no table to fix yet; deferred to whichever sprint
--     builds FYP tracking as a new feature, not patched here.
--   - `audit_logs` already exists live (columns: action, actor_id,
--     created_at, entity_id, entity_type, id, metadata) — created by some
--     prior direct change not captured in either repo file. This
--     migration does NOT recreate it, only adds/confirms its policy.
--
-- Covers:
--   S1 — eCampus password stored/exposed in plain text.
--        Decision: KEEP the eCampus/bunker feature, fix only the storage
--        hole (full Vault-based rebuild stays deferred to v1.1).
--   S6 — audit_logs read policy, scoped with the live role_label column.
--
-- Run in staging first.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- STEP 1 — eCampus password: move off `users`, encrypt at rest,
-- remove column-level readability for any client role.
--
-- Verified live: an anon-key request for `users.ecampus_password`
-- returns 200 (not a permission error), which means no column-level
-- protection exists today — any RLS-visible row that includes this
-- column in a SELECT leaks the plaintext password to whatever client
-- issued the query (e.g. a bare `.select()` used by faculty/placement-
-- rep screens that list all students — see accompanying code fixes in
-- apps/mobile/lib/services/supabase_db_service.dart and the three
-- apps/web/app/{api/user/profile,super-admin/students,super-admin/faculty}
-- routes, all of which used `select('*')`/bare `select()` and would have
-- broken under the REVOKE below without those fixes).
-- ──────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS user_ecampus_credentials (
  user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  encrypted_password  BYTEA NOT NULL,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Deliberately NO RLS policies below this line for this table.
-- With RLS enabled and zero policies, `authenticated`/`anon` get zero
-- rows and zero columns — the only way in is `service_role` (used by
-- ecampus_api.py), which bypasses RLS entirely. This is intentionally
-- stricter than a `USING (false)` policy: there is no policy to misread.
ALTER TABLE user_ecampus_credentials ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE user_ecampus_credentials IS
  'eCampus portal password, encrypted with pgcrypto (pgp_sym_encrypt). '
  'No RLS policies granted to authenticated/anon — service_role only. '
  'The encryption key is a database-level setting (app.ecampus_encryption_key), '
  'set once by an admin via ALTER DATABASE ... SET — never shipped to the '
  'mobile app, the web app, or the ecampus_api.py service env. Only the '
  'SECURITY DEFINER functions below ever read it.';

-- Fetches the shared key from a DB-level setting so no client (mobile,
-- web, or the Python service) ever needs to hold or transmit it.
-- Set once per environment, e.g.:
--   ALTER DATABASE postgres SET app.ecampus_encryption_key = '<random-secret>';
-- (requires a session reconnect / new connection to take effect).
CREATE OR REPLACE FUNCTION _ecampus_encryption_key()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT current_setting('app.ecampus_encryption_key', true);
$$;

REVOKE ALL ON FUNCTION _ecampus_encryption_key() FROM PUBLIC;

-- SECURITY DEFINER RPC so a student can set/clear their OWN password
-- from the mobile app without ever giving the client role table access,
-- and without the client ever handling the encryption key.
CREATE OR REPLACE FUNCTION set_ecampus_password(p_password TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_key TEXT := _ecampus_encryption_key();
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_password IS NULL OR btrim(p_password) = '' THEN
    DELETE FROM user_ecampus_credentials WHERE user_id = auth.uid();
    UPDATE users SET ecampus_password_set = false WHERE id = auth.uid();
    RETURN;
  END IF;

  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'eCampus encryption key is not configured on this database';
  END IF;

  INSERT INTO user_ecampus_credentials (user_id, encrypted_password, updated_at)
  VALUES (auth.uid(), pgp_sym_encrypt(btrim(p_password), v_key), now())
  ON CONFLICT (user_id)
  DO UPDATE SET encrypted_password = EXCLUDED.encrypted_password, updated_at = now();

  UPDATE users SET ecampus_password_set = true WHERE id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION set_ecampus_password(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION set_ecampus_password(TEXT) TO authenticated;

-- Server-side lookups for ecampus_api.py, called with the service_role
-- key. Exposed as RPCs (not a raw table read) since the encrypted value
-- never needs to leave Postgres in its encrypted form, and the service
-- never needs to know the encryption key either.
CREATE OR REPLACE FUNCTION get_ecampus_password(p_reg_no TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_encrypted BYTEA;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE reg_no = p_reg_no;
  IF v_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT encrypted_password INTO v_encrypted
  FROM user_ecampus_credentials WHERE user_id = v_user_id;

  IF v_encrypted IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN pgp_sym_decrypt(v_encrypted, _ecampus_encryption_key());
END;
$$;

REVOKE ALL ON FUNCTION get_ecampus_password(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_ecampus_password(TEXT) TO service_role;

-- Bulk variant for the whitelist sync job (avoids one round trip per
-- student — mirrors the existing bulk-fetch shape in ecampus_api.py).
CREATE OR REPLACE FUNCTION get_ecampus_passwords_bulk()
RETURNS TABLE(reg_no TEXT, password TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.reg_no, pgp_sym_decrypt(c.encrypted_password, _ecampus_encryption_key())
  FROM user_ecampus_credentials c
  JOIN users u ON u.id = c.user_id
  WHERE u.reg_no IS NOT NULL;
$$;

REVOKE ALL ON FUNCTION get_ecampus_passwords_bulk() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_ecampus_passwords_bulk() TO service_role;

-- Defense in depth: even before the column is dropped, no client role
-- should be able to read it directly (this is the exact gap S1 found).
REVOKE SELECT (ecampus_password) ON public.users FROM authenticated;
REVOKE SELECT (ecampus_password) ON public.users FROM anon;

-- ── MANUAL FOLLOW-UP (run after verifying the above in staging) ──
-- 0. Set the encryption key once per environment (a long random secret,
--    generated by you, not committed anywhere):
--      ALTER DATABASE postgres SET app.ecampus_encryption_key = '<random-secret>';
--    then start a NEW connection (existing pooled connections won't see it).
-- 1. Backfill existing plaintext passwords into the new table:
--      INSERT INTO user_ecampus_credentials (user_id, encrypted_password)
--      SELECT id, pgp_sym_encrypt(ecampus_password, current_setting('app.ecampus_encryption_key'))
--      FROM users
--      WHERE ecampus_password IS NOT NULL AND ecampus_password <> ''
--      ON CONFLICT (user_id) DO NOTHING;
-- 2. Confirm ecampus_api.py has been redeployed to read from
--    user_ecampus_credentials (see accompanying code change) BEFORE
--    dropping the old column, or students with a custom password will
--    silently fall back to their DOB-derived password.
-- 3. Only then:
--      ALTER TABLE users DROP COLUMN IF EXISTS ecampus_password;

-- ──────────────────────────────────────────────────────────────
-- STEP 2 — audit_logs (S6): the table already exists live with columns
-- (action, actor_id, created_at, entity_id, entity_type, id, metadata)
-- and RLS is already enabled (verified: anon gets zero rows even though
-- 2 rows exist for service_role). This only (re)asserts the intended
-- read policy using the live role_label column, since `get_user_role()`
-- does not exist in this database.
-- ──────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS audit_logs_select_faculty_hod ON audit_logs;
CREATE POLICY audit_logs_select_faculty_hod ON audit_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')
    )
  );

-- No INSERT/UPDATE/DELETE policy for any client role is added — only
-- SECURITY DEFINER functions (which bypass RLS) should write here. If an
-- authenticated-role INSERT/UPDATE/DELETE policy already exists on this
-- table from whatever created it, it should be reviewed and likely
-- dropped — please check in the Supabase dashboard (Table Editor →
-- audit_logs → RLS policies) since this migration can't see policies it
-- didn't create.

-- ──────────────────────────────────────────────────────────────
-- DEFERRED — NOT part of this migration:
-- S4 (FYP RLS) has no live table to fix (`fyp_projects` doesn't exist).
-- Per your decision, FYP tracking gets built as a new feature — including
-- its own RLS from day one, scoped by role_label — whenever that sprint
-- comes up, not patched here.
-- ──────────────────────────────────────────────────────────────
