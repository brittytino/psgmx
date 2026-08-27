-- ============================================================
-- PSGMX — 18_seed_faculty.sql
-- ============================================================
-- MCA staff roster for OTP login. Dr. Ilayaraja N is current HOD;
-- Dr. Chitra A keeps HOD access as previous HOD.
-- Also completes first-login for already-rostered 25MX/26MX students
-- so OTP can land on the dashboard instead of a broken onboarding loop.
--
-- Run AFTER 16_seed_students_26mx.sql.
-- ============================================================

GRANT ALL PRIVILEGES ON TABLE public.whitelist TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.whitelist_email_aliases TO postgres, service_role;
GRANT ALL PRIVILEGES ON TABLE public.user_auth_identities TO postgres, service_role;

BEGIN;

ALTER TABLE public.whitelist
    ADD COLUMN IF NOT EXISTS role_label TEXT NOT NULL DEFAULT 'Student';

ALTER TABLE public.whitelist
    DROP CONSTRAINT IF EXISTS whitelist_role_label_check;
ALTER TABLE public.whitelist
    ADD CONSTRAINT whitelist_role_label_check
    CHECK (role_label IN ('Student', 'Faculty', 'Alumni', 'HOD'));

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_alias public.whitelist_email_aliases%ROWTYPE;
    v_wl public.whitelist%ROWTYPE;
    v_user_id UUID;
    v_role TEXT;
    v_roles JSONB;
BEGIN
    SELECT * INTO v_alias
    FROM public.whitelist_email_aliases
    WHERE lower(email) = lower(NEW.email)
    LIMIT 1;

    IF v_alias IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT * INTO v_wl FROM public.whitelist WHERE email = v_alias.whitelist_email;

    v_role := COALESCE(v_wl.role_label, 'Student');
    IF v_role IN ('Faculty', 'HOD') THEN
        v_roles := '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb;
    ELSE
        v_roles := COALESCE(
            v_wl.roles,
            '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb
        );
    END IF;

    SELECT id INTO v_user_id
    FROM public.users
    WHERE reg_no = v_wl.reg_no
    LIMIT 1;

    IF v_user_id IS NULL THEN
        INSERT INTO public.users (
            id, email, personal_email, college_email, reg_no,
            reg_no_is_placeholder, name, team_id, batch, batch_id, gender,
            role_label, roles, leetcode_username, dob, onboarding_complete
        ) VALUES (
            NEW.id, lower(NEW.email), v_wl.personal_email, v_wl.college_email,
            v_wl.reg_no, COALESCE(v_wl.reg_no_is_placeholder, false), v_wl.name,
            v_wl.team_id, COALESCE(v_wl.batch, 'G1'), v_wl.batch_id, v_wl.gender,
            v_role, v_roles, v_wl.leetcode_username, v_wl.dob, TRUE
        )
        RETURNING id INTO v_user_id;
    ELSE
        UPDATE public.users
        SET personal_email = COALESCE(v_wl.personal_email, personal_email),
            college_email = COALESCE(v_wl.college_email, college_email),
            role_label = COALESCE(v_wl.role_label, role_label),
            roles = CASE
                WHEN COALESCE(v_wl.role_label, role_label) IN ('Faculty', 'HOD') THEN v_roles
                ELSE roles
            END,
            onboarding_complete = TRUE,
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    INSERT INTO public.user_auth_identities (
        auth_user_id, user_id, email, email_type, verified_at
    ) VALUES (
        NEW.id, v_user_id, lower(NEW.email), v_alias.email_type, NEW.email_confirmed_at
    )
    ON CONFLICT (auth_user_id) DO UPDATE
       SET user_id = EXCLUDED.user_id,
           email = EXCLUDED.email,
           email_type = EXCLUDED.email_type,
           verified_at = COALESCE(EXCLUDED.verified_at, public.user_auth_identities.verified_at);

    RETURN NEW;
END;
$$;

