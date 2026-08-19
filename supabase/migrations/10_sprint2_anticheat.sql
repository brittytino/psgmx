-- ============================================================
-- PSGMX — 10_sprint2_anticheat.sql
-- Sprint 2: Daily Five integrity (plan Section 4.2).
--
-- CONFIRMED LIVE VULNERABILITY (not hypothetical) while auditing per the
-- plan's explicit "must-audit item": apps/mobile/lib/services/
-- daily_five_service.dart fetchTodaysSession() does a bare `.select()`
-- (= SELECT *) on `question_bank` as the authenticated student, which
-- includes `correct_option` — the full answer key for every question in
-- the topic pool (not just the 5 shown) is sent to the client BEFORE the
-- student answers. Grading then happens CLIENT-SIDE, and the resulting
-- accuracy_rate is self-reported directly to increment_daily_five_streak()
-- — a student can call that RPC with p_accuracy_rate: 1.0 regardless of
-- what they actually answered. This violates plan Rule 2 ("the client
-- never computes or writes a trust-sensitive value") concretely, not just
-- in principle.
--
-- Fix: column-level REVOKE (same pattern as ecampus_password/S1 and
-- mock_exam_questions.correct_option earlier), a seeded per-(user,date)
-- question-set RPC, and server-side grading that still calls through to
-- the existing increment_daily_five_streak() RPC so its streak logic
-- (which this migration does not have visibility into — it isn't in any
-- committed migration, so it was created directly against the live DB)
-- is preserved rather than reimplemented and risked diverging.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- STEP 1 — daily_five_attempts: server-side record of what was served
-- and when, enabling both "one submission per day" (DB-enforced, not
-- just UI-enforced) and the impossible-speed check.
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

CREATE POLICY daily_five_attempts_select_own ON daily_five_attempts
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY daily_five_attempts_select_faculty_hod ON daily_five_attempts
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));
-- No INSERT/UPDATE policy for authenticated — RPC-only, same as mock exams.

-- ──────────────────────────────────────────────────────────────
-- STEP 2 — column-level REVOKE on question_bank.correct_option.
-- Closes the confirmed leak immediately, independent of the RPCs below.
-- The mobile app's fetchTodaysSession() MUST be updated to select an
-- explicit column list excluding correct_option (see accompanying Dart
-- change) — a bare select() will otherwise error the whole request once
-- this lands.
-- ──────────────────────────────────────────────────────────────

REVOKE SELECT (correct_option) ON public.question_bank FROM authenticated;

