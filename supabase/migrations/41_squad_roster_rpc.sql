-- ============================================================
-- PSGMX Migration 41 — 41_squad_roster_rpc.sql
-- ============================================================
-- apps/web/app/student/squads/page.tsx already ships a Squads view that
-- reads `users` (by team_uuid), `daily_five_streaks`, and `code_submissions`
-- directly from the client for the caller's squadmates. None of that data is
-- actually visible under existing RLS to anyone but the row owner or an
-- admin role:
--   - users:               only "own row", PR/coordinator/faculty, or a
--                           Team Leader scoped to the legacy team_id/
--                           is_team_leader() path — not team_uuid.
--   - daily_five_streaks:  "streaks_read_own" only.
--   - code_submissions:    "submissions_students_read_own" only.
-- So today the web Squads page silently renders an empty member list for
-- every caller who isn't already covered by one of those existing policies.
--
-- Rather than widen RLS on those three tables (which would let a squadmate
-- craft their own wider `select()` and read sensitive columns this feature
-- never intended to expose — e.g. code_storage_path, ai_evaluation_json,
-- ecampus_password), this ships one SECURITY DEFINER RPC that returns only
-- the specific completion-signal fields PRD Ch. 14.1 describes ("a squad
-- feed of completion updates, not scores"): name, reg number, Team Leader
-- flag, current streak, and verified-quest count — scoped to the caller's
-- own team_uuid only. Both apps/web and apps/mobile should call this
-- instead of the raw table reads.
-- ============================================================

-- PR-set weekly objective (PRD 14.1: "each squad has... a weekly squad
-- objective"). Previously a hardcoded client-side string on both web and
-- mobile — this makes it a real, settable field with a sensible computed
-- fallback for squads the PR hasn't set one for yet.
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS objective TEXT;

CREATE OR REPLACE FUNCTION public.get_my_squad()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_team_uuid UUID;
  v_result JSONB;
  v_member_count INTEGER;
BEGIN
  SELECT team_uuid INTO v_team_uuid FROM public.users WHERE id = auth.uid();
  IF v_team_uuid IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT count(*) INTO v_member_count FROM public.users WHERE team_uuid = v_team_uuid;

  SELECT jsonb_build_object(
    'team_id', t.id,
    'team_name', t.team_name,
    'team_code', t.team_code,
    'objective', COALESCE(
      t.objective,
      format('Complete %s combined CodeBox verified quests and maintain active Daily Five streaks.',
             GREATEST(v_member_count, 1) * 3)
    ),
    'members', COALESCE(jsonb_agg(
      jsonb_build_object(
        'id', u.id,
        'name', u.name,
        'reg_no', u.reg_no,
        'is_team_leader', COALESCE((u.roles->>'isTeamLeader')::boolean, false),
        'current_streak', COALESCE(s.current_streak, 0),
        'verified_quest_count', COALESCE(q.verified_count, 0)
      ) ORDER BY u.name
    ) FILTER (WHERE u.id IS NOT NULL), '[]'::jsonb),
    -- Squad feed (PRD 14.1: "completion updates, not scores") — real
    -- verified-quest-completion events for the team in the last 7 days,
    -- newest first. Deliberately excludes anything score-shaped.
    'feed', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'member_name', fu.name,
        'quest_title', fq.title,
        'completed_at', fc.submitted_at
      ) ORDER BY fc.submitted_at DESC)
      FROM public.code_submissions fc
      JOIN public.users fu ON fu.id = fc.student_id
      JOIN public.quests fq ON fq.id = fc.quest_id
      WHERE fu.team_uuid = v_team_uuid
        AND fc.is_verified_complete = TRUE
        AND fc.submitted_at > now() - INTERVAL '7 days'
      LIMIT 20
    ), '[]'::jsonb)
  )
  INTO v_result
  FROM public.teams t
  LEFT JOIN public.users u ON u.team_uuid = t.id
  LEFT JOIN public.daily_five_streaks s ON s.user_id = u.id
  LEFT JOIN (
    SELECT student_id, COUNT(*) AS verified_count
    FROM public.code_submissions
    WHERE is_verified_complete = TRUE
    GROUP BY student_id
  ) q ON q.student_id = u.id
  WHERE t.id = v_team_uuid
  GROUP BY t.id, t.team_name, t.team_code, t.objective;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_squad() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_squad() TO authenticated;

-- Lets a PR set their batch's squad objectives (mirrors the existing
-- quests_pr_batch_manage RLS pattern: gated on the publish_quests
-- permission, scoped to the PR's own batch).
CREATE OR REPLACE FUNCTION public.set_squad_objective(p_team_id UUID, p_objective TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_team_batch UUID;
BEGIN
  IF NOT public.user_has_permission(auth.uid(), 'publish_quests')
     AND NOT public.is_faculty_or_hod(auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized to set squad objectives';
  END IF;

  SELECT batch_id INTO v_team_batch FROM public.teams WHERE id = p_team_id;
  IF v_team_batch IS NULL THEN
    RAISE EXCEPTION 'Squad not found';
  END IF;
  IF v_team_batch != public.get_user_batch_id(auth.uid()) AND NOT public.is_faculty_or_hod(auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized for this squad''s batch';
  END IF;

  UPDATE public.teams SET objective = NULLIF(trim(p_objective), ''), updated_at = now() WHERE id = p_team_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_squad_objective(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_squad_objective(UUID, TEXT) TO authenticated;
