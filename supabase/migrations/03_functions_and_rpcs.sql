-- ============================================================
-- PSGMX — 03_functions_and_rpcs.sql
-- Canonical Business Logic & API Functions
-- ============================================================

-- ── 1. Logical Identity & Role Verification ──────────────────

CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT u.id
  FROM public.users u
  JOIN auth.users a ON a.id = auth.uid()
  WHERE u.id = a.id
     OR lower(u.email) = lower(a.email)
     OR lower(u.personal_email) = lower(a.email)
     OR lower(u.college_email) = lower(a.email)
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_user_reg_no()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT reg_no FROM public.users WHERE id = public.current_user_id();
$$;

CREATE OR REPLACE FUNCTION public.current_user_batch()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT batch FROM public.users WHERE id = public.current_user_id();
$$;

CREATE OR REPLACE FUNCTION public.is_team_leader()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE((roles->>'isTeamLeader')::boolean, false)
  FROM public.users WHERE id = public.current_user_id();
$$;

CREATE OR REPLACE FUNCTION public.is_coordinator()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE((roles->>'isCoordinator')::boolean, false)
  FROM public.users WHERE id = public.current_user_id();
$$;

CREATE OR REPLACE FUNCTION public.is_placement_rep()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE((roles->>'isPlacementRep')::boolean, false)
  FROM public.users WHERE id = public.current_user_id();
$$;

CREATE OR REPLACE FUNCTION public.resolve_student_actor(p_candidate UUID)
RETURNS UUID
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_canonical UUID := public.current_user_id();
BEGIN
  IF v_canonical IS NOT NULL AND (p_candidate IS NULL OR p_candidate = v_canonical OR p_candidate = auth.uid()) THEN
    RETURN v_canonical;
  END IF;
  RETURN COALESCE(v_canonical, auth.uid());
END;
$$;

-- ── 2. Onboarding & Auto-Provisioning Profile ────────────────

CREATE OR REPLACE FUNCTION public.auto_provision_profile()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_whitelist public.whitelist%ROWTYPE;
  v_batch_id UUID;
