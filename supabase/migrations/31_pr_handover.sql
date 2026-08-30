-- Atomic, batch-scoped PR handover. HOD/faculty cannot execute this operation.
CREATE OR REPLACE FUNCTION public.handover_placement_rep(
  p_outgoing_batch_code TEXT,
  p_incoming_batch_code TEXT,
  p_incoming_identity TEXT
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_outgoing UUID;
  v_incoming UUID;
  v_new_pr UUID;
BEGIN
  IF auth.uid() IS NULL OR v_actor IS NULL OR NOT public.is_placement_rep(v_actor) THEN
    RAISE EXCEPTION 'Placement Representative access required';
  END IF;
  SELECT id INTO v_outgoing FROM public.batches WHERE upper(batch_code) = upper(trim(p_outgoing_batch_code));
  SELECT id INTO v_incoming FROM public.batches WHERE upper(batch_code) = upper(trim(p_incoming_batch_code));
  IF v_outgoing IS NULL OR v_incoming IS NULL OR v_outgoing = v_incoming THEN RAISE EXCEPTION 'Select two valid batches'; END IF;
  IF public.get_user_batch_id(v_actor) <> v_outgoing THEN RAISE EXCEPTION 'You can hand over only your own batch'; END IF;
  SELECT id INTO v_new_pr FROM public.users
  WHERE batch_id = v_incoming AND role_label = 'Student'
    AND (upper(reg_no) = upper(trim(p_incoming_identity)) OR lower(email) = lower(trim(p_incoming_identity))
      OR lower(personal_email) = lower(trim(p_incoming_identity)) OR lower(college_email) = lower(trim(p_incoming_identity)))
  LIMIT 1;
  IF v_new_pr IS NULL THEN RAISE EXCEPTION 'Incoming PR must be a verified student in the incoming batch'; END IF;

  UPDATE public.users SET roles = COALESCE(roles, '{}'::jsonb) || '{"isPlacementRep": false}'::jsonb, updated_at = now()
  WHERE batch_id = v_outgoing AND COALESCE((roles->>'isPlacementRep')::boolean, false);
  UPDATE public.users SET roles = COALESCE(roles, '{}'::jsonb) || '{"isPlacementRep": true}'::jsonb, updated_at = now()
  WHERE id = v_new_pr;
  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
  VALUES (v_actor, 'PLACEMENT_REP_HANDOVER', 'users', v_new_pr,
    jsonb_build_object('outgoing_batch', upper(trim(p_outgoing_batch_code)), 'incoming_batch', upper(trim(p_incoming_batch_code))));
  RETURN jsonb_build_object('success', true, 'incoming_pr_id', v_new_pr);
END;
$$;
REVOKE ALL ON FUNCTION public.handover_placement_rep(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.handover_placement_rep(TEXT, TEXT, TEXT) TO authenticated;
