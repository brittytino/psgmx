-- ============================================================
-- PSGMX — 03_schema_placement.sql
-- ============================================================
-- Placement classes (sessions/attendance), placement drive records
-- (companies/placement_log_entries), and the legacy day-to-day class
-- attendance system (attendance_records/scheduled_attendance_dates).
--
-- BUG FIX vs. the old apps/mobile/database/01_MASTER_SETUP.sql: that file's
-- placement_attendance_summary view did `u.team_id::UUID = ANY(ps.target_team_ids)`
-- — casting the legacy free-text team code (e.g. 'T20') straight to UUID
-- against a UUID[] column, which always errors, since users.team_id codes
-- were never the same id space as the `teams` table's UUID rows (nothing
-- ever populated that mapping). Fixed here by making
-- placement_sessions.target_team_ids a TEXT[] of the same legacy codes
-- users.team_id already uses — no cast, no separate mapping table needed,
-- and no app-code changes required since the app already sends team codes
-- as plain strings everywhere else.
--
-- Run AFTER 02_schema_academic.sql.
-- ============================================================

-- ── companies — placement drive header records ───────────────────────────
CREATE TABLE companies (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID        NOT NULL REFERENCES batches(id),
    name            TEXT        NOT NULL,
    visit_date      DATE        NOT NULL,
    roles_offered   TEXT[]      NOT NULL DEFAULT '{}',
    package_band    TEXT,                 -- e.g. '5-8 LPA', '10+ LPA'
    eligibility     TEXT,
    rounds          JSONB       NOT NULL DEFAULT '[]',  -- [{name, type, description}]
    -- Nullable: historical placement-drive data (14_seed_placement_23mx_24mx.sql)
    -- is imported before any real HOD/placement-rep has ever logged in, so
    -- there is no live user to attribute it to yet.
    created_by      UUID        REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_companies_batch_date ON companies(batch_id, visit_date ASC);

-- ── placement_log_entries — second-year personal experience writeups ────────
CREATE TABLE placement_log_entries (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID        NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users(id),
    round_name      TEXT        NOT NULL,
    experience_text TEXT        NOT NULL,
    is_moderated    BOOLEAN     NOT NULL DEFAULT FALSE,
    moderated_by    UUID        REFERENCES users(id),
    approval_status TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_log_entries_company ON placement_log_entries(company_id, created_at DESC);
CREATE INDEX idx_log_entries_user    ON placement_log_entries(user_id);

-- ── placement_sessions — scheduled placement classes ────────────────────────
CREATE TABLE placement_sessions (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id          UUID        NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    scheduled_by      UUID        NOT NULL REFERENCES users(id),
    session_datetime  TIMESTAMPTZ NOT NULL,
    topic             TEXT        NOT NULL,
    description       TEXT,
    session_type      VARCHAR(50) DEFAULT 'Other',
    session_mode      VARCHAR(20) DEFAULT 'Offline',
    duration_minutes  INTEGER     DEFAULT 60,
    location          VARCHAR(255) DEFAULT 'TBA',
    is_locked         BOOLEAN     DEFAULT FALSE,
    -- NULL means whole batch; non-NULL array means a subset of legacy team codes (e.g. '{T01,T02}')
    target_team_ids   TEXT[]      DEFAULT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_placement_sessions_batch    ON placement_sessions(batch_id, session_datetime DESC);
CREATE INDEX idx_placement_sessions_datetime ON placement_sessions(session_datetime);

-- ── placement_attendance ─────────────────────────────────────────────────
CREATE TABLE placement_attendance (
    session_id  UUID    NOT NULL REFERENCES placement_sessions(id) ON DELETE CASCADE,
    user_id     UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      TEXT    NOT NULL CHECK (status IN ('present', 'absent', 'excused')),
    marked_by   UUID    NOT NULL REFERENCES users(id),
    marked_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes       TEXT,
    PRIMARY KEY (session_id, user_id)
);

CREATE INDEX idx_placement_attendance_user    ON placement_attendance(user_id, session_id);
CREATE INDEX idx_placement_attendance_session ON placement_attendance(session_id);

-- Rolling placement-attendance % per user, across every session they were
-- eligible for (their team was targeted, or the session was batch-wide).
CREATE VIEW placement_attendance_summary AS
SELECT
    u.id                        AS user_id,
    u.batch_id,
    COUNT(ps.id)                AS eligible_sessions,
    COUNT(pa.session_id) FILTER (WHERE pa.status = 'present') AS attended_sessions,
    CASE
        WHEN COUNT(ps.id) = 0 THEN 0
        ELSE ROUND(
            COUNT(pa.session_id) FILTER (WHERE pa.status = 'present') * 100.0 / COUNT(ps.id),
            2
        )
    END                         AS attendance_pct
FROM users u
JOIN placement_sessions ps ON ps.batch_id = u.batch_id
    AND (
        ps.target_team_ids IS NULL              -- whole-batch session
        OR u.team_id = ANY(ps.target_team_ids)  -- targeted session (legacy TEXT team codes on both sides)
    )
LEFT JOIN placement_attendance pa
    ON pa.session_id = ps.id AND pa.user_id = u.id
GROUP BY u.id, u.batch_id;

-- ── scheduled_attendance_dates — dates when class attendance marking opens ──
CREATE TABLE scheduled_attendance_dates (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date          DATE NOT NULL UNIQUE,
    is_working_day BOOLEAN NOT NULL DEFAULT TRUE,
    scheduled_by  UUID REFERENCES users(id),
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scheduled_dates_date ON scheduled_attendance_dates(date);

-- ── attendance_records — individual day-to-day class attendance ─────────────
CREATE TABLE attendance_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    team_id     TEXT NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('PRESENT', 'ABSENT', 'NA')),
    marked_by   UUID REFERENCES users(id),
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)  -- enables bulk upsert
);

CREATE INDEX idx_attendance_date    ON attendance_records(date);
CREATE INDEX idx_attendance_user_id ON attendance_records(user_id);
CREATE INDEX idx_attendance_team_id ON attendance_records(team_id);
CREATE INDEX idx_attendance_status  ON attendance_records(status);

-- Per-student attendance summary, sourced from whitelist (so every
-- pre-provisioned student appears, not just those who have logged in yet).
CREATE VIEW student_attendance_summary
WITH (security_invoker = true) AS
SELECT
    u.id                                         AS student_id,
    u.id                                         AS user_id,
    COALESCE(u.email,   w.email)                 AS email,
    w.reg_no,
    COALESCE(u.name,    w.name)                  AS name,
    COALESCE(u.team_id, w.team_id)               AS team_id,
    COALESCE(u.batch,   w.batch)                 AS batch,
    COALESCE(SUM(CASE WHEN ar.status = 'PRESENT'              THEN 1 ELSE 0 END), 0)::int AS present_count,
    COALESCE(SUM(CASE WHEN ar.status = 'ABSENT'               THEN 1 ELSE 0 END), 0)::int AS absent_count,
    COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0)::int AS total_working_days,
    CASE
        WHEN COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0) = 0 THEN 0.0
        ELSE ROUND(
            COALESCE(SUM(CASE WHEN ar.status = 'PRESENT' THEN 1 ELSE 0 END), 0)::numeric
            / NULLIF(COALESCE(SUM(CASE WHEN ar.status IN ('PRESENT', 'ABSENT') THEN 1 ELSE 0 END), 0), 0)
            * 100,
            2
        )
    END AS attendance_percentage
FROM whitelist w
LEFT JOIN users u  ON u.reg_no  = w.reg_no
LEFT JOIN attendance_records ar ON ar.user_id = u.id
WHERE w.reg_no IS NOT NULL
GROUP BY
    w.reg_no, w.email, w.name, w.team_id, w.batch,
    u.id, u.email, u.name, u.team_id, u.batch;

DO $$
BEGIN
    RAISE NOTICE '✅ 03_schema_placement.sql complete.';
    RAISE NOTICE 'NEXT: run 04_schema_knowledge_fyp.sql';
END $$;
