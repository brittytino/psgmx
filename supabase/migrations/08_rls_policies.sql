-- ============================================================
-- PSGMX — 08_rls_policies.sql
-- ============================================================
-- Row-Level Security for every table. Entirely on the Gen-C role model
-- (role_label / roles JSONB / user_permissions) — no dependency on the
-- dead get_user_role()/role/app_role layer from the old generation-A files.
--
-- Run AFTER 07_triggers.sql (needs every helper function to already exist).
-- ============================================================

-- ══════════════════════════════════════════════════════════════
-- Core identity/org tables
-- ══════════════════════════════════════════════════════════════

ALTER TABLE users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE whitelist         ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams             ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs        ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config        ENABLE ROW LEVEL SECURITY;

-- users
CREATE POLICY "users_read_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_read_placement_rep" ON users FOR SELECT USING (is_placement_rep(auth.uid()));
CREATE POLICY "users_read_coordinator" ON users FOR SELECT USING (is_coordinator(auth.uid()));
CREATE POLICY "users_read_faculty_hod" ON users FOR SELECT USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "users_read_team" ON users FOR SELECT
    USING (is_team_leader(auth.uid()) AND team_id = get_user_team(auth.uid()));
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "users_update_placement_rep" ON users FOR UPDATE USING (is_placement_rep(auth.uid()));
CREATE POLICY "users_insert_auth" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- whitelist
CREATE POLICY "whitelist_read_all" ON whitelist FOR SELECT USING (TRUE);
CREATE POLICY "whitelist_manage_placement_rep" ON whitelist FOR ALL USING (is_placement_rep(auth.uid()));
CREATE POLICY "whitelist_manage_manage_members" ON whitelist FOR ALL
    USING (user_has_permission(auth.uid(), 'manage_members'))
    WITH CHECK (user_has_permission(auth.uid(), 'manage_members'));

-- batches: everyone can read; only service-role (cron) mutates
CREATE POLICY "batches_read_all" ON batches FOR SELECT TO authenticated USING (TRUE);

-- teams
CREATE POLICY "teams_read_all" ON teams FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "teams_write_configure_teams" ON teams FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'configure_teams'))
    WITH CHECK (user_has_permission(auth.uid(), 'configure_teams'));

-- user_permissions
CREATE POLICY "permissions_read_own" ON user_permissions FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "permissions_read_manage_members" ON user_permissions FOR SELECT TO authenticated
    USING (user_has_permission(auth.uid(), 'manage_members'));
CREATE POLICY "permissions_write_manage_members" ON user_permissions FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'manage_members'))
    WITH CHECK (user_has_permission(auth.uid(), 'manage_members'));

-- audit_logs — insert-only from the app, actor must be self; no app-level
-- UPDATE/DELETE at all (only service_role, which bypasses RLS).
CREATE POLICY "audit_logs_select_faculty_hod" ON audit_logs FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "audit_logs_select_placement_rep" ON audit_logs FOR SELECT TO authenticated
    USING (is_placement_rep(auth.uid()));
CREATE POLICY "audit_logs_insert_auth" ON audit_logs FOR INSERT
    WITH CHECK (auth.uid() = actor_id AND actor_id IS NOT NULL);

-- app_config
CREATE POLICY "app_config_read_public" ON app_config FOR SELECT USING (TRUE);
CREATE POLICY "app_config_update_admin" ON app_config FOR UPDATE
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- ══════════════════════════════════════════════════════════════
-- Academic: daily tasks, defaulters, daily content, Daily Five, readiness
-- ══════════════════════════════════════════════════════════════

ALTER TABLE daily_tasks              ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE defaulter_flags          ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_task_bank        ENABLE ROW LEVEL SECURITY;
ALTER TABLE apti_dsa_daily_bank      ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_bank            ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_five_streaks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_five_attempts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE readiness_scores         ENABLE ROW LEVEL SECURITY;
ALTER TABLE leetcode_stats           ENABLE ROW LEVEL SECURITY;

-- daily_tasks
CREATE POLICY "daily_tasks_read_all" ON daily_tasks FOR SELECT USING (TRUE);
CREATE POLICY "daily_tasks_insert" ON daily_tasks FOR INSERT
    WITH CHECK (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()) OR user_has_permission(auth.uid(), 'publish_tasks'));
CREATE POLICY "daily_tasks_update" ON daily_tasks FOR UPDATE
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()) OR user_has_permission(auth.uid(), 'publish_tasks'));
CREATE POLICY "daily_tasks_delete" ON daily_tasks FOR DELETE USING (is_placement_rep(auth.uid()));

