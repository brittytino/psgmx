-- ============================================================
-- PSGMX Migration 55 — 55_auto_lineage_trigger.sql
-- ============================================================
-- docs/batch-lifecycle.md ("Lineage and Alumni Matching") documents a live
-- trigger that fires when a student's `users` row is created: it extracts
-- the numeric suffix of `reg_no` (e.g. `25MX223` -> `223`), searches for a
-- prior-batch user with the same suffix, and inserts a `lineage_map` row.
--
-- That trigger has never existed. The only thing that has ever populated
-- `lineage_map` is the one-time hardcoded VALUES list in
-- 39_seed_alumni_and_lineage.sql, computed offline for the batches that
-- existed in August 2026 (19MX-26MX). Every batch onboarded after that —
-- 27MX through 31MX are already pre-seeded as `pending_onboarding` rows by
-- 20_scalable_batch_lifecycle.sql — will get zero lineage_map rows and no
-- assigned senior, because nothing ever runs the suffix match again.
--
-- This migration adds the real trigger, matching the suffix-matching
-- semantics the migration 39 seed already used (immediate closest prior
-- match by intake year), so it produces identical results automatically
-- for every batch from now on instead of requiring another hand-written
-- seed migration each year.
--
-- Design notes:
--   * Fires on the same event the docs describe: INSERT on `public.users`
--     (the logical student profile, created at first OTP login — see
--     handle_new_user() in 15_identity_batch_team_hardening.sql — not on
--     `whitelist`, which only holds the pre-login roster row).
--   * Also fires on UPDATE OF reg_no, because a freshly-imported batch can
--     carry a placeholder reg_no (see users.reg_no_is_placeholder) that a
--     faculty member corrects to the real value later; that correction is
--     an UPDATE, not an INSERT, and must also trigger a lineage match.
--   * "Prior batch" is derived from the two-digit intake year embedded in
--     reg_no itself (`25MX223` -> 25), not `users.batch_id`, so it works
--     even if batch_id hasn't been backfilled yet for a given row.
--   * Handles both directions: (a) the newly (re)matched user finding their
--     own senior among existing users, and (b) an existing later-batch user
--     who had no senior yet (because their senior hadn't logged in when
--     the junior first onboarded) now picking up the newly (re)matched user
--     as their senior, if it is a closer match than none at all.
--   * A one-time backfill at the end closes any gap for users created
--     since the migration 39 seed was written (e.g. late 26MX roster
--     corrections) without touching any student who already has a row.
-- ============================================================

CREATE OR REPLACE FUNCTION public.assign_lineage_senior()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_suffix   TEXT;
    v_year     INT;
    v_senior   UUID;
BEGIN
    -- Only real MCA register numbers participate (NNMXNNN). Placeholder
    -- reg_nos, faculty/HOD accounts, and malformed rows are skipped.
    IF NEW.reg_no IS NULL OR NEW.reg_no !~ '^[0-9]{2}MX[0-9]{3}$' THEN
        RETURN NEW;
    END IF;

    v_suffix := right(NEW.reg_no, 3);
    v_year   := left(NEW.reg_no, 2)::INT;

    -- (a) Find NEW's own senior: the closest existing user sharing the
    -- same suffix in a strictly earlier intake year.
    SELECT u.id INTO v_senior
    FROM public.users u
    WHERE u.id <> NEW.id
      AND u.reg_no ~ '^[0-9]{2}MX[0-9]{3}$'
      AND right(u.reg_no, 3) = v_suffix
      AND left(u.reg_no, 2)::INT < v_year
    ORDER BY left(u.reg_no, 2)::INT DESC
    LIMIT 1;

    IF v_senior IS NOT NULL THEN
        INSERT INTO public.lineage_map (student_id, senior_user_id, assigned_at)
        VALUES (NEW.id, v_senior, now())
        ON CONFLICT (student_id) DO UPDATE
            SET senior_user_id = EXCLUDED.senior_user_id,
                assigned_at = EXCLUDED.assigned_at
            WHERE public.lineage_map.senior_user_id IS DISTINCT FROM EXCLUDED.senior_user_id;
    END IF;

    -- (b) NEW may itself be the senior a later-batch user was waiting for:
    -- close the gap for any same-suffix, later-year user who still has no
    -- lineage_map row at all (their senior hadn't logged in yet when they
    -- first onboarded).
    INSERT INTO public.lineage_map (student_id, senior_user_id, assigned_at)
    SELECT j.id, NEW.id, now()
    FROM public.users j
    WHERE j.id <> NEW.id
      AND j.reg_no ~ '^[0-9]{2}MX[0-9]{3}$'
      AND right(j.reg_no, 3) = v_suffix
      AND left(j.reg_no, 2)::INT > v_year
      AND NOT EXISTS (
          SELECT 1 FROM public.lineage_map lm WHERE lm.student_id = j.id
      )
    ON CONFLICT (student_id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS assign_lineage_senior_trigger ON public.users;
CREATE TRIGGER assign_lineage_senior_trigger
AFTER INSERT OR UPDATE OF reg_no ON public.users
FOR EACH ROW EXECUTE FUNCTION public.assign_lineage_senior();

REVOKE ALL ON FUNCTION public.assign_lineage_senior() FROM PUBLIC;

-- One-time backfill: close any existing gap (e.g. a 26MX user created
-- after the migration 39 seed snapshot was written) without touching any
-- student who already has a lineage_map row.
INSERT INTO public.lineage_map (student_id, senior_user_id, assigned_at)
SELECT DISTINCT ON (j.id)
    j.id,
    s.id,
    now()
FROM public.users j
JOIN public.users s
    ON s.id <> j.id
   AND s.reg_no ~ '^[0-9]{2}MX[0-9]{3}$'
   AND right(s.reg_no, 3) = right(j.reg_no, 3)
   AND left(s.reg_no, 2)::INT < left(j.reg_no, 2)::INT
WHERE j.reg_no ~ '^[0-9]{2}MX[0-9]{3}$'
  AND NOT EXISTS (SELECT 1 FROM public.lineage_map lm WHERE lm.student_id = j.id)
ORDER BY j.id, left(s.reg_no, 2)::INT DESC
ON CONFLICT (student_id) DO NOTHING;

DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT count(*) INTO v_count FROM public.lineage_map;
    RAISE NOTICE '✅ Migration 55 complete: % total lineage_map rows after backfill.', v_count;
END $$;
