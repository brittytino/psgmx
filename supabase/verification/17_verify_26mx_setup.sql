-- ============================================================
-- PSGMX — Supabase dashboard verification for migrations 15 and 16
-- ============================================================
-- Read-only. Run after 15_identity_batch_team_hardening.sql and
-- 16_seed_students_26mx.sql. It raises an error if a required object or
-- roster invariant is missing, then returns compact status summaries.
-- ============================================================

DO $$
DECLARE
    v_batch_id UUID;
    v_status TEXT;
    v_total INT;
    v_g1 INT;
    v_g2 INT;
    v_otp_ready INT;
    v_pending_email INT;
    v_aliases INT;
BEGIN
    SELECT id, status INTO v_batch_id, v_status
    FROM public.batches
    WHERE batch_code = '26MX';

    IF v_batch_id IS NULL THEN
        RAISE EXCEPTION '26MX batch row is missing';
    END IF;
    IF v_status <> 'active_junior' THEN
        RAISE EXCEPTION '26MX should be active_junior, found %', v_status;
    END IF;
    IF to_regclass('public.whitelist_email_aliases') IS NULL
       OR to_regclass('public.user_auth_identities') IS NULL THEN
        RAISE EXCEPTION 'Migration 15 identity tables are missing';
    END IF;
    IF to_regprocedure('public.current_user_id()') IS NULL
       OR to_regprocedure('public.get_my_profile()') IS NULL THEN
        RAISE EXCEPTION 'Migration 15 logical-identity functions are missing';
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'users'
          AND policyname = 'users_batch_boundary'
          AND permissive = 'RESTRICTIVE'
    ) THEN
        RAISE EXCEPTION 'Strict users batch boundary policy is missing';
    END IF;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE batch = 'G1'),
        COUNT(*) FILTER (WHERE batch = 'G2'),
        COUNT(*) FILTER (WHERE personal_email IS NOT NULL OR college_email IS NOT NULL),
        COUNT(*) FILTER (WHERE personal_email IS NULL AND college_email IS NULL)
    INTO v_total, v_g1, v_g2, v_otp_ready, v_pending_email
    FROM public.whitelist
    WHERE batch_id = v_batch_id;

    SELECT COUNT(*) INTO v_aliases
    FROM public.whitelist_email_aliases a
    JOIN public.whitelist w ON w.email = a.whitelist_email
    WHERE w.batch_id = v_batch_id;

    IF v_total <> 117 OR v_g1 <> 59 OR v_g2 <> 58 THEN
        RAISE EXCEPTION '26MX roster mismatch: total %, G1 %, G2 %', v_total, v_g1, v_g2;
    END IF;
    IF v_otp_ready <> 117 OR v_pending_email <> 0 THEN
        RAISE EXCEPTION '26MX email readiness mismatch: ready %, pending %', v_otp_ready, v_pending_email;
    END IF;
    IF v_aliases < 235 THEN
        RAISE EXCEPTION '26MX alias mismatch: expected at least 235, found %', v_aliases;
    END IF;
END $$;

SELECT
    b.batch_code,
    b.status,
    COUNT(w.*) AS rostered_students,
    COUNT(*) FILTER (WHERE w.batch = 'G1') AS g1_students,
    COUNT(*) FILTER (WHERE w.batch = 'G2') AS g2_students,
    COUNT(*) FILTER (
        WHERE w.personal_email IS NOT NULL OR w.college_email IS NOT NULL
    ) AS otp_ready_students,
    COUNT(*) FILTER (
        WHERE w.personal_email IS NULL AND w.college_email IS NULL
    ) AS email_required_students
FROM public.batches b
LEFT JOIN public.whitelist w ON w.batch_id = b.id
WHERE b.batch_code IN ('25MX', '26MX')
GROUP BY b.batch_code, b.status
ORDER BY b.batch_code;

SELECT
    COUNT(*) FILTER (WHERE p.policyname LIKE '%batch_boundary') AS batch_boundary_policies,
    to_regclass('public.whitelist_email_aliases') IS NOT NULL AS roster_alias_table_ready,
    to_regclass('public.user_auth_identities') IS NOT NULL AS auth_identity_table_ready,
    to_regprocedure('public.current_user_id()') IS NOT NULL AS logical_identity_ready
FROM pg_policies p
WHERE p.schemaname = 'public';
