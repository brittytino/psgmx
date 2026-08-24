-- ============================================================
-- PSGMX — 11_daily_five_fix.sql
--
-- Daily Five ("Spark Five") is currently 100% non-functional on the live
-- database (apps/mobile/database/01_MASTER_SETUP.sql, confirmed as the
-- deployed schema):
--   - question_bank exists but has ZERO seeded rows.
--   - None of the RPCs the app calls exist live: get_daily_five_questions,
--     submit_daily_five_answers, get_daily_five_results,
--     get_question_bank_full, reset_daily_five_streak_violation.
--
-- A version of these RPCs exists in supabase/migrations/10_sprint2_anticheat.sql,
-- but it was written against a DIFFERENT, incompatible question_bank shape
-- (option_a/b/c/d TEXT columns + correct_option TEXT) that does not match
-- the live table (options JSONB + correct_option INT 0-3, as created in
-- 01_MASTER_SETUP.sql's "Migration 19: Daily Five Quiz Engine" section).
-- It also has one real logic bug independent of that mismatch: it filters
-- question_bank.topic by a 'Year 1 -'/'Year 2 -' prefix that no seeded
-- topic value (e.g. 'aptitude', 'dsa') has, so it would return zero
-- questions for everyone even if the column types matched.
--
-- This migration ports that design (SECURITY DEFINER RPCs, answer key
-- never shipped to the client pre-submission, server-side grading,
-- resume-in-progress support, speed-cheat flagging) rewritten against the
-- ACTUAL live schema, with the topic-prefix bug removed.
--
-- Run this once in the Supabase SQL editor. increment_daily_five_streak()
-- and apply_streak_freeze() already exist live (01_MASTER_SETUP.sql,
-- "Migration 19") and are reused as-is — not redefined here.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- STEP 1 — daily_five_attempts: server-side record of what was served
-- and when. Enables both "one submission per day" (DB-enforced) and the
-- impossible-speed anti-cheat check.
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS daily_five_attempts (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attempt_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  question_ids   UUID[] NOT NULL,
  started_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at   TIMESTAMPTZ,
  correct_count  INTEGER,
  accuracy_rate  NUMERIC,
  flagged        BOOLEAN NOT NULL DEFAULT false,
  flag_reason    TEXT,
  UNIQUE (user_id, attempt_date)
);

ALTER TABLE daily_five_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS daily_five_attempts_select_own ON daily_five_attempts;
CREATE POLICY daily_five_attempts_select_own ON daily_five_attempts
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS daily_five_attempts_select_faculty_hod ON daily_five_attempts;
CREATE POLICY daily_five_attempts_select_faculty_hod ON daily_five_attempts
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));
-- No INSERT/UPDATE policy for authenticated — RPC-only (SECURITY DEFINER below).

-- ──────────────────────────────────────────────────────────────
-- STEP 2 — get_question_bank_full(): admin-only read including
-- correct_option, gated on the publish_tasks permission (or Faculty/HOD).
-- Backs the question-bank management screen
-- (apps/mobile/lib/services/daily_five_service.dart fetchAllQuestions()).
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_question_bank_full()
RETURNS SETOF question_bank
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = auth.uid()
      AND (u.role_label IN ('Faculty', 'HOD')
           OR EXISTS (SELECT 1 FROM user_permissions p WHERE p.user_id = u.id AND p.permission_key = 'publish_tasks'))
  ) THEN
    RAISE EXCEPTION 'Missing publish_tasks permission';
  END IF;
  RETURN QUERY SELECT * FROM question_bank ORDER BY topic;
END;
$$;

REVOKE ALL ON FUNCTION get_question_bank_full() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_question_bank_full() TO authenticated;

