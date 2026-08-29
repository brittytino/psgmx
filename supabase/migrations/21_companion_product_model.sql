-- ============================================================
-- PSGMX — Companion product model
-- Preparation readiness is the product. Official drives remain in NEO PAT.
-- This migration is additive and preserves legacy placement data only for
-- historical migration/rollback; new product flows use the tables below.
-- ============================================================

-- ── Capability vocabulary ──────────────────────────────────────────────────

ALTER TABLE public.user_permissions
  DROP CONSTRAINT IF EXISTS user_permissions_permission_key_check;

ALTER TABLE public.user_permissions
  ADD CONSTRAINT user_permissions_permission_key_check CHECK (permission_key IN (
    -- Companion capabilities
    'manage_members',
    'configure_teams',
    'schedule_preparation_sessions',
    'mark_preparation_participation',
    'publish_quests',
    'publish_announcements',
    'manage_preparation_tracks',
    'moderate_interview_patterns',
    'view_batch_analytics',
    'view_ai_mentor',
    'governance_admin',
    -- Legacy compatibility keys. Do not grant these in new UI.
    'schedule_placement_sessions',
    'mark_placement_attendance',
    'publish_tasks',
    'manage_company_records',
    'moderate_placement_log'
  ));

CREATE OR REPLACE FUNCTION public.is_governance_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = p_user_id
      AND (
        lower(COALESCE(u.role_label, '')) = 'hod'
        OR EXISTS (
          SELECT 1 FROM public.user_permissions up
          WHERE up.user_id = u.id AND up.permission_key = 'governance_admin'
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION public.is_governance_admin(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_governance_admin(UUID) TO authenticated, service_role;

-- Student administrators can grant only student operational capabilities.
-- Governance access is intentionally excluded from this RPC.
CREATE OR REPLACE FUNCTION public.set_member_permissions(
  p_user_id UUID,
  p_permissions TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_batch UUID;
  v_key TEXT;
  v_allowed CONSTANT TEXT[] := ARRAY[
    'manage_members', 'configure_teams', 'schedule_preparation_sessions',
    'mark_preparation_participation', 'publish_quests',
    'publish_announcements', 'manage_preparation_tracks',
    'moderate_interview_patterns', 'view_batch_analytics', 'view_ai_mentor'
  ];
BEGIN
  SELECT batch_id INTO v_batch FROM public.users WHERE id = p_user_id;
  IF v_batch IS NULL THEN RAISE EXCEPTION 'Member not found'; END IF;

  IF NOT (
    public.is_faculty_or_hod(v_actor)
    OR (
      public.user_has_permission(v_actor, 'manage_members')
      AND public.get_user_batch_id(v_actor) = v_batch
    )
  ) THEN
    RAISE EXCEPTION 'Not authorized to manage this member';
  END IF;

  IF EXISTS (
    SELECT 1 FROM unnest(COALESCE(p_permissions, ARRAY[]::TEXT[])) p
    WHERE NOT (p = ANY(v_allowed))
  ) THEN
    RAISE EXCEPTION 'Unknown or governance-only permission';
  END IF;

  DELETE FROM public.user_permissions
  WHERE user_id = p_user_id AND permission_key <> 'governance_admin';

  FOREACH v_key IN ARRAY COALESCE(p_permissions, ARRAY[]::TEXT[]) LOOP
    INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
    VALUES (p_user_id, v_key, v_actor)
    ON CONFLICT (user_id, permission_key) DO UPDATE
      SET granted_by = EXCLUDED.granted_by, granted_at = now();
  END LOOP;

  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, batch_id, metadata)
  VALUES (
    v_actor, 'MEMBER_PERMISSIONS_UPDATED', 'user', p_user_id, v_batch,
    jsonb_build_object('permissions', COALESCE(p_permissions, ARRAY[]::TEXT[]))
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_member_permissions(UUID, TEXT[]) TO authenticated;

-- Migrate existing student administrator grants to the companion vocabulary.
INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
SELECT user_id,
  CASE permission_key
    WHEN 'schedule_placement_sessions' THEN 'schedule_preparation_sessions'
    WHEN 'mark_placement_attendance' THEN 'mark_preparation_participation'
    WHEN 'publish_tasks' THEN 'publish_quests'
    WHEN 'manage_company_records' THEN 'manage_preparation_tracks'
    WHEN 'moderate_placement_log' THEN 'moderate_interview_patterns'
  END,
  granted_by
FROM public.user_permissions
WHERE permission_key IN (
  'schedule_placement_sessions', 'mark_placement_attendance', 'publish_tasks',
  'manage_company_records', 'moderate_placement_log'
)
ON CONFLICT (user_id, permission_key) DO NOTHING;

-- Keep future representative promotions on the same capability vocabulary.
CREATE OR REPLACE FUNCTION public.ensure_rep_permissions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF COALESCE((NEW.roles->>'isPlacementRep')::boolean, false) THEN
    INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
    SELECT NEW.id, permission_key, NEW.id
    FROM unnest(ARRAY[
      'manage_members', 'configure_teams', 'schedule_preparation_sessions',
      'mark_preparation_participation', 'publish_quests',
      'publish_announcements', 'manage_preparation_tracks',
      'moderate_interview_patterns', 'view_batch_analytics', 'view_ai_mentor'
    ]) AS permissions(permission_key)
    ON CONFLICT (user_id, permission_key) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
SELECT u.id, permission_key, u.id
FROM public.users u
CROSS JOIN unnest(ARRAY[
  'manage_members', 'configure_teams', 'schedule_preparation_sessions',
  'mark_preparation_participation', 'publish_quests',
  'publish_announcements', 'manage_preparation_tracks',
  'moderate_interview_patterns', 'view_batch_analytics', 'view_ai_mentor'
]) AS permissions(permission_key)
WHERE COALESCE((u.roles->>'isPlacementRep')::boolean, false)
ON CONFLICT (user_id, permission_key) DO NOTHING;

-- ── Preparation tracks ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.preparation_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID REFERENCES public.batches(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  summary TEXT NOT NULL CHECK (char_length(trim(summary)) BETWEEN 10 AND 1000),
  stage TEXT NOT NULL DEFAULT 'all'
    CHECK (stage IN ('foundation', 'proof', 'all')),
  skill_domains TEXT[] NOT NULL DEFAULT '{}',
  difficulty TEXT NOT NULL DEFAULT 'adaptive'
    CHECK (difficulty IN ('foundation', 'intermediate', 'advanced', 'adaptive')),
  estimated_weeks INTEGER NOT NULL DEFAULT 4 CHECK (estimated_weeks BETWEEN 1 AND 24),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_preparation_tracks_batch_stage
  ON public.preparation_tracks(batch_id, stage, is_active);

ALTER TABLE public.preparation_tracks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "preparation_tracks_read"
  ON public.preparation_tracks FOR SELECT TO authenticated
  USING (
    is_active
    AND (batch_id IS NULL OR public.can_access_batch(batch_id))
  );

CREATE POLICY "preparation_tracks_manage"
  ON public.preparation_tracks FOR ALL TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.user_has_permission(public.current_user_id(), 'manage_preparation_tracks')
  )
  WITH CHECK (
    public.is_faculty_or_hod(public.current_user_id())
    OR (
      public.user_has_permission(public.current_user_id(), 'manage_preparation_tracks')
      AND (batch_id IS NULL OR batch_id = public.get_user_batch_id(public.current_user_id()))
    )
  );

-- ── Interview Pattern Library ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.interview_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 5 AND 160),
  pattern_type TEXT NOT NULL CHECK (pattern_type IN (
    'aptitude_screening', 'coding_round', 'technical_deep_dive',
    'fyp_discussion', 'behavioural', 'group_discussion', 'general'
  )),
  historical_context TEXT,
  preparation_helped TEXT NOT NULL CHECK (char_length(trim(preparation_helped)) >= 20),
  mistakes TEXT,
  example_themes TEXT[] NOT NULL DEFAULT '{}',
  advice TEXT NOT NULL CHECK (char_length(trim(advice)) >= 20),
  company_name TEXT,
  batch_year TEXT,
  approval_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (approval_status IN ('draft', 'pending', 'changes_requested', 'approved', 'rejected', 'retired')),
  reviewed_by UUID REFERENCES public.users(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  review_due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_interview_patterns_status_created
  ON public.interview_patterns(approval_status, created_at DESC);

ALTER TABLE public.interview_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "interview_patterns_read_approved_or_own"
  ON public.interview_patterns FOR SELECT TO authenticated
  USING (
    approval_status = 'approved'
    OR author_id = public.current_user_id()
    OR public.is_faculty_or_hod(public.current_user_id())
    OR public.user_has_permission(public.current_user_id(), 'moderate_interview_patterns')
  );

CREATE POLICY "interview_patterns_author_insert"
  ON public.interview_patterns FOR INSERT TO authenticated
  WITH CHECK (author_id = public.current_user_id());

CREATE POLICY "interview_patterns_author_update_draft"
  ON public.interview_patterns FOR UPDATE TO authenticated
  USING (
    author_id = public.current_user_id()
    AND approval_status IN ('draft', 'pending', 'changes_requested')
  )
  WITH CHECK (author_id = public.current_user_id());

CREATE POLICY "interview_patterns_moderate"
  ON public.interview_patterns FOR UPDATE TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.user_has_permission(public.current_user_id(), 'moderate_interview_patterns')
  )
  WITH CHECK (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.user_has_permission(public.current_user_id(), 'moderate_interview_patterns')
  );

-- Approved patterns become source-grounded Knowledge Brain material.
CREATE UNIQUE INDEX IF NOT EXISTS idx_knowledge_source_unique
  ON public.knowledge_brain_articles(source)
  WHERE source LIKE 'interview_pattern:%';

CREATE OR REPLACE FUNCTION public.sync_approved_interview_pattern()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_source TEXT := 'interview_pattern:' || NEW.id::TEXT;
  v_content TEXT;
BEGIN
  IF NEW.approval_status <> 'approved' THEN
    UPDATE public.knowledge_brain_articles
      SET approval_status = 'rejected', updated_at = now()
    WHERE source = v_source AND NEW.approval_status IN ('rejected', 'retired');
    RETURN NEW;
  END IF;

  v_content := concat_ws(E'\n\n',
    NULLIF(NEW.historical_context, ''),
    'Preparation that helped: ' || NEW.preparation_helped,
    CASE WHEN NULLIF(NEW.mistakes, '') IS NOT NULL THEN 'Mistakes and lessons: ' || NEW.mistakes END,
    'Advice: ' || NEW.advice
  );

  INSERT INTO public.knowledge_brain_articles(
    author_id, title, summary, content, tags, company_name, source,
    batch_year, approval_status, reviewed_by, reviewed_at
  ) VALUES (
    NEW.author_id, NEW.title, left(NEW.advice, 300), v_content,
    ARRAY['interview-pattern', NEW.pattern_type], NEW.company_name, v_source,
    NEW.batch_year, 'approved', NEW.reviewed_by, NEW.reviewed_at
  )
  ON CONFLICT (source) WHERE source LIKE 'interview_pattern:%'
  DO UPDATE SET
    title = EXCLUDED.title,
    summary = EXCLUDED.summary,
    content = EXCLUDED.content,
    tags = EXCLUDED.tags,
    company_name = EXCLUDED.company_name,
    batch_year = EXCLUDED.batch_year,
    approval_status = 'approved',
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = now();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_approved_interview_pattern_trigger
  ON public.interview_patterns;
CREATE TRIGGER sync_approved_interview_pattern_trigger
AFTER INSERT OR UPDATE OF approval_status, title, preparation_helped, mistakes, advice
ON public.interview_patterns
FOR EACH ROW EXECUTE FUNCTION public.sync_approved_interview_pattern();

-- ── Versioned readiness evidence ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.readiness_dimension_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  dimension TEXT NOT NULL CHECK (dimension IN (
    'aptitude_reasoning', 'coding_problem_solving', 'core_computer_science',
    'communication_interview', 'assessment_performance', 'portfolio_project'
  )),
  score NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
  confidence TEXT NOT NULL DEFAULT 'low' CHECK (confidence IN ('low', 'medium', 'high')),
  evidence_count INTEGER NOT NULL DEFAULT 0 CHECK (evidence_count >= 0),
  evidence_fresh_at TIMESTAMPTZ,
  algorithm_version TEXT NOT NULL DEFAULT 'v2',
  evidence JSONB NOT NULL DEFAULT '[]',
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, dimension, algorithm_version)
);

ALTER TABLE public.readiness_dimension_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "readiness_dimensions_read_own"
  ON public.readiness_dimension_scores FOR SELECT TO authenticated
  USING (user_id = public.current_user_id());

CREATE POLICY "readiness_dimensions_read_faculty"
  ON public.readiness_dimension_scores FOR SELECT TO authenticated
  USING (public.is_faculty_or_hod(public.current_user_id()));

CREATE OR REPLACE FUNCTION public.refresh_readiness_dimensions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_components JSONB := NEW.components_json;
  v_computed TIMESTAMPTZ := NEW.computed_at;
BEGIN
  INSERT INTO public.readiness_dimension_scores(
    user_id, dimension, score, confidence, evidence_count,
    evidence_fresh_at, algorithm_version, evidence, computed_at
  )
  SELECT NEW.user_id, dimension, score, confidence, evidence_count,
    CASE WHEN evidence_count > 0 THEN v_computed ELSE NULL END,
    'v2', evidence, v_computed
  FROM (VALUES
    ('aptitude_reasoning',
      (COALESCE((v_components->>'daily_five_accuracy_pct')::numeric, 0) * .60 + COALESCE((v_components->>'daily_five_adherence_pct')::numeric, 0) * .40),
      'medium', 2, jsonb_build_array('daily_five_accuracy_pct', 'daily_five_adherence_pct')),
    ('coding_problem_solving',
      COALESCE((v_components->>'leetcode_momentum_percentile')::numeric, 0),
      CASE WHEN v_components ? 'leetcode_momentum_percentile' THEN 'medium' ELSE 'low' END,
      CASE WHEN v_components ? 'leetcode_momentum_percentile' THEN 1 ELSE 0 END,
      CASE WHEN v_components ? 'leetcode_momentum_percentile' THEN jsonb_build_array('leetcode_momentum_percentile') ELSE '[]'::jsonb END),
    ('core_computer_science',
      COALESCE((v_components->>'task_completion_rate_pct')::numeric, 0),
      CASE WHEN v_components ? 'task_completion_rate_pct' THEN 'low' ELSE 'low' END,
      CASE WHEN v_components ? 'task_completion_rate_pct' THEN 1 ELSE 0 END,
      CASE WHEN v_components ? 'task_completion_rate_pct' THEN jsonb_build_array('quest_completion_rate_pct') ELSE '[]'::jsonb END),
    ('assessment_performance',
      COALESCE((v_components->>'daily_five_accuracy_pct')::numeric, 0),
      CASE WHEN v_components ? 'daily_five_accuracy_pct' THEN 'medium' ELSE 'low' END,
      CASE WHEN v_components ? 'daily_five_accuracy_pct' THEN 1 ELSE 0 END,
      CASE WHEN v_components ? 'daily_five_accuracy_pct' THEN jsonb_build_array('daily_five_accuracy_pct') ELSE '[]'::jsonb END),
    ('communication_interview', 0::numeric, 'low', 0, '[]'::jsonb),
    ('portfolio_project', 0::numeric, 'low', 0, '[]'::jsonb)
  ) AS dimensions(dimension, score, confidence, evidence_count, evidence)
  ON CONFLICT (user_id, dimension, algorithm_version) DO UPDATE SET
    score = EXCLUDED.score,
    confidence = EXCLUDED.confidence,
    evidence_count = EXCLUDED.evidence_count,
    evidence_fresh_at = EXCLUDED.evidence_fresh_at,
    evidence = EXCLUDED.evidence,
    computed_at = EXCLUDED.computed_at;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS refresh_readiness_dimensions_trigger ON public.readiness_scores;
CREATE TRIGGER refresh_readiness_dimensions_trigger
AFTER INSERT OR UPDATE OF components_json ON public.readiness_scores
FOR EACH ROW EXECUTE FUNCTION public.refresh_readiness_dimensions();

-- Backfill the latest existing snapshot without changing its score or date.
UPDATE public.readiness_scores snapshot
SET components_json = snapshot.components_json
WHERE snapshot.id IN (
  SELECT DISTINCT ON (user_id) id
  FROM public.readiness_scores
  ORDER BY user_id, computed_at DESC
);

-- ── Ethical gamification: XP, mastery and weekly journeys ──────────────────

CREATE TABLE IF NOT EXISTS public.user_experience (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  lifetime_xp INTEGER NOT NULL DEFAULT 0 CHECK (lifetime_xp >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  last_meaningful_action_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.experience_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_key TEXT NOT NULL,
  source_type TEXT NOT NULL,
  source_id UUID,
  xp INTEGER NOT NULL CHECK (xp BETWEEN 1 AND 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, event_key, source_type, source_id)
);

CREATE TABLE IF NOT EXISTS public.user_mastery (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  skill_key TEXT NOT NULL,
  level TEXT NOT NULL DEFAULT 'discovering' CHECK (level IN (
    'discovering', 'practising', 'applying', 'demonstrating', 'maintaining'
  )),
  confidence TEXT NOT NULL DEFAULT 'low' CHECK (confidence IN ('low', 'medium', 'high')),
  evidence_count INTEGER NOT NULL DEFAULT 0,
  last_evidence_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, skill_key)
);

CREATE TABLE IF NOT EXISTS public.weekly_journeys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  stage TEXT NOT NULL CHECK (stage IN ('foundation', 'proof', 'alumni_contribution')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, week_start)
);

