-- ============================================================
-- PSGMX — 03_triggers.sql (v2)
-- Database triggers for automatic Edge Function invocation,
-- search vector updates, lineage building, and data integrity.
-- ============================================================
-- Prerequisites:
--   - pg_net extension (HTTP calls)
--   - 02_functions.sql loaded
--   - Edge function URLs set via:
--       ALTER DATABASE postgres SET app.edge_function_url_compute_readiness_score = '...';
--       ALTER DATABASE postgres SET app.edge_function_url_knowledge_ingest = '...';
--       ALTER DATABASE postgres SET app.supabase_service_role_key = '...';
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- TRIGGER HELPER: fire_compute_readiness_score
-- Calls the compute-readiness-score Edge Function via pg_net.
-- Fire-and-forget (async). Falls back to SQL RPC if URL not set.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_compute_readiness_score()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id          UUID;
  v_function_url     TEXT;
  v_service_role_key TEXT;
BEGIN
  -- Determine user_id from triggering table
  IF TG_TABLE_NAME = 'daily_five_streaks' THEN
    v_user_id := NEW.user_id;
  ELSIF TG_TABLE_NAME = 'leetcode_stats' THEN
    v_user_id := NEW.user_id;
    -- Also recompute batch percentiles via SQL function (synchronous)
    PERFORM recompute_batch_leetcode_percentiles(
      (SELECT batch_id FROM users WHERE id = NEW.user_id)
    );
  ELSIF TG_TABLE_NAME = 'mock_exam_results' THEN
    v_user_id := NEW.student_id;
  ELSIF TG_TABLE_NAME = 'placement_attendance' THEN
    v_user_id := NEW.student_id;
  END IF;

  IF v_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_function_url     := current_setting('app.edge_function_url_compute_readiness_score', true);
  v_service_role_key := current_setting('app.supabase_service_role_key', true);

  IF v_function_url IS NOT NULL AND v_function_url != '' THEN
    -- Async HTTP call via pg_net
    PERFORM net.http_post(
      url     := v_function_url,
      body    := jsonb_build_object('user_id', v_user_id::TEXT),
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || COALESCE(v_service_role_key, '')
      )
    );
  ELSE
    -- Fallback: compute synchronously via SQL RPC
    PERFORM compute_readiness_score(v_user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- TRIGGER 1: daily_five_streaks → compute-readiness-score
DROP TRIGGER IF EXISTS trig_daily_five_streaks_readiness ON daily_five_streaks;
CREATE TRIGGER trig_daily_five_streaks_readiness
  AFTER INSERT OR UPDATE ON daily_five_streaks
  FOR EACH ROW EXECUTE FUNCTION trigger_compute_readiness_score();

-- TRIGGER 2: leetcode_stats → compute-readiness-score
DROP TRIGGER IF EXISTS trig_leetcode_stats_readiness ON leetcode_stats;
CREATE TRIGGER trig_leetcode_stats_readiness
  AFTER INSERT OR UPDATE ON leetcode_stats
  FOR EACH ROW EXECUTE FUNCTION trigger_compute_readiness_score();

-- TRIGGER 3: mock_exam_results INSERT → compute-readiness-score
DROP TRIGGER IF EXISTS trig_mock_exam_results_readiness ON mock_exam_results;
CREATE TRIGGER trig_mock_exam_results_readiness
  AFTER INSERT ON mock_exam_results
  FOR EACH ROW EXECUTE FUNCTION trigger_compute_readiness_score();

-- TRIGGER 4: placement_attendance → compute-readiness-score
DROP TRIGGER IF EXISTS trig_placement_attendance_readiness ON placement_attendance;
CREATE TRIGGER trig_placement_attendance_readiness
  AFTER INSERT OR UPDATE ON placement_attendance
  FOR EACH ROW EXECUTE FUNCTION trigger_compute_readiness_score();

-- ──────────────────────────────────────────────────────────────
-- TRIGGER HELPER: trigger_knowledge_ingest
-- Called when placement_log_entries.approval_status → 'approved'
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_knowledge_ingest()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_function_url     TEXT;
  v_service_role_key TEXT;
BEGIN
  -- Only fire when approval_status transitions TO 'approved'
  IF NEW.approval_status = 'approved' AND (OLD.approval_status IS DISTINCT FROM 'approved') THEN
    v_function_url     := current_setting('app.edge_function_url_knowledge_ingest', true);
    v_service_role_key := current_setting('app.supabase_service_role_key', true);

    IF v_function_url IS NOT NULL AND v_function_url != '' THEN
      PERFORM net.http_post(
        url     := v_function_url,
        body    := jsonb_build_object('entry_id', NEW.id::TEXT),
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || COALESCE(v_service_role_key, '')
        )
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- TRIGGER 5: placement_log_entries approval → knowledge-ingest
DROP TRIGGER IF EXISTS trig_placement_log_approval ON placement_log_entries;
CREATE TRIGGER trig_placement_log_approval
  AFTER UPDATE ON placement_log_entries
  FOR EACH ROW EXECUTE FUNCTION trigger_knowledge_ingest();

-- ──────────────────────────────────────────────────────────────
-- TRIGGER 6: new user → auto-build lineage_map
-- Matches roll_no suffix to find seniors in prior batches.
-- e.g. '25MX223' suffix='MX223' matches '24MX223', '23MX223'
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_build_lineage_map()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_roll_suffix TEXT;
  v_senior      RECORD;
BEGIN
  -- Only process users with a roll_no (students)
  IF NEW.roll_no IS NULL OR NEW.batch_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Extract suffix: everything after the leading digits
  -- e.g. '25MX223' → 'MX223'
  v_roll_suffix := regexp_replace(NEW.roll_no, '^\d+', '');
  IF v_roll_suffix = '' OR v_roll_suffix = NEW.roll_no THEN
    RETURN NEW;  -- roll_no doesn't match expected pattern
  END IF;

  -- Find all seniors whose roll_no ends with the same suffix
  -- and whose batch started before the new user's batch
  FOR v_senior IN
    SELECT u.id AS senior_id
    FROM users u
    JOIN batches b_senior ON b_senior.id = u.batch_id
    JOIN batches b_junior ON b_junior.id = NEW.batch_id
    WHERE u.roll_no IS NOT NULL
      AND u.roll_no LIKE '%' || v_roll_suffix
      AND u.roll_no != NEW.roll_no
      AND u.batch_id IS NOT NULL
      AND u.batch_id != NEW.batch_id
      AND b_senior.start_date < b_junior.start_date
  LOOP
    INSERT INTO lineage_map (junior_user_id, senior_user_id, roll_suffix)
    VALUES (NEW.id, v_senior.senior_id, v_roll_suffix)
    ON CONFLICT (junior_user_id, senior_user_id) DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trig_users_build_lineage ON users;
CREATE TRIGGER trig_users_build_lineage
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION trigger_build_lineage_map();

-- ──────────────────────────────────────────────────────────────
-- TRIGGER 7: user role → 'alumni' sets mentorship_open = false
-- Alumni must actively opt in to mentorship.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_alumni_mentorship_default()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'alumni' AND OLD.role IS DISTINCT FROM 'alumni' THEN
    NEW.mentorship_open := false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trig_users_alumni_mentorship ON users;
CREATE TRIGGER trig_users_alumni_mentorship
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION trigger_alumni_mentorship_default();

-- ──────────────────────────────────────────────────────────────
-- TRIGGER 8: knowledge_brain_articles → update search_vector
-- Keeps the full-text search vector current on every write.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_update_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.summary, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.company_name, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(substring(NEW.content, 1, 2000), '')), 'D');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trig_knowledge_search_vector ON knowledge_brain_articles;
CREATE TRIGGER trig_knowledge_search_vector
  BEFORE INSERT OR UPDATE OF title, summary, content, tags, company_name
  ON knowledge_brain_articles
  FOR EACH ROW EXECUTE FUNCTION trigger_update_search_vector();

