// ============================================================
// PSGMX — lib/ai/rag.ts (v2)
// Retrieval-Augmented Generation context builder.
// Uses pgvector cosine similarity (<=> operator) for semantic search
// with tsvector keyword search as fallback.
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
 * generateEmbedding
 * Generates a 384-dim embedding for a query string using the Supabase AI edge endpoint.
 * Calls the knowledge-ingest edge function's embedding endpoint, or falls back to null.
 */
async function generateEmbedding(text: string): Promise<number[] | null> {
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const serviceKey  = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!supabaseUrl || !serviceKey) return null

    // Call Supabase's native AI inference endpoint (available in Edge Functions only)
    // From Next.js server context, we call it via the REST API
    const response = await fetch(`${supabaseUrl}/functions/v1/generate-embedding`, {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({ text }),
      signal: AbortSignal.timeout(5000),
    })

    if (!response.ok) return null
    const data = await response.json()
    return data.embedding ?? null
  } catch {
    return null
  }
}

/**
 * semanticSearch
 * Runs a pgvector cosine similarity search against knowledge_embeddings.
 * Returns top-5 chunks from approved articles.
 */
async function semanticSearch(embedding: number[]): Promise<RAGContext['articles']> {
  // Use Supabase RPC for the vector search
  const { data, error } = await supabaseAdmin.rpc('knowledge_semantic_search', {
    query_embedding: embedding,
    match_threshold: 0.5,    // cosine similarity threshold (1 - distance)
    match_count:     5,
  } as any)

  if (error || !data) return []

  return (data as Array<{
    id: string
    article_id: string
    chunk_text: string
    title: string
    similarity: number
  }>).map(row => ({
    id:         row.id,
    title:      row.title ?? 'Unknown Article',
    chunk_text: row.chunk_text,
    article_id: row.article_id,
    similarity: row.similarity,
  }))
}

/**
 * keywordSearch
 * Full-text tsvector search fallback when embeddings aren't available.
 */
async function keywordSearch(query: string): Promise<RAGContext['articles']> {
  // Build a tsquery from the user's query
  const tsQuery = query
    .trim()
    .split(/\s+/)
    .filter(w => w.length > 2)
    .map(w => w.replace(/[^a-zA-Z0-9]/g, ''))
    .filter(Boolean)
    .join(' | ')

  if (!tsQuery) return []

  const { data, error } = await supabaseAdmin
    .from('knowledge_brain_articles')
    .select(`
      id,
      title,
      summary
    `)
    .eq('approval_status', 'approved')
    .textSearch('search_vector', tsQuery, { type: 'websearch', config: 'english' })
    .limit(5)

  if (error || !data) return []

  // For keyword results, fetch first chunk of each article
  const articleIds = (data as any[]).map((a: any) => a.id)
  const { data: chunks } = await supabaseAdmin
    .from('knowledge_embeddings')
    .select('id, article_id, chunk_text')
    .in('article_id', articleIds)
    .eq('chunk_index', 0)

  return (data as any[]).map((article: any, index: number) => {
    const chunk = chunks?.find((c: any) => c.article_id === article.id)
    return {
      id:         (chunk as any)?.id ?? article.id,
      title:      (article as any).title,
      chunk_text: (chunk as any)?.chunk_text ?? article.summary ?? '',
      article_id: article.id,
      similarity: 1 - index * 0.1,
    }
  }).filter((a: any) => a.chunk_text.length > 0)
}

/**
 * buildRAGContext
 * Primary function called by the AI Senior API route.
 * Tries semantic search first, falls back to keyword search.
 */
export async function buildRAGContext(
  query: string,
  userId: string
): Promise<RAGContext> {
  let articles: RAGContext['articles'] = []

  // 1. Try semantic search via pgvector
  const embedding = await generateEmbedding(query)
  if (embedding && embedding.length > 0) {
    articles = await semanticSearch(embedding)
  }

  // 2. Fall back to keyword search if semantic search returns nothing
  if (articles.length === 0) {
    articles = await keywordSearch(query)
  }

  // 3. Optionally boost lineage-related articles
  // TODO: Implement lineage boosting — query lineage_map for userId,
  // then boost articles from the same batch_year as their seniors' batch.

  return {
    articles,
    systemPrompt: DEFAULT_SYSTEM_PROMPT,
  }
}

/**
 * formatRAGContextForPrompt
 * Converts RAGContext into a string suitable for LLM prompt injection.
 */
export function formatRAGContextForPrompt(context: RAGContext): string {
  if (context.articles.length === 0) {
    return '(No relevant Knowledge Brain articles found for this question.)'
  }

  return context.articles
    .map((article, i) =>
      `--- Source ${i + 1}: ${(article as any).title} (similarity: ${article.similarity.toFixed(2)}) ---\n${article.chunk_text}`
    )
    .join('\n\n')
}
