-- ============================================================
-- PSGMX Migration 27 — external sync history and free-tier maintenance
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.leetcode_stat_snapshots (
  username TEXT NOT NULL REFERENCES public.leetcode_stats(username) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_solved INTEGER NOT NULL DEFAULT 0,
  easy_solved INTEGER NOT NULL DEFAULT 0,
  medium_solved INTEGER NOT NULL DEFAULT 0,
  hard_solved INTEGER NOT NULL DEFAULT 0,
  ranking INTEGER NOT NULL DEFAULT 0,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(username, snapshot_date)
);

ALTER TABLE public.leetcode_stat_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY leetcode_snapshots_authenticated_read ON public.leetcode_stat_snapshots
  FOR SELECT TO authenticated USING (true);

CREATE OR REPLACE FUNCTION public.run_daily_maintenance()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user RECORD;
  v_scores INTEGER := 0;
  v_birthdays INTEGER := 0;
BEGIN
  DELETE FROM public.otp_rate_log WHERE sent_at < now() - interval '24 hours';
  v_birthdays := public.send_birthday_notifications();

  FOR v_user IN
    SELECT u.id FROM public.users u
    JOIN public.batches b ON b.id = u.batch_id
    WHERE u.role_label = 'Student' AND b.status IN ('active_junior', 'active_senior')
  LOOP
    PERFORM public.compute_readiness_score(v_user.id);
    v_scores := v_scores + 1;
  END LOOP;
  RETURN jsonb_build_object('readiness_scores_computed', v_scores, 'birthday_notifications', v_birthdays);
END;
$$;

REVOKE ALL ON FUNCTION public.run_daily_maintenance() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.run_daily_maintenance() TO service_role;

COMMIT;
