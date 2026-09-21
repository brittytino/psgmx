-- ============================================================
-- PSGMX Migration 58 — 58_lock_down_leetcode_writes.sql
-- ============================================================
-- `leetcode_stats_insert_own`/`leetcode_stats_update_own`
-- (52_private_progress_guardrails.sql) let an authenticated student write
-- to their own `leetcode_stats` row directly from the client using the
-- anon-key session. Those policies check row OWNERSHIP (the row's username
-- belongs to the caller) but not column VALUES — nothing stops a modified
-- client from setting `total_solved`/`weekly_score` to any number it wants.
-- `readiness_after_leetcode_sync` (15_identity_batch_team_hardening.sql)
-- recomputes the caller's readiness score straight from those columns, so
-- this was a direct path to a self-inflated readiness score.
--
-- docs/user-flow.md 4.5 specifies LeetCode stats are synced server-side
-- only (GitHub Actions -> sync-leetcode Edge Function every 6h). This
-- migration removes the client-writable policies; the only writers left
-- are the `sync-leetcode` Edge Function and the new
-- apps/web/app/api/user/leetcode-sync route, both of which use the
-- service-role client and therefore bypass RLS entirely — service_role
-- was never granted these policies in the first place, so revoking the
-- `authenticated` policies has no effect on either write path.
--
-- Reads are untouched: `leetcode_stats_read_own` /
-- `leetcode_stats_read_faculty_hod` still apply.
-- ============================================================

DROP POLICY IF EXISTS "leetcode_stats_insert_own" ON public.leetcode_stats;
DROP POLICY IF EXISTS "leetcode_stats_update_own" ON public.leetcode_stats;