BEGIN
  SELECT * INTO v_whitelist FROM public.whitelist
  WHERE lower(email) = lower(NEW.email)
     OR lower(personal_email) = lower(NEW.email)
     OR lower(college_email) = lower(NEW.email)
  LIMIT 1;

  IF FOUND THEN
    v_batch_id := v_whitelist.batch_id;
    IF v_batch_id IS NULL AND v_whitelist.reg_no IS NOT NULL THEN
      SELECT id INTO v_batch_id FROM public.batches
      WHERE batch_code = substr(v_whitelist.reg_no, 1, 4);
    END IF;

    INSERT INTO public.users (
      id, email, personal_email, college_email, reg_no, reg_no_is_placeholder,
      name, team_id, team_uuid, batch, batch_id, gender, dob, roles, leetcode_username
    ) VALUES (
      NEW.id,
      NEW.email,
      v_whitelist.personal_email,
      v_whitelist.college_email,
      COALESCE(v_whitelist.reg_no, 'TEMP_' || substr(NEW.id::text, 1, 8)),
      v_whitelist.reg_no_is_placeholder,
      COALESCE(v_whitelist.name, split_part(NEW.email, '@', 1)),
      v_whitelist.team_id,
      v_whitelist.team_uuid,
      COALESCE(v_whitelist.batch, 'G1'),
      v_batch_id,
      v_whitelist.gender,
      v_whitelist.dob,
      COALESCE(v_whitelist.roles, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
      v_whitelist.leetcode_username
    ) ON CONFLICT (id) DO UPDATE SET
      personal_email = COALESCE(EXCLUDED.personal_email, users.personal_email),
      college_email = COALESCE(EXCLUDED.college_email, users.college_email),
      team_uuid = COALESCE(EXCLUDED.team_uuid, users.team_uuid),
      updated_at = now();
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_onboarding_profile(
  p_target_tier TEXT,
  p_preferred_role TEXT,
  p_primary_language TEXT,
  p_daily_commitment_minutes INT,
  p_interview_comfort TEXT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid UUID := public.current_user_id();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.users SET
    target_tier = p_target_tier,
    preferred_role = p_preferred_role,
    primary_language = p_primary_language,
    daily_commitment_minutes = p_daily_commitment_minutes,
    interview_comfort = p_interview_comfort,
    onboarding_complete = true,
    updated_at = now()
  WHERE id = v_uid;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- ── 3. Daily Five Technical Engine ───────────────────────────

CREATE OR REPLACE FUNCTION public.get_daily_five_questions(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (id UUID, question_text TEXT, options JSONB, topic TEXT, difficulty TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_target_user UUID;
  v_attempt public.daily_five_attempts%ROWTYPE;
  v_question_ids UUID[];
  v_seed FLOAT;
  v_score NUMERIC;
  v_difficulty TEXT;
BEGIN
  IF auth.uid() IS NULL AND v_actor IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_actor IS NULL THEN
    v_actor := auth.uid();
  END IF;

  v_target_user := COALESCE(p_user_id, v_actor, auth.uid());

  IF p_user_id IS NOT NULL AND p_user_id <> v_actor AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authenticated as this student';
  END IF;

  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE;
  IF FOUND THEN
    IF v_attempt.submitted_at IS NOT NULL THEN
      RAISE EXCEPTION 'Already completed today''s Daily Five';
    END IF;
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
    SELECT array_agg(qid) INTO v_question_ids FROM (
      SELECT q.id AS qid
      FROM public.question_bank q
      WHERE q.is_active
      ORDER BY random()
      LIMIT 5
    ) fallback_selected;
  END IF;

  IF COALESCE(array_length(v_question_ids, 1), 0) < 5 THEN
    RAISE EXCEPTION 'At least five active questions are required';
  END IF;

  INSERT INTO public.daily_five_attempts(user_id, attempt_date, question_ids, started_at)
  VALUES (v_actor, CURRENT_DATE, v_question_ids, now())
  ON CONFLICT (user_id, attempt_date) DO UPDATE
    SET question_ids = EXCLUDED.question_ids, started_at = EXCLUDED.started_at
    WHERE daily_five_attempts.submitted_at IS NULL;

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
  v_fallback_qids UUID[];
BEGIN
  IF auth.uid() IS NULL AND v_actor IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_actor IS NULL THEN
    v_actor := auth.uid();
  END IF;

  IF p_user_id IS NOT NULL AND p_user_id <> v_actor AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authenticated as this student';
  END IF;

  IF jsonb_typeof(p_answers) <> 'object' THEN
    RAISE EXCEPTION 'Answers must be an object';
  END IF;

  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE FOR UPDATE;

  IF NOT FOUND THEN
    SELECT array_agg(key::uuid) INTO v_fallback_qids FROM jsonb_each_text(p_answers);
    INSERT INTO public.daily_five_attempts(user_id, attempt_date, question_ids, started_at)
    VALUES (v_actor, CURRENT_DATE, COALESCE(v_fallback_qids, '{}'::uuid[]), now() - INTERVAL '60 seconds')
    RETURNING * INTO v_attempt;
  END IF;

  IF v_attempt.submitted_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'correct_count', COALESCE(v_attempt.correct_count, 0),
      'total_questions', array_length(v_attempt.question_ids, 1),
      'accuracy_rate', COALESCE(v_attempt.accuracy_rate, 0),
      'flagged', v_attempt.flagged,
      'already_completed', true
    );
  END IF;

  FOR v_question IN SELECT id, correct_option FROM public.question_bank WHERE id = ANY(v_attempt.question_ids) LOOP
    v_total := v_total + 1;
    BEGIN
      v_answer := (p_answers ->> v_question.id::TEXT)::INTEGER;
    EXCEPTION WHEN invalid_text_representation THEN
      v_answer := NULL;
    END;
    IF v_answer = v_question.correct_option THEN
      v_correct := v_correct + 1;
    END IF;
  END LOOP;

  IF v_total = 0 THEN
    v_total := GREATEST(array_length(v_attempt.question_ids, 1), 1);
  END IF;

  v_accuracy := v_correct::NUMERIC / v_total;
  v_elapsed := extract(epoch FROM (now() - v_attempt.started_at))::INTEGER;
  IF v_elapsed < 3 THEN
    v_flagged := true;
    v_reason := 'Submission was faster than the integrity floor';
  END IF;

  UPDATE public.daily_five_attempts SET
    submitted_at = now(),
    correct_count = v_correct,
    accuracy_rate = v_accuracy,
    flagged = v_flagged,
    flag_reason = v_reason
  WHERE id = v_attempt.id;

  PERFORM public.increment_daily_five_streak(v_actor, v_accuracy);

  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
  VALUES (
    v_actor,
    'DAILY_FIVE_COMPLETED',
    'daily_five_attempts',
    v_attempt.id,
    jsonb_build_object(
      'accuracy_rate', v_accuracy,
      'correct_count', v_correct,
      'total_questions', v_total,
      'flagged', v_flagged
    )
  );

  RETURN jsonb_build_object(
    'correct_count', v_correct,
    'total_questions', v_total,
    'accuracy_rate', v_accuracy,
    'flagged', v_flagged
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_daily_five_streak(p_user_id UUID, p_accuracy NUMERIC)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_streak public.daily_five_streaks%ROWTYPE;
BEGIN
  SELECT * INTO v_streak FROM public.daily_five_streaks WHERE user_id = p_user_id FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.daily_five_streaks (user_id, current_streak, longest_streak, last_completed)
    VALUES (p_user_id, 1, 1, CURRENT_DATE);
    RETURN;
  END IF;

  IF v_streak.last_completed = CURRENT_DATE THEN
    RETURN;
  ELSIF v_streak.last_completed = CURRENT_DATE - 1 THEN
    UPDATE public.daily_five_streaks SET
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      last_completed = CURRENT_DATE,
      updated_at = now()
    WHERE user_id = p_user_id;
  ELSE
    UPDATE public.daily_five_streaks SET
      current_streak = 1,
      last_completed = CURRENT_DATE,
      updated_at = now()
    WHERE user_id = p_user_id;
  END IF;
END;
$$;

-- ── 4. Placement Squads & Teams Dynamic APIs ─────────────────

CREATE OR REPLACE FUNCTION public.get_my_squad()
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_team_uuid UUID;
  v_result JSONB;
BEGIN
  SELECT team_uuid INTO v_team_uuid FROM public.users WHERE id = v_actor;
  IF v_team_uuid IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'team_id', t.id,
    'team_name', t.team_name,
    'team_code', t.team_code,
    'objective', COALESCE(t.objective, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
    'members', COALESCE(jsonb_agg(
      jsonb_build_object(
        'id', u.id,
        'name', u.name,
        'reg_no', u.reg_no,
        'is_team_leader', ((u.id = t.team_leader_id) OR COALESCE((u.roles->>'isTeamLeader')::boolean, false)),
        'current_streak', COALESCE(s.current_streak, 0),
        'verified_quest_count', COALESCE(q.cnt, 0)
      ) ORDER BY u.name
    ) FILTER (WHERE u.id IS NOT NULL), '[]'::jsonb),
    'feed', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'member_name', fu.name,
        'quest_title', fq.title,
        'completed_at', fc.submitted_at
      ) ORDER BY fc.submitted_at DESC)
      FROM public.code_submissions fc
      JOIN public.users fu ON fu.id = fc.student_id
      JOIN public.quests fq ON fq.id = fc.quest_id
      WHERE fu.team_uuid = v_team_uuid AND fc.is_verified_complete = TRUE
      LIMIT 15
    ), '[]'::jsonb)
  )
  INTO v_result
  FROM public.teams t
  LEFT JOIN public.users u ON u.team_uuid = t.id
  LEFT JOIN public.daily_five_streaks s ON s.user_id = u.id
  LEFT JOIN (
    SELECT student_id, count(*) AS cnt FROM public.code_submissions
    WHERE is_verified_complete = TRUE GROUP BY student_id
  ) q ON q.student_id = u.id
  WHERE t.id = v_team_uuid
  GROUP BY t.id, t.team_name, t.team_code, t.objective;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_batch_placement_teams(p_batch_code TEXT DEFAULT '26MX')
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_batch_id UUID;
  v_teams JSONB;
