-- ============================================================
-- PSGMX — 05_rls_policies.sql
-- Row Level Security (RLS) Access Control Architecture
-- ============================================================

-- ── 1. Enable RLS on All Tables ──────────────────────────────
ALTER TABLE public.batches                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whitelist                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whitelist_email_aliases   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.active_sessions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_locks             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_completions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.defaulter_flags           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_task_bank         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.apti_dsa_daily_bank       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_content_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculty                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_slots           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_sessions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ca_marks                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_records           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placements                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placement_statistics      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tier_targets              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_bank             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_five_attempts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_five_streaks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.readiness_scores          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.readiness_dimension_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_experience           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.code_problems             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.code_submissions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leetcode_stats            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentor_assignments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lineage_requests          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_test_templates       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_test_attempts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communication_attempts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communication_prompt_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fyp_topics                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.senior_articles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_comments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_reports        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderated_content         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_reads        ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.knowledge_brain_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_embeddings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_patterns        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lineage_map               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exams                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exam_questions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exam_results         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generated_tests        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaboration_posts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sprint_attempts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_journeys           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_events         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fyp_projects              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fyp_progress_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leetcode_stat_snapshots   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fyp_feedback              ENABLE ROW LEVEL SECURITY;

-- ── 2. Public / App Configurations & Open Content ────────────
CREATE POLICY "app_config_read_all" ON public.app_config FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "batches_read_all"    ON public.batches FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "teams_read_all"      ON public.teams FOR SELECT TO authenticated USING (true);
CREATE POLICY "tier_targets_read"   ON public.tier_targets FOR SELECT TO authenticated USING (true);
CREATE POLICY "articles_read_published" ON public.senior_articles FOR SELECT TO authenticated USING (is_published = true);
CREATE POLICY "code_problems_read"  ON public.code_problems FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "quests_read"         ON public.quests FOR SELECT TO authenticated USING (is_active = true);

-- ── 3. Users Profile Policies ────────────────────────────────
CREATE POLICY "users_read_directory" ON public.users FOR SELECT TO authenticated USING (true);
CREATE POLICY "users_update_own"     ON public.users FOR UPDATE TO authenticated USING (id = auth.uid() OR id = public.current_user_id());

-- ── 4. Private Progress & Evidence Guardrails ────────────────
CREATE POLICY "readiness_scores_read_own" ON public.readiness_scores FOR SELECT TO authenticated USING (user_id = public.current_user_id() OR user_id = auth.uid());
CREATE POLICY "readiness_dimensions_read_own" ON public.readiness_dimension_scores FOR SELECT TO authenticated USING (user_id = public.current_user_id() OR user_id = auth.uid());
CREATE POLICY "user_experience_read_own" ON public.user_experience FOR SELECT TO authenticated USING (user_id = public.current_user_id() OR user_id = auth.uid());

CREATE POLICY "daily_five_attempts_read_own" ON public.daily_five_attempts FOR SELECT TO authenticated USING (user_id = public.current_user_id() OR user_id = auth.uid());
CREATE POLICY "daily_five_streaks_read_own" ON public.daily_five_streaks FOR SELECT TO authenticated USING (user_id = public.current_user_id() OR user_id = auth.uid());

CREATE POLICY "code_submissions_read_own" ON public.code_submissions FOR SELECT TO authenticated USING (student_id = public.current_user_id() OR student_id = auth.uid());
CREATE POLICY "code_submissions_insert_own" ON public.code_submissions FOR INSERT TO authenticated WITH CHECK (student_id = public.current_user_id() OR student_id = auth.uid());

CREATE POLICY "leetcode_stats_read" ON public.leetcode_stats FOR SELECT TO authenticated USING (true);
CREATE POLICY "leetcode_snapshots_read" ON public.leetcode_stat_snapshots FOR SELECT TO authenticated USING (true);

CREATE POLICY "communication_prompts_read" ON public.communication_prompt_bank FOR SELECT TO authenticated USING (is_active);
CREATE POLICY "communication_attempts_read_own" ON public.communication_attempts FOR SELECT TO authenticated USING (student_id = public.current_user_id() OR student_id = auth.uid());

-- ── 5. Device Tokens & In-App Notifications ──────────────────
CREATE POLICY "device_tokens_manage_own" ON public.device_tokens FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_read_recipient" ON public.notifications FOR SELECT TO authenticated
USING (
  is_active = true AND (
    target_audience IN ('all', 'students') OR
    (target_audience = 'user' AND (target_user_id = auth.uid() OR target_user_id = public.current_user_id()))
  )
);

CREATE POLICY "notification_reads_manage_own" ON public.notification_reads FOR ALL TO authenticated
USING (user_id = auth.uid() OR user_id = public.current_user_id())
WITH CHECK (user_id = auth.uid() OR user_id = public.current_user_id());

-- ── 6. Mentorship & Lineage ──────────────────────────────────
CREATE POLICY "mentor_assignments_read_involved" ON public.mentor_assignments FOR SELECT TO authenticated
USING (senior_id = public.current_user_id() OR junior_id = public.current_user_id());