CREATE TABLE IF NOT EXISTS public.journey_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES public.weekly_journeys(id) ON DELETE CASCADE,
  mission_type TEXT NOT NULL,
  title TEXT NOT NULL,
  skill_dimension TEXT,
  estimated_minutes INTEGER NOT NULL DEFAULT 5 CHECK (estimated_minutes BETWEEN 1 AND 180),
  action_path TEXT,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'in_progress', 'completed', 'skipped')),
  progress JSONB NOT NULL DEFAULT '{}',
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.record_meaningful_experience(
  p_user_id UUID,
  p_event_key TEXT,
  p_source_type TEXT,
  p_source_id UUID,
  p_xp INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_inserted INTEGER;
BEGIN
  INSERT INTO public.experience_events(user_id, event_key, source_type, source_id, xp)
  VALUES (p_user_id, p_event_key, p_source_type, p_source_id, p_xp)
  ON CONFLICT (user_id, event_key, source_type, source_id) DO NOTHING;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 0 THEN RETURN; END IF;

  INSERT INTO public.user_experience(user_id, lifetime_xp, level, last_meaningful_action_at)
  VALUES (p_user_id, p_xp, floor(sqrt(p_xp::numeric / 100))::integer + 1, now())
  ON CONFLICT (user_id) DO UPDATE SET
    lifetime_xp = public.user_experience.lifetime_xp + EXCLUDED.lifetime_xp,
    level = floor(sqrt((public.user_experience.lifetime_xp + EXCLUDED.lifetime_xp)::numeric / 100))::integer + 1,
    last_meaningful_action_at = now(),
    updated_at = now();
END;
$$;

-- XP is awarded only by trusted database triggers, never by a client RPC.
REVOKE ALL ON FUNCTION public.record_meaningful_experience(UUID, TEXT, TEXT, UUID, INTEGER) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.award_companion_experience()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_TABLE_NAME = 'daily_five_attempts'
     AND NEW.submitted_at IS NOT NULL
     AND (TG_OP = 'INSERT' OR OLD.submitted_at IS NULL) THEN
    PERFORM public.record_meaningful_experience(NEW.user_id, 'daily_five_submitted', TG_TABLE_NAME, NEW.id, 25);
  ELSIF TG_TABLE_NAME = 'task_completions'
     AND NEW.completed
     AND (TG_OP = 'INSERT' OR NOT COALESCE(OLD.completed, false)) THEN
    PERFORM public.record_meaningful_experience(NEW.user_id, 'quest_completed', TG_TABLE_NAME, NEW.id, 20);
  ELSIF TG_TABLE_NAME = 'mock_exam_results'
     AND NEW.reflected_at IS NOT NULL
     AND (TG_OP = 'INSERT' OR OLD.reflected_at IS NULL) THEN
    PERFORM public.record_meaningful_experience(NEW.student_id, 'assessment_reflected', TG_TABLE_NAME, NEW.id, 40);
  END IF;
  RETURN NEW;
END;
$$;

-- Reflection evidence must exist before its XP trigger is declared.
ALTER TABLE public.mock_exam_results
  ADD COLUMN IF NOT EXISTS reflection TEXT,
  ADD COLUMN IF NOT EXISTS reflected_at TIMESTAMPTZ;

DROP TRIGGER IF EXISTS award_daily_five_experience ON public.daily_five_attempts;
CREATE TRIGGER award_daily_five_experience
AFTER INSERT OR UPDATE OF submitted_at ON public.daily_five_attempts
FOR EACH ROW EXECUTE FUNCTION public.award_companion_experience();
DROP TRIGGER IF EXISTS award_quest_experience ON public.task_completions;
CREATE TRIGGER award_quest_experience
AFTER INSERT OR UPDATE OF completed ON public.task_completions
FOR EACH ROW EXECUTE FUNCTION public.award_companion_experience();
DROP TRIGGER IF EXISTS award_reflection_experience ON public.mock_exam_results;
CREATE TRIGGER award_reflection_experience
AFTER INSERT OR UPDATE OF reflected_at ON public.mock_exam_results
FOR EACH ROW EXECUTE FUNCTION public.award_companion_experience();

ALTER TABLE public.user_experience ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_journeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_missions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_experience_read_own" ON public.user_experience
  FOR SELECT TO authenticated USING (user_id = public.current_user_id());
CREATE POLICY "experience_events_read_own" ON public.experience_events
  FOR SELECT TO authenticated USING (user_id = public.current_user_id());
CREATE POLICY "user_mastery_read_own" ON public.user_mastery
  FOR SELECT TO authenticated USING (user_id = public.current_user_id());
CREATE POLICY "weekly_journeys_own" ON public.weekly_journeys
  FOR SELECT TO authenticated USING (user_id = public.current_user_id());
CREATE POLICY "journey_missions_own" ON public.journey_missions
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.weekly_journeys j
      WHERE j.id = journey_id AND j.user_id = public.current_user_id()
    )
  );
