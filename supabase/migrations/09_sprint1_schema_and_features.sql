-- ============================================================
-- PSGMX — 09_sprint1_schema_and_features.sql
-- Sprint 1: kill hardcoded dashboard data (plan Section 7) + Placement Rep
-- web panel (Section 8) + HOD/Faculty consolidation (Section 10) + a
-- correct birthday-notification path (Section 6).
--
-- Written and verified against the LIVE database via direct introspection
-- (see 08_security_fixes_sprint0.sql header for how/why). Run this AFTER
-- 08_security_fixes_sprint0.sql.
--
-- Confirmed live facts this migration depends on:
--   - Role model: users.role_label TEXT ('Student','Faculty','Alumni', and
--     presumably 'HOD'), NOT role/app_role enums.
--   - teams, placement_sessions, companies, announcements, readiness_scores,
--     daily_five_streaks, leetcode_stats, question_bank, notifications,
--     notification_reads all already exist — this migration does not
--     recreate them.
--   - fyp_projects, knowledge_brain_articles, lineage_map, ai_query_logs,
--     mock_exams, mock_exam_results, readiness_score_history do NOT exist —
--     built fresh here (per your "treat as net-new builds" decision).
--   - notifications.notification_type has a CHECK constraint that currently
--     REJECTS 'birthday' (verified with a live test insert — rolled back
--     automatically since Postgres rejects the whole row on violation, nothing
--     to clean up). Inferred allowed set from app code's dbType mapping:
--     'announcement' | 'motivation' | 'reminder' | 'alert'.
--   - The mobile app's existing birthday flow (notification_service.dart
--     checkAndSendBirthdayNotifications/sendBirthdayNotification) is
--     client-triggered (only fires if someone happens to open the app that
--     day), downloads every user's DOB to the client to check, and sends a
--     public THIRD-PERSON broadcast ("Let's wish X a happy birthday!") to
--     everyone — never a personal first-person message to the birthday
--     person themselves, and does not respect any privacy toggle. This
--     migration adds the correct personal-notification path (Section 6.3
--     copy) as a SECURITY DEFINER function you can run manually or on a
--     pg_cron schedule; it does not delete the existing client-side
--     broadcast (see accompanying Dart change, which is left as an
--     optional public "today's birthdays" chip gated by show_birthday_publicly).
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- STEP 1 — users: add the one column that's genuinely missing.
-- `dob DATE` already exists live — no need to add date_of_birth.
-- `is_hod` is NOT added: per plan D1 ("keep the DB role as-is, just merge
-- the UI") and your role_label decision, HOD is just role_label = 'HOD'.
-- ──────────────────────────────────────────────────────────────

ALTER TABLE users ADD COLUMN IF NOT EXISTS show_birthday_publicly BOOLEAN NOT NULL DEFAULT false;

-- Alumni mentorship-availability toggle (Section 7.3 "Mentorship Status"
-- widget + D4/lineage flows). Doesn't exist live either.
ALTER TABLE users ADD COLUMN IF NOT EXISTS mentorship_open BOOLEAN NOT NULL DEFAULT false;

-- `onboarding_complete` is referenced by BOTH the mobile app
-- (app_user.dart: onboardingComplete) and several web routes
-- (api/auth/login, api/auth/verify, api/auth/first-login,
-- api/hod/pending-alumni) but does not exist live — meaning every login
-- currently falls through to `!onboarding_complete` as `!undefined` =
-- true and redirects to /onboarding UNCONDITIONALLY, for every user,
-- forever. This is the single most impactful fix in this migration.
--
-- Backfill: every user who already exists today predates this column and
-- is presumably already using the app (Daily Five, bunker screen, etc.) —
-- grandfather them all in as already-onboarded so this fix doesn't force
-- ~124 active students back through onboarding. Only genuinely new
-- signups from this point on default to false and go through the real flow.
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_complete BOOLEAN NOT NULL DEFAULT false;
UPDATE users SET onboarding_complete = true WHERE onboarding_complete = false;

-- ──────────────────────────────────────────────────────────────
-- STEP 2 — notifications: allow 'birthday' as a notification_type.
-- ──────────────────────────────────────────────────────────────

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_notification_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_notification_type_check
  CHECK (notification_type IN ('announcement', 'motivation', 'reminder', 'alert', 'birthday'));

-- ──────────────────────────────────────────────────────────────
-- STEP 3 — send_birthday_notifications(): personal notification, matching
-- Section 6.3's exact copy. Callable manually for testing, or scheduled
-- (see the pg_cron block at the bottom of this file).
--
-- Convention followed (matches the app's existing "personal notification"
-- pattern in notification_service.dart:showNotification — target_audience
-- = 'user' with created_by repurposed as "who this belongs to", since the
-- table has no dedicated target_user_id column):
--   target_audience = 'user', created_by = <birthday person's own id>
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION send_birthday_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_user IN
    SELECT id, name
    FROM users
    WHERE dob IS NOT NULL
      AND EXTRACT(MONTH FROM dob) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND EXTRACT(DAY FROM dob) = EXTRACT(DAY FROM CURRENT_DATE)
  LOOP
    -- Idempotency: skip if a personal birthday notification already exists
    -- for this user today.
    IF EXISTS (
      SELECT 1 FROM notifications
      WHERE created_by = v_user.id
        AND notification_type = 'birthday'
        AND target_audience = 'user'
        AND generated_at::date = CURRENT_DATE
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO notifications (
      title, message, notification_type, tone, target_audience,
      created_by, is_active, generated_at, valid_until
    ) VALUES (
      'Happy Birthday, ' || split_part(v_user.name, ' ', 1) || '! 🎂',
      E'Hope your day''s a good one. On behalf of the whole PSGMX community — faculty, seniors, and juniors — we wish you a wonderful year ahead, both in your placement journey and beyond.\n— With warm regards, PSG MCA Department',
      'birthday',
      'friendly',
      'user',
      v_user.id,
      true,
      now(),
      (CURRENT_DATE + INTERVAL '1 day')::timestamptz
    );

    -- Optional public shoutout chip, only if the user opted in.
    IF EXISTS (SELECT 1 FROM users WHERE id = v_user.id AND show_birthday_publicly = true) THEN
      INSERT INTO notifications (
        title, message, notification_type, tone, target_audience,
        created_by, is_active, generated_at, valid_until
      ) VALUES (
        '🎉 Today''s birthday',
        split_part(v_user.name, ' ', 1) || ' is celebrating a birthday today!',
        'birthday',
        'friendly',
        'all',
        v_user.id,
        true,
        now(),
        (CURRENT_DATE + INTERVAL '1 day')::timestamptz
      );
    END IF;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION send_birthday_notifications() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION send_birthday_notifications() TO service_role;

-- ── MANUAL FOLLOW-UP ──
-- To schedule this daily at 7:00 AM IST (01:30 UTC), run (requires the
-- pg_cron extension — enable via Database → Extensions in the dashboard,
-- or `CREATE EXTENSION IF NOT EXISTS pg_cron;` if your plan allows it):
--   SELECT cron.schedule(
--     'send-birthday-notifications',
--     '30 1 * * *',
--     $$SELECT send_birthday_notifications();$$
--   );
-- To test manually right now: SELECT send_birthday_notifications();
-- (returns the count of birthday notifications sent)

-- ──────────────────────────────────────────────────────────────
-- STEP 4 — knowledge_brain_articles (Section 7.1/7.2/7.3, net-new).
--
-- Shape corrected mid-migration: apps/web/lib/ai/rag.ts,
-- apps/web/app/api/knowledge/search/route.ts, and the super-admin pages
-- were ALL already written against a specific richer shape (title,
-- summary, content, tags[], company_name, approval_status,
-- search_vector) plus a companion `knowledge_embeddings` table for
-- pgvector RAG search — none of which exist live, so the AI Senior
-- feature and knowledge search are currently non-functional. Building to
-- match what that existing code already expects, rather than inventing
-- a third incompatible shape.
-- ──────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS vector;

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
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION update_knowledge_search_vector()
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

DROP TRIGGER IF EXISTS trig_knowledge_search_vector ON knowledge_brain_articles;
CREATE TRIGGER trig_knowledge_search_vector
  BEFORE INSERT OR UPDATE OF title, summary, content, tags, company_name
  ON knowledge_brain_articles
  FOR EACH ROW EXECUTE FUNCTION update_knowledge_search_vector();

CREATE INDEX IF NOT EXISTS knowledge_brain_articles_search_idx
  ON knowledge_brain_articles USING gin(search_vector);

CREATE TABLE IF NOT EXISTS knowledge_embeddings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id  UUID NOT NULL REFERENCES knowledge_brain_articles(id) ON DELETE CASCADE,
  chunk_text  TEXT NOT NULL,
  chunk_index INTEGER NOT NULL DEFAULT 0,
  embedding   vector(384),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS knowledge_embeddings_article_idx ON knowledge_embeddings(article_id);

-- RPC referenced by apps/web/lib/ai/rag.ts (matches supabase/migrations/06_semantic_search.sql).
CREATE OR REPLACE FUNCTION knowledge_semantic_search(
  query_embedding  vector,
  match_threshold  FLOAT DEFAULT 0.5,
  match_count      INT   DEFAULT 5
)
RETURNS TABLE (
  id          UUID,
  article_id  UUID,
  chunk_text  TEXT,
  title       TEXT,
  similarity  FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ke.id,
    ke.article_id,
    ke.chunk_text,
    kba.title,
    1 - (ke.embedding <=> query_embedding) AS similarity
  FROM knowledge_embeddings ke
  JOIN knowledge_brain_articles kba
    ON kba.id = ke.article_id
   AND kba.approval_status = 'approved'
  WHERE ke.embedding IS NOT NULL
    AND (1 - (ke.embedding <=> query_embedding)) >= match_threshold
  ORDER BY ke.embedding <=> query_embedding
  LIMIT match_count;
$$;

ALTER TABLE knowledge_brain_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY knowledge_brain_articles_select_approved ON knowledge_brain_articles
  FOR SELECT TO authenticated
  USING (approval_status = 'approved');

CREATE POLICY knowledge_brain_articles_select_own ON knowledge_brain_articles
  FOR SELECT TO authenticated
  USING (author_id = auth.uid());

CREATE POLICY knowledge_brain_articles_select_faculty_hod ON knowledge_brain_articles
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD'))
  );

CREATE POLICY knowledge_brain_articles_insert_own ON knowledge_brain_articles
  FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid());

-- Only faculty/HOD may change approval_status — students may not
-- update their own submission's review state.
CREATE POLICY knowledge_brain_articles_update_faculty_hod ON knowledge_brain_articles
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- Embeddings are read via the SECURITY DEFINER RPC above, never queried
-- directly by the client — no SELECT policy for authenticated. Only
-- faculty/HOD (via the knowledge-brain review flow) or service_role
-- write chunks/embeddings.
CREATE POLICY knowledge_embeddings_write_faculty_hod ON knowledge_embeddings
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- ──────────────────────────────────────────────────────────────
-- STEP 5 — ai_query_logs (Section 7.2 "AI Senior top queries" widget).
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ai_query_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  query_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE ai_query_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY ai_query_logs_select_faculty_hod ON ai_query_logs
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- No client INSERT policy: the /api/ai-senior route logs via service_role.

-- ──────────────────────────────────────────────────────────────
-- STEP 6 — lineage_map (Section 7.1 "Your Senior" widget).
-- Simple 1:1 junior→senior assignment. Senior is typically an alumni user;
-- senior_user_id is nullable so a mapping can exist before a specific
-- senior is assigned.
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS lineage_map (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  senior_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  senior_quote   TEXT,
  assigned_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by    UUID REFERENCES users(id)
);

ALTER TABLE lineage_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineage_map_select_own ON lineage_map
  FOR SELECT TO authenticated
  USING (student_id = auth.uid() OR senior_user_id = auth.uid());

CREATE POLICY lineage_map_select_faculty_hod ON lineage_map
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

CREATE POLICY lineage_map_write_faculty_hod ON lineage_map
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- ──────────────────────────────────────────────────────────────
-- STEP 7 — fyp_projects / fyp_progress_logs / fyp_feedback.
-- Built fresh (per your decision), with correct RLS from day one — no
-- "auth.uid() IS NOT NULL" open-read mistake this time.
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS fyp_projects (
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

CREATE TABLE IF NOT EXISTS fyp_progress_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  note       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fyp_feedback (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
  faculty_id UUID NOT NULL REFERENCES users(id),
  comment    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fyp_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY fyp_projects_select_own ON fyp_projects
  FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY fyp_projects_select_faculty_hod ON fyp_projects
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));
CREATE POLICY fyp_projects_write_own ON fyp_projects
  FOR INSERT TO authenticated WITH CHECK (student_id = auth.uid());
CREATE POLICY fyp_projects_update_own ON fyp_projects
  FOR UPDATE TO authenticated USING (student_id = auth.uid()) WITH CHECK (student_id = auth.uid());
CREATE POLICY fyp_projects_update_faculty_hod ON fyp_projects
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

CREATE POLICY fyp_progress_logs_select_own ON fyp_progress_logs
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM fyp_projects p WHERE p.id = fyp_progress_logs.project_id AND p.student_id = auth.uid()));
CREATE POLICY fyp_progress_logs_select_faculty_hod ON fyp_progress_logs
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));
CREATE POLICY fyp_progress_logs_insert_own ON fyp_progress_logs
  FOR INSERT TO authenticated WITH CHECK (student_id = auth.uid());