BEGIN
  SELECT id INTO v_batch_id FROM public.batches WHERE batch_code = p_batch_code;
  IF v_batch_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'team_code', t.team_code,
        'team_name', t.team_name,
        'objective', t.objective,
        'target_size', t.target_size,
        'team_leader_id', t.team_leader_id,
        'members', COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', COALESCE(u.id::text, w.id::text),
                'name', COALESCE(u.name, w.name),
                'roll_no', COALESCE(u.reg_no, w.reg_no),
                'is_leader', (
                  (u.id IS NOT NULL AND u.id = t.team_leader_id) OR
                  COALESCE((u.roles->>'isTeamLeader')::boolean, false) OR
                  COALESCE((w.roles->>'isTeamLeader')::boolean, false)
                )
              ) ORDER BY
                ((u.id IS NOT NULL AND u.id = t.team_leader_id) OR
                 COALESCE((u.roles->>'isTeamLeader')::boolean, false) OR
                 COALESCE((w.roles->>'isTeamLeader')::boolean, false)) DESC,
                COALESCE(u.reg_no, w.reg_no)
            )
            FROM public.whitelist w
            LEFT JOIN public.users u ON u.reg_no = w.reg_no
            WHERE w.team_uuid = t.id OR w.team_id = t.team_code
          ),
          '[]'::jsonb
        )
      ) ORDER BY t.team_code
    ),
    '[]'::jsonb
  ) INTO v_teams
  FROM public.teams t
  WHERE t.batch_id = v_batch_id;

  RETURN v_teams;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_squad_objective(p_team_id UUID, p_objective TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.teams SET objective = p_objective, updated_at = now() WHERE id = p_team_id;
END;
$$;

-- ── 5. Lineage & Mentorship APIs ─────────────────────────────

CREATE OR REPLACE FUNCTION public.get_lineage_reveal()
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_user UUID := public.current_user_id();
  v_senior RECORD;
BEGIN
  SELECT s.id, s.name, s.current_company, s.current_role_title, s.avatar_url, s.linkedin_url
  INTO v_senior
  FROM public.mentor_assignments ma
  JOIN public.users s ON s.id = ma.senior_id
  WHERE ma.junior_id = v_user AND ma.is_active = TRUE
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'senior_id', v_senior.id,
    'name', v_senior.name,
    'company', v_senior.current_company,
    'role', v_senior.current_role_title,
    'avatar_url', v_senior.avatar_url,
    'linkedin_url', v_senior.linkedin_url
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_lineage_juniors()
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_user UUID := public.current_user_id();
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'junior_id', j.id,
      'name', j.name,
      'reg_no', j.reg_no,
      'target_tier', j.target_tier,
      'preferred_role', j.preferred_role
    ) ORDER BY j.name
  ), '[]'::jsonb)
  INTO v_result
  FROM public.mentor_assignments ma
  JOIN public.users j ON j.id = ma.junior_id
  WHERE ma.senior_id = v_user AND ma.is_active = TRUE;

  RETURN v_result;