-- task_completions
CREATE POLICY "task_completions_read_own" ON task_completions FOR SELECT TO authenticated
    USING (user_id = auth.uid());
CREATE POLICY "task_completions_read_team" ON task_completions FOR SELECT TO authenticated
    USING (is_team_leader(auth.uid()) AND EXISTS (
        SELECT 1 FROM users WHERE users.id = task_completions.user_id AND users.team_id = get_user_team(auth.uid())
    ));
CREATE POLICY "task_completions_read_rep" ON task_completions FOR SELECT TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));
CREATE POLICY "task_completions_insert_own" ON task_completions FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        OR (is_team_leader(auth.uid()) AND EXISTS (
            SELECT 1 FROM users WHERE users.id = task_completions.user_id AND users.team_id = get_user_team(auth.uid())
        ))
        OR is_placement_rep(auth.uid()) OR is_coordinator(auth.uid())
    );
CREATE POLICY "task_completions_update_verify" ON task_completions FOR UPDATE TO authenticated
    USING (
        (is_team_leader(auth.uid()) AND EXISTS (
            SELECT 1 FROM users WHERE users.id = task_completions.user_id AND users.team_id = get_user_team(auth.uid())
        ))
        OR is_placement_rep(auth.uid()) OR is_coordinator(auth.uid())
    );
CREATE POLICY "task_completions_update_own" ON task_completions FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- defaulter_flags
CREATE POLICY "defaulter_read_own" ON defaulter_flags FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "defaulter_read_team" ON defaulter_flags FOR SELECT TO authenticated
    USING (is_team_leader(auth.uid()) AND EXISTS (
        SELECT 1 FROM users WHERE users.id = defaulter_flags.user_id AND users.team_id = get_user_team(auth.uid())
    ));
CREATE POLICY "defaulter_read_admin" ON defaulter_flags FOR SELECT TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));
CREATE POLICY "defaulter_manage_admin" ON defaulter_flags FOR ALL TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()))
    WITH CHECK (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- project_task_bank / apti_dsa_daily_bank
CREATE POLICY "project_task_bank_read" ON project_task_bank FOR SELECT TO authenticated USING (is_active = TRUE);
CREATE POLICY "project_task_bank_write" ON project_task_bank FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'publish_tasks')) WITH CHECK (user_has_permission(auth.uid(), 'publish_tasks'));
CREATE POLICY "apti_dsa_daily_bank_read" ON apti_dsa_daily_bank FOR SELECT TO authenticated USING (is_active = TRUE);
CREATE POLICY "apti_dsa_daily_bank_write" ON apti_dsa_daily_bank FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'publish_tasks')) WITH CHECK (user_has_permission(auth.uid(), 'publish_tasks'));
CREATE POLICY "daily_content_completions_own" ON daily_content_completions FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- question_bank — correct_option column itself is locked down separately
-- in 09_grants_security.sql; row-level access is open to all authenticated.
CREATE POLICY "qbank_read_active" ON question_bank FOR SELECT TO authenticated USING (is_active = TRUE);
CREATE POLICY "qbank_write" ON question_bank FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'publish_tasks')) WITH CHECK (user_has_permission(auth.uid(), 'publish_tasks'));

-- daily_five_streaks — no direct authenticated INSERT/UPDATE at all; every
-- write goes through the SECURITY DEFINER RPCs in 06_functions.sql.
CREATE POLICY "streaks_read_own" ON daily_five_streaks FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "streaks_read_admin" ON daily_five_streaks FOR SELECT TO authenticated
    USING (user_has_permission(auth.uid(), 'view_batch_analytics'));

-- daily_five_attempts — RPC-only writes, same reasoning.
CREATE POLICY "daily_five_attempts_select_own" ON daily_five_attempts FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "daily_five_attempts_select_faculty_hod" ON daily_five_attempts FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));

-- readiness_scores — append-only log; app can only insert its own row
-- (compute_readiness_score() itself is SECURITY DEFINER and bypasses this).
CREATE POLICY "readiness_read_own" ON readiness_scores FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "readiness_read_admin" ON readiness_scores FOR SELECT TO authenticated
    USING (user_has_permission(auth.uid(), 'view_batch_analytics'));
CREATE POLICY "readiness_insert_system" ON readiness_scores FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- leetcode_stats
CREATE POLICY "leetcode_stats_read_all" ON leetcode_stats FOR SELECT USING (TRUE);
CREATE POLICY "leetcode_stats_manage_auth" ON leetcode_stats FOR ALL USING (auth.role() = 'authenticated');

-- ══════════════════════════════════════════════════════════════
-- Placement
-- ══════════════════════════════════════════════════════════════

