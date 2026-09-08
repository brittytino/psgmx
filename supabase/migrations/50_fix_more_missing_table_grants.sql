-- ============================================================
-- PSGMX Migration 50 — 50_fix_more_missing_table_grants.sql
-- ============================================================
-- Migration 49 fixed 4 tables missing their required table-level GRANT.
-- Querying the LIVE production database directly (via PostgREST) for every
-- table that exists in any migration turned up a much larger, pre-existing
-- version of the same problem: migration 09_grants_security.sql's
-- `ALTER DEFAULT PRIVILEGES FOR ROLE postgres ... GRANT ... TO authenticated`
-- was meant to auto-grant every future table, but it empirically has not
-- been taking effect for tables created in later migrations (whichever
-- role actually executes a pasted SQL Editor migration evidently doesn't
-- match `FOR ROLE postgres` closely enough for Postgres to apply it) —
-- confirmed by the fact that even the SERVICE ROLE key gets 42501
-- "permission denied" on these tables, which no RLS policy can explain.
--
-- These 10 tables had ZERO grant statements anywhere in the migration
-- history (verified by grep across every migration, not just assumed):
-- ai_conversations, ai_messages, assessment_blueprints, code_submissions,
-- communication_attempts, communication_prompt_bank,
-- ecampus_weekly_timetable, leetcode_stat_snapshots, mentor_assignments,
-- quests. In production, right now, this means: no student can read their
-- own CodeBox submission or communication-practice history, the Communication
-- Practice prompt list can't even be fetched (by anyone, including the
-- server-side API route using service_role), eCampus timetable sync/reads
-- fail, the AI Senior conversation history can't be saved or read, and PRs
-- can't list/pause their own quests (this session's new feature).
--
-- Verb sets below match each table's existing RLS policies exactly (a
-- `FOR ALL` policy needs the full CRUD grant since RLS is what narrows it
-- down per-row from there; a `FOR SELECT`-only policy set means writes are
-- intentionally server-side/service-role-only, so authenticated gets SELECT
-- only and service_role gets everything).
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.ai_conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.ai_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.assessment_blueprints TO authenticated;
GRANT SELECT ON TABLE public.code_submissions TO authenticated;
GRANT SELECT ON TABLE public.communication_attempts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.communication_prompt_bank TO authenticated;
GRANT SELECT ON TABLE public.ecampus_weekly_timetable TO authenticated;
GRANT SELECT ON TABLE public.leetcode_stat_snapshots TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.mentor_assignments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.quests TO authenticated;

GRANT ALL PRIVILEGES ON TABLE public.ai_conversations TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.ai_messages TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.assessment_blueprints TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.code_submissions TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.communication_attempts TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.communication_prompt_bank TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.ecampus_weekly_timetable TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.leetcode_stat_snapshots TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.mentor_assignments TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.quests TO postgres, service_role;

-- The already-correct column-level REVOKEs in 26_codebox_rls_hardening.sql
-- (REVOKE INSERT, UPDATE, DELETE ON code_submissions/communication_attempts
-- FROM authenticated) remain in effect — re-running them here is harmless
-- and documents the intent alongside the fix, since REVOKE on a privilege
-- that was never granted is a no-op, not an error.
REVOKE INSERT, UPDATE, DELETE ON TABLE public.code_submissions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.communication_attempts FROM authenticated;
