-- ============================================================
-- PSGMX — 00_initial_schema.sql  (v2 — full rebuild)
-- Complete database schema for the PSGMX educational ecosystem.
-- Includes ALL columns used by both Flutter and Next.js apps.
-- Run order matters: parent tables before child tables.
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_net";   -- HTTP calls from triggers → Edge Functions

-- ============================================================
-- SECTION 1: CORE IDENTITY TABLES
-- ============================================================

-- Batch records. One row per MCA intake year.
CREATE TABLE IF NOT EXISTS batches (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_code  TEXT NOT NULL UNIQUE,      -- e.g. '25MX', '26MX'
  start_date  DATE NOT NULL,             -- e.g. 2025-06-01
  end_date    DATE NOT NULL,             -- e.g. 2027-06-30
  status      TEXT NOT NULL DEFAULT 'active_junior'
              CHECK (status IN ('active_junior', 'active_senior', 'graduated')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- All users: students, alumni, faculty, HOD.
-- Students and alumni are identified by roll_no.
-- Faculty and HOD have NULL roll_no.
CREATE TABLE IF NOT EXISTS users (
  id                              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                           TEXT NOT NULL UNIQUE,
  full_name                       TEXT NOT NULL,
  roll_no                         TEXT UNIQUE,             -- NULL for faculty/HOD
  batch_id                        UUID REFERENCES batches(id),  -- NULL for faculty/HOD
  role                            TEXT NOT NULL DEFAULT 'student'
                                  CHECK (role IN ('student', 'alumni', 'faculty', 'hod')),
  app_role                        TEXT NOT NULL DEFAULT 'student'
                                  CHECK (app_role IN ('student', 'team_leader', 'coordinator', 'placement_rep')),
  team_id                         UUID,                    -- FK added after teams table is created
  avatar_url                      TEXT,
  linkedin_url                    TEXT,
  current_company                 TEXT,                    -- filled in after graduation
  current_role_title              TEXT,                    -- filled in after graduation
  mentorship_open                 BOOLEAN NOT NULL DEFAULT false,  -- alumni toggle
  onboarding_complete             BOOLEAN NOT NULL DEFAULT false,

  -- ── Extended profile fields (used by Flutter app) ──────────────────────────
  gender                          TEXT CHECK (gender IN ('male', 'female', 'other', NULL)),
  dob                             DATE,                    -- date of birth for birthday notifications
  role_label                      TEXT NOT NULL DEFAULT 'Student',  -- UI-facing cosmetic label
  leetcode_username               TEXT,                    -- stored here for quick profile access
  ecampus_password                TEXT,                    -- encrypted eCampus portal password
  ecampus_password_set            BOOLEAN NOT NULL DEFAULT false,

  -- ── Notification preferences (Flutter per-user toggles) ────────────────────
  birthday_notifications_enabled  BOOLEAN NOT NULL DEFAULT true,
  leetcode_notifications_enabled  BOOLEAN NOT NULL DEFAULT true,
  task_reminders_enabled          BOOLEAN NOT NULL DEFAULT true,
  attendance_alerts_enabled       BOOLEAN NOT NULL DEFAULT true,
  announcements_enabled           BOOLEAN NOT NULL DEFAULT true,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Teams within a batch. Created and managed by the Placement Rep.
CREATE TABLE IF NOT EXISTS teams (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id     UUID NOT NULL REFERENCES batches(id),
  team_name    TEXT NOT NULL,              -- e.g. 'Team Alpha', 'Team 1'
  target_size  INTEGER NOT NULL DEFAULT 10,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add FK back to users for team_id (circular reference resolved via ALTER TABLE)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'users_team_id_fkey' AND table_name = 'users'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT users_team_id_fkey
      FOREIGN KEY (team_id) REFERENCES teams(id);
  END IF;
END;
$$;

-- Granular permission flags per user.
CREATE TABLE IF NOT EXISTS user_permissions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission   TEXT NOT NULL,
  -- Valid permissions:
  -- 'manage_members', 'configure_teams', 'schedule_sessions',
  -- 'publish_tasks', 'manage_company_records', 'moderate_placement_log',
  -- 'view_batch_analytics', 'mark_attendance_batch'
  granted_by   UUID REFERENCES users(id),
  granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, permission)
);

-- Lineage map: auto-populated on user creation from roll_no suffix.
-- Links 25MX223 → 24MX223 → 23MX223 etc.
CREATE TABLE IF NOT EXISTS lineage_map (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  junior_user_id   UUID NOT NULL REFERENCES users(id),
  senior_user_id   UUID NOT NULL REFERENCES users(id),
  roll_suffix      TEXT NOT NULL,            -- the shared numeric suffix e.g. 'MX223'
  UNIQUE(junior_user_id, senior_user_id)
);

-- ============================================================
-- SECTION 2: PLACEMENT SESSION ATTENDANCE (Mobile App)
-- ============================================================

CREATE TABLE IF NOT EXISTS placement_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id        UUID NOT NULL REFERENCES batches(id),
  scheduled_by    UUID NOT NULL REFERENCES users(id),
  session_date    DATE NOT NULL,
  session_time    TIME NOT NULL,
  topic           TEXT NOT NULL,
  target_scope    TEXT NOT NULL DEFAULT 'batch'
                  CHECK (target_scope IN ('batch', 'teams')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS placement_session_teams (
  session_id  UUID NOT NULL REFERENCES placement_sessions(id) ON DELETE CASCADE,
  team_id     UUID NOT NULL REFERENCES teams(id),
  PRIMARY KEY (session_id, team_id)
);

CREATE TABLE IF NOT EXISTS placement_attendance (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  UUID NOT NULL REFERENCES placement_sessions(id),
  student_id  UUID NOT NULL REFERENCES users(id),
  status      TEXT NOT NULL DEFAULT 'absent'
              CHECK (status IN ('present', 'absent', 'excused')),
  marked_by   UUID NOT NULL REFERENCES users(id),
  note        TEXT,
  marked_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(session_id, student_id)
);

-- ============================================================
-- SECTION 3: DAILY FIVE QUIZ (Mobile App)
-- ============================================================

CREATE TABLE IF NOT EXISTS question_bank (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_text  TEXT NOT NULL,
  option_a       TEXT NOT NULL,
  option_b       TEXT NOT NULL,
  option_c       TEXT NOT NULL,
  option_d       TEXT NOT NULL,
  correct_option TEXT NOT NULL CHECK (correct_option IN ('a','b','c','d')),
  topic          TEXT NOT NULL,
  -- Topics: 'aptitude', 'verbal', 'dsa', 'dbms', 'os', 'networks',
  --         'oop', 'python', 'java', 'hr_behavioral'
  difficulty     TEXT NOT NULL DEFAULT 'medium'
                 CHECK (difficulty IN ('easy', 'medium', 'hard')),
  is_active      BOOLEAN NOT NULL DEFAULT true,
  created_by     UUID REFERENCES users(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS daily_five_streaks (
  user_id                    UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak             INTEGER NOT NULL DEFAULT 0,
  longest_streak             INTEGER NOT NULL DEFAULT 0,
  freezes_remaining          INTEGER NOT NULL DEFAULT 2,
  freezes_reset_month        INTEGER,           -- month number (1-12) of last freeze reset
  last_completed_date        DATE,
  total_days_completed       INTEGER NOT NULL DEFAULT 0,
  running_accuracy_rate      NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  total_questions_answered   INTEGER NOT NULL DEFAULT 0,
  total_questions_correct    INTEGER NOT NULL DEFAULT 0,
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- SECTION 4: LEETCODE STATS (Mobile App)
-- ============================================================

CREATE TABLE IF NOT EXISTS leetcode_stats (
  user_id               UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  username              TEXT,
  total_solved          INTEGER NOT NULL DEFAULT 0,
  easy_solved           INTEGER NOT NULL DEFAULT 0,
  medium_solved         INTEGER NOT NULL DEFAULT 0,
  hard_solved           INTEGER NOT NULL DEFAULT 0,
  batch_easy_solved     INTEGER NOT NULL DEFAULT 0,
  batch_medium_solved   INTEGER NOT NULL DEFAULT 0,
  batch_hard_solved     INTEGER NOT NULL DEFAULT 0,
  batch_weighted_score  INTEGER NOT NULL DEFAULT 0,
  batch_percentile      NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  weekly_solved         INTEGER NOT NULL DEFAULT 0,
  ranking               INTEGER,
  synced_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- LeetCode username whitelist: one row per allowed username.
-- Prevents duplicate username claims across users.
CREATE TABLE IF NOT EXISTS leetcode_username_whitelist (
  username   TEXT PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  added_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- SECTION 5: TASKS (Mobile App)
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_tasks (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id       UUID NOT NULL REFERENCES batches(id),
  task_date      DATE NOT NULL,
  task_type      TEXT NOT NULL CHECK (task_type IN ('leetcode', 'core_subject')),
  title          TEXT NOT NULL,
  description    TEXT,
  reference_url  TEXT,
  subject        TEXT,                           -- for core_subject type
  published_by   UUID NOT NULL REFERENCES users(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(batch_id, task_date, task_type)
);

CREATE TABLE IF NOT EXISTS task_completions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id      UUID NOT NULL REFERENCES daily_tasks(id),
  student_id   UUID NOT NULL REFERENCES users(id),
  completed    BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  verified_by  UUID REFERENCES users(id),
  verified_at  TIMESTAMPTZ,
  UNIQUE(task_id, student_id)
);

-- ============================================================
-- SECTION 6: PLACEMENT LOG (Mobile App writes, Web reads)
-- ============================================================

CREATE TABLE IF NOT EXISTS companies (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id              UUID NOT NULL REFERENCES batches(id),
  company_name          TEXT NOT NULL,
  visit_date            DATE NOT NULL,
  roles_offered         TEXT[],
  package_band_min      NUMERIC(10,2),
  package_band_max      NUMERIC(10,2),
  eligibility_criteria  TEXT,
  rounds                TEXT[],
  logged_by             UUID NOT NULL REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS placement_log_entries (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        UUID NOT NULL REFERENCES companies(id),
  student_id        UUID NOT NULL REFERENCES users(id),
  round_name        TEXT NOT NULL,
  experience_text   TEXT NOT NULL,
  is_anonymous      BOOLEAN NOT NULL DEFAULT false,
  approval_status   TEXT NOT NULL DEFAULT 'pending'
                    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by       UUID REFERENCES users(id),
  approved_at       TIMESTAMPTZ,
  kb_article_id     UUID,                        -- FK added after knowledge_brain_articles
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- SECTION 7: READINESS SCORE
-- ============================================================

CREATE TABLE IF NOT EXISTS readiness_scores (
  user_id          UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  score            NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  daily_five_score NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  leetcode_score   NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  mock_exam_score  NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  session_score    NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  band             TEXT GENERATED ALWAYS AS (
    CASE
      WHEN score >= 80 THEN 'strong'
      WHEN score >= 60 THEN 'building'
      WHEN score >= 40 THEN 'needs_attention'
      ELSE 'at_risk'
    END
  ) STORED,
  computed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS readiness_score_history (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  score            NUMERIC(5,2) NOT NULL,
  daily_five_score NUMERIC(5,2),
  leetcode_score   NUMERIC(5,2),
  mock_exam_score  NUMERIC(5,2),
  session_score    NUMERIC(5,2),
  snapshot_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE(user_id, snapshot_date)
);

-- ============================================================
-- SECTION 8: KNOWLEDGE BRAIN (Web App writes, shared)
-- ============================================================

CREATE TABLE IF NOT EXISTS knowledge_brain_articles (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title                   TEXT NOT NULL,
  content                 TEXT NOT NULL,
  summary                 TEXT,
  author_id               UUID REFERENCES users(id),
  source                  TEXT NOT NULL DEFAULT 'web'
                          CHECK (source IN ('web', 'flutter_placement_log')),
  placement_log_entry_id  UUID REFERENCES placement_log_entries(id),
  tags                    TEXT[],
  company_name            TEXT,
  batch_year              TEXT,
  approval_status         TEXT NOT NULL DEFAULT 'pending'
                          CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by             UUID REFERENCES users(id),
  approved_at             TIMESTAMPTZ,
  view_count              INTEGER NOT NULL DEFAULT 0,
  -- Full-text search vector (auto-updated by trigger in 05_search_index.sql)
  search_vector           tsvector,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add FK from placement_log_entries.kb_article_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'placement_log_entries_kb_article_id_fkey'
  ) THEN
    ALTER TABLE placement_log_entries ADD CONSTRAINT placement_log_entries_kb_article_id_fkey
      FOREIGN KEY (kb_article_id) REFERENCES knowledge_brain_articles(id);
  END IF;
END;
$$;

-- pgvector embeddings for semantic search
CREATE TABLE IF NOT EXISTS knowledge_embeddings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id   UUID NOT NULL REFERENCES knowledge_brain_articles(id) ON DELETE CASCADE,
  chunk_index  INTEGER NOT NULL DEFAULT 0,
  chunk_text   TEXT NOT NULL,
  embedding    vector(384),   -- gte-small output dimension is 384
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(article_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS knowledge_embeddings_vector_idx
  ON knowledge_embeddings
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 50);

CREATE INDEX IF NOT EXISTS knowledge_brain_articles_search_idx
  ON knowledge_brain_articles
  USING gin(search_vector);

-- ============================================================
-- SECTION 9: MOCK EXAMINATIONS (Web App)
-- ============================================================

CREATE TABLE IF NOT EXISTS mock_exams (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  description       TEXT,
  target_batch_id   UUID REFERENCES batches(id),
  created_by        UUID NOT NULL REFERENCES users(id),
  scheduled_at      TIMESTAMPTZ NOT NULL,
  duration_minutes  INTEGER NOT NULL DEFAULT 60,
  total_marks       INTEGER NOT NULL DEFAULT 100,
  proctoring_level  TEXT NOT NULL DEFAULT 'standard'
                    CHECK (proctoring_level IN ('standard', 'strict')),
  status            TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft', 'published', 'active', 'completed')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mock_exam_questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id         UUID NOT NULL REFERENCES mock_exams(id) ON DELETE CASCADE,
  question_text   TEXT NOT NULL,
  question_type   TEXT NOT NULL DEFAULT 'mcq'
                  CHECK (question_type IN ('mcq', 'coding', 'short_answer')),
  option_a        TEXT,
  option_b        TEXT,
  option_c        TEXT,
  option_d        TEXT,
  correct_option  TEXT,
  marks           INTEGER NOT NULL DEFAULT 1,
  order_index     INTEGER NOT NULL,
  UNIQUE(exam_id, order_index)
);

CREATE TABLE IF NOT EXISTS mock_exam_results (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id              UUID NOT NULL REFERENCES mock_exams(id),
  student_id           UUID NOT NULL REFERENCES users(id),
  score                NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  raw_marks            INTEGER NOT NULL DEFAULT 0,
  submitted_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  time_taken_seconds   INTEGER,
  proctoring_flags     JSONB NOT NULL DEFAULT '[]',
  UNIQUE(exam_id, student_id)
);

-- ============================================================
-- SECTION 10: NOTIFICATIONS AND ANNOUNCEMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS announcements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id    UUID REFERENCES batches(id),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  posted_by   UUID NOT NULL REFERENCES users(id),
  is_pinned   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type            TEXT NOT NULL,
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  is_read         BOOLEAN NOT NULL DEFAULT false,
  reference_id    UUID,
  reference_type  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_user_unread_idx
  ON notifications(user_id, is_read, created_at DESC)
  WHERE is_read = false;

-- ============================================================
-- SECTION 11: ALUMNI AND HOD
-- ============================================================

CREATE TABLE IF NOT EXISTS collaboration_posts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  posted_by    UUID NOT NULL REFERENCES users(id),
  post_type    TEXT NOT NULL CHECK (post_type IN ('job', 'project', 'mentorship')),
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  visibility   TEXT NOT NULL DEFAULT 'batch'
               CHECK (visibility IN ('lineage_only', 'batch', 'department')),
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lineage_messages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id     UUID NOT NULL REFERENCES users(id),
  receiver_id   UUID NOT NULL REFERENCES users(id),
  message_text  TEXT NOT NULL,
  is_read       BOOLEAN NOT NULL DEFAULT false,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      UUID REFERENCES users(id),
  action        TEXT NOT NULL,
  target_table  TEXT,
  target_id     UUID,
  metadata      JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS users_batch_id_idx             ON users(batch_id);
CREATE INDEX IF NOT EXISTS users_roll_no_idx              ON users(roll_no);
CREATE INDEX IF NOT EXISTS users_role_idx                 ON users(role);
CREATE INDEX IF NOT EXISTS users_app_role_idx             ON users(app_role);
CREATE INDEX IF NOT EXISTS placement_attendance_student_idx ON placement_attendance(student_id);
CREATE INDEX IF NOT EXISTS placement_attendance_session_idx ON placement_attendance(session_id);
CREATE INDEX IF NOT EXISTS placement_sessions_batch_idx   ON placement_sessions(batch_id);
CREATE INDEX IF NOT EXISTS daily_tasks_batch_date_idx     ON daily_tasks(batch_id, task_date);
CREATE INDEX IF NOT EXISTS mock_exam_results_student_idx  ON mock_exam_results(student_id);
CREATE INDEX IF NOT EXISTS mock_exam_results_exam_idx     ON mock_exam_results(exam_id);
CREATE INDEX IF NOT EXISTS knowledge_articles_approval_idx ON knowledge_brain_articles(approval_status);
CREATE INDEX IF NOT EXISTS lineage_map_junior_idx         ON lineage_map(junior_user_id);
CREATE INDEX IF NOT EXISTS lineage_map_senior_idx         ON lineage_map(senior_user_id);
CREATE INDEX IF NOT EXISTS companies_batch_idx            ON companies(batch_id);
CREATE INDEX IF NOT EXISTS readiness_scores_score_idx     ON readiness_scores(score DESC);
CREATE INDEX IF NOT EXISTS leetcode_stats_batch_score_idx ON leetcode_stats(batch_weighted_score DESC);
