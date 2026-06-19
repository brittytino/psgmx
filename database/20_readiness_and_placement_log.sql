-- ============================================================================
-- PSGMX v4 — Migration 20: Readiness Score + Placement Log + AI (tables)
-- ============================================================================
-- Creates:
--   • readiness_scores      — daily/weekly score snapshots
--   • companies             — placement drive header records
--   • placement_log_entries — second-year personal experience writeups
--
-- Run AFTER 19_daily_five.sql
-- ============================================================================

-- ── 1. readiness_scores ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS readiness_scores (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score           NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    computed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Breakdown of each component for audit/display
    components_json JSONB       NOT NULL DEFAULT '{}'
    -- expected shape:
    -- {
    --   "placement_attendance_pct": 80.5,
    --   "daily_five_adherence_pct": 90.0,
    --   "task_completion_rate_pct": 75.0,
    --   "daily_five_accuracy_pct": 60.0,
    --   "leetcode_momentum_percentile": 65.0
    -- }
);

CREATE INDEX IF NOT EXISTS idx_readiness_user_time
    ON readiness_scores(user_id, computed_at DESC);

-- ── 2. Readiness score formula function ──────────────────────────────────────
-- Called nightly (or on-demand) to compute and store a fresh snapshot.
CREATE OR REPLACE FUNCTION compute_readiness_score(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_placement_att     NUMERIC := 0;
    v_streak_adherence  NUMERIC := 0;
    v_task_completion   NUMERIC := 0;
    v_daily_accuracy    NUMERIC := 0;
    v_lc_percentile     NUMERIC := 0;
    v_score             NUMERIC;
    v_batch_id          UUID;
    v_30d_ago           DATE    := CURRENT_DATE - INTERVAL '30 days';
BEGIN
    SELECT batch_id INTO v_batch_id FROM users WHERE id = p_user_id;

    -- Component 1: Placement attendance %
    SELECT COALESCE(attendance_pct, 0)
    INTO v_placement_att
    FROM placement_attendance_summary
    WHERE user_id = p_user_id;

    -- Component 2: Daily Five streak adherence (days completed / eligible, trailing 30d)
    -- Simplified: use current_streak as proxy if last_completed within 30d
    SELECT COALESCE(
        CASE
            WHEN last_completed_date >= v_30d_ago
            THEN LEAST(current_streak, 30) * 100.0 / 30
            ELSE 0
        END, 0)
    INTO v_streak_adherence
    FROM daily_five_streaks
    WHERE user_id = p_user_id;

    -- Component 3: Task completion rate (trailing 30d)
    SELECT COALESCE(
        COUNT(*) FILTER (WHERE completed = TRUE) * 100.0 / NULLIF(COUNT(*), 0),
        0)
    INTO v_task_completion
    FROM task_completions
    WHERE user_id = p_user_id
      AND task_date >= v_30d_ago;

    -- Component 4: Daily Five accuracy (last stored rate)
    SELECT COALESCE(last_accuracy_rate * 100, 0)
    INTO v_daily_accuracy
    FROM daily_five_streaks
    WHERE user_id = p_user_id;

    -- Component 5: LeetCode momentum percentile (within own batch, trailing 30d)
    -- We approximate using the ranking field in leetcode_stats.
    -- A proper 30-day delta percentile requires a separate snapshot table;
    -- this is the V1 approximation.
    WITH batch_lc AS (
        SELECT ls.username,
               ls.total_solved,
               PERCENT_RANK() OVER (ORDER BY ls.total_solved) * 100 AS pct_rank
        FROM leetcode_stats ls
        JOIN users u ON u.leetcode_username = ls.username
        WHERE u.batch_id = v_batch_id
    )
    SELECT COALESCE(pct_rank, 0)
    INTO v_lc_percentile
    FROM batch_lc
    JOIN users u2 ON u2.leetcode_username = batch_lc.username
    WHERE u2.id = p_user_id;

    -- Weighted formula (weights sum to 1.00)
    v_score :=
        0.30 * v_placement_att
      + 0.20 * v_streak_adherence
      + 0.20 * v_task_completion
      + 0.15 * v_daily_accuracy
      + 0.15 * v_lc_percentile;

    v_score := ROUND(LEAST(GREATEST(v_score, 0), 100), 2);

    -- Store snapshot
    INSERT INTO readiness_scores (user_id, score, computed_at, components_json)
    VALUES (
        p_user_id,
        v_score,
        NOW(),
        jsonb_build_object(
            'placement_attendance_pct',    ROUND(v_placement_att,    2),
            'daily_five_adherence_pct',    ROUND(v_streak_adherence, 2),
            'task_completion_rate_pct',    ROUND(v_task_completion,  2),
            'daily_five_accuracy_pct',     ROUND(v_daily_accuracy,   2),
            'leetcode_momentum_percentile', ROUND(v_lc_percentile,   2)
        )
    );

    RETURN v_score;
END;
$$;

-- ── 3. companies ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS companies (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID        NOT NULL REFERENCES batches(id),
    name            TEXT        NOT NULL,
    visit_date      DATE        NOT NULL,
    roles_offered   TEXT[]      NOT NULL DEFAULT '{}',
    -- e.g. '5-8 LPA', '10+ LPA'
    package_band    TEXT,
    eligibility     TEXT,
    -- JSON array of round objects: [{name, type, description}]
    rounds          JSONB       NOT NULL DEFAULT '[]',
    created_by      UUID        NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_companies_batch_date
    ON companies(batch_id, visit_date ASC);

DROP TRIGGER IF EXISTS set_updated_at_companies ON companies;
CREATE TRIGGER set_updated_at_companies
    BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 4. placement_log_entries ─────────────────────────────────────────────────
-- Only second-year (active_senior batch) students can create entries.
-- Graduated batch entries remain permanently visible.
CREATE TABLE IF NOT EXISTS placement_log_entries (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID        NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users(id),
    round_name      TEXT        NOT NULL,
    experience_text TEXT        NOT NULL,
    is_moderated    BOOLEAN     NOT NULL DEFAULT FALSE,
    moderated_by    UUID        REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_log_entries_company
    ON placement_log_entries(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_log_entries_user
    ON placement_log_entries(user_id);

DROP TRIGGER IF EXISTS set_updated_at_log_entries ON placement_log_entries;
CREATE TRIGGER set_updated_at_log_entries
    BEFORE UPDATE ON placement_log_entries
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 5. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE readiness_scores      ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies             ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_log_entries ENABLE ROW LEVEL SECURITY;

-- readiness_scores: own score + admins
DROP POLICY IF EXISTS "readiness_read_own" ON readiness_scores;
CREATE POLICY "readiness_read_own" ON readiness_scores
    FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "readiness_read_admin" ON readiness_scores;
CREATE POLICY "readiness_read_admin" ON readiness_scores
    FOR SELECT TO authenticated
    USING (user_has_permission(auth.uid(), 'view_batch_analytics'));

DROP POLICY IF EXISTS "readiness_insert_system" ON readiness_scores;
CREATE POLICY "readiness_insert_system" ON readiness_scores
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- companies: all active + graduated batch members can read
DROP POLICY IF EXISTS "companies_read_all" ON companies;
CREATE POLICY "companies_read_all" ON companies
    FOR SELECT TO authenticated USING (TRUE);

-- manage_company_records permission to create/edit
DROP POLICY IF EXISTS "companies_write" ON companies;
CREATE POLICY "companies_write" ON companies
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'manage_company_records'))
    WITH CHECK (user_has_permission(auth.uid(), 'manage_company_records'));

-- placement_log_entries: all can read
DROP POLICY IF EXISTS "log_entries_read_all" ON placement_log_entries;
CREATE POLICY "log_entries_read_all" ON placement_log_entries
    FOR SELECT TO authenticated USING (TRUE);

-- Only active_senior batch members can write entries
DROP POLICY IF EXISTS "log_entries_insert_senior" ON placement_log_entries;
CREATE POLICY "log_entries_insert_senior" ON placement_log_entries
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users u
            JOIN batches b ON b.id = u.batch_id
            WHERE u.id = auth.uid()
              AND b.status = 'active_senior'
        )
    );

