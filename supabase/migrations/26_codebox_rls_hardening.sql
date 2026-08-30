-- ============================================================
-- PSGMX Migration 26 — CodeBox and communication RLS hardening
-- ============================================================

BEGIN;

DROP POLICY IF EXISTS "Students view published quests for their batch" ON public.quests;
DROP POLICY IF EXISTS "Authors can manage their own quests" ON public.quests;
DROP POLICY IF EXISTS "PR can manage quests for their batch" ON public.quests;
DROP POLICY IF EXISTS "Students view their own submissions" ON public.code_submissions;
DROP POLICY IF EXISTS "Students insert their own submissions" ON public.code_submissions;
DROP POLICY IF EXISTS "Faculty view submissions for recovery cases" ON public.code_submissions;
DROP POLICY IF EXISTS "Students manage their own communication attempts" ON public.communication_attempts;
DROP POLICY IF EXISTS "Faculty view for mentoring review" ON public.communication_attempts;

CREATE POLICY quests_students_targeted_read ON public.quests
  FOR SELECT TO authenticated USING (
    status = 'published'
    AND (available_from IS NULL OR available_from <= now())
    AND (target_batch_id IS NULL OR target_batch_id = public.get_user_batch_id(public.current_user_id()))
    AND (
      cardinality(target_team_ids) = 0
      OR (SELECT u.team_uuid FROM public.users u WHERE u.id = public.current_user_id()) = ANY(target_team_ids)
    )
  );

CREATE POLICY quests_authors_manage ON public.quests
  FOR ALL TO authenticated
  USING (authored_by = public.current_user_id())
  WITH CHECK (authored_by = public.current_user_id());

CREATE POLICY quests_pr_batch_manage ON public.quests
  FOR ALL TO authenticated
  USING (
    public.user_has_permission(public.current_user_id(), 'publish_quests')
    AND (target_batch_id IS NULL OR target_batch_id = public.get_user_batch_id(public.current_user_id()))
  )
  WITH CHECK (
    public.user_has_permission(public.current_user_id(), 'publish_quests')
    AND (target_batch_id IS NULL OR target_batch_id = public.get_user_batch_id(public.current_user_id()))
  );

CREATE POLICY submissions_students_read_own ON public.code_submissions
  FOR SELECT TO authenticated USING (student_id = public.current_user_id());

CREATE POLICY submissions_faculty_read_assigned ON public.code_submissions
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.mentor_assignments ma
      WHERE ma.student_id = code_submissions.student_id
        AND ma.mentor_id = public.current_user_id() AND ma.active
    )
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = public.current_user_id() AND u.role_label = 'HOD'
    )
  );

CREATE POLICY communication_students_read_own ON public.communication_attempts
  FOR SELECT TO authenticated USING (student_id = public.current_user_id());

CREATE POLICY communication_faculty_read_assigned ON public.communication_attempts
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.mentor_assignments ma
      WHERE ma.student_id = communication_attempts.student_id
        AND ma.mentor_id = public.current_user_id() AND ma.active
    )
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = public.current_user_id() AND u.role_label = 'HOD'
    )
  );

REVOKE INSERT, UPDATE, DELETE ON public.code_submissions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.communication_attempts FROM authenticated;

COMMIT;
