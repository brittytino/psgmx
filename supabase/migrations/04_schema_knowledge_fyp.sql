-- ============================================================
-- PSGMX — 04_schema_knowledge_fyp.sql
-- ============================================================
-- Knowledge Brain (AI Senior RAG), lineage map, final-year-project
-- tracking, mock exams, and the smaller alumni/feedback tables.
--
-- Run AFTER 03_schema_placement.sql.
-- ============================================================

-- ── knowledge_brain_articles + knowledge_embeddings (RAG) ───────────────────
CREATE TABLE knowledge_brain_articles (
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
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX knowledge_brain_articles_search_idx ON knowledge_brain_articles USING gin(search_vector);

CREATE TABLE knowledge_embeddings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id  UUID NOT NULL REFERENCES knowledge_brain_articles(id) ON DELETE CASCADE,
  chunk_text  TEXT NOT NULL,
  chunk_index INTEGER NOT NULL DEFAULT 0,
  embedding   vector(384),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX knowledge_embeddings_article_idx ON knowledge_embeddings(article_id);

-- ── lineage_map — 1:1 junior→senior "Your Senior" mapping ───────────────────
CREATE TABLE lineage_map (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  senior_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  senior_quote   TEXT,
  assigned_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by    UUID REFERENCES users(id)
);

-- ── fyp_projects / fyp_progress_logs / fyp_feedback ─────────────────────────
CREATE TABLE fyp_projects (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id         UUID REFERENCES batches(id),
  student_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  description      TEXT,
  guide_name       TEXT,
  team_members_count INTEGER NOT NULL DEFAULT 1,
  status           TEXT NOT NULL DEFAULT 'proposal'
                    CHECK (status IN ('proposal', 'in_progress', 'completed', 'archived')),
  repository_url   TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fyp_progress_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  note       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fyp_feedback (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
  faculty_id UUID NOT NULL REFERENCES users(id),
  comment    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── mock_exams / mock_exam_questions / mock_exam_results ────────────────────
-- Matches apps/web/app/exam/[examId]/page.tsx's anti-cheat exam UI exactly
-- (per-student deterministic shuffle, camera + fullscreen proctoring,
-- proctoring_flags, submission via the submit_exam_server_side RPC).
CREATE TABLE mock_exams (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            TEXT NOT NULL,
  description      TEXT,
  duration_minutes INTEGER NOT NULL DEFAULT 60,
  total_marks      INTEGER NOT NULL DEFAULT 0,
  exam_date        TIMESTAMPTZ,
  batch_id         UUID REFERENCES batches(id),
  created_by       UUID REFERENCES users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE mock_exam_questions (
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
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE mock_exam_results (
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
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (exam_id, student_id)
);

-- ── collaboration_posts — alumni marketplace (jobs/projects/mentorship) ─────
CREATE TABLE collaboration_posts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_type   TEXT NOT NULL CHECK (post_type IN ('job', 'project', 'mentorship')),
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  visibility  TEXT NOT NULL DEFAULT 'batch' CHECK (visibility IN ('lineage_only', 'batch', 'department')),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  posted_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── user_feedback — in-app feedback widget ───────────────────────────────
CREATE TABLE user_feedback (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category      TEXT NOT NULL DEFAULT 'general',
  feedback_text TEXT NOT NULL,
  rating        INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── ai_query_logs — AI Senior usage log ─────────────────────────────────
CREATE TABLE ai_query_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  query_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DO $$
BEGIN
    RAISE NOTICE '✅ 04_schema_knowledge_fyp.sql complete.';
    RAISE NOTICE 'NEXT: run 05_schema_misc.sql';
END $$;