ALTER TABLE companies                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_log_entries     ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_sessions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_attendance      ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_attendance_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records        ENABLE ROW LEVEL SECURITY;

-- companies
CREATE POLICY "companies_read_all" ON companies FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "companies_write" ON companies FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'manage_company_records'))
    WITH CHECK (user_has_permission(auth.uid(), 'manage_company_records'));

-- placement_log_entries
CREATE POLICY "log_entries_read_all" ON placement_log_entries FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "log_entries_insert_senior" ON placement_log_entries FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (SELECT 1 FROM users u JOIN batches b ON b.id = u.batch_id WHERE u.id = auth.uid() AND b.status = 'active_senior')
    );
CREATE POLICY "log_entries_update_own" ON placement_log_entries FOR UPDATE TO authenticated
    USING (user_id = auth.uid() AND is_moderated = FALSE) WITH CHECK (user_id = auth.uid());
CREATE POLICY "log_entries_moderate" ON placement_log_entries FOR UPDATE TO authenticated
    USING (user_has_permission(auth.uid(), 'moderate_placement_log'));

-- placement_sessions
CREATE POLICY "placement_sessions_read" ON placement_sessions FOR SELECT TO authenticated
    USING (batch_id = get_user_batch_id(auth.uid()));
CREATE POLICY "placement_sessions_write" ON placement_sessions FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'schedule_placement_sessions'))
    WITH CHECK (user_has_permission(auth.uid(), 'schedule_placement_sessions'));

-- placement_attendance
CREATE POLICY "placement_attendance_read_own" ON placement_attendance FOR SELECT TO authenticated
    USING (user_id = auth.uid());
CREATE POLICY "placement_attendance_write" ON placement_attendance FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'mark_placement_attendance'))
    WITH CHECK (user_has_permission(auth.uid(), 'mark_placement_attendance'));
CREATE POLICY "placement_attendance_read_admin" ON placement_attendance FOR SELECT TO authenticated
    USING (
        user_has_permission(auth.uid(), 'view_batch_analytics')
        AND EXISTS (SELECT 1 FROM placement_sessions ps WHERE ps.id = placement_attendance.session_id AND ps.batch_id = get_user_batch_id(auth.uid()))
    );

-- scheduled_attendance_dates
CREATE POLICY "scheduled_dates_read_all" ON scheduled_attendance_dates FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "scheduled_dates_manage" ON scheduled_attendance_dates FOR ALL TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

-- attendance_records
CREATE POLICY "attendance_read_own" ON attendance_records FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "attendance_read_team" ON attendance_records FOR SELECT TO authenticated
    USING (is_team_leader(auth.uid()) AND team_id = get_user_team(auth.uid()));
CREATE POLICY "attendance_read_admins" ON attendance_records FOR SELECT TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));
CREATE POLICY "attendance_insert_team_leader" ON attendance_records FOR INSERT TO authenticated
    WITH CHECK (is_team_leader(auth.uid()) AND team_id = get_user_team(auth.uid()) AND is_date_scheduled(date));
CREATE POLICY "attendance_insert_placement_rep" ON attendance_records FOR INSERT TO authenticated
    WITH CHECK (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));
CREATE POLICY "attendance_update_team_leader" ON attendance_records FOR UPDATE TO authenticated
    USING (is_team_leader(auth.uid()) AND team_id = get_user_team(auth.uid()) AND is_date_scheduled(date))
    WITH CHECK (is_team_leader(auth.uid()) AND team_id = get_user_team(auth.uid()) AND is_date_scheduled(date));
CREATE POLICY "attendance_update_placement_rep" ON attendance_records FOR UPDATE TO authenticated
    USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));
CREATE POLICY "attendance_delete_placement_rep" ON attendance_records FOR DELETE TO authenticated
    USING (is_placement_rep(auth.uid()));

-- ══════════════════════════════════════════════════════════════
-- Knowledge Brain / FYP / mock exams / alumni
-- ══════════════════════════════════════════════════════════════

ALTER TABLE knowledge_brain_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_embeddings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_query_logs            ENABLE ROW LEVEL SECURITY;
ALTER TABLE lineage_map              ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_projects             ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_progress_logs        ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_feedback             ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_exams               ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_exam_questions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_exam_results        ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_posts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback            ENABLE ROW LEVEL SECURITY;

-- knowledge_brain_articles / knowledge_embeddings
CREATE POLICY "knowledge_brain_articles_select_approved" ON knowledge_brain_articles FOR SELECT TO authenticated
    USING (approval_status = 'approved');
