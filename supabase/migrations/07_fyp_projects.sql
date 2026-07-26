-- ============================================================
-- PSGMX — 07_fyp_projects.sql
-- Final Year Projects (FYP) tracking & User feedback tables.
-- Enables FYP portfolio, progress logs, faculty reviews, & platform feedback.
-- ============================================================

CREATE TABLE IF NOT EXISTS fyp_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID REFERENCES batches(id),
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  guide_name TEXT NOT NULL DEFAULT 'Dr. Arunkumar',
  team_members_count INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'in_progress'
    CHECK (status IN ('proposal', 'in_progress', 'completed', 'archived')),
  repository_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fyp_progress_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  author_name TEXT NOT NULL DEFAULT 'You',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fyp_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES fyp_projects(id) ON DELETE CASCADE,
  faculty_id UUID REFERENCES users(id),
  faculty_name TEXT NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL DEFAULT 'general',
  feedback_text TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Row Level Security
ALTER TABLE fyp_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fyp_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;

-- Policies for fyp_projects
CREATE POLICY fyp_projects_read ON fyp_projects
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY fyp_projects_write ON fyp_projects
  FOR ALL USING (auth.uid() = student_id OR EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('faculty', 'hod')
  ));

-- Policies for fyp_progress_logs
CREATE POLICY fyp_progress_logs_read ON fyp_progress_logs
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY fyp_progress_logs_write ON fyp_progress_logs
  FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Policies for fyp_feedback
CREATE POLICY fyp_feedback_read ON fyp_feedback
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY fyp_feedback_write ON fyp_feedback
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('faculty', 'hod')
  ));

-- Policies for user_feedback
CREATE POLICY user_feedback_read ON user_feedback
  FOR SELECT USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('faculty', 'hod')
  ));

CREATE POLICY user_feedback_write ON user_feedback
  FOR INSERT WITH CHECK (auth.uid() = user_id);
