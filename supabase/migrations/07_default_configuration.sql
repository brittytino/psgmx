-- ============================================================
-- PSGMX — 07_default_configuration.sql
-- Default Presets, Batches, Squads & App Configuration
-- ============================================================

BEGIN;

-- ── 1. MCA Cohort Batches ────────────────────────────────────
INSERT INTO public.batches (batch_code, start_year, end_year, status) VALUES
    ('23MX', 2023, 2025, 'graduated'),
    ('24MX', 2024, 2026, 'graduated'),
    ('25MX', 2025, 2027, 'active_senior'),
    ('26MX', 2026, 2028, 'active_junior')
ON CONFLICT (batch_code) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = now();

-- ── 2. Remote App Version Config ─────────────────────────────
INSERT INTO public.app_config (
    min_required_version, latest_version, force_update, update_message,
    github_release_url, emergency_block
) VALUES (
    '1.0.0', '1.2.0', false,
    'A new version of PSGMX is available. Update now for the latest features.',
    'https://github.com/psgmx/psgmx-flutter/releases/latest', false
) ON CONFLICT DO NOTHING;

-- ── 3. Tier Targets ──────────────────────────────────────────
INSERT INTO public.tier_targets (tier, min_score, max_score, description) VALUES
    ('tier1', 75, 100, 'Product companies, high-frequency engineering, and premier R&D roles (12+ LPA).'),
    ('tier2', 50, 74,  'Established tech enterprises, full-stack consulting, and scalable systems (6-12 LPA).'),
    ('tier3', 0,  49,  'Services, foundation development, and core technology transformation (under 6 LPA).')
ON CONFLICT (tier) DO UPDATE SET
    min_score = EXCLUDED.min_score,
    max_score = EXCLUDED.max_score,
    description = EXCLUDED.description;

-- ── 4. Placement 2026 Squads ─────────────────────────────────
DO $$
DECLARE
  v_batch_id UUID;
BEGIN
  SELECT id INTO v_batch_id FROM public.batches WHERE batch_code = '26MX';
  IF v_batch_id IS NOT NULL THEN
    INSERT INTO public.teams (batch_id, team_name, team_code, target_size, objective) VALUES
      (v_batch_id, 'Team 1',  'T01', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 2',  'T02', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 3',  'T03', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 4',  'T04', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 5',  'T05', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 6',  'T06', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 7',  'T07', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 8',  'T08', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 9',  'T09', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 10', 'T10', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 11', 'T11', 6, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 12', 'T12', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 13', 'T13', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 14', 'T14', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 15', 'T15', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 16', 'T16', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 17', 'T17', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 18', 'T18', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 19', 'T19', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 20', 'T20', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.'),
      (v_batch_id, 'Team 21', 'T21', 5, 'Complete combined CodeBox quests and maintain Daily Five streaks.')
    ON CONFLICT (batch_id, team_code) DO UPDATE SET
      team_name = EXCLUDED.team_name,
      target_size = EXCLUDED.target_size,
      objective = EXCLUDED.objective,
      updated_at = now();
  END IF;
END $$;

-- ── 4. Curated Communication Practice Prompt Bank ───────────
INSERT INTO public.communication_prompt_bank (prompt_text, category, difficulty, evaluation_focus) VALUES
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

COMMIT;

