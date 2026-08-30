ALTER TABLE public.knowledge_brain_articles
  ADD COLUMN IF NOT EXISTS review_due_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_knowledge_review_due
  ON public.knowledge_brain_articles(review_due_at)
  WHERE review_due_at IS NOT NULL;
