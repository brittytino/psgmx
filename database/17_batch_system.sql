-- ============================================================================
-- PSGMX v4 — Migration 17: Batch System + Dynamic Permission Model
-- ============================================================================
-- Introduces:
--   • batches          — one row per MCA cohort
--   • user_permissions — per-user capability flags (replaces static roles JSONB)
--   • teams            — auto-generated, Rep-configurable student teams
--
-- Also migrates existing users.batch ('G1'/'G2') data into the batches table
-- and wires up the nightly batch-rotation cron job.
--
-- Run AFTER 16_security_hardening.sql
-- ============================================================================

-- ── 1. batches ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batches (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code  TEXT        NOT NULL UNIQUE,   -- e.g. '25MX', '26MX'
    start_year  INT         NOT NULL,
    end_year    INT         NOT NULL,
    status      TEXT        NOT NULL
                CHECK (status IN ('active_senior', 'active_junior', 'graduated')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_code   ON batches(batch_code);

-- ── 2. Migrate existing G1/G2 batch strings into the batches table ────────────
-- Inserts placeholder rows if they don't exist yet so foreign keys resolve.
INSERT INTO batches (batch_code, start_year, end_year, status)
VALUES
    ('25MX', 2025, 2027, 'active_senior'),
    ('26MX', 2026, 2028, 'active_junior')
ON CONFLICT (batch_code) DO NOTHING;

-- ── 3. Add batch_id + role_label columns to users ────────────────────────────
-- batch_id is the FK to batches; role_label is the UI-facing name (cosmetic only).
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS batch_id   UUID  REFERENCES batches(id),
    ADD COLUMN IF NOT EXISTS role_label TEXT  NOT NULL DEFAULT 'Student';

-- Back-fill batch_id from legacy batch ('G1' → '25MX', 'G2' → '26MX')
UPDATE users u
SET batch_id = b.id
FROM batches b
WHERE (u.batch = 'G1' AND b.batch_code = '25MX')
   OR (u.batch = 'G2' AND b.batch_code = '26MX');

CREATE INDEX IF NOT EXISTS idx_users_batch_id ON users(batch_id);

-- ── 4. user_permissions ───────────────────────────────────────────────────────
-- Each row grants one permission key to one user.
-- Valid keys are enforced via the CHECK constraint below.
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id         UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_key  TEXT    NOT NULL
        CHECK (permission_key IN (
            'manage_members',
            'configure_teams',
            'schedule_placement_sessions',
            'mark_placement_attendance',
            'publish_tasks',
            'manage_company_records',
            'moderate_placement_log',
            'view_batch_analytics'
        )),
    granted_by      UUID    REFERENCES users(id),
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, permission_key)
);

CREATE INDEX IF NOT EXISTS idx_user_permissions_user
    ON user_permissions(user_id);

-- Grant all permissions to every existing Placement Rep
INSERT INTO user_permissions (user_id, permission_key)
SELECT u.id, p.key
FROM users u
CROSS JOIN (VALUES
    ('manage_members'),
    ('configure_teams'),
    ('schedule_placement_sessions'),
    ('mark_placement_attendance'),
    ('publish_tasks'),
    ('manage_company_records'),
    ('moderate_placement_log'),
    ('view_batch_analytics')
) AS p(key)
WHERE (u.roles->>'isPlacementRep')::boolean = TRUE
ON CONFLICT DO NOTHING;

