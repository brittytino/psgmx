-- ============================================================
-- PSGMX — 17_update_2026_placement_teams.sql
-- ============================================================
-- Synchronizes 26MX placement teams, squad targets, and assignments
-- with the updated institutional roster from PLACEMNETS TEAMS 2026.
-- ============================================================

BEGIN;

-- ── 1. Fix and Harden get_batch_placement_teams RPC ───────────
CREATE OR REPLACE FUNCTION public.get_batch_placement_teams(p_batch_code TEXT DEFAULT '26MX')
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_batch_id UUID;
  v_teams JSONB;
BEGIN
  SELECT id INTO v_batch_id FROM public.batches WHERE batch_code = p_batch_code;
  IF v_batch_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'team_code', t.team_code,
        'team_name', t.team_name,
        'objective', t.objective,
        'target_size', t.target_size,
        'team_leader_id', t.team_leader_id,
        'members', COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', COALESCE(u.id::text, w.reg_no, w.email),
                'name', COALESCE(u.name, w.name),
                'roll_no', COALESCE(u.reg_no, w.reg_no),
                'is_leader', (
                  (u.id IS NOT NULL AND u.id = t.team_leader_id) OR
                  COALESCE((u.roles->>'isTeamLeader')::boolean, false) OR
                  COALESCE((w.roles->>'isTeamLeader')::boolean, false)
                )
              ) ORDER BY
                ((u.id IS NOT NULL AND u.id = t.team_leader_id) OR
                 COALESCE((u.roles->>'isTeamLeader')::boolean, false) OR
                 COALESCE((w.roles->>'isTeamLeader')::boolean, false)) DESC,
                COALESCE(u.reg_no, w.reg_no)
            )
            FROM public.whitelist w
            LEFT JOIN public.users u ON u.reg_no = w.reg_no
            WHERE w.team_uuid = t.id OR (w.team_id = t.team_code AND w.batch_id = v_batch_id)
          ),
          '[]'::jsonb
        )
      ) ORDER BY t.team_code
    ),
    '[]'::jsonb
  ) INTO v_teams
  FROM public.teams t
  WHERE t.batch_id = v_batch_id;

  RETURN v_teams;
END;
$$;

-- ── 2. Update 26MX Teams Target Sizes ─────────────────────────
DO $$
DECLARE
  v_batch_id UUID;
BEGIN
  SELECT id INTO v_batch_id FROM public.batches WHERE batch_code = '26MX';
  IF v_batch_id IS NOT NULL THEN
    UPDATE public.teams SET target_size = 5 WHERE batch_id = v_batch_id AND team_code IN ('T04', 'T10', 'T14', 'T15', 'T16', 'T17', 'T18', 'T19', 'T20', 'T21');
    UPDATE public.teams SET target_size = 6 WHERE batch_id = v_batch_id AND team_code IN ('T01', 'T02', 'T03', 'T05', 'T06', 'T07', 'T08', 'T09', 'T11', 'T12', 'T13');
  END IF;
END $$;

-- ── 3. Temporary Table for Placement 2026 Roster Mapping ──────
CREATE TEMP TABLE temp_2026_placement_teams (
  team_code TEXT NOT NULL,
  roll_no TEXT NOT NULL,
  is_leader BOOLEAN NOT NULL DEFAULT FALSE
) ON COMMIT DROP;

