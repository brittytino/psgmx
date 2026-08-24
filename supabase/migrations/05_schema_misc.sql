-- ============================================================
-- PSGMX — 05_schema_misc.sql
-- ============================================================
-- Announcements/notifications, the eCampus (PSG Bunker) scraper-cache
-- tables, and misc security-hardening support tables.
--
-- Run AFTER 04_schema_knowledge_fyp.sql.
-- ============================================================

-- ── notifications ─────────────────────────────────────────────────────────
CREATE TABLE notifications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title               TEXT NOT NULL,
    message             TEXT NOT NULL,
    notification_type   TEXT NOT NULL CHECK (notification_type IN ('motivation', 'reminder', 'alert', 'announcement', 'birthday')),
    tone                TEXT CHECK (tone IN ('serious', 'friendly', 'humorous')),
    -- 'user' = a personal notification, addressed via created_by (e.g. birthday messages)
    target_audience     TEXT NOT NULL CHECK (target_audience IN ('all', 'students', 'team_leaders', 'coordinators', 'placement_reps', 'G1', 'G2', 'user')),
    generated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until         TIMESTAMPTZ,
    created_by          UUID REFERENCES users(id),
    is_active           BOOLEAN NOT NULL DEFAULT true
);

-- ── announcements ─────────────────────────────────────────────────────────
CREATE TABLE announcements (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        TEXT NOT NULL,
    message      TEXT NOT NULL,
    is_priority  BOOLEAN NOT NULL DEFAULT FALSE,
    expiry_date  TIMESTAMPTZ,
    created_by   UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX idx_announcements_priority   ON announcements(is_priority DESC);

-- ── notification_reads — per-user read/dismiss tracking ─────────────────────
CREATE TABLE notification_reads (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id  UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dismissed_at     TIMESTAMPTZ,
    UNIQUE(notification_id, user_id)
);

-- ── otp_rate_log — audit visibility on top of Supabase Auth's own limiter ───
CREATE TABLE otp_rate_log (
    id       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    email    TEXT        NOT NULL,
    sent_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_rate_log_email_time ON otp_rate_log (email, sent_at DESC);

-- RLS enabled, deliberately ZERO policies below — no client role (anon or
-- authenticated) should ever read or write raw OTP-send email/timestamp
-- pairs; service_role (which bypasses RLS) is the only writer.
ALTER TABLE otp_rate_log ENABLE ROW LEVEL SECURITY;

-- ── user_ecampus_credentials — encrypted eCampus portal password ────────────
CREATE TABLE user_ecampus_credentials (
  user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  encrypted_password  BYTEA NOT NULL,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE user_ecampus_credentials IS
  'eCampus portal password, encrypted with pgcrypto (pgp_sym_encrypt). '
  'No RLS policies granted to authenticated/anon — service_role only. '
  'The encryption key is a database-level setting '
  '(app.ecampus_encryption_key) set once by an admin, never shipped to '
  'any client — only the SECURITY DEFINER functions in 06_functions.sql '
  'ever read it.';

-- RLS enabled, deliberately ZERO policies below — same reasoning as
-- otp_rate_log above. This is intentionally stricter than a
-- `USING (false)` policy: there is no policy to misread.
ALTER TABLE user_ecampus_credentials ENABLE ROW LEVEL SECURITY;

-- ── ecampus_attendance / ecampus_cgpa — scraper cache, one row per student ──
CREATE TABLE ecampus_attendance (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no     TEXT NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB  NOT NULL,           -- {subjects: [...], summary: {...}}
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ecampus_att_reg_no    ON ecampus_attendance(reg_no);
CREATE INDEX idx_ecampus_att_synced_at ON ecampus_attendance(synced_at DESC);
CREATE INDEX idx_ecampus_att_pct ON ecampus_attendance ((data->'summary'->>'overall_percentage'));

CREATE TABLE ecampus_cgpa (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no     TEXT NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB  NOT NULL,           -- {cgpa, semester_sgpa: [...], courses: [...], ...}
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ecampus_cgpa_reg_no    ON ecampus_cgpa(reg_no);
CREATE INDEX idx_ecampus_cgpa_synced_at ON ecampus_cgpa(synced_at DESC);
CREATE INDEX idx_ecampus_cgpa_val ON ecampus_cgpa ((data->>'cgpa'));

CREATE VIEW v_ecampus_attendance_summary
WITH (security_invoker = true) AS
SELECT
    ea.reg_no,
    u.name,
    (ea.data->'summary'->>'total_hours')::int         AS total_hours,
    (ea.data->'summary'->>'total_present')::int        AS total_present,
    (ea.data->'summary'->>'overall_percentage')::numeric AS overall_pct,
    (ea.data->'summary'->>'overall_can_bunk')::int     AS can_bunk,
    (ea.data->'summary'->>'overall_need_attend')::int  AS need_attend,
    ea.synced_at
FROM ecampus_attendance ea
JOIN users u ON u.reg_no = ea.reg_no;

CREATE VIEW v_ecampus_cgpa_summary
WITH (security_invoker = true) AS
SELECT
    ec.reg_no,
    u.name,
    (ec.data->>'cgpa')::numeric            AS cgpa,
    (ec.data->>'total_credits')::int       AS total_credits,
    ec.data->>'latest_semester'            AS latest_semester,
    (ec.data->>'total_semesters')::int     AS total_semesters,
    ec.synced_at
FROM ecampus_cgpa ec
JOIN users u ON u.reg_no = ec.reg_no;

-- ── ecampus_bunked_subjects — per-subject bunk detail ────────────────────
CREATE TABLE ecampus_bunked_subjects (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no        TEXT NOT NULL REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    course_code   TEXT NOT NULL,
    course_title  TEXT,
    total_hours   INT NOT NULL DEFAULT 0,
    total_present INT NOT NULL DEFAULT 0,
    percentage    NUMERIC,
    can_bunk      INT NOT NULL DEFAULT 0,
    need_attend   INT NOT NULL DEFAULT 0,
    synced_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (reg_no, course_code)
);

CREATE INDEX idx_ecampus_bunked_reg_no    ON ecampus_bunked_subjects(reg_no);
CREATE INDEX idx_ecampus_bunked_synced_at ON ecampus_bunked_subjects(synced_at DESC);

-- ── ecampus_ca_marks — Continuous Assessment internal marks ─────────────────
CREATE TABLE ecampus_ca_marks (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no     TEXT        NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB       NOT NULL DEFAULT '{}',
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ecampus_ca_reg_no    ON ecampus_ca_marks(reg_no);
CREATE INDEX idx_ecampus_ca_synced_at ON ecampus_ca_marks(synced_at DESC);

-- ── ecampus_ca_timetable — per-student CA test timetable ────────────────────
CREATE TABLE ecampus_ca_timetable (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reg_no     TEXT        NOT NULL UNIQUE REFERENCES whitelist(reg_no) ON DELETE CASCADE,
    data       JSONB       NOT NULL DEFAULT '{}',
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ecampus_ca_tt_reg_no    ON ecampus_ca_timetable(reg_no);
CREATE INDEX idx_ecampus_ca_tt_synced_at ON ecampus_ca_timetable(synced_at DESC);

-- ── ca_timetable_global — one shared CA timetable for the whole batch ───────
CREATE TABLE ca_timetable_global (
    id         INT         PRIMARY KEY DEFAULT 1,
    data       JSONB       NOT NULL DEFAULT '{}',
    synced_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_by  TEXT,           -- reg_no of the placement rep who triggered the sync
    CONSTRAINT single_row CHECK (id = 1)
);

DO $$
BEGIN
    RAISE NOTICE '✅ 05_schema_misc.sql complete — all tables created.';
    RAISE NOTICE 'NEXT: run 06_functions.sql';
END $$;
