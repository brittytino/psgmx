-- ============================================================
-- PSGMX — 06_semantic_search.sql
-- PostgreSQL RPC for pgvector cosine similarity search.
-- Called by lib/ai/rag.ts via supabaseAdmin.rpc()
-- ============================================================

-- RPC: knowledge_semantic_search
-- Performs cosine similarity search on knowledge_embeddings.
-- Returns top N chunks from approved knowledge_brain_articles.
CREATE OR REPLACE FUNCTION knowledge_semantic_search(
  query_embedding  vector,       -- 384-dim gte-small embedding
  match_threshold  FLOAT DEFAULT 0.5,   -- minimum cosine similarity (1 - distance)
  match_count      INT   DEFAULT 5
)
RETURNS TABLE (
  id          UUID,
  article_id  UUID,
  chunk_text  TEXT,
  title       TEXT,
  similarity  FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ke.id,
    ke.article_id,
    ke.chunk_text,
    kba.title,
    1 - (ke.embedding <=> query_embedding) AS similarity
  FROM knowledge_embeddings ke
  JOIN knowledge_brain_articles kba
    ON kba.id = ke.article_id
   AND kba.approval_status = 'approved'
  WHERE ke.embedding IS NOT NULL
    AND (1 - (ke.embedding <=> query_embedding)) >= match_threshold
  ORDER BY ke.embedding <=> query_embedding   -- ascending distance = descending similarity
  LIMIT match_count;
$$;
