-- ============================================================
-- PSGMX — 12_daily_content_tables.sql
--
-- Backs the "Project Tasks" and "Apti & DSA" tabs in
-- apps/mobile/lib/ui/tasks/tasks_screen.dart. Those tab labels already
-- existed in the app, but were just relabeled filters over the
-- admin-assigned daily_tasks table — not real daily-rotating content.
--
-- This migration adds two static, date-keyed content banks (one
-- substantial project/practical task per day-of-year, one DSA problem +
-- 3 aptitude questions per day-of-year) plus a simple per-user
-- mark-as-done tracking table. Content is selected deterministically by
-- day-of-year — every student sees the same day's content, cycling
-- yearly, so it doubles as shared daily curriculum (supports peer
-- discussion of "today's problem").
--
-- Run this once in the Supabase SQL editor, after 11_daily_five_fix.sql.
-- ============================================================

-- ── 1. project_task_bank ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS project_task_bank (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year     INT         NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    title           TEXT        NOT NULL,
    description     TEXT        NOT NULL,
    category        TEXT        NOT NULL
                    CHECK (category IN ('Web Dev', 'DBMS', 'OOP-Java', 'System Design', 'Git-DevOps', 'Testing', 'Cloud Basics')),
    difficulty      TEXT        NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    reference_link  TEXT,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);

CREATE INDEX IF NOT EXISTS idx_project_task_bank_doy ON project_task_bank(day_of_year);

-- ── 2. apti_dsa_daily_bank ────────────────────────────────────────────────
-- One row = one day's full Apti & DSA practice set: 1 DSA problem +
-- 3 short aptitude MCQs embedded as JSONB. Ungraded (practice/completion,
-- not scored) — no anti-cheat machinery needed, unlike Daily Five.
CREATE TABLE IF NOT EXISTS apti_dsa_daily_bank (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year         INT         NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    dsa_title           TEXT        NOT NULL,
    dsa_difficulty      TEXT        NOT NULL CHECK (dsa_difficulty IN ('easy', 'medium', 'hard')),
    dsa_topic           TEXT        NOT NULL,
    dsa_external_link   TEXT,
    dsa_hint            TEXT,
    -- Array of exactly 3 objects: [{"question":"...","options":["A","B","C","D"],"correct_option":0}, ...]
    aptitude_questions  JSONB       NOT NULL,
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);

CREATE INDEX IF NOT EXISTS idx_apti_dsa_daily_bank_doy ON apti_dsa_daily_bank(day_of_year);

-- ── 3. daily_content_completions ──────────────────────────────────────────
-- Simple mark-as-done tracking — no streak (not requested for these two,
-- unlike Daily Five's dedicated streak system).
CREATE TABLE IF NOT EXISTS daily_content_completions (
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type    TEXT        NOT NULL CHECK (content_type IN ('project_task', 'apti_dsa')),
    item_date       DATE        NOT NULL DEFAULT CURRENT_DATE,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    PRIMARY KEY (user_id, content_type, item_date)
);

-- ── 4. RLS ─────────────────────────────────────────────────────────────────
ALTER TABLE project_task_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE apti_dsa_daily_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content_completions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS project_task_bank_read ON project_task_bank;
CREATE POLICY project_task_bank_read ON project_task_bank
    FOR SELECT TO authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS project_task_bank_write ON project_task_bank;
CREATE POLICY project_task_bank_write ON project_task_bank
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'publish_tasks'))
    WITH CHECK (user_has_permission(auth.uid(), 'publish_tasks'));

DROP POLICY IF EXISTS apti_dsa_daily_bank_read ON apti_dsa_daily_bank;
CREATE POLICY apti_dsa_daily_bank_read ON apti_dsa_daily_bank
    FOR SELECT TO authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS apti_dsa_daily_bank_write ON apti_dsa_daily_bank;
CREATE POLICY apti_dsa_daily_bank_write ON apti_dsa_daily_bank
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'publish_tasks'))
    WITH CHECK (user_has_permission(auth.uid(), 'publish_tasks'));

DROP POLICY IF EXISTS daily_content_completions_own ON daily_content_completions;
CREATE POLICY daily_content_completions_own ON daily_content_completions
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ── 5. Success ─────────────────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration 12 complete: Daily Content (Project Tasks + Apti & DSA)';
    RAISE NOTICE '  - project_task_bank table created';
    RAISE NOTICE '  - apti_dsa_daily_bank table created';
    RAISE NOTICE '  - daily_content_completions table created';
    RAISE NOTICE 'NEXT: run 13_daily_content_seed.sql to populate 365+365 days of content';
    RAISE NOTICE '========================================';
END $$;
