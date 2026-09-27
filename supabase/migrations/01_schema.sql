-- ============================================================
-- PSGMX — 01_schema.sql
-- Canonical Database Schema (Consolidated Core)
-- ============================================================
-- Consolidated single source of truth for all public tables,
-- column types, constraints, foreign keys, and indexes.
-- Designed for future contributors to initialize the full PSGMX
-- architecture cleanly without historical migration patches.
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── 1. Batches & Cohorts ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS batches (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code  TEXT NOT NULL UNIQUE,   -- e.g. '23MX', '24MX', '25MX', '26MX'
    start_year  INT NOT NULL,
    end_year    INT NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('pending_onboarding', 'active_junior', 'active_senior', 'graduated')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_code   ON batches(batch_code);

-- ── 2. Placement Squads / Teams ──────────────────────────────
CREATE TABLE IF NOT EXISTS teams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    team_code       TEXT NOT NULL,
    team_name       TEXT NOT NULL,
    team_leader_id  UUID,                     -- Resolved to users(id) via FK below
    target_size     INT NOT NULL DEFAULT 6 CHECK (target_size BETWEEN 3 AND 20),
    objective       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (batch_id, team_code)
);

CREATE INDEX IF NOT EXISTS idx_teams_batch_id ON teams(batch_id);
CREATE INDEX IF NOT EXISTS idx_teams_team_code ON teams(team_code);

