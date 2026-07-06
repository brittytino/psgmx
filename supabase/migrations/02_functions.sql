-- ============================================================
-- PSGMX — 02_functions.sql (v2)
-- Helper SQL functions for RLS policies and application logic.
-- Includes RPCs called by both Flutter and Next.js apps.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Helper: get_user_role
-- Returns (role, app_role) for a given user_id.
-- Used in RLS policy expressions.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_user_role(p_user_id UUID)
RETURNS TABLE(role TEXT, app_role TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.role, u.app_role
  FROM users u
  WHERE u.id = p_user_id;
$$;

-- ──────────────────────────────────────────────────────────────
-- Helper: get_batch_for_user
-- Returns the batch_id for a student user.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_batch_for_user(p_user_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT batch_id FROM users WHERE id = p_user_id;
$$;

-- ──────────────────────────────────────────────────────────────
-- RPC: compute_readiness_score
-- Called by Flutter after calibration or by admin scripts.
-- Computes and upserts the readiness score for a user.
-- Uses the same formula as the Edge Function.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION compute_readiness_score(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user            RECORD;
  v_streak          RECORD;
  v_batch_ids       UUID[];
  v_batch_stats     RECORD;
  v_leetcode        RECORD;
  v_exam_score      NUMERIC := 0;
  v_sessions_att    INTEGER := 0;
  v_sessions_elig   INTEGER := 0;
  v_daily_five      NUMERIC := 0;
  v_leetcode_score  NUMERIC := 0;
  v_mock_score      NUMERIC := 0;
  v_session_score   NUMERIC := 0;
  v_total           NUMERIC := 0;
  v_accuracy_rate   NUMERIC := 0;
  v_adherence_rate  NUMERIC := 0;
  v_today           DATE := CURRENT_DATE;
BEGIN
  -- Fetch user
  SELECT id, batch_id, role INTO v_user FROM users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'User not found');
  END IF;

  -- ── 1. Daily Five Score ─────────────────────────────────────
  SELECT * INTO v_streak FROM daily_five_streaks WHERE user_id = p_user_id;
  IF FOUND THEN
    v_accuracy_rate  := LEAST(COALESCE(v_streak.running_accuracy_rate, 0) / 100.0, 1.0);
    v_adherence_rate := LEAST(COALESCE(v_streak.total_days_completed, 0)::NUMERIC / 90.0, 1.0);
    v_daily_five := LEAST(
      (v_accuracy_rate * 0.10 * 100) + (v_adherence_rate * 0.20 * 100),
      30.0
    );
  END IF;

  -- ── 2. LeetCode Score ───────────────────────────────────────
  SELECT batch_percentile INTO v_leetcode FROM leetcode_stats WHERE user_id = p_user_id;
  IF FOUND THEN
    v_leetcode_score := LEAST(COALESCE(v_leetcode.batch_percentile, 0) * 0.25, 25.0);
  END IF;

  -- ── 3. Mock Exam Score ──────────────────────────────────────
  SELECT COALESCE(
    SUM(
      CASE
        WHEN (v_today - submitted_at::DATE) <= 30 THEN score * 1.0
        WHEN (v_today - submitted_at::DATE) <= 90 THEN score * 0.7
        ELSE score * 0.4
      END
    ) /
    NULLIF(
      SUM(
        CASE
          WHEN (v_today - submitted_at::DATE) <= 30 THEN 1.0
          WHEN (v_today - submitted_at::DATE) <= 90 THEN 0.7
          ELSE 0.4
        END
      ), 0
    ), 0
  ) INTO v_exam_score
  FROM mock_exam_results
  WHERE student_id = p_user_id;
  v_mock_score := LEAST(v_exam_score * 0.35, 35.0);

  -- ── 4. Session Score ────────────────────────────────────────
  SELECT COUNT(*) INTO v_sessions_att
  FROM placement_attendance
  WHERE student_id = p_user_id AND status IN ('present', 'excused');

  IF v_user.batch_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_sessions_elig
    FROM placement_sessions
    WHERE batch_id = v_user.batch_id AND target_scope = 'batch';
  END IF;

  v_session_score := LEAST(
    (v_sessions_att::NUMERIC / GREATEST(v_sessions_elig, 1)) * 10,
    10.0
  );

  -- ── 5. Total ────────────────────────────────────────────────
  v_total := LEAST(v_daily_five + v_leetcode_score + v_mock_score + v_session_score, 100.0);

  -- ── 6. Upsert readiness_scores ──────────────────────────────
  INSERT INTO readiness_scores (
    user_id, score, daily_five_score, leetcode_score, mock_exam_score, session_score, computed_at
  ) VALUES (
    p_user_id,
    ROUND(v_total, 2),
    ROUND(v_daily_five, 2),
    ROUND(v_leetcode_score, 2),
    ROUND(v_mock_score, 2),
    ROUND(v_session_score, 2),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    score            = EXCLUDED.score,
    daily_five_score = EXCLUDED.daily_five_score,
    leetcode_score   = EXCLUDED.leetcode_score,
    mock_exam_score  = EXCLUDED.mock_exam_score,
    session_score    = EXCLUDED.session_score,
    computed_at      = EXCLUDED.computed_at;

  -- ── 7. Daily snapshot ───────────────────────────────────────
  INSERT INTO readiness_score_history (
    user_id, score, daily_five_score, leetcode_score, mock_exam_score, session_score, snapshot_date
  ) VALUES (
    p_user_id, ROUND(v_total, 2), ROUND(v_daily_five, 2),
    ROUND(v_leetcode_score, 2), ROUND(v_mock_score, 2), ROUND(v_session_score, 2), v_today
  )
  ON CONFLICT (user_id, snapshot_date) DO UPDATE SET
    score            = EXCLUDED.score,
    daily_five_score = EXCLUDED.daily_five_score,
    leetcode_score   = EXCLUDED.leetcode_score,
    mock_exam_score  = EXCLUDED.mock_exam_score,
    session_score    = EXCLUDED.session_score;

  RETURN jsonb_build_object(
    'user_id',          p_user_id,
    'score',            ROUND(v_total, 2),
    'daily_five_score', ROUND(v_daily_five, 2),
    'leetcode_score',   ROUND(v_leetcode_score, 2),
    'mock_exam_score',  ROUND(v_mock_score, 2),
    'session_score',    ROUND(v_session_score, 2)
  );
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- RPC: update_leetcode_username_unified
-- Atomic update: sets users.leetcode_username, upserts
-- leetcode_username_whitelist, and initialises leetcode_stats.
-- Called by Flutter when user saves/changes their LeetCode username.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_leetcode_username_unified(
  p_user_id     UUID,
  p_new_username TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_username TEXT;
BEGIN
  -- Validate username not blank
  IF p_new_username IS NULL OR trim(p_new_username) = '' THEN
    RETURN jsonb_build_object('error', 'Username cannot be blank');
  END IF;

  -- Check if another user already holds this username
  IF EXISTS (
    SELECT 1 FROM leetcode_username_whitelist
    WHERE username = p_new_username AND user_id != p_user_id
  ) THEN
    RETURN jsonb_build_object('error', 'Username already claimed by another user');
  END IF;

  -- Get old username for cleanup
  SELECT leetcode_username INTO v_old_username FROM users WHERE id = p_user_id;

  -- Remove old whitelist entry if exists
  IF v_old_username IS NOT NULL THEN
    DELETE FROM leetcode_username_whitelist WHERE username = v_old_username AND user_id = p_user_id;
  END IF;

  -- Update users table
  UPDATE users SET leetcode_username = p_new_username, updated_at = now()
  WHERE id = p_user_id;

  -- Upsert whitelist
  INSERT INTO leetcode_username_whitelist (username, user_id)
  VALUES (p_new_username, p_user_id)
  ON CONFLICT (username) DO UPDATE SET user_id = EXCLUDED.user_id;

  -- Initialise or update leetcode_stats with new username
  INSERT INTO leetcode_stats (user_id, username)
  VALUES (p_user_id, p_new_username)
  ON CONFLICT (user_id) DO UPDATE SET username = EXCLUDED.username;

  -- Also link username in stats to users.leetcode_username
  UPDATE leetcode_stats SET username = p_new_username WHERE user_id = p_user_id;

  RETURN jsonb_build_object('success', true, 'username', p_new_username);
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- RPC: recompute_batch_leetcode_percentiles
-- Recomputes batch_percentile for ALL students in a batch.
-- Called by the Edge Function after any leetcode_stats update.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION recompute_batch_leetcode_percentiles(p_batch_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  WITH ranked AS (
    SELECT
      ls.user_id,
      ls.batch_weighted_score,
      ROW_NUMBER() OVER (ORDER BY ls.batch_weighted_score DESC) AS rnk,
      COUNT(*) OVER () AS total
    FROM leetcode_stats ls
    JOIN users u ON u.id = ls.user_id
    WHERE u.batch_id = p_batch_id
  ),
  percentiles AS (
    SELECT
      user_id,
      CASE WHEN total = 1 THEN 100.0
           ELSE ROUND(((total - rnk)::NUMERIC / (total - 1)) * 100, 2)
      END AS pct
    FROM ranked
  )
  UPDATE leetcode_stats ls
  SET batch_percentile = p.pct
  FROM percentiles p
  WHERE ls.user_id = p.user_id;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- RPC: submit_exam_server_side
-- Evaluates exam answers server-side and writes mock_exam_results.
-- Prevents client-side answer exposure.
-- Called by Next.js API route POST /api/student/exam/submit
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION submit_exam_server_side(
  p_exam_id           UUID,
  p_student_id        UUID,
  p_answers           JSONB,   -- {"question_uuid": "A", ...}
  p_time_taken_seconds INTEGER,
  p_proctoring_flags  JSONB    -- [{type, timestamp}, ...]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exam         RECORD;
  v_q            RECORD;
  v_raw_marks    INTEGER := 0;
  v_total_marks  INTEGER;
  v_norm_score   NUMERIC;
  v_result_id    UUID;
BEGIN
  -- Check exam exists and is active/published
  SELECT id, total_marks, status INTO v_exam FROM mock_exams WHERE id = p_exam_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Exam not found');
  END IF;

  -- Check not already submitted
  IF EXISTS (SELECT 1 FROM mock_exam_results WHERE exam_id = p_exam_id AND student_id = p_student_id) THEN
    RETURN jsonb_build_object('error', 'Already submitted');
  END IF;

  v_total_marks := COALESCE(v_exam.total_marks, 100);

  -- Evaluate each MCQ question
  FOR v_q IN
    SELECT id, correct_option, marks
    FROM mock_exam_questions
    WHERE exam_id = p_exam_id AND question_type = 'mcq'
  LOOP
    IF lower(p_answers->>(v_q.id::TEXT)) = lower(COALESCE(v_q.correct_option, '')) THEN
      v_raw_marks := v_raw_marks + COALESCE(v_q.marks, 1);
    END IF;
  END LOOP;

  v_norm_score := ROUND((v_raw_marks::NUMERIC / GREATEST(v_total_marks, 1)) * 100, 2);

  INSERT INTO mock_exam_results (
    exam_id, student_id, score, raw_marks,
    time_taken_seconds, proctoring_flags, submitted_at
  ) VALUES (
    p_exam_id, p_student_id, v_norm_score, v_raw_marks,
    p_time_taken_seconds, COALESCE(p_proctoring_flags, '[]'), now()
  )
  RETURNING id INTO v_result_id;

  RETURN jsonb_build_object(
    'success',   true,
    'result_id', v_result_id,
    'raw_marks', v_raw_marks,
    'score',     v_norm_score,
    'out_of',    v_total_marks
  );
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Function: updated_at auto-update trigger function
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Apply to users table
DROP TRIGGER IF EXISTS trig_users_updated_at ON users;
CREATE TRIGGER trig_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Apply to knowledge_brain_articles table
DROP TRIGGER IF EXISTS trig_kba_updated_at ON knowledge_brain_articles;
CREATE TRIGGER trig_kba_updated_at
  BEFORE UPDATE ON knowledge_brain_articles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
