-- ============================================================
-- PSGMX — 40_private_progress_guardrails.sql
-- Named progress is private. Staff analytics must be aggregate-only and
-- served by explicitly authorized server routes.
-- ============================================================

BEGIN;

-- Students may read their own roster row. Member managers keep access through
-- the existing manage-members policies; ordinary batch membership is not a
-- reason to expose roster emails or dates of birth.
DROP POLICY IF EXISTS "whitelist_read_all" ON public.whitelist;
DROP POLICY IF EXISTS "whitelist_read_own" ON public.whitelist;
CREATE POLICY "whitelist_read_own" ON public.whitelist
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = public.current_user_id()
      AND u.reg_no = whitelist.reg_no
  )
);

-- Remove staff/representative access to named readiness and streak rows.
-- Aggregate staff insight is computed server-side with service-role access.
DROP POLICY IF EXISTS "readiness_read_admin" ON public.readiness_scores;
DROP POLICY IF EXISTS "streaks_read_admin" ON public.daily_five_streaks;

-- LeetCode evidence is user-owned. The former policies allowed every signed-in
-- user to read and overwrite the entire cohort table.
DROP POLICY IF EXISTS "leetcode_stats_read_all" ON public.leetcode_stats;
DROP POLICY IF EXISTS "leetcode_stats_manage_auth" ON public.leetcode_stats;
DROP POLICY IF EXISTS leetcode_batch_boundary ON public.leetcode_stats;
DROP POLICY IF EXISTS "leetcode_stats_read_own" ON public.leetcode_stats;
DROP POLICY IF EXISTS "leetcode_stats_insert_own" ON public.leetcode_stats;
DROP POLICY IF EXISTS "leetcode_stats_update_own" ON public.leetcode_stats;

CREATE POLICY "leetcode_stats_read_own" ON public.leetcode_stats
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = public.current_user_id()
      AND lower(u.leetcode_username) = lower(leetcode_stats.username)
  )
);

CREATE POLICY "leetcode_stats_insert_own" ON public.leetcode_stats
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = public.current_user_id()
      AND lower(u.leetcode_username) = lower(leetcode_stats.username)
  )
);

CREATE POLICY "leetcode_stats_update_own" ON public.leetcode_stats
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = public.current_user_id()
      AND lower(u.leetcode_username) = lower(leetcode_stats.username)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = public.current_user_id()
      AND lower(u.leetcode_username) = lower(leetcode_stats.username)
  )
);

COMMIT;