CREATE POLICY "knowledge_brain_articles_select_own" ON knowledge_brain_articles FOR SELECT TO authenticated
    USING (author_id = auth.uid());
CREATE POLICY "knowledge_brain_articles_select_faculty_hod" ON knowledge_brain_articles FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "knowledge_brain_articles_insert_own" ON knowledge_brain_articles FOR INSERT TO authenticated
    WITH CHECK (author_id = auth.uid());
CREATE POLICY "knowledge_brain_articles_update_faculty_hod" ON knowledge_brain_articles FOR UPDATE TO authenticated
    USING (is_faculty_or_hod(auth.uid())) WITH CHECK (is_faculty_or_hod(auth.uid()));
-- knowledge_embeddings: no SELECT policy for authenticated — read only via
-- the knowledge_semantic_search() SECURITY DEFINER RPC.
CREATE POLICY "knowledge_embeddings_write_faculty_hod" ON knowledge_embeddings FOR ALL TO authenticated
    USING (is_faculty_or_hod(auth.uid())) WITH CHECK (is_faculty_or_hod(auth.uid()));

-- ai_query_logs — no client INSERT policy; the API route logs via service_role.
CREATE POLICY "ai_query_logs_select_faculty_hod" ON ai_query_logs FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));

-- lineage_map
CREATE POLICY "lineage_map_select_own" ON lineage_map FOR SELECT TO authenticated
    USING (student_id = auth.uid() OR senior_user_id = auth.uid());
CREATE POLICY "lineage_map_select_faculty_hod" ON lineage_map FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "lineage_map_write_faculty_hod" ON lineage_map FOR ALL TO authenticated
    USING (is_faculty_or_hod(auth.uid())) WITH CHECK (is_faculty_or_hod(auth.uid()));

-- fyp_projects / fyp_progress_logs / fyp_feedback
CREATE POLICY "fyp_projects_select_own" ON fyp_projects FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "fyp_projects_select_faculty_hod" ON fyp_projects FOR SELECT TO authenticated USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "fyp_projects_write_own" ON fyp_projects FOR INSERT TO authenticated WITH CHECK (student_id = auth.uid());
CREATE POLICY "fyp_projects_update_own" ON fyp_projects FOR UPDATE TO authenticated
    USING (student_id = auth.uid()) WITH CHECK (student_id = auth.uid());
CREATE POLICY "fyp_projects_update_faculty_hod" ON fyp_projects FOR UPDATE TO authenticated
    USING (is_faculty_or_hod(auth.uid())) WITH CHECK (is_faculty_or_hod(auth.uid()));

CREATE POLICY "fyp_progress_logs_select_own" ON fyp_progress_logs FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM fyp_projects p WHERE p.id = fyp_progress_logs.project_id AND p.student_id = auth.uid()));
CREATE POLICY "fyp_progress_logs_select_faculty_hod" ON fyp_progress_logs FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "fyp_progress_logs_insert_own" ON fyp_progress_logs FOR INSERT TO authenticated
    WITH CHECK (student_id = auth.uid());

CREATE POLICY "fyp_feedback_select_own" ON fyp_feedback FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM fyp_projects p WHERE p.id = fyp_feedback.project_id AND p.student_id = auth.uid()));
CREATE POLICY "fyp_feedback_select_faculty_hod" ON fyp_feedback FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "fyp_feedback_insert_faculty_hod" ON fyp_feedback FOR INSERT TO authenticated
    WITH CHECK (is_faculty_or_hod(auth.uid()));

-- mock_exams / mock_exam_questions / mock_exam_results — grading + session
-- lifecycle is RPC-only (start_mock_exam / submit_exam_server_side); no
-- direct INSERT/UPDATE policy for authenticated on results.
CREATE POLICY "mock_exams_select_all" ON mock_exams FOR SELECT TO authenticated USING (true);
CREATE POLICY "mock_exams_write_faculty_hod" ON mock_exams FOR ALL TO authenticated
    USING (is_faculty_or_hod(auth.uid())) WITH CHECK (is_faculty_or_hod(auth.uid()));

CREATE POLICY "mock_exam_questions_select_all" ON mock_exam_questions FOR SELECT TO authenticated USING (true);
CREATE POLICY "mock_exam_questions_write_faculty_hod" ON mock_exam_questions FOR ALL TO authenticated
    USING (is_faculty_or_hod(auth.uid())) WITH CHECK (is_faculty_or_hod(auth.uid()));

CREATE POLICY "mock_exam_results_select_own" ON mock_exam_results FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "mock_exam_results_select_faculty_hod" ON mock_exam_results FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()));

