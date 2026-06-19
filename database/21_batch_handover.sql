-- ==============================================================================
-- 21_batch_handover.sql
-- Automates the end-of-year batch promotion using pg_cron.
-- ==============================================================================

-- Ensure pg_cron extension is enabled (Requires Supabase dashboard or postgres user)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create the rotation function
CREATE OR REPLACE FUNCTION rotate_batch_status()
RETURNS void AS $$
BEGIN
    -- This function promotes current 'active' batches to 'alumni'
    -- if their graduation year has passed.
    UPDATE batches
    SET status = 'graduated'
    WHERE status IN ('active_senior', 'active_junior')
      AND (end_year::text || '-07-01')::date < CURRENT_DATE;
      
    -- Note: We assume graduation officially happens around July 1st
    -- of the graduation year.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule the cron job to run every day at midnight
-- Need to check if the job already exists before scheduling to avoid errors.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily_batch_rotation') THEN
        PERFORM cron.schedule(
            'daily_batch_rotation',
            '0 0 * * *',
            'SELECT rotate_batch_status()'
        );
    END IF;
END $$;
