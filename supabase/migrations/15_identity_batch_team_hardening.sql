-- ============================================================
-- PSGMX — 15_identity_batch_team_hardening.sql
-- ============================================================
-- Incremental, data-preserving hardening for an already-running database.
--
-- 1. One logical student can authenticate with personal and college email.
-- 2. Batch-scoped rows are protected by restrictive RLS policies.
-- 3. Teams get one canonical UUID while legacy team codes remain compatible.
-- 4. Rollout controls are stored with the existing app configuration.
--
-- Run AFTER 14_seed_placement_23mx_24mx.sql. Do not re-run 00_reset.sql on a
-- database containing real student data.
-- ============================================================

BEGIN;

-- ── Dual-email logical identity ──────────────────────────────────────────

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS personal_email TEXT,
    ADD COLUMN IF NOT EXISTS college_email TEXT;

ALTER TABLE public.whitelist
    ADD COLUMN IF NOT EXISTS personal_email TEXT,
    ADD COLUMN IF NOT EXISTS college_email TEXT;

UPDATE public.users
SET college_email = email
WHERE college_email IS NULL
  AND lower(email) LIKE '%@psgtech.ac.in';

UPDATE public.users
SET personal_email = email
WHERE personal_email IS NULL
  AND lower(email) NOT LIKE '%@psgtech.ac.in';

UPDATE public.whitelist
SET college_email = email
WHERE college_email IS NULL
  AND lower(email) LIKE '%@psgtech.ac.in';

