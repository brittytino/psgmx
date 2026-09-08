-- ============================================================
-- PSGMX Migration 47 — 47_session_lock_enforcement.sql
-- ============================================================
-- `placement_sessions.is_locked` (migration 03) has existed since the
-- earliest schema but was never read or written anywhere — Agent.md
-- promises a PR "session status" quick action but no semantics were ever
-- defined for what "locked" blocks.
--
-- Semantics adopted here (the natural reading of "lock a session"): once a
-- session is locked, its attendance is finalized — no further insert/update
-- to `placement_attendance` for that session is allowed, for anyone,
-- including the PR who already had `mark_placement_attendance` rights. This
-- is enforced in RLS itself (PRD "rule zero": hiding a button is never
-- access control), not just hidden client-side.
--
-- Locking/unlocking itself needs no new RPC — `placement_sessions_write`
-- already lets a `schedule_placement_sessions`-permission holder (the PR)
-- update any column on their batch's sessions, `is_locked` included.
-- ============================================================

DROP POLICY IF EXISTS "placement_attendance_write" ON placement_attendance;
CREATE POLICY "placement_attendance_write" ON placement_attendance FOR ALL TO authenticated
    USING (
        user_has_permission(auth.uid(), 'mark_placement_attendance')
        AND NOT EXISTS (
            SELECT 1 FROM placement_sessions ps
            WHERE ps.id = placement_attendance.session_id AND ps.is_locked = true
        )
    )
    WITH CHECK (
        user_has_permission(auth.uid(), 'mark_placement_attendance')
        AND NOT EXISTS (
            SELECT 1 FROM placement_sessions ps
            WHERE ps.id = placement_attendance.session_id AND ps.is_locked = true
        )
    );