CREATE POLICY fyp_feedback_select_own ON fyp_feedback
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM fyp_projects p WHERE p.id = fyp_feedback.project_id AND p.student_id = auth.uid()));
CREATE POLICY fyp_feedback_select_faculty_hod ON fyp_feedback
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));
CREATE POLICY fyp_feedback_insert_faculty_hod ON fyp_feedback
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- ──────────────────────────────────────────────────────────────
-- STEP 8 — mock_exams / mock_exam_questions / mock_exam_results
-- (Section 4.1 + 7.1).
--
-- Shape corrected mid-migration: apps/web/app/exam/[examId]/page.tsx
-- ALREADY implements a fairly complete anti-cheat exam UI — per-student
-- deterministic shuffle, camera + fullscreen proctoring, a proctoring
-- flags array, and submission through a dedicated API route
-- (/api/student/exam/submit) rather than a direct client insert — it was
-- just missing the tables underneath it. Building `mock_exam_questions`
-- (not the `question_ids` array I first sketched) to match what that page
-- already queries, plus the `submit_exam_server_side` RPC it already calls.
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS mock_exams (
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
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

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
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (exam_id, student_id)
);

ALTER TABLE mock_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_exam_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY mock_exams_select_all ON mock_exams
  FOR SELECT TO authenticated USING (true);
