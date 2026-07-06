-- ============================================================
-- PSGMX — 01_rls_policies.sql
-- Row Level Security policies for all tables.
-- Assumes 02_functions.sql has been applied (uses get_user_role, etc.)
-- ============================================================
-- Policy naming convention: <table>_<operation>_<scope>

-- Helper: Check if the current user has a specific role or app_role
-- Usage: (SELECT role FROM get_user_role(auth.uid())) = 'faculty'

-- ──────────────────────────────────────────────────────────────
-- HELPER: is_student_in_my_team
-- Returns true if student_id is in the same team as team_leader_id.
-- Used by placement_attendance and task_completions policies.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_student_in_my_team(
  p_student_id     UUID,
  p_team_leader_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM users s
    JOIN users tl ON tl.id = p_team_leader_id
    WHERE s.id = p_student_id
      AND s.team_id = tl.team_id
      AND s.team_id IS NOT NULL
  );
$$;

-- ──────────────────────────────────────────────────────────────
-- LEETCODE_USERNAME_WHITELIST — users read own; system writes via RPC
-- ──────────────────────────────────────────────────────────────
ALTER TABLE leetcode_username_whitelist ENABLE ROW LEVEL SECURITY;

CREATE POLICY leetcode_whitelist_select_own ON leetcode_username_whitelist
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- Only via the update_leetcode_username_unified SECURITY DEFINER RPC
CREATE POLICY leetcode_whitelist_insert_deny ON leetcode_username_whitelist
  FOR INSERT TO authenticated
  WITH CHECK (false);



-- ──────────────────────────────────────────────────────────────
-- BATCHES — readable by all authenticated users
-- ──────────────────────────────────────────────────────────────
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY batches_select_authenticated ON batches
  FOR SELECT TO authenticated
  USING (true);

-- Only HOD can insert/update batches
CREATE POLICY batches_insert_hod ON batches
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM get_user_role(auth.uid())) = 'hod');

CREATE POLICY batches_update_hod ON batches
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) = 'hod');

