-- ============================================================
-- PSGMX Migration 45 — 45_lineage_requests.sql
-- ============================================================
-- PRD Ch. 14.2: "Students can send connection requests with a specific
-- topic and question. Alumni can accept, decline, or redirect." What
-- shipped in migrations 39-41 is a different, simpler model: a static 1:1
-- pairing (lineage_map) seeded by register-suffix matching, surfaced
-- read-only via get_my_lineage(). This adds the request/response layer on
-- top — additive, not a replacement, so the assigned-senior card keeps
-- working exactly as it does today even for students who never send a
-- request.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.lineage_requests (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  alumni_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  topic          TEXT NOT NULL CHECK (char_length(trim(topic)) BETWEEN 2 AND 120),
  question       TEXT NOT NULL CHECK (char_length(trim(question)) BETWEEN 5 AND 1000),
  status         TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'redirected')),
  redirected_to  UUID REFERENCES public.users(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_lineage_requests_student ON public.lineage_requests(student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lineage_requests_alumni_open
  ON public.lineage_requests(alumni_id) WHERE status = 'pending';

ALTER TABLE public.lineage_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lineage_requests_student_read" ON public.lineage_requests
  FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "lineage_requests_student_insert" ON public.lineage_requests
  FOR INSERT TO authenticated WITH CHECK (student_id = auth.uid());
CREATE POLICY "lineage_requests_alumni_read" ON public.lineage_requests
  FOR SELECT TO authenticated USING (alumni_id = auth.uid());
CREATE POLICY "lineage_requests_alumni_respond" ON public.lineage_requests
  FOR UPDATE TO authenticated
  USING (alumni_id = auth.uid())
  WITH CHECK (alumni_id = auth.uid() AND status IN ('accepted', 'declined', 'redirected'));