CREATE POLICY "journey_missions_update_own" ON public.journey_missions
  FOR UPDATE TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.weekly_journeys j
      WHERE j.id = journey_id AND j.user_id = public.current_user_id()
    )
  );

-- ── Structured mentorship and support ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.mentorship_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mentor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  topic TEXT NOT NULL CHECK (char_length(trim(topic)) BETWEEN 3 AND 100),
  context TEXT NOT NULL CHECK (char_length(trim(context)) BETWEEN 10 AND 1500),
  preferred_response TEXT NOT NULL DEFAULT 'async'
    CHECK (preferred_response IN ('async', 'call', 'in_person')),
  status TEXT NOT NULL DEFAULT 'requested'
    CHECK (status IN ('requested', 'accepted', 'answered', 'declined', 'redirected', 'cancelled')),
  resolution_note TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.support_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  case_type TEXT NOT NULL CHECK (case_type IN (
    'student_request', 'evidence_gap', 'assessment_support',
    'academic_continuity', 'identity', 'privacy', 'technical'
  )),
  title TEXT NOT NULL,
  context TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'requested'
    CHECK (status IN ('suggested', 'requested', 'active', 'review_due', 'resolved', 'closed')),
  owner_id UUID REFERENCES public.users(id),
  goal TEXT,
  action_plan JSONB NOT NULL DEFAULT '[]',
  review_at TIMESTAMPTZ,
  resolution TEXT,
  privacy_level TEXT NOT NULL DEFAULT 'faculty_student'
    CHECK (privacy_level IN ('faculty_student', 'governance')),
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.mentorship_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mentorship_participants_read" ON public.mentorship_requests
  FOR SELECT TO authenticated USING (
    requester_id = public.current_user_id()
    OR mentor_id = public.current_user_id()
    OR public.is_faculty_or_hod(public.current_user_id())
  );