-- ──────────────────────────────────────────────────────────────
-- USERS — tiered read access
-- ──────────────────────────────────────────────────────────────
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Every user can read their own row
CREATE POLICY users_select_own ON users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- Faculty and HOD can read all users
CREATE POLICY users_select_faculty_hod ON users
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- Placement Rep can read all users in their batch
CREATE POLICY users_select_placement_rep ON users
  FOR SELECT TO authenticated
  USING (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

-- Every authenticated user can insert their own user row (on signup)
CREATE POLICY users_insert_own ON users
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- Users can update their own profile fields
CREATE POLICY users_update_own ON users
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Faculty can update student app_role and team assignments (but not role)
CREATE POLICY users_update_faculty ON users
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- TEAMS — batch-scoped access
-- ──────────────────────────────────────────────────────────────
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY teams_select_own_batch ON teams
  FOR SELECT TO authenticated
  USING (batch_id = get_batch_for_user(auth.uid())
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY teams_insert_placement_rep ON teams
  FOR INSERT TO authenticated
  WITH CHECK (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

CREATE POLICY teams_update_placement_rep ON teams
  FOR UPDATE TO authenticated
  USING (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

-- ──────────────────────────────────────────────────────────────
-- USER_PERMISSIONS — read by self, managed by Placement Rep/Faculty
-- ──────────────────────────────────────────────────────────────
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_permissions_select_own ON user_permissions
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep');

CREATE POLICY user_permissions_insert_rep_faculty ON user_permissions
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

CREATE POLICY user_permissions_delete_rep_faculty ON user_permissions
  FOR DELETE TO authenticated
  USING (
    (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

-- ──────────────────────────────────────────────────────────────
-- LINEAGE_MAP — read by involved parties + faculty/HOD
-- ──────────────────────────────────────────────────────────────
ALTER TABLE lineage_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineage_map_select ON lineage_map
  FOR SELECT TO authenticated
  USING (
    junior_user_id = auth.uid()
    OR senior_user_id = auth.uid()
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
  );

-- Inserts are done by the trigger function (SECURITY DEFINER), no direct insert policy needed
-- for regular users. Adding a restrictive policy for safety.
CREATE POLICY lineage_map_insert_deny ON lineage_map
  FOR INSERT TO authenticated
  WITH CHECK (false);  -- only trigger (SECURITY DEFINER) can insert

-- ──────────────────────────────────────────────────────────────
-- PLACEMENT_SESSIONS — batch-scoped
-- ──────────────────────────────────────────────────────────────
ALTER TABLE placement_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY placement_sessions_select_batch ON placement_sessions
  FOR SELECT TO authenticated
  USING (
    batch_id = get_batch_for_user(auth.uid())
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
  );

-- Coordinator and Placement Rep can create sessions for their batch
CREATE POLICY placement_sessions_insert_coordinator ON placement_sessions
  FOR INSERT TO authenticated
  WITH CHECK (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) IN ('coordinator', 'placement_rep')
  );

CREATE POLICY placement_sessions_update_coordinator ON placement_sessions
  FOR UPDATE TO authenticated
  USING (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) IN ('coordinator', 'placement_rep')
  );

-- ──────────────────────────────────────────────────────────────
-- PLACEMENT_SESSION_TEAMS
-- ──────────────────────────────────────────────────────────────
ALTER TABLE placement_session_teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY placement_session_teams_select ON placement_session_teams
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM placement_sessions ps
      WHERE ps.id = session_id
        AND (ps.batch_id = get_batch_for_user(auth.uid())
          OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'))
    )
  );

CREATE POLICY placement_session_teams_insert_coordinator ON placement_session_teams
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM placement_sessions ps
      WHERE ps.id = session_id
        AND ps.batch_id = get_batch_for_user(auth.uid())
        AND (SELECT app_role FROM get_user_role(auth.uid())) IN ('coordinator', 'placement_rep')
    )
  );

-- ──────────────────────────────────────────────────────────────
-- PLACEMENT_ATTENDANCE — students read own; team leaders write team
-- ──────────────────────────────────────────────────────────────
ALTER TABLE placement_attendance ENABLE ROW LEVEL SECURITY;

-- Students can read their own attendance
CREATE POLICY placement_attendance_select_own ON placement_attendance
  FOR SELECT TO authenticated
  USING (student_id = auth.uid());

-- Faculty, HOD, Placement Rep can read all attendance in their scope
CREATE POLICY placement_attendance_select_faculty ON placement_attendance
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep');

-- Team Leaders can read attendance for their team
CREATE POLICY placement_attendance_select_team_leader ON placement_attendance
  FOR SELECT TO authenticated
  USING (
    (SELECT app_role FROM get_user_role(auth.uid())) = 'team_leader'
    AND is_student_in_my_team(student_id, auth.uid())
  );

-- Team Leaders can insert attendance for their own team members only
CREATE POLICY placement_attendance_insert_team_leader ON placement_attendance
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT app_role FROM get_user_role(auth.uid())) IN ('team_leader', 'coordinator', 'placement_rep')
    AND is_student_in_my_team(student_id, auth.uid())
    AND marked_by = auth.uid()
  );

-- Team Leaders can update attendance they marked
CREATE POLICY placement_attendance_update_team_leader ON placement_attendance
  FOR UPDATE TO authenticated
  USING (
    marked_by = auth.uid()
    AND (SELECT app_role FROM get_user_role(auth.uid())) IN ('team_leader', 'coordinator', 'placement_rep')
  );

-- ──────────────────────────────────────────────────────────────
-- QUESTION_BANK — all authenticated users read active questions
-- ──────────────────────────────────────────────────────────────
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;

CREATE POLICY question_bank_select_active ON question_bank
  FOR SELECT TO authenticated
  USING (is_active = true);

-- Faculty, HOD, Coordinators can read all (including inactive)
CREATE POLICY question_bank_select_all_faculty ON question_bank
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) IN ('coordinator', 'placement_rep'));

-- Only faculty/HOD/placement_rep can insert/update questions
CREATE POLICY question_bank_insert_faculty ON question_bank
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep');

CREATE POLICY question_bank_update_faculty ON question_bank
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep');

