-- ============================================================
-- PSGMX — 04_triggers.sql
-- Event-Driven Database Automation & Triggers
-- ============================================================

-- ── 1. Live Readiness Dimensions Calculation ─────────────────
CREATE OR REPLACE FUNCTION public.refresh_readiness_dimensions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_components JSONB := NEW.components_json;
  v_computed TIMESTAMPTZ := NEW.computed_at;
  v_user UUID := NEW.user_id;

  v_comm_count INT := 0;
  v_comm_score NUMERIC := 0;
  v_comm_fresh TIMESTAMPTZ;

  v_portfolio_count INT := 0;
  v_portfolio_score NUMERIC := 0;
  v_portfolio_fresh TIMESTAMPTZ;
  v_has_github BOOLEAN := FALSE;

  v_apt_score NUMERIC := 0;
  v_code_score NUMERIC := 0;
  v_core_score NUMERIC := 0;
  v_assess_score NUMERIC := 0;
BEGIN
  -- 1. Communication evaluations
  SELECT
    COUNT(*),
    COALESCE(AVG(
      CASE
        WHEN faculty_score IS NOT NULL THEN (faculty_score * 10.0)
        WHEN ai_scores_json IS NOT NULL THEN (
          COALESCE((ai_scores_json->>'clarity_score')::numeric, 5) * 3.33 +
          COALESCE((ai_scores_json->>'structure_score')::numeric, 5) * 3.33 +
          COALESCE((ai_scores_json->>'relevance_score')::numeric, 5) * 3.34
        )
        ELSE 60.0
      END
    ), 0),
    MAX(created_at)
  INTO v_comm_count, v_comm_score, v_comm_fresh
  FROM public.communication_attempts
  WHERE student_id = v_user AND is_active = TRUE;

  -- 2. Portfolio & verified code quests
  SELECT (github_url IS NOT NULL AND length(trim(github_url)) > 0)
  INTO v_has_github FROM public.users WHERE id = v_user;

  SELECT COUNT(*), MAX(submitted_at)
  INTO v_portfolio_count, v_portfolio_fresh
  FROM public.code_submissions
  WHERE student_id = v_user AND is_verified_complete = TRUE;

  v_portfolio_score := CASE
    WHEN v_has_github AND v_portfolio_count > 0 THEN LEAST(60 + (v_portfolio_count * 10), 100)
    WHEN v_has_github THEN 50
    WHEN v_portfolio_count > 0 THEN LEAST(v_portfolio_count * 15, 80)
    ELSE 0
  END;
  IF v_has_github THEN
    v_portfolio_count := v_portfolio_count + 1;
    v_portfolio_fresh := COALESCE(v_portfolio_fresh, v_computed);
  END IF;

  -- 3. Measured component scores
  v_apt_score := (COALESCE((v_components->>'daily_five_accuracy_pct')::numeric, 0) * .60 +
                  COALESCE((v_components->>'daily_five_adherence_pct')::numeric, 0) * .40);

  v_code_score := COALESCE((v_components->>'leetcode_momentum_percentile')::numeric, 0);
  v_core_score := COALESCE((v_components->>'task_completion_rate_pct')::numeric, 0);
  v_assess_score := COALESCE((v_components->>'daily_five_accuracy_pct')::numeric, 0);

  INSERT INTO public.readiness_dimension_scores(
    user_id, dimension, score, confidence, evidence_count,
    evidence_fresh_at, algorithm_version, evidence, computed_at
  )
  SELECT NEW.user_id, dimension, score, confidence, evidence_count,
    CASE WHEN evidence_count > 0 THEN COALESCE(evidence_fresh_at, v_computed) ELSE NULL END,
    'v2', evidence, v_computed
  FROM (VALUES
    ('aptitude_reasoning',
      ROUND(v_apt_score, 2),
      CASE WHEN v_apt_score > 0 THEN 'medium' ELSE 'low' END,
      CASE WHEN v_apt_score > 0 THEN 2 ELSE 0 END,
      v_computed,
      CASE WHEN v_apt_score > 0 THEN jsonb_build_array('daily_five_accuracy_pct', 'daily_five_adherence_pct') ELSE '[]'::jsonb END),

    ('coding_problem_solving',
      ROUND(v_code_score, 2),
      CASE WHEN v_code_score > 0 THEN 'medium' ELSE 'low' END,
      CASE WHEN v_code_score > 0 THEN 1 ELSE 0 END,
      v_computed,
      CASE WHEN v_code_score > 0 THEN jsonb_build_array('leetcode_momentum_percentile') ELSE '[]'::jsonb END),

    ('core_computer_science',
      ROUND(v_core_score, 2),
      CASE WHEN v_core_score > 0 THEN 'medium' ELSE 'low' END,
      CASE WHEN v_core_score > 0 THEN 1 ELSE 0 END,
      v_computed,
      CASE WHEN v_core_score > 0 THEN jsonb_build_array('task_completion_rate_pct') ELSE '[]'::jsonb END),

    ('assessment_performance',
      ROUND(v_assess_score, 2),
      CASE WHEN v_assess_score > 0 THEN 'medium' ELSE 'low' END,
      CASE WHEN v_assess_score > 0 THEN 1 ELSE 0 END,
      v_computed,
      CASE WHEN v_assess_score > 0 THEN jsonb_build_array('daily_five_accuracy_pct') ELSE '[]'::jsonb END),

    ('communication_interview',
      ROUND(v_comm_score, 2),
      CASE WHEN v_comm_count >= 3 THEN 'high' WHEN v_comm_count > 0 THEN 'medium' ELSE 'low' END,
      v_comm_count,
      v_comm_fresh,
      CASE WHEN v_comm_count > 0 THEN jsonb_build_array('communication_score') ELSE '[]'::jsonb END),

    ('portfolio_project',
      ROUND(v_portfolio_score, 2),
      CASE WHEN v_portfolio_count >= 2 THEN 'medium' WHEN v_portfolio_count > 0 THEN 'low' ELSE 'low' END,
      v_portfolio_count,
      v_portfolio_fresh,
      CASE
        WHEN v_portfolio_count > 0 AND v_has_github THEN jsonb_build_array('portfolio_score', 'verified_quests')
        WHEN v_portfolio_count > 0 THEN jsonb_build_array('portfolio_score')
        ELSE '[]'::jsonb
      END)
  ) AS dimensions(dimension, score, confidence, evidence_count, evidence_fresh_at, evidence)
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

-- ── 2. User Auto-Provisioning Trigger ────────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.auto_provision_profile();

-- ── 3. Session Lock Enforcement Trigger ──────────────────────
CREATE OR REPLACE FUNCTION public.check_session_lock()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.session_locks WHERE user_id = NEW.user_id) THEN
    RAISE EXCEPTION 'Account is temporarily locked due to simultaneous active sessions.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_session_lock ON public.active_sessions;
CREATE TRIGGER enforce_session_lock
BEFORE INSERT OR UPDATE ON public.active_sessions
FOR EACH ROW EXECUTE FUNCTION public.check_session_lock();

-- ── 4. Knowledge Brain Search Vector Automation ──────────────
CREATE OR REPLACE FUNCTION public.update_knowledge_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.summary, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.company_name, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(substring(NEW.content, 1, 2000), '')), 'D');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_kba_search_vector ON public.knowledge_brain_articles;
CREATE TRIGGER trg_kba_search_vector
BEFORE INSERT OR UPDATE OF title, summary, content, tags, company_name ON public.knowledge_brain_articles
FOR EACH ROW EXECUTE FUNCTION public.update_knowledge_search_vector();