-- ── 5. teams ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teams (
    id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID    NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    team_name       TEXT    NOT NULL,
    team_leader_id  UUID    REFERENCES users(id),
    target_size     INT     NOT NULL DEFAULT 6
                    CHECK (target_size BETWEEN 3 AND 20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teams_batch_id ON teams(batch_id);

-- ── 6. RLS on new tables ─────────────────────────────────────────────────────

-- batches: everyone can read; only service-role can mutate (via cron job)
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "batches_read_all" ON batches;
CREATE POLICY "batches_read_all" ON batches
    FOR SELECT TO authenticated USING (TRUE);

-- user_permissions: users see their own; manage_members can see batch
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "permissions_read_own" ON user_permissions;
CREATE POLICY "permissions_read_own" ON user_permissions
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "permissions_read_manage_members" ON user_permissions;
CREATE POLICY "permissions_read_manage_members" ON user_permissions
    FOR SELECT TO authenticated
    USING (user_has_permission(auth.uid(), 'manage_members'));

DROP POLICY IF EXISTS "permissions_write_manage_members" ON user_permissions;
CREATE POLICY "permissions_write_manage_members" ON user_permissions
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'manage_members'))
    WITH CHECK (user_has_permission(auth.uid(), 'manage_members'));

-- teams: all authenticated users can read; configure_teams can write
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "teams_read_all" ON teams;
CREATE POLICY "teams_read_all" ON teams
    FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS "teams_write_configure_teams" ON teams;
CREATE POLICY "teams_write_configure_teams" ON teams
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'configure_teams'))
    WITH CHECK (user_has_permission(auth.uid(), 'configure_teams'));

-- ── 7. Batch rotation function ────────────────────────────────────────────────
-- Runs nightly. Flips a batch to 'graduated' when its end_year has passed
-- the current academic year cutoff (we use July 1 as the graduation trigger —
-- adjust the month/day to match the actual convocation date if needed).
CREATE OR REPLACE FUNCTION rotate_batch_status()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    graduation_cutoff DATE;
    v_batch           RECORD;
BEGIN
    -- Graduation cutoff: July 1 of the end_year
    -- (Adjust month/day per the open assumption in Agent.md §14)
    FOR v_batch IN
        SELECT id, batch_code, end_year, status FROM batches
        WHERE status <> 'graduated'
        ORDER BY end_year
    LOOP
        graduation_cutoff := make_date(v_batch.end_year, 7, 1);

        IF CURRENT_DATE >= graduation_cutoff THEN
            UPDATE batches SET status = 'graduated', updated_at = NOW()
            WHERE id = v_batch.id;

            -- Write audit log entry
            INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, metadata)
            SELECT
                u.id,
                'BATCH_GRADUATED',
                'batch',
                v_batch.id,
                jsonb_build_object(
                    'batch_code', v_batch.batch_code,
                    'graduated_at', NOW()
                )
            FROM users u
            WHERE (u.roles->>'isPlacementRep')::boolean = TRUE
              AND u.batch_id = v_batch.id
            LIMIT 1;

            RAISE NOTICE 'Batch % graduated', v_batch.batch_code;
        END IF;
    END LOOP;

    -- Promote active_junior → active_senior if there is no active_senior
    IF NOT EXISTS (SELECT 1 FROM batches WHERE status = 'active_senior') THEN
        UPDATE batches
        SET status = 'active_senior', updated_at = NOW()
        WHERE status = 'active_junior'
        ORDER BY start_year
        LIMIT 1;
    END IF;
END;
$$;

-- ── 8. Schedule the cron job (runs daily at 01:00 UTC) ───────────────────────
SELECT cron.schedule(
    'rotate-batch-status',
    '0 1 * * *',
    'SELECT rotate_batch_status()'
);

-- ── 9. Updated timestamp trigger for new tables ───────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_updated_at_batches ON batches;
CREATE TRIGGER set_updated_at_batches
    BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_teams ON teams;
CREATE TRIGGER set_updated_at_teams
    BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 10. Success ───────────────────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration 17 complete: Batch System + Permissions';
    RAISE NOTICE '  - batches table created + seeded (25MX, 26MX)';
    RAISE NOTICE '  - users.batch_id + role_label added';
    RAISE NOTICE '  - user_permissions table created';
    RAISE NOTICE '  - teams table created';
    RAISE NOTICE '  - rotate_batch_status() cron job scheduled (01:00 UTC daily)';
    RAISE NOTICE 'NEXT: Run 18_placement_sessions.sql';
    RAISE NOTICE '========================================';
END $$;
