-- ─────────────────────────────────────────────────────────────────────────────
-- Migration 12: App Release Notes + app_config rollout columns
-- Purpose:
--   1. Add missing rollout-targeting columns to app_config
--   2. Create app_release_notes table (changelog shown in-app per version)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Patch app_config with rollout columns (idempotent) ─────────────────────
ALTER TABLE public.app_config
  ADD COLUMN IF NOT EXISTS rollout_stage     TEXT    NOT NULL DEFAULT 'full'
      CHECK (rollout_stage IN ('internal', 'batch', 'full')),
  ADD COLUMN IF NOT EXISTS enabled_batch_ids TEXT[]  NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS pilot_user_ids    TEXT[]  NOT NULL DEFAULT '{}';

-- ── 2. Release Notes table ───────────────────────────────────────────────────
-- Each row is the changelog for one release version.
-- The mobile app queries the entries newer than the previously-seen version
-- and shows them on first launch after an update.
CREATE TABLE IF NOT EXISTS public.app_release_notes (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    version      TEXT        NOT NULL UNIQUE,       -- e.g. "4.3.2"
    title        TEXT        NOT NULL,              -- e.g. "What's New in v4.3.2"
    highlights   TEXT[]      NOT NULL DEFAULT '{}', -- short bullet points
    description  TEXT,                             -- optional longer body text
    release_date DATE        NOT NULL DEFAULT CURRENT_DATE,
    platform     TEXT        NOT NULL DEFAULT 'all'
        CHECK (platform IN ('android', 'ios', 'all')),
    is_published BOOLEAN     NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_release_notes_version
    ON public.app_release_notes (version DESC);

-- ── 3. RLS for release notes (public read, admin write) ──────────────────────
ALTER TABLE public.app_release_notes ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read published notes
DROP POLICY IF EXISTS "release_notes_public_read" ON public.app_release_notes;
CREATE POLICY "release_notes_public_read"
    ON public.app_release_notes
    FOR SELECT
    TO authenticated
    USING (is_published = true);

-- Service-role (admin / CI pipeline) can insert/update
DROP POLICY IF EXISTS "release_notes_service_write" ON public.app_release_notes;
CREATE POLICY "release_notes_service_write"
    ON public.app_release_notes
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ── 4. Seed initial release note for v4.3.2 ──────────────────────────────────
INSERT INTO public.app_release_notes (version, title, highlights, description, release_date)
VALUES (
    '4.3.2',
    'What''s New in v4.3.2',
    ARRAY[
        '🔧 Fixed Communication Practice connectivity issues',
        '⚡ Faster startup with improved offline caching',
        '🛡️ Enhanced enterprise-grade security hardening',
        '🐛 Resolved flutter analyze warnings across the app',
        '📦 Improved CI/CD pipeline reliability'
    ],
    'This release focuses on stability, security, and developer experience improvements across the entire PSGMX platform.',
    '2026-09-27'
)
ON CONFLICT (version) DO UPDATE
    SET highlights   = EXCLUDED.highlights,
        description  = EXCLUDED.description,
        title        = EXCLUDED.title,
        is_published = true;

INSERT INTO public.app_release_notes (version, title, highlights, description, release_date)
VALUES (
    '4.3.3',
    'What''s New in v4.3.3',
    ARRAY[
        '🎉 New "What''s New" screen — see release highlights on every update',
        '📋 Release notes are now fetched live from the database',
        '🔒 Emergency block & force update screens properly wired for all platforms',
        '🗂️ Rollout targeting columns added to app_config (internal / batch / full)',
        '✅ Zero flutter analyze warnings — clean codebase'
    ],
    'Introducing in-app release notes! Every time you update, you''ll see exactly what changed — powered by the database, no hardcoding.',
    '2026-09-27'
)
ON CONFLICT (version) DO UPDATE
    SET highlights   = EXCLUDED.highlights,
        description  = EXCLUDED.description,
        title        = EXCLUDED.title,
        is_published = true;