END;
$$;

-- ── 6. Moderation & Community Governance ────────────────────

CREATE OR REPLACE FUNCTION public.moderate_community_content(
  p_entity_type TEXT,
  p_entity_id UUID,
  p_action TEXT,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_moderator UUID := public.current_user_id();
BEGIN
  IF NOT (public.is_coordinator() OR public.is_placement_rep()) THEN
    RAISE EXCEPTION 'Unauthorized to moderate content';
  END IF;

  INSERT INTO public.moderated_content (entity_type, entity_id, moderator_id, action, notes)
  VALUES (p_entity_type, p_entity_id, v_moderator, p_action, p_notes)
  ON CONFLICT (entity_id) DO UPDATE SET
    action = EXCLUDED.action,
    notes = EXCLUDED.notes,
    moderator_id = EXCLUDED.moderator_id;
END;
$$;

-- ── 7. Assessment Engine & Mock Exams ────────────────────────

CREATE OR REPLACE FUNCTION public.start_mock_exam(p_exam_id UUID)
RETURNS TABLE (result_id UUID, session_token UUID, started_at TIMESTAMPTZ, duration_minutes INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_existing public.mock_exam_results%ROWTYPE;
    v_duration INTEGER;
    v_user UUID := COALESCE(public.current_user_id(), auth.uid());
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_existing FROM public.mock_exam_results WHERE exam_id = p_exam_id AND student_id = v_user;
    SELECT m.duration_minutes INTO v_duration FROM public.mock_exams m WHERE m.id = p_exam_id;
    IF v_duration IS NULL THEN
        RAISE EXCEPTION 'Exam not found';
    END IF;

    IF FOUND AND v_existing.status IN ('submitted', 'auto_submitted') THEN
        RAISE EXCEPTION 'Already submitted';
    END IF;

    IF FOUND THEN
        RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_duration;
        RETURN;
    END IF;

    INSERT INTO public.mock_exam_results (exam_id, student_id, session_token, started_at, status)
    VALUES (p_exam_id, v_user, gen_random_uuid(), now(), 'in_progress')
    RETURNING mock_exam_results.id, mock_exam_results.session_token, mock_exam_results.started_at
    INTO v_existing.id, v_existing.session_token, v_existing.started_at;

    RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_duration;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_exam_server_side(
    p_exam_id UUID,
    p_student_id UUID,
    p_answers JSONB,
    p_time_taken_seconds INTEGER,
    p_proctoring_flags JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_result public.mock_exam_results%ROWTYPE;
    v_duration_minutes INTEGER;
    v_question RECORD;
    v_raw_marks NUMERIC := 0;
    v_out_of NUMERIC := 0;
    v_total_questions INTEGER := 0;
    v_student_answer TEXT;
    v_elapsed_seconds INTEGER;
    v_status TEXT := 'submitted';
    v_caller UUID := COALESCE(public.current_user_id(), auth.uid());
BEGIN
    IF v_caller IS NULL OR v_caller <> p_student_id THEN
        RAISE EXCEPTION 'Not authenticated as the submitting student';
    END IF;

    SELECT * INTO v_result FROM public.mock_exam_results WHERE exam_id = p_exam_id AND student_id = p_student_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active session — call start_mock_exam first';
    END IF;
    IF v_result.status IN ('submitted', 'auto_submitted') THEN
        RAISE EXCEPTION 'Already submitted';
    END IF;

    SELECT duration_minutes INTO v_duration_minutes FROM public.mock_exams WHERE id = p_exam_id;
    v_elapsed_seconds := EXTRACT(EPOCH FROM (now() - v_result.started_at))::INTEGER;
    IF v_elapsed_seconds > (v_duration_minutes * 60) + 120 THEN
        v_status := 'auto_submitted';
    END IF;

    FOR v_question IN SELECT * FROM public.mock_exam_questions WHERE exam_id = p_exam_id ORDER BY order_index LOOP
        v_total_questions := v_total_questions + 1;
        v_out_of := v_out_of + v_question.marks;
        v_student_answer := p_answers ->> v_question.id::TEXT;
        IF v_student_answer IS NOT NULL AND upper(v_student_answer) = v_question.correct_option THEN
            v_raw_marks := v_raw_marks + v_question.marks;
        END IF;
    END LOOP;

    UPDATE public.mock_exam_results SET
        submitted_at = now(),
        score = CASE WHEN v_out_of > 0 THEN round((v_raw_marks / v_out_of) * 100, 2) ELSE 0 END,
        raw_marks = v_raw_marks,
        out_of = v_out_of,
        total_questions = v_total_questions,
        proctoring_flags = COALESCE(p_proctoring_flags, '[]'::jsonb),
        status = v_status
    WHERE id = v_result.id;

    RETURN jsonb_build_object(
        'result_id', v_result.id,
        'score', CASE WHEN v_out_of > 0 THEN round((v_raw_marks / v_out_of) * 100, 2) ELSE 0 END,
        'raw_marks', v_raw_marks,
        'out_of', v_out_of
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_mock_exam_question_with_answer(p_question_id UUID)
RETURNS TABLE (id UUID, exam_id UUID, question_text TEXT, option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT, correct_option TEXT, marks INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = COALESCE(public.current_user_id(), auth.uid()) AND u.role_label IN ('Faculty', 'HOD')) THEN
        RAISE EXCEPTION 'Only faculty/HOD may view correct answers';
    END IF;
    RETURN QUERY
        SELECT q.id, q.exam_id, q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, q.marks
        FROM public.mock_exam_questions q WHERE q.id = p_question_id;
END;
$$;

-- ── 8. Knowledge Semantic Search (RAG) ───────────────────────

CREATE OR REPLACE FUNCTION public.knowledge_semantic_search(
    query_embedding vector(384),
    match_threshold FLOAT DEFAULT 0.5,
    match_count INT DEFAULT 5
)
RETURNS TABLE (id UUID, article_id UUID, chunk_text TEXT, title TEXT, similarity FLOAT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT ke.id, ke.article_id, ke.chunk_text, kba.title, 1 - (ke.embedding <=> query_embedding) AS similarity
    FROM public.knowledge_embeddings ke
    JOIN public.knowledge_brain_articles kba ON kba.id = ke.article_id AND kba.approval_status = 'approved'
    WHERE ke.embedding IS NOT NULL AND (1 - (ke.embedding <=> query_embedding)) >= match_threshold
    ORDER BY ke.embedding <=> query_embedding
    LIMIT match_count;
$$;

-- ── 9. Daily Automation Functions ────────────────────────────

CREATE OR REPLACE FUNCTION public.send_birthday_notifications()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user RECORD;
    v_count INTEGER := 0;
BEGIN
    FOR v_user IN
        SELECT id, name FROM public.users
        WHERE dob IS NOT NULL
          AND EXTRACT(MONTH FROM dob) = EXTRACT(MONTH FROM CURRENT_DATE)
          AND EXTRACT(DAY FROM dob) = EXTRACT(DAY FROM CURRENT_DATE)
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM public.notifications
            WHERE created_by = v_user.id AND notification_type = 'birthday'
              AND target_audience = 'user' AND generated_at::date = CURRENT_DATE
        ) THEN
            INSERT INTO public.notifications (
                title, message, notification_type, tone, target_audience, target_user_id, is_active
            ) VALUES (
                '🎂 Happy Birthday!',
                'Happy Birthday, ' || v_user.name || '! Wishing you a fantastic year filled with placement success! 🎉',
                'birthday',
                'celebratory',
                'user',
                v_user.id,
                true
            );
            v_count := v_count + 1;
        END IF;
    END LOOP;
    RETURN v_count;
END;
$$;