-- ──────────────────────────────────────────────────────────────
-- DAILY_FIVE_STREAKS — students read and update own row only
-- Faculty/HOD can read all
-- ──────────────────────────────────────────────────────────────
ALTER TABLE daily_five_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY daily_five_streaks_select_own ON daily_five_streaks
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY daily_five_streaks_select_faculty_hod ON daily_five_streaks
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY daily_five_streaks_insert_own ON daily_five_streaks
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY daily_five_streaks_update_own ON daily_five_streaks
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- LEETCODE_STATS — students read/write own; faculty/HOD read all
-- ──────────────────────────────────────────────────────────────
ALTER TABLE leetcode_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY leetcode_stats_select_own ON leetcode_stats
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY leetcode_stats_select_batch ON leetcode_stats
  FOR SELECT TO authenticated
  USING (
    -- Batch members can see leaderboard data
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = leetcode_stats.user_id
        AND u.batch_id = get_batch_for_user(auth.uid())
    )
  );

CREATE POLICY leetcode_stats_select_faculty_hod ON leetcode_stats
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY leetcode_stats_insert_own ON leetcode_stats
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY leetcode_stats_update_own ON leetcode_stats
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- DAILY_TASKS — batch-scoped read; coordinator/rep can publish
-- ──────────────────────────────────────────────────────────────
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY daily_tasks_select_batch ON daily_tasks
  FOR SELECT TO authenticated
  USING (batch_id = get_batch_for_user(auth.uid())
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY daily_tasks_insert_coordinator ON daily_tasks
  FOR INSERT TO authenticated
  WITH CHECK (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) IN ('coordinator', 'placement_rep')
  );

CREATE POLICY daily_tasks_update_coordinator ON daily_tasks
  FOR UPDATE TO authenticated
  USING (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) IN ('coordinator', 'placement_rep')
  );

-- ──────────────────────────────────────────────────────────────
-- TASK_COMPLETIONS — students manage own; team leader verifies
-- ──────────────────────────────────────────────────────────────
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY task_completions_select_own ON task_completions
  FOR SELECT TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY task_completions_select_team_leader ON task_completions
  FOR SELECT TO authenticated
  USING (
    (SELECT app_role FROM get_user_role(auth.uid())) IN ('team_leader', 'coordinator', 'placement_rep')
    AND is_student_in_my_team(student_id, auth.uid())
  );

CREATE POLICY task_completions_select_faculty_hod ON task_completions
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY task_completions_insert_own ON task_completions
  FOR INSERT TO authenticated
  WITH CHECK (student_id = auth.uid());

CREATE POLICY task_completions_update_own ON task_completions
  FOR UPDATE TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

-- Team leaders can update verification fields
CREATE POLICY task_completions_update_verify ON task_completions
  FOR UPDATE TO authenticated
  USING (
    (SELECT app_role FROM get_user_role(auth.uid())) IN ('team_leader', 'coordinator', 'placement_rep')
    AND is_student_in_my_team(student_id, auth.uid())
  );

