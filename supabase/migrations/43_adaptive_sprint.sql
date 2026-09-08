-- ============================================================
-- PSGMX Migration 43 — 43_adaptive_sprint.sql
-- ============================================================
-- PRD Ch. 4.2 describes a distinct "Adaptive Skill Sprint" — student picks a
-- domain and a 5/10/20 minute duration, questions escalate from recall to
-- application, a session ends with a mastery movement report, and wrong
-- concepts enter a revisit queue automatically. None of that exists: Train's
-- "Launch Sprint" button and the /train/sprint route both silently open
-- plain Daily Five instead.
--
-- This mirrors the existing Daily Five pattern (get_daily_five_questions /
-- submit_daily_five_answers in 06_functions.sql) rather than inventing a new
-- one: a SECURITY DEFINER RPC serves questions without ever exposing
-- correct_option to the client, and grading happens server-side on submit.
-- Unlike Daily Five, a sprint is not once-per-day — a student can run
-- several sprints — so sprint_attempts has no daily uniqueness constraint.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sprint_attempts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  domain            TEXT, -- NULL = "recommended for me" (mixed topics)
  duration_minutes  SMALLINT NOT NULL CHECK (duration_minutes IN (5, 10, 20)),
  question_ids      UUID[] NOT NULL,
  started_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at      TIMESTAMPTZ,
  correct_count     INTEGER,
  total_questions   INTEGER,
  accuracy_rate     NUMERIC(4,3)
);

CREATE INDEX IF NOT EXISTS idx_sprint_attempts_user_time ON public.sprint_attempts(user_id, started_at DESC);

ALTER TABLE public.sprint_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sprint_attempts_read_own" ON public.sprint_attempts
  FOR SELECT TO authenticated USING (user_id = auth.uid());
-- All writes happen through the SECURITY DEFINER RPCs below, run as the
-- table owner — no direct INSERT/UPDATE policy is needed for authenticated.

