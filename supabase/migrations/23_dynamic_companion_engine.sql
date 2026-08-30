-- ============================================================
-- PSGMX Migration 23 — Dynamic companion engine
-- Durable AI context, private CodeBox tests, eCampus timetable cache,
-- communication prompt bank, and audited mentor assignment.
-- ============================================================

BEGIN;

ALTER TABLE public.quests
  ALTER COLUMN authored_by DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS slug TEXT,
  ADD COLUMN IF NOT EXISTS bank_origin TEXT NOT NULL DEFAULT 'PSGMX original',
  ADD COLUMN IF NOT EXISTS is_system_seed BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS starter_code_json JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS solution_contract TEXT NOT NULL DEFAULT 'stdin_stdout'
    CHECK (solution_contract IN ('stdin_stdout'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_quests_slug_unique
  ON public.quests(slug) WHERE slug IS NOT NULL;

ALTER TABLE public.code_submissions
  ADD COLUMN IF NOT EXISTS code_sha256 TEXT,
  ADD COLUMN IF NOT EXISTS source_bytes INTEGER,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.quest_test_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_id UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  case_index SMALLINT NOT NULL CHECK (case_index BETWEEN 0 AND 50),
  stdin TEXT NOT NULL DEFAULT '',
  expected_stdout TEXT NOT NULL,
  is_sample BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (quest_id, case_index)
);

ALTER TABLE public.quest_test_cases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.quest_test_cases FROM anon, authenticated;
GRANT ALL ON public.quest_test_cases TO service_role;

CREATE TABLE IF NOT EXISTS public.ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'AI Senior conversation',
  context_summary TEXT NOT NULL DEFAULT '',
  last_model_used TEXT,
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 12000),
  model_used TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_time
  ON public.ai_conversations(user_id, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_time
  ON public.ai_messages(conversation_id, created_at DESC);

ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY ai_conversations_own ON public.ai_conversations
  FOR ALL TO authenticated
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());
CREATE POLICY ai_messages_own ON public.ai_messages
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.ai_conversations c
    WHERE c.id = conversation_id AND c.user_id = public.current_user_id()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.ai_conversations c
    WHERE c.id = conversation_id AND c.user_id = public.current_user_id()
  ));

