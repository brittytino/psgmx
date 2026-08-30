-- ============================================================
-- PSGMX Migration 22 — CodeBox Schema
-- quests: tasks authored by PR/faculty with hidden test suites
-- code_submissions: student code attempts, Piston results, AI evaluation
-- See: docs/user-flow.md Chapter 4.3, 11.2
-- ============================================================

-- ── Quest types ─────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE quest_type AS ENUM ('coding', 'sql', 'system_design', 'debugging', 'aptitude', 'core_cs', 'communication');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE quest_status AS ENUM ('draft', 'published', 'paused', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── quests ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quests (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Authorship
  authored_by           UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,

  -- Content
  title                 TEXT NOT NULL CHECK (char_length(title) BETWEEN 3 AND 200),
  type                  quest_type NOT NULL DEFAULT 'coding',
  status                quest_status NOT NULL DEFAULT 'draft',
  problem_md            TEXT NOT NULL,               -- Markdown with LaTeX support
  difficulty            SMALLINT NOT NULL DEFAULT 3 CHECK (difficulty BETWEEN 1 AND 5),

  -- Coding task configuration
  allowed_languages     TEXT[] NOT NULL DEFAULT ARRAY['python', 'java', 'cpp', 'javascript'],
  time_limit_seconds    SMALLINT NOT NULL DEFAULT 3 CHECK (time_limit_seconds BETWEEN 1 AND 10),
  memory_limit_mb       SMALLINT NOT NULL DEFAULT 256,

  -- Test suite — stored in Supabase Storage, NEVER sent to client
  test_suite_storage_path TEXT,  -- e.g. 'quests/{quest_id}/test_suite.json'
  sample_cases_json     JSONB,   -- visible sample cases shown to student: [{input, expected_output, label}]

  -- Verification thresholds
  min_pass_rate         NUMERIC(4,3) NOT NULL DEFAULT 0.700 CHECK (min_pass_rate BETWEEN 0 AND 1),
  min_ai_quality_score  SMALLINT NOT NULL DEFAULT 5 CHECK (min_ai_quality_score BETWEEN 0 AND 10),
  max_attempts          SMALLINT NOT NULL DEFAULT 10,

  -- Targeting
  target_batch_id       UUID REFERENCES public.batches(id) ON DELETE SET NULL,
  target_team_ids       UUID[] NOT NULL DEFAULT '{}',  -- empty = all teams in batch

  -- Schedule
  available_from        TIMESTAMPTZ,
  due_at                TIMESTAMPTZ,

  -- Metadata
  topic_tags            TEXT[] NOT NULL DEFAULT '{}',
  xp_reward             SMALLINT NOT NULL DEFAULT 50
);

CREATE INDEX IF NOT EXISTS idx_quests_batch ON public.quests(target_batch_id);
CREATE INDEX IF NOT EXISTS idx_quests_status ON public.quests(status);
CREATE INDEX IF NOT EXISTS idx_quests_due ON public.quests(due_at);
CREATE INDEX IF NOT EXISTS idx_quests_authored_by ON public.quests(authored_by);

-- Auto-update updated_at
CREATE OR REPLACE TRIGGER quests_updated_at
  BEFORE UPDATE ON public.quests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── code_submissions ──────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE submission_verdict AS ENUM ('pending', 'verified_complete', 'failed_tests', 'failed_ai_quality', 'error', 'timeout');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.code_submissions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Identity
  quest_id              UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  attempt_number        SMALLINT NOT NULL DEFAULT 1,

  -- Submission
  language              TEXT NOT NULL,
  submitted_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Code is stored encrypted in Supabase Storage
  -- This column only stores the storage path, not the code itself
  code_storage_path     TEXT,  -- e.g. 'submissions/{submission_id}/code.txt'

  -- Piston API execution results
  piston_results_json   JSONB,
  -- Structure: { cases: [{test_index, passed, stdout, stderr, runtime_ms}], passed_count, total_count }

  -- OpenRouter AI evaluation
  ai_evaluation_json    JSONB,
  -- Structure: { quality_score, time_complexity, space_complexity, issues[], brief_feedback }
  ai_model_used         TEXT,  -- which model from the fallback chain responded

  -- Final verdict
  verdict               submission_verdict NOT NULL DEFAULT 'pending',
  is_verified_complete  BOOLEAN NOT NULL DEFAULT FALSE,
  verification_reason   TEXT,

  -- Uniqueness: one attempt number per student per quest
  UNIQUE (quest_id, student_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_submissions_quest ON public.code_submissions(quest_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON public.code_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_submissions_verified ON public.code_submissions(is_verified_complete) WHERE is_verified_complete = TRUE;

-- ── communication_attempts ────────────────────────────────────
-- Audio practice recordings (2-minute MP3, audio only per free tier constraint)
CREATE TABLE IF NOT EXISTS public.communication_attempts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  student_id            UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prompt_text           TEXT NOT NULL,  -- the practice prompt shown to the student

  -- Audio file stored in Supabase Storage (MP3, max 2 minutes)
  audio_storage_path    TEXT,  -- e.g. 'communication/{student_id}/{attempt_id}.mp3'
  duration_seconds      SMALLINT,

  -- Free STT transcript (from Hugging Face Whisper)
  transcript            TEXT,

  -- OpenRouter AI evaluation
  ai_scores_json        JSONB,
  -- Structure: { clarity_score, structure_score, filler_word_count, relevance_score, brief_feedback, suggested_improvement }
  ai_model_used         TEXT,
  ai_evaluated_at       TIMESTAMPTZ,

  -- Faculty human review (optional, higher confidence weight)
  faculty_reviewed      BOOLEAN NOT NULL DEFAULT FALSE,
  faculty_reviewer_id   UUID REFERENCES public.users(id),
  faculty_score         SMALLINT CHECK (faculty_score BETWEEN 0 AND 10),
  faculty_notes         TEXT,
  faculty_reviewed_at   TIMESTAMPTZ,

  -- Max 10 clips per student enforced in application layer
  -- Oldest clip storage_path is deleted from Supabase Storage when 11th is saved
  is_active             BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_comm_student ON public.communication_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_comm_active ON public.communication_attempts(student_id, is_active) WHERE is_active = TRUE;

-- ── RLS Policies ─────────────────────────────────────────────

-- Quests: students see published quests targeting their batch
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students view published quests for their batch"
  ON public.quests FOR SELECT
  TO authenticated
  USING (
    status = 'published'
    AND (
      target_batch_id IS NULL
      OR target_batch_id = (SELECT batch_id FROM public.users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Authors can manage their own quests"
  ON public.quests FOR ALL
  TO authenticated
  USING (authored_by = auth.uid())
  WITH CHECK (authored_by = auth.uid());

CREATE POLICY "PR can manage quests for their batch"
  ON public.quests FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.permission_key = 'publish_quests'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.permission_key = 'publish_quests'
    )
  );

CREATE POLICY "Service role full access to quests"
  ON public.quests FOR ALL
  TO service_role
  USING (TRUE) WITH CHECK (TRUE);

-- code_submissions: students see only their own; faculty/HOD see all for their batch
ALTER TABLE public.code_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students view their own submissions"
  ON public.code_submissions FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "Students insert their own submissions"
  ON public.code_submissions FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Faculty view submissions for recovery cases"
  ON public.code_submissions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND lower(COALESCE(u.role_label, '')) IN ('faculty', 'hod')
    )
  );

CREATE POLICY "Service role full access to submissions"
  ON public.code_submissions FOR ALL
  TO service_role
  USING (TRUE) WITH CHECK (TRUE);

-- communication_attempts: students see only their own
ALTER TABLE public.communication_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students manage their own communication attempts"
  ON public.communication_attempts FOR ALL
  TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Faculty view for mentoring review"
  ON public.communication_attempts FOR SELECT
  TO authenticated
  USING (
    faculty_reviewed = TRUE
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND lower(COALESCE(u.role_label, '')) IN ('faculty', 'hod')
    )
  );

CREATE POLICY "Service role full access to communication attempts"
  ON public.communication_attempts FOR ALL
  TO service_role
  USING (TRUE) WITH CHECK (TRUE);

-- ── Audit triggers ────────────────────────────────────────────
-- Submission verdict changes are audited
CREATE OR REPLACE FUNCTION public.audit_submission_verdict()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.verdict IS DISTINCT FROM NEW.verdict THEN
    INSERT INTO public.audit_logs (
      actor_id, action, table_name, record_id, old_data, new_data
    ) VALUES (
      auth.uid(),
      'submission_verdict_changed',
      'code_submissions',
      NEW.id,
      jsonb_build_object('verdict', OLD.verdict, 'is_verified', OLD.is_verified_complete),
      jsonb_build_object('verdict', NEW.verdict, 'is_verified', NEW.is_verified_complete)
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER audit_submission_verdict_trigger
  AFTER UPDATE ON public.code_submissions
  FOR EACH ROW EXECUTE FUNCTION public.audit_submission_verdict();
