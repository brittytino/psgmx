-- ============================================================
-- PSGMX — 01_schema_core.sql
-- ============================================================
-- Core identity/org tables: batches, users, whitelist, teams,
-- user_permissions, audit_logs, app_config.
--
-- This is the SINGLE canonical shape for these tables, reconciled from the
-- three generations that used to coexist in this repo (see the rebuild
-- plan for the full audit). Column choices here match what apps/web and
-- apps/mobile actually query today:
--   - reg_no (not roll_no) is the roll-number column.
--   - name (not full_name) is the display-name column.
--   - role_label (TEXT) + roles (JSONB sub-flags) + user_permissions
--     (fine-grained capability table) are ALL kept — both apps genuinely
--     read all three, this isn't drift to resolve away.
--   - users.team_id stays a legacy free-text code ('T01'..'T21') — it is
--     used throughout RLS (is_team_leader() + team_id equality checks)
--     and by the mobile app's whitelist-driven team system. The `teams`
--     table (UUID rows) is a separate, newer admin-configuration construct
--     and is intentionally NOT the same id space as users.team_id.
--
-- Run AFTER 00_reset.sql.
-- ============================================================

-- ── batches — one row per MCA admission cohort ──────────────────────────────
CREATE TABLE batches (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code  TEXT        NOT NULL UNIQUE,   -- e.g. '25MX', '26MX'
    start_year  INT         NOT NULL,
    end_year    INT         NOT NULL,
    status      TEXT        NOT NULL
                CHECK (status IN ('pending_onboarding', 'active_junior', 'active_senior', 'graduated')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_batches_status ON batches(status);
CREATE INDEX idx_batches_code   ON batches(batch_code);

COMMENT ON COLUMN batches.status IS
  'pending_onboarding: batch has arrived but students only have placeholder '
  'roll numbers (see users.reg_no_is_placeholder) — not yet fully onboarded. '
  'active_junior/active_senior/graduated follow the normal 2-year MCA lifecycle.';

-- ── users — one row per person, 1:1 with auth.users(id) ─────────────────────
CREATE TABLE users (
    id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email               TEXT NOT NULL UNIQUE,
    reg_no              TEXT NOT NULL UNIQUE,
    reg_no_is_placeholder BOOLEAN NOT NULL DEFAULT FALSE,
    name                TEXT NOT NULL,
    team_id             TEXT,                     -- legacy free-text team code, e.g. 'T20'
    batch               TEXT NOT NULL CHECK (batch IN ('G1', 'G2')),
    batch_id            UUID REFERENCES batches(id),
    gender              TEXT,
    dob                 DATE,
    role_label          TEXT NOT NULL DEFAULT 'Student'
                        CHECK (role_label IN ('Student', 'Faculty', 'Alumni', 'HOD')),
    roles               JSONB NOT NULL DEFAULT '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}',
    leetcode_username   TEXT,
    ecampus_password       TEXT DEFAULT NULL,
    ecampus_password_set   BOOLEAN NOT NULL DEFAULT FALSE,
    onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
    mentorship_open     BOOLEAN NOT NULL DEFAULT FALSE,
    show_birthday_publicly BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url          TEXT,
    linkedin_url        TEXT,
    github_url          TEXT,
    current_company     TEXT,
    current_role_title  TEXT,
    skills              TEXT[] NOT NULL DEFAULT '{}',
    -- Active academic arrears/backlogs, e.g. [{"subject": "DBMS", "status": "pending"}].
    -- Read by apps/web/app/student/recovery-hub/page.tsx; no write path exists yet
    -- (no admin UI populates this) — defaults empty, which is a real, correct
    -- state (no arrears) rather than the previous "column doesn't exist" error.
    arrears             JSONB NOT NULL DEFAULT '[]',
    birthday_notifications_enabled  BOOLEAN DEFAULT TRUE,
    leetcode_notifications_enabled  BOOLEAN DEFAULT TRUE,
    task_reminders_enabled          BOOLEAN DEFAULT TRUE,
    attendance_alerts_enabled       BOOLEAN DEFAULT TRUE,
    announcements_enabled           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email    ON users(email);
CREATE INDEX idx_users_reg_no   ON users(reg_no);
CREATE INDEX idx_users_team_id  ON users(team_id);
CREATE INDEX idx_users_batch    ON users(batch);
CREATE INDEX idx_users_batch_id ON users(batch_id);
CREATE INDEX idx_users_roles    ON users USING GIN(roles);

COMMENT ON COLUMN users.reg_no_is_placeholder IS
  'True for a student seeded before their real roll number was issued '
  '(e.g. a just-arrived batch). Faculty edits reg_no to the real value once '
  'known via the batch-import flow — no re-import or FK changes needed, '
  'since every other table joins on user_id, never reg_no.';

-- ── whitelist — pre-registration gate before a student''s first OTP login ───
CREATE TABLE whitelist (
    email               TEXT PRIMARY KEY,
    name                TEXT,
    reg_no              TEXT UNIQUE,
    reg_no_is_placeholder BOOLEAN NOT NULL DEFAULT FALSE,
    batch               TEXT,               -- 'G1'/'G2' legacy section code
    batch_id            UUID REFERENCES batches(id),
    team_id             TEXT,
    gender              TEXT,
    dob                 DATE,
    leetcode_username   TEXT,
    roles               JSONB,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_whitelist_email  ON whitelist(email);
CREATE INDEX idx_whitelist_reg_no ON whitelist(reg_no);

-- ── teams — Rep-configurable student teams (admin construct, UUID space) ────
CREATE TABLE teams (
    id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID    NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    team_name       TEXT    NOT NULL,
    team_leader_id  UUID    REFERENCES users(id),
    target_size     INT     NOT NULL DEFAULT 6 CHECK (target_size BETWEEN 3 AND 20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_teams_batch_id ON teams(batch_id);

-- ── user_permissions — fine-grained capability flags ────────────────────────
CREATE TABLE user_permissions (
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

CREATE INDEX idx_user_permissions_user ON user_permissions(user_id);

-- ── audit_logs ────────────────────────────────────────────────────────────
CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id    UUID REFERENCES users(id),
    action      TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id   UUID,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_actor_id   ON audit_logs(actor_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ── app_config — single-row remote version/maintenance config ───────────────
CREATE TABLE app_config (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    min_required_version  TEXT NOT NULL DEFAULT '1.0.0',
    latest_version        TEXT NOT NULL DEFAULT '1.0.0',
    force_update          BOOLEAN NOT NULL DEFAULT false,
    update_message        TEXT DEFAULT 'A new version of PSGMX is available.',
    github_release_url    TEXT DEFAULT 'https://github.com/psgmx/psgmx-flutter/releases/latest',
    android_download_url  TEXT,
    ios_download_url      TEXT,
    emergency_block        BOOLEAN NOT NULL DEFAULT false,
    emergency_message      TEXT DEFAULT 'App temporarily unavailable.',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by            TEXT
);

DO $$
BEGIN
    RAISE NOTICE '✅ 01_schema_core.sql complete — batches, users, whitelist, teams, user_permissions, audit_logs, app_config created.';
    RAISE NOTICE 'NEXT: run 02_schema_academic.sql';
END $$;