CREATE TABLE IF NOT EXISTS public.communication_prompt_bank (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_text TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL CHECK (category IN (
    'introduction', 'behavioural', 'technical_explanation', 'project_defence',
    'group_discussion', 'workplace', 'storytelling'
  )),
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  evaluation_focus TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.communication_prompt_bank ENABLE ROW LEVEL SECURITY;
CREATE POLICY communication_prompts_read ON public.communication_prompt_bank
  FOR SELECT TO authenticated USING (is_active);
CREATE POLICY communication_prompts_faculty_write ON public.communication_prompt_bank
  FOR ALL TO authenticated
  USING (public.is_faculty_or_hod(public.current_user_id()))
  WITH CHECK (public.is_faculty_or_hod(public.current_user_id()));

INSERT INTO public.communication_prompt_bank(prompt_text, category, difficulty, evaluation_focus) VALUES
  ('Introduce yourself in 90 seconds for a software engineering interview.', 'introduction', 'easy', ARRAY['clarity','structure','relevance']),
  ('Explain one technical project without using jargon that a non-technical interviewer would understand.', 'project_defence', 'medium', ARRAY['clarity','audience awareness','impact']),
  ('Describe a disagreement in a team and how you helped the group reach a decision.', 'behavioural', 'medium', ARRAY['STAR structure','ownership','reflection']),
  ('Explain database indexing and one situation where an index can make performance worse.', 'technical_explanation', 'hard', ARRAY['accuracy','trade-offs','examples']),
  ('Defend one architecture decision in your final-year project and compare it with an alternative.', 'project_defence', 'hard', ARRAY['reasoning','trade-offs','evidence']),
  ('Speak for one minute on whether generative AI improves or weakens student learning.', 'group_discussion', 'medium', ARRAY['balance','structure','conclusion']),
  ('Describe a production bug you would investigate and narrate your debugging approach.', 'technical_explanation', 'hard', ARRAY['sequence','hypothesis','verification']),
  ('Explain a time you missed a deadline and what changed in your working method afterward.', 'behavioural', 'medium', ARRAY['accountability','learning','specificity']),
  ('Give a concise status update when a task is blocked by another team.', 'workplace', 'easy', ARRAY['brevity','ownership','next step']),
  ('Tell a two-minute story about learning a difficult technical concept.', 'storytelling', 'easy', ARRAY['narrative','clarity','reflection'])
ON CONFLICT (prompt_text) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.ecampus_weekly_timetable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reg_no TEXT NOT NULL UNIQUE REFERENCES public.whitelist(reg_no) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  data JSONB NOT NULL DEFAULT '[]',
  synced_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ecampus_weekly_timetable ENABLE ROW LEVEL SECURITY;
CREATE POLICY ecampus_timetable_own ON public.ecampus_weekly_timetable
  FOR SELECT TO authenticated USING (
    reg_no = (SELECT u.reg_no FROM public.users u WHERE u.id = public.current_user_id())
  );

CREATE TABLE IF NOT EXISTS public.mentor_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mentor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
  assigned_by UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  focus_areas TEXT[] NOT NULL DEFAULT '{}',
  active BOOLEAN NOT NULL DEFAULT true,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_mentor_per_student
  ON public.mentor_assignments(student_id) WHERE active;

ALTER TABLE public.mentor_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY mentor_assignments_participants_read ON public.mentor_assignments
  FOR SELECT TO authenticated USING (
    student_id = public.current_user_id()
    OR mentor_id = public.current_user_id()
    OR assigned_by = public.current_user_id()
    OR public.is_faculty_or_hod(public.current_user_id())
  );

CREATE OR REPLACE FUNCTION public.assign_student_mentor(
  p_student_id UUID,
  p_mentor_id UUID,
  p_focus_areas TEXT[] DEFAULT '{}'
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_batch UUID;
  v_assignment UUID;
BEGIN
  SELECT batch_id INTO v_batch
  FROM public.users
  WHERE id = p_student_id AND role_label = 'Student';
  IF v_batch IS NULL THEN RAISE EXCEPTION 'Student or batch not found'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = p_mentor_id AND role_label IN ('Faculty', 'HOD')
  ) THEN RAISE EXCEPTION 'Mentor must be faculty'; END IF;

  IF NOT (
    public.is_faculty_or_hod(v_actor)
    OR (
      public.is_placement_rep(v_actor)
      AND public.get_user_batch_id(v_actor) = v_batch
      AND public.user_has_permission(v_actor, 'manage_members')
    )
  ) THEN RAISE EXCEPTION 'Not authorized for this batch'; END IF;

  UPDATE public.mentor_assignments
  SET active = false, ended_at = now()
  WHERE student_id = p_student_id AND active;

  INSERT INTO public.mentor_assignments(
    student_id, mentor_id, batch_id, assigned_by, focus_areas
  ) VALUES (
    p_student_id, p_mentor_id, v_batch, v_actor, COALESCE(p_focus_areas, '{}')
  ) RETURNING id INTO v_assignment;

  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, batch_id, metadata)
  VALUES (v_actor, 'MENTOR_ASSIGNED', 'user', p_student_id, v_batch,
          jsonb_build_object('mentor_id', p_mentor_id, 'focus_areas', p_focus_areas));
  RETURN v_assignment;
END;
$$;

REVOKE ALL ON FUNCTION public.assign_student_mentor(UUID, UUID, TEXT[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_student_mentor(UUID, UUID, TEXT[]) TO authenticated;

-- Private storage buckets. Clients never receive hidden test suites.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'storage') THEN
    EXECUTE $storage$
      INSERT INTO storage.buckets(id, name, public, file_size_limit)
      VALUES
        ('quests', 'quests', false, 1048576),
        ('student-media', 'student-media', false, 12582912)
      ON CONFLICT (id) DO UPDATE
      SET public = false, file_size_limit = EXCLUDED.file_size_limit
    $storage$;
  END IF;
END;
$$;

COMMIT;