-- ──────────────────────────────────────────────────────────────
-- STEP 3 — get_daily_five_questions(): server-picked, seeded per
-- (user_id, today), returns 5 questions WITHOUT correct_option. Resumes
-- the same attempt's question set if called again the same day before
-- submission, so re-opening the app mid-quiz doesn't reshuffle questions.
-- Draws from ALL active questions — no topic-prefix filter (the live
-- question_bank uses plain topic values like 'aptitude'/'dsa'/'dbms',
-- not a year-segmented naming scheme).
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_daily_five_questions(p_user_id UUID)
RETURNS TABLE (id UUID, question_text TEXT, options JSONB, topic TEXT, difficulty TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt daily_five_attempts%ROWTYPE;
  v_seed FLOAT;
  v_question_ids UUID[];
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;

  SELECT * INTO v_attempt FROM daily_five_attempts
  WHERE user_id = p_user_id AND attempt_date = CURRENT_DATE;

  IF FOUND THEN
    IF v_attempt.submitted_at IS NOT NULL THEN
      RAISE EXCEPTION 'Already completed today''s Daily Five';
    END IF;
    -- Resume the same question set already served today.
    RETURN QUERY
      SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
      FROM question_bank q WHERE q.id = ANY(v_attempt.question_ids);
    RETURN;
  END IF;

  -- Deterministic per (user_id, date) seed in [-1, 1], as setseed() requires.
  v_seed := (('x' || substr(md5(p_user_id::TEXT || CURRENT_DATE::TEXT), 1, 8))::bit(32)::BIGINT::FLOAT / 2147483647.0) - 1.0;
  PERFORM setseed(v_seed);

  SELECT array_agg(qid) INTO v_question_ids FROM (
    SELECT q.id AS qid FROM question_bank q
    WHERE q.is_active = true
    ORDER BY random()
    LIMIT 5
  ) sub;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'No active questions found in question bank';
  END IF;

  INSERT INTO daily_five_attempts (user_id, attempt_date, question_ids, started_at)
  VALUES (p_user_id, CURRENT_DATE, v_question_ids, now());

  RETURN QUERY
    SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
    FROM question_bank q WHERE q.id = ANY(v_question_ids);
END;
$$;

REVOKE ALL ON FUNCTION get_daily_five_questions(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_daily_five_questions(UUID) TO authenticated;

-- ──────────────────────────────────────────────────────────────
-- STEP 4 — submit_daily_five_answers(): server-side grading against the
-- live INT correct_option column. Flags (does not reject) <3s completions
-- for faculty review, calls the existing increment_daily_five_streak().
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION submit_daily_five_answers(p_user_id UUID, p_answers JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt daily_five_attempts%ROWTYPE;
  v_question RECORD;
  v_correct_count INTEGER := 0;
  v_total INTEGER := 0;
  v_accuracy NUMERIC;
  v_elapsed_seconds INTEGER;
  v_flagged BOOLEAN := false;
  v_flag_reason TEXT;
  v_student_answer INTEGER;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;

  SELECT * INTO v_attempt FROM daily_five_attempts
  WHERE user_id = p_user_id AND attempt_date = CURRENT_DATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active Daily Five session — call get_daily_five_questions first';
  END IF;

  IF v_attempt.submitted_at IS NOT NULL THEN
    RAISE EXCEPTION 'Already completed today''s Daily Five';
  END IF;

  FOR v_question IN
    SELECT id, correct_option FROM question_bank WHERE id = ANY(v_attempt.question_ids)
  LOOP
    v_total := v_total + 1;
    v_student_answer := (p_answers ->> v_question.id::TEXT)::INTEGER;
    IF v_student_answer IS NOT NULL AND v_student_answer = v_question.correct_option THEN
      v_correct_count := v_correct_count + 1;
    END IF;
  END LOOP;

  v_accuracy := CASE WHEN v_total > 0 THEN v_correct_count::NUMERIC / v_total ELSE 0 END;

  v_elapsed_seconds := EXTRACT(EPOCH FROM (now() - v_attempt.started_at))::INTEGER;
  IF v_elapsed_seconds < 3 THEN
    v_flagged := true;
    v_flag_reason := format('Completed in %s seconds (floor: 3s for %s questions)', v_elapsed_seconds, v_total);
  END IF;

  UPDATE daily_five_attempts SET
    submitted_at  = now(),
    correct_count = v_correct_count,
    accuracy_rate = v_accuracy,
    flagged       = v_flagged,
    flag_reason   = v_flag_reason
  WHERE id = v_attempt.id;

  PERFORM increment_daily_five_streak(p_user_id, v_accuracy);

  INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, metadata)
  VALUES (
    p_user_id, 'DAILY_FIVE_COMPLETED', 'daily_five_attempts', v_attempt.id,
    jsonb_build_object('accuracy_rate', v_accuracy, 'correct_count', v_correct_count, 'total_questions', v_total, 'flagged', v_flagged)
  );

  RETURN jsonb_build_object('correct_count', v_correct_count, 'total_questions', v_total, 'accuracy_rate', v_accuracy, 'flagged', v_flagged);
END;
$$;

REVOKE ALL ON FUNCTION submit_daily_five_answers(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_daily_five_answers(UUID, JSONB) TO authenticated;

-- ──────────────────────────────────────────────────────────────
-- STEP 5 — get_daily_five_results(): reveals correct_option, but ONLY for
-- an attempt the caller has already submitted today — powers the "why was
-- I wrong" AI explanation (apps/mobile/lib/services/ai_mentor_service.dart
-- explainWrongAnswer(), which already only runs post-submission).
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_daily_five_results(p_user_id UUID)
RETURNS TABLE (id UUID, correct_option INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt daily_five_attempts%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;

  SELECT * INTO v_attempt FROM daily_five_attempts
  WHERE user_id = p_user_id AND attempt_date = CURRENT_DATE;

  IF NOT FOUND OR v_attempt.submitted_at IS NULL THEN
    RAISE EXCEPTION 'No submitted attempt found for today';
  END IF;

  RETURN QUERY
    SELECT q.id, q.correct_option FROM question_bank q WHERE q.id = ANY(v_attempt.question_ids);
END;
$$;

REVOKE ALL ON FUNCTION get_daily_five_results(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_daily_five_results(UUID) TO authenticated;

-- ──────────────────────────────────────────────────────────────
-- STEP 6 — reset_daily_five_streak_violation(): replaces the direct
-- daily_five_streaks UPDATE currently done client-side in
-- DailyFiveService.terminateExam() (apps/mobile/lib/services/
-- daily_five_service.dart). daily_five_streaks has no authenticated
-- INSERT/UPDATE policy live, so that direct write was already failing —
-- this RPC is the fix, called via the same terminateExam() code path
-- (already calls reset_daily_five_streak_violation by name, no Dart
-- change needed).
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION reset_daily_five_streak_violation(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;
  UPDATE daily_five_streaks SET current_streak = 0 WHERE user_id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION reset_daily_five_streak_violation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reset_daily_five_streak_violation(UUID) TO authenticated;

-- ── Success ──────────────────────────────────────────────────────────────
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Migration 11 complete: Daily Five RPCs';
  RAISE NOTICE '  - daily_five_attempts table created';
  RAISE NOTICE '  - get_daily_five_questions() created';
  RAISE NOTICE '  - submit_daily_five_answers() created';
  RAISE NOTICE '  - get_daily_five_results() created';
  RAISE NOTICE '  - get_question_bank_full() created';
  RAISE NOTICE '  - reset_daily_five_streak_violation() created';
  RAISE NOTICE 'NEXT: run 12_question_bank_seed.sql to populate question_bank';
  RAISE NOTICE '========================================';
END $$;