CREATE POLICY "mentorship_requester_insert" ON public.mentorship_requests
  FOR INSERT TO authenticated WITH CHECK (requester_id = public.current_user_id());
CREATE POLICY "mentorship_participants_update" ON public.mentorship_requests
  FOR UPDATE TO authenticated USING (
    requester_id = public.current_user_id()
    OR mentor_id = public.current_user_id()
    OR public.is_faculty_or_hod(public.current_user_id())
  );

CREATE POLICY "support_cases_student_read" ON public.support_cases
  FOR SELECT TO authenticated USING (student_id = public.current_user_id());
CREATE POLICY "support_cases_student_request" ON public.support_cases
  FOR INSERT TO authenticated WITH CHECK (
    student_id = public.current_user_id()
    AND created_by = public.current_user_id()
    AND case_type IN ('student_request', 'identity', 'privacy', 'technical')
  );
CREATE POLICY "support_cases_faculty_read" ON public.support_cases
  FOR SELECT TO authenticated USING (public.is_faculty_or_hod(public.current_user_id()));
CREATE POLICY "support_cases_faculty_manage" ON public.support_cases
  FOR ALL TO authenticated
  USING (public.is_faculty_or_hod(public.current_user_id()))
  WITH CHECK (public.is_faculty_or_hod(public.current_user_id()));