UPDATE public.whitelist
SET personal_email = email
WHERE personal_email IS NULL
  AND lower(email) NOT LIKE '%@psgtech.ac.in';

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_personal_email_unique
    ON public.users (lower(personal_email)) WHERE personal_email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_college_email_unique
    ON public.users (lower(college_email)) WHERE college_email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_whitelist_personal_email_unique
    ON public.whitelist (lower(personal_email)) WHERE personal_email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_whitelist_college_email_unique
    ON public.whitelist (lower(college_email)) WHERE college_email IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.whitelist_email_aliases (
    email           TEXT PRIMARY KEY,
    whitelist_email TEXT NOT NULL REFERENCES public.whitelist(email) ON DELETE CASCADE,
    email_type      TEXT NOT NULL CHECK (email_type IN ('personal', 'college')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.whitelist_email_aliases
    DROP CONSTRAINT IF EXISTS whitelist_email_aliases_whitelist_email_fkey;
ALTER TABLE public.whitelist_email_aliases
    ADD CONSTRAINT whitelist_email_aliases_whitelist_email_fkey
    FOREIGN KEY (whitelist_email) REFERENCES public.whitelist(email)
    ON UPDATE CASCADE ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS idx_whitelist_aliases_lower_email
    ON public.whitelist_email_aliases (lower(email));

INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
SELECT lower(w.email), w.email,
       CASE WHEN lower(w.email) LIKE '%@psgtech.ac.in' THEN 'college' ELSE 'personal' END
FROM public.whitelist w
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
SELECT lower(w.personal_email), w.email, 'personal'
FROM public.whitelist w
WHERE w.personal_email IS NOT NULL
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
SELECT lower(w.college_email), w.email, 'college'
FROM public.whitelist w
WHERE w.college_email IS NOT NULL
ON CONFLICT (email) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.user_auth_identities (
    auth_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    email        TEXT NOT NULL,
    email_type   TEXT NOT NULL CHECK (email_type IN ('personal', 'college')),
    verified_at  TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_auth_identities_lower_email
    ON public.user_auth_identities (lower(email));
CREATE INDEX IF NOT EXISTS idx_user_auth_identities_user_id
    ON public.user_auth_identities (user_id);

INSERT INTO public.user_auth_identities (auth_user_id, user_id, email, email_type, verified_at)
SELECT u.id, u.id, lower(u.email),
       CASE WHEN lower(u.email) LIKE '%@psgtech.ac.in' THEN 'college' ELSE 'personal' END,
       au.email_confirmed_at
FROM public.users u
JOIN auth.users au ON au.id = u.id
ON CONFLICT (auth_user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        (SELECT i.user_id FROM public.user_auth_identities i WHERE i.auth_user_id = auth.uid()),
        auth.uid()
    );
$$;

REVOKE ALL ON FUNCTION public.current_user_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_id() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS SETOF public.users
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT * FROM public.users WHERE id = public.current_user_id();
$$;

REVOKE ALL ON FUNCTION public.get_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated, service_role;

-- The first accepted email creates the logical profile. A later accepted
-- email for the same whitelist row only creates another auth mapping.
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
BEGIN
    SELECT * INTO v_alias
    FROM public.whitelist_email_aliases
    WHERE lower(email) = lower(NEW.email)
    LIMIT 1;

    IF v_alias IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT * INTO v_wl FROM public.whitelist WHERE email = v_alias.whitelist_email;

    SELECT id INTO v_user_id
    FROM public.users
    WHERE reg_no = v_wl.reg_no
    LIMIT 1;

    IF v_user_id IS NULL THEN
        INSERT INTO public.users (
            id, email, personal_email, college_email, reg_no,
            reg_no_is_placeholder, name, team_id, batch, batch_id, gender,
            roles, leetcode_username, dob
        ) VALUES (
            NEW.id, lower(NEW.email), v_wl.personal_email, v_wl.college_email,
            v_wl.reg_no, COALESCE(v_wl.reg_no_is_placeholder, false), v_wl.name,
            v_wl.team_id, COALESCE(v_wl.batch, 'G1'), v_wl.batch_id, v_wl.gender,
            COALESCE(v_wl.roles, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
            v_wl.leetcode_username, v_wl.dob
        )
        RETURNING id INTO v_user_id;
    ELSE
        UPDATE public.users
        SET personal_email = COALESCE(v_wl.personal_email, personal_email),
            college_email = COALESCE(v_wl.college_email, college_email),
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

-- Keep aliases synchronized when a roster row is added or receives its
-- college email later.
CREATE OR REPLACE FUNCTION public.sync_whitelist_email_aliases()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
    VALUES (
        lower(NEW.email), NEW.email,
        CASE WHEN lower(NEW.email) LIKE '%@psgtech.ac.in' THEN 'college' ELSE 'personal' END
    )
    ON CONFLICT (email) DO NOTHING;

    IF NEW.personal_email IS NOT NULL THEN
        INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
        VALUES (lower(NEW.personal_email), NEW.email, 'personal')
        ON CONFLICT (email) DO NOTHING;
    END IF;

    IF NEW.college_email IS NOT NULL THEN
        INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
        VALUES (lower(NEW.college_email), NEW.email, 'college')
        ON CONFLICT (email) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_whitelist_email_aliases_trigger ON public.whitelist;
CREATE TRIGGER sync_whitelist_email_aliases_trigger
AFTER INSERT OR UPDATE OF email, personal_email, college_email ON public.whitelist
FOR EACH ROW EXECUTE FUNCTION public.sync_whitelist_email_aliases();

-- ── Canonical UUID team mapping (legacy code kept as compatibility data) ──

ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS team_code TEXT;
UPDATE public.teams
SET team_code = COALESCE(team_code, 'TEAM-' || left(id::text, 8))
WHERE team_code IS NULL;
ALTER TABLE public.teams ALTER COLUMN team_code SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_teams_batch_code_unique
    ON public.teams(batch_id, team_code);

INSERT INTO public.teams (batch_id, team_name, team_code)
SELECT DISTINCT w.batch_id, w.team_id, w.team_id
FROM public.whitelist w
WHERE w.batch_id IS NOT NULL AND w.team_id IS NOT NULL
ON CONFLICT (batch_id, team_code) DO NOTHING;

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS team_uuid UUID REFERENCES public.teams(id) ON DELETE SET NULL;
ALTER TABLE public.whitelist ADD COLUMN IF NOT EXISTS team_uuid UUID REFERENCES public.teams(id) ON DELETE SET NULL;

UPDATE public.users u
SET team_uuid = t.id
FROM public.teams t
WHERE u.team_uuid IS NULL AND t.batch_id = u.batch_id AND t.team_code = u.team_id;

UPDATE public.whitelist w
SET team_uuid = t.id
FROM public.teams t
WHERE w.team_uuid IS NULL AND t.batch_id = w.batch_id AND t.team_code = w.team_id;

CREATE INDEX IF NOT EXISTS idx_users_team_uuid ON public.users(team_uuid);
CREATE INDEX IF NOT EXISTS idx_whitelist_team_uuid ON public.whitelist(team_uuid);

CREATE OR REPLACE FUNCTION public.sync_user_team_code()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.team_uuid IS NOT NULL THEN
        SELECT team_code INTO NEW.team_id FROM public.teams WHERE id = NEW.team_uuid;
    ELSIF NEW.team_id IS NOT NULL THEN
        SELECT id INTO NEW.team_uuid
        FROM public.teams
        WHERE batch_id = NEW.batch_id AND team_code = NEW.team_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_users_team_code_trigger ON public.users;
CREATE TRIGGER sync_users_team_code_trigger
BEFORE INSERT OR UPDATE OF team_uuid, team_id, batch_id ON public.users
FOR EACH ROW EXECUTE FUNCTION public.sync_user_team_code();

CREATE OR REPLACE FUNCTION public.get_user_team_uuid(p_user_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$ SELECT team_uuid FROM public.users WHERE id = p_user_id $$;

CREATE OR REPLACE FUNCTION public.assign_team_member(p_user_id UUID, p_team_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID := public.current_user_id();
    v_target_batch UUID;
    v_team_batch UUID;
BEGIN
    SELECT batch_id INTO v_target_batch FROM public.users WHERE id = p_user_id;
    SELECT batch_id INTO v_team_batch FROM public.teams WHERE id = p_team_id;

    IF v_target_batch IS NULL OR v_team_batch IS NULL OR v_target_batch <> v_team_batch THEN
        RAISE EXCEPTION 'Student and team must belong to the same batch';
    END IF;

    IF NOT (public.is_faculty_or_hod(v_actor) OR
            (public.is_placement_rep(v_actor) AND public.get_user_batch_id(v_actor) = v_target_batch) OR
            public.user_has_permission(v_actor, 'configure_teams')) THEN
        RAISE EXCEPTION 'Not authorized to assign this team';
    END IF;

    UPDATE public.users SET team_uuid = p_team_id, updated_at = now() WHERE id = p_user_id;
    UPDATE public.whitelist w
       SET team_uuid = p_team_id, team_id = (SELECT team_code FROM public.teams WHERE id = p_team_id)
     WHERE w.reg_no = (SELECT reg_no FROM public.users WHERE id = p_user_id);

    INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
    VALUES (v_actor, 'TEAM_MEMBER_ASSIGNED', 'user', p_user_id, jsonb_build_object('team_id', p_team_id));
END;
$$;

CREATE OR REPLACE FUNCTION public.set_team_leader(p_team_id UUID, p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID := public.current_user_id();
    v_batch UUID;
    v_previous UUID;
BEGIN
    SELECT batch_id, team_leader_id INTO v_batch, v_previous FROM public.teams WHERE id = p_team_id FOR UPDATE;

    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id AND batch_id = v_batch) THEN
        RAISE EXCEPTION 'Leader must belong to the team batch';
    END IF;

    IF NOT (public.is_faculty_or_hod(v_actor) OR
            (public.is_placement_rep(v_actor) AND public.get_user_batch_id(v_actor) = v_batch) OR
            public.user_has_permission(v_actor, 'configure_teams')) THEN
        RAISE EXCEPTION 'Not authorized to set this leader';
    END IF;

    IF v_previous IS NOT NULL AND v_previous <> p_user_id THEN
        UPDATE public.users
        SET roles = jsonb_set(roles, '{isTeamLeader}', 'false'::jsonb), updated_at = now()
        WHERE id = v_previous;
    END IF;

    PERFORM public.assign_team_member(p_user_id, p_team_id);
    UPDATE public.users
       SET roles = jsonb_set(roles, '{isTeamLeader}', 'true'::jsonb), updated_at = now()
     WHERE id = p_user_id;
    UPDATE public.teams SET team_leader_id = p_user_id, updated_at = now() WHERE id = p_team_id;

    INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
    VALUES (v_actor, 'TEAM_LEADER_SET', 'team', p_team_id, jsonb_build_object('user_id', p_user_id));
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_team_uuid(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_team_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_team_leader(UUID, UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_member_permissions(p_user_id UUID, p_permissions TEXT[])
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID := public.current_user_id();
    v_batch UUID;
    v_key TEXT;
    v_allowed CONSTANT TEXT[] := ARRAY[
        'manage_members', 'configure_teams', 'schedule_placement_sessions',
        'mark_placement_attendance', 'publish_tasks', 'manage_company_records',
        'moderate_placement_log', 'view_batch_analytics'
    ];
BEGIN
    SELECT batch_id INTO v_batch FROM public.users WHERE id = p_user_id;
    IF v_batch IS NULL THEN RAISE EXCEPTION 'Member not found'; END IF;
    IF NOT (public.is_faculty_or_hod(v_actor) OR
            (public.is_placement_rep(v_actor) AND public.get_user_batch_id(v_actor) = v_batch)) THEN
        RAISE EXCEPTION 'Not authorized to manage this member';
    END IF;

    IF EXISTS (SELECT 1 FROM unnest(p_permissions) p WHERE NOT (p = ANY(v_allowed))) THEN
        RAISE EXCEPTION 'Unknown permission';
    END IF;

    DELETE FROM public.user_permissions WHERE user_id = p_user_id;
    FOREACH v_key IN ARRAY p_permissions LOOP
        INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
        VALUES (p_user_id, v_key, v_actor);
    END LOOP;

    INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, batch_id, metadata)
    VALUES (v_actor, 'MEMBER_PERMISSIONS_UPDATED', 'user', p_user_id, v_batch,
            jsonb_build_object('permissions', p_permissions));
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_member_permissions(UUID, TEXT[]) TO authenticated;

-- Placement Reps own the complete operational console for their batch. These
-- are operational capabilities only; faculty/HOD governance remains separate.
INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
SELECT u.id, p.permission_key, u.id
FROM public.users u
CROSS JOIN unnest(ARRAY[
    'manage_members', 'configure_teams', 'schedule_placement_sessions',
    'mark_placement_attendance', 'publish_tasks', 'manage_company_records',
    'moderate_placement_log', 'view_batch_analytics'
]) AS p(permission_key)
WHERE COALESCE((u.roles->>'isPlacementRep')::boolean, false)
ON CONFLICT (user_id, permission_key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.ensure_rep_permissions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF COALESCE((NEW.roles->>'isPlacementRep')::boolean, false) THEN
        INSERT INTO public.user_permissions(user_id, permission_key, granted_by)
        SELECT NEW.id, p.permission_key, NEW.id FROM unnest(ARRAY[
            'manage_members', 'configure_teams', 'schedule_placement_sessions',
            'mark_placement_attendance', 'publish_tasks', 'manage_company_records',
            'moderate_placement_log', 'view_batch_analytics'
        ]) AS p(permission_key)
        ON CONFLICT (user_id, permission_key) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ensure_rep_permissions_trigger ON public.users;
CREATE TRIGGER ensure_rep_permissions_trigger
AFTER INSERT OR UPDATE OF roles ON public.users
FOR EACH ROW EXECUTE FUNCTION public.ensure_rep_permissions();

-- ── Batch scope and rollout columns ──────────────────────────────────────

ALTER TABLE public.daily_tasks ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id);
ALTER TABLE public.scheduled_attendance_dates ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id);
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id);
ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id);
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id);

UPDATE public.daily_tasks d SET batch_id = u.batch_id FROM public.users u
WHERE d.batch_id IS NULL AND d.uploaded_by = u.id;
UPDATE public.scheduled_attendance_dates d SET batch_id = u.batch_id FROM public.users u
WHERE d.batch_id IS NULL AND d.scheduled_by = u.id;
UPDATE public.notifications n SET batch_id = u.batch_id FROM public.users u
WHERE n.batch_id IS NULL AND n.created_by = u.id;
UPDATE public.announcements a SET batch_id = u.batch_id FROM public.users u
WHERE a.batch_id IS NULL AND a.created_by = u.id;
UPDATE public.audit_logs a SET batch_id = u.batch_id FROM public.users u
WHERE a.batch_id IS NULL AND a.actor_id = u.id;

ALTER TABLE public.daily_tasks DROP CONSTRAINT IF EXISTS daily_tasks_date_topic_type_key;
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_tasks_batch_date_topic
    ON public.daily_tasks(batch_id, date, topic_type) NULLS NOT DISTINCT;
ALTER TABLE public.scheduled_attendance_dates DROP CONSTRAINT IF EXISTS scheduled_attendance_dates_date_key;
CREATE UNIQUE INDEX IF NOT EXISTS idx_scheduled_dates_batch_date
    ON public.scheduled_attendance_dates(batch_id, date) NULLS NOT DISTINCT;

ALTER TABLE public.app_config
    ADD COLUMN IF NOT EXISTS rollout_stage TEXT NOT NULL DEFAULT 'internal'
        CHECK (rollout_stage IN ('internal', 'pilot', 'batch', 'full')),
    ADD COLUMN IF NOT EXISTS enabled_batch_ids UUID[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS pilot_user_ids UUID[] NOT NULL DEFAULT '{}';

CREATE OR REPLACE FUNCTION public.can_access_batch(p_batch_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.is_faculty_or_hod(public.current_user_id())
        OR p_batch_id IS NULL
        OR p_batch_id = public.get_user_batch_id(public.current_user_id());
$$;

REVOKE ALL ON FUNCTION public.can_access_batch(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_access_batch(UUID) TO authenticated, service_role;

-- Existing policies were authored when auth.uid() and the logical student id
-- were identical. Rewrite those expressions so either accepted email reaches
-- the same student rows and permissions.
DO $$
DECLARE
    p RECORD;
    v_sql TEXT;
BEGIN
    FOR p IN
        SELECT schemaname, tablename, policyname, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public'
          AND (COALESCE(qual, '') LIKE '%auth.uid()%'
               OR COALESCE(with_check, '') LIKE '%auth.uid()%')
    LOOP
        v_sql := format('ALTER POLICY %I ON %I.%I', p.policyname, p.schemaname, p.tablename);
        IF p.qual IS NOT NULL THEN
            v_sql := v_sql || ' USING (' || replace(p.qual, 'auth.uid()', 'current_user_id()') || ')';
        END IF;
        IF p.with_check IS NOT NULL THEN
            v_sql := v_sql || ' WITH CHECK (' || replace(p.with_check, 'auth.uid()', 'current_user_id()') || ')';
        END IF;
        EXECUTE v_sql;
    END LOOP;
END $$;

-- RPC authorization checks also assumed auth.uid() was the profile id. Keep
-- their public signatures stable while making the implementation alias-aware.
DO $$
DECLARE
    f RECORD;
    v_definition TEXT;
BEGIN
    FOR f IN
        SELECT p.oid, p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          -- pg_proc also contains aggregates and window functions.
          -- pg_get_functiondef() raises 42809 for those objects, so only
          -- inspect ordinary functions here.
          AND p.prokind = 'f'
          AND p.proname <> 'current_user_id'
    LOOP
        v_definition := pg_get_functiondef(f.oid);
        IF v_definition LIKE '%auth.uid()%' THEN
            v_definition := replace(v_definition, 'auth.uid()', 'public.current_user_id()');
            EXECUTE v_definition;
        END IF;
    END LOOP;
END $$;

-- Restrictive policies are AND-ed with the existing capability policies.
-- This closes cross-batch reads/writes without duplicating every role rule.
DROP POLICY IF EXISTS users_batch_boundary ON public.users;
DROP POLICY IF EXISTS whitelist_batch_boundary ON public.whitelist;
DROP POLICY IF EXISTS teams_batch_boundary ON public.teams;
DROP POLICY IF EXISTS daily_tasks_batch_boundary ON public.daily_tasks;
DROP POLICY IF EXISTS companies_batch_boundary ON public.companies;
DROP POLICY IF EXISTS placement_sessions_batch_boundary ON public.placement_sessions;
DROP POLICY IF EXISTS scheduled_dates_batch_boundary ON public.scheduled_attendance_dates;
DROP POLICY IF EXISTS notifications_batch_boundary ON public.notifications;
DROP POLICY IF EXISTS announcements_batch_boundary ON public.announcements;
DROP POLICY IF EXISTS audit_logs_batch_boundary ON public.audit_logs;
DROP POLICY IF EXISTS permissions_batch_boundary ON public.user_permissions;
DROP POLICY IF EXISTS completions_batch_boundary ON public.task_completions;
DROP POLICY IF EXISTS defaulters_batch_boundary ON public.defaulter_flags;
DROP POLICY IF EXISTS streaks_batch_boundary ON public.daily_five_streaks;
DROP POLICY IF EXISTS attempts_batch_boundary ON public.daily_five_attempts;
DROP POLICY IF EXISTS readiness_batch_boundary ON public.readiness_scores;
DROP POLICY IF EXISTS attendance_batch_boundary ON public.attendance_records;
DROP POLICY IF EXISTS placement_attendance_batch_boundary ON public.placement_attendance;
DROP POLICY IF EXISTS placement_log_batch_boundary ON public.placement_log_entries;
DROP POLICY IF EXISTS leetcode_batch_boundary ON public.leetcode_stats;

CREATE POLICY users_batch_boundary ON public.users AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY whitelist_batch_boundary ON public.whitelist AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY teams_batch_boundary ON public.teams AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY daily_tasks_batch_boundary ON public.daily_tasks AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY companies_batch_boundary ON public.companies AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY placement_sessions_batch_boundary ON public.placement_sessions AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY scheduled_dates_batch_boundary ON public.scheduled_attendance_dates AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY notifications_batch_boundary ON public.notifications AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY announcements_batch_boundary ON public.announcements AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));
CREATE POLICY audit_logs_batch_boundary ON public.audit_logs AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(batch_id)) WITH CHECK (public.can_access_batch(batch_id));

CREATE POLICY permissions_batch_boundary ON public.user_permissions AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY completions_batch_boundary ON public.task_completions AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY defaulters_batch_boundary ON public.defaulter_flags AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY streaks_batch_boundary ON public.daily_five_streaks AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY attempts_batch_boundary ON public.daily_five_attempts AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY readiness_batch_boundary ON public.readiness_scores AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY attendance_batch_boundary ON public.attendance_records AS RESTRICTIVE FOR ALL TO authenticated
USING (public.can_access_batch(public.get_user_batch_id(user_id)))
WITH CHECK (public.can_access_batch(public.get_user_batch_id(user_id)));
CREATE POLICY placement_attendance_batch_boundary ON public.placement_attendance AS RESTRICTIVE FOR ALL TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.placement_sessions s
    WHERE s.id = session_id AND public.can_access_batch(s.batch_id)
)) WITH CHECK (EXISTS (
    SELECT 1 FROM public.placement_sessions s
    WHERE s.id = session_id AND public.can_access_batch(s.batch_id)
));
CREATE POLICY placement_log_batch_boundary ON public.placement_log_entries AS RESTRICTIVE FOR ALL TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.companies c
    WHERE c.id = company_id AND public.can_access_batch(c.batch_id)
)) WITH CHECK (EXISTS (
    SELECT 1 FROM public.companies c
    WHERE c.id = company_id AND public.can_access_batch(c.batch_id)
));
CREATE POLICY leetcode_batch_boundary ON public.leetcode_stats AS RESTRICTIVE FOR ALL TO authenticated
USING (
    public.is_faculty_or_hod(public.current_user_id()) OR EXISTS (
        SELECT 1 FROM public.users u
        WHERE lower(u.leetcode_username) = lower(username)
          AND public.can_access_batch(u.batch_id)
    )
) WITH CHECK (
    public.is_faculty_or_hod(public.current_user_id()) OR EXISTS (
        SELECT 1 FROM public.users u
        WHERE lower(u.leetcode_username) = lower(username)
          AND public.can_access_batch(u.batch_id)
    )
);