INSERT INTO public.whitelist (
    email, college_email, name, reg_no, batch, role_label, roles
) VALUES
    ('ac.mca@psgtech.ac.in',  'ac.mca@psgtech.ac.in',  'Dr. Chitra A',            'FAC-AC',  'G1', 'HOD',     '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('vur.mca@psgtech.ac.in', 'vur.mca@psgtech.ac.in', 'Dr. Umarani V',           'FAC-VUR', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('nir.mca@psgtech.ac.in', 'nir.mca@psgtech.ac.in', 'Dr. Ilayaraja N',         'FAC-NIR', 'G1', 'HOD',     '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('sng.mca@psgtech.ac.in', 'sng.mca@psgtech.ac.in', 'Dr. Geetha N',            'FAC-SNG', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('sba.mca@psgtech.ac.in', 'sba.mca@psgtech.ac.in', 'Dr. Bhama S',             'FAC-SBA', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('vvn.mca@psgtech.ac.in', 'vvn.mca@psgtech.ac.in', 'Dr. Venkatesan V',        'FAC-VVN', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('abh.mca@psgtech.ac.in', 'abh.mca@psgtech.ac.in', 'Dr. Bhuvaneswari A',      'FAC-ABH', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('vrm.mca@psgtech.ac.in', 'vrm.mca@psgtech.ac.in', 'Dr. Manavalan R',         'FAC-VRM', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('jgt.mca@psgtech.ac.in', 'jgt.mca@psgtech.ac.in', 'Mrs. Gowri Thangam J',    'FAC-JGT', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('msa.mca@psgtech.ac.in', 'msa.mca@psgtech.ac.in', 'Dr. Subathra M',          'FAC-MSA', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('jaa.mca@psgtech.ac.in', 'jaa.mca@psgtech.ac.in', 'Mrs. Aarthi J',           'FAC-JAA', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('asa.mca@psgtech.ac.in', 'asa.mca@psgtech.ac.in', 'Mrs. Aarthi Mai A S',     'FAC-ASA', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('tdg.mca@psgtech.ac.in', 'tdg.mca@psgtech.ac.in', 'Mrs. Gayathri Devi T',    'FAC-TDG', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('ran.mca@psgtech.ac.in', 'ran.mca@psgtech.ac.in', 'Mrs. Aruna R',            'FAC-RAN', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('akk.mca@psgtech.ac.in', 'akk.mca@psgtech.ac.in', 'Mrs. Kalyani A',          'FAC-AKK', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('amr.mca@psgtech.ac.in', 'amr.mca@psgtech.ac.in', 'Mrs. Manoranjitham A',    'FAC-AMR', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('nrj.mca@psgtech.ac.in', 'nrj.mca@psgtech.ac.in', 'Mrs. Rajeswari N',        'FAC-NRJ', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('csc.mca@psgtech.ac.in', 'csc.mca@psgtech.ac.in', 'Mr. Sundar C',            'FAC-CSC', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
    ('sss.mca@psgtech.ac.in', 'sss.mca@psgtech.ac.in', 'Mr. Shankar S',           'FAC-SSS', 'G1', 'Faculty', '{"isStudent": false, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (email) DO UPDATE SET
    college_email = EXCLUDED.college_email,
    name = EXCLUDED.name,
    reg_no = EXCLUDED.reg_no,
    batch = EXCLUDED.batch,
    role_label = EXCLUDED.role_label,
    roles = EXCLUDED.roles;

-- Existing student/faculty rows that already logged in once were stuck
-- because onboarding never flipped this flag.
UPDATE public.users
SET onboarding_complete = TRUE,
    updated_at = now()
WHERE onboarding_complete IS DISTINCT FROM TRUE;

DO $$
DECLARE
    faculty_count INT;
    hod_count INT;
BEGIN
    SELECT COUNT(*) INTO faculty_count
    FROM public.whitelist
    WHERE role_label IN ('Faculty', 'HOD');

    SELECT COUNT(*) INTO hod_count
    FROM public.whitelist
    WHERE role_label = 'HOD';

    IF faculty_count <> 19 THEN
        RAISE EXCEPTION 'Faculty seed failed: expected 19 staff rows, found %', faculty_count;
    END IF;
    IF hod_count <> 2 THEN
        RAISE EXCEPTION 'HOD seed failed: expected 2 HOD rows, found %', hod_count;
    END IF;

    RAISE NOTICE '18_seed_faculty.sql complete — % staff, % HOD.', faculty_count, hod_count;
END $$;

COMMIT;