-- ── Existing feature alignment ─────────────────────────────────────────────

ALTER TABLE public.mock_exam_results
  ADD COLUMN IF NOT EXISTS reflection TEXT,
  ADD COLUMN IF NOT EXISTS reflected_at TIMESTAMPTZ;

ALTER TABLE public.fyp_projects
  ADD COLUMN IF NOT EXISTS domain TEXT,
  ADD COLUMN IF NOT EXISTS problem_statement TEXT,
  ADD COLUMN IF NOT EXISTS architecture_summary TEXT,
  ADD COLUMN IF NOT EXISTS demonstration_url TEXT,
  ADD COLUMN IF NOT EXISTS evidence_confidence TEXT NOT NULL DEFAULT 'low'
    CHECK (evidence_confidence IN ('low', 'medium', 'high'));

ALTER TABLE public.collaboration_posts
  DROP CONSTRAINT IF EXISTS collaboration_posts_post_type_check;
ALTER TABLE public.collaboration_posts
  ADD CONSTRAINT collaboration_posts_post_type_check CHECK (post_type IN (
    'project', 'mentorship', 'learning_event', 'career_information',
    'unofficial_opportunity', 'job'
  ));
ALTER TABLE public.collaboration_posts
  ADD COLUMN IF NOT EXISTS disclaimer TEXT NOT NULL DEFAULT
    'Community information only. This is not an official PSG Tech placement drive. Use NEO PAT for official placement operations.';

ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_notification_type_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_notification_type_check CHECK (notification_type IN (
    'motivation', 'reminder', 'alert', 'announcement', 'birthday',
    'action_required', 'progress', 'community', 'system'
  ));
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS target_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS action_path TEXT,
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'announcement'
    CHECK (category IN ('action_required', 'scheduled_reminder', 'progress', 'community', 'announcement', 'system'));

