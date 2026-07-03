-- Trigger to update readiness score when attendance changes
CREATE OR REPLACE FUNCTION trigger_readiness_attendance()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM compute_readiness_score(OLD.user_id);
  ELSE
    PERFORM compute_readiness_score(NEW.user_id);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS readiness_attendance_trigger ON attendance_records;
CREATE TRIGGER readiness_attendance_trigger
AFTER INSERT OR UPDATE OR DELETE ON attendance_records
FOR EACH ROW EXECUTE FUNCTION trigger_readiness_attendance();

-- Trigger to update readiness score when daily five streak changes
CREATE OR REPLACE FUNCTION trigger_readiness_daily_five()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM compute_readiness_score(OLD.user_id);
  ELSE
    PERFORM compute_readiness_score(NEW.user_id);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS readiness_daily_five_trigger ON daily_five_streaks;
CREATE TRIGGER readiness_daily_five_trigger
AFTER INSERT OR UPDATE OR DELETE ON daily_five_streaks
FOR EACH ROW EXECUTE FUNCTION trigger_readiness_daily_five();

-- Trigger to update readiness score when task completions change
CREATE OR REPLACE FUNCTION trigger_readiness_tasks()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM compute_readiness_score(OLD.user_id);
  ELSE
    PERFORM compute_readiness_score(NEW.user_id);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS readiness_tasks_trigger ON task_completions;
CREATE TRIGGER readiness_tasks_trigger
AFTER INSERT OR UPDATE OR DELETE ON task_completions
FOR EACH ROW EXECUTE FUNCTION trigger_readiness_tasks();

-- Trigger to update readiness score when leetcode stats change
CREATE OR REPLACE FUNCTION trigger_readiness_leetcode()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Find the user(s) with this leetcode username
  IF TG_OP = 'DELETE' THEN
    FOR v_user_id IN SELECT id FROM users WHERE leetcode_username = OLD.username LOOP
      PERFORM compute_readiness_score(v_user_id);
    END LOOP;
  ELSE
    FOR v_user_id IN SELECT id FROM users WHERE leetcode_username = NEW.username LOOP
      PERFORM compute_readiness_score(v_user_id);
    END LOOP;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS readiness_leetcode_trigger ON leetcode_stats;
CREATE TRIGGER readiness_leetcode_trigger
AFTER INSERT OR UPDATE OR DELETE ON leetcode_stats
FOR EACH ROW EXECUTE FUNCTION trigger_readiness_leetcode();