-- The original view ran with owner privileges. Recreate it as an invoker view
-- so the restrictive batch policies on users/sessions/attendance are honored.
DROP VIEW IF EXISTS public.placement_attendance_summary;
CREATE VIEW public.placement_attendance_summary
WITH (security_invoker = true) AS
SELECT
    u.id AS user_id,
    u.batch_id,
    COUNT(ps.id) AS eligible_sessions,
    COUNT(pa.session_id) FILTER (WHERE pa.status = 'present') AS attended_sessions,
    CASE WHEN COUNT(ps.id) = 0 THEN 0
         ELSE ROUND(COUNT(pa.session_id) FILTER (WHERE pa.status = 'present') * 100.0 / COUNT(ps.id), 2)
    END AS attendance_pct
FROM public.users u
JOIN public.placement_sessions ps ON ps.batch_id = u.batch_id
    AND (ps.target_team_ids IS NULL OR u.team_id = ANY(ps.target_team_ids))
LEFT JOIN public.placement_attendance pa ON pa.session_id = ps.id AND pa.user_id = u.id
GROUP BY u.id, u.batch_id;

GRANT SELECT ON public.placement_attendance_summary TO authenticated;

-- Keep the Today score fresh after meaningful activity; the nightly cron in
-- 07 remains the reconciliation backstop.
CREATE OR REPLACE FUNCTION public.recompute_readiness_after_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    IF TG_TABLE_NAME = 'leetcode_stats' THEN
        SELECT id INTO v_user_id FROM public.users
        WHERE lower(leetcode_username) = lower(NEW.username) LIMIT 1;
    ELSE
        v_user_id := NEW.user_id;
    END IF;
    IF v_user_id IS NOT NULL THEN PERFORM public.compute_readiness_score(v_user_id); END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS readiness_after_daily_five ON public.daily_five_attempts;