-- ──────────────────────────────────────────────────────────────
-- FUNCTION: graduate_batch (transactional RPC for batch-graduation Edge Fn)
-- Wraps the entire graduation sequence in a database transaction.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION graduate_batch(p_batch_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_batch         RECORD;
  v_users         UUID[];
  v_notifications JSONB[] := '{}';
  v_uid           UUID;
  v_junior_batch  RECORD;
BEGIN
  -- All inside one transaction (function body IS the transaction unit in PL/pgSQL)

  -- 1. Fetch and lock the batch
  SELECT id, batch_code, status INTO v_batch
  FROM batches WHERE id = p_batch_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Batch % not found', p_batch_id;
  END IF;
  IF v_batch.status = 'graduated' THEN
    RETURN jsonb_build_object('skipped', true, 'reason', 'Already graduated');
  END IF;

  -- 2. Graduate the batch
  UPDATE batches SET status = 'graduated' WHERE id = p_batch_id;

  -- 3. Convert students to alumni
  UPDATE users
  SET role = 'alumni', app_role = 'student', mentorship_open = false, updated_at = now()
  WHERE batch_id = p_batch_id AND role = 'student'
  RETURNING id INTO v_uid;

  -- Collect affected user IDs
  SELECT array_agg(id) INTO v_users
  FROM users WHERE batch_id = p_batch_id AND role = 'alumni';

  -- 4. Insert graduation notifications
  IF v_users IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, title, body, reference_id, reference_type)
    SELECT
      uid,
      'graduation',
      'Congratulations! You''ve graduated from ' || v_batch.batch_code,
      'Your batch ' || v_batch.batch_code || ' has officially graduated. Welcome to the PSGMX alumni network!',
      p_batch_id,
      'batch'
    FROM unnest(v_users) AS uid;
  END IF;

  -- 5. Promote the earliest active_junior batch to active_senior
  SELECT id, batch_code INTO v_junior_batch
  FROM batches
  WHERE status = 'active_junior'
  ORDER BY start_date ASC
  LIMIT 1;

  IF v_junior_batch.id IS NOT NULL THEN
    UPDATE batches SET status = 'active_senior' WHERE id = v_junior_batch.id;
  END IF;

  -- 6. Audit log
  INSERT INTO audit_logs (actor_id, action, target_table, target_id, metadata)
  VALUES (
    NULL, 'batch_graduation', 'batches', p_batch_id,
    jsonb_build_object(
      'batch_code',       v_batch.batch_code,
      'users_graduated',  COALESCE(array_length(v_users, 1), 0),
      'promoted_batch',   v_junior_batch.batch_code,
      'graduated_at',     now()
    )
  );

  RETURN jsonb_build_object(
    'success',        true,
    'batch_code',     v_batch.batch_code,
    'users_graduated', COALESCE(array_length(v_users, 1), 0),
    'promoted_batch', v_junior_batch.batch_code
  );
END;
$$;
