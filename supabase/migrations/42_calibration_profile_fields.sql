-- ============================================================
-- PSGMX Migration 42 — 42_calibration_profile_fields.sql
-- ============================================================
-- The mobile onboarding calibration step (PRD Ch. 3.2, Step 4) is supposed
-- to capture: target role family, a per-dimension confidence rating (4
-- dimensions, 3-point scale), practice days available per week, and a
-- preferred reminder window. None of that has ever had a column to land in
-- — the existing calibration screen asked three unrelated engagement
-- questions and threw its result away downstream. This adds the real
-- columns, matching the flat-column style already used on `users`.
-- ============================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS target_role_family TEXT
    CHECK (target_role_family IN ('product_engineering', 'service_engineering', 'research', 'undecided')),
  ADD COLUMN IF NOT EXISTS confidence_aptitude SMALLINT CHECK (confidence_aptitude BETWEEN 1 AND 3),
  ADD COLUMN IF NOT EXISTS confidence_coding SMALLINT CHECK (confidence_coding BETWEEN 1 AND 3),
  ADD COLUMN IF NOT EXISTS confidence_core_cs SMALLINT CHECK (confidence_core_cs BETWEEN 1 AND 3),
  ADD COLUMN IF NOT EXISTS confidence_communication SMALLINT CHECK (confidence_communication BETWEEN 1 AND 3),
  ADD COLUMN IF NOT EXISTS practice_days_per_week SMALLINT CHECK (practice_days_per_week BETWEEN 1 AND 7),
  ADD COLUMN IF NOT EXISTS reminder_window TEXT
    CHECK (reminder_window IN ('morning', 'afternoon', 'evening'));
