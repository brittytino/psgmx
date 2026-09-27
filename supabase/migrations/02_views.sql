-- ============================================================
-- PSGMX — 02_views.sql
-- Materialized & Relational Views
-- ============================================================

-- ── 1. current_readiness_scores ─────────────────────────────
-- Returns the latest computed readiness snapshot for each student
CREATE OR REPLACE VIEW public.current_readiness_scores AS
SELECT DISTINCT ON (user_id)
    id,
    user_id,
    score,
    computed_at,
    components_json
FROM public.readiness_scores
ORDER BY user_id, computed_at DESC;