CREATE POLICY mock_exams_write_faculty_hod ON mock_exams
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- Students may read question text/options (needed to render the exam),
-- but NEVER correct_option — enforced with the same column-level REVOKE
-- pattern used for ecampus_password (S1), directly satisfying Section
-- 4.2's "answer key never shipped to client pre-submission" audit item.
-- Faculty/HOD (who set the questions) can read everything including
-- correct_option; grading itself happens in the SECURITY DEFINER RPC
-- below, which reads correct_option as the function owner regardless of
-- the column-level REVOKE (that only restricts client roles).
CREATE POLICY mock_exam_questions_select_all ON mock_exam_questions
  FOR SELECT TO authenticated USING (true);
CREATE POLICY mock_exam_questions_write_faculty_hod ON mock_exam_questions
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- Per plan Section 4.5: students get SELECT on their own row only, and
-- ZERO direct INSERT/UPDATE — grading and session lifecycle are RPC-only
-- (start_mock_exam / submit_exam_server_side below). No INSERT/UPDATE
-- policy for `authenticated` is added here on purpose.
CREATE POLICY mock_exam_results_select_own ON mock_exam_results
  FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY mock_exam_results_select_faculty_hod ON mock_exam_results
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));

-- ── Faculty/HOD may see correct_option; students may not. ──
-- (Run once pgcrypto/column-privilege model is in place; safe to re-run.)
REVOKE SELECT (correct_option) ON public.mock_exam_questions FROM authenticated;

