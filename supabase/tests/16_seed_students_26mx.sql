-- Run after migrations 15 and 16 in a disposable/local database.
-- The transaction is rolled back and never changes persistent data.
BEGIN;

DO $$
DECLARE
    v_batch_id UUID;
    v_total INT;
    v_g1 INT;
    v_g2 INT;
    v_otp_ready INT;
    v_pending_email INT;
    v_aliases INT;
    v_status TEXT;
BEGIN
    SELECT id, status INTO v_batch_id, v_status
    FROM public.batches
    WHERE batch_code = '26MX';

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE batch = 'G1'),
        COUNT(*) FILTER (WHERE batch = 'G2'),
        COUNT(*) FILTER (WHERE personal_email IS NOT NULL),
        COUNT(*) FILTER (WHERE personal_email IS NULL AND college_email IS NULL)
    INTO v_total, v_g1, v_g2, v_otp_ready, v_pending_email
    FROM public.whitelist
    WHERE batch_id = v_batch_id;

    SELECT COUNT(*) INTO v_aliases
    FROM public.whitelist_email_aliases a
    JOIN public.whitelist w ON w.email = a.whitelist_email
    WHERE w.batch_id = v_batch_id;

    IF v_total <> 117 OR v_g1 <> 59 OR v_g2 <> 58 THEN
        RAISE EXCEPTION '26MX roster totals are invalid: total %, G1 %, G2 %', v_total, v_g1, v_g2;
    END IF;
    IF v_otp_ready <> 117 OR v_pending_email <> 0 THEN
        RAISE EXCEPTION '26MX email readiness is invalid: ready %, pending %', v_otp_ready, v_pending_email;
    END IF;
    IF v_aliases <> 235 THEN
        RAISE EXCEPTION '26MX should have 235 approved aliases, found %', v_aliases;
    END IF;
    IF v_status <> 'active_junior' THEN
        RAISE EXCEPTION '26MX should be active_junior, found %', v_status;
    END IF;
END $$;

ROLLBACK;