DROP POLICY IF EXISTS "notifications_read_active" ON public.notifications;
CREATE POLICY "notifications_read_scoped" ON public.notifications
  FOR SELECT TO authenticated USING (
    is_active
    AND (valid_until IS NULL OR valid_until > now())
    AND (
      target_audience = 'all'
      OR target_user_id = public.current_user_id()
      OR (target_audience = 'user' AND created_by = public.current_user_id())
      OR (batch_id IS NOT NULL AND batch_id = public.get_user_batch_id(public.current_user_id()))
      OR (target_audience = 'students' AND lower((SELECT role_label FROM public.users WHERE id = public.current_user_id())) = 'student')
      OR (target_audience = 'placement_reps' AND public.is_placement_rep(public.current_user_id()))
      OR (target_audience = 'coordinators' AND public.is_coordinator(public.current_user_id()))
      OR (target_audience = 'team_leaders' AND public.is_team_leader(public.current_user_id()))
    )
  );

-- Rebind legacy storage tables to companion capabilities. Table names stay
-- stable for a safe rollout, while all new authorization uses the new model.
DROP POLICY IF EXISTS "daily_tasks_insert" ON public.daily_tasks;
DROP POLICY IF EXISTS "daily_tasks_update" ON public.daily_tasks;
CREATE POLICY "daily_tasks_insert" ON public.daily_tasks FOR INSERT TO authenticated
  WITH CHECK (
    public.user_has_permission(public.current_user_id(), 'publish_quests')
    AND (batch_id IS NULL OR batch_id = public.get_user_batch_id(public.current_user_id()))
  );