-- Users can update their own (non-moderated) entries
DROP POLICY IF EXISTS "log_entries_update_own" ON placement_log_entries;
CREATE POLICY "log_entries_update_own" ON placement_log_entries
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() AND is_moderated = FALSE)
    WITH CHECK (user_id = auth.uid());

-- moderate_placement_log permission to moderate entries
DROP POLICY IF EXISTS "log_entries_moderate" ON placement_log_entries;
CREATE POLICY "log_entries_moderate" ON placement_log_entries
    FOR UPDATE TO authenticated
    USING (user_has_permission(auth.uid(), 'moderate_placement_log'));

-- ── 6. Nightly readiness score computation for all active users ───────────────
SELECT cron.schedule(
    'compute-readiness-scores',
    '0 2 * * *',   -- 02:00 UTC daily
    $$
    DO $$
    DECLARE v_user RECORD;
    BEGIN
        FOR v_user IN
            SELECT u.id FROM users u
            JOIN batches b ON b.id = u.batch_id
            WHERE b.status IN ('active_senior', 'active_junior')
        LOOP
            PERFORM compute_readiness_score(v_user.id);
        END LOOP;
    END;
    $$
    $$
);

-- ── 7. Success ────────────────────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration 20 complete: Readiness + Placement Log';
    RAISE NOTICE '  - readiness_scores table + compute function';
    RAISE NOTICE '  - nightly score computation cron scheduled';
    RAISE NOTICE '  - companies table created';
    RAISE NOTICE '  - placement_log_entries table created';
    RAISE NOTICE '  - RLS policies applied to all tables';
    RAISE NOTICE 'All DB migrations complete!';
    RAISE NOTICE '========================================';
END $$;
