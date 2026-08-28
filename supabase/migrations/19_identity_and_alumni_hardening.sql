-- ============================================================
-- PSGMX — 19_identity_and_alumni_hardening.sql
-- ============================================================
-- Data-preserving release migration for v4.0.1.
-- 1. Completes the 26MX331 identity.
-- 2. Pre-registers the deterministic college identity for every 26MX row.
-- 3. Keeps both identities attached to one logical profile.
-- 4. Seeds recent graduated batches used by OTP alumni enrollment.
-- ============================================================

BEGIN;

ALTER TABLE public.whitelist
    ADD COLUMN IF NOT EXISTS role_label TEXT NOT NULL DEFAULT 'Student';

ALTER TABLE public.whitelist
    DROP CONSTRAINT IF EXISTS whitelist_role_label_check;
ALTER TABLE public.whitelist
    ADD CONSTRAINT whitelist_role_label_check
    CHECK (role_label IN ('Student', 'Faculty', 'Alumni', 'HOD'));

CREATE OR REPLACE FUNCTION public.mca_college_email(p_reg_no TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT CASE
        WHEN upper(trim(p_reg_no)) ~ '^[0-9]{2}MX[0-9]{3}$'
        THEN lower(trim(p_reg_no)) || '@psgtech.ac.in'
        ELSE NULL
    END;
$$;

-- The final missing 26MX personal identity.
UPDATE public.whitelist
SET email = 'nareshwaran703@gmail.com',
    personal_email = 'nareshwaran703@gmail.com',
    college_email = '26mx331@psgtech.ac.in',
    name = 'NARESHWARAN J'
WHERE reg_no = '26MX331';

-- Register college identities before the institution activates the inboxes.
UPDATE public.whitelist
SET college_email = public.mca_college_email(reg_no)
WHERE reg_no ~ '^26MX[0-9]{3}$'
  AND college_email IS DISTINCT FROM public.mca_college_email(reg_no);

-- Keep profiles that have already logged in synchronized with the roster.
UPDATE public.users u
SET personal_email = COALESCE(w.personal_email, u.personal_email),
    college_email = COALESCE(w.college_email, u.college_email),
    updated_at = now()
FROM public.whitelist w
WHERE u.reg_no = w.reg_no
  AND w.reg_no ~ '^26MX[0-9]{3}$';

-- Be explicit as well as trigger-driven, making the migration idempotent.
INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
SELECT lower(w.personal_email), w.email, 'personal'
FROM public.whitelist w
WHERE w.reg_no ~ '^26MX[0-9]{3}$' AND w.personal_email IS NOT NULL
ON CONFLICT (email) DO UPDATE
SET whitelist_email = EXCLUDED.whitelist_email, email_type = EXCLUDED.email_type;

INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
SELECT lower(w.college_email), w.email, 'college'
FROM public.whitelist w
WHERE w.reg_no ~ '^26MX[0-9]{3}$' AND w.college_email IS NOT NULL
ON CONFLICT (email) DO UPDATE
SET whitelist_email = EXCLUDED.whitelist_email, email_type = EXCLUDED.email_type;

DELETE FROM public.whitelist_email_aliases
WHERE email = 'pending+26mx331@roster.psgmx.invalid';

-- Recent historical cohorts available for alumni enrollment. Older valid MCA
-- batches are created safely by the enrollment endpoint when first required.
INSERT INTO public.batches (batch_code, start_year, end_year, status) VALUES
    ('20MX', 2020, 2022, 'graduated'),
    ('21MX', 2021, 2023, 'graduated'),
    ('22MX', 2022, 2024, 'graduated')
ON CONFLICT (batch_code) DO UPDATE
SET start_year = EXCLUDED.start_year,
    end_year = EXCLUDED.end_year,
    status = 'graduated',
    updated_at = now();

GRANT EXECUTE ON FUNCTION public.mca_college_email(TEXT) TO authenticated, service_role;

COMMIT;