CREATE POLICY "daily_tasks_update" ON public.daily_tasks FOR UPDATE TO authenticated
  USING (
    public.user_has_permission(public.current_user_id(), 'publish_quests')
    AND (batch_id IS NULL OR batch_id = public.get_user_batch_id(public.current_user_id()))
  )
  WITH CHECK (
    public.user_has_permission(public.current_user_id(), 'publish_quests')
    AND (batch_id IS NULL OR batch_id = public.get_user_batch_id(public.current_user_id()))
  );

DROP POLICY IF EXISTS "project_task_bank_write" ON public.project_task_bank;
CREATE POLICY "project_task_bank_write" ON public.project_task_bank FOR ALL TO authenticated
  USING (public.user_has_permission(public.current_user_id(), 'publish_quests'))
  WITH CHECK (public.user_has_permission(public.current_user_id(), 'publish_quests'));
DROP POLICY IF EXISTS "apti_dsa_daily_bank_write" ON public.apti_dsa_daily_bank;
CREATE POLICY "apti_dsa_daily_bank_write" ON public.apti_dsa_daily_bank FOR ALL TO authenticated
  USING (public.user_has_permission(public.current_user_id(), 'publish_quests'))
  WITH CHECK (public.user_has_permission(public.current_user_id(), 'publish_quests'));
DROP POLICY IF EXISTS "qbank_write" ON public.question_bank;
CREATE POLICY "qbank_write" ON public.question_bank FOR ALL TO authenticated
  USING (public.user_has_permission(public.current_user_id(), 'publish_quests'))
  WITH CHECK (public.user_has_permission(public.current_user_id(), 'publish_quests'));

