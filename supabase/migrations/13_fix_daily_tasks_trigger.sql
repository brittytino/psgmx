-- ============================================================
-- PSGMX — 13_fix_daily_tasks_trigger.sql
-- Fix: Ensure daily_five_attempts, daily_five_streaks, and daily_tasks
-- have completed column to prevent: record "new" has no field "completed",
-- drop any rogue triggers on attempt tables, and grant SELECT on question_bank
-- ============================================================

-- 1. Ensure 'completed' column exists on daily_five_attempts & daily_five_streaks
ALTER TABLE IF EXISTS public.daily_five_attempts 
  ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT FALSE;

ALTER TABLE IF EXISTS public.daily_five_streaks 
  ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT FALSE;

-- 2. Ensure 'completed' and 'batch_id' exist on daily_tasks
ALTER TABLE IF EXISTS public.daily_tasks 
  ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.batches(id);

-- 3. Drop all rogue triggers on daily_five_attempts & daily_five_streaks
-- (The canonical engine handles streak updates inside RPC functions, not triggers)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT trigger_name, event_object_table 
    FROM information_schema.triggers 
    WHERE event_object_schema = 'public'
      AND event_object_table IN ('daily_five_attempts', 'daily_five_streaks', 'daily_tasks')
  ) LOOP
    BEGIN
      EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.trigger_name) || ' ON public.' || quote_ident(r.event_object_table) || ' CASCADE;';
      RAISE NOTICE 'Dropped trigger % on %', r.trigger_name, r.event_object_table;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Could not drop trigger %: %', r.trigger_name, SQLERRM;
    END;
  END LOOP;
END;
$$;

-- 4. Grant authenticated SELECT on question_bank (with correct_option withheld by column revoke)
GRANT SELECT ON public.question_bank TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'question_bank' AND policyname = 'question_bank_read_active'
  ) THEN
    CREATE POLICY "question_bank_read_active" 
      ON public.question_bank 
      FOR SELECT TO authenticated 
      USING (is_active = true);
  END IF;
END;
$$;

-- 5. Performance index on daily_tasks
CREATE INDEX IF NOT EXISTS idx_daily_tasks_batch_id ON public.daily_tasks(batch_id);
