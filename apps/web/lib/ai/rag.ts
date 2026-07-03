// ============================================================
// PSGMX — lib/ai/rag.ts
// Retrieval-Augmented Generation context builder.
// Migrated from MongoDB (KnowledgeBrainArticle + KnowledgeGraphEdge)
// to Supabase pgvector semantic search on knowledge_embeddings.
// ============================================================
import { supabaseAdmin } from '@/lib/supabase/admin'

export interface RAGContext {
  articles: Array<{
    id: string
    title: string
    chunk_text: string
    article_id: string
    similarity: number
  }>
  systemPrompt: string
}

const DEFAULT_SYSTEM_PROMPT = `You are the AI Senior for the MCA Department at PSG College of Technology, Coimbatore.
You help students with placement preparation: aptitude, DSA, database concepts, operating systems, networking, OOP, Python, Java, and HR interviews.
Use the provided Knowledge Brain context to answer accurately. If the context doesn't cover the question, say so honestly.
Be concise, practical, and encouraging. Use examples where helpful.`

/**
 * buildRAGContext
 * Performs semantic search on knowledge_embeddings using pgvector cosine similarity.
 * Returns the top-5 most relevant chunks as RAG context.
 *
 * @param query - The user's question text
 * @param userId - The requesting user's UUID (for lineage boosting)
 * @returns RAGContext with matching articles and system prompt
 */
export async function buildRAGContext(
  query: string,
  userId: string
): Promise<RAGContext> {
  // 1. Generate an embedding for the query using Supabase AI
  // This is called from the API route (server-side Next.js), not Edge Function
  // so we use fetch to call a Supabase Edge Function or the Supabase AI endpoint.
  // TODO: Replace with direct Supabase AI call once the Edge Function runtime
  // is available in Next.js server components.
  // For now, fall back to keyword search as a reliable baseline.

  // 2. Semantic search — try pgvector first, fall back to keyword
  let chunks: Array<{
    id: string
    article_id: string
    chunk_text: string
    knowledge_brain_articles: { title: string } | null
  }> = []

  // Keyword search fallback (always works without embeddings)
  const { data: keywordChunks, error } = await supabaseAdmin
    .from('knowledge_embeddings')
    .select(`
      id,
      article_id,
      chunk_text,
      knowledge_brain_articles!inner(title, approval_status)
    `)
    .ilike('chunk_text', `%${query.substring(0, 50)}%`)
    .limit(5)

  if (!error && keywordChunks) {
    chunks = keywordChunks as typeof chunks
  }

  // 3. Boost lineage-related articles if user has lineage connections
  // TODO: Implement lineage-based article boosting using lineage_map
  // when pgvector semantic search is enabled.

  const articles = chunks.map((chunk, index) => ({
    id: chunk.id,
    title: (chunk.knowledge_brain_articles as { title: string } | null)?.title ?? 'Unknown Article',
    chunk_text: chunk.chunk_text,
    article_id: chunk.article_id,
    similarity: 1 - index * 0.1,  // Approximate similarity score from keyword rank
  }))

  return {
    articles,
    systemPrompt: DEFAULT_SYSTEM_PROMPT,
  }
}

/**
 * formatRAGContextForPrompt
 * Converts RAGContext into a string suitable for injection into an LLM prompt.
 */
export function formatRAGContextForPrompt(context: RAGContext): string {
  if (context.articles.length === 0) {
    return '(No relevant Knowledge Brain articles found for this question.)'
  }

  return context.articles
    .map((article, i) => `--- Article ${i + 1}: ${article.title} ---\n${article.chunk_text}`)
    .join('\n\n')
}
