-- Preserve the complete first-login profile instead of discarding student inputs.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS interests TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS career_goal TEXT;

COMMENT ON COLUMN public.users.interests IS
  'Student-selected technical or career interests used to personalize preparation.';
COMMENT ON COLUMN public.users.career_goal IS
  'Optional student career direction captured during first login.';