DROP POLICY IF EXISTS "placement_sessions_write" ON public.placement_sessions;
CREATE POLICY "placement_sessions_write" ON public.placement_sessions FOR ALL TO authenticated
  USING (
    public.user_has_permission(public.current_user_id(), 'schedule_preparation_sessions')
    AND batch_id = public.get_user_batch_id(public.current_user_id())
  )
  WITH CHECK (
    public.user_has_permission(public.current_user_id(), 'schedule_preparation_sessions')
    AND batch_id = public.get_user_batch_id(public.current_user_id())
  );

DROP POLICY IF EXISTS "placement_attendance_write" ON public.placement_attendance;
CREATE POLICY "placement_attendance_write" ON public.placement_attendance FOR ALL TO authenticated
  USING (
    public.user_has_permission(public.current_user_id(), 'mark_preparation_participation')
    AND EXISTS (
      SELECT 1
      FROM public.placement_sessions session
      JOIN public.users member ON member.id = placement_attendance.user_id
      JOIN public.users actor ON actor.id = public.current_user_id()
      WHERE session.id = placement_attendance.session_id
        AND session.batch_id = actor.batch_id
        AND member.batch_id = actor.batch_id
        AND (
          public.is_faculty_or_hod(actor.id)
          OR public.is_placement_rep(actor.id)
          OR public.is_coordinator(actor.id)
          OR (public.is_team_leader(actor.id) AND member.team_uuid = actor.team_uuid)
        )
    )
  )
  WITH CHECK (
    public.user_has_permission(public.current_user_id(), 'mark_preparation_participation')
    AND marked_by = public.current_user_id()
    AND EXISTS (
      SELECT 1
      FROM public.placement_sessions session
      JOIN public.users member ON member.id = placement_attendance.user_id
      JOIN public.users actor ON actor.id = public.current_user_id()
      WHERE session.id = placement_attendance.session_id
        AND session.batch_id = actor.batch_id
        AND member.batch_id = actor.batch_id
        AND (
          public.is_faculty_or_hod(actor.id)
          OR public.is_placement_rep(actor.id)
          OR public.is_coordinator(actor.id)
          OR (public.is_team_leader(actor.id) AND member.team_uuid = actor.team_uuid)
        )
    )
  );

DROP POLICY IF EXISTS "announcements_manage" ON public.announcements;
CREATE POLICY "announcements_manage" ON public.announcements FOR ALL TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.user_has_permission(public.current_user_id(), 'publish_announcements')
  )
  WITH CHECK (
    public.is_faculty_or_hod(public.current_user_id())
    OR (
      public.user_has_permission(public.current_user_id(), 'publish_announcements')
      AND (batch_id IS NULL OR batch_id = public.get_user_batch_id(public.current_user_id()))
    )
  );

DROP POLICY IF EXISTS "notifications_manage" ON public.notifications;
CREATE POLICY "notifications_manage" ON public.notifications FOR ALL TO authenticated
  USING (
    public.is_faculty_or_hod(public.current_user_id())
    OR public.user_has_permission(public.current_user_id(), 'publish_announcements')
  )
  WITH CHECK (
    public.is_faculty_or_hod(public.current_user_id())
    OR (
      public.user_has_permission(public.current_user_id(), 'publish_announcements')
      AND (batch_id IS NULL OR batch_id = public.get_user_batch_id(public.current_user_id()))
    )
  );

DROP POLICY IF EXISTS "users_update_placement_rep" ON public.users;
CREATE POLICY "users_update_batch_operator" ON public.users FOR UPDATE TO authenticated
  USING (
    public.user_has_permission(public.current_user_id(), 'manage_members')
    AND batch_id = public.get_user_batch_id(public.current_user_id())
    AND lower(COALESCE(role_label, '')) = 'student'
  )
  WITH CHECK (
    batch_id = public.get_user_batch_id(public.current_user_id())
    AND lower(COALESCE(role_label, '')) = 'student'
  );

-- New table grants. RLS remains authoritative.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.preparation_tracks TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.interview_patterns TO authenticated;
GRANT SELECT ON public.readiness_dimension_scores TO authenticated;
GRANT SELECT ON public.user_experience, public.experience_events, public.user_mastery TO authenticated;
GRANT SELECT ON public.weekly_journeys TO authenticated;
GRANT SELECT, UPDATE ON public.journey_missions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.mentorship_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.support_cases TO authenticated;

COMMENT ON TABLE public.companies IS
  'Legacy historical drive data. Official current placement operations belong in NEO PAT; do not use for new PSGMX flows.';
COMMENT ON TABLE public.placement_log_entries IS
  'Legacy source awaiting migration to interview_patterns. New PSGMX submissions must use interview_patterns.';