-- ── 3. Whitelist Pre-Registration Gate ───────────────────────
CREATE TABLE IF NOT EXISTS whitelist (
    email               TEXT PRIMARY KEY,
    personal_email      TEXT,
    college_email       TEXT,
    name                TEXT,
    reg_no              TEXT UNIQUE,
    reg_no_is_placeholder BOOLEAN NOT NULL DEFAULT FALSE,
    batch               TEXT,                 -- Section code: 'G1', 'G2'
    batch_id            UUID REFERENCES batches(id),
    team_id             TEXT,                 -- Legacy free-text code ('T01'..'T21')
    team_uuid           UUID REFERENCES teams(id),
    gender              TEXT,
    dob                 DATE,
    leetcode_username   TEXT,
    roles               JSONB,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whitelist_email  ON whitelist(email);
CREATE INDEX IF NOT EXISTS idx_whitelist_reg_no ON whitelist(reg_no);
CREATE INDEX IF NOT EXISTS idx_whitelist_batch_id ON whitelist(batch_id);
CREATE INDEX IF NOT EXISTS idx_whitelist_team_uuid ON whitelist(team_uuid);
CREATE UNIQUE INDEX IF NOT EXISTS idx_whitelist_personal_email_unique ON whitelist (lower(personal_email)) WHERE personal_email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_whitelist_college_email_unique ON whitelist (lower(college_email)) WHERE college_email IS NOT NULL;

-- Dual-email logical identity mappings
CREATE TABLE IF NOT EXISTS whitelist_email_aliases (
    email           TEXT PRIMARY KEY,
    whitelist_email TEXT NOT NULL REFERENCES whitelist(email) ON DELETE CASCADE,
    email_type      TEXT NOT NULL CHECK (email_type IN ('personal', 'college')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whitelist_email_aliases_whitelist ON whitelist_email_aliases(whitelist_email);

-- ── 4. Users (1:1 with auth.users) ───────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email               TEXT NOT NULL UNIQUE,
    personal_email      TEXT,
    college_email       TEXT,
    reg_no              TEXT NOT NULL UNIQUE,
    reg_no_is_placeholder BOOLEAN NOT NULL DEFAULT FALSE,
    name                TEXT NOT NULL,
    team_id             TEXT,                 -- Legacy text code ('T01'..'T21')
    team_uuid           UUID REFERENCES teams(id),
    batch               TEXT NOT NULL CHECK (batch IN ('G1', 'G2')),
    batch_id            UUID REFERENCES batches(id),
    gender              TEXT,
    dob                 DATE,
    role_label          TEXT NOT NULL DEFAULT 'Student' CHECK (role_label IN ('Student', 'Faculty', 'Alumni', 'HOD')),
    roles               JSONB NOT NULL DEFAULT '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}',
    leetcode_username   TEXT,
    ecampus_password_set BOOLEAN NOT NULL DEFAULT FALSE,
    onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
    mentorship_open     BOOLEAN NOT NULL DEFAULT FALSE,
    show_birthday_publicly BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url          TEXT,
    linkedin_url        TEXT,
    github_url          TEXT,
    current_company     TEXT,
    current_role_title  TEXT,
    skills              TEXT[] NOT NULL DEFAULT '{}',
    interests           TEXT[] NOT NULL DEFAULT '{}',
    career_goal         TEXT,
    arrears             JSONB NOT NULL DEFAULT '[]',
    -- Calibration Profile Fields
    target_tier         TEXT CHECK (target_tier IN ('tier1', 'tier2', 'tier3')),
    preferred_role      TEXT,
    primary_language    TEXT,
    daily_commitment_minutes INT DEFAULT 30,
    interview_comfort   TEXT CHECK (interview_comfort IN ('beginner', 'intermediate', 'advanced')),
    -- Notification Preferences
    birthday_notifications_enabled  BOOLEAN DEFAULT TRUE,
    leetcode_notifications_enabled  BOOLEAN DEFAULT TRUE,
    task_reminders_enabled          BOOLEAN DEFAULT TRUE,
    attendance_alerts_enabled       BOOLEAN DEFAULT TRUE,
    announcements_enabled           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Circular FK for team leader on teams table
ALTER TABLE teams DROP CONSTRAINT IF EXISTS fk_teams_leader;
ALTER TABLE teams ADD CONSTRAINT fk_teams_leader FOREIGN KEY (team_leader_id) REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_email      ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_reg_no     ON users(reg_no);
CREATE INDEX IF NOT EXISTS idx_users_team_id    ON users(team_id);
CREATE INDEX IF NOT EXISTS idx_users_team_uuid  ON users(team_uuid);
CREATE INDEX IF NOT EXISTS idx_users_batch_id   ON users(batch_id);
CREATE INDEX IF NOT EXISTS idx_users_roles      ON users USING GIN(roles);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_personal_email_unique ON users (lower(personal_email)) WHERE personal_email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_college_email_unique ON users (lower(college_email)) WHERE college_email IS NOT NULL;

-- ── 5. Capability Permissions & System Audit ─────────────────
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_key  TEXT NOT NULL CHECK (permission_key IN (
        'manage_members',
        'configure_teams',
        'schedule_placement_sessions',
        'mark_placement_attendance',
        'publish_tasks',
        'manage_company_records',
        'moderate_placement_log',
        'view_batch_analytics'
    )),
    granted_by      UUID REFERENCES users(id),
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, permission_key)
);

CREATE INDEX IF NOT EXISTS idx_user_permissions_user ON user_permissions(user_id);

CREATE TABLE IF NOT EXISTS audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id    UUID REFERENCES users(id),
    action      TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id   UUID,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id   ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ── 6. Remote Application Config ─────────────────────────────
CREATE TABLE IF NOT EXISTS app_config (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    min_required_version  TEXT NOT NULL DEFAULT '1.0.0',
    latest_version        TEXT NOT NULL DEFAULT '1.0.0',
    force_update          BOOLEAN NOT NULL DEFAULT false,
    update_message        TEXT DEFAULT 'A new version of PSGMX is available.',
    github_release_url    TEXT DEFAULT 'https://github.com/psgmx/psgmx-flutter/releases/latest',
    android_download_url  TEXT,
    ios_download_url      TEXT,
    emergency_block       BOOLEAN NOT NULL DEFAULT false,
    emergency_message     TEXT DEFAULT 'App temporarily unavailable.',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by            TEXT
);

-- ── 7. Device Tokens & Session Lock ──────────────────────────
CREATE TABLE IF NOT EXISTS device_tokens (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform     TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, device_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

CREATE TABLE IF NOT EXISTS active_sessions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id      TEXT NOT NULL,
    platform       TEXT NOT NULL,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address     INET,
    user_agent     TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, device_id)
);