-- collaboration_posts (alumni marketplace)
CREATE POLICY "collaboration_posts_select" ON collaboration_posts FOR SELECT TO authenticated
    USING (
        is_active = true AND (
            visibility = 'department'
            OR posted_by = auth.uid()
            OR EXISTS (
                SELECT 1 FROM users u1, users u2
                WHERE u1.id = auth.uid() AND u2.id = collaboration_posts.posted_by
                  AND visibility = 'batch' AND u1.batch_id = u2.batch_id
            )
        )
    );
CREATE POLICY "collaboration_posts_insert_own" ON collaboration_posts FOR INSERT TO authenticated WITH CHECK (posted_by = auth.uid());
CREATE POLICY "collaboration_posts_update_own" ON collaboration_posts FOR UPDATE TO authenticated
    USING (posted_by = auth.uid()) WITH CHECK (posted_by = auth.uid());

-- user_feedback
CREATE POLICY "user_feedback_select_own" ON user_feedback FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "user_feedback_select_faculty_hod" ON user_feedback FOR SELECT TO authenticated USING (is_faculty_or_hod(auth.uid()));
CREATE POLICY "user_feedback_insert_own" ON user_feedback FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- ══════════════════════════════════════════════════════════════
-- Notifications / announcements / eCampus
-- ══════════════════════════════════════════════════════════════

ALTER TABLE notifications          ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecampus_attendance     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecampus_cgpa           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecampus_bunked_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecampus_ca_marks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecampus_ca_timetable   ENABLE ROW LEVEL SECURITY;
ALTER TABLE ca_timetable_global    ENABLE ROW LEVEL SECURITY;
-- user_ecampus_credentials: RLS enabled, deliberately ZERO policies below
-- (already ALTER'd in 05_schema_misc.sql) — service_role only.

CREATE POLICY "notifications_read_active" ON notifications FOR SELECT USING (is_active = TRUE);
CREATE POLICY "notifications_manage" ON notifications FOR ALL USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

CREATE POLICY "announcements_read_all" ON announcements FOR SELECT USING (TRUE);
CREATE POLICY "announcements_manage" ON announcements FOR ALL USING (is_placement_rep(auth.uid()) OR is_coordinator(auth.uid()));

CREATE POLICY "notification_reads_own" ON notification_reads FOR ALL USING (user_id = auth.uid());

CREATE POLICY "students_read_own_attendance" ON ecampus_attendance FOR SELECT
    USING (reg_no = (SELECT reg_no FROM users WHERE id = auth.uid()));
CREATE POLICY "admins_read_all_attendance" ON ecampus_attendance FOR SELECT
    USING (is_coordinator(auth.uid()) OR is_placement_rep(auth.uid()));

CREATE POLICY "students_read_own_cgpa" ON ecampus_cgpa FOR SELECT
    USING (reg_no = (SELECT reg_no FROM users WHERE id = auth.uid()));
CREATE POLICY "admins_read_all_cgpa" ON ecampus_cgpa FOR SELECT
    USING (is_coordinator(auth.uid()) OR is_placement_rep(auth.uid()));

CREATE POLICY "students_read_own_bunked" ON ecampus_bunked_subjects FOR SELECT
    USING (reg_no = (SELECT reg_no FROM users WHERE id = auth.uid()));
CREATE POLICY "admins_read_all_bunked" ON ecampus_bunked_subjects FOR SELECT
    USING (is_coordinator(auth.uid()) OR is_placement_rep(auth.uid()));

CREATE POLICY "student_read_own_ca" ON ecampus_ca_marks FOR SELECT
    USING (reg_no = (SELECT reg_no FROM users WHERE id = auth.uid()));
CREATE POLICY "admin_read_all_ca" ON ecampus_ca_marks FOR SELECT
    USING (is_coordinator(auth.uid()) OR is_placement_rep(auth.uid()));

CREATE POLICY "student_read_own_ca_timetable" ON ecampus_ca_timetable FOR SELECT
    USING (reg_no = (SELECT reg_no FROM users WHERE id = auth.uid()));
CREATE POLICY "admin_read_all_ca_timetable" ON ecampus_ca_timetable FOR SELECT
    USING (is_coordinator(auth.uid()) OR is_placement_rep(auth.uid()));

CREATE POLICY "authenticated_read_ca_timetable_global" ON ca_timetable_global FOR SELECT TO authenticated USING (true);

DO $$
BEGIN
    RAISE NOTICE '✅ 08_rls_policies.sql complete — RLS enabled and policies applied to every table.';
    RAISE NOTICE 'NEXT: run 09_grants_security.sql';
END $$;
