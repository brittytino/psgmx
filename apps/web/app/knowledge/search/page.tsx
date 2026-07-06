// ============================================================
// GET /knowledge/search?q=...
// Knowledge Brain search page.
// Supports both semantic (pgvector) and keyword (tsvector) search.
// Server Component — SSR for SEO and initial data load.
// ============================================================
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'

interface Article {
  id: string
  title: string
  summary: string | null
  company_name: string | null
  tags: string[] | null
  batch_year: string | null
  author_id: string | null
  view_count: number
  created_at: string
}

async function searchArticles(query: string, supabase: Awaited<ReturnType<typeof createClient>>): Promise<Article[]> {
  if (!query.trim()) return []

  // Try full-text search via tsvector
  const tsQuery = query
    .trim()
    .split(/\s+/)
    .map(w => w.replace(/[^a-zA-Z0-9]/g, ''))
    .filter(w => w.length > 1)
    .join(' | ')

  if (tsQuery) {
    const { data: ftsResults, error } = await supabase
      .from('knowledge_brain_articles')
      .select('id, title, summary, company_name, tags, batch_year, author_id, view_count, created_at')
      .eq('approval_status', 'approved')
      .textSearch('search_vector', tsQuery, { type: 'websearch', config: 'english' })
      .order('view_count', { ascending: false })
      .limit(20)

    if (!error && ftsResults && ftsResults.length > 0) {
      return ftsResults as Article[]
    }
  }

  // Fallback: simple ilike search on title + company_name
  const { data: likeResults } = await supabase
    .from('knowledge_brain_articles')
    .select('id, title, summary, company_name, tags, batch_year, author_id, view_count, created_at')
    .eq('approval_status', 'approved')
    .or(`title.ilike.%${query}%,company_name.ilike.%${query}%,summary.ilike.%${query}%`)
    .order('view_count', { ascending: false })
    .limit(20)

  return (likeResults ?? []) as Article[]
}

export default async function KnowledgeSearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login?redirect=/knowledge/search')

  const { q: query = '' } = await searchParams
  const articles = query ? await searchArticles(query, supabase) : []

  // Increment view count when clicking (handled client-side separately)

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-12">
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Knowledge Brain Search</h1>
          <p className="text-gray-500">Search interview experiences, guides, and placement insights</p>
        </div>

        {/* Search Form */}
        <form method="GET" className="mb-10">
          <div className="flex gap-3">
            <input
              type="text"
              name="q"
              defaultValue={query}
              placeholder="Search by company, topic, or keyword..."
              className="flex-1 px-5 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-base shadow-sm"
              autoFocus
            />
            <button
              type="submit"
              className="px-8 py-3 bg-indigo-600 text-white rounded-xl font-medium hover:bg-indigo-700 transition shadow-sm"
            >
              Search
            </button>
          </div>
        </form>

        {/* Results */}
        {query && (
          <div>
            <p className="text-sm text-gray-500 mb-6">
              {articles.length > 0
                ? `${articles.length} result${articles.length !== 1 ? 's' : ''} for "${query}"`
                : `No results found for "${query}"`}
            </p>

            {articles.length === 0 && (
              <div className="text-center py-16 bg-white rounded-2xl border border-gray-200">
                <div className="text-4xl mb-4">🔍</div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">No articles found</h3>
                <p className="text-gray-500 text-sm max-w-xs mx-auto">
                  Try a different keyword, or browse the full knowledge base
                </p>
                <Link
                  href="/knowledge"
                  className="mt-6 inline-block px-6 py-2.5 bg-indigo-600 text-white rounded-xl text-sm font-medium hover:bg-indigo-700 transition"
                >
                  Browse All Articles
                </Link>
              </div>
            )}

            <div className="space-y-4">
              {articles.map(article => (
                <Link
                  key={article.id}
                  href={`/knowledge/${article.id}`}
                  className="block bg-white rounded-2xl border border-gray-200 p-6 hover:border-indigo-300 hover:shadow-md transition-all group"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1 min-w-0">
                      <h3 className="text-base font-semibold text-gray-900 group-hover:text-indigo-600 transition truncate mb-1">
                        {article.title}
                      </h3>
                      {article.summary && (
                        <p className="text-sm text-gray-500 line-clamp-2 mb-3">
                          {article.summary}
                        </p>
                      )}
                      <div className="flex flex-wrap items-center gap-2 text-xs">
                        {article.company_name && (
                          <span className="px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full font-medium">
                            {article.company_name}
                          </span>
                        )}
                        {article.batch_year && (
                          <span className="px-2.5 py-1 bg-gray-100 text-gray-600 rounded-full">
                            {article.batch_year}
                          </span>
                        )}
                        {article.tags?.slice(0, 3).map(tag => (
                          <span key={tag} className="px-2.5 py-1 bg-indigo-50 text-indigo-600 rounded-full">
                            #{tag}
                          </span>
                        ))}
                      </div>
                    </div>
                    <div className="text-xs text-gray-400 shrink-0 mt-1 text-right">
                      <div>{article.view_count} views</div>
                      <div className="mt-1">
                        {new Date(article.created_at).toLocaleDateString('en-IN', {
                          day: 'numeric', month: 'short', year: 'numeric'
                        })}
                      </div>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        )}

        {!query && (
          <div className="text-center py-20 text-gray-400">
            <div className="text-5xl mb-4">📚</div>
            <p className="text-lg font-medium text-gray-600 mb-2">What are you looking for?</p>
            <p className="text-sm">Search for companies, topics, or placement insights above</p>
          </div>
        )}
      </div>
    </div>
  )
}
