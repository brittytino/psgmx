-- ============================================================
-- PSGMX — 00_initial_schema.sql
-- Complete database schema for the PSGMX educational ecosystem.
-- Run order matters: parent tables must be created before child tables.
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_net";  -- for HTTP calls from triggers to Edge Functions

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
  id                    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                 TEXT NOT NULL UNIQUE,
  full_name             TEXT NOT NULL,
  roll_no               TEXT UNIQUE,             -- NULL for faculty/HOD
  batch_id              UUID REFERENCES batches(id),  -- NULL for faculty/HOD
  role                  TEXT NOT NULL DEFAULT 'student'
                        CHECK (role IN ('student', 'alumni', 'faculty', 'hod')),
  app_role              TEXT NOT NULL DEFAULT 'student'
                        CHECK (app_role IN ('student', 'team_leader', 'coordinator', 'placement_rep')),
                        -- app_role is only meaningful when role = 'student' or 'alumni'
  team_id               UUID,                    -- FK added after teams table is created
  avatar_url            TEXT,
  linkedin_url          TEXT,
  current_company       TEXT,                    -- filled in after graduation
  current_role_title    TEXT,                    -- filled in after graduation
  mentorship_open       BOOLEAN NOT NULL DEFAULT false,  -- alumni toggle
  onboarding_complete   BOOLEAN NOT NULL DEFAULT false,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
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
ALTER TABLE users ADD CONSTRAINT users_team_id_fkey
  FOREIGN KEY (team_id) REFERENCES teams(id);

-- Granular permission flags per user.
-- Used to customize what a Coordinator or Team Leader can do beyond their base app_role.
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
  roll_suffix      TEXT NOT NULL,            -- the shared numeric suffix e.g. '223'
  UNIQUE(junior_user_id, senior_user_id)
);

-- ============================================================
-- SECTION 2: PLACEMENT SESSION ATTENDANCE (Mobile App)
-- ============================================================

-- Sessions scheduled by Placement Rep or Coordinators via Flutter app.
CREATE TABLE IF NOT EXISTS placement_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id        UUID NOT NULL REFERENCES batches(id),
  scheduled_by    UUID NOT NULL REFERENCES users(id),
  session_date    DATE NOT NULL,
  session_time    TIME NOT NULL,
  topic           TEXT NOT NULL,
  target_scope    TEXT NOT NULL DEFAULT 'batch'
                  CHECK (target_scope IN ('batch', 'teams')),
                  -- if 'teams', see placement_session_teams join table
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Which teams a session targets when target_scope = 'teams'
CREATE TABLE IF NOT EXISTS placement_session_teams (
  session_id  UUID NOT NULL REFERENCES placement_sessions(id) ON DELETE CASCADE,
  team_id     UUID NOT NULL REFERENCES teams(id),
  PRIMARY KEY (session_id, team_id)
);

-- Per-student attendance per session. Written by Team Leaders via Flutter app.
CREATE TABLE IF NOT EXISTS placement_attendance (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  UUID NOT NULL REFERENCES placement_sessions(id),
  student_id  UUID NOT NULL REFERENCES users(id),
  status      TEXT NOT NULL DEFAULT 'absent'
              CHECK (status IN ('present', 'absent', 'excused')),
  marked_by   UUID NOT NULL REFERENCES users(id),  -- the Team Leader
  note        TEXT,
  marked_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(session_id, student_id)
);

-- ============================================================
-- SECTION 3: DAILY FIVE QUIZ (Mobile App)
-- ============================================================

-- Central question bank. Written by admins/coordinators, read by Flutter app.
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