CREATE TRIGGER readiness_after_daily_five
AFTER INSERT OR UPDATE OF submitted_at ON public.daily_five_attempts
FOR EACH ROW WHEN (NEW.submitted_at IS NOT NULL)
EXECUTE FUNCTION public.recompute_readiness_after_activity();

DROP TRIGGER IF EXISTS readiness_after_task_completion ON public.task_completions;
CREATE TRIGGER readiness_after_task_completion
AFTER INSERT OR UPDATE OF completed, verified_at ON public.task_completions
FOR EACH ROW EXECUTE FUNCTION public.recompute_readiness_after_activity();

DROP TRIGGER IF EXISTS readiness_after_placement_attendance ON public.placement_attendance;
CREATE TRIGGER readiness_after_placement_attendance
AFTER INSERT OR UPDATE OF status ON public.placement_attendance
FOR EACH ROW EXECUTE FUNCTION public.recompute_readiness_after_activity();

DROP TRIGGER IF EXISTS readiness_after_leetcode_sync ON public.leetcode_stats;
CREATE TRIGGER readiness_after_leetcode_sync
AFTER INSERT OR UPDATE OF total_solved, weekly_score ON public.leetcode_stats
FOR EACH ROW EXECUTE FUNCTION public.recompute_readiness_after_activity();

-- Mapping/alias tables are never client-listable. A user may only see their
-- own accepted identities through this narrow view.
ALTER TABLE public.whitelist_email_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_auth_identities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS identities_read_own ON public.user_auth_identities;
CREATE POLICY identities_read_own ON public.user_auth_identities FOR SELECT TO authenticated
USING (user_id = public.current_user_id());

CREATE OR REPLACE VIEW public.my_email_identities
WITH (security_invoker = true) AS
SELECT email, email_type, verified_at
FROM public.user_auth_identities
WHERE user_id = public.current_user_id();

GRANT SELECT ON public.my_email_identities TO authenticated;
GRANT SELECT ON public.user_auth_identities TO authenticated;

DO $$
BEGIN
    RAISE NOTICE '15 complete: dual-email identity, canonical team mapping, batch boundaries, rollout controls.';
END $$;

COMMIT;
