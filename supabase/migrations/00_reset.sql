-- ============================================================
-- PSGMX — 00_reset.sql
-- ============================================================
-- Drops the entire public schema and rebuilds it empty, so the migration
-- sequence that follows (01_schema_core.sql .. 14_seed_placement_23mx_24mx.sql)
-- always starts from a clean, known state instead of layering on top of
-- whatever drift has accumulated in the live database.
--
-- ⚠️ DESTRUCTIVE — this deletes every row in every table in the `public`
-- schema. Confirmed with the project owner that there is no live data to
-- preserve before running this. Do not run against a database that has
-- real user data you care about.
--
-- Run this FIRST, once, in the Supabase SQL Editor (or via
-- `supabase db reset` locally, which applies this whole directory in
-- filename order automatically).
-- ============================================================

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Extensions used across the schema/functions that follow.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
BEGIN
    RAISE NOTICE '✅ 00_reset.sql complete — public schema dropped and recreated empty.';
    RAISE NOTICE 'NEXT: run 01_schema_core.sql';
END $$;