CREATE TABLE IF NOT EXISTS session_locks (
    user_id    UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    locked_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reason     TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 8. Daily Tasks & Defaulter Tracking ──────────────────────
CREATE TABLE IF NOT EXISTS daily_tasks (
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

CREATE INDEX IF NOT EXISTS idx_daily_tasks_date ON daily_tasks(date);

CREATE TABLE IF NOT EXISTS task_completions (
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

CREATE INDEX IF NOT EXISTS idx_completions_user_id ON task_completions(user_id);

CREATE TABLE IF NOT EXISTS defaulter_flags (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    defaulter_status      BOOLEAN NOT NULL DEFAULT FALSE,
    defaulter_reason      TEXT NOT NULL DEFAULT '',
    consecutive_absences  INT NOT NULL DEFAULT 0,
    attendance_percentage NUMERIC(5,2),
    detected_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at           TIMESTAMPTZ,
    resolved_by           UUID REFERENCES users(id),
    notes                 TEXT,
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS project_task_bank (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year     INT NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    category        TEXT NOT NULL CHECK (category IN ('Web Dev', 'DBMS', 'OOP-Java', 'System Design', 'Git-DevOps', 'Testing', 'Cloud Basics')),
    difficulty      TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    reference_link  TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);

CREATE TABLE IF NOT EXISTS apti_dsa_daily_bank (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year         INT NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    dsa_title           TEXT NOT NULL,
    dsa_difficulty      TEXT NOT NULL CHECK (dsa_difficulty IN ('easy', 'medium', 'hard')),
    dsa_topic           TEXT NOT NULL,
    dsa_external_link   TEXT,
    dsa_hint            TEXT,
    aptitude_questions  JSONB NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);

CREATE TABLE IF NOT EXISTS daily_content_completions (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_of_year     INT NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    content_type    TEXT NOT NULL CHECK (content_type IN ('project', 'apti_dsa')),
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, day_of_year, content_type)
);

-- ── 9. Academic Attendance & Courses ─────────────────────────
CREATE TABLE IF NOT EXISTS courses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        TEXT NOT NULL UNIQUE,
    title       TEXT NOT NULL,
    semester    INT NOT NULL,
    credits     INT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS faculty (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID UNIQUE REFERENCES users(id),
    name        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    cabin       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS classes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id   UUID NOT NULL REFERENCES courses(id),
    faculty_id  UUID NOT NULL REFERENCES faculty(id),
    batch_id    UUID NOT NULL REFERENCES batches(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS timetable_slots (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id    UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    room        TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS attendance_sessions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id    UUID NOT NULL REFERENCES classes(id),
    session_date DATE NOT NULL,
    period      INT NOT NULL,
    marked_by   UUID NOT NULL REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS attendance_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id  UUID NOT NULL REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    student_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      TEXT NOT NULL CHECK (status IN ('present', 'absent', 'on_duty')),
    remarks     TEXT,
    UNIQUE (session_id, student_id)
);

CREATE TABLE IF NOT EXISTS ca_marks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id   UUID NOT NULL REFERENCES courses(id),
    component   TEXT NOT NULL,
    marks_obtained NUMERIC(5,2) NOT NULL,
    max_marks   NUMERIC(5,2) NOT NULL,
    entered_by  UUID NOT NULL REFERENCES users(id),
    entered_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, course_id, component)
);

-- ── 10. Placement Drives & Company Records ────────────────────
CREATE TABLE IF NOT EXISTS company_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    tier        TEXT NOT NULL CHECK (tier IN ('tier1', 'tier2', 'tier3', 'dream', 'super_dream')),
    industry    TEXT,
    website     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS placements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID NOT NULL REFERENCES batches(id),
    company_name    TEXT NOT NULL,
    job_role        TEXT NOT NULL,
    package_lpa     NUMERIC(5,2) NOT NULL,
    tier            TEXT NOT NULL CHECK (tier IN ('tier1', 'tier2', 'tier3', 'dream', 'super_dream')),
    drive_date      DATE NOT NULL,
    venue           TEXT,
    eligibility_criteria JSONB NOT NULL DEFAULT '{}',
    status          TEXT NOT NULL CHECK (status IN ('upcoming', 'in_progress', 'completed', 'cancelled')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS placement_statistics (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id            UUID NOT NULL UNIQUE REFERENCES batches(id) ON DELETE CASCADE,
    total_eligible      INT NOT NULL DEFAULT 0,
    total_placed        INT NOT NULL DEFAULT 0,
    highest_package_lpa NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    average_package_lpa NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    median_package_lpa  NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    offers_count        INT NOT NULL DEFAULT 0,
    companies_visited   INT NOT NULL DEFAULT 0,
    last_updated        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tier_targets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier        TEXT NOT NULL UNIQUE CHECK (tier IN ('tier1', 'tier2', 'tier3')),
    min_score   INT NOT NULL,
    max_score   INT NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 11. Daily Five Quiz Engine & Streaks ─────────────────────
CREATE TABLE IF NOT EXISTS question_bank (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text   TEXT NOT NULL,
    options         JSONB NOT NULL,
    correct_option  INT NOT NULL CHECK (correct_option BETWEEN 0 AND 3),
    topic           TEXT NOT NULL,
    difficulty      TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_question_bank_topic_diff ON question_bank(topic, difficulty) WHERE is_active = TRUE;

CREATE TABLE IF NOT EXISTS daily_five_attempts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attempt_date    DATE NOT NULL,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at    TIMESTAMPTZ,
    question_ids    UUID[] NOT NULL,
    correct_count   INT,
    accuracy_rate   NUMERIC(4,3),
    flagged         BOOLEAN NOT NULL DEFAULT FALSE,
    flag_reason     TEXT,
    UNIQUE (user_id, attempt_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_five_attempts_user_date ON daily_five_attempts(user_id, attempt_date);

CREATE TABLE IF NOT EXISTS daily_five_streaks (
    user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_streak  INT NOT NULL DEFAULT 0,
    longest_streak  INT NOT NULL DEFAULT 0,
    last_completed  DATE,
    streak_freezes  INT NOT NULL DEFAULT 2,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 12. Readiness Engine & Ethical Gamification ──────────────
CREATE TABLE IF NOT EXISTS readiness_scores (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score           NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    computed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    components_json JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_readiness_user_time ON readiness_scores(user_id, computed_at DESC);

CREATE TABLE IF NOT EXISTS readiness_dimension_scores (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dimension           TEXT NOT NULL CHECK (dimension IN (
                            'aptitude_reasoning',
                            'coding_problem_solving',
                            'core_computer_science',
                            'communication_interview',
                            'assessment_performance',
                            'portfolio_project'
                        )),
    score               NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    confidence          TEXT NOT NULL CHECK (confidence IN ('low', 'medium', 'high')),
    evidence_count      INTEGER NOT NULL DEFAULT 0 CHECK (evidence_count >= 0),
    evidence_fresh_at   TIMESTAMPTZ,
    algorithm_version   TEXT NOT NULL DEFAULT 'v2',
    evidence            JSONB NOT NULL DEFAULT '[]'::jsonb,
    computed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, dimension, algorithm_version)
);

CREATE INDEX IF NOT EXISTS idx_readiness_dimension_user ON readiness_dimension_scores(user_id, dimension);

CREATE TABLE IF NOT EXISTS user_experience (
    user_id                     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    lifetime_xp                 INTEGER NOT NULL DEFAULT 0 CHECK (lifetime_xp >= 0),
    level                       INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    last_meaningful_action_at   TIMESTAMPTZ,
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 12b. LeetCode Stats & Snapshots ──────────────────────────
CREATE TABLE IF NOT EXISTS leetcode_stats (
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

CREATE INDEX IF NOT EXISTS idx_leetcode_stats_total  ON leetcode_stats(total_solved DESC);
CREATE INDEX IF NOT EXISTS idx_leetcode_stats_weekly ON leetcode_stats(weekly_score DESC);

CREATE TABLE IF NOT EXISTS leetcode_stat_snapshots (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      TEXT NOT NULL,
    snapshot_date DATE NOT NULL,
    total_solved  INT NOT NULL DEFAULT 0,
    easy_solved   INT NOT NULL DEFAULT 0,
    medium_solved INT NOT NULL DEFAULT 0,
    hard_solved   INT NOT NULL DEFAULT 0,
    ranking       INT,
    captured_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (username, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_leetcode_snapshots_user_date ON leetcode_stat_snapshots(username, snapshot_date DESC);

-- ── 13. CodeBox & Verified Quests ────────────────────────────
CREATE TABLE IF NOT EXISTS code_problems (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    slug            TEXT NOT NULL UNIQUE,
    difficulty      TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    category        TEXT NOT NULL,
    description_md  TEXT NOT NULL,
    starter_code    JSONB NOT NULL DEFAULT '{}',
    test_cases      JSONB NOT NULL DEFAULT '[]',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    dimension       TEXT NOT NULL,
    xp_reward       INT NOT NULL DEFAULT 100,
    expires_at      TIMESTAMPTZ,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS code_submissions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    problem_id          UUID REFERENCES code_problems(id),
    quest_id            UUID REFERENCES quests(id),
    student_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code                TEXT NOT NULL,
    language            TEXT NOT NULL,
    status              TEXT NOT NULL CHECK (status IN ('accepted', 'wrong_answer', 'runtime_error', 'time_limit')),
    is_verified_complete BOOLEAN NOT NULL DEFAULT FALSE,
    submitted_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_code_submissions_student ON code_submissions(student_id);

CREATE TABLE IF NOT EXISTS leetcode_stats (
    username        TEXT PRIMARY KEY,
    total_solved    INT NOT NULL DEFAULT 0,
    easy_solved     INT NOT NULL DEFAULT 0,
    medium_solved   INT NOT NULL DEFAULT 0,
    hard_solved     INT NOT NULL DEFAULT 0,
    acceptance_rate NUMERIC(5,2),
    ranking         INT,
    last_updated    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 14. Mentorship, Lineage & Mock Exams ─────────────────────
CREATE TABLE IF NOT EXISTS mentor_assignments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    senior_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    junior_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (senior_id, junior_id)
);

CREATE TABLE IF NOT EXISTS lineage_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    junior_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status          TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (junior_id, senior_id)
);

CREATE TABLE IF NOT EXISTS mock_test_templates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    tier        TEXT NOT NULL CHECK (tier IN ('tier1', 'tier2', 'tier3')),
    duration_minutes INT NOT NULL DEFAULT 60,
    question_ids UUID[] NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mock_test_attempts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES mock_test_templates(id),
    student_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score       NUMERIC(5,2),
    started_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    answers_json JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.communication_prompt_bank (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_text      TEXT NOT NULL UNIQUE,
    category         TEXT NOT NULL CHECK (category IN (
        'introduction', 'behavioural', 'technical_explanation', 'project_defence',
        'group_discussion', 'workplace', 'storytelling'
    )),
    difficulty       TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    evaluation_focus TEXT[] NOT NULL DEFAULT '{}',
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS communication_attempts (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prompt_text        TEXT,
    audio_storage_path TEXT,
    duration_seconds   SMALLINT,
    transcript         TEXT,
    ai_scores_json     JSONB,
    ai_model_used      TEXT,
    faculty_reviewed   BOOLEAN NOT NULL DEFAULT FALSE,
    faculty_reviewer_id UUID REFERENCES users(id),
    faculty_score      NUMERIC(4,2),
    faculty_notes      TEXT,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comm_student ON communication_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_comm_active ON communication_attempts(student_id, is_active) WHERE is_active = TRUE;

-- ── 15. FYP Topics, Senior Articles & Community Board ─────────
CREATE TABLE IF NOT EXISTS fyp_topics (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    domain      TEXT NOT NULL,
    description TEXT NOT NULL,
    faculty_id  UUID REFERENCES faculty(id),
    is_taken    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS senior_articles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    slug        TEXT NOT NULL UNIQUE,
    author_id   UUID REFERENCES users(id),
    company     TEXT,
    content_md  TEXT NOT NULL,
    tags        TEXT[] NOT NULL DEFAULT '{}',
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS community_posts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    content     TEXT NOT NULL,
    tags        TEXT[] NOT NULL DEFAULT '{}',
    upvotes     INT NOT NULL DEFAULT 0,
    is_pinned   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS community_comments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    author_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS moderation_reports (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('post', 'comment', 'article')),
    entity_id   UUID NOT NULL,
    reason      TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS moderated_content (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL,
    entity_id   UUID NOT NULL UNIQUE,
    moderator_id UUID NOT NULL REFERENCES users(id),
    action      TEXT NOT NULL CHECK (action IN ('hidden', 'flagged', 'restored')),
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 16. In-App Notifications & Delivery ──────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             TEXT NOT NULL,
    message           TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    tone              TEXT,
    target_audience   TEXT NOT NULL,
    target_user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    action_path       TEXT,
    category          TEXT,
    generated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until       TIMESTAMPTZ,
    created_by        UUID REFERENCES users(id),
    is_active         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_notifications_target_user ON notifications(target_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_active ON notifications(is_active, generated_at DESC);

CREATE TABLE IF NOT EXISTS notification_reads (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (notification_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_notification_reads_lookup ON notification_reads(user_id, notification_id);

-- ── 17. Knowledge Brain, Assessment Engines & Collaboration ──
CREATE TABLE IF NOT EXISTS knowledge_brain_articles (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title            TEXT NOT NULL,
    summary          TEXT,
    content          TEXT NOT NULL,
    tags             TEXT[] NOT NULL DEFAULT '{}',
    company_name     TEXT,
    source           TEXT,
    batch_year       TEXT,
    view_count       INTEGER NOT NULL DEFAULT 0,
    approval_status  TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    search_vector    tsvector,
    reviewed_by      UUID REFERENCES users(id),
    reviewed_at      TIMESTAMPTZ,
    review_due_at    TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kba_search ON knowledge_brain_articles USING gin(search_vector);
CREATE INDEX IF NOT EXISTS idx_kba_approval ON knowledge_brain_articles(approval_status, created_at DESC);

CREATE TABLE IF NOT EXISTS knowledge_embeddings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id  UUID NOT NULL REFERENCES knowledge_brain_articles(id) ON DELETE CASCADE,
    chunk_text  TEXT NOT NULL,
    chunk_index INTEGER NOT NULL DEFAULT 0,
    embedding   vector(384),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ke_article ON knowledge_embeddings(article_id);

CREATE TABLE IF NOT EXISTS interview_patterns (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title              TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 5 AND 160),
    pattern_type       TEXT NOT NULL CHECK (pattern_type IN (
        'aptitude_screening', 'coding_round', 'technical_deep_dive',
        'fyp_discussion', 'behavioural', 'group_discussion', 'general'
    )),
    historical_context TEXT,
    preparation_helped TEXT NOT NULL CHECK (char_length(trim(preparation_helped)) >= 20),
    mistakes           TEXT,
    example_themes     TEXT[] NOT NULL DEFAULT '{}',
    advice             TEXT NOT NULL CHECK (char_length(trim(advice)) >= 20),
    company_name       TEXT,
    batch_year         TEXT,
    approval_status    TEXT NOT NULL DEFAULT 'pending'
                       CHECK (approval_status IN ('draft', 'pending', 'changes_requested', 'approved', 'rejected', 'retired')),
    reviewed_by        UUID REFERENCES users(id),
    reviewed_at        TIMESTAMPTZ,
    review_notes       TEXT,
    review_due_at      TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interview_patterns_status ON interview_patterns(approval_status, created_at DESC);

CREATE TABLE IF NOT EXISTS lineage_map (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    senior_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    senior_quote   TEXT,
    assigned_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by    UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS mock_exams (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title            TEXT NOT NULL,
    description      TEXT,
    domain           TEXT CHECK (domain IN ('aptitude', 'core_cs', 'coding', 'dbms', 'networks', 'os', 'general')),
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    total_marks      INTEGER NOT NULL DEFAULT 0,
    exam_date        TIMESTAMPTZ,
    batch_id         UUID REFERENCES batches(id),
    ai_generated     BOOLEAN NOT NULL DEFAULT FALSE,
    created_by       UUID REFERENCES users(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mock_exam_questions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id         UUID NOT NULL REFERENCES mock_exams(id) ON DELETE CASCADE,
    question_text   TEXT NOT NULL,
    option_a        TEXT,
    option_b        TEXT,
    option_c        TEXT,
    option_d        TEXT,
    correct_option  TEXT NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
    marks           INTEGER NOT NULL DEFAULT 1,
    order_index     INTEGER NOT NULL DEFAULT 0,
    explanation     TEXT,
    difficulty      TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mock_exam_questions_exam ON mock_exam_questions(exam_id, order_index);

CREATE TABLE IF NOT EXISTS mock_exam_results (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id           UUID NOT NULL REFERENCES mock_exams(id) ON DELETE CASCADE,
    student_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token     UUID NOT NULL DEFAULT gen_random_uuid(),
    started_at        TIMESTAMPTZ,
    submitted_at      TIMESTAMPTZ,
    score             NUMERIC,
    raw_marks         NUMERIC,
    out_of            NUMERIC,
    total_questions   INTEGER,
    proctoring_flags  JSONB NOT NULL DEFAULT '[]',
    status            TEXT NOT NULL DEFAULT 'in_progress'
                      CHECK (status IN ('in_progress', 'submitted', 'auto_submitted', 'voided')),
    voided_by         UUID REFERENCES users(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (exam_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_mock_exam_results_student ON mock_exam_results(student_id, exam_id);

CREATE TABLE IF NOT EXISTS ai_generated_tests (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id        UUID REFERENCES mock_exams(id) ON DELETE SET NULL,
    batch_id       UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    week_number    SMALLINT NOT NULL,
    year           SMALLINT NOT NULL,
    domain         TEXT NOT NULL CHECK (domain IN ('aptitude', 'core_cs', 'coding', 'dbms', 'networks', 'os', 'general')),
    question_count SMALLINT NOT NULL DEFAULT 10,
    status         TEXT NOT NULL DEFAULT 'generated' CHECK (status IN ('generated', 'published', 'faculty_reviewed', 'cancelled')),
    model_used     TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at   TIMESTAMPTZ,
    UNIQUE (week_number, year, domain, batch_id)
);

CREATE TABLE IF NOT EXISTS collaboration_posts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_type   TEXT NOT NULL CHECK (post_type IN ('job', 'project', 'mentorship')),
    title       TEXT NOT NULL,
    description TEXT NOT NULL,
    visibility  TEXT NOT NULL DEFAULT 'batch' CHECK (visibility IN ('lineage_only', 'batch', 'department')),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    posted_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collab_posts_active ON collaboration_posts(is_active, created_at DESC);

CREATE TABLE IF NOT EXISTS sprint_attempts (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attempt_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    domain         TEXT NOT NULL,
    question_ids   UUID[] NOT NULL,
    answers        JSONB NOT NULL DEFAULT '{}',
    score          NUMERIC NOT NULL DEFAULT 0,
    total_questions INT NOT NULL DEFAULT 5,
    started_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at   TIMESTAMPTZ,
    UNIQUE (user_id, attempt_date, domain)
);

CREATE TABLE IF NOT EXISTS weekly_journeys (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start  DATE NOT NULL,
    highlights  JSONB NOT NULL DEFAULT '[]',
    strengths   JSONB NOT NULL DEFAULT '[]',
    focus_areas JSONB NOT NULL DEFAULT '[]',
    score_delta NUMERIC DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, week_start)
);

CREATE TABLE IF NOT EXISTS experience_events (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    xp_earned  INT NOT NULL DEFAULT 0,
    metadata   JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fyp_projects (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id           UUID REFERENCES batches(id),
    student_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title              TEXT NOT NULL,
    description        TEXT,
    guide_name         TEXT,
    team_members_count INTEGER NOT NULL DEFAULT 1,
    status             TEXT NOT NULL DEFAULT 'proposal'
                       CHECK (status IN ('proposal', 'in_progress', 'completed', 'archived')),
    repository_url     TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fyp_progress_logs (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    note       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fyp_feedback (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
    faculty_id UUID NOT NULL REFERENCES users(id),
    comment    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

