-- ============================================================
-- PSGMX Migration 32 — Mentor Assignments Hardening
-- Adds bulk assignment and PR-specific assign RPC
-- ============================================================

-- ── PR-only: assign mentor to student in own batch ──────────────────────────
-- The existing assign_student_mentor() already handles PRs if they have
-- manage_members permission. This migration adds a convenience wrapper and
-- a bulk auto-assign function.

CREATE OR REPLACE FUNCTION public.pr_assign_mentor(
  p_student_id UUID,
  p_mentor_id  UUID,
  p_focus_areas TEXT[] DEFAULT '{}'
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delegates to the canonical assign_student_mentor which enforces all guards
  RETURN public.assign_student_mentor(p_student_id, p_mentor_id, p_focus_areas);
END;
$$;

REVOKE ALL ON FUNCTION public.pr_assign_mentor(UUID, UUID, TEXT[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.pr_assign_mentor(UUID, UUID, TEXT[]) TO authenticated;

-- ── Bulk auto-assign: round-robin faculty across all unassigned students ──────
CREATE OR REPLACE FUNCTION public.pr_bulk_assign_mentors(
  p_batch_id UUID DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor       UUID := public.current_user_id();
  v_batch_id    UUID;
  v_faculty     UUID[];
  v_unassigned  UUID[];
  v_fac_count   INT;
  v_idx         INT := 0;
  v_student     UUID;
  v_assigned    INT := 0;
BEGIN
  -- Resolve batch
  IF p_batch_id IS NOT NULL THEN
    v_batch_id := p_batch_id;
  ELSE
    SELECT batch_id INTO v_batch_id FROM public.users WHERE id = v_actor;
  END IF;

  IF v_batch_id IS NULL THEN RAISE EXCEPTION 'Batch not found'; END IF;

  -- Only PR with manage_members or faculty/HOD can call this
  IF NOT (
    public.is_faculty_or_hod(v_actor)
    OR (
      public.is_placement_rep(v_actor)
      AND public.get_user_batch_id(v_actor) = v_batch_id
      AND public.user_has_permission(v_actor, 'manage_members')
    )
  ) THEN RAISE EXCEPTION 'Not authorized'; END IF;

  -- Load active faculty
  SELECT ARRAY_AGG(id ORDER BY name)
  INTO v_faculty
  FROM public.users
  WHERE role_label IN ('Faculty', 'HOD');

  IF v_faculty IS NULL OR array_length(v_faculty, 1) = 0 THEN
    RETURN jsonb_build_object('assigned', 0, 'message', 'No faculty found');
  END IF;

  v_fac_count := array_length(v_faculty, 1);

  -- Get unassigned students in this batch
  SELECT ARRAY_AGG(u.id ORDER BY u.name)
  INTO v_unassigned
  FROM public.users u
  WHERE u.batch_id = v_batch_id
    AND u.role_label = 'Student'
    AND NOT EXISTS (
      SELECT 1 FROM public.mentor_assignments ma
      WHERE ma.student_id = u.id AND ma.active = TRUE
    );

  IF v_unassigned IS NULL OR array_length(v_unassigned, 1) = 0 THEN
    RETURN jsonb_build_object('assigned', 0, 'message', 'All students already have mentors');
  END IF;

  -- Round-robin assignment
  FOREACH v_student IN ARRAY v_unassigned LOOP
    PERFORM public.assign_student_mentor(
      v_student,
      v_faculty[(v_idx % v_fac_count) + 1],
      '{}'
    );
    v_idx    := v_idx + 1;
    v_assigned := v_assigned + 1;
  END LOOP;

  RETURN jsonb_build_object('assigned', v_assigned, 'faculty_count', v_fac_count);
END;
$$;

REVOKE ALL ON FUNCTION public.pr_bulk_assign_mentors(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.pr_bulk_assign_mentors(UUID) TO authenticated;

-- ── INSERT/UPDATE policy for PR ───────────────────────────────────────────────
DROP POLICY IF EXISTS mentor_assignments_pr_write ON public.mentor_assignments;
CREATE POLICY mentor_assignments_pr_write ON public.mentor_assignments
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_faculty_or_hod(public.current_user_id())
    OR (
      public.is_placement_rep(public.current_user_id())
      AND public.user_has_permission(public.current_user_id(), 'manage_members')
    )
  );

DROP POLICY IF EXISTS mentor_assignments_pr_deactivate ON public.mentor_assignments;
CREATE POLICY mentor_assignments_pr_deactivate ON public.mentor_assignments
  FOR UPDATE TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR (
      public.is_placement_rep(public.current_user_id())
      AND public.user_has_permission(public.current_user_id(), 'manage_members')
      AND batch_id = public.get_user_batch_id(public.current_user_id())
    )
  );

COMMENT ON TABLE public.mentor_assignments IS
  'One-to-one mentorship: each active student has at most one active faculty mentor. '
  'Assigned by PR (manage_members) or Faculty/HOD. All changes are audit-logged by the assign_student_mentor trigger.';
