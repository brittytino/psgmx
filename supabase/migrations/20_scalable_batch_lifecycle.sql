-- ============================================================
-- PSGMX 20 — scalable five-batch lifecycle
-- ============================================================
-- Keeps cohort state derived from academic years instead of relying on a
-- chain of one-off promotions. July 1 is the lifecycle boundary.

INSERT INTO public.batches (batch_code, start_year, end_year, status)
SELECT
    right(start_year::text, 2) || 'MX',
    start_year,
    start_year + 2,
    'pending_onboarding'
FROM generate_series(2027, 2031) AS start_year
ON CONFLICT (batch_code) DO UPDATE
SET start_year = EXCLUDED.start_year,
    end_year = EXCLUDED.end_year,
    updated_at = now();

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
            SET role_label = 'Alumni', updated_at = now()
            WHERE batch_id = v_batch.id
              AND role_label = 'Student';
        END IF;
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.rotate_batch_status() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rotate_batch_status() TO service_role;

SELECT public.rotate_batch_status();

COMMENT ON FUNCTION public.rotate_batch_status() IS
  'Idempotently derives every MCA batch status from start/end year at the July 1 academic boundary and graduates student accounts.';
