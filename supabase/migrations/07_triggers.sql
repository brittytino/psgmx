-- ============================================================
-- PSGMX — 07_triggers.sql
-- ============================================================
-- Wires the trigger functions defined in 06_functions.sql to their tables.
--
-- Run AFTER 06_functions.sql.
-- ============================================================

-- ── Auth: create the users row on first login ────────────────────────────
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── Notifications ─────────────────────────────────────────────────────────
CREATE TRIGGER on_daily_task_created
    AFTER INSERT ON daily_tasks
    FOR EACH ROW EXECUTE FUNCTION notify_new_daily_task();

CREATE TRIGGER on_attendance_scheduled
    AFTER INSERT ON scheduled_attendance_dates
    FOR EACH ROW EXECUTE FUNCTION notify_attendance_schedule();

CREATE TRIGGER on_leetcode_stat_update
    AFTER UPDATE OF total_solved ON leetcode_stats
    FOR EACH ROW
    WHEN (NEW.total_solved > OLD.total_solved)
    EXECUTE FUNCTION notify_leetcode_milestone();

-- ── LeetCode anomaly flagging ─────────────────────────────────────────────
CREATE TRIGGER trig_leetcode_anomaly_flag
    BEFORE UPDATE ON leetcode_stats
    FOR EACH ROW EXECUTE FUNCTION _flag_leetcode_anomaly();

-- ── Knowledge Brain search vector ─────────────────────────────────────────
CREATE TRIGGER trig_knowledge_search_vector
    BEFORE INSERT OR UPDATE OF title, summary, content, tags, company_name
    ON knowledge_brain_articles
    FOR EACH ROW EXECUTE FUNCTION update_knowledge_search_vector();

-- ── app_config timestamp ──────────────────────────────────────────────────
CREATE TRIGGER app_config_updated_at
    BEFORE UPDATE ON app_config
    FOR EACH ROW EXECUTE FUNCTION update_app_config_timestamp();

-- ── Generic updated_at maintenance ────────────────────────────────────────
CREATE TRIGGER set_updated_at_users
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_batches
    BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_teams
    BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_daily_tasks
    BEFORE UPDATE ON daily_tasks
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_task_completions
    BEFORE UPDATE ON task_completions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_question_bank
    BEFORE UPDATE ON question_bank
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_companies
    BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_log_entries
    BEFORE UPDATE ON placement_log_entries
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_placement_sessions
    BEFORE UPDATE ON placement_sessions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_fyp_projects
    BEFORE UPDATE ON fyp_projects
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_knowledge_brain_articles
    BEFORE UPDATE ON knowledge_brain_articles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_updated_at_defaulter_flags
    BEFORE UPDATE ON defaulter_flags
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Recurring jobs are invoked by authenticated GitHub Actions workflows.
-- Do not add pg_cron schedules here: the production target is Supabase Free.

DO $$
BEGIN
    RAISE NOTICE '✅ 07_triggers.sql complete — triggers wired; scheduling is external.';
    RAISE NOTICE 'NEXT: run 08_rls_policies.sql';
END $$;