CREATE POLICY "lineage_requests_manage_involved" ON public.lineage_requests FOR ALL TO authenticated
USING (senior_id = public.current_user_id() OR junior_id = public.current_user_id())
WITH CHECK (junior_id = public.current_user_id());

CREATE POLICY "lineage_map_read_involved" ON public.lineage_map FOR SELECT TO authenticated
USING (student_id = public.current_user_id() OR senior_user_id = public.current_user_id() OR student_id = auth.uid() OR senior_user_id = auth.uid());

-- ── 7. Community Board & Moderation ──────────────────────────
CREATE POLICY "community_posts_read" ON public.community_posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "community_posts_insert" ON public.community_posts FOR INSERT TO authenticated WITH CHECK (author_id = public.current_user_id());
CREATE POLICY "community_comments_read" ON public.community_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "community_comments_insert" ON public.community_comments FOR INSERT TO authenticated WITH CHECK (author_id = public.current_user_id());

CREATE POLICY "moderation_reports_insert" ON public.moderation_reports FOR INSERT TO authenticated WITH CHECK (reporter_id = public.current_user_id());
CREATE POLICY "moderated_content_read" ON public.moderated_content FOR SELECT TO authenticated USING (true);

-- ── 8. Knowledge Brain, Assessment Engines & Collaboration ────
CREATE POLICY "kba_read_approved_or_own" ON public.knowledge_brain_articles FOR SELECT TO authenticated
USING (approval_status = 'approved' OR author_id = public.current_user_id() OR author_id = auth.uid());

CREATE POLICY "kba_insert_own" ON public.knowledge_brain_articles FOR INSERT TO authenticated
WITH CHECK (author_id = public.current_user_id() OR author_id = auth.uid());

CREATE POLICY "ke_read_approved" ON public.knowledge_embeddings FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.knowledge_brain_articles kba WHERE kba.id = knowledge_embeddings.article_id AND kba.approval_status = 'approved'));

CREATE POLICY "patterns_read_approved_or_own" ON public.interview_patterns FOR SELECT TO authenticated
USING (approval_status = 'approved' OR author_id = public.current_user_id() OR author_id = auth.uid());

CREATE POLICY "patterns_insert_own" ON public.interview_patterns FOR INSERT TO authenticated
WITH CHECK (author_id = public.current_user_id() OR author_id = auth.uid());

CREATE POLICY "mock_exams_read" ON public.mock_exams FOR SELECT TO authenticated USING (true);

CREATE POLICY "mock_exam_questions_read" ON public.mock_exam_questions FOR SELECT TO authenticated USING (true);

CREATE POLICY "mock_exam_results_read_own" ON public.mock_exam_results FOR SELECT TO authenticated
USING (student_id = public.current_user_id() OR student_id = auth.uid());

CREATE POLICY "ai_generated_tests_read" ON public.ai_generated_tests FOR SELECT TO authenticated
USING (public.is_faculty_or_hod(public.current_user_id()) OR public.is_placement_rep(public.current_user_id()));

CREATE POLICY "collab_posts_read" ON public.collaboration_posts FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "collab_posts_insert_own" ON public.collaboration_posts FOR INSERT TO authenticated WITH CHECK (posted_by = public.current_user_id() OR posted_by = auth.uid());

CREATE POLICY "sprint_attempts_read_own" ON public.sprint_attempts FOR SELECT TO authenticated
USING (user_id = public.current_user_id() OR user_id = auth.uid());
CREATE POLICY "sprint_attempts_write_own" ON public.sprint_attempts FOR ALL TO authenticated
USING (user_id = public.current_user_id() OR user_id = auth.uid())
WITH CHECK (user_id = public.current_user_id() OR user_id = auth.uid());

CREATE POLICY "weekly_journeys_read_own" ON public.weekly_journeys FOR SELECT TO authenticated
USING (user_id = public.current_user_id() OR user_id = auth.uid());

CREATE POLICY "experience_events_read_own" ON public.experience_events FOR SELECT TO authenticated
USING (user_id = public.current_user_id() OR user_id = auth.uid());

CREATE POLICY "fyp_projects_read" ON public.fyp_projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "fyp_projects_write_own" ON public.fyp_projects FOR ALL TO authenticated
USING (student_id = public.current_user_id() OR student_id = auth.uid())
WITH CHECK (student_id = public.current_user_id() OR student_id = auth.uid());

CREATE POLICY "fyp_progress_logs_read" ON public.fyp_progress_logs FOR SELECT TO authenticated USING (true);
CREATE POLICY "fyp_progress_logs_write_own" ON public.fyp_progress_logs FOR ALL TO authenticated
USING (student_id = public.current_user_id() OR student_id = auth.uid())
WITH CHECK (student_id = public.current_user_id() OR student_id = auth.uid());

CREATE POLICY "fyp_feedback_read" ON public.fyp_feedback FOR SELECT TO authenticated USING (true);

