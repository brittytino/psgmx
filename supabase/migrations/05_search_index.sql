-- ============================================================
-- PSGMX — 05_search_index.sql
-- Full-text search index on knowledge_brain_articles.
-- tsvector column + update trigger for real-time indexing.
-- ============================================================

-- Update search_vector from title + content + tags + company_name
CREATE OR REPLACE FUNCTION update_knowledge_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.summary, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.company_name, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(substring(NEW.content, 1, 2000), '')), 'D');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trig_knowledge_search_vector ON knowledge_brain_articles;
CREATE TRIGGER trig_knowledge_search_vector
  BEFORE INSERT OR UPDATE OF title, summary, content, tags, company_name
  ON knowledge_brain_articles
  FOR EACH ROW EXECUTE FUNCTION update_knowledge_search_vector();

-- Backfill existing rows (run once)
UPDATE knowledge_brain_articles
SET search_vector =
  setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
  setweight(to_tsvector('english', COALESCE(summary, '')), 'B') ||
  setweight(to_tsvector('english', COALESCE(company_name, '')), 'B') ||
  setweight(to_tsvector('english', COALESCE(array_to_string(tags, ' '), '')), 'C') ||
  setweight(to_tsvector('english', COALESCE(substring(content, 1, 2000), '')), 'D')
WHERE search_vector IS NULL;

-- Ensure index exists (also in 00_initial_schema.sql — idempotent)
CREATE INDEX IF NOT EXISTS knowledge_brain_articles_search_idx
  ON knowledge_brain_articles
  USING gin(search_vector);
