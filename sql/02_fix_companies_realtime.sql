-- ============================================================
-- PSGMX SQL — FILE 02: Fix Companies Table RLS & Realtime
-- Run this SECOND in Supabase SQL Editor
-- Fixes the RealtimeSubscribeException on the Log screen
-- ============================================================

-- Enable RLS on companies (may already be on)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Allow ALL authenticated users to read ALL company records
DROP POLICY IF EXISTS companies_read_all ON companies;
CREATE POLICY companies_read_all ON companies
    FOR SELECT TO authenticated USING (true);

-- Allow only users with manage_company_records permission to insert/update
DROP POLICY IF EXISTS companies_write ON companies;
CREATE POLICY companies_write ON companies
    FOR ALL TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM user_permissions
        WHERE user_id = auth.uid()
          AND permission = 'manage_company_records'
      )
    )
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM user_permissions
        WHERE user_id = auth.uid()
          AND permission = 'manage_company_records'
      )
    );

-- Enable Realtime on companies table
-- NOTE: In Supabase dashboard also go to Database > Replication and enable for 'companies' table
ALTER PUBLICATION supabase_realtime ADD TABLE companies;

-- Also fix placement_log_entries RLS
ALTER TABLE placement_log_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS placement_log_entries_read ON placement_log_entries;
CREATE POLICY placement_log_entries_read ON placement_log_entries
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS placement_log_entries_insert ON placement_log_entries;
CREATE POLICY placement_log_entries_insert ON placement_log_entries
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

SELECT 'FILE 02 COMPLETE: Companies RLS and realtime fixed.' AS status;
