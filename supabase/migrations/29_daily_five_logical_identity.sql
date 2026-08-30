-- ============================================================
-- PSGMX Migration 29 — Daily Five logical identity hardening
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_daily_five_questions(p_user_id UUID)
RETURNS TABLE (id UUID, question_text TEXT, options JSONB, topic TEXT, difficulty TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_attempt public.daily_five_attempts%ROWTYPE;
  v_question_ids UUID[];
  v_seed FLOAT;
  v_score NUMERIC;
  v_difficulty TEXT;
BEGIN
  IF auth.uid() IS NULL OR v_actor IS NULL OR v_actor <> p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this student';
  END IF;

  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE;
  IF FOUND THEN
    IF v_attempt.submitted_at IS NOT NULL THEN RAISE EXCEPTION 'Already completed today''s Daily Five'; END IF;
    RETURN QUERY SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
      FROM public.question_bank q WHERE q.id = ANY(v_attempt.question_ids)
      ORDER BY array_position(v_attempt.question_ids, q.id);
    RETURN;
  END IF;

  SELECT score INTO v_score FROM public.readiness_scores
  WHERE user_id = v_actor ORDER BY computed_at DESC LIMIT 1;
  v_difficulty := CASE WHEN COALESCE(v_score, 0) < 45 THEN 'easy'
                       WHEN v_score < 75 THEN 'medium' ELSE 'hard' END;
  v_seed := (('x' || substr(md5(v_actor::TEXT || CURRENT_DATE::TEXT), 1, 8))::bit(32)::BIGINT::FLOAT / 2147483647.0) - 1.0;
  PERFORM setseed(v_seed);

  SELECT array_agg(qid) INTO v_question_ids FROM (
    SELECT q.id AS qid
    FROM public.question_bank q
    WHERE q.is_active
    ORDER BY (q.difficulty = v_difficulty) DESC, random()
    LIMIT 5
  ) selected;
  IF COALESCE(array_length(v_question_ids, 1), 0) < 5 THEN
    RAISE EXCEPTION 'At least five active questions are required';
  END IF;

  INSERT INTO public.daily_five_attempts(user_id, attempt_date, question_ids, started_at)
  VALUES (v_actor, CURRENT_DATE, v_question_ids, now());
  RETURN QUERY SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
    FROM public.question_bank q WHERE q.id = ANY(v_question_ids)
    ORDER BY array_position(v_question_ids, q.id);
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_daily_five_answers(p_user_id UUID, p_answers JSONB)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_attempt public.daily_five_attempts%ROWTYPE;
  v_question RECORD;
  v_correct INTEGER := 0;
  v_total INTEGER := 0;
  v_answer INTEGER;
  v_accuracy NUMERIC;
  v_elapsed INTEGER;
  v_flagged BOOLEAN := false;
  v_reason TEXT;
BEGIN
  IF auth.uid() IS NULL OR v_actor IS NULL OR v_actor <> p_user_id THEN RAISE EXCEPTION 'Not authenticated as this student'; END IF;
  IF jsonb_typeof(p_answers) <> 'object' THEN RAISE EXCEPTION 'Answers must be an object'; END IF;
  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No active Daily Five session'; END IF;
  IF v_attempt.submitted_at IS NOT NULL THEN RAISE EXCEPTION 'Already completed today''s Daily Five'; END IF;

  FOR v_question IN SELECT id, correct_option FROM public.question_bank WHERE id = ANY(v_attempt.question_ids) LOOP
    v_total := v_total + 1;
    BEGIN v_answer := (p_answers ->> v_question.id::TEXT)::INTEGER;
    EXCEPTION WHEN invalid_text_representation THEN v_answer := NULL; END;
    IF v_answer = v_question.correct_option THEN v_correct := v_correct + 1; END IF;
  END LOOP;
  IF v_total <> array_length(v_attempt.question_ids, 1) THEN RAISE EXCEPTION 'Question set changed during this attempt'; END IF;
  v_accuracy := v_correct::NUMERIC / v_total;
  v_elapsed := extract(epoch FROM (now() - v_attempt.started_at))::INTEGER;
  IF v_elapsed < 3 THEN v_flagged := true; v_reason := 'Submission was faster than the integrity floor'; END IF;

  UPDATE public.daily_five_attempts SET submitted_at = now(), correct_count = v_correct,
    accuracy_rate = v_accuracy, flagged = v_flagged, flag_reason = v_reason WHERE id = v_attempt.id;
  PERFORM public.increment_daily_five_streak(v_actor, v_accuracy);
  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
  VALUES (v_actor, 'DAILY_FIVE_COMPLETED', 'daily_five_attempts', v_attempt.id,
    jsonb_build_object('accuracy_rate', v_accuracy, 'correct_count', v_correct, 'total_questions', v_total, 'flagged', v_flagged));
  RETURN jsonb_build_object('correct_count', v_correct, 'total_questions', v_total,
    'accuracy_rate', v_accuracy, 'flagged', v_flagged);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_daily_five_results(p_user_id UUID)
RETURNS TABLE (id UUID, correct_option INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_actor UUID := public.current_user_id(); v_attempt public.daily_five_attempts%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR v_actor IS NULL OR v_actor <> p_user_id THEN RAISE EXCEPTION 'Not authenticated as this student'; END IF;
  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE;
  IF NOT FOUND OR v_attempt.submitted_at IS NULL THEN RAISE EXCEPTION 'No submitted attempt found for today'; END IF;
  RETURN QUERY SELECT q.id, q.correct_option FROM public.question_bank q WHERE q.id = ANY(v_attempt.question_ids);
END;
$$;

REVOKE ALL ON FUNCTION public.get_daily_five_questions(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_daily_five_answers(UUID, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_daily_five_results(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_daily_five_questions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_daily_five_answers(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_five_results(UUID) TO authenticated;

DROP POLICY IF EXISTS "streaks_read_own" ON public.daily_five_streaks;
DROP POLICY IF EXISTS "daily_five_attempts_select_own" ON public.daily_five_attempts;
DROP POLICY IF EXISTS "daily_five_attempts_select_faculty_hod" ON public.daily_five_attempts;
CREATE POLICY "streaks_read_own" ON public.daily_five_streaks FOR SELECT TO authenticated
USING (user_id = public.current_user_id());
CREATE POLICY "daily_five_attempts_select_own" ON public.daily_five_attempts FOR SELECT TO authenticated
USING (user_id = public.current_user_id());
CREATE POLICY "daily_five_attempts_select_assigned_faculty" ON public.daily_five_attempts FOR SELECT TO authenticated
USING (
  public.is_hod(public.current_user_id()) OR EXISTS (
    SELECT 1 FROM public.mentor_assignments ma WHERE ma.student_id = daily_five_attempts.user_id
      AND ma.mentor_id = public.current_user_id() AND ma.active
  )
);