-- Coordinators/faculty legitimately need correct_option to manage the
-- question bank (apps/mobile/lib/services/daily_five_service.dart
-- fetchAllQuestions(), used by the admin question-bank screen — its own
-- comment says "Requires publish_tasks permission (enforced by RLS)",
-- but the live RLS on question_bank only gates rows, not this column, so
-- the REVOKE above would otherwise silently break that legitimate screen
-- too). Column grants can't be conditioned on a permissions table, so
-- this is exposed via an RPC instead of a raw column grant.
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
-- (user_id, today), returns 5 questions WITHOUT correct_option.
-- Reuses the existing attempt row (and its already-served question_ids)
-- if called again the same day before submission — so re-opening the app
-- mid-quiz doesn't reshuffle the questions out from under the student,
-- but also can't be used to draw a fresh set after submitting.
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_daily_five_questions(p_user_id UUID)
RETURNS TABLE (id UUID, question_text TEXT, options JSONB, topic TEXT, difficulty TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt daily_five_attempts%ROWTYPE;
  v_batch_status TEXT;
  v_topic_prefix TEXT;
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

  SELECT b.status INTO v_batch_status
  FROM users u JOIN batches b ON b.id = u.batch_id
  WHERE u.id = p_user_id;

  v_topic_prefix := CASE WHEN v_batch_status = 'active_senior' THEN 'Year 2 -' ELSE 'Year 1 -' END;

  -- Deterministic per (user_id, date) seed in [-1, 1], as setseed() requires.
  v_seed := (('x' || substr(md5(p_user_id::TEXT || CURRENT_DATE::TEXT), 1, 8))::bit(32)::BIGINT::FLOAT / 2147483647.0) - 1.0;
  PERFORM setseed(v_seed);

  SELECT array_agg(qid) INTO v_question_ids FROM (
    SELECT q.id AS qid FROM question_bank q
    WHERE q.is_active = true AND q.topic LIKE v_topic_prefix || '%'
    ORDER BY random()
    LIMIT 5
  ) sub;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'No active questions found for topic %', v_topic_prefix;
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
-- STEP 4 — submit_daily_five_answers(): server-side grading. Flags (but
-- does not reject) impossibly fast completions per Section 4.2 — the
-- attempt still counts, but is marked for faculty review rather than
-- silently accepted as a clean streak day.
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

  -- Preserve existing streak logic — this migration doesn't know its
  -- internals (not in any committed migration file, so it was created
  -- directly against the live DB), it just feeds it a server-verified
  -- accuracy rate instead of a client-reported one.
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

-- get_daily_five_results(): reveals correct_option, but ONLY for an
-- attempt the caller has already submitted today — powers the "why was I
-- wrong" AI explanation in the results screen (apps/mobile/lib/services/
-- ai_mentor_service.dart explainWrongAnswer(), which already only runs
-- post-submission). Revealing answers after submission is fine; this
-- still can't be used to peek before answering.
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
-- STEP 5 — terminateExam's direct write, and closing the
-- daily_five_streaks direct-write hole (Section 4.5: "zero direct
-- INSERT/UPDATE — all writes go through SECURITY DEFINER RPCs").
--
-- Confirmed live: apps/mobile/lib/services/daily_five_service.dart
-- terminateExam() does `.from('daily_five_streaks').update({'current_streak':
-- 0}).eq('user_id', userId)` directly as the student's own session. Since
-- get_daily_five_questions/submit_daily_five_answers/apply_streak_freeze
-- now cover every legitimate write to this table, this is the last direct
-- write left, and once it's replaced, no authenticated-role INSERT/UPDATE
-- policy should remain necessary on daily_five_streaks at all.
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

-- ── MANUAL VERIFICATION REQUIRED (cannot be done from here) ──
-- I do not have SQL introspection access to list daily_five_streaks'
-- actual live RLS policies by name (only REST-level probing, which
-- confirms behavior but not policy names). The two DROP statements below
-- guess the names using this codebase's prevailing naming convention
-- (<table>_insert_own / <table>_update_own). Please verify in the
-- Supabase dashboard (Database → Tables → daily_five_streaks → RLS
-- Policies) that NO INSERT or UPDATE policy remains for the
-- `authenticated` role after running this — if the real policy has a
-- different name, these DROP IF EXISTS statements will silently no-op
-- and the direct-write hole stays open.
DROP POLICY IF EXISTS daily_five_streaks_insert_own ON daily_five_streaks;
DROP POLICY IF EXISTS daily_five_streaks_update_own ON daily_five_streaks;

-- ──────────────────────────────────────────────────────────────
-- STEP 6 — LeetCode integrity (Section 4.3), scoped to what's actually
-- achievable without a larger architecture change.
--
-- CONFIRMED LIVE, SEPARATE FINDING (bigger than the plan's checklist
-- assumed): the plan marks "server-side polling, not self-reported
-- scores" as already ✅ existing. It does not. apps/mobile/lib/providers/
-- leetcode_provider.dart calls https://leetcode.com/graphql DIRECTLY FROM
-- THE CLIENT, then upserts the parsed result straight into leetcode_stats
-- using the student's own session — both the fetch AND the write are
-- fully client-controlled. Any student can skip the real LeetCode call
-- entirely and upsert fabricated numbers directly. This is the single
-- most exploitable gap found in this whole audit, since it feeds straight
-- into the readiness score's leetcode_momentum_percentile component.
--
-- Properly fixing this requires a genuine server-side polling service
-- (a scheduled Edge Function or an external cron job using service_role,
-- structurally similar to ecampus_api.py) that removes the client's
-- ability to write this table directly — that is a distinct, larger
-- piece of infrastructure, not a one-line policy change, and isn't
-- built in this migration. Flagging this explicitly rather than leaving
-- it undocumented. What IS shipped here, since it doesn't require that
-- redesign and the plan explicitly asks for it "now":
--   - username change rate-limiting (max 1 per 30 days)
--   - anomaly flagging on implausible solved-count jumps
-- ──────────────────────────────────────────────────────────────

ALTER TABLE leetcode_stats ADD COLUMN IF NOT EXISTS username_last_changed_at TIMESTAMPTZ;
ALTER TABLE leetcode_stats ADD COLUMN IF NOT EXISTS flagged BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE leetcode_stats ADD COLUMN IF NOT EXISTS flag_reason TEXT;

CREATE OR REPLACE FUNCTION _flag_leetcode_anomaly()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.total_solved IS NOT NULL
     AND NEW.total_solved - OLD.total_solved > 50
     AND NEW.last_updated - OLD.last_updated < INTERVAL '2 days' THEN
    NEW.flagged := true;
    NEW.flag_reason := format(
      'Jumped from %s to %s solved (+%s) between %s and %s',
      OLD.total_solved, NEW.total_solved, NEW.total_solved - OLD.total_solved,
      OLD.last_updated, NEW.last_updated
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trig_leetcode_anomaly_flag ON leetcode_stats;
CREATE TRIGGER trig_leetcode_anomaly_flag
  BEFORE UPDATE ON leetcode_stats
  FOR EACH ROW EXECUTE FUNCTION _flag_leetcode_anomaly();

-- Rate-limit RPC for username changes. The mobile app currently updates
-- `users.leetcode_username` directly wherever that happens (not audited
-- as part of this migration — a separate follow-up); this RPC is
-- provided for that call site to switch to, but the switch itself is not
-- made here since the exact call site needs the same care the daily-five
-- fix got, not a guess.
CREATE OR REPLACE FUNCTION update_leetcode_username_rate_limited(p_user_id UUID, p_new_username TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_last_changed TIMESTAMPTZ;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authenticated as this user';
  END IF;

  SELECT ls.username_last_changed_at INTO v_last_changed
  FROM users u JOIN leetcode_stats ls ON ls.username = u.leetcode_username
  WHERE u.id = p_user_id;

  IF v_last_changed IS NOT NULL AND v_last_changed > now() - INTERVAL '30 days' THEN
    RAISE EXCEPTION 'LeetCode username can only be changed once every 30 days (last changed %)', v_last_changed;
  END IF;

  UPDATE users SET leetcode_username = p_new_username WHERE id = p_user_id;
  UPDATE leetcode_stats SET username_last_changed_at = now() WHERE username = p_new_username;
END;
$$;

REVOKE ALL ON FUNCTION update_leetcode_username_rate_limited(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION update_leetcode_username_rate_limited(UUID, TEXT) TO authenticated;

-- ── MANUAL FOLLOW-UP ──
-- This migration assumes `increment_daily_five_streak(p_user_id uuid,
-- p_accuracy_rate numeric)` and `apply_streak_freeze(p_user_id uuid)`
-- already exist live (the mobile app calls both today). Please confirm
-- their actual signatures in the Supabase dashboard (Database →
-- Functions) before running this — if an argument name/order differs,
-- the PERFORM call inside submit_daily_five_answers() needs updating.
