-- ============================================================
-- PSGMX Migration 49 — 49_fix_missing_table_grants.sql
-- ============================================================
-- Migrations 43-45 created new tables (sprint_attempts,
-- sprint_revisit_queue, device_tokens, lineage_requests), enabled RLS, and
-- added policies — but never added the underlying table-level GRANT that
-- Postgres requires in addition to RLS. RLS policies only decide which
-- ROWS a role can see once it already has table-level access; without a
-- GRANT, Postgres denies the query before RLS is even evaluated
-- ("permission denied for table X"), regardless of how permissive the
-- policies are.
--
-- This was caught by directly querying the live production database (via
-- the PostgREST REST API) after deploying — every one of these four tables
-- returned 42501 "permission denied for table", confirmed via curl, even
-- though the RLS policies were correct. The codebase's own established
-- convention (migration 21: `GRANT SELECT, INSERT, UPDATE ON
-- public.support_cases TO authenticated;`) was simply missed for these four
-- new tables. Concretely this meant, in production, right now:
--   - Adaptive Sprint could never load its own just-created attempt id
--     (adaptive_sprint_screen.dart's direct `sprint_attempts` select).
--   - Lineage requests could never be sent or read (community_screen.dart's
--     insert, mentoring_inbox_screen.dart's select/update).
--   - device_tokens could never be written by a client, and — since the
--     send-push Edge Function also queries it via the service_role key,
--     which likewise had no grant — could never be read server-side either.
-- ============================================================

GRANT SELECT ON TABLE public.sprint_attempts TO authenticated;
GRANT SELECT ON TABLE public.sprint_revisit_queue TO authenticated;
-- Writes to both go exclusively through the SECURITY DEFINER RPCs
-- (start_adaptive_sprint / submit_adaptive_sprint), which run as the
-- function owner and don't need the caller's own table grants — only the
-- direct client-side SELECT (reading back the newly created attempt id)
-- needed this.

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.device_tokens TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.device_tokens TO postgres, service_role;

GRANT SELECT, INSERT, UPDATE ON TABLE public.lineage_requests TO authenticated;
