-- ============================================================
-- PSGMX — 37_auto_provision_profile_hardening.sql
-- ============================================================
-- Auto-provisions missing public.users profile when auth.users
-- row pre-exists or when handle_new_user trigger did not fire.
-- Guarantees get_my_profile() always returns the student profile.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS SETOF public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_email TEXT;
    v_wl public.whitelist%ROWTYPE;
    v_alias public.whitelist_email_aliases%ROWTYPE;
BEGIN
    v_user_id := public.current_user_id();

    -- If profile already exists in public.users, return it immediately
    IF EXISTS (SELECT 1 FROM public.users WHERE id = v_user_id) THEN
        RETURN QUERY SELECT * FROM public.users WHERE id = v_user_id;
        RETURN;
    END IF;

    -- Auto-provision: If auth.uid() is authenticated but missing in public.users
    SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
    IF v_email IS NOT NULL THEN
        SELECT * INTO v_alias FROM public.whitelist_email_aliases WHERE lower(email) = lower(v_email) LIMIT 1;
        IF v_alias IS NOT NULL THEN
            SELECT * INTO v_wl FROM public.whitelist WHERE email = v_alias.whitelist_email LIMIT 1;
            IF v_wl IS NOT NULL THEN
                INSERT INTO public.users (
                    id, email, personal_email, college_email, reg_no,
                    reg_no_is_placeholder, name, team_id, batch, batch_id, gender,
                    role_label, roles, leetcode_username, dob, onboarding_complete
                ) VALUES (
                    auth.uid(), lower(v_email), v_wl.personal_email, v_wl.college_email,
                    v_wl.reg_no, COALESCE(v_wl.reg_no_is_placeholder, false), v_wl.name,
                    v_wl.team_id, COALESCE(v_wl.batch, 'G1'), v_wl.batch_id, v_wl.gender,
                    COALESCE(v_wl.role_label, 'Student'),
                    COALESCE(v_wl.roles, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
                    v_wl.leetcode_username, v_wl.dob, TRUE
                )
                ON CONFLICT (id) DO UPDATE SET updated_at = now();

                INSERT INTO public.user_auth_identities (
                    auth_user_id, user_id, email, email_type, verified_at
                ) VALUES (
                    auth.uid(), auth.uid(), lower(v_email), v_alias.email_type, now()
                )
                ON CONFLICT (auth_user_id) DO NOTHING;

                RETURN QUERY SELECT * FROM public.users WHERE id = auth.uid();
                RETURN;
            END IF;
        END IF;
    END IF;

    RETURN QUERY SELECT * FROM public.users WHERE id = v_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated, service_role;

-- Also run an immediate sync to provision any existing auth.users into public.users
DO $$
DECLARE
    r RECORD;
    v_wl public.whitelist%ROWTYPE;
    v_alias public.whitelist_email_aliases%ROWTYPE;
BEGIN
    FOR r IN SELECT id, email, email_confirmed_at FROM auth.users WHERE email IS NOT NULL LOOP
        SELECT * INTO v_alias FROM public.whitelist_email_aliases WHERE lower(email) = lower(r.email) LIMIT 1;
        IF v_alias IS NOT NULL THEN
            SELECT * INTO v_wl FROM public.whitelist WHERE email = v_alias.whitelist_email LIMIT 1;
            IF v_wl IS NOT NULL THEN
                INSERT INTO public.users (
                    id, email, personal_email, college_email, reg_no,
                    reg_no_is_placeholder, name, team_id, batch, batch_id, gender,
                    role_label, roles, leetcode_username, dob, onboarding_complete
                ) VALUES (
                    r.id, lower(r.email), v_wl.personal_email, v_wl.college_email,
                    v_wl.reg_no, COALESCE(v_wl.reg_no_is_placeholder, false), v_wl.name,
                    v_wl.team_id, COALESCE(v_wl.batch, 'G1'), v_wl.batch_id, v_wl.gender,
                    COALESCE(v_wl.role_label, 'Student'),
                    COALESCE(v_wl.roles, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
                    v_wl.leetcode_username, v_wl.dob, TRUE
                )
                ON CONFLICT (id) DO NOTHING;

                INSERT INTO public.user_auth_identities (
                    auth_user_id, user_id, email, email_type, verified_at
                ) VALUES (
                    r.id, r.id, lower(r.email), v_alias.email_type, COALESCE(r.email_confirmed_at, now())
                )
                ON CONFLICT (auth_user_id) DO NOTHING;
            END IF;
        END IF;
    END LOOP;
END $$;
