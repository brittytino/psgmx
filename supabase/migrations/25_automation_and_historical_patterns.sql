-- ============================================================
-- PSGMX Migration 25 — operational automation and historical evidence
-- ============================================================

BEGIN;

-- Historical batch imports are system-owned records, not invented alumni
-- testimony. Live alumni contributions still require an author.
ALTER TABLE public.interview_patterns
  ALTER COLUMN author_id DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS is_system_archived BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.knowledge_brain_articles
  ALTER COLUMN author_id DROP NOT NULL;

INSERT INTO public.interview_patterns(
  title, pattern_type, historical_context, preparation_helped, mistakes,
  example_themes, advice, company_name, batch_year, approval_status,
  reviewed_at, review_notes, is_system_archived
)
SELECT
  left(c.name || ' · archived ' || b.batch_code || ' selection pattern', 160),
  'general',
  'Archived department record from ' || b.batch_code || '. Recorded selection structure: ' ||
    COALESCE(c.rounds::text, 'not documented') ||
    '. This is historical preparation evidence, not a current drive announcement.',
  'Use the recorded round sequence to choose relevant aptitude, coding, communication, and technical practice.',
  'Do not assume an archived round sequence, eligibility rule, date, or package remains current.',
  ARRAY['historical round structure', 'preparation planning'],
  'Prepare the underlying skills and verify every current official detail in NEO PAT before acting.',
  c.name,
  b.batch_code,
  'approved',
  now(),
  'System migration from archived department company records.',
  true
FROM public.companies c
JOIN public.batches b ON b.id = c.batch_id
WHERE b.batch_code IN ('23MX', '24MX')
  AND NOT EXISTS (
    SELECT 1 FROM public.interview_patterns p
    WHERE p.company_name = c.name AND p.batch_year = b.batch_code AND p.is_system_archived
  );

-- Deterministic server-side squad balancing. Readiness is used only for the
-- ordering and is never returned to the PR.
CREATE OR REPLACE FUNCTION public.auto_assign_unassigned_squads(p_target_size INTEGER DEFAULT 6)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_batch UUID := public.get_user_batch_id(v_actor);
  v_unassigned INTEGER;
  v_existing INTEGER;
  v_required INTEGER;
  v_created INTEGER := 0;
  v_assigned INTEGER := 0;
  v_index INTEGER := 0;
  v_team_index INTEGER;
  v_team_ids UUID[];
  v_student RECORD;
BEGIN
  IF p_target_size < 3 OR p_target_size > 12 THEN
    RAISE EXCEPTION 'Target size must be between 3 and 12';
  END IF;
  IF v_batch IS NULL OR NOT (
    public.is_faculty_or_hod(v_actor)
    OR (public.is_placement_rep(v_actor) AND public.user_has_permission(v_actor, 'configure_teams'))
  ) THEN RAISE EXCEPTION 'Not authorized to configure this batch'; END IF;

  SELECT count(*) INTO v_unassigned FROM public.users
  WHERE batch_id = v_batch AND role_label = 'Student' AND team_uuid IS NULL;
  IF v_unassigned = 0 THEN
    RETURN jsonb_build_object('assigned', 0, 'created', 0, 'message', 'Every student already has a squad.');
  END IF;

  SELECT count(*) INTO v_existing FROM public.teams WHERE batch_id = v_batch;
  v_required := GREATEST(v_existing, CEIL((v_unassigned + (
    SELECT count(*) FROM public.users WHERE batch_id = v_batch AND role_label = 'Student' AND team_uuid IS NOT NULL
  ))::numeric / p_target_size)::integer);

  FOR v_index IN (v_existing + 1)..v_required LOOP
    INSERT INTO public.teams(batch_id, team_name, team_code, target_size)
    VALUES (v_batch, 'Squad ' || lpad(v_index::text, 2, '0'), 'T' || lpad(v_index::text, 2, '0'), p_target_size);
    v_created := v_created + 1;
  END LOOP;

  SELECT array_agg(id ORDER BY team_code) INTO v_team_ids
  FROM public.teams WHERE batch_id = v_batch;
  v_index := 0;
  FOR v_student IN
    SELECT u.id
    FROM public.users u
    LEFT JOIN public.current_readiness_scores r ON r.user_id = u.id
    WHERE u.batch_id = v_batch AND u.role_label = 'Student' AND u.team_uuid IS NULL
    ORDER BY COALESCE(r.score, 0) DESC, u.reg_no
  LOOP
    v_team_index := CASE
      WHEN ((v_index / array_length(v_team_ids, 1)) % 2) = 0
        THEN (v_index % array_length(v_team_ids, 1)) + 1
      ELSE array_length(v_team_ids, 1) - (v_index % array_length(v_team_ids, 1))
    END;
    PERFORM public.assign_team_member(v_student.id, v_team_ids[v_team_index]);
    v_assigned := v_assigned + 1;
    v_index := v_index + 1;
  END LOOP;

  INSERT INTO public.audit_logs(actor_id, action, entity_type, batch_id, metadata)
  VALUES (v_actor, 'SQUADS_AUTO_ASSIGNED', 'batch', v_batch,
          jsonb_build_object('assigned', v_assigned, 'created', v_created, 'target_size', p_target_size));
  RETURN jsonb_build_object('assigned', v_assigned, 'created', v_created);
