-- 1. Ensure 'completed' column exists on mock_exam_results
ALTER TABLE IF EXISTS public.mock_exam_results 
  ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT FALSE;

-- 2. Drop all rogue triggers on mock_exam_results
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT trigger_name, event_object_table 
    FROM information_schema.triggers 
    WHERE event_object_schema = 'public'
      AND event_object_table = 'mock_exam_results'
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
