-- ============================================================
-- PSGMX Migration 51 — Logical identity hardening for features
-- added after the original identity migration.
-- ============================================================
-- A student can authenticate with either their personal or college address.
-- Both auth identities resolve to one public.users row through
-- current_user_id(). Lineage requests and Community Board policies were
-- introduced later and accidentally returned to auth.uid(), which rejected
-- the second identity and could write the wrong owner id from mobile.

BEGIN;

DROP POLICY IF EXISTS "lineage_requests_student_read"
  ON public.lineage_requests;
DROP POLICY IF EXISTS "lineage_requests_student_insert"
  ON public.lineage_requests;
DROP POLICY IF EXISTS "lineage_requests_alumni_read"
  ON public.lineage_requests;
DROP POLICY IF EXISTS "lineage_requests_alumni_respond"
  ON public.lineage_requests;

CREATE POLICY "lineage_requests_student_read"
  ON public.lineage_requests FOR SELECT TO authenticated
  USING (student_id = public.current_user_id());

CREATE POLICY "lineage_requests_student_insert"
  ON public.lineage_requests FOR INSERT TO authenticated
  WITH CHECK (student_id = public.current_user_id());

CREATE POLICY "lineage_requests_alumni_read"
  ON public.lineage_requests FOR SELECT TO authenticated
  USING (alumni_id = public.current_user_id());

CREATE POLICY "lineage_requests_alumni_respond"
  ON public.lineage_requests FOR UPDATE TO authenticated
  USING (alumni_id = public.current_user_id())
  WITH CHECK (
    alumni_id = public.current_user_id()
    AND status IN ('accepted', 'declined', 'redirected')
  );

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
    senior.id,
    senior.name,
    senior.reg_no,
    senior.avatar_url,
    senior.current_company,
    senior.current_role_title,
    senior.linkedin_url,
    senior.email,
    senior.mentorship_open,
    lineage.senior_quote,
    lineage.assigned_at
  FROM public.lineage_map lineage
  JOIN public.users senior ON senior.id = lineage.senior_user_id
  WHERE lineage.student_id = public.current_user_id();
$$;

REVOKE ALL ON FUNCTION public.get_my_lineage() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_lineage() TO authenticated;

DROP POLICY IF EXISTS "collaboration_posts_select"
  ON public.collaboration_posts;
DROP POLICY IF EXISTS "collaboration_posts_moderate"
  ON public.collaboration_posts;
DROP POLICY IF EXISTS "collaboration_posts_insert_own"
  ON public.collaboration_posts;
DROP POLICY IF EXISTS "collaboration_posts_update_own"
  ON public.collaboration_posts;

CREATE POLICY "collaboration_posts_select"
  ON public.collaboration_posts FOR SELECT TO authenticated
  USING (
    is_active = true
    AND (
      moderation_status = 'approved'
      OR posted_by = public.current_user_id()
    )
    AND (
      visibility = 'department'
      OR posted_by = public.current_user_id()
      OR EXISTS (
        SELECT 1
        FROM public.users viewer, public.users author
        WHERE viewer.id = public.current_user_id()
          AND author.id = collaboration_posts.posted_by
          AND visibility = 'batch'
          AND viewer.batch_id = author.batch_id
      )
      OR (
        visibility = 'lineage_only'
        AND EXISTS (
          SELECT 1
          FROM public.lineage_map lineage
          WHERE (
            lineage.student_id = public.current_user_id()
            AND lineage.senior_user_id = collaboration_posts.posted_by
          ) OR (
            lineage.senior_user_id = public.current_user_id()
            AND lineage.student_id = collaboration_posts.posted_by
          )
        )
      )
    )
  );

CREATE POLICY "collaboration_posts_moderate"
  ON public.collaboration_posts FOR SELECT TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.is_placement_rep(public.current_user_id())
  );

CREATE POLICY "collaboration_posts_insert_own"
  ON public.collaboration_posts FOR INSERT TO authenticated
  WITH CHECK (posted_by = public.current_user_id());

CREATE POLICY "collaboration_posts_update_own"
  ON public.collaboration_posts FOR UPDATE TO authenticated
  USING (posted_by = public.current_user_id())
  WITH CHECK (posted_by = public.current_user_id());

CREATE OR REPLACE FUNCTION public.moderate_collaboration_post(
  p_post_id UUID,
  p_hide BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
BEGIN
  IF NOT (
    public.is_faculty_or_hod(v_actor)
    OR public.is_placement_rep(v_actor)
  ) THEN
    RAISE EXCEPTION 'Not authorized to moderate the community board';
  END IF;

  UPDATE public.collaboration_posts
  SET moderation_status = CASE WHEN p_hide THEN 'hidden' ELSE 'approved' END,
      moderated_by = v_actor,
      moderated_at = now()
  WHERE id = p_post_id;
END;
$$;

REVOKE ALL ON FUNCTION public.moderate_collaboration_post(UUID, BOOLEAN)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderate_collaboration_post(UUID, BOOLEAN)
  TO authenticated;

-- Migrations 41-47 introduced more mobile functions and policies after the
-- original dual-email identity rollout. Recompile those function bodies so
-- their caller checks resolve the same logical profile as the rest of PSGMX.
DO $$
DECLARE
  v_function REGPROCEDURE;
BEGIN
  FOREACH v_function IN ARRAY ARRAY[
    'public.get_my_squad()'::regprocedure,
    'public.get_my_juniors()'::regprocedure,
    'public.set_squad_objective(uuid,text)'::regprocedure,
    'public.start_adaptive_sprint(uuid,text,smallint)'::regprocedure,
    'public.submit_adaptive_sprint(uuid,uuid,jsonb)'::regprocedure
  ]
  LOOP
    EXECUTE replace(
      pg_get_functiondef(v_function),
      'auth.uid()',
      'public.current_user_id()'
    );
  END LOOP;
END;
$$;

DROP POLICY IF EXISTS "sprint_attempts_read_own"
  ON public.sprint_attempts;
CREATE POLICY "sprint_attempts_read_own"
  ON public.sprint_attempts FOR SELECT TO authenticated
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "sprint_revisit_read_own"
  ON public.sprint_revisit_queue;
CREATE POLICY "sprint_revisit_read_own"
  ON public.sprint_revisit_queue FOR SELECT TO authenticated
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "device_tokens_own_read" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_own_write" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_own_update" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_own_delete" ON public.device_tokens;

CREATE POLICY "device_tokens_own_read"
  ON public.device_tokens FOR SELECT TO authenticated
  USING (user_id = public.current_user_id());
CREATE POLICY "device_tokens_own_write"
  ON public.device_tokens FOR INSERT TO authenticated
  WITH CHECK (user_id = public.current_user_id());
CREATE POLICY "device_tokens_own_update"
  ON public.device_tokens FOR UPDATE TO authenticated
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());
CREATE POLICY "device_tokens_own_delete"
  ON public.device_tokens FOR DELETE TO authenticated
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "placement_attendance_write"
  ON public.placement_attendance;
CREATE POLICY "placement_attendance_write"
  ON public.placement_attendance FOR ALL TO authenticated
  USING (
    public.user_has_permission(
      public.current_user_id(),
      'mark_placement_attendance'
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.placement_sessions session
      WHERE session.id = placement_attendance.session_id
        AND session.is_locked = true
    )
  )
  WITH CHECK (
    public.user_has_permission(
      public.current_user_id(),
      'mark_placement_attendance'
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.placement_sessions session
      WHERE session.id = placement_attendance.session_id
        AND session.is_locked = true
    )
  );

COMMIT;
