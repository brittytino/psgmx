-- Persistent read state for department announcements across web and mobile.
CREATE TABLE IF NOT EXISTS public.announcement_reads (
  announcement_id UUID NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (announcement_id, user_id)
);
ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "announcement_reads_own_select" ON public.announcement_reads FOR SELECT TO authenticated
USING (user_id = public.current_user_id());
CREATE POLICY "announcement_reads_own_insert" ON public.announcement_reads FOR INSERT TO authenticated
WITH CHECK (user_id = public.current_user_id());
CREATE POLICY "announcement_reads_own_update" ON public.announcement_reads FOR UPDATE TO authenticated
USING (user_id = public.current_user_id()) WITH CHECK (user_id = public.current_user_id());
GRANT SELECT, INSERT, UPDATE ON public.announcement_reads TO authenticated;