-- ──────────────────────────────────────────────────────────────
-- COMPANIES — all authenticated users read; placement rep writes
-- ──────────────────────────────────────────────────────────────
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY companies_select_authenticated ON companies
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY companies_insert_placement_rep ON companies
  FOR INSERT TO authenticated
  WITH CHECK (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

CREATE POLICY companies_update_placement_rep ON companies
  FOR UPDATE TO authenticated
  USING (
    batch_id = get_batch_for_user(auth.uid())
    AND (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

-- ──────────────────────────────────────────────────────────────
-- PLACEMENT_LOG_ENTRIES — students write own; faculty approves; alumni reads
-- ──────────────────────────────────────────────────────────────
ALTER TABLE placement_log_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY placement_log_entries_select_own ON placement_log_entries
  FOR SELECT TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY placement_log_entries_select_faculty ON placement_log_entries
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY placement_log_entries_select_alumni ON placement_log_entries
  FOR SELECT TO authenticated
  USING (
    (SELECT role FROM get_user_role(auth.uid())) = 'alumni'
    AND (is_anonymous = false OR student_id = auth.uid())
  );

CREATE POLICY placement_log_entries_insert_student ON placement_log_entries
  FOR INSERT TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND (SELECT role FROM get_user_role(auth.uid())) = 'student'
  );

CREATE POLICY placement_log_entries_update_own ON placement_log_entries
  FOR UPDATE TO authenticated
  USING (student_id = auth.uid() AND approval_status = 'pending');

-- Faculty can update approval_status, approved_by, approved_at
CREATE POLICY placement_log_entries_update_faculty ON placement_log_entries
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- READINESS_SCORES — students read own; faculty/HOD/rep read all
-- No direct writes by users — computed by Edge Function (service role)
-- ──────────────────────────────────────────────────────────────
ALTER TABLE readiness_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY readiness_scores_select_own ON readiness_scores
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY readiness_scores_select_batch ON readiness_scores
  FOR SELECT TO authenticated
  USING (
    -- Placement Reps see all in their batch
    (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
    AND EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = readiness_scores.user_id
        AND u.batch_id = get_batch_for_user(auth.uid())
    )
  );

CREATE POLICY readiness_scores_select_faculty_hod ON readiness_scores
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- READINESS_SCORE_HISTORY — same rules as readiness_scores
-- ──────────────────────────────────────────────────────────────
ALTER TABLE readiness_score_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY readiness_score_history_select_own ON readiness_score_history
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY readiness_score_history_select_faculty_hod ON readiness_score_history
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- KNOWLEDGE_BRAIN_ARTICLES — approved articles are public;
-- alumni/students can submit (pending); faculty approves
-- ──────────────────────────────────────────────────────────────
ALTER TABLE knowledge_brain_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY knowledge_brain_articles_select_approved ON knowledge_brain_articles
  FOR SELECT TO authenticated
  USING (approval_status = 'approved');

-- Faculty and HOD can read all (including pending/rejected)
CREATE POLICY knowledge_brain_articles_select_faculty ON knowledge_brain_articles
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- Authors can read their own (even if pending)
CREATE POLICY knowledge_brain_articles_select_own ON knowledge_brain_articles
  FOR SELECT TO authenticated
  USING (author_id = auth.uid());

-- Students and alumni can insert (always pending)
CREATE POLICY knowledge_brain_articles_insert_student_alumni ON knowledge_brain_articles
  FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND approval_status = 'pending'
    AND (SELECT role FROM get_user_role(auth.uid())) IN ('student', 'alumni')
  );

-- Authors can update their own pending articles
CREATE POLICY knowledge_brain_articles_update_own ON knowledge_brain_articles
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid() AND approval_status = 'pending');

-- Faculty can update approval status
CREATE POLICY knowledge_brain_articles_update_faculty ON knowledge_brain_articles
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- KNOWLEDGE_EMBEDDINGS — same visibility as parent article
-- Only Edge Function (service role) writes embeddings
-- ──────────────────────────────────────────────────────────────
ALTER TABLE knowledge_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY knowledge_embeddings_select_approved ON knowledge_embeddings
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM knowledge_brain_articles kba
      WHERE kba.id = article_id AND kba.approval_status = 'approved'
    )
  );

CREATE POLICY knowledge_embeddings_select_faculty ON knowledge_embeddings
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- MOCK_EXAMS — published exams visible to students in target batch
-- ──────────────────────────────────────────────────────────────
ALTER TABLE mock_exams ENABLE ROW LEVEL SECURITY;

-- Faculty/HOD see all exams
CREATE POLICY mock_exams_select_faculty ON mock_exams
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- Students see published/active/completed exams for their batch
CREATE POLICY mock_exams_select_student ON mock_exams
  FOR SELECT TO authenticated
  USING (
    status IN ('published', 'active', 'completed')
    AND (target_batch_id IS NULL OR target_batch_id = get_batch_for_user(auth.uid()))
    AND (SELECT role FROM get_user_role(auth.uid())) = 'student'
  );

-- Only faculty can create/update exams
CREATE POLICY mock_exams_insert_faculty ON mock_exams
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY mock_exams_update_faculty ON mock_exams
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- MOCK_EXAM_QUESTIONS — same visibility as mock_exams
-- ──────────────────────────────────────────────────────────────
ALTER TABLE mock_exam_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY mock_exam_questions_select_faculty ON mock_exam_questions
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY mock_exam_questions_select_student ON mock_exam_questions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM mock_exams me
      WHERE me.id = exam_id
        AND me.status IN ('active')
        AND (me.target_batch_id IS NULL OR me.target_batch_id = get_batch_for_user(auth.uid()))
    )
    AND (SELECT role FROM get_user_role(auth.uid())) = 'student'
  );

CREATE POLICY mock_exam_questions_insert_faculty ON mock_exam_questions
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

