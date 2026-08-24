-- ============================================================
-- PSGMX — 02_schema_academic.sql
-- ============================================================
-- Daily tasks, task completions, defaulter flags, the two daily content
-- banks (Project Tasks / Apti & DSA), the Daily Five quiz engine, readiness
-- scores, and LeetCode stats.
--
-- Run AFTER 01_schema_core.sql.
-- ============================================================

-- ── daily_tasks — admin-assigned LeetCode/core-subject tasks ────────────────
CREATE TABLE daily_tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date            DATE NOT NULL,
    topic_type      TEXT NOT NULL CHECK (topic_type IN ('leetcode', 'core')),
    title           TEXT NOT NULL,
    reference_link  TEXT,
    subject         TEXT,
    uploaded_by     UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(date, topic_type)
);

CREATE INDEX idx_daily_tasks_date       ON daily_tasks(date);
CREATE INDEX idx_daily_tasks_topic_type ON daily_tasks(topic_type);

-- ── task_completions — student submissions + team-leader verification ───────
CREATE TABLE task_completions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_date       DATE NOT NULL,
    completed       BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at    TIMESTAMPTZ,
    verified_by     UUID REFERENCES users(id),
    verified_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, task_date)
);

CREATE INDEX idx_completions_user_id   ON task_completions(user_id);
CREATE INDEX idx_completions_task_date ON task_completions(task_date);

-- ── defaulter_flags ───────────────────────────────────────────────────────
CREATE TABLE defaulter_flags (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    defaulter_status        BOOLEAN NOT NULL DEFAULT FALSE,
    defaulter_reason        TEXT NOT NULL DEFAULT '',
    consecutive_absences    INT NOT NULL DEFAULT 0,
    attendance_percentage   NUMERIC(5,2),
    detected_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at             TIMESTAMPTZ,
    resolved_by             UUID REFERENCES users(id),
    notes                   TEXT,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_defaulter_status     ON defaulter_flags(defaulter_status);
CREATE INDEX idx_defaulter_detected_at ON defaulter_flags(detected_at DESC);

-- ── project_task_bank — 365 date-keyed project/practical tasks ──────────────
CREATE TABLE project_task_bank (
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

CREATE INDEX idx_project_task_bank_doy ON project_task_bank(day_of_year);

-- ── apti_dsa_daily_bank — 365 date-keyed DSA + aptitude practice sets ───────
CREATE TABLE apti_dsa_daily_bank (
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

CREATE INDEX idx_apti_dsa_daily_bank_doy ON apti_dsa_daily_bank(day_of_year);

-- ── daily_content_completions — mark-as-done for the two banks above ───────
CREATE TABLE daily_content_completions (
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type    TEXT        NOT NULL CHECK (content_type IN ('project_task', 'apti_dsa')),
    item_date       DATE        NOT NULL DEFAULT CURRENT_DATE,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    PRIMARY KEY (user_id, content_type, item_date)
);

-- ── question_bank — Daily Five quiz question pool ───────────────────────────
CREATE TABLE question_bank (
    id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text   TEXT    NOT NULL,
    options         JSONB   NOT NULL,        -- e.g. ["A", "B", "C", "D"]
    correct_option  INT     NOT NULL CHECK (correct_option BETWEEN 0 AND 3),  -- 0-based index into options
    topic           TEXT    NOT NULL,
    difficulty      TEXT    NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    created_by      UUID    REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_question_bank_topic      ON question_bank(topic);
CREATE INDEX idx_question_bank_difficulty ON question_bank(difficulty);
CREATE INDEX idx_question_bank_active     ON question_bank(is_active);

-- ── daily_five_streaks — one row per user, current streak state ─────────────
CREATE TABLE daily_five_streaks (
    user_id             UUID    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_streak      INT     NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak      INT     NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    freezes_remaining   INT     NOT NULL DEFAULT 2 CHECK (freezes_remaining BETWEEN 0 AND 2),
    freezes_reset_month TEXT    NOT NULL DEFAULT TO_CHAR(NOW(), 'YYYY-MM'),  -- 'YYYY-MM', tracks monthly freeze reset
    last_completed_date DATE,
    last_accuracy_rate  NUMERIC(4,3) CHECK (last_accuracy_rate BETWEEN 0 AND 1),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── daily_five_attempts — server-side record of what was served + graded ────
CREATE TABLE daily_five_attempts (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attempt_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    question_ids   UUID[] NOT NULL,
    started_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at   TIMESTAMPTZ,
    correct_count  INTEGER,
    accuracy_rate  NUMERIC,
    flagged        BOOLEAN NOT NULL DEFAULT false,
    flag_reason    TEXT,
    UNIQUE (user_id, attempt_date)
);

-- ── readiness_scores — append-only score snapshot log ───────────────────────
CREATE TABLE readiness_scores (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score           NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    computed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    components_json JSONB       NOT NULL DEFAULT '{}'
    -- expected shape: {"placement_attendance_pct":.., "daily_five_adherence_pct":..,
    --   "task_completion_rate_pct":.., "daily_five_accuracy_pct":.., "leetcode_momentum_percentile":..}
);

CREATE INDEX idx_readiness_user_time ON readiness_scores(user_id, computed_at DESC);

-- Convenience view: exactly the latest row per user (dashboards/leaderboard
-- need "current score", not the full history). security_invoker is required
-- so this respects the underlying table's RLS instead of running as owner.
CREATE VIEW current_readiness_scores
WITH (security_invoker = true) AS
SELECT DISTINCT ON (user_id) user_id, score, components_json, computed_at
FROM readiness_scores
ORDER BY user_id, computed_at DESC;

-- ── leetcode_stats — synced LeetCode counts for the leaderboard ────────────
CREATE TABLE leetcode_stats (
    username                  TEXT PRIMARY KEY,
    total_solved              INT DEFAULT 0,
    easy_solved                INT DEFAULT 0,
    medium_solved              INT DEFAULT 0,
    hard_solved                 INT DEFAULT 0,
    ranking                    INT DEFAULT 0,
    weekly_score                INT DEFAULT 0,
    profile_picture             TEXT,
    username_last_changed_at    TIMESTAMPTZ,
    flagged                     BOOLEAN NOT NULL DEFAULT false,
    flag_reason                 TEXT,
    last_updated                 TIMESTAMPTZ DEFAULT NOW(),
    created_at                  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leetcode_stats_total  ON leetcode_stats(total_solved DESC);
CREATE INDEX idx_leetcode_stats_weekly ON leetcode_stats(weekly_score DESC);

DO $$
BEGIN
    RAISE NOTICE '✅ 02_schema_academic.sql complete.';
    RAISE NOTICE 'NEXT: run 03_schema_placement.sql';
END $$;
