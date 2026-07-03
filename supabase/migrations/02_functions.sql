-- ============================================================
-- PSGMX — 02_functions.sql
-- Helper SQL functions used by RLS policies and application code.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- get_user_role(uid)
-- Returns the role and app_role for a given user UUID.
-- Used in RLS policies to avoid repeated subqueries.
-- SECURITY DEFINER allows it to bypass RLS when reading users table.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_user_role(uid UUID)
RETURNS TABLE(role TEXT, app_role TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.role, u.app_role
  FROM users u
  WHERE u.id = uid;
$$;

-- ──────────────────────────────────────────────────────────────
-- get_batch_for_user(uid)
-- Returns the batch_id UUID for a student user.
-- Returns NULL for faculty/HOD.
-- Used in RLS policies to scope data to a student's own batch.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_batch_for_user(uid UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT batch_id FROM users WHERE id = uid;
$$;

-- ──────────────────────────────────────────────────────────────
-- get_team_for_user(uid)
-- Returns the team_id UUID for a student.
-- Returns NULL if not on a team.
-- Used in RLS policies for team-scoped attendance marking.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_team_for_user(uid UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT team_id FROM users WHERE id = uid;
$$;

-- ──────────────────────────────────────────────────────────────
-- is_student_in_my_team(student_uid, team_leader_uid)
-- Returns true if student_uid belongs to the same team as team_leader_uid.
-- Used in the placement_attendance INSERT policy for Team Leaders.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_student_in_my_team(student_uid UUID, team_leader_uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users s
    JOIN users tl ON tl.id = team_leader_uid
    WHERE s.id = student_uid
      AND s.team_id = tl.team_id
      AND s.team_id IS NOT NULL
  );
$$;

-- ──────────────────────────────────────────────────────────────
-- update_updated_at_column()
-- Generic trigger function to auto-update the updated_at timestamp.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Apply updated_at trigger to tables that have the column
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER knowledge_brain_articles_updated_at
  BEFORE UPDATE ON knowledge_brain_articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
