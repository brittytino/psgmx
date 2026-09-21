-- ============================================================
-- PSGMX Migration 56 — 56_fix_batch_handover_actor.sql
-- ============================================================
-- docs/user-flow.md Chapter 6.2 ("The Batch Handover Ceremony") and Chapter
-- 19's capability table are explicit: only the HOD (governance_admin) may
-- initiate a batch handover. A Placement Rep cannot. The web UI is built
-- exactly that way — /faculty/batch-management is HOD-only (see
-- ROLE_GUARDS in apps/web/proxy.ts), and its "Execute Batch Graduation &
-- PR Handover" button posts to /api/cron/yearly-transition, which already
-- requires requireAppRole(req, 'hod') before calling this RPC.
--
-- But 31_pr_handover.sql's handover_placement_rep() independently required
-- the *caller* to already be a placement rep of the outgoing batch
-- (`is_placement_rep(v_actor)` + `get_user_batch_id(v_actor) = v_outgoing`)
-- — a leftover from an earlier "PR self-hands-over" design the comment on
-- that migration still names ("HOD/faculty cannot execute this
-- operation"). Since an HOD is never a placement rep, every call from the
-- only real, correctly-gated call site always raised "Placement
-- Representative access required." The documented handover ceremony has
-- therefore never been able to complete.
--
-- This migration re-points the actor check at is_governance_admin()
-- (21_companion_product_model.sql — true for the current HOD and for any
-- faculty explicitly holding the 'governance_admin' permission, matching
-- Chapter 8.3's "former HODs retain governance access" rule) and drops the
-- now-meaningless "your own batch" restriction, since the actor is a
-- department-level governance holder, not a batch-scoped PR.
--
-- It also accepts an optional outgoing-PR identity so the caller's
-- nomination (captured in the web UI's Step 1 but never previously
-- validated) is checked against who currently holds the PR capability in
-- the outgoing batch, catching a typo'd nomination before it silently
-- no-ops instead of failing loudly.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handover_placement_rep(
  p_outgoing_batch_code TEXT,
  p_incoming_batch_code TEXT,
  p_incoming_identity TEXT,
  p_outgoing_identity TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_outgoing UUID;
  v_incoming UUID;
  v_new_pr UUID;
  v_outgoing_pr_count INT;
BEGIN
  IF auth.uid() IS NULL OR v_actor IS NULL OR NOT public.is_governance_admin(v_actor) THEN
    RAISE EXCEPTION 'Governance (HOD) access required';
  END IF;

  SELECT id INTO v_outgoing FROM public.batches WHERE upper(batch_code) = upper(trim(p_outgoing_batch_code));
  SELECT id INTO v_incoming FROM public.batches WHERE upper(batch_code) = upper(trim(p_incoming_batch_code));
  IF v_outgoing IS NULL OR v_incoming IS NULL OR v_outgoing = v_incoming THEN RAISE EXCEPTION 'Select two valid batches'; END IF;

  IF p_outgoing_identity IS NOT NULL AND trim(p_outgoing_identity) <> '' THEN
    SELECT count(*) INTO v_outgoing_pr_count
    FROM public.users
    WHERE batch_id = v_outgoing
      AND COALESCE((roles->>'isPlacementRep')::boolean, false)
      AND (upper(reg_no) = upper(trim(p_outgoing_identity)) OR lower(email) = lower(trim(p_outgoing_identity))
        OR lower(personal_email) = lower(trim(p_outgoing_identity)) OR lower(college_email) = lower(trim(p_outgoing_identity)));
    IF v_outgoing_pr_count = 0 THEN
      RAISE EXCEPTION 'Outgoing PR identity does not match the current Placement Rep of the outgoing batch';
    END IF;
  END IF;

  SELECT id INTO v_new_pr FROM public.users
  WHERE batch_id = v_incoming AND role_label = 'Student'
    AND (upper(reg_no) = upper(trim(p_incoming_identity)) OR lower(email) = lower(trim(p_incoming_identity))
      OR lower(personal_email) = lower(trim(p_incoming_identity)) OR lower(college_email) = lower(trim(p_incoming_identity)))
  LIMIT 1;
  IF v_new_pr IS NULL THEN RAISE EXCEPTION 'Incoming PR must be a verified student in the incoming batch'; END IF;

  UPDATE public.users SET roles = COALESCE(roles, '{}'::jsonb) || '{"isPlacementRep": false}'::jsonb, updated_at = now()
  WHERE batch_id = v_outgoing AND COALESCE((roles->>'isPlacementRep')::boolean, false);
  -- The role flag flip above has no corresponding cleanup trigger for
  -- user_permissions (ensure_rep_permissions_trigger only ever INSERTs
  -- rows when isPlacementRep turns true; nothing deletes them when it
  -- turns false), so without this the outgoing PR silently keeps every
  -- delegated permission (manage_members, publish_tasks, etc.) after
  -- losing the isPlacementRep flag.
  DELETE FROM public.user_permissions
  WHERE user_id IN (SELECT id FROM public.users WHERE batch_id = v_outgoing)
    AND permission_key IN (
      'manage_members', 'configure_teams', 'schedule_placement_sessions',
      'mark_placement_attendance', 'publish_tasks', 'manage_company_records',
      'moderate_placement_log', 'view_batch_analytics'
    );
  UPDATE public.users SET roles = COALESCE(roles, '{}'::jsonb) || '{"isPlacementRep": true}'::jsonb, updated_at = now()
  WHERE id = v_new_pr;
  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
  VALUES (v_actor, 'PLACEMENT_REP_HANDOVER', 'users', v_new_pr,
    jsonb_build_object('outgoing_batch', upper(trim(p_outgoing_batch_code)), 'incoming_batch', upper(trim(p_incoming_batch_code)), 'outgoing_identity', p_outgoing_identity));
  RETURN jsonb_build_object('success', true, 'incoming_pr_id', v_new_pr);
END;
$$;

REVOKE ALL ON FUNCTION public.handover_placement_rep(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.handover_placement_rep(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- The old 3-arg overload is no longer called by any route (see
-- apps/web/app/api/cron/yearly-transition/route.ts, updated alongside this
-- migration to pass the 4th argument) — drop it so a stale client can't
-- silently hit the old PR-self-service authorization path.
DROP FUNCTION IF EXISTS public.handover_placement_rep(TEXT, TEXT, TEXT);
