-- ============================================================
-- PSGMX SQL — FILE 01: Create Daily Content Tables
-- Run this FIRST in Supabase SQL Editor
-- ============================================================

-- 1. project_task_bank
CREATE TABLE IF NOT EXISTS project_task_bank (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year     INT         NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    title           TEXT        NOT NULL,
    description     TEXT        NOT NULL,
    category        TEXT        NOT NULL,
    difficulty      TEXT        NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    reference_link  TEXT,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);
CREATE INDEX IF NOT EXISTS idx_project_task_bank_doy ON project_task_bank(day_of_year);

-- 2. apti_dsa_daily_bank
CREATE TABLE IF NOT EXISTS apti_dsa_daily_bank (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year         INT         NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    dsa_title           TEXT        NOT NULL,
    dsa_difficulty      TEXT        NOT NULL CHECK (dsa_difficulty IN ('easy', 'medium', 'hard')),
    dsa_topic           TEXT        NOT NULL,
    dsa_external_link   TEXT,
    dsa_hint            TEXT,
    aptitude_questions  JSONB       NOT NULL,
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);
CREATE INDEX IF NOT EXISTS idx_apti_dsa_daily_bank_doy ON apti_dsa_daily_bank(day_of_year);

-- 3. daily_content_completions
CREATE TABLE IF NOT EXISTS daily_content_completions (
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type    TEXT        NOT NULL CHECK (content_type IN ('project_task', 'apti_dsa')),
    item_date       DATE        NOT NULL DEFAULT CURRENT_DATE,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    PRIMARY KEY (user_id, content_type, item_date)
);

-- 4. RLS Policies
ALTER TABLE project_task_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE apti_dsa_daily_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content_completions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS project_task_bank_read ON project_task_bank;
CREATE POLICY project_task_bank_read ON project_task_bank
    FOR SELECT TO authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS apti_dsa_daily_bank_read ON apti_dsa_daily_bank;
CREATE POLICY apti_dsa_daily_bank_read ON apti_dsa_daily_bank
    FOR SELECT TO authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS daily_content_completions_own ON daily_content_completions;
CREATE POLICY daily_content_completions_own ON daily_content_completions
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

SELECT 'FILE 01 COMPLETE: Daily content tables created.' AS status;
