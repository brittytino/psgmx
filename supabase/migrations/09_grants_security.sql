-- ============================================================
-- PSGMX — 09_grants_security.sql
-- ============================================================
-- Table/sequence/function-level GRANTs (required for PostgREST access at
-- all — RLS from 08_rls_policies.sql is the row-level layer on top of
-- this, not a replacement for it), followed by the specific column-level
-- REVOKEs that protect secrets/answer-keys even though the table itself is
-- broadly granted.
--
-- Replaces the old supabase/fix-permissions.sql, which did a blanket
-- `GRANT ALL ON ALL TABLES ... TO anon, authenticated` with NO follow-up
-- column REVOKEs — that re-opens the eCampus-password and quiz-answer-key
-- leaks below if it is ever run after this file. Do not reintroduce it.
--
-- Run AFTER 08_rls_policies.sql.
-- ============================================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO postgres, service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA public TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT EXECUTE ON ROUTINES TO authenticated;

-- anon gets nothing table-level by default in this rebuild — the mobile
-- and web apps always operate as `authenticated` post-login. The handful
-- of views the old schema explicitly opened to anon are re-opened here
-- (their RLS/definition already scopes them to nothing useful without a
-- real auth.uid(), so this is a safe no-op for anonymous callers, not an
-- actual data exposure).
GRANT SELECT ON student_attendance_summary   TO anon;
GRANT SELECT ON v_ecampus_attendance_summary TO anon;
GRANT SELECT ON v_ecampus_cgpa_summary       TO anon;
GRANT SELECT ON ca_timetable_global          TO anon;
GRANT SELECT ON app_config                   TO anon;

-- ──────────────────────────────────────────────────────────────
-- Column-level REVOKEs — secrets and answer keys never reach a client,
-- even though the table itself is broadly granted above.
-- ──────────────────────────────────────────────────────────────

-- eCampus password: legacy plaintext column (kept for backward-compat
-- reads by service_role only — the real secret lives in
-- user_ecampus_credentials, written via set_ecampus_password()).
REVOKE SELECT (ecampus_password) ON public.users FROM authenticated;
REVOKE SELECT (ecampus_password) ON public.users FROM anon;

-- Daily Five answer key — students may read a question's options but
-- never correct_option before submitting. get_question_bank_full() and
-- get_daily_five_results() (SECURITY DEFINER) are the only sanctioned ways
-- to see it, per the checks already inside those functions.
REVOKE SELECT (correct_option) ON public.question_bank FROM authenticated;

-- Mock exam answer key — same pattern; get_mock_exam_question_with_answer()
-- and submit_exam_server_side() are the only sanctioned paths.
REVOKE SELECT (correct_option) ON public.mock_exam_questions FROM authenticated;

COMMENT ON COLUMN public.users.ecampus_password IS
  'Legacy plaintext eCampus password column. NEVER exposed to the client — '
  'readable only by service_role. Prefer user_ecampus_credentials '
  '(pgp_sym_encrypt-encrypted, via set_ecampus_password()/get_ecampus_password()).';

-- ──────────────────────────────────────────────────────────────
-- Bootstrap: grant permission-table entries to whoever already carries the
-- corresponding roles JSONB flag. No-op on a freshly seeded database (no
-- `users` rows exist yet — those are created on first login, not by seed),
-- but keeps this migration safe to re-run later against a populated DB.
-- ──────────────────────────────────────────────────────────────

INSERT INTO user_permissions (user_id, permission_key)
SELECT u.id, p.key
FROM users u
CROSS JOIN (VALUES
    ('manage_members'), ('configure_teams'), ('schedule_placement_sessions'),
    ('mark_placement_attendance'), ('publish_tasks'), ('manage_company_records'),
    ('moderate_placement_log'), ('view_batch_analytics')
) AS p(key)
WHERE (u.roles->>'isPlacementRep')::boolean = TRUE
ON CONFLICT DO NOTHING;

INSERT INTO user_permissions (user_id, permission_key)
SELECT u.id, 'mark_placement_attendance'
FROM users u
WHERE (u.roles->>'isTeamLeader')::boolean = TRUE
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE '✅ 09_grants_security.sql complete — grants applied, secrets locked down.';
    RAISE NOTICE 'Schema build is done. NEXT: run 10_seed_batches.sql';
END $$;
