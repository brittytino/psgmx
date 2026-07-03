-- ========================================
-- FIX SUPABASE ROLE PERMISSIONS
-- ========================================
-- Run this in your Supabase SQL Editor to grant the necessary 
-- table permissions to the anon and authenticated roles.
-- Row Level Security (RLS) will still protect the actual data.

-- 1. Grant usage on the public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- 2. Grant table permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- 3. Grant sequence permissions (for auto-incrementing IDs if any)
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- 4. Grant routine/function permissions (for RPCs)
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;

-- 5. Ensure future tables also get these permissions automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated;
