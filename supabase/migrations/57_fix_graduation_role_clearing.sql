-- ============================================================
-- PSGMX Migration 57 — 57_fix_graduation_role_clearing.sql
-- ============================================================
-- docs/batch-lifecycle.md ("What Happens to Each User on Graduation") is
-- explicit: Team Leader, Coordinator, and Placement Rep capabilities are
-- all cleared when a student becomes an alumnus. rotate_batch_status()
-- (20_scalable_batch_lifecycle.sql) — the function actually invoked nightly
-- by .github/workflows/daily-maintenance.yml via
-- apps/web/app/api/cron/daily-maintenance — only ever flips `role_label`
-- to 'Alumni'. It never touches `users.roles` (isPlacementRep /
-- isCoordinator / isTeamLeader) or the delegated rows in
-- `user_permissions`, so a PR/coordinator/team-leader whose batch
-- auto-graduates keeps every elevated capability indefinitely as an
-- alumnus — e.g. is_placement_rep() (06_functions.sql) still returns true
-- for them, since it reads only the `roles` JSONB this function never
-- clears.
--
-- This migration replaces the graduation branch to also clear the three
-- role flags and delete the associated user_permissions rows, mirroring
-- the same cleanup added to handover_placement_rep() in
-- 56_fix_batch_handover_actor.sql for the manual-handover path.
-- ============================================================

CREATE OR REPLACE FUNCTION public.rotate_batch_status()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_batch RECORD;
    v_next_status TEXT;
BEGIN
    FOR v_batch IN
        SELECT id, batch_code, start_year, end_year, status
        FROM public.batches
        ORDER BY start_year
        FOR UPDATE
    LOOP
        v_next_status := CASE
            WHEN CURRENT_DATE >= make_date(v_batch.end_year, 7, 1)
                THEN 'graduated'
            WHEN CURRENT_DATE >= make_date(v_batch.start_year + 1, 7, 1)
                THEN 'active_senior'
            WHEN CURRENT_DATE >= make_date(v_batch.start_year, 7, 1)
                THEN 'active_junior'
            ELSE 'pending_onboarding'
        END;

        IF v_batch.status IS DISTINCT FROM v_next_status THEN
            UPDATE public.batches
            SET status = v_next_status, updated_at = now()
            WHERE id = v_batch.id;

            INSERT INTO public.audit_logs (
                actor_id, action, entity_type, entity_id, metadata
            )
            SELECT u.id, 'BATCH_STATUS_CHANGED', 'batch', v_batch.id,
                   jsonb_build_object(
                       'batch_code', v_batch.batch_code,
                       'from', v_batch.status,
                       'to', v_next_status,
                       'changed_at', now()
                   )
            FROM public.users u
            WHERE u.role_label = 'HOD'
            ORDER BY u.created_at
            LIMIT 1;
        END IF;

        IF v_next_status = 'graduated' THEN
            UPDATE public.users
            SET role_label = 'Alumni',
                roles = COALESCE(roles, '{}'::jsonb)
                        || '{"isPlacementRep": false, "isCoordinator": false, "isTeamLeader": false}'::jsonb,
                updated_at = now()
            WHERE batch_id = v_batch.id
              AND role_label = 'Student';

            DELETE FROM public.user_permissions
            WHERE user_id IN (
                SELECT id FROM public.users WHERE batch_id = v_batch.id AND role_label = 'Alumni'
            )
            AND permission_key IN (
                'manage_members', 'configure_teams', 'schedule_placement_sessions',
                'mark_placement_attendance', 'publish_tasks', 'manage_company_records',
                'moderate_placement_log', 'view_batch_analytics'
            );
        END IF;
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.rotate_batch_status() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rotate_batch_status() TO service_role;

COMMENT ON FUNCTION public.rotate_batch_status() IS
  'Idempotently derives every MCA batch status from start/end year at the July 1 academic boundary, graduates student accounts, and clears PR/coordinator/team-leader capabilities + delegated permissions on graduation.';