-- Per-student streak state. This is the ONLY daily-five data that persists.
-- Individual question responses are NEVER stored in this database.
CREATE TABLE IF NOT EXISTS daily_five_streaks (
  user_id                    UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak             INTEGER NOT NULL DEFAULT 0,
  longest_streak             INTEGER NOT NULL DEFAULT 0,
  freezes_remaining          INTEGER NOT NULL DEFAULT 2,
  freezes_reset_month        INTEGER,           -- month number (1-12) of last freeze reset
  last_completed_date        DATE,
  total_days_completed       INTEGER NOT NULL DEFAULT 0,
  running_accuracy_rate      NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  -- running_accuracy_rate = (total correct / total answered) * 100
  -- Updated as a running calculation each time a session completes.
  total_questions_answered   INTEGER NOT NULL DEFAULT 0,
  total_questions_correct    INTEGER NOT NULL DEFAULT 0,
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- SECTION 4: LEETCODE STATS (Mobile App)
-- ============================================================

-- Synced from LeetCode public API by the Flutter app every 6 hours.
CREATE TABLE IF NOT EXISTS leetcode_stats (
  user_id               UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  username              TEXT,
  total_solved          INTEGER NOT NULL DEFAULT 0,
  easy_solved           INTEGER NOT NULL DEFAULT 0,
  medium_solved         INTEGER NOT NULL DEFAULT 0,
  hard_solved           INTEGER NOT NULL DEFAULT 0,
  -- Batch-period solved counts (from batch start_date to now)
  batch_easy_solved     INTEGER NOT NULL DEFAULT 0,
  batch_medium_solved   INTEGER NOT NULL DEFAULT 0,
  batch_hard_solved     INTEGER NOT NULL DEFAULT 0,
  -- Batch-period weighted score = easy*1 + medium*2 + hard*3
  batch_weighted_score  INTEGER NOT NULL DEFAULT 0,
  -- Percentile within own batch (0-100), recomputed by Edge Function
  batch_percentile      NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  weekly_solved         INTEGER NOT NULL DEFAULT 0,  -- problems solved in last 7 days
  ranking               INTEGER,
  synced_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- SECTION 5: TASKS (Mobile App)
-- ============================================================

-- Daily tasks published by Placement Rep or Coordinators.
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

-- Student task completion records.
CREATE TABLE IF NOT EXISTS task_completions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id      UUID NOT NULL REFERENCES daily_tasks(id),
  student_id   UUID NOT NULL REFERENCES users(id),
  completed    BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  verified_by  UUID REFERENCES users(id),  -- Team Leader who verified
  verified_at  TIMESTAMPTZ,
  UNIQUE(task_id, student_id)
);

-- ============================================================
-- SECTION 6: PLACEMENT LOG (Mobile App writes, Web reads)
-- ============================================================

-- Company visit records. Created by Placement Rep via Flutter app.
CREATE TABLE IF NOT EXISTS companies (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id              UUID NOT NULL REFERENCES batches(id),
  company_name          TEXT NOT NULL,
  visit_date            DATE NOT NULL,
  roles_offered         TEXT[],             -- array of role names
  package_band_min      NUMERIC(10,2),      -- in LPA
  package_band_max      NUMERIC(10,2),      -- in LPA
  eligibility_criteria  TEXT,
  rounds                TEXT[],             -- e.g. ['Online Test', 'Technical', 'HR']
  logged_by             UUID NOT NULL REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Personal experience writeups by second-year students.
-- Flows into Knowledge Brain on Next.js after faculty approval.
CREATE TABLE IF NOT EXISTS placement_log_entries (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        UUID NOT NULL REFERENCES companies(id),
  student_id        UUID NOT NULL REFERENCES users(id),
  round_name        TEXT NOT NULL,
  experience_text   TEXT NOT NULL,
  is_anonymous      BOOLEAN NOT NULL DEFAULT false,
  approval_status   TEXT NOT NULL DEFAULT 'pending'
                    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by       UUID REFERENCES users(id),  -- faculty member
  approved_at       TIMESTAMPTZ,
  kb_article_id     UUID,                       -- FK to knowledge_brain_articles once ingested
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- SECTION 7: READINESS SCORE (Computed by Edge Function)
-- ============================================================

-- Current score per student. Updated within 60 seconds of any contributing event.
CREATE TABLE IF NOT EXISTS readiness_scores (
  user_id          UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  score            NUMERIC(5,2) NOT NULL DEFAULT 0.00,   -- 0 to 100
  -- Component scores (each 0 to their max)
  daily_five_score NUMERIC(5,2) NOT NULL DEFAULT 0.00,  -- max 30
  leetcode_score   NUMERIC(5,2) NOT NULL DEFAULT 0.00,  -- max 25
  mock_exam_score  NUMERIC(5,2) NOT NULL DEFAULT 0.00,  -- max 35
  session_score    NUMERIC(5,2) NOT NULL DEFAULT 0.00,  -- max 10
  -- Band for quick filtering
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

-- Daily snapshots for trend analysis.
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

-- Faculty-approved articles, guides, and interview experiences.
-- Some rows originate from placement_log_entries (source='flutter_placement_log').
-- Some are written directly on the web platform (source='web').
CREATE TABLE IF NOT EXISTS knowledge_brain_articles (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title                   TEXT NOT NULL,
  content                 TEXT NOT NULL,
  summary                 TEXT,                  -- 2-3 sentence summary for AI context
  author_id               UUID REFERENCES users(id),
  source                  TEXT NOT NULL DEFAULT 'web'
                          CHECK (source IN ('web', 'flutter_placement_log')),
  placement_log_entry_id  UUID REFERENCES placement_log_entries(id),
  tags                    TEXT[],
  company_name            TEXT,                  -- if interview-experience article
  batch_year              TEXT,                  -- e.g. '25MX' for batch context
  approval_status         TEXT NOT NULL DEFAULT 'pending'
                          CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by             UUID REFERENCES users(id),
  approved_at             TIMESTAMPTZ,
  view_count              INTEGER NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add FK from placement_log_entries.kb_article_id to knowledge_brain_articles
ALTER TABLE placement_log_entries ADD CONSTRAINT placement_log_entries_kb_article_id_fkey
  FOREIGN KEY (kb_article_id) REFERENCES knowledge_brain_articles(id);

-- pgvector embeddings for semantic search.
-- Requires: CREATE EXTENSION vector; (enabled above)
CREATE TABLE IF NOT EXISTS knowledge_embeddings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id   UUID NOT NULL REFERENCES knowledge_brain_articles(id) ON DELETE CASCADE,
  chunk_index  INTEGER NOT NULL DEFAULT 0,  -- for multi-chunk articles
  chunk_text   TEXT NOT NULL,
  embedding    vector(1536),                -- OpenAI text-embedding-3-small / gte-small dimension
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(article_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS knowledge_embeddings_vector_idx
  ON knowledge_embeddings
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- ============================================================
-- SECTION 9: MOCK EXAMINATIONS (Web App)
-- ============================================================

-- Exam definitions created by faculty on the web platform.
CREATE TABLE IF NOT EXISTS mock_exams (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  description       TEXT,
  target_batch_id   UUID REFERENCES batches(id),  -- NULL = all active batches
  created_by        UUID NOT NULL REFERENCES users(id),
  scheduled_at      TIMESTAMPTZ NOT NULL,
  duration_minutes  INTEGER NOT NULL DEFAULT 60,
  total_marks       INTEGER NOT NULL DEFAULT 100,
  proctoring_level  TEXT NOT NULL DEFAULT 'standard'
                    CHECK (proctoring_level IN ('standard', 'strict')),
                    -- standard: camera + tab detection
                    -- strict:   camera + tab detection + fullscreen enforcement
  status            TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft', 'published', 'active', 'completed')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Individual questions within a mock exam.
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
  correct_option  TEXT,              -- for mcq
  marks           INTEGER NOT NULL DEFAULT 1,
  order_index     INTEGER NOT NULL,
  UNIQUE(exam_id, order_index)
);

-- Per-student results for each exam.
CREATE TABLE IF NOT EXISTS mock_exam_results (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id              UUID NOT NULL REFERENCES mock_exams(id),
  student_id           UUID NOT NULL REFERENCES users(id),
  score                NUMERIC(5,2) NOT NULL DEFAULT 0.00,  -- 0 to 100 (normalised %)
  raw_marks            INTEGER NOT NULL DEFAULT 0,
  submitted_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  time_taken_seconds   INTEGER,
  proctoring_flags     JSONB NOT NULL DEFAULT '[]',
  -- e.g. [{"type":"tab_switch","timestamp":"..."},{"type":"camera_loss","timestamp":"..."}]
  UNIQUE(exam_id, student_id)
);

-- ============================================================
-- SECTION 10: NOTIFICATIONS AND ANNOUNCEMENTS (Both Apps)
-- ============================================================

CREATE TABLE IF NOT EXISTS announcements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id    UUID REFERENCES batches(id),  -- NULL = all batches
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
  -- Types: 'exam_scheduled', 'streak_nudge', 'announcement',
  --        'session_reminder', 'session_marked', 'graduation',
  --        'lineage_senior_active', 'article_approved'
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  is_read         BOOLEAN NOT NULL DEFAULT false,
  reference_id    UUID,               -- optional FK to related record
  reference_type  TEXT,               -- e.g. 'mock_exam', 'placement_session'
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_user_unread_idx
  ON notifications(user_id, is_read, created_at DESC)
  WHERE is_read = false;

-- ============================================================
-- SECTION 11: ALUMNI AND HOD (Web App)
-- ============================================================

-- Collaboration marketplace posts by alumni or students.
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

-- Lineage messages between alumni and their matched junior students.
CREATE TABLE IF NOT EXISTS lineage_messages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id     UUID NOT NULL REFERENCES users(id),
  receiver_id   UUID NOT NULL REFERENCES users(id),
  message_text  TEXT NOT NULL,
  is_read       BOOLEAN NOT NULL DEFAULT false,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Audit log for all sensitive actions.
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
-- ADDITIONAL INDEXES for query performance
-- ============================================================

CREATE INDEX IF NOT EXISTS users_batch_id_idx ON users(batch_id);
CREATE INDEX IF NOT EXISTS users_roll_no_idx ON users(roll_no);
CREATE INDEX IF NOT EXISTS users_role_idx ON users(role);
CREATE INDEX IF NOT EXISTS placement_attendance_student_idx ON placement_attendance(student_id);
CREATE INDEX IF NOT EXISTS placement_attendance_session_idx ON placement_attendance(session_id);
CREATE INDEX IF NOT EXISTS placement_sessions_batch_idx ON placement_sessions(batch_id);
CREATE INDEX IF NOT EXISTS daily_tasks_batch_date_idx ON daily_tasks(batch_id, task_date);
CREATE INDEX IF NOT EXISTS mock_exam_results_student_idx ON mock_exam_results(student_id);
CREATE INDEX IF NOT EXISTS mock_exam_results_exam_idx ON mock_exam_results(exam_id);
CREATE INDEX IF NOT EXISTS knowledge_brain_articles_approval_idx ON knowledge_brain_articles(approval_status);
CREATE INDEX IF NOT EXISTS lineage_map_junior_idx ON lineage_map(junior_user_id);
CREATE INDEX IF NOT EXISTS lineage_map_senior_idx ON lineage_map(senior_user_id);
CREATE INDEX IF NOT EXISTS companies_batch_idx ON companies(batch_id);
CREATE INDEX IF NOT EXISTS readiness_scores_score_idx ON readiness_scores(score DESC);
