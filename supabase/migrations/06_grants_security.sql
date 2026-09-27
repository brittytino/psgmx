-- ============================================================
-- PSGMX — 06_grants_security.sql
-- Role Privileges, Schema Grants & Execution Permissions
-- ============================================================

-- Schema Usage
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO service_role;

-- Authenticated Role Access
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Sensitive Column Restrictions (Anti-Cheat & Leak Prevention)
-- Students cannot read correct answers via PostgREST; evaluation is strictly server-side RPC
REVOKE SELECT (correct_option) ON public.mock_exam_questions FROM authenticated;
REVOKE SELECT (correct_option) ON public.question_bank FROM authenticated;

-- Public / Anonymous Role Access (Restricted to Login & Remote Config)
GRANT SELECT ON public.app_config TO anon;
GRANT SELECT ON public.batches TO anon;

-- Function Execution Grants
GRANT EXECUTE ON FUNCTION public.current_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_reg_no() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_batch() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_team_leader() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_coordinator() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_placement_rep() TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_onboarding_profile(TEXT, TEXT, TEXT, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_five_questions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_daily_five_answers(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_squad() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_batch_placement_teams(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_squad_objective(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_lineage_reveal() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_lineage_juniors() TO authenticated;
GRANT EXECUTE ON FUNCTION public.moderate_community_content(TEXT, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.start_mock_exam(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_exam_server_side(UUID, UUID, JSONB, INT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_mock_exam_question_with_answer(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.knowledge_semantic_search(vector, FLOAT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_birthday_notifications() TO authenticated, service_role;