CREATE POLICY mock_exam_questions_update_faculty ON mock_exam_questions
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- ──────────────────────────────────────────────────────────────
-- MOCK_EXAM_RESULTS — students read own ONLY; faculty/HOD read all
-- ──────────────────────────────────────────────────────────────
ALTER TABLE mock_exam_results ENABLE ROW LEVEL SECURITY;

-- Students can ONLY see their own results
CREATE POLICY mock_exam_results_select_own ON mock_exam_results
  FOR SELECT TO authenticated
  USING (student_id = auth.uid()
    AND (SELECT role FROM get_user_role(auth.uid())) = 'student');

-- Faculty and HOD can read all results
CREATE POLICY mock_exam_results_select_faculty ON mock_exam_results
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));

-- Students can submit their own results
CREATE POLICY mock_exam_results_insert_student ON mock_exam_results
  FOR INSERT TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND (SELECT role FROM get_user_role(auth.uid())) = 'student'
  );

-- ──────────────────────────────────────────────────────────────
-- ANNOUNCEMENTS — all authenticated users read
-- Faculty/HOD/Placement Rep can post
-- ──────────────────────────────────────────────────────────────
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY announcements_select_authenticated ON announcements
  FOR SELECT TO authenticated
  USING (
    batch_id IS NULL  -- global announcement
    OR batch_id = get_batch_for_user(auth.uid())
    OR (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
  );

CREATE POLICY announcements_insert_faculty_rep ON announcements
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod')
    OR (SELECT app_role FROM get_user_role(auth.uid())) = 'placement_rep'
  );

-- ──────────────────────────────────────────────────────────────
-- NOTIFICATIONS — users read/update their own only
-- Edge Function (service role) inserts
-- ──────────────────────────────────────────────────────────────
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notifications_select_own ON notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY notifications_update_own ON notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- COLLABORATION_POSTS — visibility-based access
-- ──────────────────────────────────────────────────────────────
ALTER TABLE collaboration_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY collaboration_posts_select ON collaboration_posts
  FOR SELECT TO authenticated
  USING (
    is_active = true
    AND (
      visibility = 'department'
      OR (visibility = 'batch' AND EXISTS (
        SELECT 1 FROM users u1, users u2
        WHERE u1.id = posted_by AND u2.id = auth.uid()
          AND u1.batch_id = u2.batch_id
      ))
      OR (visibility = 'lineage_only' AND EXISTS (
        SELECT 1 FROM lineage_map lm
        WHERE (lm.junior_user_id = auth.uid() AND lm.senior_user_id = posted_by)
          OR (lm.senior_user_id = auth.uid() AND lm.junior_user_id = posted_by)
      ))
      OR posted_by = auth.uid()
    )
  );

CREATE POLICY collaboration_posts_insert_alumni_student ON collaboration_posts
  FOR INSERT TO authenticated
  WITH CHECK (
    posted_by = auth.uid()
    AND (SELECT role FROM get_user_role(auth.uid())) IN ('alumni', 'student')
  );

CREATE POLICY collaboration_posts_update_own ON collaboration_posts
  FOR UPDATE TO authenticated
  USING (posted_by = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- LINEAGE_MESSAGES — sender and receiver can read; alumni sends
-- ──────────────────────────────────────────────────────────────
ALTER TABLE lineage_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineage_messages_select ON lineage_messages
  FOR SELECT TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Alumni can send messages to their matched juniors
CREATE POLICY lineage_messages_insert_alumni ON lineage_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND (SELECT role FROM get_user_role(auth.uid())) = 'alumni'
    AND EXISTS (
      SELECT 1 FROM lineage_map lm
      WHERE lm.senior_user_id = auth.uid()
        AND lm.junior_user_id = receiver_id
    )
  );

-- Mark messages as read
CREATE POLICY lineage_messages_update_receiver ON lineage_messages
  FOR UPDATE TO authenticated
  USING (receiver_id = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- AUDIT_LOGS — HOD and faculty can read; no user writes (Edge Function only)
-- ──────────────────────────────────────────────────────────────
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_logs_select_faculty_hod ON audit_logs
  FOR SELECT TO authenticated
  USING ((SELECT role FROM get_user_role(auth.uid())) IN ('faculty', 'hod'));
