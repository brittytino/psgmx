-- ============================================================
-- PSGMX Migration 28 — logical-identity mock exam lifecycle
-- ============================================================

-- Kept here as well as in the canonical function set so this migration is
-- safe on projects that already applied the original 06_functions.sql.
CREATE OR REPLACE FUNCTION public.is_hod(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id AND role_label = 'HOD');
$$;

CREATE OR REPLACE FUNCTION public.start_mock_exam(p_exam_id UUID)
RETURNS TABLE (result_id UUID, session_token UUID, started_at TIMESTAMPTZ, duration_minutes INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_student UUID := public.current_user_id();
  v_existing public.mock_exam_results%ROWTYPE;
  v_exam public.mock_exams%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR v_student IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_exam FROM public.mock_exams WHERE id = p_exam_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Exam not found'; END IF;
  IF v_exam.batch_id IS NOT NULL AND v_exam.batch_id <> public.get_user_batch_id(v_student) THEN
    RAISE EXCEPTION 'Exam belongs to another batch';
  END IF;
  IF v_exam.exam_date IS NOT NULL AND v_exam.exam_date > now() THEN RAISE EXCEPTION 'Exam is not open yet'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.mock_exam_questions WHERE exam_id = p_exam_id) THEN
    RAISE EXCEPTION 'Exam has no reviewed questions';
  END IF;

  SELECT * INTO v_existing FROM public.mock_exam_results
  WHERE exam_id = p_exam_id AND student_id = v_student;
  IF FOUND AND v_existing.status IN ('submitted', 'auto_submitted') THEN RAISE EXCEPTION 'Already submitted'; END IF;
  IF FOUND THEN
    RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_exam.duration_minutes;
    RETURN;
  END IF;

  INSERT INTO public.mock_exam_results(exam_id, student_id, session_token, started_at, status)
  VALUES (p_exam_id, v_student, gen_random_uuid(), now(), 'in_progress')
  RETURNING * INTO v_existing;
  RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_exam.duration_minutes;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_exam_server_side(
  p_exam_id UUID, p_student_id UUID, p_answers JSONB,
  p_time_taken_seconds INTEGER, p_proctoring_flags JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_student UUID := public.current_user_id();
  v_result public.mock_exam_results%ROWTYPE;
  v_duration INTEGER;
  v_question RECORD;
  v_raw NUMERIC := 0;
  v_out_of NUMERIC := 0;
  v_total INTEGER := 0;
  v_answer TEXT;
  v_elapsed INTEGER;
  v_status TEXT := 'submitted';
BEGIN
  IF auth.uid() IS NULL OR v_student IS NULL OR v_student <> p_student_id THEN
    RAISE EXCEPTION 'Not authenticated as the submitting student';
  END IF;
  IF jsonb_typeof(p_answers) <> 'object' THEN RAISE EXCEPTION 'Answers must be an object'; END IF;

  SELECT * INTO v_result FROM public.mock_exam_results
  WHERE exam_id = p_exam_id AND student_id = v_student FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No active exam session'; END IF;
  IF v_result.status IN ('submitted', 'auto_submitted') THEN RAISE EXCEPTION 'Already submitted'; END IF;

  SELECT duration_minutes INTO v_duration FROM public.mock_exams WHERE id = p_exam_id;
  v_elapsed := extract(epoch FROM (now() - v_result.started_at))::integer;
  IF v_elapsed > (v_duration * 60) + 120 THEN v_status := 'auto_submitted'; END IF;

  FOR v_question IN SELECT * FROM public.mock_exam_questions WHERE exam_id = p_exam_id ORDER BY order_index LOOP
    v_total := v_total + 1;
    v_out_of := v_out_of + v_question.marks;
    v_answer := upper(COALESCE(p_answers ->> v_question.id::text, ''));
    IF v_answer = v_question.correct_option THEN v_raw := v_raw + v_question.marks; END IF;
  END LOOP;
  IF v_total = 0 THEN RAISE EXCEPTION 'Exam has no questions'; END IF;

  UPDATE public.mock_exam_results SET
    submitted_at = now(), score = round((v_raw / v_out_of) * 100, 2),
    raw_marks = v_raw, out_of = v_out_of, total_questions = v_total,
    proctoring_flags = COALESCE(p_proctoring_flags, '[]'::jsonb), status = v_status
  WHERE id = v_result.id;

  RETURN jsonb_build_object('result_id', v_result.id, 'score', round((v_raw / v_out_of) * 100, 2),
    'raw_marks', v_raw, 'out_of', v_out_of, 'status', v_status, 'elapsed_seconds', v_elapsed);
END;
$$;

REVOKE ALL ON FUNCTION public.start_mock_exam(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_mock_exam(UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.submit_exam_server_side(UUID, UUID, JSONB, INTEGER, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_exam_server_side(UUID, UUID, JSONB, INTEGER, JSONB) TO authenticated;

-- Replace broad legacy policies with logical-identity and batch-scoped access.
DROP POLICY IF EXISTS "mock_exams_select_all" ON public.mock_exams;
CREATE POLICY "mock_exams_select_scope" ON public.mock_exams FOR SELECT TO authenticated
USING (
  batch_id IS NULL
  OR batch_id = public.get_user_batch_id(public.current_user_id())
  OR public.is_faculty_or_hod(public.current_user_id())
  OR public.is_placement_rep(public.current_user_id())
);

DROP POLICY IF EXISTS "mock_exam_questions_select_all" ON public.mock_exam_questions;
CREATE POLICY "mock_exam_questions_select_scope" ON public.mock_exam_questions FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.mock_exams e
    WHERE e.id = exam_id
      AND (
        e.batch_id IS NULL
        OR e.batch_id = public.get_user_batch_id(public.current_user_id())
        OR public.is_faculty_or_hod(public.current_user_id())
        OR public.is_placement_rep(public.current_user_id())
      )
  )
);

DROP POLICY IF EXISTS "mock_exam_results_select_own" ON public.mock_exam_results;
DROP POLICY IF EXISTS "mock_exam_results_select_faculty_hod" ON public.mock_exam_results;
CREATE POLICY "mock_exam_results_select_own" ON public.mock_exam_results FOR SELECT TO authenticated
USING (student_id = public.current_user_id());
CREATE POLICY "mock_exam_results_select_assigned_faculty" ON public.mock_exam_results FOR SELECT TO authenticated
USING (
  public.is_hod(public.current_user_id())
  OR EXISTS (
    SELECT 1 FROM public.mentor_assignments ma
    WHERE ma.student_id = mock_exam_results.student_id
      AND ma.mentor_id = public.current_user_id()
      AND ma.active
  )
);