INSERT INTO temp_2026_placement_teams (team_code, roll_no, is_leader) VALUES
  ('T01', '26MX212', true),  ('T01', '26MX333', false), ('T01', '26MX216', false), ('T01', '26MX228', false), ('T01', '26MX209', false), ('T01', '26MX344', false),
  ('T02', '26MX115', true),  ('T02', '26MX125', false), ('T02', '26MX356', false), ('T02', '26MX343', false), ('T02', '26MX110', false), ('T02', '26MX325', false),
  ('T03', '26MX309', true),  ('T03', '26MX203', false), ('T03', '26MX358', false), ('T03', '26MX119', false), ('T03', '26MX307', false), ('T03', '26MX346', false),
  ('T04', '26MX304', true),  ('T04', '26MX352', false), ('T04', '26MX211', false), ('T04', '26MX334', false), ('T04', '26MX102', false),
  ('T05', '26MX332', true),  ('T05', '26MX106', false), ('T05', '26MX114', false), ('T05', '26MX349', false), ('T05', '26MX223', false), ('T05', '26MX337', false),
  ('T06', '26MX205', true),  ('T06', '26MX117', false), ('T06', '26MX347', false), ('T06', '26MX127', false), ('T06', '26MX112', false), ('T06', '26MX322', false),
  ('T07', '26MX351', true),  ('T07', '26MX218', false), ('T07', '26MX348', false), ('T07', '26MX105', false), ('T07', '26MX310', false), ('T07', '26MX335', false),
  ('T08', '26MX320', true),  ('T08', '26MX108', false), ('T08', '26MX305', false), ('T08', '26MX312', false), ('T08', '26MX210', false), ('T08', '26MX126', false),
  ('T09', '26MX342', true),  ('T09', '26MX313', false), ('T09', '26MX341', false), ('T09', '26MX207', false), ('T09', '26MX204', false), ('T09', '26MX301', false),
  ('T10', '26MX214', true),  ('T10', '26MX202', false), ('T10', '26MX324', false), ('T10', '26MX219', false), ('T10', '26MX353', false),
  ('T11', '26MX336', true),  ('T11', '26MX315', false), ('T11', '26MX128', false), ('T11', '26MX227', false), ('T11', '26MX329', false), ('T11', '26MX104', false),
  ('T12', '26MX101', true),  ('T12', '26MX201', false), ('T12', '26MX303', false), ('T12', '26MX345', false), ('T12', '26MX107', false), ('T12', '26MX217', false),
  ('T13', '26MX224', true),  ('T13', '26MX123', false), ('T13', '26MX226', false), ('T13', '26MX116', false), ('T13', '26MX302', false), ('T13', '26MX109', false),
  ('T14', '26MX129', true),  ('T14', '26MX326', false), ('T14', '26MX222', false), ('T14', '26MX330', false), ('T14', '26MX208', false),
  ('T15', '26MX215', true),  ('T15', '26MX206', false), ('T15', '26MX318', false), ('T15', '26MX220', false), ('T15', '26MX314', false),
  ('T16', '26MX317', true),  ('T16', '26MX350', false), ('T16', '26MX120', false), ('T16', '26MX321', false), ('T16', '26MX111', false),
  ('T17', '26MX354', true),  ('T17', '26MX340', false), ('T17', '26MX121', false), ('T17', '26MX308', false), ('T17', '26MX328', false),
  ('T18', '26MX221', true),  ('T18', '26MX122', false), ('T18', '26MX319', false), ('T18', '26MX230', false), ('T18', '26MX113', false),
  ('T19', '26MX357', true),  ('T19', '26MX124', false), ('T19', '26MX225', false), ('T19', '26MX323', false), ('T19', '26MX229', false),
  ('T20', '26MX327', true),  ('T20', '26MX331', false), ('T20', '26MX118', false), ('T20', '26MX338', false), ('T20', '26MX306', false),
  ('T21', '26MX311', true),  ('T21', '26MX355', false), ('T21', '26MX316', false), ('T21', '26MX339', false), ('T21', '26MX103', false);

-- ── 4. Apply to Whitelist ──────────────────────────────────────
UPDATE public.whitelist w
SET
  team_uuid = t.id,
  team_id = m.team_code,
  roles = CASE
    WHEN m.is_leader THEN jsonb_set(COALESCE(w.roles, '{}'::jsonb), '{isTeamLeader}', 'true'::jsonb)
    ELSE jsonb_set(COALESCE(w.roles, '{}'::jsonb), '{isTeamLeader}', 'false'::jsonb)
  END
FROM temp_2026_placement_teams m
JOIN public.teams t ON t.team_code = m.team_code AND t.batch_id = (SELECT id FROM public.batches WHERE batch_code = '26MX')
WHERE w.reg_no = m.roll_no;

-- ── 5. Apply to Users ──────────────────────────────────────────
UPDATE public.users u
SET
  team_uuid = t.id,
  team_id = m.team_code,
  roles = CASE
    WHEN m.is_leader THEN jsonb_set(COALESCE(u.roles, '{}'::jsonb), '{isTeamLeader}', 'true'::jsonb)
    ELSE jsonb_set(COALESCE(u.roles, '{}'::jsonb), '{isTeamLeader}', 'false'::jsonb)
  END,
  updated_at = now()
FROM temp_2026_placement_teams m
JOIN public.teams t ON t.team_code = m.team_code AND t.batch_id = (SELECT id FROM public.batches WHERE batch_code = '26MX')
WHERE u.reg_no = m.roll_no;

-- ── 6. Update Team Leaders on public.teams ────────────────────
UPDATE public.teams t
SET
  team_leader_id = u.id,
  updated_at = now()
FROM temp_2026_placement_teams m
JOIN public.users u ON u.reg_no = m.roll_no
WHERE m.is_leader = true
  AND t.team_code = m.team_code
  AND t.batch_id = (SELECT id FROM public.batches WHERE batch_code = '26MX');

-- ── 7. Clear team for unassigned 26MX students ────────────────
UPDATE public.whitelist w
SET team_uuid = NULL, team_id = NULL,
    roles = jsonb_set(COALESCE(w.roles, '{}'::jsonb), '{isTeamLeader}', 'false'::jsonb)
WHERE w.batch_id = (SELECT id FROM public.batches WHERE batch_code = '26MX')
  AND w.reg_no NOT IN (SELECT roll_no FROM temp_2026_placement_teams);

UPDATE public.users u
SET team_uuid = NULL, team_id = NULL,
    roles = jsonb_set(COALESCE(u.roles, '{}'::jsonb), '{isTeamLeader}', 'false'::jsonb),
    updated_at = now()
WHERE u.batch_id = (SELECT id FROM public.batches WHERE batch_code = '26MX')
  AND u.reg_no NOT IN (SELECT roll_no FROM temp_2026_placement_teams);

COMMIT;
