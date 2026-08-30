-- ============================================================
-- PSGMX Migration 34 — AI-Generated Mock Test Schema
-- Tracks weekly AI-generated assessments, prevents duplicates,
-- and provides the schedule hook for the GitHub Actions cron.
-- ============================================================

-- ── ai_generated_tests — metadata log for AI-created exams ─────────────────
CREATE TABLE IF NOT EXISTS public.ai_generated_tests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id       UUID REFERENCES public.mock_exams(id) ON DELETE SET NULL,
  batch_id      UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
  week_number   SMALLINT NOT NULL,      -- ISO week (1–53)
  year          SMALLINT NOT NULL,
  domain        TEXT NOT NULL CHECK (domain IN (
    'aptitude', 'core_cs', 'coding', 'dbms', 'networks', 'os', 'general'
  )),
  question_count SMALLINT NOT NULL DEFAULT 10,
  status        TEXT NOT NULL DEFAULT 'generated'
                CHECK (status IN ('generated', 'published', 'faculty_reviewed', 'cancelled')),
  model_used    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at  TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_tests_week_domain_batch
  ON public.ai_generated_tests(week_number, year, domain, batch_id);

ALTER TABLE public.ai_generated_tests ENABLE ROW LEVEL SECURITY;

-- Students cannot see this table — only faculty, HOD, PR
CREATE POLICY ai_generated_tests_read
  ON public.ai_generated_tests FOR SELECT TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.is_placement_rep(public.current_user_id())
  );

CREATE POLICY ai_generated_tests_service_insert
  ON public.ai_generated_tests FOR INSERT TO service_role
  WITH CHECK (true);

CREATE POLICY ai_generated_tests_service_update
  ON public.ai_generated_tests FOR UPDATE TO service_role
  USING (true);

GRANT SELECT ON public.ai_generated_tests TO authenticated;
GRANT ALL ON public.ai_generated_tests TO service_role;

-- ── Add ai_generated flag to mock_exams if not already there ─────────────────
ALTER TABLE public.mock_exams
  ADD COLUMN IF NOT EXISTS ai_generated BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.mock_exams
  ADD COLUMN IF NOT EXISTS domain TEXT CHECK (domain IN (
    'aptitude', 'core_cs', 'coding', 'dbms', 'networks', 'os', 'general'
  ));

ALTER TABLE public.mock_exam_questions
  ADD COLUMN IF NOT EXISTS explanation TEXT,
  ADD COLUMN IF NOT EXISTS difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  ADD COLUMN IF NOT EXISTS topic_tag TEXT;

-- ── Helper: check if this week's test already exists ─────────────────────────
CREATE OR REPLACE FUNCTION public.weekly_mock_exists(
  p_domain TEXT,
  p_year SMALLINT DEFAULT EXTRACT(YEAR FROM NOW())::SMALLINT,
  p_week SMALLINT DEFAULT EXTRACT(WEEK FROM NOW())::SMALLINT,
  p_batch_id UUID DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.ai_generated_tests
    WHERE year = p_year AND week_number = p_week AND domain = p_domain
      AND (p_batch_id IS NULL OR batch_id = p_batch_id)
      AND status NOT IN ('cancelled')
  );
$$;

REVOKE ALL ON FUNCTION public.weekly_mock_exists(TEXT, SMALLINT, SMALLINT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.weekly_mock_exists(TEXT, SMALLINT, SMALLINT, UUID) TO service_role, authenticated;

-- ── Helper: get schedule for domains to rotate ───────────────────────────────
-- Returns the domain to generate this week based on round-robin.
-- Week 1: aptitude, Week 2: coding, Week 3: dbms, Week 4: os, Week 5: networks...
CREATE OR REPLACE FUNCTION public.get_weekly_mock_domain(
  p_week SMALLINT DEFAULT EXTRACT(WEEK FROM NOW())::SMALLINT
) RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT (ARRAY[
    'aptitude', 'coding', 'dbms', 'os', 'networks', 'core_cs', 'general'
  ])[(p_week % 7) + 1];
$$;

COMMENT ON TABLE public.ai_generated_tests IS
  'Tracks every AI-generated weekly mock test. The GitHub Actions workflow checks '
  'this table before calling /api/cron/mock-test-auto to prevent duplicate generation. '
  'Status: generated → published (after cron publishes) → faculty_reviewed (after faculty edits).';
