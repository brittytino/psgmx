-- Run after migrations in a disposable/local database.
-- The transaction is rolled back and never changes persistent data.
BEGIN;

DO $$
DECLARE
    v_25 UUID;
    v_26 UUID;
BEGIN
    SELECT id INTO v_25 FROM public.batches WHERE batch_code = '25MX';
    SELECT id INTO v_26 FROM public.batches WHERE batch_code = '26MX';
    IF v_25 IS NULL OR v_26 IS NULL OR v_25 = v_26 THEN
        RAISE EXCEPTION '25MX and 26MX batch identities must be distinct';
    END IF;

    IF to_regclass('public.user_auth_identities') IS NULL THEN
        RAISE EXCEPTION 'dual-email identity map is missing';
    END IF;
    IF to_regclass('public.whitelist_email_aliases') IS NULL THEN
        RAISE EXCEPTION 'whitelist alias map is missing';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'team_code'
    ) THEN
        RAISE EXCEPTION 'canonical team code is missing';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND policyname = 'users_batch_boundary' AND permissive = 'RESTRICTIVE'
    ) THEN
        RAISE EXCEPTION 'restrictive users batch boundary is missing';
    END IF;
END $$;

ROLLBACK;