END;
$$;

REVOKE ALL ON FUNCTION public.auto_assign_unassigned_squads(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auto_assign_unassigned_squads(INTEGER) TO authenticated;

CREATE TABLE IF NOT EXISTS public.assessment_blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
  owner_faculty_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title_prefix TEXT NOT NULL DEFAULT 'Weekly readiness check',
  topics TEXT[] NOT NULL DEFAULT '{}',
  question_count INTEGER NOT NULL DEFAULT 20 CHECK (question_count BETWEEN 5 AND 50),
  duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK (duration_minutes BETWEEN 10 AND 120),
  exams_per_week INTEGER NOT NULL DEFAULT 1 CHECK (exams_per_week BETWEEN 1 AND 2),
  publish_weekday INTEGER NOT NULL DEFAULT 6 CHECK (publish_weekday BETWEEN 1 AND 7),
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(batch_id, owner_faculty_id)
);

ALTER TABLE public.mock_exams
  ADD COLUMN IF NOT EXISTS automation_key TEXT,
  ADD COLUMN IF NOT EXISTS generated_from_blueprint UUID REFERENCES public.assessment_blueprints(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS auto_generated BOOLEAN NOT NULL DEFAULT false;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mock_exam_automation_key
  ON public.mock_exams(automation_key) WHERE automation_key IS NOT NULL;

ALTER TABLE public.assessment_blueprints ENABLE ROW LEVEL SECURITY;
CREATE POLICY assessment_blueprints_faculty_manage ON public.assessment_blueprints
  FOR ALL TO authenticated
  USING (owner_faculty_id = public.current_user_id() OR EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = public.current_user_id() AND u.role_label = 'HOD'
  ))
  WITH CHECK (owner_faculty_id = public.current_user_id() OR EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = public.current_user_id() AND u.role_label = 'HOD'
  ));

CREATE OR REPLACE FUNCTION public.generate_weekly_mock_exams(p_week_start DATE DEFAULT date_trunc('week', now())::date)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_blueprint RECORD;
  v_sequence INTEGER;
  v_exam_id UUID;
  v_key TEXT;
  v_created INTEGER := 0;
BEGIN
  FOR v_blueprint IN SELECT * FROM public.assessment_blueprints WHERE active LOOP
    FOR v_sequence IN 1..v_blueprint.exams_per_week LOOP
      v_key := v_blueprint.id::text || ':' || p_week_start::text || ':' || v_sequence::text;
      IF EXISTS (SELECT 1 FROM public.mock_exams WHERE automation_key = v_key) THEN CONTINUE; END IF;

      INSERT INTO public.mock_exams(
        title, description, duration_minutes, total_marks, exam_date,
        batch_id, created_by, automation_key, generated_from_blueprint, auto_generated
      ) VALUES (
        v_blueprint.title_prefix || ' · ' || to_char(p_week_start, 'DD Mon') ||
          CASE WHEN v_blueprint.exams_per_week > 1 THEN ' · ' || v_sequence ELSE '' END,
        'Automatically assembled from the faculty-approved question bank blueprint. Reflect after submission to turn the score into a next step.',
        v_blueprint.duration_minutes,
        v_blueprint.question_count,
        (p_week_start + (v_blueprint.publish_weekday - 1) + ((v_sequence - 1) * 3))::timestamp + time '09:00',
        v_blueprint.batch_id,
        v_blueprint.owner_faculty_id,
        v_key,
        v_blueprint.id,
        true
      ) RETURNING id INTO v_exam_id;

      INSERT INTO public.mock_exam_questions(
        exam_id, question_text, option_a, option_b, option_c, option_d,
        correct_option, marks, order_index
      )
      SELECT v_exam_id, q.question_text,
        q.options->>0, q.options->>1, q.options->>2, q.options->>3,
        chr(65 + q.correct_option), 1,
        row_number() OVER (ORDER BY md5(q.id::text || v_key)) - 1
      FROM public.question_bank q
      WHERE q.is_active
        AND (cardinality(v_blueprint.topics) = 0 OR q.topic = ANY(v_blueprint.topics))
      ORDER BY md5(q.id::text || v_key)
      LIMIT v_blueprint.question_count;

      UPDATE public.mock_exams
      SET total_marks = (SELECT count(*) FROM public.mock_exam_questions WHERE exam_id = v_exam_id)
      WHERE id = v_exam_id;
      v_created := v_created + 1;
    END LOOP;
  END LOOP;
  RETURN v_created;
END;
$$;

REVOKE ALL ON FUNCTION public.generate_weekly_mock_exams(DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.generate_weekly_mock_exams(DATE) TO service_role;

COMMIT;