-- ── Revisit queue — wrong concepts resurface in later sprints ──────────────
CREATE TABLE IF NOT EXISTS public.sprint_revisit_queue (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  question_id   UUID NOT NULL REFERENCES public.question_bank(id) ON DELETE CASCADE,
  topic         TEXT NOT NULL,
  added_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_sprint_revisit_open ON public.sprint_revisit_queue(user_id) WHERE resolved_at IS NULL;
-- Partial unique index (not a plain UNIQUE constraint) — Postgres treats
-- every NULL as distinct in a normal unique constraint, which would let
-- duplicate *open* entries pile up for the same question since resolved_at
-- is NULL for all of them. This enforces "at most one open entry per
-- (user, question)" while still allowing many resolved historical rows.
CREATE UNIQUE INDEX IF NOT EXISTS idx_sprint_revisit_unique_open
  ON public.sprint_revisit_queue(user_id, question_id) WHERE resolved_at IS NULL;

ALTER TABLE public.sprint_revisit_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sprint_revisit_read_own" ON public.sprint_revisit_queue
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.start_adaptive_sprint(
  p_user_id UUID, p_domain TEXT, p_duration_minutes SMALLINT
)
RETURNS TABLE (id UUID, question_text TEXT, options JSONB, topic TEXT, difficulty TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_question_count INTEGER;
  v_revisit_ids UUID[];
  v_remaining INTEGER;
  v_question_ids UUID[];
  v_attempt_id UUID;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;
  IF p_duration_minutes NOT IN (5, 10, 20) THEN
    RAISE EXCEPTION 'duration_minutes must be 5, 10, or 20';
  END IF;

  v_question_count := CASE p_duration_minutes WHEN 5 THEN 5 WHEN 10 THEN 10 ELSE 18 END;

  -- Prioritise open revisit-queue questions (same domain if one was picked)
  -- so a wrong concept genuinely resurfaces, per PRD 4.2.
  SELECT array_agg(qid) INTO v_revisit_ids FROM (
    SELECT rq.question_id AS qid
    FROM public.sprint_revisit_queue rq
    JOIN public.question_bank q ON q.id = rq.question_id
    WHERE rq.user_id = p_user_id AND rq.resolved_at IS NULL
      AND (p_domain IS NULL OR q.topic = p_domain)
      AND q.is_active = true
    ORDER BY rq.added_at
    LIMIT v_question_count
  ) sub;

  v_remaining := v_question_count - COALESCE(array_length(v_revisit_ids, 1), 0);

  SELECT array_agg(qid) INTO v_question_ids FROM (
    SELECT q.id AS qid
    FROM public.question_bank q
    WHERE q.is_active = true
      AND (p_domain IS NULL OR q.topic = p_domain)
      AND (v_revisit_ids IS NULL OR q.id != ALL(v_revisit_ids))
    -- Escalate recall -> application: easy first, then medium, then hard.
    ORDER BY CASE q.difficulty WHEN 'easy' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END, random()
    LIMIT v_remaining
  ) sub;

  v_question_ids := COALESCE(v_revisit_ids, ARRAY[]::UUID[]) || COALESCE(v_question_ids, ARRAY[]::UUID[]);

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'No active questions found for this domain';
  END IF;

  INSERT INTO public.sprint_attempts (user_id, domain, duration_minutes, question_ids)
  VALUES (p_user_id, p_domain, p_duration_minutes, v_question_ids)
  RETURNING sprint_attempts.id INTO v_attempt_id;

  RETURN QUERY
    SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
    FROM public.question_bank q
    WHERE q.id = ANY(v_question_ids)
    ORDER BY array_position(v_question_ids, q.id);
END;
$$;

REVOKE ALL ON FUNCTION public.start_adaptive_sprint(UUID, TEXT, SMALLINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_adaptive_sprint(UUID, TEXT, SMALLINT) TO authenticated;

CREATE OR REPLACE FUNCTION public.submit_adaptive_sprint(
  p_user_id UUID, p_attempt_id UUID, p_answers JSONB
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_attempt public.sprint_attempts%ROWTYPE;
  v_question RECORD;
  v_student_answer INTEGER;
  v_correct_count INTEGER := 0;
  v_total INTEGER := 0;
  v_easy_correct INTEGER := 0; v_easy_total INTEGER := 0;
  v_medium_correct INTEGER := 0; v_medium_total INTEGER := 0;
  v_hard_correct INTEGER := 0; v_hard_total INTEGER := 0;
  v_resolved_count INTEGER := 0;
  v_accuracy NUMERIC;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;

  SELECT * INTO v_attempt FROM public.sprint_attempts
  WHERE id = p_attempt_id AND user_id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sprint attempt not found';
  END IF;
  IF v_attempt.submitted_at IS NOT NULL THEN
    RAISE EXCEPTION 'This sprint was already submitted';
  END IF;

  FOR v_question IN
    SELECT id, correct_option, difficulty FROM public.question_bank WHERE id = ANY(v_attempt.question_ids)
  LOOP
    v_total := v_total + 1;
    v_student_answer := (p_answers ->> v_question.id::TEXT)::INTEGER;
    IF v_student_answer IS NOT NULL AND v_student_answer = v_question.correct_option THEN
      v_correct_count := v_correct_count + 1;
      IF v_question.difficulty = 'easy' THEN v_easy_correct := v_easy_correct + 1;
      ELSIF v_question.difficulty = 'medium' THEN v_medium_correct := v_medium_correct + 1;
      ELSE v_hard_correct := v_hard_correct + 1; END IF;

      -- Resolve this question in the revisit queue if it was there.
      UPDATE public.sprint_revisit_queue
      SET resolved_at = now()
      WHERE user_id = p_user_id AND question_id = v_question.id AND resolved_at IS NULL;
      GET DIAGNOSTICS v_resolved_count = ROW_COUNT;
    ELSE
      -- Wrong (or skipped) — enters the revisit queue if not already open.
      INSERT INTO public.sprint_revisit_queue (user_id, question_id, topic)
      SELECT p_user_id, v_question.id, q.topic FROM public.question_bank q WHERE q.id = v_question.id
      ON CONFLICT (user_id, question_id) WHERE resolved_at IS NULL DO NOTHING;
    END IF;

    IF v_question.difficulty = 'easy' THEN v_easy_total := v_easy_total + 1;
    ELSIF v_question.difficulty = 'medium' THEN v_medium_total := v_medium_total + 1;
    ELSE v_hard_total := v_hard_total + 1; END IF;
  END LOOP;

  v_accuracy := CASE WHEN v_total > 0 THEN v_correct_count::NUMERIC / v_total ELSE 0 END;

  UPDATE public.sprint_attempts SET
    submitted_at = now(), correct_count = v_correct_count, total_questions = v_total, accuracy_rate = v_accuracy
  WHERE id = p_attempt_id;

  INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
  VALUES (p_user_id, 'ADAPTIVE_SPRINT_COMPLETED', 'sprint_attempts', p_attempt_id,
          jsonb_build_object('accuracy_rate', v_accuracy, 'correct_count', v_correct_count, 'total_questions', v_total));

  RETURN jsonb_build_object(
    'correct_count', v_correct_count,
    'total_questions', v_total,
    'accuracy_rate', v_accuracy,
    'resolved_revisit_count', v_resolved_count,
    'by_difficulty', jsonb_build_object(
      'easy', jsonb_build_object('correct', v_easy_correct, 'total', v_easy_total),
      'medium', jsonb_build_object('correct', v_medium_correct, 'total', v_medium_total),
      'hard', jsonb_build_object('correct', v_hard_correct, 'total', v_hard_total)
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_adaptive_sprint(UUID, UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_adaptive_sprint(UUID, UUID, JSONB) TO authenticated;
