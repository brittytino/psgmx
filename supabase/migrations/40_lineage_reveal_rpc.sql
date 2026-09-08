-- ============================================================
-- PSGMX Migration 40 — 40_lineage_reveal_rpc.sql
-- ============================================================
-- The mobile Community tab has a "Your MX lineage" section with real
-- lineage_map rows (seeded in 39_seed_alumni_and_lineage.sql) but no way to
-- read them: RLS on `users` has no "read any student's public profile"
-- policy, so a direct client-side join from lineage_map to users returns
-- nothing for a senior outside the junior's own team.
--
-- This RPC is scoped by `lm.student_id = auth.uid()` in the query itself,
-- so it can only ever reveal the caller's own assigned senior — never an
-- arbitrary user's profile. That keeps the existing `users` RLS untouched.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_lineage()
RETURNS TABLE (
  senior_user_id UUID,
  senior_name TEXT,
  senior_reg_no TEXT,
  senior_avatar_url TEXT,
  senior_current_company TEXT,
  senior_current_role_title TEXT,
  senior_linkedin_url TEXT,
  senior_email TEXT,
  senior_mentorship_open BOOLEAN,
  senior_quote TEXT,
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
    u.avatar_url,
    u.current_company,
    u.current_role_title,
    u.linkedin_url,
    u.email,
    u.mentorship_open,
    lm.senior_quote,
    lm.assigned_at
  FROM public.lineage_map lm
  JOIN public.users u ON u.id = lm.senior_user_id
  WHERE lm.student_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_lineage() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_lineage() TO authenticated;
