-- ============================================================================
-- PSGMX v4 — Migration 18: Placement Sessions + Placement Attendance
-- ============================================================================
-- Creates the two tables that drive placement-class attendance tracking
-- (Section 4.2 of Agent.md). This is the number that feeds the readiness score —
-- NOT the eCampus official academic attendance.
--
-- Run AFTER 17_batch_system.sql
-- ============================================================================

-- ── 1. placement_sessions ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS placement_sessions (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id          UUID        NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    scheduled_by      UUID        NOT NULL REFERENCES users(id),
    session_datetime  TIMESTAMPTZ NOT NULL,
    topic             TEXT        NOT NULL,
    description       TEXT,
    -- NULL means whole batch; non-NULL array means subset of team IDs
    target_team_ids   UUID[]      DEFAULT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_placement_sessions_batch
    ON placement_sessions(batch_id, session_datetime DESC);
CREATE INDEX IF NOT EXISTS idx_placement_sessions_datetime
    ON placement_sessions(session_datetime);

DROP TRIGGER IF EXISTS set_updated_at_placement_sessions ON placement_sessions;
CREATE TRIGGER set_updated_at_placement_sessions
    BEFORE UPDATE ON placement_sessions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 2. placement_attendance ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS placement_attendance (
    session_id  UUID    NOT NULL REFERENCES placement_sessions(id) ON DELETE CASCADE,
    user_id     UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      TEXT    NOT NULL
                CHECK (status IN ('present', 'absent', 'excused')),
    marked_by   UUID    NOT NULL REFERENCES users(id),
    marked_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes       TEXT,
    PRIMARY KEY (session_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_placement_attendance_user
    ON placement_attendance(user_id, session_id);
CREATE INDEX IF NOT EXISTS idx_placement_attendance_session
    ON placement_attendance(session_id);

-- ── 3. Computed view: placement attendance percentage per user ────────────────
-- Returns each user's rolling placement attendance % across all sessions
-- they were eligible for (i.e. their team was targeted or session was batch-wide).
CREATE OR REPLACE VIEW placement_attendance_summary AS
SELECT
    u.id                        AS user_id,
    u.batch_id,
    COUNT(ps.id)                AS eligible_sessions,
    COUNT(pa.session_id)
        FILTER (WHERE pa.status = 'present')
                                AS attended_sessions,
    CASE
        WHEN COUNT(ps.id) = 0 THEN 0
        ELSE ROUND(
            COUNT(pa.session_id) FILTER (WHERE pa.status = 'present')
            * 100.0 / COUNT(ps.id),
            2
        )
    END                         AS attendance_pct
FROM users u
JOIN placement_sessions ps ON ps.batch_id = u.batch_id
    AND (
        ps.target_team_ids IS NULL          -- whole-batch session
        OR u.team_id::UUID = ANY(ps.target_team_ids)  -- targeted session
    )
LEFT JOIN placement_attendance pa
    ON pa.session_id = ps.id AND pa.user_id = u.id
GROUP BY u.id, u.batch_id;

-- ── 4. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE placement_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_attendance ENABLE ROW LEVEL SECURITY;

-- placement_sessions: all authenticated users can read (same batch)
DROP POLICY IF EXISTS "placement_sessions_read" ON placement_sessions;
CREATE POLICY "placement_sessions_read" ON placement_sessions
    FOR SELECT TO authenticated
    USING (batch_id = get_user_batch_id(auth.uid()));

-- schedule_placement_sessions permission required to create/edit/delete
DROP POLICY IF EXISTS "placement_sessions_write" ON placement_sessions;
CREATE POLICY "placement_sessions_write" ON placement_sessions
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'schedule_placement_sessions'))
    WITH CHECK (user_has_permission(auth.uid(), 'schedule_placement_sessions'));

-- placement_attendance: students see their own
DROP POLICY IF EXISTS "placement_attendance_read_own" ON placement_attendance;
CREATE POLICY "placement_attendance_read_own" ON placement_attendance
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- mark_placement_attendance permission required to insert/update
DROP POLICY IF EXISTS "placement_attendance_write" ON placement_attendance;
CREATE POLICY "placement_attendance_write" ON placement_attendance
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'mark_placement_attendance'))
    WITH CHECK (user_has_permission(auth.uid(), 'mark_placement_attendance'));

-- Reps/Coordinators (view_batch_analytics) can read all attendance for their batch
DROP POLICY IF EXISTS "placement_attendance_read_admin" ON placement_attendance;
CREATE POLICY "placement_attendance_read_admin" ON placement_attendance
    FOR SELECT TO authenticated
    USING (
        user_has_permission(auth.uid(), 'view_batch_analytics')
        AND EXISTS (
            SELECT 1 FROM placement_sessions ps
            WHERE ps.id = placement_attendance.session_id
              AND ps.batch_id = get_user_batch_id(auth.uid())
        )
    );

-- ── 5. Grant mark_placement_attendance to all existing Team Leaders ───────────
INSERT INTO user_permissions (user_id, permission_key)
SELECT u.id, 'mark_placement_attendance'
FROM users u
WHERE (u.roles->>'isTeamLeader')::boolean = TRUE
ON CONFLICT DO NOTHING;

-- ── 6. Success ────────────────────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration 18 complete: Placement Sessions';
    RAISE NOTICE '  - placement_sessions table created';
    RAISE NOTICE '  - placement_attendance table created';
    RAISE NOTICE '  - placement_attendance_summary view created';
    RAISE NOTICE '  - RLS policies applied';
    RAISE NOTICE 'NEXT: Run 19_daily_five.sql';
    RAISE NOTICE '========================================';
END $$;
