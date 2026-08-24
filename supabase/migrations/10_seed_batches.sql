-- ============================================================
-- PSGMX — 10_seed_batches.sql
-- ============================================================
-- Seeds all four MCA batches this system currently needs to know about,
-- plus the default app_config row.
--
-- Status reasoning as of the time this was written (batches are a 2-year
-- MCA program):
--   23MX (2023-2025) — graduated, alumni.
--   24MX (2024-2026) — graduated (placement-drive data in 14_seed_placement_23mx_24mx.sql
--                       is historical record of their 2nd-year placement season).
--   25MX (2025-2027) — active_senior, the current fully-onboarded batch
--                       (real students seeded in 13_seed_students_25mx.sql).
--   26MX (2026-2028) — pending_onboarding: batch has arrived but only has
--                       placeholder roll numbers so far (per reg_no_is_placeholder).
--                       No student rows are seeded for them yet — there is no
--                       source data for individual 26MX students anywhere in
--                       this repo, unlike 23MX/24MX/25MX. Once real names and
--                       roll numbers exist, add them via the faculty
--                       batch-import flow (apps/web/app/api/faculty/batch-import),
--                       then flip this batch's status to 'active_junior'.
--
-- Adjust status/years here if the real academic calendar differs.
--
-- Run AFTER 09_grants_security.sql.
-- ============================================================

INSERT INTO batches (batch_code, start_year, end_year, status) VALUES
    ('23MX', 2023, 2025, 'graduated'),
    ('24MX', 2024, 2026, 'graduated'),
    ('25MX', 2025, 2027, 'active_senior'),
    ('26MX', 2026, 2028, 'pending_onboarding')
ON CONFLICT (batch_code) DO NOTHING;

INSERT INTO app_config (
    min_required_version, latest_version, force_update, update_message,
    github_release_url, emergency_block
) VALUES (
    '1.0.0', '1.2.0', false,
    'A new version of PSGMX is available! Update now to get the latest features and improvements.',
    'https://github.com/psgmx/psgmx-flutter/releases/latest', false
) ON CONFLICT DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE '✅ 10_seed_batches.sql complete — 23MX/24MX/25MX/26MX seeded, app_config initialized.';
    RAISE NOTICE 'NEXT: run 11_seed_question_bank.sql';
END $$;
