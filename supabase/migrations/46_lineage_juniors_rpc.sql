-- ============================================================
-- PSGMX Migration 46 — 46_lineage_juniors_rpc.sql
-- ============================================================
-- apps/web/app/alumni/lineage/page.tsx ("Juniors Assigned to You") and
-- apps/web/app/student/lineage/page.tsx both read `lineage_map` and `users`
-- directly from the browser client. Same root problem migration 40 already
-- fixed for the student side: RLS on `users` has no policy letting an
-- alumnus read an arbitrary junior's row (or vice versa) — only "own row",
-- PR/coordinator/faculty, or the legacy same-team_id path. Both pages'
-- client-side "fallback: guess by register-suffix" queries hit the exact
-- same wall and also return nothing for a real user.
--
-- get_my_lineage() (migration 40) already covers "my senior" for any
-- caller (student or alumnus) with a lineage_map row as the student side.
-- This adds the missing other direction: "students assigned to me as their
-- senior" — scoped by `lm.senior_user_id = auth.uid()` exactly like
-- get_my_lineage() is scoped by `lm.student_id = auth.uid()`, so an
-- alumnus can only ever see their own assigned juniors.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_juniors()
RETURNS TABLE (
  junior_user_id UUID,
  junior_name TEXT,
  junior_reg_no TEXT,
  junior_email TEXT,
  junior_linkedin_url TEXT,
  junior_current_company TEXT,
  junior_current_role_title TEXT,
  assigned_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.id,
    u.name,
    u.reg_no,
    u.email,
    u.linkedin_url,
    u.current_company,
    u.current_role_title,
    lm.assigned_at
  FROM public.lineage_map lm
  JOIN public.users u ON u.id = lm.student_id
  WHERE lm.senior_user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_juniors() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_juniors() TO authenticated;