-- Faculty/HOD still need to read correct_option to author/verify exams —
-- since role membership can't be expressed in a column GRANT, this is
-- exposed back to them via a SECURITY DEFINER helper rather than a raw
-- column grant (which would have to apply to the whole `authenticated`
-- role, re-opening the leak for students).
CREATE OR REPLACE FUNCTION get_mock_exam_question_with_answer(p_question_id UUID)
RETURNS TABLE (id UUID, exam_id UUID, question_text TEXT, option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT, correct_option TEXT, marks INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')) THEN
    RAISE EXCEPTION 'Only faculty/HOD may view correct answers';
  END IF;
  RETURN QUERY
    SELECT q.id, q.exam_id, q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, q.marks
    FROM mock_exam_questions q WHERE q.id = p_question_id;
END;
$$;

REVOKE ALL ON FUNCTION get_mock_exam_question_with_answer(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_mock_exam_question_with_answer(UUID) TO authenticated;

-- ──────────────────────────────────────────────────────────────
-- start_mock_exam: server-authoritative start time + single-active-session
-- (Section 4.1). The exam page currently times itself client-side
-- (`startTime.current = Date.now()`) and reports elapsed seconds to the
-- submit endpoint — this RPC gives it a real server timestamp to check
-- against instead, and rejects a second concurrent attempt.
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION start_mock_exam(p_exam_id UUID)
RETURNS TABLE (result_id UUID, session_token UUID, started_at TIMESTAMPTZ, duration_minutes INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing mock_exam_results%ROWTYPE;
  v_duration INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_existing FROM mock_exam_results
  WHERE exam_id = p_exam_id AND student_id = auth.uid();

  SELECT m.duration_minutes INTO v_duration FROM mock_exams m WHERE m.id = p_exam_id;
  IF v_duration IS NULL THEN
    RAISE EXCEPTION 'Exam not found';
  END IF;

  IF FOUND AND v_existing.status IN ('submitted', 'auto_submitted') THEN
    RAISE EXCEPTION 'Already submitted';
  END IF;

  IF FOUND THEN
    -- Resume the same in-progress session rather than issuing a second one.
    RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_duration;
    RETURN;
  END IF;

  INSERT INTO mock_exam_results (exam_id, student_id, session_token, started_at, status)
  VALUES (p_exam_id, auth.uid(), gen_random_uuid(), now(), 'in_progress')
  RETURNING mock_exam_results.id, mock_exam_results.session_token, mock_exam_results.started_at
  INTO v_existing.id, v_existing.session_token, v_existing.started_at;

  RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_duration;
END;
$$;

REVOKE ALL ON FUNCTION start_mock_exam(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION start_mock_exam(UUID) TO authenticated;

-- ──────────────────────────────────────────────────────────────
-- submit_exam_server_side: matches the exact call shape already used by
-- apps/web/app/api/student/exam/submit/route.ts. Grades server-side —
-- correct_option is read here as the function owner, never sent to the
-- browser. Rejects a resubmission ("Already submitted", matched by that
-- route's error-message string check) and auto-grades whatever was
-- answered if the server-computed elapsed time exceeds the exam duration
-- (a fixed 2-minute grace period for submission network latency),
-- regardless of the client-reported p_time_taken_seconds.
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION submit_exam_server_side(
  p_exam_id UUID,
  p_student_id UUID,
  p_answers JSONB,
  p_time_taken_seconds INTEGER,
  p_proctoring_flags JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result mock_exam_results%ROWTYPE;
  v_duration_minutes INTEGER;
  v_question RECORD;
  v_raw_marks NUMERIC := 0;
  v_out_of NUMERIC := 0;
  v_total_questions INTEGER := 0;
  v_student_answer TEXT;
  v_elapsed_seconds INTEGER;
  v_status TEXT := 'submitted';
BEGIN
  IF auth.uid() IS NULL OR auth.uid() != p_student_id THEN
    RAISE EXCEPTION 'Not authenticated as the submitting student';
  END IF;

  SELECT * INTO v_result FROM mock_exam_results
  WHERE exam_id = p_exam_id AND student_id = p_student_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active session — call start_mock_exam first';
  END IF;

  IF v_result.status IN ('submitted', 'auto_submitted') THEN
    RAISE EXCEPTION 'Already submitted';
  END IF;

  SELECT duration_minutes INTO v_duration_minutes FROM mock_exams WHERE id = p_exam_id;

  v_elapsed_seconds := EXTRACT(EPOCH FROM (now() - v_result.started_at))::INTEGER;
  IF v_elapsed_seconds > (v_duration_minutes * 60) + 120 THEN
    v_status := 'auto_submitted';
  END IF;

  FOR v_question IN SELECT * FROM mock_exam_questions WHERE exam_id = p_exam_id ORDER BY order_index LOOP
    v_total_questions := v_total_questions + 1;
    v_out_of := v_out_of + v_question.marks;
    v_student_answer := p_answers ->> v_question.id::TEXT;
    IF v_student_answer IS NOT NULL AND upper(v_student_answer) = v_question.correct_option THEN
      v_raw_marks := v_raw_marks + v_question.marks;
    END IF;
  END LOOP;

  UPDATE mock_exam_results SET
    submitted_at     = now(),
    score             = CASE WHEN v_out_of > 0 THEN round((v_raw_marks / v_out_of) * 100, 2) ELSE 0 END,
    raw_marks         = v_raw_marks,
    out_of            = v_out_of,
    total_questions   = v_total_questions,
    proctoring_flags  = COALESCE(p_proctoring_flags, '[]'::jsonb),
    status            = v_status
  WHERE id = v_result.id;

  RETURN jsonb_build_object(
    'result_id', v_result.id,
    'score', CASE WHEN v_out_of > 0 THEN round((v_raw_marks / v_out_of) * 100, 2) ELSE 0 END,
    'raw_marks', v_raw_marks,
    'out_of', v_out_of
  );
END;
$$;

REVOKE ALL ON FUNCTION submit_exam_server_side(UUID, UUID, JSONB, INTEGER, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_exam_server_side(UUID, UUID, JSONB, INTEGER, JSONB) TO service_role;

-- ──────────────────────────────────────────────────────────────
-- STEP 9 — readiness_score_history (Section 5.3 audit trail).
-- CORRECTED: verified live that `readiness_scores` is ALREADY an
-- append-only log (85 rows found for a single user_id, not one row per
-- user) — it already IS the audit trail Section 5.3 asks for. No separate
-- table/trigger needed; adding a covering index instead so "get the
-- current score" (latest row per user) queries stay fast as this grows.
-- Frontend code must query `ORDER BY computed_at DESC LIMIT 1` per user —
-- never `.single()` on a bare user_id filter, since that will error once
-- more than one row exists (it already does for every user today).
-- ──────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS readiness_scores_user_computed_idx
  ON readiness_scores(user_id, computed_at DESC);

-- Convenience view: exactly one (the latest) row per user. Dashboards and
-- the leaderboard both need "current score", not the full history.
-- WITH (security_invoker = true) is required — without it, views run with
-- the creator's privileges and silently bypass the underlying table's RLS
-- (this is the exact class of bug apps/mobile/database/01_MASTER_SETUP.sql
-- patch 15 had to fix elsewhere in this project's history).
CREATE OR REPLACE VIEW current_readiness_scores
WITH (security_invoker = true) AS
SELECT DISTINCT ON (user_id) user_id, score, components_json, computed_at
FROM readiness_scores
ORDER BY user_id, computed_at DESC;

-- ──────────────────────────────────────────────────────────────
-- STEP 10 — placement_log_entries: add tri-state moderation.
-- apps/web/app/api/governance/stats/route.ts already expects an
-- `approval_status` ('pending'/'approved'/'rejected'), but the live table
-- only has a boolean `is_moderated`/`moderated_by` pair, which can't
-- represent "rejected". Adding alongside the existing columns rather than
-- replacing them, since other code may still read is_moderated.
-- ──────────────────────────────────────────────────────────────

ALTER TABLE placement_log_entries
  ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'pending'
  CHECK (approval_status IN ('pending', 'approved', 'rejected'));

-- ──────────────────────────────────────────────────────────────
-- STEP 11 — user_feedback (matches apps/web/app/api/feedback/route.ts,
-- which already targets this exact shape).
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_feedback (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category      TEXT NOT NULL DEFAULT 'general',
  feedback_text TEXT NOT NULL,
  rating        INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_feedback_select_own ON user_feedback
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY user_feedback_select_faculty_hod ON user_feedback
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')));
CREATE POLICY user_feedback_insert_own ON user_feedback
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- STEP 12 — collaboration_posts (matches apps/web/app/alumni/marketplace/page.tsx,
-- which already targets this exact shape). Out of the plan's locked
-- launch scope (Section 15 defers the full marketplace) but the web page
-- already exists and is reachable, so it gets a working table rather than
-- a permanently broken query.
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS collaboration_posts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_type   TEXT NOT NULL CHECK (post_type IN ('job', 'project', 'mentorship')),
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  visibility  TEXT NOT NULL DEFAULT 'batch' CHECK (visibility IN ('lineage_only', 'batch', 'department')),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  posted_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE collaboration_posts ENABLE ROW LEVEL SECURITY;

-- Visibility scoping kept simple for v1: any authenticated user can see
-- 'department'-visibility posts; 'batch' is scoped to the poster's own
-- batch; 'lineage_only' is scoped to the poster's lineage_map connections.
-- Full lineage-aware visibility is part of the deferred marketplace work
-- (Section 15) — this is intentionally permissive-but-functional for now.
CREATE POLICY collaboration_posts_select ON collaboration_posts
  FOR SELECT TO authenticated
  USING (
    is_active = true AND (
      visibility = 'department'
      OR posted_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM users u1, users u2
        WHERE u1.id = auth.uid() AND u2.id = collaboration_posts.posted_by
          AND visibility = 'batch' AND u1.batch_id = u2.batch_id
      )
    )
  );

CREATE POLICY collaboration_posts_insert_own ON collaboration_posts
  FOR INSERT TO authenticated WITH CHECK (posted_by = auth.uid());
CREATE POLICY collaboration_posts_update_own ON collaboration_posts
  FOR UPDATE TO authenticated USING (posted_by = auth.uid()) WITH CHECK (posted_by = auth.uid());

-- ──────────────────────────────────────────────────────────────
-- DONE. Not covered by this migration (intentionally — later sprints):
--  - Locking down readiness_scores/daily_five_streaks/leetcode_stats to
--    remove direct student INSERT/UPDATE (Section 4.5) — Sprint 2, once
--    the replacement RPCs exist, so nothing breaks mid-migration.
--  - Question-bank answer-key stripping audit (Section 4.2) — needs a
--    code-level check of whatever API serves the daily question set, not
--    a schema change.
--  - Fixing supabase/functions/compute-readiness-score/index.ts, which
--    targets the wrong (never-applied) schema — flagged for Sprint 2.
-- ──────────────────────────────────────────────────────────────
